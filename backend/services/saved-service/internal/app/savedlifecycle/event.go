package savedlifecycle

import (
	"math"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"
	"golang.org/x/text/cases"
	"golang.org/x/text/unicode/norm"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	maxFutureClockSkew      = 5 * time.Second
	maxSummaryAge           = 30 * 24 * time.Hour
	maxSummaryLease         = 24 * time.Hour
	maxMediaLease           = 15 * time.Minute
	maxTitleBytes           = 256
	maxSubtitleBytes        = 512
	maxPlaceNameBytes       = 128
	maxDisplayLocationBytes = 512
	maxDynamicSummaryBytes  = 256
	maxMediaReferenceBytes  = 512
	maxCanonicalRouteBytes  = 256
	maxRatingScale          = 100
)

type EventKind string

const (
	EventPublished         EventKind = "content.published"
	EventUpdated           EventKind = "content.updated"
	EventUnavailable       EventKind = "content.unavailable"
	EventVisibilityChanged EventKind = "content.visibility_changed"
	EventDeleted           EventKind = "content.deleted"
)

func (k EventKind) IsValid() bool {
	switch k {
	case EventPublished, EventUpdated, EventUnavailable, EventVisibilityChanged, EventDeleted:
		return true
	default:
		return false
	}
}

type Revisions struct {
	Source     uint64
	Projection uint64
	Visibility uint64
}

func (r Revisions) IsValid() bool {
	return positiveDatabaseRevision(r.Source) &&
		positiveDatabaseRevision(r.Projection) &&
		positiveDatabaseRevision(r.Visibility)
}

type Locale string

const (
	LocaleEN Locale = "EN"
	LocaleRU Locale = "RU"
	LocaleKK Locale = "KK"
)

func (l Locale) IsValid() bool {
	return l == LocaleEN || l == LocaleRU || l == LocaleKK
}

type LocalizedProjection struct {
	Title               string
	Subtitle            string
	City                string
	Country             string
	DisplayLocation     string
	PriceSummary        string
	AvailabilitySummary string
}

func (p LocalizedProjection) validate() bool {
	return validRequiredText(p.Title, maxTitleBytes) &&
		validOptionalText(p.Subtitle, maxSubtitleBytes) &&
		validOptionalText(p.City, maxPlaceNameBytes) &&
		validOptionalText(p.Country, maxPlaceNameBytes) &&
		validOptionalText(p.DisplayLocation, maxDisplayLocationBytes) &&
		validOptionalText(p.PriceSummary, maxDynamicSummaryBytes) &&
		validOptionalText(p.AvailabilitySummary, maxDynamicSummaryBytes)
}

type LocalizedProjections struct {
	EN *LocalizedProjection
	RU *LocalizedProjection
	KK *LocalizedProjection
}

func (p LocalizedProjections) For(locale Locale) *LocalizedProjection {
	switch locale {
	case LocaleEN:
		return p.EN
	case LocaleRU:
		return p.RU
	case LocaleKK:
		return p.KK
	default:
		return nil
	}
}

func (p LocalizedProjections) values() []*LocalizedProjection {
	return []*LocalizedProjection{p.EN, p.RU, p.KK}
}

type RatingSummary struct {
	Value       float64
	ReviewCount uint64
	ScaleMax    float64
}

func (r RatingSummary) validate() bool {
	return !math.IsNaN(r.Value) && !math.IsInf(r.Value, 0) &&
		!math.IsNaN(r.ScaleMax) && !math.IsInf(r.ScaleMax, 0) &&
		r.ScaleMax > 0 && r.ScaleMax <= maxRatingScale &&
		r.Value >= 0 && r.Value <= r.ScaleMax && r.ReviewCount <= math.MaxInt64
}

type MediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

func (m MediaReference) validate(occurredAt time.Time) bool {
	return validRequiredText(m.OpaqueReference, maxMediaReferenceBytes) &&
		positiveDatabaseRevision(m.ReferenceRevision) &&
		!m.ValidUntil.IsZero() && m.ValidUntil.After(occurredAt) &&
		!m.ValidUntil.After(occurredAt.Add(maxMediaLease))
}

type PublicProjection struct {
	SourceDefaultLocale  Locale
	Localized            LocalizedProjections
	Rating               *RatingSummary
	AsOf                 *time.Time
	ValidUntil           *time.Time
	CanonicalDetailRoute string
	Media                *MediaReference
}

func (p PublicProjection) Validate(target domain.SavedTarget, occurredAt time.Time) error {
	if target.IsZero() || occurredAt.IsZero() || !p.SourceDefaultLocale.IsValid() ||
		p.Localized.For(p.SourceDefaultLocale) == nil ||
		!validCanonicalRoute(target, p.CanonicalDetailRoute) {
		return NewPermanentError(ErrorCodeInvalidPublicProjection)
	}

	hasDynamicSummary := false
	for _, localized := range p.Localized.values() {
		if localized == nil {
			continue
		}
		if !localized.validate() {
			return NewPermanentError(ErrorCodeInvalidPublicProjection)
		}
		hasDynamicSummary = hasDynamicSummary ||
			localized.PriceSummary != "" || localized.AvailabilitySummary != ""
	}

	hasRating := p.Rating != nil
	if hasRating && !p.Rating.validate() {
		return NewPermanentError(ErrorCodeInvalidPublicProjection)
	}
	requiresAsOf := hasRating || hasDynamicSummary
	if requiresAsOf != (p.AsOf != nil) || (p.ValidUntil != nil && p.AsOf == nil) {
		return NewPermanentError(ErrorCodeInvalidPublicProjection)
	}
	if p.AsOf != nil {
		asOf := p.AsOf.UTC()
		if p.AsOf.IsZero() || asOf.After(occurredAt.Add(maxFutureClockSkew)) ||
			asOf.Before(occurredAt.Add(-maxSummaryAge)) {
			return NewPermanentError(ErrorCodeInvalidPublicProjection)
		}
	}
	if hasDynamicSummary && p.ValidUntil == nil {
		return NewPermanentError(ErrorCodeInvalidPublicProjection)
	}
	if p.ValidUntil != nil {
		validUntil := p.ValidUntil.UTC()
		if p.ValidUntil.IsZero() || !validUntil.After(p.AsOf.UTC()) ||
			validUntil.After(p.AsOf.UTC().Add(maxSummaryLease)) {
			return NewPermanentError(ErrorCodeInvalidPublicProjection)
		}
	}
	if p.Media != nil && !p.Media.validate(occurredAt) {
		return NewPermanentError(ErrorCodeInvalidPublicProjection)
	}
	return nil
}

func (p PublicProjection) SearchDocument(locale Locale) *string {
	localized := p.Localized.For(locale)
	if localized == nil {
		return nil
	}
	parts := []string{
		localized.Title,
		localized.Subtitle,
		localized.City,
		localized.Country,
		localized.DisplayLocation,
	}
	normalized := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			normalized = append(normalized, part)
		}
	}
	if len(normalized) == 0 {
		return nil
	}
	document := norm.NFKC.String(strings.Join(normalized, " "))
	document = cases.Fold().String(document)
	document = strings.Join(strings.FieldsFunc(document, unicode.IsSpace), " ")
	return &document
}

type Event struct {
	EventID             uuid.UUID
	Subject             string
	SourceService       string
	SchemaVersion       uint16
	Kind                EventKind
	Target              domain.SavedTarget
	Revisions           Revisions
	OccurredAt          time.Time
	Visibility          domain.VisibilityStatus
	PublicProjection    *PublicProjection
	EnvelopeFingerprint [32]byte
}

func (e Event) Validate(now time.Time) error {
	contract, ok := ContractForSubject(e.Subject)
	if !ok || contract.SourceService != e.SourceService ||
		contract.SchemaVersion != e.SchemaVersion {
		return NewPermanentError(ErrorCodeInvalidSubject)
	}
	if e.EventID == uuid.Nil || e.EventID.Version() != 4 || e.EventID.Variant() != uuid.RFC4122 {
		return NewPermanentError(ErrorCodeInvalidEventID)
	}
	if e.Target.IsZero() || e.Target.EntityType() != contract.EntityType {
		return NewPermanentError(ErrorCodeInvalidTarget)
	}
	if !e.Revisions.IsValid() {
		return NewPermanentError(ErrorCodeInvalidRevision)
	}
	if now.IsZero() || e.OccurredAt.IsZero() || e.OccurredAt.Before(time.Unix(0, 0).UTC()) ||
		e.OccurredAt.After(now.UTC().Add(maxFutureClockSkew)) {
		return NewPermanentError(ErrorCodeInvalidTimestamp)
	}
	if !e.Kind.IsValid() || !e.Visibility.IsValid() || e.Visibility == domain.VisibilityUnknown ||
		!validKindVisibility(e.Kind, e.Visibility) {
		return NewPermanentError(ErrorCodeInvalidKindVisibility)
	}
	if e.Visibility == domain.VisibilityPrivate && e.Target.EntityType() != domain.EntityTypeActivity {
		return NewPermanentError(ErrorCodeInvalidKindVisibility)
	}
	if e.Visibility != domain.VisibilityPublic && e.PublicProjection != nil {
		return NewPermanentError(ErrorCodePayloadForbidden)
	}
	if e.PublicProjection != nil {
		if err := e.PublicProjection.Validate(e.Target, e.OccurredAt.UTC()); err != nil {
			return err
		}
	}
	if e.EnvelopeFingerprint == ([32]byte{}) {
		return NewPermanentError(ErrorCodeMalformedProtobuf)
	}
	return nil
}

func validKindVisibility(kind EventKind, visibility domain.VisibilityStatus) bool {
	switch kind {
	case EventPublished, EventUpdated:
		return visibility == domain.VisibilityPublic
	case EventUnavailable:
		return visibility == domain.VisibilityUnavailable
	case EventDeleted:
		return visibility == domain.VisibilityDeleted
	case EventVisibilityChanged:
		return visibility == domain.VisibilityPublic ||
			visibility == domain.VisibilityPrivate ||
			visibility == domain.VisibilityRestricted
	default:
		return false
	}
}

func positiveDatabaseRevision(value uint64) bool {
	return value > 0 && value <= math.MaxInt64
}

func validRequiredText(value string, maxBytes int) bool {
	return value != "" && validOptionalText(value, maxBytes)
}

func validOptionalText(value string, maxBytes int) bool {
	return len(value) <= maxBytes && utf8.ValidString(value) &&
		value == strings.TrimSpace(value) &&
		strings.IndexFunc(value, unicode.IsControl) < 0
}

func validCanonicalRoute(target domain.SavedTarget, route string) bool {
	if target.IsZero() || !validRequiredText(route, maxCanonicalRouteBytes) ||
		strings.ContainsAny(route, "?#%\\") {
		return false
	}

	var routeSegment string
	switch target.EntityType() {
	case domain.EntityTypeAttraction:
		var found bool
		routeSegment, found = strings.CutPrefix(route, "/places/")
		if !found || strings.Contains(routeSegment, "/") {
			return false
		}
	case domain.EntityTypeActivity:
		var found bool
		routeSegment, found = strings.CutPrefix(route, "/activities/")
		if !found || strings.Contains(routeSegment, "/") {
			return false
		}
	case domain.EntityTypeGuide, domain.EntityTypeUser:
		trimmed, found := strings.CutPrefix(route, "/users/")
		if !found || !strings.HasSuffix(trimmed, "/profile") {
			return false
		}
		routeSegment = strings.TrimSuffix(trimmed, "/profile")
		if strings.Contains(routeSegment, "/") {
			return false
		}
	default:
		return false
	}

	return validCanonicalRouteSegment(routeSegment)
}

func validCanonicalRouteSegment(value string) bool {
	if value == "" || value == "." || value == ".." || len(value) > 128 {
		return false
	}
	for _, character := range value {
		if (character >= 'a' && character <= 'z') ||
			(character >= 'A' && character <= 'Z') ||
			(character >= '0' && character <= '9') ||
			strings.ContainsRune("-._~", character) {
			continue
		}
		return false
	}
	return true
}
