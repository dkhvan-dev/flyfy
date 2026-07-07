package app

import (
	"context"
	"strings"
	"unicode"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

const fallbackGuideLocale = "en"

type GuideSearchIndexer interface {
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

func (u *GuideUseCase) SetSearchIndexer(indexer GuideSearchIndexer) {
	u.searchIndexer = indexer
}

func (u *GuideUseCase) syncGuideSearchDocument(ctx context.Context, aggregate *GuideAggregate) {
	if u.searchIndexer == nil || aggregate == nil || aggregate.Profile == nil || aggregate.Profile.ID == uuid.Nil {
		return
	}
	if !isGuideSearchIndexable(aggregate.Profile) {
		u.deleteGuideSearchDocument(ctx, aggregate.Profile.ID)
		return
	}

	document := guideSearchDocument(aggregate)
	if err := u.searchIndexer.UpsertSearchDocument(ctx, document); err != nil {
		log.Warn().
			Err(err).
			Str("guide_profile_id", aggregate.Profile.ID.String()).
			Msg("failed to upsert guide search document")
	}
}

func (u *GuideUseCase) deleteGuideSearchDocument(ctx context.Context, profileID uuid.UUID) {
	if u.searchIndexer == nil || profileID == uuid.Nil {
		return
	}
	if err := u.searchIndexer.DeleteSearchDocument(ctx, SearchIndexDelete{
		Domain:   "guide",
		EntityID: profileID.String(),
		Locale:   fallbackGuideLocale,
	}); err != nil {
		log.Warn().
			Err(err).
			Str("guide_profile_id", profileID.String()).
			Msg("failed to delete guide search document")
	}
}

func isGuideSearchIndexable(profile *model.GuideProfile) bool {
	return profile != nil && profile.Status == enum.GuideStatusActive
}

func guideSearchDocument(aggregate *GuideAggregate) SearchIndexDocument {
	profile := aggregate.Profile
	locale := guideSearchLocale(aggregate.UserProfile)
	title := guideSearchTitle(aggregate, locale)
	subtitle := guideSearchSubtitle(aggregate, locale)
	description := guideSearchDescription(profile, locale)
	tags := guideSearchTags(aggregate)
	categoryCodes := guideSearchCategoryCodes(aggregate)
	searchText := buildGuideSearchText(aggregate, title, subtitle, description, tags, categoryCodes)
	rating := profile.RatingAvg

	return SearchIndexDocument{
		Domain:               "guide",
		EntityID:             profile.ID.String(),
		EntityVersion:        profile.UpdatedAt.Unix(),
		Locale:               locale,
		Title:                title,
		Subtitle:             subtitle,
		Description:          description,
		Tags:                 tags,
		CategoryCodes:        categoryCodes,
		CountryCode:          strings.ToUpper(guideUserCountryCode(aggregate.UserProfile)),
		Rating:               &rating,
		ReviewCount:          profile.ReviewsCount,
		PopularityScore:      guidePopularityScore(profile),
		FreshnessScore:       1,
		TrustScore:           guideTrustScore(profile),
		AvailabilityStatus:   strings.ToLower(string(profile.Status)),
		Visibility:           "public",
		ModerationStatus:     "approved",
		DeepLink:             "/guides/" + profile.UserID.String(),
		SearchText:           searchText,
		SearchTextNormalized: normalizeGuideSearchText(searchText),
		SearchVariants:       guideSearchVariants(aggregate, tags, categoryCodes),
	}
}

func guideSearchTitle(aggregate *GuideAggregate, locale string) map[string]string {
	if aggregate.UserProfile != nil {
		name := strings.TrimSpace(strings.Join([]string{
			guideOptionalString(aggregate.UserProfile.FirstName),
			guideOptionalString(aggregate.UserProfile.LastName),
		}, " "))
		if name != "" {
			return map[string]string{locale: name}
		}
		if nickname := guideOptionalString(aggregate.UserProfile.Nickname); nickname != "" {
			return map[string]string{locale: nickname}
		}
	}
	return map[string]string{locale: "Guide"}
}

func guideSearchSubtitle(aggregate *GuideAggregate, locale string) map[string]string {
	if aggregate.Profile == nil {
		return nil
	}
	values := make([]string, 0, 3)
	if headline := guideOptionalString(aggregate.Profile.Headline); headline != "" {
		values = append(values, headline)
	}
	if aggregate.Profile.IsExcursionGuideAvailable {
		values = append(values, "excursions")
	}
	if aggregate.Profile.IsActivityHostAvailable {
		values = append(values, "activities")
	}
	if len(values) == 0 {
		return nil
	}
	return map[string]string{locale: strings.Join(values, " - ")}
}

func guideSearchDescription(profile *model.GuideProfile, locale string) map[string]string {
	if profile == nil {
		return nil
	}
	about := guideOptionalString(profile.About)
	if about == "" {
		return nil
	}
	return map[string]string{locale: about}
}

func guideSearchTags(aggregate *GuideAggregate) []string {
	values := make([]string, 0, len(aggregate.Languages)+3)
	for _, item := range aggregate.Languages {
		if item == nil {
			continue
		}
		values = append(values, item.LanguageCode)
	}
	if aggregate.Profile != nil {
		values = append(values, strings.ToLower(string(aggregate.Profile.Type)))
		if aggregate.Profile.IsPrivateGuideAvailable {
			values = append(values, "private-guide")
		}
		if aggregate.Profile.IsExcursionGuideAvailable {
			values = append(values, "excursion-guide")
		}
		if aggregate.Profile.IsActivityHostAvailable {
			values = append(values, "activity-host")
		}
	}
	return normalizeGuideSearchList(values)
}

func guideSearchCategoryCodes(aggregate *GuideAggregate) []string {
	values := make([]string, 0, len(aggregate.Specializations))
	for _, item := range aggregate.Specializations {
		if item == nil {
			continue
		}
		values = append(values, item.SpecializationCode)
	}
	return normalizeGuideSearchList(values)
}

func buildGuideSearchText(
	aggregate *GuideAggregate,
	title map[string]string,
	subtitle map[string]string,
	description map[string]string,
	tags []string,
	categoryCodes []string,
) string {
	parts := make([]string, 0, len(title)+len(subtitle)+len(description)+len(tags)+len(categoryCodes)+4)
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
	if aggregate.UserProfile != nil {
		parts = append(parts,
			guideOptionalString(aggregate.UserProfile.Nickname),
			guideUserCountryCode(aggregate.UserProfile),
		)
	}
	return strings.Join(parts, " ")
}

func guideSearchVariants(aggregate *GuideAggregate, tags []string, categoryCodes []string) []string {
	values := append([]string{}, tags...)
	values = append(values, categoryCodes...)
	if aggregate.UserProfile != nil {
		values = append(values,
			guideOptionalString(aggregate.UserProfile.FirstName),
			guideOptionalString(aggregate.UserProfile.LastName),
			guideOptionalString(aggregate.UserProfile.Nickname),
			guideUserCountryCode(aggregate.UserProfile),
		)
	}
	return normalizeGuideSearchList(values)
}

func normalizeGuideSearchText(value string) string {
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

func normalizeGuideSearchList(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		value = normalizeGuideSearchText(value)
		value = strings.ReplaceAll(value, " ", "-")
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

func guidePopularityScore(profile *model.GuideProfile) float64 {
	if profile == nil {
		return 0
	}
	ratingScore := profile.RatingAvg / 5
	if ratingScore < 0 {
		ratingScore = 0
	}
	if ratingScore > 1 {
		ratingScore = 1
	}
	reviewScore := float64(profile.ReviewsCount) / 100
	if reviewScore > 1 {
		reviewScore = 1
	}
	return ratingScore*0.7 + reviewScore*0.3
}

func guideTrustScore(profile *model.GuideProfile) float64 {
	if profile == nil || profile.Status != enum.GuideStatusActive {
		return 0
	}
	score := 0.7
	if profile.ReviewsCount >= 10 && profile.RatingAvg >= 4.5 {
		score = 0.9
	}
	return score
}

func guideSearchLocale(profile *PublicUserProfile) string {
	if profile == nil {
		return fallbackGuideLocale
	}
	locale := strings.ToLower(strings.TrimSpace(profile.Locale))
	if locale == "" {
		return fallbackGuideLocale
	}
	return locale
}

func guideUserCountryCode(profile *PublicUserProfile) string {
	if profile == nil {
		return ""
	}
	return guideOptionalString(profile.CountryCode)
}

func guideOptionalString(value *string) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(*value)
}
