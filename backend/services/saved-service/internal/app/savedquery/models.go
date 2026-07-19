package savedquery

import (
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	DefaultPageLimit            = 30
	MaxPageLimit                = 100
	MaxBatchTargets             = 100
	MaxEffectiveCollectionCount = 200
)

type Locale string

const (
	LocaleEN Locale = "EN"
	LocaleRU Locale = "RU"
	LocaleKK Locale = "KK"
)

func (l Locale) IsValid() bool {
	return l == LocaleEN || l == LocaleRU || l == LocaleKK
}

type SavedState string

const (
	SavedStateUnknown          SavedState = "UNKNOWN"
	SavedStateConfirmedUnsaved SavedState = "CONFIRMED_UNSAVED"
	SavedStateSaved            SavedState = "SAVED"
)

func (s SavedState) IsValid() bool {
	return s == SavedStateUnknown || s == SavedStateConfirmedUnsaved || s == SavedStateSaved
}

type EligibilityHint string

const (
	EligibilityUnknown       EligibilityHint = "UNKNOWN"
	EligibilityEligible      EligibilityHint = "ELIGIBLE"
	EligibilityReductionOnly EligibilityHint = "REDUCTION_ONLY"
	EligibilityIneligible    EligibilityHint = "INELIGIBLE"
)

func (h EligibilityHint) IsValid() bool {
	return h == EligibilityUnknown || h == EligibilityEligible ||
		h == EligibilityReductionOnly || h == EligibilityIneligible
}

type TargetStatus struct {
	Target                   domain.SavedTarget
	SavedState               SavedState
	EffectiveCollectionCount uint32
	Eligibility              EligibilityHint
	RelationshipGeneration   *uuid.UUID
	// ResourceVersion is the monotonic sum of the relationship lifecycle and
	// dependent membership versions for this target activation history.
	ResourceVersion uint64
}

type ContentState string

const (
	ContentStateAvailable   ContentState = "AVAILABLE"
	ContentStateUnavailable ContentState = "UNAVAILABLE"
)

type SourceRevisions struct {
	Source     uint64
	Projection uint64
	Visibility uint64
}

// PublicCardProjection contains only PUBLIC display data. It is nil for every
// unavailable/private/restricted/deleted projection. MediaReference is an
// application-internal handoff to ImageResolver and is scrubbed before a page
// leaves Service. Only ResolvedImageURL may reach an HTTP response.
type PublicCardProjection struct {
	DisplayLocale        Locale
	Title                string
	Subtitle             *string
	MediaReference       *MediaReference
	ResolvedImageURL     *string
	CanonicalDetailRoute string
	SourceUpdatedAt      time.Time
}

type MediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

type ImageRequest struct {
	ItemID            uuid.UUID
	Target            domain.SavedTarget
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

type CardProjection struct {
	ContentState ContentState
	Revisions    SourceRevisions
	Public       *PublicCardProjection
}

type ActiveRelationship struct {
	Generation                 uuid.UUID
	Version                    uint64
	DependentMembershipVersion uint64
	SavedAt                    time.Time
	AttributionID              uuid.UUID
}

// ItemID is internal pagination state and is not part of the public card
// identity. Callers expose Target and keep ItemID only for cursor encoding.
type Item struct {
	ItemID                   uuid.UUID
	Target                   domain.SavedTarget
	Relationship             ActiveRelationship
	EffectiveCollectionCount uint32
	Projection               CardProjection
}

type Keyset struct {
	SavedAt time.Time
	ItemID  uuid.UUID
}

type Page struct {
	Items   []Item
	Next    *Keyset
	HasMore bool
}
