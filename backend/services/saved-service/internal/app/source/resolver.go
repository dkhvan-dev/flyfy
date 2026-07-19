package source

import (
	"context"
	"time"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

// Resolver obtains authoritative save eligibility and the bounded public card
// projection from the domain that owns a target.
type Resolver interface {
	Resolve(ctx context.Context, target domain.SavedTarget) (Resolution, error)
}

// Revisions is the source-owned monotonic revision vector for one target.
// Components are independent and may only be compared to the same component.
type Revisions struct {
	Source     uint64
	Projection uint64
	Visibility uint64
}

// Resolution is either an eligible public projection or a payload-free deny
// result. It deliberately contains no protobuf or source aggregate types.
type Resolution struct {
	Target           domain.SavedTarget
	Eligible         bool
	Visibility       domain.VisibilityStatus
	Revisions        Revisions
	ValidatedAt      time.Time
	PublicProjection *PublicCardProjection
}

// Locale is the complete locale set accepted by Saved projections.
type Locale string

const (
	LocaleEN Locale = "en"
	LocaleRU Locale = "ru"
	LocaleKK Locale = "kk"
)

func (l Locale) IsValid() bool {
	switch l {
	case LocaleEN, LocaleRU, LocaleKK:
		return true
	default:
		return false
	}
}

// PublicCardProjection is display-safe PUBLIC content only. Localized entries
// use the closed Locale set; no owner or Saved relationship data belongs here.
type PublicCardProjection struct {
	SourceDefaultLocale  Locale
	Localized            map[Locale]LocalizedCardProjection
	Rating               *RatingSummary
	AsOf                 *time.Time
	ValidUntil           *time.Time
	CanonicalDetailRoute string
	Media                *MediaReference
}

type LocalizedCardProjection struct {
	Title               string
	Subtitle            string
	City                string
	Country             string
	DisplayLocation     string
	PriceSummary        string
	AvailabilitySummary string
}

type RatingSummary struct {
	Value       float64
	ReviewCount uint64
	ScaleMax    float64
}

type MediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}
