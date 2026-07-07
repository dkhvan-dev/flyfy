package app

import (
	"context"
	"strings"
	"unicode"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
)

const fallbackUserSearchLocale = "ru"

type UserSearchIndexer interface {
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

func (u *UserUseCase) syncUserSearchDocument(ctx context.Context, aggregate *UserAggregate) {
	if u.searchIndexer == nil || aggregate == nil || aggregate.User == nil || aggregate.User.ID == uuid.Nil {
		return
	}
	if !isUserSearchIndexable(aggregate) {
		u.deleteUserSearchDocument(ctx, aggregate.User.ID)
		return
	}

	document := userSearchDocument(aggregate)
	if err := u.searchIndexer.UpsertSearchDocument(ctx, document); err != nil {
		log.Warn().
			Err(err).
			Str("user_id", aggregate.User.ID.String()).
			Msg("failed to upsert user search document")
	}
}

func (u *UserUseCase) deleteUserSearchDocument(ctx context.Context, userID uuid.UUID) {
	if u.searchIndexer == nil || userID == uuid.Nil {
		return
	}
	if err := u.searchIndexer.DeleteSearchDocument(ctx, SearchIndexDelete{
		Domain:   "user",
		EntityID: userID.String(),
		Locale:   fallbackUserSearchLocale,
	}); err != nil {
		log.Warn().
			Err(err).
			Str("user_id", userID.String()).
			Msg("failed to delete user search document")
	}
}

func isUserSearchIndexable(aggregate *UserAggregate) bool {
	if aggregate == nil || aggregate.User == nil || aggregate.Profile == nil {
		return false
	}
	if aggregate.User.IsDeleted || aggregate.User.Status != enum.UserStatusActive {
		return false
	}
	return userSearchDisplayName(aggregate.Profile) != ""
}

func userSearchDocument(aggregate *UserAggregate) SearchIndexDocument {
	profile := aggregate.Profile
	locale := normalizeUserSearchLocale(profile.Locale)
	displayName := userSearchDisplayName(profile)
	title := map[string]string{locale: displayName}
	subtitle := userSearchSubtitle(profile, locale)
	description := userSearchDescription(profile, locale)
	categoryCodes := userSearchCategoryCodes(profile)
	searchText := buildUserSearchText(profile, title, subtitle, description, categoryCodes)

	return SearchIndexDocument{
		Domain:               "user",
		EntityID:             aggregate.User.ID.String(),
		EntityVersion:        profile.UpdatedAt.UnixNano(),
		Locale:               locale,
		Title:                title,
		Subtitle:             subtitle,
		Description:          description,
		CategoryCodes:        categoryCodes,
		CityID:               userSearchCityID(profile),
		CountryCode:          strings.ToUpper(strings.TrimSpace(valueOrEmptyStringPtr(profile.CountryCode))),
		PopularityScore:      float64(aggregate.Followers.FollowersCount),
		FreshnessScore:       0.5,
		TrustScore:           userSearchTrustScore(aggregate.Reputation),
		AvailabilityStatus:   strings.ToLower(string(aggregate.User.Status)),
		Visibility:           "public",
		ModerationStatus:     "approved",
		DeepLink:             "/users/" + aggregate.User.ID.String(),
		SearchText:           searchText,
		SearchTextNormalized: normalizeUserSearchText(searchText),
		SearchVariants:       userSearchVariants(profile, displayName, categoryCodes),
	}
}

func userSearchDisplayName(profile *model.UserProfile) string {
	if profile == nil {
		return ""
	}
	parts := make([]string, 0, 2)
	if firstName := strings.TrimSpace(valueOrEmptyStringPtr(profile.FirstName)); firstName != "" {
		parts = append(parts, firstName)
	}
	if lastName := strings.TrimSpace(valueOrEmptyStringPtr(profile.LastName)); lastName != "" {
		parts = append(parts, lastName)
	}
	if len(parts) > 0 {
		return strings.Join(parts, " ")
	}
	return strings.TrimSpace(valueOrEmptyStringPtr(profile.Nickname))
}

func userSearchSubtitle(profile *model.UserProfile, locale string) map[string]string {
	parts := make([]string, 0, 2)
	if nickname := strings.TrimSpace(valueOrEmptyStringPtr(profile.Nickname)); nickname != "" {
		parts = append(parts, nickname)
	}
	if countryCode := strings.TrimSpace(valueOrEmptyStringPtr(profile.CountryCode)); countryCode != "" {
		parts = append(parts, strings.ToUpper(countryCode))
	}
	if len(parts) == 0 {
		return nil
	}
	return map[string]string{locale: strings.Join(parts, " - ")}
}

func userSearchDescription(profile *model.UserProfile, locale string) map[string]string {
	bio := strings.TrimSpace(valueOrEmptyStringPtr(profile.Bio))
	if bio == "" {
		return nil
	}
	return map[string]string{locale: bio}
}

func userSearchCategoryCodes(profile *model.UserProfile) []string {
	codes := []string{"user"}
	if countryCode := strings.ToLower(strings.TrimSpace(valueOrEmptyStringPtr(profile.CountryCode))); countryCode != "" {
		codes = append(codes, countryCode)
	}
	return codes
}

func buildUserSearchText(
	profile *model.UserProfile,
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
		valueOrEmptyStringPtr(profile.Nickname),
		valueOrEmptyStringPtr(profile.CountryCode),
		profile.Locale,
		profile.Timezone,
	)
	return strings.Join(parts, " ")
}

func userSearchVariants(profile *model.UserProfile, displayName string, categoryCodes []string) []string {
	variants := make([]string, 0, len(categoryCodes)+3)
	for _, value := range []string{
		displayName,
		valueOrEmptyStringPtr(profile.Nickname),
		strings.ReplaceAll(valueOrEmptyStringPtr(profile.Nickname), "@", ""),
	} {
		if normalized := normalizeUserSearchText(value); normalized != "" && !userSearchContainsString(variants, normalized) {
			variants = append(variants, normalized)
		}
	}
	for _, value := range categoryCodes {
		if normalized := normalizeUserSearchText(value); normalized != "" && !userSearchContainsString(variants, normalized) {
			variants = append(variants, normalized)
		}
	}
	return variants
}

func userSearchCityID(profile *model.UserProfile) string {
	if profile == nil || profile.CityID == nil || *profile.CityID == uuid.Nil {
		return ""
	}
	return profile.CityID.String()
}

func userSearchTrustScore(reputation *model.UserReputation) float64 {
	if reputation == nil || reputation.TrustScore <= 0 {
		return 0
	}
	if reputation.TrustScore >= 100 {
		return 1
	}
	return float64(reputation.TrustScore) / 100
}

func normalizeUserSearchLocale(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	switch value {
	case "ru", "en", "kk", "kz":
		return value
	default:
		return fallbackUserSearchLocale
	}
}

func normalizeUserSearchText(value string) string {
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

func userSearchContainsString(values []string, candidate string) bool {
	for _, value := range values {
		if value == candidate {
			return true
		}
	}
	return false
}

func valueOrEmptyStringPtr(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
