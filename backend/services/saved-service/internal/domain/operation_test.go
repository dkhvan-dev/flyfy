package domain

import (
	"errors"
	"math"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestSavedOperationTerminalTransitions(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	operation := newPendingOperation(t, now)
	version := uint64(7)
	generation := uuid.New()
	if err := operation.Succeed(now.Add(time.Second), OperationOutcomeApplied, RefreshScopeSavedItems, OperationVersionEffects{
		AppliedRelationship: &AppliedRelationshipVersion{Generation: generation, Version: version},
	}); err != nil {
		t.Fatalf("Succeed() error = %v", err)
	}
	if operation.Status() != OperationStatusSucceeded || operation.Outcome() != OperationOutcomeApplied || operation.RefreshScope() != RefreshScopeSavedItems {
		t.Fatalf("Succeed() status/scope = %q/%q", operation.Status(), operation.RefreshScope())
	}
	if got := operation.AppliedRelationshipVersion(); got == nil || *got != version {
		t.Fatalf("AppliedRelationshipVersion() = %v, want %d", got, version)
	}
	if err := operation.Reject(now.Add(2*time.Second), ErrTargetUnavailable, RefreshScopeNone); !errors.Is(err, ErrMutationStale) {
		t.Fatalf("Reject(terminal) error = %v, want stale", err)
	}
}

func TestOperationKindEligibility(t *testing.T) {
	t.Parallel()

	tests := []struct {
		kind OperationKind
		want bool
	}{
		{kind: OperationKindSave, want: true},
		{kind: OperationKindUnsave, want: false},
		{kind: OperationKindSetTargetCollections, want: true},
		{kind: OperationKindCreateCollection, want: false},
		{kind: OperationKindRenameCollection, want: false},
		{kind: OperationKindDeleteCollection, want: false},
	}

	for _, test := range tests {
		if got := test.kind.RequiresPublicEligibility(); got != test.want {
			t.Errorf("%q RequiresPublicEligibility() = %t, want %t", test.kind, got, test.want)
		}
	}
}

func TestSavedOperationDeadlineGuardAndExpiry(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	operation := newPendingOperation(t, now)

	if err := operation.GuardCommit(operation.CommitDeadline()); !errors.Is(err, ErrOperationExpired) {
		t.Fatalf("GuardCommit(deadline) error = %v, want expired", err)
	}
	if err := operation.Expire(operation.CommitDeadline().Add(time.Second)); err != nil {
		t.Fatalf("Expire() error = %v", err)
	}
	if operation.Status() != OperationStatusExpired || operation.Outcome() != OperationOutcomeExpired || operation.Failure() != nil {
		t.Fatalf("Expire() = status %q, outcome %#v", operation.Status(), operation.Outcome())
	}
	if operation.RefreshScope() != RefreshScopeSavedItems {
		t.Fatalf("Expire() refresh scope = %q, want %q", operation.RefreshScope(), RefreshScopeSavedItems)
	}
}

func TestExpiredOperationRefreshScopeMatrix(t *testing.T) {
	t.Parallel()
	tests := map[OperationKind]RefreshScope{
		OperationKindSave:                 RefreshScopeSavedItems,
		OperationKindUnsave:               RefreshScopeBoth,
		OperationKindSetTargetCollections: RefreshScopeBoth,
		OperationKindCreateCollection:     RefreshScopeCollections,
		OperationKindRenameCollection:     RefreshScopeCollections,
		OperationKindDeleteCollection:     RefreshScopeBoth,
	}
	for kind, want := range tests {
		if got := expiredOperationRefreshScope(kind); got != want {
			t.Errorf("expiredOperationRefreshScope(%q) = %q, want %q", kind, got, want)
		}
	}
}

func TestSavedOperationRejectsWithTypedOutcome(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	operation := newPendingOperation(t, now)
	if err := operation.Reject(now.Add(time.Second), ErrDependencyUnavailable, RefreshScopeNone); err != nil {
		t.Fatalf("Reject() error = %v", err)
	}

	failure := operation.Failure()
	if operation.Status() != OperationStatusRejected || operation.Outcome() != OperationOutcomeRejected || failure == nil || failure.Code != ErrorCodeDependencyUnavailable || !failure.Retryable {
		t.Fatalf("Reject() = status %q, outcome %q, failure %#v", operation.Status(), operation.Outcome(), failure)
	}
}

func TestNewPendingOperationRejectsWeakIdentityAndUnboundedDeadline(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	validKey := "0123456789abcdefghijklmnopqrstuv"
	validHMAC := make([]byte, semanticRequestHMACBytes)
	tests := []struct {
		name     string
		key      string
		hmac     []byte
		deadline time.Time
	}{
		{name: "short idempotency key", key: "too-short", hmac: validHMAC, deadline: now.Add(time.Second)},
		{name: "non-token idempotency key", key: validKey + " ", hmac: validHMAC, deadline: now.Add(time.Second)},
		{name: "malformed base64url key", key: "aaaaaaaaaaaaaaaaaaaaaaaaa", hmac: validHMAC, deadline: now.Add(time.Second)},
		{name: "non-SHA256 HMAC", key: validKey, hmac: []byte{1, 2, 3}, deadline: now.Add(time.Second)},
		{name: "deadline exceeds hard bound", key: validKey, hmac: validHMAC, deadline: now.Add(maxOperationCommitWindow + time.Nanosecond)},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := NewPendingOperation(
				uuid.New(), uuid.New(), uuid.New(), OperationKindSave,
				test.key, test.hmac, 1, SourceSurfaceCard, 7, now, test.deadline,
			)
			if !errors.Is(err, ErrMutationStale) {
				t.Fatalf("NewPendingOperation() error = %v, want mutation stale", err)
			}
		})
	}

	_, err := NewPendingOperation(
		uuid.MustParse("00000000-0000-1000-8000-000000000011"), uuid.New(), uuid.New(), OperationKindSave,
		validKey, validHMAC, 1, SourceSurfaceCard, 7, now, now.Add(time.Second),
	)
	if !errors.Is(err, ErrMutationStale) {
		t.Fatalf("NewPendingOperation(non-v4 ID) error = %v, want mutation stale", err)
	}

	_, err = NewPendingOperation(
		uuid.New(), uuid.New(), uuid.New(), OperationKindSave,
		validKey, validHMAC, 1, SourceSurfaceCard, 0, now, now.Add(time.Second),
	)
	if !errors.Is(err, ErrMutationStale) {
		t.Fatalf("NewPendingOperation(zero policy revision) error = %v, want mutation stale", err)
	}

	_, err = NewPendingOperation(
		uuid.New(), uuid.New(), uuid.New(), OperationKindSave,
		validKey, validHMAC, math.MaxInt32+1, SourceSurfaceCard, 7, now, now.Add(time.Second),
	)
	if !errors.Is(err, ErrMutationStale) {
		t.Fatalf("NewPendingOperation(key version overflow) error = %v, want mutation stale", err)
	}

	_, err = NewPendingOperation(
		uuid.New(), uuid.New(), uuid.New(), OperationKindSave,
		validKey, validHMAC, 1, SourceSurfaceCard, math.MaxInt64+1, now, now.Add(time.Second),
	)
	if !errors.Is(err, ErrMutationStale) {
		t.Fatalf("NewPendingOperation(policy revision overflow) error = %v, want mutation stale", err)
	}
}

func TestSavedOperationRejectsVersionOverflow(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	operation := newPendingOperation(t, now)
	overflow := uint64(math.MaxInt64) + 1
	if err := operation.Succeed(now.Add(time.Second), OperationOutcomeApplied, RefreshScopeSavedItems, OperationVersionEffects{
		AppliedUserUsageVersion: &overflow,
	}); !errors.Is(err, ErrMutationStale) {
		t.Fatalf("Succeed(version overflow) error = %v, want mutation stale", err)
	}
}

func newPendingOperation(t *testing.T, now time.Time) *SavedOperation {
	t.Helper()
	operation, err := NewPendingOperation(
		uuid.MustParse("00000000-0000-4000-8000-000000000011"),
		uuid.MustParse("00000000-0000-0000-0000-000000000012"),
		uuid.MustParse("00000000-0000-0000-0000-000000000013"),
		OperationKindSave,
		"0123456789abcdefghijklmnopqrstuv",
		make([]byte, semanticRequestHMACBytes),
		1,
		SourceSurfaceCard,
		7,
		now,
		now.Add(10*time.Second),
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	return operation
}
