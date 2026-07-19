package operation

import (
	"bytes"
	"context"
	"errors"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestServiceBeginUsesServerClockAndHardDeadline(t *testing.T) {
	t.Parallel()

	serverNow := time.Date(2026, time.July, 16, 15, 30, 0, 123, time.FixedZone("ALMT", 5*60*60))
	store := newMutexOperationStore()
	service := mustOperationService(t, store, mustOperationKeyRing(t), serverNow)

	result, err := service.Begin(context.Background(), validBeginRequest(t))
	if err != nil {
		t.Fatalf("Begin() error = %v", err)
	}
	if result.Outcome != BeginOutcomeNewlyAcceptedPending || result.Receipt.Status() != domain.OperationStatusPending {
		t.Fatalf("Begin() outcome/status = %q/%q", result.Outcome, result.Receipt.Status())
	}
	wantNow := serverNow.UTC()
	if !result.Receipt.CreatedAt().Equal(wantNow) {
		t.Fatalf("CreatedAt() = %v, want server time %v", result.Receipt.CreatedAt(), wantNow)
	}
	if got := result.Receipt.CommitDeadline().Sub(result.Receipt.CreatedAt()); got != operationHardCommitWindow {
		t.Fatalf("commit window = %v, want hard deadline %v", got, operationHardCommitWindow)
	}
	if calls, created := store.stats(); calls != 1 || created != 1 {
		t.Fatalf("store calls/creates = %d/%d, want 1/1", calls, created)
	}
}

func TestServiceBeginReturnsExistingPending(t *testing.T) {
	t.Parallel()

	now := testServerNow()
	store := newMutexOperationStore()
	service := mustOperationService(t, store, mustOperationKeyRing(t), now)
	request := validBeginRequest(t)

	first, err := service.Begin(context.Background(), request)
	if err != nil {
		t.Fatalf("first Begin() error = %v", err)
	}
	second, err := service.Begin(context.Background(), request)
	if err != nil {
		t.Fatalf("second Begin() error = %v", err)
	}
	if first.Outcome != BeginOutcomeNewlyAcceptedPending || second.Outcome != BeginOutcomeExistingPending {
		t.Fatalf("Begin() outcomes = %q/%q", first.Outcome, second.Outcome)
	}
	if first.Receipt != second.Receipt {
		t.Fatal("same identity did not converge to the existing receipt")
	}
	if calls, created := store.stats(); calls != 2 || created != 1 {
		t.Fatalf("store calls/creates = %d/%d, want 2/1", calls, created)
	}
}

func TestServiceBeginReplaysImmutableTerminalReceipt(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		wantStatus domain.OperationStatus
		transition func(t *testing.T, receipt *domain.SavedOperation, now time.Time)
	}{
		{
			name:       "succeeded with applied outcome",
			wantStatus: domain.OperationStatusSucceeded,
			transition: func(t *testing.T, receipt *domain.SavedOperation, now time.Time) {
				t.Helper()
				if err := receipt.Succeed(now.Add(time.Second), domain.OperationOutcomeApplied, domain.RefreshScopeSavedItems, domain.OperationVersionEffects{}); err != nil {
					t.Fatalf("Succeed() error = %v", err)
				}
				if receipt.Outcome() != domain.OperationOutcomeApplied {
					t.Fatalf("Succeed() outcome = %q, want APPLIED", receipt.Outcome())
				}
			},
		},
		{
			name:       "rejected",
			wantStatus: domain.OperationStatusRejected,
			transition: func(t *testing.T, receipt *domain.SavedOperation, now time.Time) {
				t.Helper()
				if err := receipt.Reject(now.Add(time.Second), domain.ErrTargetUnavailable, domain.RefreshScopeNone); err != nil {
					t.Fatalf("Reject() error = %v", err)
				}
			},
		},
		{
			name:       "expired",
			wantStatus: domain.OperationStatusExpired,
			transition: func(t *testing.T, receipt *domain.SavedOperation, _ time.Time) {
				t.Helper()
				if err := receipt.Expire(receipt.CommitDeadline()); err != nil {
					t.Fatalf("Expire() error = %v", err)
				}
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			now := testServerNow()
			store := newMutexOperationStore()
			service := mustOperationService(t, store, mustOperationKeyRing(t), now)
			request := validBeginRequest(t)

			accepted, err := service.Begin(context.Background(), request)
			if err != nil {
				t.Fatalf("first Begin() error = %v", err)
			}
			test.transition(t, accepted.Receipt, now)

			replayed, err := service.Begin(context.Background(), request)
			if err != nil {
				t.Fatalf("replay Begin() error = %v", err)
			}
			if replayed.Outcome != BeginOutcomeTerminalReplay || replayed.Receipt != accepted.Receipt || replayed.Receipt.Status() != test.wantStatus {
				t.Fatalf("replay outcome/receipt/status = %q/%p/%q", replayed.Outcome, replayed.Receipt, replayed.Receipt.Status())
			}
			if err := replayed.Receipt.Succeed(replayed.Receipt.CommitDeadline().Add(time.Second), domain.OperationOutcomeApplied, domain.RefreshScopeSavedItems, domain.OperationVersionEffects{}); !errors.Is(err, domain.ErrMutationStale) {
				t.Fatalf("terminal receipt accepted another transition: %v", err)
			}
		})
	}
}

func TestServiceBeginRejectsReplayMismatch(t *testing.T) {
	t.Parallel()

	t.Run("same identity with different target", func(t *testing.T) {
		service, _, request := newServiceScenario(t)
		mustBegin(t, service, request)
		request.Target = mustSavedTarget(t, domain.EntityTypeActivity, "activity|different:43")
		assertReplayMismatch(t, service, request)
	})

	t.Run("same identity with different kind", func(t *testing.T) {
		service, _, request := newServiceScenario(t)
		mustBegin(t, service, request)
		request.Kind = domain.OperationKindUnsave
		assertReplayMismatch(t, service, request)
	})

	t.Run("idempotency key reused across semantics", func(t *testing.T) {
		service, _, request := newServiceScenario(t)
		mustBegin(t, service, request)
		request.OperationID = uuid.MustParse("00000000-0000-4000-8000-000000000099")
		request.Target = mustSavedTarget(t, domain.EntityTypeGuide, "guide|different:99")
		assertReplayMismatch(t, service, request)
	})

	t.Run("operation ID reused across semantics", func(t *testing.T) {
		service, _, request := newServiceScenario(t)
		mustBegin(t, service, request)
		request.IdempotencyKey = "zyxwvutsrqponmlkjihgfedcba987654"
		request.Target = mustSavedTarget(t, domain.EntityTypeAttraction, "attraction|different:99")
		assertReplayMismatch(t, service, request)
	})

	t.Run("different semantic HMAC", func(t *testing.T) {
		now := testServerNow()
		store := newMutexOperationStore()
		ring := mustOperationKeyRing(t)
		request := validBeginRequest(t)
		badDigest := bytes.Repeat([]byte{0xa5}, 32)
		receipt, err := domain.NewPendingOperation(
			request.OperationID,
			request.SubjectID,
			request.SessionGeneration,
			request.Kind,
			request.IdempotencyKey,
			badDigest,
			ring.CurrentVersion(),
			request.SourceSurface,
			request.AcceptedPolicyRevision,
			now,
			now.Add(operationHardCommitWindow),
		)
		if err != nil {
			t.Fatalf("NewPendingOperation() error = %v", err)
		}
		store.seed(t, receipt)
		service := mustOperationService(t, store, ring, now)
		assertReplayMismatch(t, service, request)
	})

	t.Run("unavailable HMAC key version", func(t *testing.T) {
		now := testServerNow()
		store := newMutexOperationStore()
		request := validBeginRequest(t)
		oldRing, err := NewHMACKeyRing(HMACKeyConfig{Version: 1, Secret: testSecret('o')})
		if err != nil {
			t.Fatalf("NewHMACKeyRing(old) error = %v", err)
		}
		oldMAC, err := oldRing.Sign(request.Kind, request.Target)
		if err != nil {
			t.Fatalf("oldRing.Sign() error = %v", err)
		}
		receipt, err := domain.NewPendingOperation(
			request.OperationID,
			request.SubjectID,
			request.SessionGeneration,
			request.Kind,
			request.IdempotencyKey,
			oldMAC.Bytes(),
			oldMAC.KeyVersion,
			request.SourceSurface,
			request.AcceptedPolicyRevision,
			now,
			now.Add(operationHardCommitWindow),
		)
		if err != nil {
			t.Fatalf("NewPendingOperation() error = %v", err)
		}
		store.seed(t, receipt)
		currentRing, err := NewHMACKeyRing(HMACKeyConfig{Version: 2, Secret: testSecret('n')})
		if err != nil {
			t.Fatalf("NewHMACKeyRing(current) error = %v", err)
		}
		service := mustOperationService(t, store, currentRing, now)
		assertReplayMismatch(t, service, request)
	})
}

func TestServiceBeginAcceptsOverlappingVerificationKey(t *testing.T) {
	t.Parallel()

	now := testServerNow()
	store := newMutexOperationStore()
	request := validBeginRequest(t)
	oldConfig := HMACKeyConfig{Version: 1, Secret: testSecret('o')}
	newConfig := HMACKeyConfig{Version: 2, Secret: testSecret('n')}
	oldRing, err := NewHMACKeyRing(oldConfig)
	if err != nil {
		t.Fatalf("NewHMACKeyRing(old) error = %v", err)
	}
	oldService := mustOperationService(t, store, oldRing, now)
	accepted := mustBegin(t, oldService, request)

	rotatedRing, err := NewHMACKeyRing(newConfig, oldConfig)
	if err != nil {
		t.Fatalf("NewHMACKeyRing(rotated) error = %v", err)
	}
	rotatedService := mustOperationService(t, store, rotatedRing, now.Add(time.Second))
	replayed, err := rotatedService.Begin(context.Background(), request)
	if err != nil {
		t.Fatalf("Begin(after rotation) error = %v", err)
	}
	if replayed.Outcome != BeginOutcomeExistingPending || replayed.Receipt != accepted.Receipt {
		t.Fatalf("rotated replay outcome/receipt = %q/%p, want existing %p", replayed.Outcome, replayed.Receipt, accepted.Receipt)
	}
	if replayed.Receipt.RequestHMACKeyVersion() != oldConfig.Version || rotatedRing.CurrentVersion() != newConfig.Version {
		t.Fatalf("receipt/current key versions = %d/%d, want %d/%d", replayed.Receipt.RequestHMACKeyVersion(), rotatedRing.CurrentVersion(), oldConfig.Version, newConfig.Version)
	}
}

func TestServiceBeginSimultaneousSameKeyConverges(t *testing.T) {
	const workers = 32

	now := testServerNow()
	store := newMutexOperationStore()
	service := mustOperationService(t, store, mustOperationKeyRing(t), now)
	request := validBeginRequest(t)
	start := make(chan struct{})
	results := make(chan BeginResult, workers)
	errorsFound := make(chan error, workers)

	var waitGroup sync.WaitGroup
	waitGroup.Add(workers)
	for range workers {
		go func() {
			defer waitGroup.Done()
			<-start
			result, err := service.Begin(context.Background(), request)
			if err != nil {
				errorsFound <- err
				return
			}
			results <- result
		}()
	}

	close(start)
	waitGroup.Wait()
	close(results)
	close(errorsFound)
	for err := range errorsFound {
		t.Errorf("concurrent Begin() error = %v", err)
	}

	newlyAccepted := 0
	existingPending := 0
	var convergedReceipt *domain.SavedOperation
	for result := range results {
		switch result.Outcome {
		case BeginOutcomeNewlyAcceptedPending:
			newlyAccepted++
		case BeginOutcomeExistingPending:
			existingPending++
		default:
			t.Errorf("concurrent Begin() outcome = %q", result.Outcome)
		}
		if convergedReceipt == nil {
			convergedReceipt = result.Receipt
		} else if result.Receipt != convergedReceipt {
			t.Error("concurrent Begin() calls returned different receipts")
		}
	}
	if newlyAccepted != 1 || existingPending != workers-1 {
		t.Fatalf("concurrent outcomes new/existing = %d/%d, want 1/%d", newlyAccepted, existingPending, workers-1)
	}
	if calls, created := store.stats(); calls != workers || created != 1 {
		t.Fatalf("store calls/creates = %d/%d, want %d/1", calls, created, workers)
	}
}

func TestServiceBeginPreservesOwnerAndSessionIsolation(t *testing.T) {
	t.Parallel()

	now := testServerNow()
	store := newMutexOperationStore()
	service := mustOperationService(t, store, mustOperationKeyRing(t), now)
	first := validBeginRequest(t)
	otherOwner := first
	otherOwner.SubjectID = uuid.MustParse("00000000-0000-0000-0000-000000000021")
	otherSession := first
	otherSession.SessionGeneration = uuid.MustParse("00000000-0000-0000-0000-000000000022")

	for _, request := range []BeginRequest{first, otherOwner, otherSession} {
		result := mustBegin(t, service, request)
		if result.Outcome != BeginOutcomeNewlyAcceptedPending {
			t.Fatalf("isolated Begin() outcome = %q, want newly accepted", result.Outcome)
		}
	}
	replay := mustBegin(t, service, first)
	if replay.Outcome != BeginOutcomeExistingPending {
		t.Fatalf("first owner/session replay outcome = %q, want existing", replay.Outcome)
	}
	if calls, created := store.stats(); calls != 4 || created != 3 {
		t.Fatalf("store calls/creates = %d/%d, want 4/3", calls, created)
	}
}

func TestServiceDoesNotRetainRawTargetOrCanonicalRequest(t *testing.T) {
	t.Parallel()

	now := testServerNow()
	store := newMutexOperationStore()
	service := mustOperationService(t, store, mustOperationKeyRing(t), now)
	request := validBeginRequest(t)
	rawTarget := "sensitive|target:with/delimiters/and/a/long/opaque/identifier"
	request.Target = mustSavedTarget(t, domain.EntityTypeActivity, rawTarget)

	result := mustBegin(t, service, request)
	stored := store.lastReceipt()
	if stored != result.Receipt {
		t.Fatal("store did not retain only the returned domain receipt")
	}
	if bytes.Contains(stored.SemanticRequestHMAC(), []byte(rawTarget)) {
		t.Fatal("stored semantic HMAC contains the raw target")
	}

	receiptValue := reflect.ValueOf(stored).Elem()
	for index := range receiptValue.NumField() {
		field := receiptValue.Field(index)
		if field.Kind() == reflect.String && strings.Contains(field.String(), rawTarget) {
			t.Fatalf("domain receipt field %q retained the raw target", receiptValue.Type().Field(index).Name)
		}
	}

	serviceType := reflect.TypeOf(*service)
	savedTargetType := reflect.TypeOf(domain.SavedTarget{})
	beginRequestType := reflect.TypeOf(BeginRequest{})
	for index := range serviceType.NumField() {
		fieldType := serviceType.Field(index).Type
		if fieldType == savedTargetType || fieldType == beginRequestType {
			t.Fatalf("Service field %q retains semantic request data", serviceType.Field(index).Name)
		}
	}
}

func newServiceScenario(t testing.TB) (*Service, *mutexOperationStore, BeginRequest) {
	t.Helper()
	store := newMutexOperationStore()
	service := mustOperationService(t, store, mustOperationKeyRing(t), testServerNow())
	return service, store, validBeginRequest(t)
}

func mustBegin(t testing.TB, service *Service, request BeginRequest) BeginResult {
	t.Helper()
	result, err := service.Begin(context.Background(), request)
	if err != nil {
		t.Fatalf("Begin() error = %v", err)
	}
	return result
}

func assertReplayMismatch(t testing.TB, service *Service, request BeginRequest) {
	t.Helper()
	_, err := service.Begin(context.Background(), request)
	if !errors.Is(err, domain.ErrReplayMismatch) {
		t.Fatalf("Begin() error = %v, want %v", err, domain.ErrReplayMismatch)
	}
}

func mustOperationService(t testing.TB, store OperationStore, ring *HMACKeyRing, now time.Time) *Service {
	t.Helper()
	service, err := NewService(store, ring, ClockFunc(func() time.Time { return now }))
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	return service
}

func mustOperationKeyRing(t testing.TB) *HMACKeyRing {
	t.Helper()
	ring, err := NewHMACKeyRing(HMACKeyConfig{Version: 11, Secret: testSecret('k')})
	if err != nil {
		t.Fatalf("NewHMACKeyRing() error = %v", err)
	}
	return ring
}

func validBeginRequest(t testing.TB) BeginRequest {
	t.Helper()
	return BeginRequest{
		OperationID:            uuid.MustParse("00000000-0000-4000-8000-000000000011"),
		SubjectID:              uuid.MustParse("00000000-0000-0000-0000-000000000012"),
		SessionGeneration:      uuid.MustParse("00000000-0000-0000-0000-000000000013"),
		Kind:                   domain.OperationKindSave,
		IdempotencyKey:         "0123456789abcdefghijklmnopqrstuv",
		Target:                 mustSavedTarget(t, domain.EntityTypeActivity, "activity|source:42"),
		SourceSurface:          domain.SourceSurfaceCard,
		AcceptedPolicyRevision: 7,
	}
}

func testServerNow() time.Time {
	return time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
}

type scopedOperationIdentity struct {
	subjectID         uuid.UUID
	sessionGeneration uuid.UUID
	operationID       uuid.UUID
}

type scopedIdempotencyIdentity struct {
	subjectID         uuid.UUID
	sessionGeneration uuid.UUID
	idempotencyKey    string
}

type mutexOperationStore struct {
	mu            sync.Mutex
	byOperation   map[scopedOperationIdentity]*domain.SavedOperation
	byIdempotency map[scopedIdempotencyIdentity]*domain.SavedOperation
	calls         int
	created       int
	last          *domain.SavedOperation
}

func newMutexOperationStore() *mutexOperationStore {
	return &mutexOperationStore{
		byOperation:   make(map[scopedOperationIdentity]*domain.SavedOperation),
		byIdempotency: make(map[scopedIdempotencyIdentity]*domain.SavedOperation),
	}
}

func (s *mutexOperationStore) CreateOrFind(ctx context.Context, pending *domain.SavedOperation) (CreateOrFindResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.calls++

	if err := ctx.Err(); err != nil {
		return CreateOrFindResult{}, err
	}
	if pending == nil {
		return CreateOrFindResult{}, ErrOperationStoreInvariant
	}

	operationIdentity := operationIdentityOf(pending)
	if existing := s.byOperation[operationIdentity]; existing != nil {
		s.last = existing
		return CreateOrFindResult{Receipt: existing}, nil
	}
	idempotencyIdentity := idempotencyIdentityOf(pending)
	if existing := s.byIdempotency[idempotencyIdentity]; existing != nil {
		s.last = existing
		return CreateOrFindResult{Receipt: existing}, nil
	}

	s.byOperation[operationIdentity] = pending
	s.byIdempotency[idempotencyIdentity] = pending
	s.created++
	s.last = pending
	return CreateOrFindResult{Receipt: pending, Created: true}, nil
}

func (s *mutexOperationStore) seed(t testing.TB, receipt *domain.SavedOperation) {
	t.Helper()
	s.mu.Lock()
	defer s.mu.Unlock()

	operationIdentity := operationIdentityOf(receipt)
	idempotencyIdentity := idempotencyIdentityOf(receipt)
	if s.byOperation[operationIdentity] != nil || s.byIdempotency[idempotencyIdentity] != nil {
		t.Fatal("seed receipt collides with an existing fake-store identity")
	}
	s.byOperation[operationIdentity] = receipt
	s.byIdempotency[idempotencyIdentity] = receipt
}

func (s *mutexOperationStore) stats() (calls int, created int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.calls, s.created
}

func (s *mutexOperationStore) lastReceipt() *domain.SavedOperation {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.last
}

func operationIdentityOf(receipt *domain.SavedOperation) scopedOperationIdentity {
	return scopedOperationIdentity{
		subjectID:         receipt.SubjectID(),
		sessionGeneration: receipt.SessionGeneration(),
		operationID:       receipt.OperationID(),
	}
}

func idempotencyIdentityOf(receipt *domain.SavedOperation) scopedIdempotencyIdentity {
	return scopedIdempotencyIdentity{
		subjectID:         receipt.SubjectID(),
		sessionGeneration: receipt.SessionGeneration(),
		idempotencyKey:    receipt.IdempotencyKey(),
	}
}
