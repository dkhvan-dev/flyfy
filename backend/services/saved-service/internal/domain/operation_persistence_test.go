package domain

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestRestoreOperationRoundTripsPendingAndTerminalReceipts(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	tests := []struct {
		name       string
		transition func(*SavedOperation) error
	}{
		{name: "pending", transition: func(*SavedOperation) error { return nil }},
		{
			name: "applied",
			transition: func(operation *SavedOperation) error {
				observed := uint64(6)
				usage := uint64(9)
				return operation.Succeed(now.Add(time.Second), OperationOutcomeApplied, RefreshScopeSavedItems, OperationVersionEffects{
					ObservedRelationshipVersion: &observed,
					AppliedRelationship: &AppliedRelationshipVersion{
						Generation: uuid.MustParse("00000000-0000-0000-0000-000000000099"),
						Version:    7,
					},
					AppliedUserUsageVersion: &usage,
				})
			},
		},
		{
			name: "rejected",
			transition: func(operation *SavedOperation) error {
				return operation.Reject(now.Add(time.Second), ErrDependencyUnavailable, RefreshScopeNone)
			},
		},
		{
			name: "expired",
			transition: func(operation *SavedOperation) error {
				return operation.Expire(operation.CommitDeadline())
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			original := newPendingOperation(t, now)
			if err := test.transition(original); err != nil {
				t.Fatalf("transition error = %v", err)
			}

			restored, err := RestoreOperation(original.PersistenceState())
			if err != nil {
				t.Fatalf("RestoreOperation() error = %v", err)
			}
			assertSameOperationState(t, restored.PersistenceState(), original.PersistenceState())
		})
	}
}

func TestRestoreOperationRoundTripsCollectionVersionEffects(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	operation := newPendingOperationOfKind(t, now, OperationKindSetTargetCollections)
	observedRelationship := uint64(4)
	observedMembership := uint64(8)
	appliedMembership := uint64(9)
	if err := operation.Succeed(now.Add(time.Second), OperationOutcomeApplied, RefreshScopeBoth, OperationVersionEffects{
		ObservedRelationshipVersion:        &observedRelationship,
		ObservedDependentMembershipVersion: &observedMembership,
		AppliedRelationship: &AppliedRelationshipVersion{
			Generation: uuid.MustParse("00000000-0000-0000-0000-000000000099"),
			Version:    5,
		},
		AppliedDependentMembershipVersion: &appliedMembership,
		AppliedCollection: &AppliedCollectionVersion{
			CollectionID:     uuid.MustParse("00000000-0000-0000-0000-000000000098"),
			MetadataVersion:  1,
			LifecycleVersion: 1,
		},
	}); err != nil {
		t.Fatalf("Succeed() error = %v", err)
	}

	restored, err := RestoreOperation(operation.PersistenceState())
	if err != nil {
		t.Fatalf("RestoreOperation() error = %v", err)
	}
	assertSameOperationState(t, restored.PersistenceState(), operation.PersistenceState())
}

func TestRestoreOperationRejectsImpossibleLifecycle(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	base := newPendingOperation(t, now).PersistenceState()
	tests := []struct {
		name   string
		mutate func(*PersistedOperation)
	}{
		{
			name: "pending with terminal timestamp",
			mutate: func(state *PersistedOperation) {
				state.CompletedAt = timePointer(now.Add(time.Second))
			},
		},
		{
			name: "success missing exact retention",
			mutate: func(state *PersistedOperation) {
				state.Status = OperationStatusSucceeded
				state.Outcome = OperationOutcomeNoOp
				state.CompletedAt = timePointer(now.Add(time.Second))
				state.RetentionExpiresAt = timePointer(now.Add(13 * 24 * time.Hour))
			},
		},
		{
			name: "rejected without failure",
			mutate: func(state *PersistedOperation) {
				completed := now.Add(time.Second)
				state.Status = OperationStatusRejected
				state.Outcome = OperationOutcomeRejected
				state.CompletedAt = &completed
				state.RetentionExpiresAt = timePointer(completed.Add(operationRetentionWindow))
			},
		},
		{
			name: "expired before deadline",
			mutate: func(state *PersistedOperation) {
				completed := state.CommitDeadline.Add(-time.Nanosecond)
				state.Status = OperationStatusExpired
				state.Outcome = OperationOutcomeExpired
				state.CompletedAt = &completed
				state.RetentionExpiresAt = timePointer(completed.Add(operationRetentionWindow))
			},
		},
		{
			name: "applied relationship missing generation",
			mutate: func(state *PersistedOperation) {
				state.Versions.AppliedRelationship = &AppliedRelationshipVersion{Version: 1}
			},
		},
		{
			name: "collection version on target operation",
			mutate: func(state *PersistedOperation) {
				state.Versions.AppliedCollection = &AppliedCollectionVersion{
					CollectionID: uuid.New(), MetadataVersion: 1, LifecycleVersion: 1,
				}
			},
		},
		{
			name: "collection lifecycle precondition without metadata precondition",
			mutate: func(state *PersistedOperation) {
				state.Kind = OperationKindDeleteCollection
				version := uint64(1)
				state.Versions.ObservedCollectionLifecycleVersion = &version
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			state := base
			test.mutate(&state)
			if _, err := RestoreOperation(state); !errors.Is(err, ErrMutationStale) {
				t.Fatalf("RestoreOperation() error = %v, want mutation stale", err)
			}
		})
	}
}

func assertSameOperationState(t *testing.T, got, want PersistedOperation) {
	t.Helper()
	if got.OperationID != want.OperationID || got.SubjectID != want.SubjectID ||
		got.SessionGeneration != want.SessionGeneration || got.Kind != want.Kind ||
		got.IdempotencyKey != want.IdempotencyKey || got.RequestHMACKeyVersion != want.RequestHMACKeyVersion ||
		got.FirstSeenSourceSurface != want.FirstSeenSourceSurface || got.AcceptedPolicyRevision != want.AcceptedPolicyRevision ||
		got.Status != want.Status || got.Outcome != want.Outcome || got.RefreshScope != want.RefreshScope ||
		!got.CommitDeadline.Equal(want.CommitDeadline) || !got.CreatedAt.Equal(want.CreatedAt) ||
		!equalOptionalTime(got.CompletedAt, want.CompletedAt) ||
		!equalOptionalTime(got.RetentionExpiresAt, want.RetentionExpiresAt) {
		t.Fatalf("restored state differs:\n got: %#v\nwant: %#v", got, want)
	}
	if string(got.SemanticRequestHMAC) != string(want.SemanticRequestHMAC) ||
		!equalOperationFailure(got.Failure, want.Failure) ||
		!equalOptionalUint64(got.Versions.ObservedRelationshipVersion, want.Versions.ObservedRelationshipVersion) ||
		!equalOptionalUint64(got.Versions.ObservedDependentMembershipVersion, want.Versions.ObservedDependentMembershipVersion) ||
		!equalOptionalUint64(got.Versions.ObservedCollectionMetadataVersion, want.Versions.ObservedCollectionMetadataVersion) ||
		!equalOptionalUint64(got.Versions.ObservedCollectionLifecycleVersion, want.Versions.ObservedCollectionLifecycleVersion) ||
		!equalOptionalUint64(got.Versions.AppliedUserUsageVersion, want.Versions.AppliedUserUsageVersion) ||
		!equalOptionalUint64(got.Versions.AppliedDependentMembershipVersion, want.Versions.AppliedDependentMembershipVersion) ||
		!equalAppliedRelationship(got.Versions.AppliedRelationship, want.Versions.AppliedRelationship) ||
		!equalAppliedCollection(got.Versions.AppliedCollection, want.Versions.AppliedCollection) {
		t.Fatalf("restored payload-free receipt differs:\n got: %#v\nwant: %#v", got, want)
	}
}

func timePointer(value time.Time) *time.Time { return &value }

func equalOptionalTime(left, right *time.Time) bool {
	return (left == nil && right == nil) || (left != nil && right != nil && left.Equal(*right))
}

func equalOptionalUint64(left, right *uint64) bool {
	return (left == nil && right == nil) || (left != nil && right != nil && *left == *right)
}

func equalOperationFailure(left, right *OperationFailure) bool {
	return (left == nil && right == nil) ||
		(left != nil && right != nil && left.Code == right.Code && left.Retryable == right.Retryable)
}

func equalAppliedRelationship(left, right *AppliedRelationshipVersion) bool {
	return (left == nil && right == nil) ||
		(left != nil && right != nil && left.Generation == right.Generation && left.Version == right.Version)
}

func equalAppliedCollection(left, right *AppliedCollectionVersion) bool {
	return (left == nil && right == nil) ||
		(left != nil && right != nil &&
			left.CollectionID == right.CollectionID &&
			left.MetadataVersion == right.MetadataVersion &&
			left.LifecycleVersion == right.LifecycleVersion)
}

func newPendingOperationOfKind(t *testing.T, now time.Time, kind OperationKind) *SavedOperation {
	t.Helper()
	operation, err := NewPendingOperation(
		uuid.New(),
		uuid.New(),
		uuid.New(),
		kind,
		"0123456789abcdefghijklmnopqrstuv",
		make([]byte, semanticRequestHMACBytes),
		1,
		SourceSurfaceSavedCollection,
		7,
		now,
		now.Add(10*time.Second),
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	return operation
}
