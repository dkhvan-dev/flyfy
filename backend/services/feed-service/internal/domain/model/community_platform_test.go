package model

import (
	"testing"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

func TestCommunityGeoHubAliasOnlyIsNotMaterializable(t *testing.T) {
	hub := CommunityGeoHub{
		CountryCode:       "KZ",
		CityID:            "taldykorgan",
		HubTier:           enum.CommunityGeoHubTierAliasOnly,
		CommunityEnabled:  false,
		ParentCountryCode: stringPtr("KZ"),
		ParentCityID:      stringPtr("almaty"),
	}

	if hub.CanMaterializeCommunity() {
		t.Fatalf("alias-only hub must not materialize standalone communities")
	}
	if got := hub.EffectiveCityID(); got != "almaty" {
		t.Fatalf("EffectiveCityID() = %q, want parent hub almaty", got)
	}
}

func TestCommunityGeoHubEnabledCityMaterializesItself(t *testing.T) {
	hub := CommunityGeoHub{
		CountryCode:      "VN",
		CityID:           "da-nang",
		HubTier:          enum.CommunityGeoHubTierRegional,
		CommunityEnabled: true,
	}

	if !hub.CanMaterializeCommunity() {
		t.Fatalf("enabled regional hub should materialize communities")
	}
	if got := hub.EffectiveCityID(); got != "da-nang" {
		t.Fatalf("EffectiveCityID() = %q, want own city da-nang", got)
	}
}

func TestPostProfileRequiresActivityIntentForEventProfiles(t *testing.T) {
	profile := CommunityPostProfile{
		Key:                  enum.PostProfileEventAnnouncementV1,
		PostKind:             enum.PostKindEventAnnouncement,
		ActivityCreationMode: enum.ActivityCreationModeRequired,
	}

	if !profile.RequiresActivityIntent() {
		t.Fatalf("event announcement with required activity mode must require activity intent")
	}
}

func stringPtr(value string) *string {
	return &value
}
