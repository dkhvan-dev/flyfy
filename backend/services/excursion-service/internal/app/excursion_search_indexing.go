package app

import (
	"context"
	"strings"
	"unicode"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/excursion-service/internal/domain/enum"
	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

const fallbackExcursionLocale = "en"

type ExcursionSearchIndexer interface {
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

func (u *ExcursionUseCase) SetSearchIndexer(indexer ExcursionSearchIndexer) {
	u.searchIndexer = indexer
}

func (u *ExcursionUseCase) syncExcursionSearchDocument(ctx context.Context, aggregate *ExcursionAggregate) {
	if u.searchIndexer == nil || aggregate == nil || aggregate.Excursion == nil || aggregate.Excursion.ID == uuid.Nil {
		return
	}
	item := aggregate.Excursion
	if !isExcursionSearchIndexable(item) {
		u.deleteExcursionSearchDocument(ctx, item.ID)
		return
	}

	document := excursionSearchDocument(item, aggregate.relations())
	if err := u.searchIndexer.UpsertSearchDocument(ctx, document); err != nil {
		log.Warn().
			Err(err).
			Str("excursion_id", item.ID.String()).
			Msg("failed to upsert excursion search document")
	}
}

func (u *ExcursionUseCase) deleteExcursionSearchDocument(ctx context.Context, excursionID uuid.UUID) {
	if u.searchIndexer == nil || excursionID == uuid.Nil {
		return
	}
	if err := u.searchIndexer.DeleteSearchDocument(ctx, SearchIndexDelete{
		Domain:   "excursion",
		EntityID: excursionID.String(),
		Locale:   fallbackExcursionLocale,
	}); err != nil {
		log.Warn().
			Err(err).
			Str("excursion_id", excursionID.String()).
			Msg("failed to delete excursion search document")
	}
}

func (a *ExcursionAggregate) relations() port.ExcursionRelations {
	if a == nil {
		return port.ExcursionRelations{}
	}
	return port.ExcursionRelations{
		Tags:                  append([]string(nil), a.Tags...),
		LanguageCodes:         append([]string(nil), a.LanguageCodes...),
		IncludedItems:         append([]model.ExcursionIncludedItem(nil), a.IncludedItems...),
		Itinerary:             append([]*model.ExcursionItineraryItem(nil), a.Itinerary...),
		CoverFileID:           a.CoverFileID,
		PhotoFileIDs:          append([]uuid.UUID(nil), a.PhotoFileIDs...),
		ProductCoverFileID:    a.ProductCoverFileID,
		ProductCoverImageURL:  a.ProductCoverImageURL,
		ProductPhotoFileIDs:   append([]uuid.UUID(nil), a.ProductPhotoFileIDs...),
		ProductPhotoImageURLs: append([]string(nil), a.ProductPhotoImageURLs...),
	}
}

func isExcursionSearchIndexable(item *model.Excursion) bool {
	return item != nil &&
		item.Status == enum.ExcursionStatusPublished &&
		item.Visibility == enum.ExcursionVisibilityPublic &&
		item.DeletedAt == nil
}

func excursionSearchDocument(item *model.Excursion, relations port.ExcursionRelations) SearchIndexDocument {
	locale := primaryExcursionLocale(relations.LanguageCodes)
	title := excursionLocalizedTitle(item, locale)
	subtitle := excursionLocalizedSubtitle(item, locale)
	description := excursionLocalizedDescription(item, locale)
	tags := normalizeExcursionSearchList(relations.Tags)
	categoryCodes := excursionSearchCategoryCodes(item, relations)
	searchText := buildExcursionSearchText(item, relations, title, subtitle, description, tags, categoryCodes)
	price := item.PriceAmount
	rating := item.GuideRatingAvg
	trustScore := float64(item.GuideTrustScore) / 100
	if trustScore <= 0 {
		trustScore = 0.7
	}

	return SearchIndexDocument{
		Domain:               "excursion",
		EntityID:             item.ID.String(),
		EntityVersion:        int64(item.Revision),
		Locale:               locale,
		Title:                title,
		Subtitle:             subtitle,
		Description:          description,
		Tags:                 tags,
		CategoryCodes:        categoryCodes,
		CityID:               excursionOptionalString(item.DepartureCityID),
		CountryCode:          strings.ToUpper(excursionOptionalString(item.CountryCode)),
		Latitude:             item.Latitude,
		Longitude:            item.Longitude,
		PriceMin:             &price,
		PriceMax:             &price,
		Currency:             strings.ToUpper(strings.TrimSpace(item.Currency)),
		Rating:               &rating,
		ReviewCount:          item.GuideReviewsCount,
		PopularityScore:      excursionPopularityScore(item),
		FreshnessScore:       1,
		TrustScore:           trustScore,
		AvailabilityStatus:   strings.ToLower(string(item.Status)),
		Visibility:           "public",
		ModerationStatus:     "approved",
		DeepLink:             "/excursions/" + item.ID.String(),
		SearchText:           searchText,
		SearchTextNormalized: normalizeExcursionSearchText(searchText),
		SearchVariants:       excursionSearchVariants(item, relations, tags, categoryCodes),
	}
}

func primaryExcursionLocale(languageCodes []string) string {
	for _, code := range languageCodes {
		code = strings.ToLower(strings.TrimSpace(code))
		if code != "" {
			return code
		}
	}
	return fallbackExcursionLocale
}

func excursionLocalizedTitle(item *model.Excursion, fallbackLocale string) map[string]string {
	values := map[string]string{fallbackLocale: strings.TrimSpace(item.Title)}
	for locale, copy := range item.ProductTranslations {
		if title := strings.TrimSpace(copy.Title); title != "" {
			values[normalizeExcursionLocale(locale)] = title
		}
	}
	for locale, copy := range item.Translations {
		if title := strings.TrimSpace(copy.Title); title != "" {
			values[normalizeExcursionLocale(locale)] = title
		}
	}
	return values
}

func excursionLocalizedSubtitle(item *model.Excursion, fallbackLocale string) map[string]string {
	parts := make([]string, 0, 4)
	if city := excursionOptionalString(item.CityName); city != "" {
		parts = append(parts, city)
	}
	if landmark := excursionOptionalString(item.LandmarkName); landmark != "" {
		parts = append(parts, landmark)
	}
	if guide := strings.TrimSpace(item.GuideDisplayName); guide != "" {
		parts = append(parts, guide)
	}
	if len(parts) == 0 {
		return nil
	}
	return map[string]string{fallbackLocale: strings.Join(parts, " - ")}
}

func excursionLocalizedDescription(item *model.Excursion, fallbackLocale string) map[string]string {
	values := map[string]string{fallbackLocale: strings.TrimSpace(item.Description)}
	for locale, copy := range item.ProductTranslations {
		if description := strings.TrimSpace(copy.Description); description != "" {
			values[normalizeExcursionLocale(locale)] = description
		}
	}
	for locale, copy := range item.Translations {
		if description := strings.TrimSpace(copy.Description); description != "" {
			values[normalizeExcursionLocale(locale)] = description
		}
	}
	return values
}

func excursionSearchCategoryCodes(item *model.Excursion, relations port.ExcursionRelations) []string {
	values := []string{
		item.CategorySlug,
		excursionOptionalString(item.DepartureCityID),
	}
	values = append(values, relations.LanguageCodes...)
	return normalizeExcursionSearchList(values)
}

func buildExcursionSearchText(
	item *model.Excursion,
	relations port.ExcursionRelations,
	title map[string]string,
	subtitle map[string]string,
	description map[string]string,
	tags []string,
	categoryCodes []string,
) string {
	parts := make([]string, 0, len(title)+len(subtitle)+len(description)+len(tags)+len(categoryCodes)+len(relations.Itinerary)+8)
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
		item.Summary,
		item.GuideDisplayName,
		item.GuideSearchText,
		excursionOptionalString(item.CityName),
		excursionOptionalString(item.CountryCode),
		excursionOptionalString(item.LandmarkName),
	)
	for _, itineraryItem := range relations.Itinerary {
		if itineraryItem == nil {
			continue
		}
		parts = append(parts, itineraryItem.Title, itineraryItem.Description, excursionOptionalString(itineraryItem.PlaceName))
	}
	return strings.Join(parts, " ")
}

func excursionSearchVariants(
	item *model.Excursion,
	relations port.ExcursionRelations,
	tags []string,
	categoryCodes []string,
) []string {
	values := append([]string{}, tags...)
	values = append(values, categoryCodes...)
	values = append(values,
		item.GuideDisplayName,
		item.GuideSearchText,
		excursionOptionalString(item.CityName),
		excursionOptionalString(item.CountryCode),
		excursionOptionalString(item.LandmarkName),
	)
	for _, itineraryItem := range relations.Itinerary {
		if itineraryItem == nil {
			continue
		}
		values = append(values, itineraryItem.Title, excursionOptionalString(itineraryItem.PlaceName))
	}
	return normalizeExcursionSearchList(values)
}

func normalizeExcursionSearchText(value string) string {
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

func normalizeExcursionSearchList(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		value = normalizeExcursionSearchText(value)
		value = strings.ReplaceAll(value, " ", "-")
		if value == "" {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func normalizeExcursionLocale(locale string) string {
	locale = strings.ToLower(strings.TrimSpace(locale))
	if locale == "" {
		return fallbackExcursionLocale
	}
	return locale
}

func excursionOptionalString(value *string) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(*value)
}

func excursionPopularityScore(item *model.Excursion) float64 {
	if item == nil {
		return 0
	}
	ratingScore := item.GuideRatingAvg / 5
	if ratingScore < 0 {
		ratingScore = 0
	}
	if ratingScore > 1 {
		ratingScore = 1
	}
	reviewScore := float64(item.GuideReviewsCount) / 100
	if reviewScore > 1 {
		reviewScore = 1
	}
	return ratingScore*0.7 + reviewScore*0.3
}
