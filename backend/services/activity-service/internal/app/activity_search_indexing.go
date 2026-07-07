package app

import (
	"context"
	"strings"
	"unicode"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

const fallbackActivityLocale = "en"

type ActivitySearchIndexer interface {
	UpsertSearchDocument(ctx context.Context, document SearchIndexDocument) error
	DeleteSearchDocument(ctx context.Context, deletion SearchIndexDelete) error
}

type SearchIndexDocument struct {
	Domain               string
	EntityID             string
	EntityVersion        int64
	Locale               string
	Title                map[string]string
	Subtitle             map[string]string
	Description          map[string]string
	Tags                 []string
	CategoryCodes        []string
	CityID               string
	CountryCode          string
	Latitude             *float64
	Longitude            *float64
	PriceMin             *float64
	PriceMax             *float64
	Currency             string
	Rating               *float64
	ReviewCount          int
	PopularityScore      float64
	FreshnessScore       float64
	TrustScore           float64
	AvailabilityStatus   string
	Visibility           string
	ModerationStatus     string
	DeepLink             string
	SearchText           string
	SearchTextNormalized string
	SearchVariants       []string
}

type SearchIndexDelete struct {
	Domain   string
	EntityID string
	Locale   string
}

func (u *ActivityUseCase) SetSearchIndexer(indexer ActivitySearchIndexer) {
	u.searchIndexer = indexer
}

func (u *ActivityUseCase) syncActivitySearchDocument(ctx context.Context, item *model.Activity) {
	if u.searchIndexer == nil || item == nil || item.ID == uuid.Nil {
		return
	}
	if !isActivitySearchIndexable(item) {
		u.deleteActivitySearchDocument(ctx, item.ID)
		return
	}

	tags, err := u.repo.ListTagsByActivityID(ctx, item.ID)
	if err != nil {
		log.Warn().
			Err(err).
			Str("activity_id", item.ID.String()).
			Msg("failed to resolve activity tags for search indexing")
		tags = nil
	}

	document := activitySearchDocument(item, tags)
	if err = u.searchIndexer.UpsertSearchDocument(ctx, document); err != nil {
		log.Warn().
			Err(err).
			Str("activity_id", item.ID.String()).
			Msg("failed to upsert activity search document")
	}
}

func (u *ActivityUseCase) deleteActivitySearchDocument(ctx context.Context, activityID uuid.UUID) {
	if u.searchIndexer == nil || activityID == uuid.Nil {
		return
	}
	if err := u.searchIndexer.DeleteSearchDocument(ctx, SearchIndexDelete{
		Domain:   "activity",
		EntityID: activityID.String(),
		Locale:   fallbackActivityLocale,
	}); err != nil {
		log.Warn().
			Err(err).
			Str("activity_id", activityID.String()).
			Msg("failed to delete activity search document")
	}
}

func isActivitySearchIndexable(item *model.Activity) bool {
	if item == nil {
		return false
	}
	return item.Visibility == enum.ActivityVisibilityPublic &&
		item.ModerationStatus == enum.ActivityModerationStatusApproved &&
		!item.Status.IsTerminal()
}

func activitySearchDocument(item *model.Activity, tags []string) SearchIndexDocument {
	locale := normalizeActivitySearchLocale(item.LanguageCode)
	title := map[string]string{locale: strings.TrimSpace(item.Title)}
	description := map[string]string{locale: strings.TrimSpace(item.Description)}
	subtitle := activitySearchSubtitle(item, locale)
	categoryCodes := activitySearchCategoryCodes(item)
	normalizedTags := normalizeTags(tags)
	searchText := buildActivitySearchText(item, title, subtitle, description, normalizedTags, categoryCodes)
	currency := model.ValueOrEmpty(item.Currency)

	return SearchIndexDocument{
		Domain:               "activity",
		EntityID:             item.ID.String(),
		EntityVersion:        int64(item.Revision),
		Locale:               locale,
		Title:                title,
		Subtitle:             subtitle,
		Description:          description,
		Tags:                 normalizedTags,
		CategoryCodes:        categoryCodes,
		CityID:               activitySearchCityID(item),
		CountryCode:          activitySearchCountryCode(item),
		Latitude:             item.Latitude,
		Longitude:            item.Longitude,
		PriceMin:             item.PriceAmount,
		PriceMax:             item.PriceAmount,
		Currency:             currency,
		PopularityScore:      activityPopularityScore(item),
		FreshnessScore:       activityFreshnessScore(item),
		TrustScore:           0.7,
		AvailabilityStatus:   strings.ToLower(string(item.Status)),
		Visibility:           "public",
		ModerationStatus:     "approved",
		DeepLink:             "/activities/" + item.ID.String(),
		SearchText:           searchText,
		SearchTextNormalized: normalizeActivitySearchText(searchText),
		SearchVariants:       activitySearchVariants(item, normalizedTags, categoryCodes),
	}
}

func activitySearchSubtitle(item *model.Activity, locale string) map[string]string {
	parts := make([]string, 0, 3)
	if city := strings.TrimSpace(model.ValueOrEmpty(item.CityName)); city != "" {
		parts = append(parts, city)
	}
	if city := strings.TrimSpace(model.ValueOrEmpty(item.AuthorCityName)); city != "" && !activitySearchContainsString(parts, city) {
		parts = append(parts, city)
	}
	if item.Format != "" {
		parts = append(parts, strings.ToLower(string(item.Format)))
	}
	if len(parts) == 0 {
		return nil
	}
	return map[string]string{locale: strings.Join(parts, " - ")}
}

func activitySearchCategoryCodes(item *model.Activity) []string {
	codes := make([]string, 0, 4)
	appendCode := func(value string) {
		value = strings.ToLower(strings.TrimSpace(value))
		if value == "" || activitySearchContainsString(codes, value) {
			return
		}
		codes = append(codes, value)
	}

	appendCode(item.CategorySlug)
	if item.SubcategorySlug != nil {
		appendCode(*item.SubcategorySlug)
	}
	appendCode(string(item.Format))
	appendCode(string(item.PriceType))
	return codes
}

func activitySearchCityID(item *model.Activity) string {
	if value := strings.TrimSpace(model.ValueOrEmpty(item.CityID)); value != "" {
		return value
	}
	return strings.TrimSpace(model.ValueOrEmpty(item.AuthorCityID))
}

func activitySearchCountryCode(item *model.Activity) string {
	if value := strings.TrimSpace(model.ValueOrEmpty(item.CountryCode)); value != "" {
		return strings.ToUpper(value)
	}
	return strings.ToUpper(strings.TrimSpace(model.ValueOrEmpty(item.AuthorCountryCode)))
}

func buildActivitySearchText(
	item *model.Activity,
	title map[string]string,
	subtitle map[string]string,
	description map[string]string,
	tags []string,
	categoryCodes []string,
) string {
	parts := make([]string, 0, len(title)+len(subtitle)+len(description)+len(tags)+len(categoryCodes)+8)
	for _, value := range title {
		parts = append(parts, value)
	}
	for _, value := range subtitle {
		parts = append(parts, value)
	}
	for _, value := range description {
		parts = append(parts, value)
	}
	parts = append(parts, tags...)
	parts = append(parts, categoryCodes...)
	parts = append(parts,
		model.ValueOrEmpty(item.CityID),
		model.ValueOrEmpty(item.CityName),
		model.ValueOrEmpty(item.CountryCode),
		model.ValueOrEmpty(item.AuthorCityID),
		model.ValueOrEmpty(item.AuthorCityName),
		model.ValueOrEmpty(item.AuthorCountryCode),
	)
	return strings.Join(parts, " ")
}

func normalizeActivitySearchText(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return ""
	}

	var builder strings.Builder
	builder.Grow(len(value))
	previousSpace := true
	for _, r := range value {
		if unicode.IsSpace(r) {
			if !previousSpace {
				builder.WriteRune(' ')
				previousSpace = true
			}
			continue
		}
		builder.WriteRune(r)
		previousSpace = false
	}
	return strings.TrimSpace(builder.String())
}

func activitySearchVariants(item *model.Activity, tags []string, categoryCodes []string) []string {
	values := make([]string, 0, len(tags)+len(categoryCodes)+6)
	values = append(values, tags...)
	values = append(values, categoryCodes...)
	values = append(values,
		model.ValueOrEmpty(item.CityID),
		model.ValueOrEmpty(item.CityName),
		model.ValueOrEmpty(item.CountryCode),
		model.ValueOrEmpty(item.AuthorCityID),
		model.ValueOrEmpty(item.AuthorCityName),
		model.ValueOrEmpty(item.AuthorCountryCode),
	)

	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		value = normalizeActivitySearchText(value)
		if value == "" {
			continue
		}
		if _, exists := seen[value]; exists {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func activityPopularityScore(item *model.Activity) float64 {
	if item == nil {
		return 0
	}
	switch item.Status {
	case enum.ActivityStatusFull, enum.ActivityStatusConfirmed:
		return 0.8
	case enum.ActivityStatusEnrollmentOpen, enum.ActivityStatusPublished:
		return 0.7
	case enum.ActivityStatusRegistrationClosed, enum.ActivityStatusStarted:
		return 0.45
	default:
		return 0.25
	}
}

func activityFreshnessScore(item *model.Activity) float64 {
	if item == nil {
		return 0
	}
	if item.StartAt.IsZero() {
		return 0.5
	}
	if item.StartAt.After(item.UpdatedAt) {
		return 1
	}
	return 0.35
}

func normalizeActivitySearchLocale(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return fallbackActivityLocale
	}
	return value
}

func activitySearchContainsString(items []string, needle string) bool {
	for _, item := range items {
		if item == needle {
			return true
		}
	}
	return false
}
