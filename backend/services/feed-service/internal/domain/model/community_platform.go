package model

import (
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

type CommunityPostProfile struct {
	Key                  enum.PostProfileKey
	Version              int
	PostKind             enum.PostKind
	ComposerPreset       string
	RenderPreset         string
	SchemaJSON           json.RawMessage
	ValidationJSON       json.RawMessage
	ModerationMode       enum.ModerationMode
	ActivityCreationMode enum.ActivityCreationMode
	CreatedAt            time.Time
	UpdatedAt            time.Time
}

type CommunityPostProfileListFilter struct {
	PostKind string
	Limit    int
	Offset   int
}

func (p CommunityPostProfile) RequiresActivityIntent() bool {
	return p.ActivityCreationMode == enum.ActivityCreationModeRequired ||
		(p.ActivityCreationMode == enum.ActivityCreationModeOptional &&
			(p.PostKind == enum.PostKindEventAnnouncement || p.PostKind == enum.PostKindTripPlan))
}

type CommunityBlueprint struct {
	ID                     uuid.UUID
	Key                    string
	Category               string
	DefaultPostProfileKey  enum.PostProfileKey
	AllowedPostProfileKeys []string
	EnabledTabs            []string
	SubcategoryKeys        []string
	PromotionSegmentKeys   []string
	TitleI18n              map[string]string
	DescriptionI18n        map[string]string
	RulesI18n              map[string][]string
	IconKey                string
	RolloutPolicy          enum.CommunityRolloutPolicy
	AllowedScopeTypes      []enum.CommunityScopeType
	DefaultModerationMode  enum.ModerationMode
	Status                 enum.CommunityStatus
	CreatedAt              time.Time
	UpdatedAt              time.Time
}

type CommunityBlueprintListFilter struct {
	Category      string
	Search        string
	PostProfile   string
	RolloutPolicy string
	Status        *enum.CommunityStatus
	Limit         int
	Offset        int
}

type CommunityGeoHub struct {
	CountryCode       string
	CityID            string
	HubTier           enum.CommunityGeoHubTier
	CommunityEnabled  bool
	ParentCountryCode *string
	ParentCityID      *string
	Reason            string
	Priority          int
	CreatedBy         string
	UpdatedAt         time.Time
}

type CommunityGeoHubListFilter struct {
	CountryCode      string
	CityID           string
	HubTier          string
	CommunityEnabled *bool
	IncludeAliasOnly bool
	Limit            int
	Offset           int
}

func (h CommunityGeoHub) CanMaterializeCommunity() bool {
	return h.CommunityEnabled && h.HubTier != enum.CommunityGeoHubTierAliasOnly
}

func (h CommunityGeoHub) EffectiveCountryCode() string {
	if h.ParentCountryCode != nil && strings.TrimSpace(*h.ParentCountryCode) != "" {
		return strings.ToUpper(strings.TrimSpace(*h.ParentCountryCode))
	}
	return strings.ToUpper(strings.TrimSpace(h.CountryCode))
}

func (h CommunityGeoHub) EffectiveCityID() string {
	if h.ParentCityID != nil && strings.TrimSpace(*h.ParentCityID) != "" {
		return strings.TrimSpace(*h.ParentCityID)
	}
	return strings.TrimSpace(h.CityID)
}

type CommunityGeoAlias struct {
	CountryCode       string
	CityID            string
	ParentCountryCode string
	ParentCityID      string
	Reason            string
	CreatedBy         string
	UpdatedAt         time.Time
}

type CommunityBlueprintGeoCoverage struct {
	ID          uuid.UUID
	BlueprintID uuid.UUID
	CountryCode string
	CityID      *string
	ScopeType   enum.CommunityScopeType
	Status      enum.CommunityStatus
	Priority    int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type CommunityInstance struct {
	ID              uuid.UUID
	CommunityID     *uuid.UUID
	BlueprintID     uuid.UUID
	Slug            string
	CountryCode     string
	CityID          *string
	ScopeType       enum.CommunityScopeType
	TitleI18n       map[string]string
	DescriptionI18n map[string]string
	RulesI18n       map[string][]string
	Status          enum.CommunityStatus
	MemberCount     int
	PostCount       int
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type CommunityInstanceListFilter struct {
	BlueprintID uuid.UUID
	CountryCode string
	CityID      string
	ScopeType   string
	Status      *enum.CommunityStatus
	Search      string
	Limit       int
	Offset      int
}

type CommunityInstanceMaterializationFilter struct {
	BlueprintID uuid.UUID
	CountryCode string
	CityID      string
	ScopeType   string
	Limit       int
}

type CommunityInstanceMaterializationResult struct {
	MaterializedCount int
}
