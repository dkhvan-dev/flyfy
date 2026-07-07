package app

import (
	"context"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

var requiredCommunityLocales = []string{"ru", "en", "kk"}

const maxCommunityPlatformListLimit = 500

type CreateCommunityInput struct {
	Slug             string
	TitleI18n        map[string]string
	DescriptionI18n  map[string]string
	RulesI18n        map[string][]string
	Topic            string
	CityID           *string
	CountryCode      *string
	AvatarFileID     *uuid.UUID
	CoverFileID      *uuid.UUID
	Visibility       string
	PostingPolicy    string
	Status           string
	CreatedByAdminID uuid.UUID
}

type UpdateCommunityInput struct {
	CommunityID      uuid.UUID
	Slug             string
	TitleI18n        map[string]string
	DescriptionI18n  map[string]string
	RulesI18n        map[string][]string
	Topic            string
	CityID           *string
	CountryCode      *string
	AvatarFileID     *uuid.UUID
	CoverFileID      *uuid.UUID
	Visibility       string
	PostingPolicy    string
	Status           string
	UpdatedByAdminID uuid.UUID
}

type ListCommunityPostProfilesInput struct {
	PostKind string
	Limit    int
	Offset   int
}

type ListCommunityBlueprintsInput struct {
	Category      string
	Search        string
	PostProfile   string
	RolloutPolicy string
	Status        string
	Limit         int
	Offset        int
}

type ListCommunityGeoHubsInput struct {
	CountryCode      string
	CityID           string
	HubTier          string
	CommunityEnabled *bool
	IncludeAliasOnly bool
	Limit            int
	Offset           int
}

type ListCommunityInstancesInput struct {
	BlueprintID uuid.UUID
	CountryCode string
	CityID      string
	ScopeType   string
	Status      string
	Search      string
	Limit       int
	Offset      int
}

type MaterializeCommunityInstancesInput struct {
	BlueprintID uuid.UUID
	CountryCode string
	CityID      string
	ScopeType   string
	Limit       int
}

func (u *PostUseCase) CreateCommunity(ctx context.Context, input CreateCommunityInput) (*CommunityView, error) {
	if input.CreatedByAdminID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	community, err := communityFromCreateInput(input)
	if err != nil {
		return nil, err
	}
	if err = u.repo.CreateCommunity(ctx, community); err != nil {
		return nil, err
	}
	u.syncCommunitySearchDocument(ctx, community)

	return &CommunityView{
		Community:         community,
		FollowedByViewer:  false,
		ViewerCanModerate: false,
		ViewerTrustStatus: "ACTIVE",
	}, nil
}

func (u *PostUseCase) GetAdminCommunity(ctx context.Context, communityID uuid.UUID) (*CommunityView, error) {
	if communityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	community, err := u.repo.GetCommunityByID(ctx, communityID)
	if err != nil {
		return nil, err
	}
	if community == nil || community.DeletedAt != nil {
		return nil, ErrCommunityNotFound
	}
	return &CommunityView{
		Community:         community,
		FollowedByViewer:  false,
		ViewerCanModerate: true,
		ViewerTrustStatus: "ACTIVE",
	}, nil
}

func (u *PostUseCase) UpdateCommunity(ctx context.Context, input UpdateCommunityInput) (*CommunityView, error) {
	if input.UpdatedByAdminID == uuid.Nil {
		return nil, ErrInvalidUserID
	}
	if input.CommunityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	existing, err := u.repo.GetCommunityByID(ctx, input.CommunityID)
	if err != nil {
		return nil, err
	}
	if existing == nil || existing.DeletedAt != nil {
		return nil, ErrCommunityNotFound
	}
	community, err := communityFromUpdateInput(existing, input)
	if err != nil {
		return nil, err
	}
	if err = u.repo.UpdateCommunity(ctx, community); err != nil {
		return nil, err
	}
	u.syncCommunitySearchDocument(ctx, community)
	return &CommunityView{
		Community:         community,
		FollowedByViewer:  false,
		ViewerCanModerate: true,
		ViewerTrustStatus: "ACTIVE",
	}, nil
}

func (u *PostUseCase) ListCommunityPostProfiles(ctx context.Context, input ListCommunityPostProfilesInput) ([]*model.CommunityPostProfile, error) {
	limit, offset := normalizeCommunityPlatformListPagination(input.Limit, input.Offset)
	return u.repo.ListCommunityPostProfiles(ctx, model.CommunityPostProfileListFilter{
		PostKind: strings.ToUpper(strings.TrimSpace(input.PostKind)),
		Limit:    limit,
		Offset:   offset,
	})
}

func (u *PostUseCase) ListCommunityBlueprints(ctx context.Context, input ListCommunityBlueprintsInput) ([]*model.CommunityBlueprint, error) {
	limit, offset := normalizeCommunityPlatformListPagination(input.Limit, input.Offset)
	var status *enum.CommunityStatus
	if rawStatus := strings.TrimSpace(input.Status); rawStatus != "" {
		normalized := enum.NormalizeCommunityStatus(enum.CommunityStatus(rawStatus))
		if !normalized.IsValid() {
			return nil, ErrPostValidationFailed
		}
		status = &normalized
	}
	return u.repo.ListCommunityBlueprints(ctx, model.CommunityBlueprintListFilter{
		Category:      strings.TrimSpace(input.Category),
		Search:        strings.TrimSpace(input.Search),
		PostProfile:   strings.TrimSpace(input.PostProfile),
		RolloutPolicy: strings.ToUpper(strings.TrimSpace(input.RolloutPolicy)),
		Status:        status,
		Limit:         limit,
		Offset:        offset,
	})
}

func (u *PostUseCase) ListCommunityGeoHubs(ctx context.Context, input ListCommunityGeoHubsInput) ([]*model.CommunityGeoHub, error) {
	limit, offset := normalizeCommunityPlatformListPagination(input.Limit, input.Offset)
	return u.repo.ListCommunityGeoHubs(ctx, model.CommunityGeoHubListFilter{
		CountryCode:      normalizeCountryCode(input.CountryCode),
		CityID:           strings.TrimSpace(input.CityID),
		HubTier:          strings.ToUpper(strings.TrimSpace(input.HubTier)),
		CommunityEnabled: input.CommunityEnabled,
		IncludeAliasOnly: input.IncludeAliasOnly,
		Limit:            limit,
		Offset:           offset,
	})
}

func (u *PostUseCase) ListCommunityInstances(ctx context.Context, input ListCommunityInstancesInput) ([]*model.CommunityInstance, error) {
	limit, offset := normalizeCommunityPlatformListPagination(input.Limit, input.Offset)
	var status *enum.CommunityStatus
	if rawStatus := strings.TrimSpace(input.Status); rawStatus != "" {
		normalized := enum.NormalizeCommunityStatus(enum.CommunityStatus(rawStatus))
		if !normalized.IsValid() {
			return nil, ErrPostValidationFailed
		}
		status = &normalized
	}
	return u.repo.ListCommunityInstances(ctx, model.CommunityInstanceListFilter{
		BlueprintID: input.BlueprintID,
		CountryCode: normalizeCountryCode(input.CountryCode),
		CityID:      strings.TrimSpace(input.CityID),
		ScopeType:   strings.ToUpper(strings.TrimSpace(input.ScopeType)),
		Status:      status,
		Search:      strings.TrimSpace(input.Search),
		Limit:       limit,
		Offset:      offset,
	})
}

func (u *PostUseCase) MaterializeCommunityInstances(ctx context.Context, input MaterializeCommunityInstancesInput) (*model.CommunityInstanceMaterializationResult, error) {
	return u.repo.MaterializeCommunityInstances(ctx, model.CommunityInstanceMaterializationFilter{
		BlueprintID: input.BlueprintID,
		CountryCode: normalizeCountryCode(input.CountryCode),
		CityID:      strings.TrimSpace(input.CityID),
		ScopeType:   strings.ToUpper(strings.TrimSpace(input.ScopeType)),
		Limit:       input.Limit,
	})
}

func communityFromCreateInput(input CreateCommunityInput) (*model.Community, error) {
	slug := normalizeCommunitySlug(input.Slug)
	fields := map[string]string{}
	if slug == "" {
		fields["slug"] = "invalid"
	}

	titleI18n := normalizeCommunityTextMap(input.TitleI18n)
	descriptionI18n := normalizeCommunityTextMap(input.DescriptionI18n)
	rulesI18n := normalizeCommunityRulesMap(input.RulesI18n)
	for _, locale := range requiredCommunityLocales {
		if titleI18n[locale] == "" {
			fields["title_"+locale] = "required"
		}
		if descriptionI18n[locale] == "" {
			fields["description_"+locale] = "required"
		}
	}

	visibility := enum.NormalizeCommunityVisibility(enum.CommunityVisibility(input.Visibility))
	if !visibility.IsValid() {
		fields["visibility"] = "invalid"
	}
	postingPolicy := enum.NormalizeCommunityPostingPolicy(enum.CommunityPostingPolicy(input.PostingPolicy))
	if !postingPolicy.IsValid() {
		fields["postingPolicy"] = "invalid"
	}
	status := enum.NormalizeCommunityStatus(enum.CommunityStatus(input.Status))
	if !status.IsValid() {
		fields["status"] = "invalid"
	}
	if len(fields) > 0 {
		return nil, NewPostValidationError(fields, ErrPostValidationFailed)
	}

	topic := strings.ToUpper(strings.TrimSpace(input.Topic))
	if topic == "" {
		topic = "GENERAL"
	}
	now := time.Now().UTC()
	createdBy := input.CreatedByAdminID
	return &model.Community{
		ID:               uuid.New(),
		Slug:             slug,
		Title:            preferredCommunityText(titleI18n),
		TitleI18n:        titleI18n,
		Description:      preferredCommunityText(descriptionI18n),
		DescriptionI18n:  descriptionI18n,
		Topic:            topic,
		Rules:            preferredCommunityRules(rulesI18n),
		RulesI18n:        rulesI18n,
		CityID:           normalizedStringPtr(input.CityID),
		CountryCode:      normalizedUpperStringPtr(input.CountryCode),
		LanguageCode:     "ru",
		AvatarFileID:     cloneUUIDPtr(input.AvatarFileID),
		CoverFileID:      cloneUUIDPtr(input.CoverFileID),
		Visibility:       visibility,
		PostingPolicy:    postingPolicy,
		Status:           status,
		CreatedByAdminID: &createdBy,
		CreatedAt:        now,
		UpdatedAt:        now,
	}, nil
}

func communityFromUpdateInput(existing *model.Community, input UpdateCommunityInput) (*model.Community, error) {
	if existing == nil {
		return nil, ErrCommunityNotFound
	}
	createdBy := uuid.Nil
	if existing.CreatedByAdminID != nil {
		createdBy = *existing.CreatedByAdminID
	}
	createInput := CreateCommunityInput{
		Slug:             input.Slug,
		TitleI18n:        input.TitleI18n,
		DescriptionI18n:  input.DescriptionI18n,
		RulesI18n:        input.RulesI18n,
		Topic:            input.Topic,
		CityID:           input.CityID,
		CountryCode:      input.CountryCode,
		AvatarFileID:     input.AvatarFileID,
		CoverFileID:      input.CoverFileID,
		Visibility:       input.Visibility,
		PostingPolicy:    input.PostingPolicy,
		Status:           input.Status,
		CreatedByAdminID: createdBy,
	}
	if createInput.CreatedByAdminID == uuid.Nil {
		createInput.CreatedByAdminID = input.UpdatedByAdminID
	}
	community, err := communityFromCreateInput(createInput)
	if err != nil {
		return nil, err
	}
	community.ID = existing.ID
	community.FollowerCount = existing.FollowerCount
	community.PostCount = existing.PostCount
	community.CreatedByAdminID = existing.CreatedByAdminID
	community.CreatedAt = existing.CreatedAt
	community.DeletedAt = existing.DeletedAt
	community.UpdatedAt = time.Now().UTC()
	return community, nil
}

func normalizeCommunityPlatformListPagination(limit int, offset int) (int, int) {
	if limit <= 0 {
		limit = defaultListLimit
	}
	if limit > maxCommunityPlatformListLimit {
		limit = maxCommunityPlatformListLimit
	}
	if offset < 0 {
		offset = 0
	}
	return limit, offset
}

func normalizeCommunitySlug(value string) string {
	slug := strings.ToLower(strings.TrimSpace(value))
	if slug == "" || strings.HasPrefix(slug, "-") || strings.HasSuffix(slug, "-") {
		return ""
	}
	previousDash := false
	for _, r := range slug {
		valid := unicode.IsDigit(r) || (r >= 'a' && r <= 'z') || r == '-'
		if !valid || (r == '-' && previousDash) {
			return ""
		}
		previousDash = r == '-'
	}
	return slug
}

func normalizeCommunityTextMap(input map[string]string) map[string]string {
	out := make(map[string]string, len(requiredCommunityLocales))
	for _, locale := range requiredCommunityLocales {
		out[locale] = strings.TrimSpace(input[locale])
	}
	return out
}

func normalizeCommunityRulesMap(input map[string][]string) map[string][]string {
	out := make(map[string][]string, len(requiredCommunityLocales))
	for _, locale := range requiredCommunityLocales {
		rules := make([]string, 0, len(input[locale]))
		for _, rule := range input[locale] {
			if trimmed := strings.TrimSpace(rule); trimmed != "" {
				rules = append(rules, trimmed)
			}
		}
		out[locale] = rules
	}
	return out
}

func preferredCommunityText(values map[string]string) string {
	for _, locale := range requiredCommunityLocales {
		if value := strings.TrimSpace(values[locale]); value != "" {
			return value
		}
	}
	return ""
}

func preferredCommunityRules(values map[string][]string) []string {
	for _, locale := range requiredCommunityLocales {
		if len(values[locale]) > 0 {
			return append([]string(nil), values[locale]...)
		}
	}
	return nil
}

func normalizedStringPtr(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func normalizedUpperStringPtr(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.ToUpper(strings.TrimSpace(*value))
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func cloneUUIDPtr(value *uuid.UUID) *uuid.UUID {
	if value == nil || *value == uuid.Nil {
		return nil
	}
	cloned := *value
	return &cloned
}
