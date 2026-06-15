package dto

import "encoding/json"

type CommunityResponse struct {
	ID                     string              `json:"id"`
	Slug                   string              `json:"slug"`
	Title                  string              `json:"title"`
	TitleI18n              map[string]string   `json:"titleI18n,omitempty"`
	Description            string              `json:"description"`
	DescriptionI18n        map[string]string   `json:"descriptionI18n,omitempty"`
	Topic                  string              `json:"topic"`
	Rules                  []string            `json:"rules,omitempty"`
	RulesI18n              map[string][]string `json:"rulesI18n,omitempty"`
	CityID                 *string             `json:"cityId,omitempty"`
	CountryCode            *string             `json:"countryCode,omitempty"`
	LanguageCode           string              `json:"languageCode"`
	AvatarFileID           *string             `json:"avatarFileId,omitempty"`
	CoverFileID            *string             `json:"coverFileId,omitempty"`
	Visibility             string              `json:"visibility"`
	PostingPolicy          string              `json:"postingPolicy"`
	Status                 string              `json:"status"`
	DefaultPostProfileKey  string              `json:"defaultPostProfileKey"`
	AllowedPostProfileKeys []string            `json:"allowedPostProfileKeys"`
	EnabledTabs            []string            `json:"enabledTabs"`
	FollowerCount          int                 `json:"followerCount"`
	MembersCount           int                 `json:"membersCount"`
	PostCount              int                 `json:"postCount"`
	FollowedByViewer       bool                `json:"followedByViewer"`
	ViewerRole             string              `json:"viewerRole,omitempty"`
	ViewerCanModerate      bool                `json:"viewerCanModerate"`
	MutedByViewer          bool                `json:"mutedByViewer"`
	ViewerTrustStatus      string              `json:"viewerTrustStatus"`
	CreatedAt              string              `json:"createdAt"`
	UpdatedAt              string              `json:"updatedAt"`
}

type CommunityListResponse struct {
	Items  []*CommunityResponse `json:"items"`
	Limit  int                  `json:"limit"`
	Offset int                  `json:"offset"`
}

type CreateCommunityRequest struct {
	Slug            string              `json:"slug"`
	TitleI18n       map[string]string   `json:"titleI18n"`
	DescriptionI18n map[string]string   `json:"descriptionI18n"`
	RulesI18n       map[string][]string `json:"rulesI18n,omitempty"`
	Topic           string              `json:"topic"`
	CityID          *string             `json:"cityId,omitempty"`
	CountryCode     *string             `json:"countryCode,omitempty"`
	AvatarFileID    *string             `json:"avatarFileId,omitempty"`
	CoverFileID     *string             `json:"coverFileId,omitempty"`
	Visibility      string              `json:"visibility"`
	PostingPolicy   string              `json:"postingPolicy"`
	Status          string              `json:"status"`
}

type ReportCommunityRequest struct {
	Reason  string `json:"reason"`
	Details string `json:"details"`
}

type CommunityReportResponse struct {
	ID             string `json:"id"`
	CommunityID    string `json:"communityId"`
	ReporterUserID string `json:"reporterUserId"`
	Reason         string `json:"reason"`
	Details        string `json:"details"`
	Status         string `json:"status"`
	CreatedAt      string `json:"createdAt"`
	UpdatedAt      string `json:"updatedAt"`
}

type CommunityReportSubmissionResponse struct {
	Report           *CommunityReportResponse `json:"report"`
	OpenReportsCount int                      `json:"openReportsCount"`
}

type UpdateCommunityMemberRoleRequest struct {
	Role string `json:"role"`
}

type UpdateCommunityMemberStatusRequest struct {
	Status string `json:"status"`
}

type CommunityMembershipResponse struct {
	CommunityID string `json:"communityId"`
	UserID      string `json:"userId"`
	Role        string `json:"role"`
	Status      string `json:"status"`
	CreatedAt   string `json:"createdAt"`
	UpdatedAt   string `json:"updatedAt"`
}

type CommunityMemberResponse struct {
	CommunityID string         `json:"communityId"`
	UserID      string         `json:"userId"`
	Role        string         `json:"role"`
	Status      string         `json:"status"`
	User        AuthorResponse `json:"user"`
	CreatedAt   string         `json:"createdAt"`
	UpdatedAt   string         `json:"updatedAt"`
}

type CommunityMemberListResponse struct {
	Items   []*CommunityMemberResponse `json:"items"`
	Limit   int                        `json:"limit"`
	Offset  int                        `json:"offset"`
	HasMore bool                       `json:"hasMore"`
}

type CommunityMemberRoleChangeResponse struct {
	ID           string         `json:"id"`
	CommunityID  string         `json:"communityId"`
	TargetUserID string         `json:"targetUserId"`
	ActorUserID  string         `json:"actorUserId"`
	Actor        AuthorResponse `json:"actor"`
	PreviousRole string         `json:"previousRole"`
	NextRole     string         `json:"nextRole"`
	CreatedAt    string         `json:"createdAt"`
}

type CommunityMemberRoleChangeListResponse struct {
	Items   []*CommunityMemberRoleChangeResponse `json:"items"`
	Limit   int                                  `json:"limit"`
	Offset  int                                  `json:"offset"`
	HasMore bool                                 `json:"hasMore"`
}

type CommunityPostProfileResponse struct {
	Key                  string          `json:"key"`
	Version              int             `json:"version"`
	PostKind             string          `json:"postKind"`
	ComposerPreset       string          `json:"composerPreset"`
	RenderPreset         string          `json:"renderPreset"`
	Schema               json.RawMessage `json:"schema"`
	Validation           json.RawMessage `json:"validation"`
	ModerationMode       string          `json:"moderationMode"`
	ActivityCreationMode string          `json:"activityCreationMode"`
	CreatedAt            string          `json:"createdAt"`
	UpdatedAt            string          `json:"updatedAt"`
}

type CommunityPostProfileListResponse struct {
	Items  []*CommunityPostProfileResponse `json:"items"`
	Limit  int                             `json:"limit"`
	Offset int                             `json:"offset"`
}

type CommunityBlueprintResponse struct {
	ID                     string              `json:"id"`
	Key                    string              `json:"key"`
	Category               string              `json:"category"`
	DefaultPostProfileKey  string              `json:"defaultPostProfileKey"`
	AllowedPostProfileKeys []string            `json:"allowedPostProfileKeys"`
	EnabledTabs            []string            `json:"enabledTabs"`
	SubcategoryKeys        []string            `json:"subcategoryKeys"`
	PromotionSegmentKeys   []string            `json:"promotionSegmentKeys"`
	TitleI18n              map[string]string   `json:"titleI18n"`
	DescriptionI18n        map[string]string   `json:"descriptionI18n"`
	RulesI18n              map[string][]string `json:"rulesI18n,omitempty"`
	IconKey                string              `json:"iconKey"`
	RolloutPolicy          string              `json:"rolloutPolicy"`
	AllowedScopeTypes      []string            `json:"allowedScopeTypes"`
	DefaultModerationMode  string              `json:"defaultModerationMode"`
	Status                 string              `json:"status"`
	CreatedAt              string              `json:"createdAt"`
	UpdatedAt              string              `json:"updatedAt"`
}

type CommunityBlueprintListResponse struct {
	Items  []*CommunityBlueprintResponse `json:"items"`
	Limit  int                           `json:"limit"`
	Offset int                           `json:"offset"`
}

type CommunityGeoHubResponse struct {
	CountryCode       string  `json:"countryCode"`
	CityID            string  `json:"cityId"`
	HubTier           string  `json:"hubTier"`
	CommunityEnabled  bool    `json:"communityEnabled"`
	ParentCountryCode *string `json:"parentCountryCode,omitempty"`
	ParentCityID      *string `json:"parentCityId,omitempty"`
	Reason            string  `json:"reason"`
	Priority          int     `json:"priority"`
	CanMaterialize    bool    `json:"canMaterialize"`
	EffectiveCountry  string  `json:"effectiveCountryCode"`
	EffectiveCityID   string  `json:"effectiveCityId"`
	CreatedBy         string  `json:"createdBy"`
	UpdatedAt         string  `json:"updatedAt"`
}

type CommunityGeoHubListResponse struct {
	Items  []*CommunityGeoHubResponse `json:"items"`
	Limit  int                        `json:"limit"`
	Offset int                        `json:"offset"`
}

type CommunityInstanceResponse struct {
	ID              string              `json:"id"`
	CommunityID     *string             `json:"communityId,omitempty"`
	BlueprintID     string              `json:"blueprintId"`
	Slug            string              `json:"slug"`
	CountryCode     string              `json:"countryCode"`
	CityID          *string             `json:"cityId,omitempty"`
	ScopeType       string              `json:"scopeType"`
	TitleI18n       map[string]string   `json:"titleI18n"`
	DescriptionI18n map[string]string   `json:"descriptionI18n"`
	RulesI18n       map[string][]string `json:"rulesI18n,omitempty"`
	Status          string              `json:"status"`
	MemberCount     int                 `json:"memberCount"`
	PostCount       int                 `json:"postCount"`
	CreatedAt       string              `json:"createdAt"`
	UpdatedAt       string              `json:"updatedAt"`
}

type CommunityInstanceListResponse struct {
	Items  []*CommunityInstanceResponse `json:"items"`
	Limit  int                          `json:"limit"`
	Offset int                          `json:"offset"`
}

type MaterializeCommunityInstancesRequest struct {
	BlueprintID string `json:"blueprintId,omitempty"`
	CountryCode string `json:"countryCode,omitempty"`
	CityID      string `json:"cityId,omitempty"`
	ScopeType   string `json:"scopeType,omitempty"`
	Limit       int    `json:"limit,omitempty"`
}

type MaterializeCommunityInstancesResponse struct {
	MaterializedCount int `json:"materializedCount"`
}
