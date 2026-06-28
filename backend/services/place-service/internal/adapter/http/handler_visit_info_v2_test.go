package http

import (
	"testing"

	"github.com/google/uuid"
	"kz/inflap/backend/services/place-service/internal/app"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestToVisitInfoResponse_V2Localized(t *testing.T) {
	info := model.PlaceVisitInfo{
		OpeningHours: &model.PlaceOpeningHours{
			Summary:  model.LocalizedText{"en": "Daily 10-18", "ru": "Ежедневно 10-18"},
			Seasonal: model.LocalizedText{"ru": "Только летом"},
			Days:     map[string]any{"mon": "closed"},
		},
		Season:       &model.PlaceSeason{Months: []int{6, 7}, Note: model.LocalizedText{"ru": "Лето"}},
		GettingThere: model.LocalizedText{"en": "3h from Almaty", "ru": "3 ч из Алматы"},
		Included:     []model.LocalizedText{{"ru": "Вход на территорию"}},
		Excluded:     []model.LocalizedText{{"ru": "Гид"}},
		Links:        []model.PlaceLink{{Kind: "WEBSITE", URL: "https://a.kz"}},
	}

	resp := toVisitInfoResponse(info, "ru", "en")

	if resp.OpeningHours == nil || resp.OpeningHours.Summary != "Ежедневно 10-18" {
		t.Fatalf("opening summary = %+v", resp.OpeningHours)
	}
	if resp.OpeningHours.Days["mon"] != "closed" {
		t.Fatalf("days not passed through: %v", resp.OpeningHours.Days)
	}
	if resp.GettingThere != "3 ч из Алматы" {
		t.Fatalf("gettingThere = %q", resp.GettingThere)
	}
	if len(resp.Included) != 1 || resp.Included[0] != "Вход на территорию" {
		t.Fatalf("included = %v", resp.Included)
	}
	if resp.Season == nil || resp.Season.Note != "Лето" || len(resp.Season.Months) != 2 {
		t.Fatalf("season = %+v", resp.Season)
	}
	if len(resp.Links) != 1 || resp.Links[0].URL != "https://a.kz" {
		t.Fatalf("links = %v", resp.Links)
	}
}

func TestToVisitInfoResponse_PlanningBlocksLocalized(t *testing.T) {
	info := model.PlaceVisitInfo{
		PriceNote:     model.LocalizedText{"ru": "Наличными удобнее"},
		TimeOnSite:    &model.PlaceVisitDuration{MinMinutes: intPtrHTTPV2(90), MaxMinutes: intPtrHTTPV2(150), Note: model.LocalizedText{"ru": "Без спешки"}},
		CarTravelTime: &model.PlaceVisitDuration{MinMinutes: intPtrHTTPV2(120), MaxMinutes: intPtrHTTPV2(180), Note: model.LocalizedText{"ru": "От Алматы"}},
		RoadCondition: "GRAVEL",
		FeeItems: []model.PlaceFeeItem{
			{
				Type:      "ENTRANCE",
				Title:     model.LocalizedText{"ru": "Вход"},
				MinAmount: floatPtrHTTPV2(650),
				MaxAmount: floatPtrHTTPV2(900),
				Currency:  "KZT",
				Unit:      "PERSON",
				Required:  true,
				Note:      model.LocalizedText{"ru": "Цена примерная"},
				SortOrder: 10,
			},
		},
		AccessOptions: []model.PlaceAccessOption{
			{
				TransportType:      "CAR",
				DurationMinMinutes: intPtrHTTPV2(120),
				DurationMaxMinutes: intPtrHTTPV2(180),
				RouteHint:          model.LocalizedText{"ru": "Ориентир — кордон"},
				RoadCondition:      "GRAVEL",
				Requires4x4:        true,
				ParkingNote:        model.LocalizedText{"ru": "Парковка у поста"},
				LastSegmentNote:    model.LocalizedText{"ru": "Грунтовка"},
				Note:               model.LocalizedText{"ru": "После дождя осторожно"},
				SortOrder:          20,
			},
		},
		PracticalNotes: []model.PlacePracticalNote{
			{NoteType: "CONNECTION", Title: model.LocalizedText{"ru": "Связь"}, Body: model.LocalizedText{"ru": "Интернет пропадает"}, Priority: "IMPORTANT", SortOrder: 30},
		},
		RecommendedItems: []model.PlaceRecommendedItem{
			{ItemType: "WATER", Title: model.LocalizedText{"ru": "Вода"}, Note: model.LocalizedText{"ru": "1 литр"}, Importance: "REQUIRED", Season: "SUMMER", SortOrder: 40},
		},
	}

	resp := toVisitInfoResponse(info, "ru", "en")

	if resp.PriceNote != "Наличными удобнее" {
		t.Fatalf("priceNote = %q", resp.PriceNote)
	}
	if resp.TimeOnSite == nil || resp.TimeOnSite.Note != "Без спешки" {
		t.Fatalf("timeOnSite = %+v", resp.TimeOnSite)
	}
	if len(resp.FeeItems) != 1 || resp.FeeItems[0].Title != "Вход" || !resp.FeeItems[0].Required {
		t.Fatalf("feeItems = %+v", resp.FeeItems)
	}
	if len(resp.AccessOptions) != 1 || resp.AccessOptions[0].RouteHint != "Ориентир — кордон" || !resp.AccessOptions[0].Requires4x4 {
		t.Fatalf("accessOptions = %+v", resp.AccessOptions)
	}
	if len(resp.PracticalNotes) != 1 || resp.PracticalNotes[0].Body != "Интернет пропадает" {
		t.Fatalf("practicalNotes = %+v", resp.PracticalNotes)
	}
	if len(resp.RecommendedItems) != 1 || resp.RecommendedItems[0].Title != "Вода" {
		t.Fatalf("recommendedItems = %+v", resp.RecommendedItems)
	}
}

func TestToPlaceResponse_PriceSummaryLabelUsesShortCardCopy(t *testing.T) {
	place := &model.Place{
		ID:            uuid.New(),
		AuthorUserID:  uuid.New(),
		Locale:        "ru",
		DefaultLocale: "en",
		PriceAmount:   nil,
		VisitInfo: model.PlaceVisitInfo{
			FeeItems: []model.PlaceFeeItem{
				{
					Type:      "ENTRANCE",
					MinAmount: floatPtrHTTPV2(650),
					Currency:  "KZT",
					Required:  true,
				},
			},
		},
	}

	resp := toPlaceResponse(&app.PlaceView{Place: place, Author: app.PlaceAuthor{UserID: uuid.New()}})

	if resp.PriceSummaryLabel != "от 650 ₸" {
		t.Fatalf("priceSummaryLabel = %q", resp.PriceSummaryLabel)
	}
}

func intPtrHTTPV2(value int) *int {
	return &value
}

func floatPtrHTTPV2(value float64) *float64 {
	return &value
}
