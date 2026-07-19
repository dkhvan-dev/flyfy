package savedcollection

import (
	"math"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	DefaultMaxActiveCollections        uint64 = 200
	DefaultMaxMembershipsPerCollection uint64 = 5_000
	DefaultMaxMembershipsPerOwner      uint64 = 50_000
	DefaultMaxDesiredCollectionIDs            = 200
)

type Limits struct {
	MaxActiveCollections        uint64
	MaxMembershipsPerCollection uint64
	MaxMembershipsPerOwner      uint64
	MaxDesiredCollectionIDs     int
	MaxActiveSaves              uint64
}

func (limits Limits) WithDefaults() Limits {
	if limits.MaxActiveCollections == 0 {
		limits.MaxActiveCollections = DefaultMaxActiveCollections
	}
	if limits.MaxMembershipsPerCollection == 0 {
		limits.MaxMembershipsPerCollection = DefaultMaxMembershipsPerCollection
	}
	if limits.MaxMembershipsPerOwner == 0 {
		limits.MaxMembershipsPerOwner = DefaultMaxMembershipsPerOwner
	}
	if limits.MaxDesiredCollectionIDs == 0 {
		limits.MaxDesiredCollectionIDs = DefaultMaxDesiredCollectionIDs
	}
	if limits.MaxActiveSaves == 0 {
		limits.MaxActiveSaves = 10_000
	}
	return limits
}

func (limits Limits) Validate() error {
	limits = limits.WithDefaults()
	if limits.MaxActiveCollections > DefaultMaxActiveCollections ||
		limits.MaxMembershipsPerCollection > DefaultMaxMembershipsPerCollection ||
		limits.MaxMembershipsPerOwner > DefaultMaxMembershipsPerOwner ||
		limits.MaxMembershipsPerCollection > limits.MaxMembershipsPerOwner ||
		limits.MaxDesiredCollectionIDs < 1 ||
		limits.MaxDesiredCollectionIDs > DefaultMaxDesiredCollectionIDs ||
		uint64(limits.MaxDesiredCollectionIDs) > limits.MaxActiveCollections ||
		limits.MaxActiveSaves > 10_000 || limits.MaxActiveSaves > math.MaxInt64 {
		return ErrInvalidCommand
	}
	return nil
}

type Locale string

const (
	LocaleEN Locale = "EN"
	LocaleRU Locale = "RU"
	LocaleKK Locale = "KK"
)

func (locale Locale) IsValid() bool {
	return locale == LocaleEN || locale == LocaleRU || locale == LocaleKK
}

type CollectionLifecycleState string

const (
	CollectionLifecycleActive  CollectionLifecycleState = "ACTIVE"
	CollectionLifecycleDeleted CollectionLifecycleState = "DELETED"
)

type CoverKind string

const (
	CoverKindGeneric CoverKind = "GENERIC"
	CoverKindItem    CoverKind = "ITEM"
)

type CoverPreview struct {
	Kind             CoverKind
	Target           *domain.SavedTarget
	Title            *string
	ResolvedImageURL *string
}

func GenericCover() CoverPreview {
	return CoverPreview{Kind: CoverKindGeneric}
}

type Collection struct {
	ID               uuid.UUID
	Title            string
	LifecycleState   CollectionLifecycleState
	MetadataVersion  uint64
	LifecycleVersion uint64
	ActiveItemCount  uint64
	Cover            CoverPreview
	OrganizedAt      time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

// CoverCandidate is internal read data. OpaqueReference must only be passed to
// ThumbnailResolver; it must never be serialized as an image URL.
type CoverCandidate struct {
	CollectionID          uuid.UUID
	Target                domain.SavedTarget
	Title                 string
	OpaqueReference       string
	ReferenceRevision     uint64
	VisibilityValidatedAt time.Time
	// ValidUntil bounds the source snapshot lease, not the resolver route.
	// An expired coherent reference is still resolved through the public route,
	// whose endpoint revalidates current visibility and the exact revision.
	ValidUntil time.Time
}

type CollectionRecord struct {
	OwnerUserID    uuid.UUID
	Collection     Collection
	CoverCandidate *CoverCandidate
}

type CollectionOption struct {
	ID               uuid.UUID
	Title            string
	MetadataVersion  uint64
	LifecycleVersion uint64
}

type RelationshipSnapshotState string

const (
	RelationshipSnapshotAbsent  RelationshipSnapshotState = "ABSENT"
	RelationshipSnapshotActive  RelationshipSnapshotState = "ACTIVE"
	RelationshipSnapshotRemoved RelationshipSnapshotState = "REMOVED"
)

type RelationshipSnapshot struct {
	State      RelationshipSnapshotState
	Generation uuid.UUID
	Version    uint64
}

type TargetCollectionsSnapshot struct {
	Target                     domain.SavedTarget
	Relationship               RelationshipSnapshot
	DependentMembershipVersion uint64
	EffectiveCollectionIDs     []uuid.UUID
	CollectionOptions          []CollectionOption
	RecordedAt                 time.Time
}

type DesiredSetChange string

const (
	DesiredSetNoOp      DesiredSetChange = "NO_OP"
	DesiredSetReduction DesiredSetChange = "REDUCTION"
	DesiredSetExpansion DesiredSetChange = "EXPANSION"
	DesiredSetMixed     DesiredSetChange = "MIXED"
)

func (change DesiredSetChange) ExpandsCollections() bool {
	return change == DesiredSetExpansion || change == DesiredSetMixed
}

type DesiredSetAnalysis struct {
	Change                     DesiredSetChange
	CurrentCollectionIDs       []uuid.UUID
	DesiredExistingIDs         []uuid.UUID
	HasInlineCollection        bool
	Relationship               RelationshipSnapshot
	DependentMembershipVersion uint64
}

func (analysis DesiredSetAnalysis) RequiresPublicEligibility() bool {
	if analysis.Relationship.State == RelationshipSnapshotActive {
		return false
	}
	return len(analysis.DesiredExistingIDs) > 0 || analysis.HasInlineCollection
}

type ThumbnailRequest struct {
	CollectionID      uuid.UUID
	Target            domain.SavedTarget
	OpaqueReference   string
	ReferenceRevision uint64
	// ValidUntil is source snapshot metadata and must not be treated as the
	// lifetime of the resolver route.
	ValidUntil time.Time
}
