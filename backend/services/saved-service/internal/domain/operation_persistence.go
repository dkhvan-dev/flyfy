package domain

import (
	"time"

	"github.com/google/uuid"
)

// PersistedOperation is the payload-free representation stored by the
// operation journal. It exists so repositories can restore receipts without
// bypassing aggregate invariants.
type PersistedOperation struct {
	OperationID            uuid.UUID
	SubjectID              uuid.UUID
	SessionGeneration      uuid.UUID
	Kind                   OperationKind
	IdempotencyKey         string
	SemanticRequestHMAC    []byte
	RequestHMACKeyVersion  uint32
	FirstSeenSourceSurface SourceSurface
	AcceptedPolicyRevision uint64
	Status                 OperationStatus
	CommitDeadline         time.Time
	CreatedAt              time.Time
	CompletedAt            *time.Time
	RetentionExpiresAt     *time.Time
	Outcome                OperationOutcome
	Failure                *OperationFailure
	RefreshScope           RefreshScope
	Versions               OperationVersionEffects
}

func RestoreOperation(state PersistedOperation) (*SavedOperation, error) {
	operation, err := NewPendingOperation(
		state.OperationID,
		state.SubjectID,
		state.SessionGeneration,
		state.Kind,
		state.IdempotencyKey,
		state.SemanticRequestHMAC,
		state.RequestHMACKeyVersion,
		state.FirstSeenSourceSurface,
		state.AcceptedPolicyRevision,
		state.CreatedAt,
		state.CommitDeadline,
	)
	if err != nil || !state.Status.IsValid() || !state.RefreshScope.IsValid() || !state.Versions.isValidFor(state.Kind) {
		return nil, ErrMutationStale
	}

	operation.status = state.Status
	operation.outcome = state.Outcome
	operation.completedAt = copyTime(state.CompletedAt)
	operation.retentionExpiresAt = copyTime(state.RetentionExpiresAt)
	operation.failure = copyOperationFailure(state.Failure)
	operation.refreshScope = state.RefreshScope
	operation.observedRelationshipVersion = copyUint64(state.Versions.ObservedRelationshipVersion)
	operation.observedDependentMembershipVersion = copyUint64(state.Versions.ObservedDependentMembershipVersion)
	operation.observedCollectionMetadataVersion = copyUint64(state.Versions.ObservedCollectionMetadataVersion)
	operation.observedCollectionLifecycleVersion = copyUint64(state.Versions.ObservedCollectionLifecycleVersion)
	operation.appliedRelationship = copyAppliedRelationshipVersion(state.Versions.AppliedRelationship)
	operation.appliedUserUsageVersion = copyUint64(state.Versions.AppliedUserUsageVersion)
	operation.appliedDependentMembershipVersion = copyUint64(state.Versions.AppliedDependentMembershipVersion)
	operation.appliedCollection = copyAppliedCollectionVersion(state.Versions.AppliedCollection)

	if !operation.hasValidPersistedLifecycle() {
		return nil, ErrMutationStale
	}
	return operation, nil
}

func (o *SavedOperation) PersistenceState() PersistedOperation {
	if o == nil {
		return PersistedOperation{}
	}
	return PersistedOperation{
		OperationID:            o.operationID,
		SubjectID:              o.subjectID,
		SessionGeneration:      o.sessionGeneration,
		Kind:                   o.kind,
		IdempotencyKey:         o.idempotencyKey,
		SemanticRequestHMAC:    o.SemanticRequestHMAC(),
		RequestHMACKeyVersion:  o.requestHMACKeyVersion,
		FirstSeenSourceSurface: o.firstSeenSourceSurface,
		AcceptedPolicyRevision: o.acceptedPolicyRevision,
		Status:                 o.status,
		CommitDeadline:         o.commitDeadline,
		CreatedAt:              o.createdAt,
		CompletedAt:            o.CompletedAt(),
		RetentionExpiresAt:     o.RetentionExpiresAt(),
		Outcome:                o.outcome,
		Failure:                o.Failure(),
		RefreshScope:           o.refreshScope,
		Versions: OperationVersionEffects{
			ObservedRelationshipVersion:        o.ObservedRelationshipVersion(),
			ObservedDependentMembershipVersion: o.ObservedDependentMembershipVersion(),
			ObservedCollectionMetadataVersion:  o.ObservedCollectionMetadataVersion(),
			ObservedCollectionLifecycleVersion: o.ObservedCollectionLifecycleVersion(),
			AppliedRelationship:                o.AppliedRelationship(),
			AppliedUserUsageVersion:            o.AppliedUserUsageVersion(),
			AppliedDependentMembershipVersion:  o.AppliedDependentMembershipVersion(),
			AppliedCollection:                  o.AppliedCollection(),
		},
	}
}

func (o *SavedOperation) hasValidPersistedLifecycle() bool {
	if o.status == OperationStatusPending {
		return o.outcome == OperationOutcomePending &&
			o.failure == nil && o.refreshScope == RefreshScopeNone &&
			o.completedAt == nil && o.retentionExpiresAt == nil &&
			o.observedRelationshipVersion == nil &&
			o.observedDependentMembershipVersion == nil &&
			o.observedCollectionMetadataVersion == nil &&
			o.observedCollectionLifecycleVersion == nil &&
			o.appliedRelationship == nil &&
			o.appliedUserUsageVersion == nil &&
			o.appliedDependentMembershipVersion == nil &&
			o.appliedCollection == nil
	}

	if o.completedAt == nil || o.retentionExpiresAt == nil ||
		!o.retentionExpiresAt.Equal(o.completedAt.Add(operationRetentionWindow)) {
		return false
	}

	switch o.status {
	case OperationStatusSucceeded:
		return o.outcome.IsSuccess() && o.failure == nil &&
			!o.completedAt.After(o.commitDeadline)
	case OperationStatusRejected:
		return o.outcome == OperationOutcomeRejected && o.failure != nil &&
			o.failure.Code.IsValid() && !o.completedAt.After(o.commitDeadline) &&
			o.appliedRelationship == nil && o.appliedUserUsageVersion == nil &&
			o.appliedDependentMembershipVersion == nil && o.appliedCollection == nil
	case OperationStatusExpired:
		return o.outcome == OperationOutcomeExpired && o.failure == nil &&
			o.refreshScope == expiredOperationRefreshScope(o.kind) &&
			!o.completedAt.Before(o.commitDeadline) &&
			o.observedRelationshipVersion == nil &&
			o.observedDependentMembershipVersion == nil &&
			o.observedCollectionMetadataVersion == nil &&
			o.observedCollectionLifecycleVersion == nil &&
			o.appliedRelationship == nil &&
			o.appliedUserUsageVersion == nil &&
			o.appliedDependentMembershipVersion == nil &&
			o.appliedCollection == nil
	default:
		return false
	}
}

func copyOperationFailure(value *OperationFailure) *OperationFailure {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}
