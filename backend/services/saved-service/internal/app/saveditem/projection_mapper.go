package saveditem

import (
	"strings"
	"time"
	"unicode"

	"golang.org/x/text/cases"
	"golang.org/x/text/unicode/norm"

	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const projectionShellLifetime = time.Hour

// BuildPublicProjectionSnapshot is shared by every Saved mutation that can
// introduce a PUBLIC relationship. It keeps projection normalization and
// validation identical for direct save and collection-assignment expansion.
func BuildPublicProjectionSnapshot(
	resolution appsource.Resolution,
	serverNow time.Time,
	commitDeadline time.Time,
) (PublicProjectionSnapshot, error) {
	return projectionSnapshot(resolution, serverNow, commitDeadline)
}

func SourceServiceFor(entityType domain.EntityType) string {
	return sourceServiceFor(entityType)
}

func projectionSnapshot(
	resolution appsource.Resolution,
	serverNow time.Time,
	commitDeadline time.Time,
) (PublicProjectionSnapshot, error) {
	if resolution.PublicProjection == nil || !resolution.Eligible ||
		resolution.Visibility != domain.VisibilityPublic {
		return PublicProjectionSnapshot{}, ErrInvalidCommand
	}
	projection := resolution.PublicProjection
	localized := func(selectValue func(appsource.LocalizedCardProjection) string) LocalizedText {
		return LocalizedText{
			EN: optionalSourceText(selectValue(projection.Localized[appsource.LocaleEN])),
			RU: optionalSourceText(selectValue(projection.Localized[appsource.LocaleRU])),
			KK: optionalSourceText(selectValue(projection.Localized[appsource.LocaleKK])),
		}
	}
	title := localized(func(value appsource.LocalizedCardProjection) string { return value.Title })
	subtitle := localized(func(value appsource.LocalizedCardProjection) string { return value.Subtitle })
	city := localized(func(value appsource.LocalizedCardProjection) string { return value.City })
	country := localized(func(value appsource.LocalizedCardProjection) string { return value.Country })
	displayLocation := localized(func(value appsource.LocalizedCardProjection) string { return value.DisplayLocation })
	price := localized(func(value appsource.LocalizedCardProjection) string { return value.PriceSummary })
	availability := localized(func(value appsource.LocalizedCardProjection) string { return value.AvailabilitySummary })
	searchDocument := LocalizedText{
		EN: normalizedSearchDocument(projection.Localized[appsource.LocaleEN]),
		RU: normalizedSearchDocument(projection.Localized[appsource.LocaleRU]),
		KK: normalizedSearchDocument(projection.Localized[appsource.LocaleKK]),
	}

	snapshot := PublicProjectionSnapshot{
		Target:                   resolution.Target,
		SourceService:            sourceServiceFor(resolution.Target.EntityType()),
		SourceRevision:           resolution.Revisions.Source,
		ProjectionRevision:       resolution.Revisions.Projection,
		VisibilityRevision:       resolution.Revisions.Visibility,
		VisibilityValidatedAt:    resolution.ValidatedAt.UTC(),
		SourceDefaultLocale:      toSavedItemLocale(projection.SourceDefaultLocale),
		Title:                    title,
		Subtitle:                 subtitle,
		City:                     city,
		Country:                  country,
		DisplayLocation:          displayLocation,
		SearchDocumentVersion:    resolution.Revisions.Projection,
		NormalizedSearchDocument: searchDocument,
		PriceSummary:             price,
		AvailabilitySummary:      availability,
		AsOf:                     cloneTime(projection.AsOf),
		ValidUntil:               cloneTime(projection.ValidUntil),
		ShellExpiresAt:           serverNow.Add(projectionShellLifetime),
	}
	if projection.CanonicalDetailRoute != "" {
		route := projection.CanonicalDetailRoute
		snapshot.CanonicalDetailRoute = &route
	}
	if projection.Media != nil {
		snapshot.Media = &MediaReference{
			OpaqueReference:   projection.Media.OpaqueReference,
			ReferenceRevision: projection.Media.ReferenceRevision,
			ValidUntil:        projection.Media.ValidUntil.UTC(),
		}
	}
	if projection.Rating != nil {
		snapshot.Rating = &Rating{
			Value:       projection.Rating.Value,
			ReviewCount: projection.Rating.ReviewCount,
			ScaleMax:    projection.Rating.ScaleMax,
		}
	}
	if snapshot.SourceService == "" || !snapshot.ShellExpiresAt.After(commitDeadline) {
		return PublicProjectionSnapshot{}, ErrInvalidCommand
	}
	if err := snapshot.Validate(serverNow, commitDeadline); err != nil {
		return PublicProjectionSnapshot{}, err
	}
	return snapshot, nil
}

func sourceServiceFor(entityType domain.EntityType) string {
	switch entityType {
	case domain.EntityTypeAttraction:
		return "place-service"
	case domain.EntityTypeActivity:
		return "activity-service"
	case domain.EntityTypeUser:
		return "user-service"
	case domain.EntityTypePost:
		return "feed-service"
	default:
		return ""
	}
}

func toSavedItemLocale(locale appsource.Locale) Locale {
	switch locale {
	case appsource.LocaleEN:
		return LocaleEN
	case appsource.LocaleRU:
		return LocaleRU
	case appsource.LocaleKK:
		return LocaleKK
	default:
		return ""
	}
}

func optionalSourceText(value string) *string {
	if value == "" {
		return nil
	}
	copyValue := value
	return &copyValue
}

func normalizedSearchDocument(value appsource.LocalizedCardProjection) *string {
	parts := []string{
		value.Title,
		value.Subtitle,
		value.City,
		value.Country,
		value.DisplayLocation,
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
	return optionalSourceText(document)
}

func cloneTime(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}
	copyValue := value.UTC()
	return &copyValue
}
