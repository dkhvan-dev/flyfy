package excursion

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func TestListPendingReviewUsesAdminModerationEndpoint(t *testing.T) {
	t.Parallel()

	var gotPath string
	var gotRoles string
	client := NewClient("http://excursion-service:8093", 0, "internal-token")
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotPath = r.URL.Path
		gotRoles = r.Header.Get("X-User-Roles")
		if gotPath != "/v1/admin/excursions/moderation/pending" {
			t.Fatalf("path = %q, want admin pending endpoint", gotPath)
		}
		if r.URL.Query().Get("limit") != "25" || r.URL.Query().Get("offset") != "5" {
			t.Fatalf("query = %q, want limit=25 offset=5", r.URL.RawQuery)
		}
		if r.Header.Get("X-Internal-Service-Token") != "internal-token" {
			t.Fatalf("internal token header = %q", r.Header.Get("X-Internal-Service-Token"))
		}
		var builder strings.Builder
		_ = json.NewEncoder(&builder).Encode(excursionListResponse{Items: []excursionResponse{{
			ID:          "22222222-2222-2222-2222-222222222222",
			GuideUserID: "33333333-3333-3333-3333-333333333333",
			Title:       "Medeu",
		}}})
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(builder.String())),
			Header:     make(http.Header),
		}, nil
	})}

	items, err := client.ListPendingReview(context.Background(), 25, 5)
	if err != nil {
		t.Fatalf("ListPendingReview() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items = %d, want 1", len(items))
	}
	if gotRoles != "SUPER_ADMIN,MODERATOR" {
		t.Fatalf("roles header = %q, want moderator roles", gotRoles)
	}
}

func TestGetExcursionUsesAdminEndpoint(t *testing.T) {
	t.Parallel()

	client := NewClient("http://excursion-service:8093", 0, "internal-token")
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path != "/v1/admin/excursions/22222222-2222-2222-2222-222222222222" {
			t.Fatalf("path = %q, want admin excursion detail endpoint", r.URL.Path)
		}
		if r.Header.Get("X-User-Roles") != "SUPER_ADMIN,MODERATOR" {
			t.Fatalf("roles header = %q, want moderator roles", r.Header.Get("X-User-Roles"))
		}
		var builder strings.Builder
		_ = json.NewEncoder(&builder).Encode(excursionResponse{
			ID:              "22222222-2222-2222-2222-222222222222",
			GuideUserID:     "33333333-3333-3333-3333-333333333333",
			Title:           "Medeu",
			CountryCode:     stringPtr("KZ"),
			CityName:        stringPtr("Almaty"),
			DepartureCityID: stringPtr("almaty"),
		})
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(strings.NewReader(builder.String())),
			Header:     make(http.Header),
		}, nil
	})}

	item, err := client.GetExcursion(context.Background(), mustUUID(t, "22222222-2222-2222-2222-222222222222"))
	if err != nil {
		t.Fatalf("GetExcursion() error = %v", err)
	}
	if item.CityName != "Almaty" || item.DepartureCityID != "almaty" {
		t.Fatalf("city snapshot = %q/%q, want Almaty/almaty", item.CityName, item.DepartureCityID)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}

func TestExcursionResponseToModelExtractsItineraryPlaces(t *testing.T) {
	t.Parallel()

	firstID := "11111111-1111-1111-1111-111111111111"
	resp := excursionResponse{
		ID:               "22222222-2222-2222-2222-222222222222",
		GuideUserID:      "33333333-3333-3333-3333-333333333333",
		Title:            "Kok-Tobe + Cathedral",
		GuideDisplayName: "Guide",
		GuideNickname:    "@nomad_aru",
		GuideFirstName:   "Aruzhan",
		GuideLastName:    "Khan",
		DurationMinutes:  180,
		MaxGroupSize:     10,
		LanguageCodes:    []string{"ru", "en", "ru"},
		MeetingPoint:     "Main entrance",
		MeetingPointTranslations: map[string]string{
			"ru": "Главный вход",
		},
		Latitude:      floatPtr(43.157036),
		Longitude:     floatPtr(77.058482),
		MapURL:        stringPtr("https://inflap.app/map?lat=43.157036&lon=77.058482&title=Medeu"),
		IncludedItems: []string{"transport", "tickets", "transport"},
		IncludedTranslations: map[string][]string{
			"ru": {"Транспорт", "Входные билеты"},
		},
		ProductTranslations: map[string]localizedCopyResponse{
			"ru": {Title: "Кок-Тобе и собор"},
		},
		Itinerary: []excursionItineraryItemResponse{
			{
				ID:                 "55555555-5555-5555-5555-555555555555",
				SortOrder:          0,
				StartOffsetMinutes: 0,
				DurationMinutes:    intPtr(45),
				PlaceID:            &firstID,
				PlaceName:          stringPtr("Kok-Tobe"),
				Title:              "Kok-Tobe",
				Description:        "Ride uphill.",
				Translations: map[string]localizedItineraryResponse{
					"ru": {Title: "Кок-Тобе", Description: "Подъем к смотровой."},
				},
			},
			{
				SortOrder:                 1,
				StartOffsetMinutes:        75,
				DurationMinutes:           intPtr(30),
				TravelFromPreviousMinutes: intPtr(20),
				PlaceID:                   stringPtr("44444444-4444-4444-4444-444444444444"),
				PlaceName:                 stringPtr("Cathedral"),
				Title:                     "Cathedral",
				Translations: map[string]localizedItineraryResponse{
					"ru": {Title: "Собор"},
				},
			},
			{
				PlaceID:   &firstID,
				PlaceName: stringPtr("Kok-Tobe"),
				Title:     "Duplicate",
				Translations: map[string]localizedItineraryResponse{
					"ru": {Title: "Кок-Тобе"},
				},
			},
			{Title: "Meeting point"},
		},
	}

	item := resp.toModel()
	if item.StopCount != 4 {
		t.Fatalf("StopCount = %d, want 4", item.StopCount)
	}
	if len(item.PlaceNames) != 2 {
		t.Fatalf("PlaceNames length = %d, want 2: %#v", len(item.PlaceNames), item.PlaceNames)
	}
	if item.PlaceNames[0] != "Kok-Tobe" || item.PlaceNames[1] != "Cathedral" {
		t.Fatalf("PlaceNames = %#v, want Kok-Tobe, Cathedral", item.PlaceNames)
	}
	if item.GuideNickname != "@nomad_aru" {
		t.Fatalf("GuideNickname = %q, want @nomad_aru", item.GuideNickname)
	}
	if item.GuideLastName != "Khan" || item.GuideFirstName != "Aruzhan" {
		t.Fatalf("guide full name = %q %q, want Khan Aruzhan", item.GuideLastName, item.GuideFirstName)
	}
	if item.ProductTranslations["ru"].Title != "Кок-Тобе и собор" {
		t.Fatalf("localized product title = %q, want Russian title", item.ProductTranslations["ru"].Title)
	}
	if got := item.PlaceNamesByLocale["ru"]; len(got) != 2 || got[0] != "Кок-Тобе" || got[1] != "Собор" {
		t.Fatalf("localized place names = %#v, want Russian names", got)
	}
	if item.DurationMinutes != 180 || item.MaxGroupSize != 10 || item.MeetingPoint != "Main entrance" {
		t.Fatalf("route facts = duration %d group %d meeting %q, want 180/10/Main entrance", item.DurationMinutes, item.MaxGroupSize, item.MeetingPoint)
	}
	if item.MeetingPointByLocale["ru"] != "Главный вход" {
		t.Fatalf("meeting point translations = %#v, want Russian label", item.MeetingPointByLocale)
	}
	if item.Latitude == nil || item.Longitude == nil || *item.Latitude != 43.157036 || *item.Longitude != 77.058482 {
		t.Fatalf("meeting coordinates = %#v,%#v, want 43.157036/77.058482", item.Latitude, item.Longitude)
	}
	if item.MapURL == nil || *item.MapURL != "https://inflap.app/map?lat=43.157036&lon=77.058482&title=Medeu" {
		t.Fatalf("meeting map url = %#v, want Inflap map URL", item.MapURL)
	}
	if len(item.LanguageCodes) != 2 || item.LanguageCodes[0] != "ru" || item.LanguageCodes[1] != "en" {
		t.Fatalf("language codes = %#v, want deduplicated ru/en", item.LanguageCodes)
	}
	if len(item.IncludedItems) != 2 || item.IncludedItems[0] != "transport" || item.IncludedItems[1] != "tickets" {
		t.Fatalf("included items = %#v, want deduplicated transport/tickets", item.IncludedItems)
	}
	if got := item.IncludedItemsByLocale["ru"]; len(got) != 2 || got[0] != "Транспорт" || got[1] != "Входные билеты" {
		t.Fatalf("localized included items = %#v, want Russian labels", got)
	}
	if len(item.Itinerary) != 4 {
		t.Fatalf("itinerary length = %d, want 4", len(item.Itinerary))
	}
	if item.Itinerary[0].StartOffsetMinutes != 0 || item.Itinerary[0].DurationMinutes == nil || *item.Itinerary[0].DurationMinutes != 45 {
		t.Fatalf("first itinerary timing = offset %d duration %#v, want 0/45", item.Itinerary[0].StartOffsetMinutes, item.Itinerary[0].DurationMinutes)
	}
	if item.Itinerary[0].Translations["ru"].Description != "Подъем к смотровой." {
		t.Fatalf("itinerary translation = %#v, want localized description", item.Itinerary[0].Translations["ru"])
	}
	if item.Itinerary[1].TravelFromPreviousMinutes == nil || *item.Itinerary[1].TravelFromPreviousMinutes != 20 {
		t.Fatalf("second itinerary travel = %#v, want 20", item.Itinerary[1].TravelFromPreviousMinutes)
	}
}

func stringPtr(value string) *string {
	return &value
}

func intPtr(value int) *int {
	return &value
}

func floatPtr(value float64) *float64 {
	return &value
}

func mustUUID(t *testing.T, value string) uuid.UUID {
	t.Helper()
	id, err := uuid.Parse(value)
	if err != nil {
		t.Fatalf("parse uuid %q: %v", value, err)
	}
	return id
}
