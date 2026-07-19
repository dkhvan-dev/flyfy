package savedcollection

import (
	"crypto/subtle"
	"math"
	"sort"
	"time"

	"github.com/google/uuid"

	titleapp "kz/inflap/backend/services/saved-service/internal/app/collection"
	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	semanticRequestHMACBytes = 32
	maxStoredNormalizedBytes = 320
	maxSourceServiceBytes    = 64
)

type MutationIdentity struct {
	SubjectID             uuid.UUID
	SessionGeneration     uuid.UUID
	OperationID           uuid.UUID
	Kind                  domain.OperationKind
	SemanticRequestHMAC   []byte
	RequestHMACKeyVersion uint32
}

func (identity MutationIdentity) Validate(expected domain.OperationKind) error {
	if identity.SubjectID == uuid.Nil || identity.SessionGeneration == uuid.Nil ||
		!isUUIDv4(identity.OperationID) || identity.Kind != expected ||
		!expected.IsValid() || len(identity.SemanticRequestHMAC) != semanticRequestHMACBytes ||
		identity.RequestHMACKeyVersion == 0 || identity.RequestHMACKeyVersion > math.MaxInt32 {
		return ErrInvalidCommand
	}
	return nil
}

func (identity MutationIdentity) Matches(receipt *domain.SavedOperation) bool {
	if receipt == nil || receipt.SubjectID() != identity.SubjectID ||
		receipt.SessionGeneration() != identity.SessionGeneration ||
		receipt.OperationID() != identity.OperationID || receipt.Kind() != identity.Kind ||
		receipt.RequestHMACKeyVersion() != identity.RequestHMACKeyVersion {
		return false
	}
	persisted := receipt.SemanticRequestHMAC()
	return len(persisted) == len(identity.SemanticRequestHMAC) &&
		subtle.ConstantTimeCompare(persisted, identity.SemanticRequestHMAC) == 1
}

type ExpectedRelationshipState string

const (
	ExpectedRelationshipAbsent  ExpectedRelationshipState = "EXPECTED_ABSENT"
	ExpectedRelationshipActive  ExpectedRelationshipState = "EXPECTED_ACTIVE"
	ExpectedRelationshipRemoved ExpectedRelationshipState = "EXPECTED_REMOVED"
)

type ExpectedRelationship struct {
	State      ExpectedRelationshipState
	Generation uuid.UUID
	Version    uint64
}

func (expected ExpectedRelationship) Validate() error {
	switch expected.State {
	case ExpectedRelationshipAbsent:
		if expected.Generation != uuid.Nil || expected.Version != 0 {
			return ErrInvalidCommand
		}
	case ExpectedRelationshipActive, ExpectedRelationshipRemoved:
		if expected.Generation == uuid.Nil || expected.Version == 0 || expected.Version > math.MaxInt64 {
			return ErrInvalidCommand
		}
	default:
		return ErrInvalidCommand
	}
	return nil
}

type NewCollection struct {
	ClientCreationID uuid.UUID
	Title            string
}

type DesiredSet struct {
	Target                             domain.SavedTarget
	ExpectedRelationship               ExpectedRelationship
	ExpectedDependentMembershipVersion uint64
	DesiredCollectionIDs               []uuid.UUID
	NewCollection                      *NewCollection
}

func (desired DesiredSet) Validate(maxIDs int) error {
	if desired.Target.IsZero() || desired.ExpectedDependentMembershipVersion > math.MaxInt64 ||
		maxIDs < 1 || maxIDs > DefaultMaxDesiredCollectionIDs ||
		len(desired.DesiredCollectionIDs) > maxIDs {
		return ErrInvalidCommand
	}
	if err := desired.ExpectedRelationship.Validate(); err != nil {
		return err
	}
	if desired.ExpectedRelationship.State == ExpectedRelationshipAbsent &&
		desired.ExpectedDependentMembershipVersion != 0 {
		return ErrInvalidCommand
	}
	seen := make(map[uuid.UUID]struct{}, len(desired.DesiredCollectionIDs))
	for _, collectionID := range desired.DesiredCollectionIDs {
		if collectionID == uuid.Nil {
			return ErrInvalidCommand
		}
		if _, exists := seen[collectionID]; exists {
			return ErrInvalidCommand
		}
		seen[collectionID] = struct{}{}
	}
	if desired.NewCollection != nil {
		if !isUUIDv4(desired.NewCollection.ClientCreationID) {
			return ErrInvalidCommand
		}
		if _, err := NormalizeStoredTitle(desired.NewCollection.Title); err != nil {
			return err
		}
	}
	return nil
}

func (desired DesiredSet) SortedCollectionIDs() []uuid.UUID {
	result := append([]uuid.UUID(nil), desired.DesiredCollectionIDs...)
	sort.Slice(result, func(left, right int) bool {
		return result[left].String() < result[right].String()
	})
	return result
}

type AnalyzeDesiredSetQuery struct {
	OwnerUserID uuid.UUID
	Desired     DesiredSet
	ReadAt      time.Time
}

func (query AnalyzeDesiredSetQuery) Validate(maxIDs int) error {
	if query.OwnerUserID == uuid.Nil || query.ReadAt.IsZero() {
		return ErrInvalidCommand
	}
	return query.Desired.Validate(maxIDs)
}

type CreateCommand struct {
	Identity         MutationIdentity
	OwnerUserID      uuid.UUID
	ClientCreationID uuid.UUID
	Title            string
	ServerNow        time.Time
}

func (command CreateCommand) ValidateIdentity() error {
	return command.Identity.Validate(domain.OperationKindCreateCollection)
}

func (command CreateCommand) Validate(deadline time.Time) error {
	if command.OwnerUserID == uuid.Nil || !isUUIDv4(command.ClientCreationID) ||
		!validCommitTime(command.ServerNow, deadline) {
		return ErrInvalidCommand
	}
	_, err := NormalizeStoredTitle(command.Title)
	return err
}

type RenameCommand struct {
	Identity                MutationIdentity
	OwnerUserID             uuid.UUID
	CollectionID            uuid.UUID
	ExpectedMetadataVersion uint64
	Title                   string
	ServerNow               time.Time
}

func (command RenameCommand) ValidateIdentity() error {
	return command.Identity.Validate(domain.OperationKindRenameCollection)
}

func (command RenameCommand) Validate(deadline time.Time) error {
	if command.OwnerUserID == uuid.Nil || command.CollectionID == uuid.Nil ||
		command.ExpectedMetadataVersion == 0 || command.ExpectedMetadataVersion > math.MaxInt64 ||
		!validCommitTime(command.ServerNow, deadline) {
		return ErrInvalidCommand
	}
	_, err := NormalizeStoredTitle(command.Title)
	return err
}

type DeleteCommand struct {
	Identity                 MutationIdentity
	OwnerUserID              uuid.UUID
	CollectionID             uuid.UUID
	ExpectedMetadataVersion  uint64
	ExpectedLifecycleVersion uint64
	ServerNow                time.Time
}

func (command DeleteCommand) ValidateIdentity() error {
	return command.Identity.Validate(domain.OperationKindDeleteCollection)
}

func (command DeleteCommand) Validate(deadline time.Time) error {
	if command.OwnerUserID == uuid.Nil || command.CollectionID == uuid.Nil ||
		command.ExpectedMetadataVersion == 0 || command.ExpectedMetadataVersion > math.MaxInt64 ||
		command.ExpectedLifecycleVersion == 0 || command.ExpectedLifecycleVersion > math.MaxInt64 ||
		!validCommitTime(command.ServerNow, deadline) {
		return ErrInvalidCommand
	}
	return nil
}

type PublicEligibility struct {
	Projection saveditemapp.PublicProjectionSnapshot
}

// PrepareProjectionShellCommand reserves a payload-free projection row before
// source resolution. The final desired-set transaction requires this row to
// exist so an intervening visibility event cannot be lost for an unknown target.
type PrepareProjectionShellCommand struct {
	Identity       MutationIdentity
	Target         domain.SavedTarget
	SourceService  string
	ShellExpiresAt time.Time
	ServerNow      time.Time
}

func (command PrepareProjectionShellCommand) ValidateIdentity() error {
	return command.Identity.Validate(domain.OperationKindSetTargetCollections)
}

func (command PrepareProjectionShellCommand) Validate(deadline time.Time) error {
	if err := command.ValidateIdentity(); err != nil || command.Target.IsZero() ||
		!validSourceService(command.SourceService) || command.ServerNow.IsZero() || deadline.IsZero() ||
		!command.ServerNow.Before(deadline) || !command.ShellExpiresAt.After(deadline) ||
		command.ShellExpiresAt.After(command.ServerNow.Add(time.Hour)) {
		return ErrInvalidCommand
	}
	return nil
}

type ReplaceDesiredSetCommand struct {
	Identity    MutationIdentity
	OwnerUserID uuid.UUID
	Desired     DesiredSet
	Eligibility *PublicEligibility
	ServerNow   time.Time
}

func (command ReplaceDesiredSetCommand) ValidateIdentity() error {
	return command.Identity.Validate(domain.OperationKindSetTargetCollections)
}

func (command ReplaceDesiredSetCommand) Validate(deadline time.Time, maxIDs int) error {
	if command.OwnerUserID == uuid.Nil || !validCommitTime(command.ServerNow, deadline) {
		return ErrInvalidCommand
	}
	if err := command.Desired.Validate(maxIDs); err != nil {
		return err
	}
	if command.Eligibility != nil {
		if command.Eligibility.Projection.Target != command.Desired.Target {
			return ErrInvalidCommand
		}
		if err := command.Eligibility.Projection.Validate(command.ServerNow, deadline); err != nil {
			return ErrInvalidCommand
		}
	}
	return nil
}

type RejectPendingCommand struct {
	Identity     MutationIdentity
	Cause        *domain.DomainError
	RefreshScope domain.RefreshScope
	ServerNow    time.Time
}

func (command RejectPendingCommand) Validate() error {
	if err := command.Identity.Validate(command.Identity.Kind); err != nil ||
		!isCollectionOperationKind(command.Identity.Kind) ||
		command.ServerNow.IsZero() || command.Cause == nil ||
		!command.RefreshScope.IsValid() || !saveditemapp.IsPersistableRejection(command.Cause) {
		return ErrInvalidCommand
	}
	return nil
}

func isCollectionOperationKind(kind domain.OperationKind) bool {
	switch kind {
	case domain.OperationKindSetTargetCollections,
		domain.OperationKindCreateCollection,
		domain.OperationKindRenameCollection,
		domain.OperationKindDeleteCollection:
		return true
	default:
		return false
	}
}

type ListQuery struct {
	OwnerUserID uuid.UUID
	Locale      Locale
	ReadAt      time.Time
}

func (query ListQuery) Validate() error {
	if query.OwnerUserID == uuid.Nil || !query.Locale.IsValid() || query.ReadAt.IsZero() {
		return ErrInvalidCommand
	}
	return nil
}

type GetQuery struct {
	OwnerUserID  uuid.UUID
	CollectionID uuid.UUID
	Locale       Locale
	ReadAt       time.Time
}

func (query GetQuery) Validate() error {
	if query.OwnerUserID == uuid.Nil || query.CollectionID == uuid.Nil ||
		!query.Locale.IsValid() || query.ReadAt.IsZero() {
		return ErrInvalidCommand
	}
	return nil
}

type TargetSnapshotQuery struct {
	OwnerUserID uuid.UUID
	Target      domain.SavedTarget
	ReadAt      time.Time
}

func (query TargetSnapshotQuery) Validate() error {
	if query.OwnerUserID == uuid.Nil || query.Target.IsZero() || query.ReadAt.IsZero() {
		return ErrInvalidCommand
	}
	return nil
}

type StoredTitle struct {
	Display string
	Key     string
}

func NormalizeStoredTitle(raw string) (StoredTitle, error) {
	normalized, err := titleapp.NormalizeTitle(raw)
	if err != nil || len(normalized.Key) > maxStoredNormalizedBytes {
		return StoredTitle{}, domain.ErrCollectionTitleInvalid
	}
	return StoredTitle{Display: normalized.Display, Key: normalized.Key}, nil
}

func validCommitTime(serverNow, deadline time.Time) bool {
	return !serverNow.IsZero() && !deadline.IsZero() && serverNow.Before(deadline)
}

func validSourceService(value string) bool {
	if value == "" || len(value) > maxSourceServiceBytes || value[0] < 'a' || value[0] > 'z' {
		return false
	}
	for _, character := range value[1:] {
		if (character >= 'a' && character <= 'z') ||
			(character >= '0' && character <= '9') || character == '-' {
			continue
		}
		return false
	}
	return true
}

func isUUIDv4(value uuid.UUID) bool {
	return value != uuid.Nil && value.Version() == 4 && value.Variant() == uuid.RFC4122
}
