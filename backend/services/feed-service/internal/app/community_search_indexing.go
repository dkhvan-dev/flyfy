package app

import (
	"context"
	"strings"
	"unicode"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

const fallbackCommunityLocale = "ru"

type CommunitySearchIndexer interface {
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

func (u *PostUseCase) syncCommunitySearchDocument(ctx context.Context, community *model.Community) {
	if u.communitySearchIndexer == nil || community == nil || community.ID == uuid.Nil {
		return
	}
	if !community.IsPubliclyVisible() {
		u.deleteCommunitySearchDocument(ctx, community.ID)
		return
	}

	document := communitySearchDocument(community)
	if err := u.communitySearchIndexer.UpsertSearchDocument(ctx, document); err != nil {
		log.Warn().
			Err(err).
			Str("community_id", community.ID.String()).
			Msg("failed to upsert community search document")
	}
}

func (u *PostUseCase) deleteCommunitySearchDocument(ctx context.Context, communityID uuid.UUID) {
	if u.communitySearchIndexer == nil || communityID == uuid.Nil {
		return
	}
	if err := u.communitySearchIndexer.DeleteSearchDocument(ctx, SearchIndexDelete{
		Domain:   "community",
		EntityID: communityID.String(),
		Locale:   fallbackCommunityLocale,
	}); err != nil {
		log.Warn().
			Err(err).
			Str("community_id", communityID.String()).
			Msg("failed to delete community search document")
	}
}

func communitySearchDocument(community *model.Community) SearchIndexDocument {
	locale := normalizeCommunitySearchLocale(community.LanguageCode)
	title := localizedCommunitySearchText(community.TitleI18n, community.Title, locale)
	description := localizedCommunitySearchText(community.DescriptionI18n, community.Description, locale)
	subtitle := communitySearchSubtitle(community, locale)
	categoryCodes := communitySearchCategoryCodes(community)
	searchText := buildCommunitySearchText(community, title, subtitle, description, categoryCodes)

	return SearchIndexDocument{
		Domain:               "community",
		EntityID:             community.ID.String(),
		EntityVersion:        community.UpdatedAt.UnixNano(),
		Locale:               locale,
		Title:                title,
		Subtitle:             subtitle,
		Description:          description,
		CategoryCodes:        categoryCodes,
		CityID:               strings.TrimSpace(valueOrEmptyStringPtr(community.CityID)),
		CountryCode:          strings.ToUpper(strings.TrimSpace(valueOrEmptyStringPtr(community.CountryCode))),
		PopularityScore:      communitySearchPopularityScore(community),
		FreshnessScore:       0.5,
		TrustScore:           0.65,
		AvailabilityStatus:   strings.ToLower(string(community.Status)),
		Visibility:           "public",
		ModerationStatus:     "approved",
		DeepLink:             "/communities/" + community.ID.String(),
		SearchText:           searchText,
		SearchTextNormalized: normalizeCommunitySearchText(searchText),
		SearchVariants:       communitySearchVariants(community, categoryCodes),
	}
}

func localizedCommunitySearchText(values map[string]string, fallback string, locale string) map[string]string {
	result := make(map[string]string, len(requiredCommunityLocales))
	for _, key := range requiredCommunityLocales {
		value := strings.TrimSpace(values[key])
		if value != "" {
			result[key] = value
		}
	}
	if len(result) == 0 {
		if trimmed := strings.TrimSpace(fallback); trimmed != "" {
			result[locale] = trimmed
		}
	}
	return result
}

func communitySearchSubtitle(community *model.Community, locale string) map[string]string {
	parts := make([]string, 0, 3)
	if community.Topic != "" {
		parts = append(parts, strings.ToLower(strings.TrimSpace(community.Topic)))
	}
	if cityID := strings.TrimSpace(valueOrEmptyStringPtr(community.CityID)); cityID != "" {
		parts = append(parts, cityID)
	}
	if countryCode := strings.TrimSpace(valueOrEmptyStringPtr(community.CountryCode)); countryCode != "" {
		parts = append(parts, strings.ToUpper(countryCode))
	}
	if len(parts) == 0 {
		return nil
	}
	return map[string]string{locale: strings.Join(parts, " - ")}
}

func communitySearchCategoryCodes(community *model.Community) []string {
	codes := make([]string, 0, 2)
	appendCode := func(value string) {
		value = strings.ToLower(strings.TrimSpace(value))
		if value == "" || communitySearchContainsString(codes, value) {
			return
		}
		codes = append(codes, value)
	}
	appendCode(community.Topic)
	appendCode(community.Slug)
	return codes
}

func buildCommunitySearchText(
	community *model.Community,
	title map[string]string,
	subtitle map[string]string,
	description map[string]string,
	categoryCodes []string,
) string {
	parts := make([]string, 0, len(title)+len(subtitle)+len(description)+len(categoryCodes)+6)
	for _, value := range title {
		parts = append(parts, value)
	}
	for _, value := range subtitle {
		parts = append(parts, value)
	}
	for _, value := range description {
		parts = append(parts, value)
	}
	parts = append(parts, categoryCodes...)
	parts = append(parts,
		community.Slug,
		community.Topic,
		valueOrEmptyStringPtr(community.CityID),
		valueOrEmptyStringPtr(community.CountryCode),
	)
	return strings.Join(parts, " ")
}

func communitySearchVariants(community *model.Community, categoryCodes []string) []string {
	variants := make([]string, 0, len(community.TitleI18n)+len(categoryCodes)+2)
	for _, value := range community.TitleI18n {
		if normalized := normalizeCommunitySearchText(value); normalized != "" && !communitySearchContainsString(variants, normalized) {
			variants = append(variants, normalized)
		}
	}
	for _, value := range categoryCodes {
		if normalized := normalizeCommunitySearchText(value); normalized != "" && !communitySearchContainsString(variants, normalized) {
			variants = append(variants, normalized)
		}
	}
	if slug := normalizeCommunitySearchText(strings.ReplaceAll(community.Slug, "-", " ")); slug != "" && !communitySearchContainsString(variants, slug) {
		variants = append(variants, slug)
	}
	return variants
}

func communitySearchContainsString(values []string, candidate string) bool {
	for _, value := range values {
		if value == candidate {
			return true
		}
	}
	return false
}

func communitySearchPopularityScore(community *model.Community) float64 {
	if community == nil {
		return 0
	}
	return float64(community.FollowerCount)*0.7 + float64(community.PostCount)*0.3
}

func normalizeCommunitySearchLocale(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	for _, locale := range requiredCommunityLocales {
		if value == locale {
			return locale
		}
	}
	return fallbackCommunityLocale
}

func normalizeCommunitySearchText(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return ""
	}

	var builder strings.Builder
	builder.Grow(len(value))
	previousSpace := false
	for _, r := range value {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			builder.WriteRune(r)
			previousSpace = false
			continue
		}
		if !previousSpace {
			builder.WriteByte(' ')
			previousSpace = true
		}
	}
	return strings.TrimSpace(builder.String())
}

func valueOrEmptyStringPtr(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
