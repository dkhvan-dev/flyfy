package model

import (
	"time"

	"github.com/google/uuid"
)

type AdminCommunity struct {
	ID              uuid.UUID
	Slug            string
	Title           string
	TitleI18n       map[string]string
	Description     string
	DescriptionI18n map[string]string
	Rules           []string
	RulesI18n       map[string][]string
	Topic           string
	CityID          *string
	CountryCode     *string
	AvatarFileID    *uuid.UUID
	CoverFileID     *uuid.UUID
	Visibility      string
	PostingPolicy   string
	Status          string
	MembersCount    int
	PostCount       int
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type CommunityPostProfile struct {
	Key                  string
	Version              int
	PostKind             string
	ComposerPreset       string
	RenderPreset         string
	ModerationMode       string
	ActivityCreationMode string
	CreatedAt            time.Time
	UpdatedAt            time.Time
}

type CommunityBlueprint struct {
	ID                     uuid.UUID
	Key                    string
	Category               string
	DefaultPostProfileKey  string
	AllowedPostProfileKeys []string
	EnabledTabs            []string
	SubcategoryKeys        []string
	PromotionSegmentKeys   []string
	TitleI18n              map[string]string
	DescriptionI18n        map[string]string
	RulesI18n              map[string][]string
	IconKey                string
	RolloutPolicy          string
	AllowedScopeTypes      []string
	DefaultModerationMode  string
	Status                 string
	CreatedAt              time.Time
	UpdatedAt              time.Time
}

type CommunityGeoHub struct {
	CountryCode       string
	CityID            string
	HubTier           string
	CommunityEnabled  bool
	ParentCountryCode *string
	ParentCityID      *string
	Reason            string
	Priority          int
	CanMaterialize    bool
	EffectiveCountry  string
	EffectiveCityID   string
	CreatedBy         string
	UpdatedAt         time.Time
}

type CommunityInstance struct {
	ID              uuid.UUID
	CommunityID     *uuid.UUID
	BlueprintID     uuid.UUID
	Slug            string
	CountryCode     string
	CityID          *string
	ScopeType       string
	TitleI18n       map[string]string
	DescriptionI18n map[string]string
	RulesI18n       map[string][]string
	Status          string
	MemberCount     int
	PostCount       int
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type CommunityPlatformCatalog struct {
	PostProfiles []CommunityPostProfile
	Blueprints   []CommunityBlueprint
	GeoHubs      []CommunityGeoHub
	Instances    []CommunityInstance
}

type CommunityMaterializationResult struct {
	MaterializedCount int
}
