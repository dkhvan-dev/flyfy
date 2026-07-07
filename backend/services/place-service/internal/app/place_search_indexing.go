package app

import (
	"context"
	"strings"
	"unicode"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

type PlaceSearchIndexer interface {
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

func (u *PlaceUseCase) syncPlaceSearchDocument(ctx context.Context, place *model.Place) {
	if u.searchIndexer == nil || place == nil {
		return
	}
	if !place.IsPublished() {
		u.deletePlaceSearchDocument(ctx, place.ID)
		return
	}
	document := placeSearchDocument(place)
	_ = u.searchIndexer.UpsertSearchDocument(ctx, document)
}

func (u *PlaceUseCase) deletePlaceSearchDocument(ctx context.Context, placeID uuid.UUID) {
	if u.searchIndexer == nil || placeID == uuid.Nil {
		return
	}
	_ = u.searchIndexer.DeleteSearchDocument(ctx, SearchIndexDelete{
		Domain:   "place",
		EntityID: placeID.String(),
		Locale:   fallbackPlaceLocale,
	})
}

func placeSearchDocument(place *model.Place) SearchIndexDocument {
	title := placeLocalizedTitle(place)
	description := placeLocalizedDescription(place)
	searchText := buildPlaceSearchText(place, title, description)
	rating := place.Rating
	currency := ""
	if place.PriceCurrency != nil {
		currency = strings.ToUpper(strings.TrimSpace(*place.PriceCurrency))
	}

	return SearchIndexDocument{
		Domain:               "place",
		EntityID:             place.ID.String(),
		EntityVersion:        place.UpdatedAt.Unix(),
		Locale:               NormalizePlaceLocale(place.DefaultLocale),
		Title:                title,
		Description:          description,
		Tags:                 append([]string(nil), place.Tags...),
		CategoryCodes:        []string{strings.ToLower(place.Category.String())},
		CityID:               place.CityID,
		CountryCode:          place.CountryCode,
		Latitude:             place.Latitude,
		Longitude:            place.Longitude,
		PriceMin:             place.PriceAmount,
		PriceMax:             place.PriceAmount,
		Currency:             currency,
		Rating:               &rating,
		ReviewCount:          place.ReviewCount,
		PopularityScore:      placePopularityScore(place),
		FreshnessScore:       1,
		TrustScore:           0.75,
		AvailabilityStatus:   "available",
		Visibility:           "public",
		ModerationStatus:     "approved",
		DeepLink:             "/places/" + place.ID.String(),
		SearchText:           searchText,
		SearchTextNormalized: normalizePlaceSearchText(searchText),
		SearchVariants: append(
			append([]string(nil), place.Tags...),
			strings.ToLower(place.Category.String()),
			strings.ToLower(place.CityID),
			strings.ToLower(place.CountryCode),
		),
	}
}

func placeLocalizedTitle(place *model.Place) map[string]string {
	values := make(map[string]string)
	if strings.TrimSpace(place.Title) != "" {
		values[NormalizePlaceLocale(place.DefaultLocale)] = strings.TrimSpace(place.Title)
	}
	for locale, translation := range place.Translations {
		title := strings.TrimSpace(translation.Title)
		if title == "" {
			continue
		}
		values[NormalizePlaceLocale(locale)] = title
	}
	return values
}

func placeLocalizedDescription(place *model.Place) map[string]string {
	values := make(map[string]string)
	if strings.TrimSpace(place.Description) != "" {
		values[NormalizePlaceLocale(place.DefaultLocale)] = strings.TrimSpace(place.Description)
	}
	for locale, translation := range place.Translations {
		description := strings.TrimSpace(translation.Description)
		if description == "" {
			continue
		}
		values[NormalizePlaceLocale(locale)] = description
	}
	return values
}

func buildPlaceSearchText(place *model.Place, title map[string]string, description map[string]string) string {
	parts := make([]string, 0, len(title)+len(description)+len(place.Tags)+4)
	for _, value := range title {
		parts = append(parts, value)
	}
	for _, value := range description {
		parts = append(parts, value)
	}
	parts = append(parts, place.Tags...)
	parts = append(parts, place.Category.String(), place.CityID, place.CountryCode)
	return strings.Join(parts, " ")
}

func normalizePlaceSearchText(value string) string {
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

func placePopularityScore(place *model.Place) float64 {
	ratingScore := place.Rating / 5
	if ratingScore < 0 {
		ratingScore = 0
	}
	if ratingScore > 1 {
		ratingScore = 1
	}
	reviewScore := float64(place.ReviewCount) / 100
	if reviewScore > 1 {
		reviewScore = 1
	}
	return ratingScore*0.7 + reviewScore*0.3
}
