package saveditem

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/operation"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestServiceSaveExecutesAcceptedOperationOnce(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newServicePendingReceipt(t, now, domain.OperationKindSave)
	beginner := &stubOperationBeginner{result: operation.BeginResult{
		Receipt: receipt,
		Outcome: operation.BeginOutcomeNewlyAcceptedPending,
	}}
	repository := &stubSavedItemRepository{prepareResult: receipt, saveResult: receipt}
	resolver := &stubSourceResolver{resolution: publicServiceResolution(now)}
	sessionValidator := &stubSessionValidator{valid: true}
	policy := &stubPolicyGate{grant: PolicyGrant{Revision: 7}}
	service := newServiceForTest(t, beginner, repository, resolver, sessionValidator, policy, now)

	result, err := service.Save(context.Background(), serviceMutationRequest())
	if err != nil {
		t.Fatalf("Save() error = %v", err)
	}
	if result != receipt || repository.prepareCalls != 1 || repository.saveCalls != 1 || resolver.calls != 1 || sessionValidator.calls != 1 {
		t.Fatalf("result/calls = %p prepare=%d save=%d source=%d session=%d", result, repository.prepareCalls, repository.saveCalls, resolver.calls, sessionValidator.calls)
	}
	if policy.guardCalls != 1 || policy.validateCalls != 1 || policy.minimumRevision != 7 {
		t.Fatalf("policy = %#v", policy)
	}
	command := repository.saveCommand
	if command.OwnerUserID != serviceMutationRequest().OwnerUserID || command.MaxActiveSaves != 123 ||
		command.Projection.SourceService != "activity-service" ||
		command.Projection.VisibilityRevision != 13 ||
		command.Identity.OperationID != receipt.OperationID() {
		t.Fatalf("save command = %#v", command)
	}
	if command.Projection.NormalizedSearchDocument.RU == nil ||
		*command.Projection.NormalizedSearchDocument.RU != "прогулка алматы казахстан" {
		t.Fatalf("RU search document = %#v", command.Projection.NormalizedSearchDocument.RU)
	}
	if repository.prepareCommand.Target != serviceMutationRequest().Target ||
		repository.prepareCommand.SourceService != "activity-service" ||
		!repository.prepareCommand.ShellExpiresAt.After(receipt.CommitDeadline()) {
		t.Fatalf("prepare command = %#v", repository.prepareCommand)
	}
}

func TestServiceSaveDoesNotRepeatSourceRPCForExistingReceipt(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	for _, outcome := range []operation.BeginOutcome{
		operation.BeginOutcomeExistingPending,
		operation.BeginOutcomeTerminalReplay,
	} {
		receipt := newServicePendingReceipt(t, now, domain.OperationKindSave)
		if outcome == operation.BeginOutcomeTerminalReplay {
			if err := receipt.Succeed(now.Add(time.Second), domain.OperationOutcomeNoOp, domain.RefreshScopeSavedItems, domain.OperationVersionEffects{}); err != nil {
				t.Fatalf("Succeed() error = %v", err)
			}
		}
		beginner := &stubOperationBeginner{result: operation.BeginResult{Receipt: receipt, Outcome: outcome}}
		repository := &stubSavedItemRepository{}
		resolver := &stubSourceResolver{}
		sessionValidator := &stubSessionValidator{}
		policy := &stubPolicyGate{grant: PolicyGrant{Revision: 9}}
		service := newServiceForTest(t, beginner, repository, resolver, sessionValidator, policy, now)

		result, err := service.Save(context.Background(), serviceMutationRequest())
		if err != nil || result != receipt {
			t.Fatalf("outcome %s result=%p error=%v", outcome, result, err)
		}
		if resolver.calls != 0 || sessionValidator.calls != 0 || policy.validateCalls != 0 || repository.saveCalls != 0 {
			t.Fatalf("outcome %s executed work: source=%d session=%d policy=%d save=%d", outcome, resolver.calls, sessionValidator.calls, policy.validateCalls, repository.saveCalls)
		}
	}
}

func TestServiceDisabledExpansionPersistsRejectionWithoutSourceWork(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newServicePendingReceipt(t, now, domain.OperationKindSave)
	repository := &stubSavedItemRepository{rejectResult: receipt}
	service := newServiceForTest(
		t,
		&stubOperationBeginner{result: operation.BeginResult{
			Receipt: receipt,
			Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		&stubSourceResolver{},
		&stubSessionValidator{valid: true},
		&stubPolicyGate{grant: PolicyGrant{Revision: 7}},
		now,
		true,
	)

	result, err := service.Save(context.Background(), serviceMutationRequest())
	if err != nil || result != receipt {
		t.Fatalf("Save() = (%p, %v)", result, err)
	}
	if repository.rejectCalls != 1 || repository.prepareCalls != 0 ||
		repository.saveCalls != 0 ||
		repository.rejectCommand.Cause.Code != domain.ErrorCodeTargetUnavailable ||
		repository.rejectCommand.RefreshScope != domain.RefreshScopeNone {
		t.Fatalf("repository = %#v", repository)
	}
}

func TestServiceSavePersistsSourceDenial(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newServicePendingReceipt(t, now, domain.OperationKindSave)
	repository := &stubSavedItemRepository{prepareResult: receipt, rejectResult: receipt}
	resolver := &stubSourceResolver{resolution: appsource.Resolution{
		Target:      serviceMutationRequest().Target,
		Eligible:    false,
		Visibility:  domain.VisibilityPrivate,
		Revisions:   appsource.Revisions{Source: 1, Projection: 1, Visibility: 2},
		ValidatedAt: now,
	}}
	service := newServiceForTest(
		t,
		&stubOperationBeginner{result: operation.BeginResult{Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending}},
		repository,
		resolver,
		&stubSessionValidator{valid: true},
		&stubPolicyGate{grant: PolicyGrant{Revision: 7}},
		now,
	)

	result, err := service.Save(context.Background(), serviceMutationRequest())
	if err != nil || result != receipt {
		t.Fatalf("Save() result=%p error=%v", result, err)
	}
	if repository.rejectCalls != 1 || repository.rejectCommand.Cause.Code != domain.ErrorCodeTargetUnavailable ||
		repository.saveCalls != 0 {
		t.Fatalf("repository = %#v", repository)
	}
}

func TestServiceSaveRejectsBlockedUserBeforeProjectionWork(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	request := serviceMutationRequest()
	blockedUserID := uuid.New()
	request.Target, _ = domain.NewSavedTarget(domain.EntityTypeUser, blockedUserID.String())
	receipt := newServicePendingReceipt(t, now, domain.OperationKindSave)
	repository := &stubSavedItemRepository{rejectResult: receipt}
	resolver := &stubSourceResolver{}
	accessPolicy := &stubUserAccessPolicy{
		denied: map[uuid.UUID]struct{}{blockedUserID: {}},
	}
	service := newServiceForTest(
		t,
		&stubOperationBeginner{result: operation.BeginResult{
			Receipt: receipt,
			Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		resolver,
		&stubSessionValidator{valid: true},
		&stubPolicyGate{grant: PolicyGrant{Revision: 7}},
		now,
	)
	service.userAccessPolicy = accessPolicy

	result, err := service.Save(context.Background(), request)
	if err != nil || result != receipt {
		t.Fatalf("Save(blocked USER) = (%p, %v)", result, err)
	}
	if accessPolicy.calls != 1 || resolver.calls != 0 || repository.prepareCalls != 0 ||
		repository.saveCalls != 0 || repository.rejectCalls != 1 {
		t.Fatalf(
			"access/source/prepare/save/reject = %d/%d/%d/%d/%d",
			accessPolicy.calls,
			resolver.calls,
			repository.prepareCalls,
			repository.saveCalls,
			repository.rejectCalls,
		)
	}
	if repository.rejectCommand.Cause.Code != domain.ErrorCodeTargetUnavailable ||
		repository.rejectCommand.RefreshScope != domain.RefreshScopeSavedItems {
		t.Fatalf("rejection = %+v", repository.rejectCommand)
	}
}

func TestServiceGlobalUnsaveIsSourceIndependentAndSurvivesACKLoss(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	receipt := newServicePendingReceipt(t, now, domain.OperationKindUnsave)
	parent, cancelParent := context.WithCancel(context.Background())
	beginner := &stubOperationBeginner{
		result: operation.BeginResult{Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending},
		after:  cancelParent,
	}
	repository := &stubSavedItemRepository{unsaveResult: receipt}
	resolver := &stubSourceResolver{}
	sessionValidator := &stubSessionValidator{valid: true}
	service := newServiceForTest(
		t,
		beginner,
		repository,
		resolver,
		sessionValidator,
		&stubPolicyGate{grant: PolicyGrant{Revision: 7}},
		now,
	)

	result, err := service.GlobalUnsave(parent, serviceMutationRequest())
	if err != nil || result != receipt {
		t.Fatalf("GlobalUnsave() result=%p error=%v", result, err)
	}
	if resolver.calls != 0 || repository.unsaveCalls != 1 || sessionValidator.contextErr != nil || repository.unsaveContextErr != nil {
		t.Fatalf("calls/context: source=%d unsave=%d session=%v repo=%v", resolver.calls, repository.unsaveCalls, sessionValidator.contextErr, repository.unsaveContextErr)
	}
	if repository.unsaveCommand.Target != serviceMutationRequest().Target ||
		repository.unsaveCommand.RemovedOutboxEventID.Version() != 4 {
		t.Fatalf("unsave command = %#v", repository.unsaveCommand)
	}
}

func TestServiceGlobalUnsaveDoesNotConsultUserAccessPolicy(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	request := serviceMutationRequest()
	request.Target, _ = domain.NewSavedTarget(domain.EntityTypeUser, uuid.NewString())
	receipt := newServicePendingReceipt(t, now, domain.OperationKindUnsave)
	repository := &stubSavedItemRepository{unsaveResult: receipt}
	service := newServiceForTest(
		t,
		&stubOperationBeginner{result: operation.BeginResult{
			Receipt: receipt,
			Outcome: operation.BeginOutcomeNewlyAcceptedPending,
		}},
		repository,
		&stubSourceResolver{},
		&stubSessionValidator{valid: true},
		&stubPolicyGate{grant: PolicyGrant{Revision: 7}},
		now,
	)
	accessPolicy := &stubUserAccessPolicy{err: context.DeadlineExceeded}
	service.userAccessPolicy = accessPolicy

	result, err := service.GlobalUnsave(context.Background(), request)
	if err != nil || result != receipt {
		t.Fatalf("GlobalUnsave(USER) = (%p, %v)", result, err)
	}
	if accessPolicy.calls != 0 || repository.unsaveCalls != 1 {
		t.Fatalf("access/unsave calls = %d/%d", accessPolicy.calls, repository.unsaveCalls)
	}
}

func TestServiceRejectsWhenSessionWasRevokedBeforeCommit(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newServicePendingReceipt(t, now, domain.OperationKindUnsave)
	repository := &stubSavedItemRepository{rejectResult: receipt}
	service := newServiceForTest(
		t,
		&stubOperationBeginner{result: operation.BeginResult{Receipt: receipt, Outcome: operation.BeginOutcomeNewlyAcceptedPending}},
		repository,
		&stubSourceResolver{},
		&stubSessionValidator{valid: false},
		&stubPolicyGate{grant: PolicyGrant{Revision: 7}},
		now,
	)

	_, err := service.GlobalUnsave(context.Background(), serviceMutationRequest())
	if err != nil {
		t.Fatalf("GlobalUnsave() error = %v", err)
	}
	if repository.rejectCalls != 1 || repository.rejectCommand.Cause.Code != domain.ErrorCodeMutationStale ||
		repository.rejectCommand.RefreshScope != domain.RefreshScopeBoth || repository.unsaveCalls != 0 {
		t.Fatalf("repository = %#v", repository)
	}
}

func TestServiceMapsUnknownPolicyFailureFailClosed(t *testing.T) {
	t.Parallel()

	service := newServiceForTest(
		t,
		&stubOperationBeginner{},
		&stubSavedItemRepository{},
		&stubSourceResolver{},
		&stubSessionValidator{},
		&stubPolicyGate{guardErr: context.DeadlineExceeded},
		time.Now().UTC(),
	)
	_, err := service.Save(context.Background(), serviceMutationRequest())
	if err != domain.ErrDependencyUnavailable {
		t.Fatalf("Save() error = %v", err)
	}
}

func TestProjectionSnapshotUsesClosedSourceMatrixAndUnicodeNormalization(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	resolution := publicServiceResolution(now)
	localized := resolution.PublicProjection.Localized[appsource.LocaleEN]
	localized.Title = "  Fullwidth is rejected upstream  "
	resolution.PublicProjection.Localized[appsource.LocaleEN] = localized
	if _, err := projectionSnapshot(resolution, now, now.Add(10*time.Second)); err == nil {
		t.Fatal("projectionSnapshot() accepted untrimmed source payload")
	}

	resolution = publicServiceResolution(now)
	localized = resolution.PublicProjection.Localized[appsource.LocaleEN]
	localized.Title = "ＦｌｙＦｙ　CITY"
	resolution.PublicProjection.Localized[appsource.LocaleEN] = localized
	snapshot, err := projectionSnapshot(resolution, now, now.Add(10*time.Second))
	if err != nil {
		t.Fatalf("projectionSnapshot() error = %v", err)
	}
	if snapshot.NormalizedSearchDocument.EN == nil ||
		!strings.HasPrefix(*snapshot.NormalizedSearchDocument.EN, "flyfy city") {
		t.Fatalf("normalized EN = %#v", snapshot.NormalizedSearchDocument.EN)
	}
	if sourceServiceFor(domain.EntityType("EXCURSION")) != "" {
		t.Fatal("retired excursion type received a source-service mapping")
	}
}

func newServiceForTest(
	t *testing.T,
	beginner OperationBeginner,
	repository Repository,
	resolver appsource.Resolver,
	sessionValidator *stubSessionValidator,
	policy PolicyGate,
	now time.Time,
	disableExpansion ...bool,
) *Service {
	t.Helper()
	service, err := NewService(ServiceConfig{
		OperationBeginner: beginner,
		Repository:        repository,
		SourceResolver:    resolver,
		SessionValidator:  sessionValidator,
		PolicyGate:        policy,
		Clock:             fixedServiceClock{now: now},
		UUIDGenerator:     &sequenceUUIDGenerator{},
		MaxActiveSaves:    123,
		DisableExpansion:  len(disableExpansion) > 0 && disableExpansion[0],
	})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	return service
}

func newServicePendingReceipt(t *testing.T, now time.Time, kind domain.OperationKind) *domain.SavedOperation {
	t.Helper()
	receipt, err := domain.NewPendingOperation(
		serviceMutationRequest().OperationID,
		serviceMutationRequest().SubjectID,
		serviceMutationRequest().SessionGeneration,
		kind,
		serviceMutationRequest().IdempotencyKey,
		[]byte(strings.Repeat("h", 32)),
		1,
		serviceMutationRequest().SourceSurface,
		7,
		now,
		now.Add(10*time.Second),
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	return receipt
}

func serviceMutationRequest() TargetMutationRequest {
	target, _ := domain.NewSavedTarget(domain.EntityTypeActivity, "99999999-9999-4999-8999-999999999999")
	return TargetMutationRequest{
		SubjectID:         uuid.MustParse("11111111-1111-4111-8111-111111111111"),
		OwnerUserID:       uuid.MustParse("22222222-2222-4222-8222-222222222222"),
		SessionGeneration: uuid.MustParse("33333333-3333-4333-8333-333333333333"),
		OperationID:       uuid.MustParse("44444444-4444-4444-8444-444444444444"),
		IdempotencyKey:    "0123456789abcdefghijklmnopqrstuv",
		Target:            target,
		SourceSurface:     domain.SourceSurfaceDetail,
	}
}

func publicServiceResolution(now time.Time) appsource.Resolution {
	return appsource.Resolution{
		Target:      serviceMutationRequest().Target,
		Eligible:    true,
		Visibility:  domain.VisibilityPublic,
		Revisions:   appsource.Revisions{Source: 11, Projection: 12, Visibility: 13},
		ValidatedAt: now,
		PublicProjection: &appsource.PublicCardProjection{
			SourceDefaultLocale: appsource.LocaleRU,
			Localized: map[appsource.Locale]appsource.LocalizedCardProjection{
				appsource.LocaleEN: {Title: "Walk", City: "Almaty", Country: "Kazakhstan"},
				appsource.LocaleRU: {Title: "Прогулка", City: "Алматы", Country: "Казахстан"},
				appsource.LocaleKK: {Title: "Серуен", City: "Алматы", Country: "Қазақстан"},
			},
			CanonicalDetailRoute: "/activities/99999999-9999-4999-8999-999999999999",
		},
	}
}

type stubOperationBeginner struct {
	result  operation.BeginResult
	err     error
	request operation.BeginRequest
	calls   int
	after   func()
}

func (s *stubOperationBeginner) Begin(_ context.Context, request operation.BeginRequest) (operation.BeginResult, error) {
	s.calls++
	s.request = request
	if s.after != nil {
		s.after()
	}
	return s.result, s.err
}

type stubSavedItemRepository struct {
	prepareResult    *domain.SavedOperation
	saveResult       *domain.SavedOperation
	unsaveResult     *domain.SavedOperation
	rejectResult     *domain.SavedOperation
	prepareErr       error
	saveErr          error
	unsaveErr        error
	rejectErr        error
	prepareCommand   PrepareProjectionShellCommand
	saveCommand      SaveCommand
	unsaveCommand    GlobalUnsaveCommand
	rejectCommand    RejectPendingCommand
	prepareCalls     int
	saveCalls        int
	unsaveCalls      int
	rejectCalls      int
	unsaveContextErr error
}

func (s *stubSavedItemRepository) PrepareProjectionShell(
	_ context.Context,
	command PrepareProjectionShellCommand,
) (*domain.SavedOperation, error) {
	s.prepareCalls++
	s.prepareCommand = command
	return s.prepareResult, s.prepareErr
}

func (s *stubSavedItemRepository) Save(ctx context.Context, command SaveCommand) (*domain.SavedOperation, error) {
	s.saveCalls++
	s.saveCommand = command
	return s.saveResult, s.saveErr
}

func (s *stubSavedItemRepository) GlobalUnsave(ctx context.Context, command GlobalUnsaveCommand) (*domain.SavedOperation, error) {
	s.unsaveCalls++
	s.unsaveContextErr = ctx.Err()
	s.unsaveCommand = command
	return s.unsaveResult, s.unsaveErr
}

func (s *stubSavedItemRepository) RejectPending(_ context.Context, command RejectPendingCommand) (*domain.SavedOperation, error) {
	s.rejectCalls++
	s.rejectCommand = command
	return s.rejectResult, s.rejectErr
}

func (s *stubSavedItemRepository) GetOperation(context.Context, OperationLookup) (*domain.SavedOperation, error) {
	return nil, ErrOperationNotFound
}

type stubSourceResolver struct {
	resolution appsource.Resolution
	err        error
	calls      int
}

func (s *stubSourceResolver) Resolve(_ context.Context, _ domain.SavedTarget) (appsource.Resolution, error) {
	s.calls++
	return s.resolution, s.err
}

type stubSessionValidator struct {
	valid      bool
	err        error
	calls      int
	contextErr error
}

func (s *stubSessionValidator) Validate(ctx context.Context, _, _ string) (bool, error) {
	s.calls++
	s.contextErr = ctx.Err()
	return s.valid, s.err
}

type stubPolicyGate struct {
	grant           PolicyGrant
	guardErr        error
	validateErr     error
	guardCalls      int
	validateCalls   int
	minimumRevision uint64
}

type stubUserAccessPolicy struct {
	denied map[uuid.UUID]struct{}
	err    error
	calls  int
}

func (stub *stubUserAccessPolicy) DeniedUserIDs(
	context.Context,
	uuid.UUID,
	[]uuid.UUID,
) (map[uuid.UUID]struct{}, error) {
	stub.calls++
	return stub.denied, stub.err
}

func (s *stubPolicyGate) Guard(context.Context) (PolicyGrant, error) {
	s.guardCalls++
	return s.grant, s.guardErr
}

func (s *stubPolicyGate) ValidateCommit(_ context.Context, minimum uint64) error {
	s.validateCalls++
	s.minimumRevision = minimum
	return s.validateErr
}

type fixedServiceClock struct{ now time.Time }

func (c fixedServiceClock) Now() time.Time { return c.now }

type sequenceUUIDGenerator struct{}

func (*sequenceUUIDGenerator) NewV4() uuid.UUID { return uuid.New() }

var _ OperationBeginner = (*stubOperationBeginner)(nil)
var _ Repository = (*stubSavedItemRepository)(nil)
var _ appsource.Resolver = (*stubSourceResolver)(nil)
var _ PolicyGate = (*stubPolicyGate)(nil)
