package domain

import (
	"encoding/base64"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"
)

const (
	semanticRequestHMACBytes = 32
	minIdempotencyKeyBytes   = 22
	maxIdempotencyKeyBytes   = 128
	maxOperationCommitWindow = 15 * time.Second
	operationRetentionWindow = 14 * 24 * time.Hour
)

// SourceSurface is bounded attribution metadata, never a client payload or
// resource identifier. Unknown keeps older clients forward-compatible.
type SourceSurface string

const (
	SourceSurfaceUnknown         SourceSurface = "UNKNOWN"
	SourceSurfaceCard            SourceSurface = "CARD"
	SourceSurfaceDetail          SourceSurface = "DETAIL"
	SourceSurfaceSavedAll        SourceSurface = "SAVED_ALL"
	SourceSurfaceSavedCollection SourceSurface = "SAVED_COLLECTION"
)

func (s SourceSurface) IsValid() bool {
	switch s {
	case SourceSurfaceUnknown, SourceSurfaceCard, SourceSurfaceDetail,
		SourceSurfaceSavedAll, SourceSurfaceSavedCollection:
		return true
	default:
		return false
	}
}

type OperationKind string

const (
	OperationKindSave                 OperationKind = "SAVE_TARGET"
	OperationKindUnsave               OperationKind = "UNSAVE_TARGET"
	OperationKindSetTargetCollections OperationKind = "SET_TARGET_COLLECTIONS"
	OperationKindCreateCollection     OperationKind = "CREATE_COLLECTION"
	OperationKindRenameCollection     OperationKind = "RENAME_COLLECTION"
	OperationKindDeleteCollection     OperationKind = "DELETE_COLLECTION"
)

func (k OperationKind) IsValid() bool {
	switch k {
	case OperationKindSave,
		OperationKindUnsave,
		OperationKindSetTargetCollections,
		OperationKindCreateCollection,
		OperationKindRenameCollection,
		OperationKindDeleteCollection:
		return true
	default:
		return false
	}
}

// RequiresPublicEligibility distinguishes expansion from privacy reduction.
func (k OperationKind) RequiresPublicEligibility() bool {
	return k == OperationKindSave || k == OperationKindSetTargetCollections
}

type OperationStatus string

const (
	OperationStatusPending   OperationStatus = "PENDING"
	OperationStatusSucceeded OperationStatus = "SUCCEEDED"
	OperationStatusRejected  OperationStatus = "REJECTED"
	OperationStatusExpired   OperationStatus = "EXPIRED"
)

func (s OperationStatus) IsValid() bool {
	switch s {
	case OperationStatusPending, OperationStatusSucceeded, OperationStatusRejected, OperationStatusExpired:
		return true
	default:
		return false
	}
}

type RefreshScope string

const (
	RefreshScopeSavedItems  RefreshScope = "SAVED_ITEMS"
	RefreshScopeCollections RefreshScope = "COLLECTIONS"
	RefreshScopeBoth        RefreshScope = "BOTH"
	RefreshScopeNone        RefreshScope = "NONE"
)

func (s RefreshScope) IsValid() bool {
	switch s {
	case RefreshScopeSavedItems, RefreshScopeCollections, RefreshScopeBoth, RefreshScopeNone:
		return true
	default:
		return false
	}
}

type OperationOutcome string

const (
	OperationOutcomePending  OperationOutcome = "PENDING"
	OperationOutcomeApplied  OperationOutcome = "APPLIED"
	OperationOutcomeNoOp     OperationOutcome = "NO_OP"
	OperationOutcomeRejected OperationOutcome = "REJECTED"
	OperationOutcomeExpired  OperationOutcome = "EXPIRED"
)

func (o OperationOutcome) IsSuccess() bool {
	return o == OperationOutcomeApplied || o == OperationOutcomeNoOp
}

// OperationFailure has no presentation snapshot or request payload.
type OperationFailure struct {
	Code      ErrorCode
	Retryable bool
}

type AppliedRelationshipVersion struct {
	Generation uuid.UUID
	Version    uint64
}

type AppliedCollectionVersion struct {
	CollectionID     uuid.UUID
	MetadataVersion  uint64
	LifecycleVersion uint64
}

type OperationVersionEffects struct {
	ObservedRelationshipVersion        *uint64
	ObservedDependentMembershipVersion *uint64
	ObservedCollectionMetadataVersion  *uint64
	ObservedCollectionLifecycleVersion *uint64
	AppliedRelationship                *AppliedRelationshipVersion
	AppliedUserUsageVersion            *uint64
	AppliedDependentMembershipVersion  *uint64
	AppliedCollection                  *AppliedCollectionVersion
}

// SavedOperation is a bounded idempotency receipt, never a background job.
type SavedOperation struct {
	idempotencyKey                     string
	semanticRequestHMAC                []byte
	operationID                        uuid.UUID
	subjectID                          uuid.UUID
	sessionGeneration                  uuid.UUID
	kind                               OperationKind
	requestHMACKeyVersion              uint32
	firstSeenSourceSurface             SourceSurface
	acceptedPolicyRevision             uint64
	status                             OperationStatus
	commitDeadline                     time.Time
	createdAt                          time.Time
	completedAt                        *time.Time
	retentionExpiresAt                 *time.Time
	outcome                            OperationOutcome
	failure                            *OperationFailure
	refreshScope                       RefreshScope
	observedRelationshipVersion        *uint64
	observedDependentMembershipVersion *uint64
	observedCollectionMetadataVersion  *uint64
	observedCollectionLifecycleVersion *uint64
	appliedRelationship                *AppliedRelationshipVersion
	appliedUserUsageVersion            *uint64
	appliedDependentMembershipVersion  *uint64
	appliedCollection                  *AppliedCollectionVersion
}

func NewPendingOperation(
	operationID uuid.UUID,
	subjectID uuid.UUID,
	sessionGeneration uuid.UUID,
	kind OperationKind,
	idempotencyKey string,
	semanticRequestHMAC []byte,
	requestHMACKeyVersion uint32,
	firstSeenSourceSurface SourceSurface,
	acceptedPolicyRevision uint64,
	serverNow time.Time,
	commitDeadline time.Time,
) (*SavedOperation, error) {
	if operationID == uuid.Nil || operationID.Version() != 4 || operationID.Variant() != uuid.RFC4122 ||
		subjectID == uuid.Nil || sessionGeneration == uuid.Nil || !kind.IsValid() ||
		!isValidIdempotencyKey(idempotencyKey) || len(semanticRequestHMAC) != semanticRequestHMACBytes || requestHMACKeyVersion == 0 ||
		requestHMACKeyVersion > math.MaxInt32 || !firstSeenSourceSurface.IsValid() ||
		acceptedPolicyRevision == 0 || acceptedPolicyRevision > math.MaxInt64 ||
		serverNow.IsZero() || !commitDeadline.After(serverNow) || commitDeadline.Sub(serverNow) > maxOperationCommitWindow {
		return nil, ErrMutationStale
	}

	return &SavedOperation{
		operationID:            operationID,
		subjectID:              subjectID,
		sessionGeneration:      sessionGeneration,
		kind:                   kind,
		idempotencyKey:         idempotencyKey,
		semanticRequestHMAC:    append([]byte(nil), semanticRequestHMAC...),
		requestHMACKeyVersion:  requestHMACKeyVersion,
		firstSeenSourceSurface: firstSeenSourceSurface,
		acceptedPolicyRevision: acceptedPolicyRevision,
		status:                 OperationStatusPending,
		outcome:                OperationOutcomePending,
		commitDeadline:         commitDeadline,
		createdAt:              serverNow,
		refreshScope:           RefreshScopeNone,
	}, nil
}

func isValidIdempotencyKey(value string) bool {
	if len(value) < minIdempotencyKeyBytes || len(value) > maxIdempotencyKeyBytes || value != strings.TrimSpace(value) {
		return false
	}
	for _, char := range value {
		if (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') ||
			(char >= '0' && char <= '9') || strings.ContainsRune("-_", char) {
			continue
		}
		return false
	}
	decoded, err := base64.RawURLEncoding.DecodeString(value)
	if err != nil {
		return false
	}
	valid := len(decoded) >= 16
	clear(decoded)
	return valid
}

// GuardCommit enforces the database-CAS precondition before a state mutation.
func (o *SavedOperation) GuardCommit(serverNow time.Time) error {
	if o == nil || o.status != OperationStatusPending || serverNow.IsZero() {
		return ErrMutationStale
	}
	if !serverNow.Before(o.commitDeadline) {
		return ErrOperationExpired
	}
	return nil
}

func (o *SavedOperation) Succeed(
	serverNow time.Time,
	outcome OperationOutcome,
	refreshScope RefreshScope,
	versions OperationVersionEffects,
) error {
	if err := o.GuardCommit(serverNow); err != nil {
		return err
	}
	if !outcome.IsSuccess() || !refreshScope.IsValid() || !versions.isValidFor(o.kind) {
		return ErrMutationStale
	}

	o.status = OperationStatusSucceeded
	o.outcome = outcome
	o.completedAt = copyTime(&serverNow)
	retentionExpiresAt := serverNow.Add(operationRetentionWindow)
	o.retentionExpiresAt = &retentionExpiresAt
	o.refreshScope = refreshScope
	o.observedRelationshipVersion = copyUint64(versions.ObservedRelationshipVersion)
	o.observedDependentMembershipVersion = copyUint64(versions.ObservedDependentMembershipVersion)
	o.observedCollectionMetadataVersion = copyUint64(versions.ObservedCollectionMetadataVersion)
	o.observedCollectionLifecycleVersion = copyUint64(versions.ObservedCollectionLifecycleVersion)
	o.appliedRelationship = copyAppliedRelationshipVersion(versions.AppliedRelationship)
	o.appliedUserUsageVersion = copyUint64(versions.AppliedUserUsageVersion)
	o.appliedDependentMembershipVersion = copyUint64(versions.AppliedDependentMembershipVersion)
	o.appliedCollection = copyAppliedCollectionVersion(versions.AppliedCollection)
	return nil
}

func (o *SavedOperation) Reject(serverNow time.Time, cause *DomainError, refreshScope RefreshScope) error {
	if err := o.GuardCommit(serverNow); err != nil {
		return err
	}
	if cause == nil || !refreshScope.IsValid() {
		return ErrMutationStale
	}

	o.status = OperationStatusRejected
	o.outcome = OperationOutcomeRejected
	o.completedAt = copyTime(&serverNow)
	retentionExpiresAt := serverNow.Add(operationRetentionWindow)
	o.retentionExpiresAt = &retentionExpiresAt
	o.failure = &OperationFailure{Code: cause.Code, Retryable: cause.Retryable}
	o.refreshScope = refreshScope
	return nil
}

func (o *SavedOperation) Expire(serverNow time.Time) error {
	if o == nil || o.status != OperationStatusPending || serverNow.IsZero() {
		return ErrMutationStale
	}
	if serverNow.Before(o.commitDeadline) {
		return ErrMutationStale
	}

	o.status = OperationStatusExpired
	o.outcome = OperationOutcomeExpired
	o.completedAt = copyTime(&serverNow)
	retentionExpiresAt := serverNow.Add(operationRetentionWindow)
	o.retentionExpiresAt = &retentionExpiresAt
	o.refreshScope = expiredOperationRefreshScope(o.kind)
	return nil
}

func expiredOperationRefreshScope(kind OperationKind) RefreshScope {
	switch kind {
	case OperationKindSave:
		return RefreshScopeSavedItems
	case OperationKindUnsave, OperationKindSetTargetCollections, OperationKindDeleteCollection:
		return RefreshScopeBoth
	case OperationKindCreateCollection, OperationKindRenameCollection:
		return RefreshScopeCollections
	default:
		return RefreshScopeNone
	}
}

func (o *SavedOperation) OperationID() uuid.UUID        { return o.operationID }
func (o *SavedOperation) SubjectID() uuid.UUID          { return o.subjectID }
func (o *SavedOperation) SessionGeneration() uuid.UUID  { return o.sessionGeneration }
func (o *SavedOperation) Kind() OperationKind           { return o.kind }
func (o *SavedOperation) IdempotencyKey() string        { return o.idempotencyKey }
func (o *SavedOperation) RequestHMACKeyVersion() uint32 { return o.requestHMACKeyVersion }
func (o *SavedOperation) FirstSeenSourceSurface() SourceSurface {
	return o.firstSeenSourceSurface
}
func (o *SavedOperation) AcceptedPolicyRevision() uint64 { return o.acceptedPolicyRevision }
func (o *SavedOperation) Status() OperationStatus        { return o.status }
func (o *SavedOperation) CommitDeadline() time.Time      { return o.commitDeadline }
func (o *SavedOperation) CreatedAt() time.Time           { return o.createdAt }
func (o *SavedOperation) CompletedAt() *time.Time        { return copyTime(o.completedAt) }
func (o *SavedOperation) RetentionExpiresAt() *time.Time { return copyTime(o.retentionExpiresAt) }
func (o *SavedOperation) RefreshScope() RefreshScope     { return o.refreshScope }
func (o *SavedOperation) ObservedRelationshipVersion() *uint64 {
	return copyUint64(o.observedRelationshipVersion)
}
func (o *SavedOperation) ObservedDependentMembershipVersion() *uint64 {
	return copyUint64(o.observedDependentMembershipVersion)
}
func (o *SavedOperation) ObservedCollectionMetadataVersion() *uint64 {
	return copyUint64(o.observedCollectionMetadataVersion)
}
func (o *SavedOperation) ObservedCollectionLifecycleVersion() *uint64 {
	return copyUint64(o.observedCollectionLifecycleVersion)
}
func (o *SavedOperation) AppliedRelationshipVersion() *uint64 {
	if o.appliedRelationship == nil {
		return nil
	}
	return copyUint64(&o.appliedRelationship.Version)
}
func (o *SavedOperation) AppliedRelationship() *AppliedRelationshipVersion {
	return copyAppliedRelationshipVersion(o.appliedRelationship)
}
func (o *SavedOperation) AppliedUserUsageVersion() *uint64 {
	return copyUint64(o.appliedUserUsageVersion)
}
func (o *SavedOperation) AppliedDependentMembershipVersion() *uint64 {
	return copyUint64(o.appliedDependentMembershipVersion)
}
func (o *SavedOperation) AppliedCollection() *AppliedCollectionVersion {
	return copyAppliedCollectionVersion(o.appliedCollection)
}

func (o *SavedOperation) SemanticRequestHMAC() []byte {
	return append([]byte(nil), o.semanticRequestHMAC...)
}

func (o *SavedOperation) Outcome() OperationOutcome {
	return o.outcome
}

func (o *SavedOperation) Failure() *OperationFailure {
	if o.failure == nil {
		return nil
	}

	copy := *o.failure
	return &copy
}

func copyUint64(value *uint64) *uint64 {
	if value == nil {
		return nil
	}

	copy := *value
	return &copy
}

func (v OperationVersionEffects) isValidFor(kind OperationKind) bool {
	if v.AppliedRelationship != nil &&
		(v.AppliedRelationship.Generation == uuid.Nil || !isPositiveDBVersion(v.AppliedRelationship.Version)) {
		return false
	}
	if v.AppliedCollection != nil &&
		(v.AppliedCollection.CollectionID == uuid.Nil ||
			!isPositiveDBVersion(v.AppliedCollection.MetadataVersion) ||
			!isPositiveDBVersion(v.AppliedCollection.LifecycleVersion)) {
		return false
	}
	for _, version := range []*uint64{
		v.ObservedRelationshipVersion,
		v.ObservedDependentMembershipVersion,
		v.ObservedCollectionMetadataVersion,
		v.ObservedCollectionLifecycleVersion,
		v.AppliedUserUsageVersion,
		v.AppliedDependentMembershipVersion,
	} {
		if version != nil && *version > math.MaxInt64 {
			return false
		}
	}
	if v.ObservedDependentMembershipVersion != nil && kind != OperationKindSetTargetCollections {
		return false
	}
	if v.ObservedCollectionMetadataVersion != nil &&
		kind != OperationKindRenameCollection && kind != OperationKindDeleteCollection {
		return false
	}
	if v.ObservedCollectionLifecycleVersion != nil &&
		(kind != OperationKindDeleteCollection || v.ObservedCollectionMetadataVersion == nil) {
		return false
	}
	if v.AppliedDependentMembershipVersion != nil &&
		kind != OperationKindUnsave && kind != OperationKindSetTargetCollections {
		return false
	}
	if v.AppliedCollection != nil &&
		kind != OperationKindSetTargetCollections &&
		kind != OperationKindCreateCollection &&
		kind != OperationKindRenameCollection &&
		kind != OperationKindDeleteCollection {
		return false
	}
	return true
}

func isPositiveDBVersion(value uint64) bool {
	return value > 0 && value <= math.MaxInt64
}

func copyAppliedRelationshipVersion(value *AppliedRelationshipVersion) *AppliedRelationshipVersion {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}

func copyAppliedCollectionVersion(value *AppliedCollectionVersion) *AppliedCollectionVersion {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}
