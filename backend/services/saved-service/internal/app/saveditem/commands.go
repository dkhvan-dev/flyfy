package saveditem

import (
	"crypto/subtle"
	"math"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	DefaultMaxActiveSaves   uint64 = 10_000
	operationHMACSize              = 32
	maxSourceServiceBytes          = 64
	maxTitleBytes                  = 1024
	maxSubtitleBytes               = 2048
	maxLocationPartBytes           = 256
	maxDisplayLocationBytes        = 1024
	maxSearchDocumentBytes         = 32_768
	maxReferenceBytes              = 2048
	maxDynamicSummaryBytes         = 256
	maxRatingScale                 = 100
	maxProjectionClockSkew         = 5 * time.Second
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

type LocalizedText struct {
	EN *string
	RU *string
	KK *string
}

func (t LocalizedText) For(locale Locale) *string {
	switch locale {
	case LocaleEN:
		return t.EN
	case LocaleRU:
		return t.RU
	case LocaleKK:
		return t.KK
	default:
		return nil
	}
}

type Rating struct {
	Value       float64
	ReviewCount uint64
	ScaleMax    float64
}

type MediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

type PublicProjectionSnapshot struct {
	Target                   domain.SavedTarget
	SourceService            string
	SourceRevision           uint64
	ProjectionRevision       uint64
	VisibilityRevision       uint64
	VisibilityValidatedAt    time.Time
	SourceDefaultLocale      Locale
	Title                    LocalizedText
	Subtitle                 LocalizedText
	City                     LocalizedText
	Country                  LocalizedText
	DisplayLocation          LocalizedText
	SearchDocumentVersion    uint64
	NormalizedSearchDocument LocalizedText
	Media                    *MediaReference
	Rating                   *Rating
	PriceSummary             LocalizedText
	AvailabilitySummary      LocalizedText
	AsOf                     *time.Time
	ValidUntil               *time.Time
	CanonicalDetailRoute     *string
	ShellExpiresAt           time.Time
}

type MutationIdentity struct {
	SubjectID             uuid.UUID
	SessionGeneration     uuid.UUID
	OperationID           uuid.UUID
	Kind                  domain.OperationKind
	SemanticRequestHMAC   []byte
	RequestHMACKeyVersion uint32
}

func (i MutationIdentity) Validate(expectedKind domain.OperationKind) error {
	if i.SubjectID == uuid.Nil || i.SessionGeneration == uuid.Nil ||
		!isUUIDv4(i.OperationID) || !expectedKind.IsValid() || i.Kind != expectedKind ||
		len(i.SemanticRequestHMAC) != operationHMACSize || i.RequestHMACKeyVersion == 0 {
		return ErrInvalidCommand
	}
	return nil
}

func (i MutationIdentity) Matches(receipt *domain.SavedOperation) bool {
	if receipt == nil || receipt.SubjectID() != i.SubjectID ||
		receipt.SessionGeneration() != i.SessionGeneration ||
		receipt.OperationID() != i.OperationID || receipt.Kind() != i.Kind ||
		receipt.RequestHMACKeyVersion() != i.RequestHMACKeyVersion {
		return false
	}
	persistedHMAC := receipt.SemanticRequestHMAC()
	return len(persistedHMAC) == len(i.SemanticRequestHMAC) &&
		subtle.ConstantTimeCompare(persistedHMAC, i.SemanticRequestHMAC) == 1
}

type SaveCommand struct {
	Identity                  MutationIdentity
	OwnerUserID               uuid.UUID
	Projection                PublicProjectionSnapshot
	SavedItemID               uuid.UUID
	StateGeneration           uuid.UUID
	RelationshipAttributionID uuid.UUID
	ActivatedOutboxEventID    uuid.UUID
	MaxActiveSaves            uint64
	ServerNow                 time.Time
}

type PrepareProjectionShellCommand struct {
	Identity       MutationIdentity
	Target         domain.SavedTarget
	SourceService  string
	ShellExpiresAt time.Time
	ServerNow      time.Time
}

func (c PrepareProjectionShellCommand) ValidateIdentity() error {
	if err := c.Identity.Validate(domain.OperationKindSave); err != nil ||
		c.Target.IsZero() || !validSourceService(c.SourceService) || c.ServerNow.IsZero() {
		return ErrInvalidCommand
	}
	return nil
}

func (c PrepareProjectionShellCommand) Validate(commitDeadline time.Time) error {
	if err := c.ValidateIdentity(); err != nil || commitDeadline.IsZero() ||
		!c.ServerNow.Before(commitDeadline) ||
		!c.ShellExpiresAt.After(commitDeadline) ||
		c.ShellExpiresAt.After(c.ServerNow.Add(time.Hour)) {
		return ErrInvalidCommand
	}
	return nil
}

func (c SaveCommand) ValidateIdentity() error {
	if err := c.Identity.Validate(domain.OperationKindSave); err != nil {
		return err
	}
	if c.OwnerUserID == uuid.Nil || c.ServerNow.IsZero() {
		return ErrInvalidCommand
	}
	return nil
}

func (c SaveCommand) Validate(commitDeadline time.Time) error {
	if err := c.ValidateIdentity(); err != nil {
		return err
	}
	if !isUUIDv4(c.SavedItemID) || !isUUIDv4(c.StateGeneration) ||
		!isUUIDv4(c.RelationshipAttributionID) || !isUUIDv4(c.ActivatedOutboxEventID) ||
		c.EffectiveMaxActiveSaves() > math.MaxInt64 ||
		c.ServerNow.Before(commitDeadline.Add(-15*time.Second)) ||
		!c.ServerNow.Before(commitDeadline) {
		return ErrInvalidCommand
	}
	return c.Projection.Validate(c.ServerNow, commitDeadline)
}

func (c SaveCommand) EffectiveMaxActiveSaves() uint64 {
	if c.MaxActiveSaves == 0 {
		return DefaultMaxActiveSaves
	}
	return c.MaxActiveSaves
}

type GlobalUnsaveCommand struct {
	Identity             MutationIdentity
	OwnerUserID          uuid.UUID
	Target               domain.SavedTarget
	RemovedOutboxEventID uuid.UUID
	ServerNow            time.Time
}

func (c GlobalUnsaveCommand) ValidateIdentity() error {
	if err := c.Identity.Validate(domain.OperationKindUnsave); err != nil {
		return err
	}
	if c.OwnerUserID == uuid.Nil || c.ServerNow.IsZero() {
		return ErrInvalidCommand
	}
	return nil
}

func (c GlobalUnsaveCommand) Validate(commitDeadline time.Time) error {
	if err := c.ValidateIdentity(); err != nil {
		return err
	}
	if c.Target.IsZero() || !isUUIDv4(c.RemovedOutboxEventID) ||
		!c.ServerNow.Before(commitDeadline) {
		return ErrInvalidCommand
	}
	return nil
}

type RejectPendingCommand struct {
	Identity     MutationIdentity
	Cause        *domain.DomainError
	RefreshScope domain.RefreshScope
	ServerNow    time.Time
}

func (c RejectPendingCommand) Validate() error {
	if err := c.Identity.Validate(c.Identity.Kind); err != nil || c.ServerNow.IsZero() ||
		!c.RefreshScope.IsValid() || !IsPersistableRejection(c.Cause) {
		return ErrInvalidCommand
	}
	return nil
}

type OperationLookup struct {
	SubjectID         uuid.UUID
	SessionGeneration uuid.UUID
	OperationID       uuid.UUID
	ServerNow         time.Time
}

func (q OperationLookup) Validate() error {
	if q.SubjectID == uuid.Nil || q.SessionGeneration == uuid.Nil ||
		!isUUIDv4(q.OperationID) || q.ServerNow.IsZero() {
		return ErrInvalidCommand
	}
	return nil
}

func IsPersistableRejection(cause *domain.DomainError) bool {
	if cause == nil {
		return false
	}
	switch cause.Code {
	case domain.ErrorCodeTargetTypeUnsupported,
		domain.ErrorCodeTargetUnavailable,
		domain.ErrorCodeDependencyUnavailable,
		domain.ErrorCodeMutationStale,
		domain.ErrorCodeReplayMismatch,
		domain.ErrorCodeCollectionNotFound,
		domain.ErrorCodeCollectionDeleted,
		domain.ErrorCodeCollectionTitleInvalid,
		domain.ErrorCodeCollectionTitleConflict,
		domain.ErrorCodeCollectionLimitReached,
		domain.ErrorCodeCollectionItemLimitReached,
		domain.ErrorCodeMembershipLimitReached,
		domain.ErrorCodeItemLimitReached,
		domain.ErrorCodeRateLimited,
		domain.ErrorCodeTemporarilyUnavailable,
		domain.ErrorCodePlatformPersonalDataLocked:
		return true
	default:
		return false
	}
}

func (p PublicProjectionSnapshot) Validate(serverNow, commitDeadline time.Time) error {
	if p.Target.IsZero() || !validSourceService(p.SourceService) ||
		!positiveDBRevision(p.SourceRevision) || !positiveDBRevision(p.ProjectionRevision) ||
		!positiveDBRevision(p.VisibilityRevision) || !positiveDBRevision(p.SearchDocumentVersion) ||
		p.VisibilityValidatedAt.IsZero() || !p.SourceDefaultLocale.IsValid() ||
		p.ShellExpiresAt.IsZero() || !p.ShellExpiresAt.After(commitDeadline) ||
		p.ShellExpiresAt.After(serverNow.Add(time.Hour)) {
		return ErrInvalidCommand
	}
	if err := validateLocalized(p.Title, maxTitleBytes, true); err != nil ||
		p.Title.For(p.SourceDefaultLocale) == nil {
		return ErrInvalidCommand
	}
	if err := validateLocalized(p.Subtitle, maxSubtitleBytes, false); err != nil {
		return err
	}
	if err := validateLocalized(p.City, maxLocationPartBytes, false); err != nil {
		return err
	}
	if err := validateLocalized(p.Country, maxLocationPartBytes, false); err != nil {
		return err
	}
	if err := validateLocalized(p.DisplayLocation, maxDisplayLocationBytes, false); err != nil {
		return err
	}
	if err := validateLocalized(p.NormalizedSearchDocument, maxSearchDocumentBytes, false); err != nil {
		return err
	}
	if !validOptionalString(p.CanonicalDetailRoute, maxReferenceBytes) {
		return ErrInvalidCommand
	}
	if p.Media != nil && (!validBoundedText(p.Media.OpaqueReference, maxReferenceBytes) ||
		!positiveDBRevision(p.Media.ReferenceRevision) || p.Media.ValidUntil.IsZero() ||
		!p.Media.ValidUntil.After(serverNow) ||
		!p.Media.ValidUntil.After(p.VisibilityValidatedAt) ||
		p.Media.ValidUntil.After(p.VisibilityValidatedAt.Add(15*time.Minute))) {
		return ErrInvalidCommand
	}
	if p.Rating != nil && (math.IsNaN(p.Rating.Value) || math.IsInf(p.Rating.Value, 0) ||
		math.IsNaN(p.Rating.ScaleMax) || math.IsInf(p.Rating.ScaleMax, 0) ||
		p.Rating.ScaleMax <= 0 || p.Rating.ScaleMax > maxRatingScale ||
		p.Rating.Value < 0 || p.Rating.Value > p.Rating.ScaleMax ||
		p.Rating.ReviewCount > math.MaxInt64) {
		return ErrInvalidCommand
	}
	if err := validateLocalized(p.PriceSummary, maxDynamicSummaryBytes, false); err != nil {
		return err
	}
	if err := validateLocalized(p.AvailabilitySummary, maxDynamicSummaryBytes, false); err != nil {
		return err
	}
	hasDynamicSummary := hasLocalizedValue(p.PriceSummary) || hasLocalizedValue(p.AvailabilitySummary)
	requiresAsOf := hasDynamicSummary || p.Rating != nil
	if requiresAsOf != (p.AsOf != nil) || (p.ValidUntil != nil && p.AsOf == nil) {
		return ErrInvalidCommand
	}
	if hasDynamicSummary && p.ValidUntil == nil {
		return ErrInvalidCommand
	}
	if p.AsOf != nil && (p.AsOf.IsZero() || p.AsOf.After(serverNow.Add(maxProjectionClockSkew))) {
		return ErrInvalidCommand
	}
	if p.ValidUntil != nil && (p.ValidUntil.IsZero() || !p.ValidUntil.After(serverNow) ||
		!p.ValidUntil.After(*p.AsOf)) {
		return ErrInvalidCommand
	}
	return nil
}

func positiveDBRevision(value uint64) bool {
	return value > 0 && value <= math.MaxInt64
}

func validSourceService(value string) bool {
	if value == "" || len(value) > maxSourceServiceBytes || value[0] < 'a' || value[0] > 'z' {
		return false
	}
	for _, char := range value[1:] {
		if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-' {
			continue
		}
		return false
	}
	return true
}

func validateLocalized(value LocalizedText, maxBytes int, requireOne bool) error {
	values := []*string{value.EN, value.RU, value.KK}
	present := false
	for _, candidate := range values {
		if candidate == nil {
			continue
		}
		present = true
		if !validBoundedText(*candidate, maxBytes) {
			return ErrInvalidCommand
		}
	}
	if requireOne && !present {
		return ErrInvalidCommand
	}
	return nil
}

func validOptionalString(value *string, maxBytes int) bool {
	return value == nil || validBoundedText(*value, maxBytes)
}

func validBoundedText(value string, maxBytes int) bool {
	if value == "" || value != strings.TrimSpace(value) || !utf8.ValidString(value) || len(value) > maxBytes {
		return false
	}
	return strings.IndexFunc(value, unicode.IsControl) < 0
}

func hasLocalizedValue(value LocalizedText) bool {
	return value.EN != nil || value.RU != nil || value.KK != nil
}

func isUUIDv4(value uuid.UUID) bool {
	return value != uuid.Nil && value.Version() == 4 && value.Variant() == uuid.RFC4122
}
