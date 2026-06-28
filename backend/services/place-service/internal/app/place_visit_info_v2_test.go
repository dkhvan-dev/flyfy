package app

import (
	"testing"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestNormalizeVisitInfo_V2Fields(t *testing.T) {
	in := &PlaceVisitInfoInput{
		OpeningHours: &model.PlaceOpeningHours{
			Summary:  model.LocalizedText{"en": "  Daily 10-18  ", "xx": "ignored"},
			Seasonal: model.LocalizedText{"ru": "Только летом"},
			Days:     map[string]any{"mon": "closed", "bogus": "x", "tue": map[string]any{"open": "10:00", "close": "18:00"}},
		},
		Season:       &model.PlaceSeason{Months: []int{5, 5, 0, 13, 9}, Note: model.LocalizedText{"en": "Spring"}},
		GettingThere: model.LocalizedText{"en": "  3h from Almaty  "},
		Included:     []model.LocalizedText{{"en": "Area entry"}, {"en": "   "}},
		Excluded:     []model.LocalizedText{{"en": "Guide"}},
		Links:        []model.PlaceLink{{Kind: "website", URL: "  https://a.kz "}, {Kind: "X", URL: ""}},
	}

	got, err := normalizeVisitInfo(in, nil)
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	if got.OpeningHours == nil || got.OpeningHours.Summary["en"] != "Daily 10-18" {
		t.Fatalf("summary not trimmed/localized: %+v", got.OpeningHours)
	}
	if _, ok := got.OpeningHours.Summary["xx"]; ok {
		t.Fatalf("invalid locale kept in summary")
	}
	if _, ok := got.OpeningHours.Days["bogus"]; ok {
		t.Fatalf("invalid day key kept")
	}
	if got.Season == nil || len(got.Season.Months) != 2 { // 5 (deduped) and 9; 0 and 13 dropped
		t.Fatalf("season months = %v", got.Season.Months)
	}
	if got.GettingThere["en"] != "3h from Almaty" {
		t.Fatalf("gettingThere = %v", got.GettingThere)
	}
	if len(got.Included) != 1 {
		t.Fatalf("included should drop empty: %v", got.Included)
	}
	if len(got.Links) != 1 || got.Links[0].Kind != "WEBSITE" || got.Links[0].URL != "https://a.kz" {
		t.Fatalf("links = %v", got.Links)
	}
}

func TestNormalizeVisitInfo_PlanningFields(t *testing.T) {
	in := &PlaceVisitInfoInput{
		PriceNote:     model.LocalizedText{"ru": "  Наличными удобнее  ", "zz": "ignored"},
		TimeOnSite:    &model.PlaceVisitDuration{MinMinutes: intPtrV2(90), MaxMinutes: intPtrV2(150), Note: model.LocalizedText{"ru": "  Без спешки  "}},
		CarTravelTime: &model.PlaceVisitDuration{MinMinutes: intPtrV2(120), MaxMinutes: intPtrV2(180), Note: model.LocalizedText{"ru": "От Алматы"}},
		RoadCondition: " gravel ",
		FeeItems: []PlaceFeeDetailInput{
			{
				Type:          " entrance ",
				Title:         map[string]string{"ru": " Вход "},
				Description:   map[string]string{"ru": "Билет"},
				MinAmount:     floatPtrV2(650),
				MaxAmount:     floatPtrV2(900),
				Currency:      "kzt",
				Unit:          " person ",
				Required:      true,
				IsApproximate: true,
				Note:          map[string]string{"ru": "Цена примерная"},
				SortOrder:     20,
			},
		},
		AccessOptions: []model.PlaceAccessOption{
			{
				TransportType:      " car ",
				DurationMinMinutes: intPtrV2(120),
				DurationMaxMinutes: intPtrV2(180),
				DistanceKm:         floatPtrV2(92.5),
				RouteHint:          model.LocalizedText{"ru": " Ориентир — кордон "},
				RoadCondition:      " gravel ",
				Requires4x4:        true,
				ParkingNote:        model.LocalizedText{"ru": "Парковка у поста"},
				LastSegmentNote:    model.LocalizedText{"ru": "Грунтовка"},
				Note:               model.LocalizedText{"ru": "После дождя осторожно"},
				SortOrder:          30,
			},
		},
		PracticalNotes: []model.PlacePracticalNote{
			{
				NoteType:  " connection ",
				Title:     model.LocalizedText{"ru": " Связь "},
				Body:      model.LocalizedText{"ru": "Местами пропадает интернет"},
				Priority:  " important ",
				SortOrder: 40,
			},
		},
		RecommendedItems: []model.PlaceRecommendedItem{
			{
				ItemType:   " water ",
				Title:      model.LocalizedText{"ru": " Вода "},
				Note:       model.LocalizedText{"ru": "1 литр"},
				Importance: " required ",
				Season:     " summer ",
				SortOrder:  50,
			},
		},
	}

	got, err := normalizeVisitInfo(in, nil)
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	if got.PriceNote["ru"] != "Наличными удобнее" {
		t.Fatalf("priceNote = %v", got.PriceNote)
	}
	if got.TimeOnSite == nil || *got.TimeOnSite.MinMinutes != 90 || got.TimeOnSite.Note["ru"] != "Без спешки" {
		t.Fatalf("timeOnSite = %+v", got.TimeOnSite)
	}
	if got.RoadCondition != "GRAVEL" {
		t.Fatalf("roadCondition = %q", got.RoadCondition)
	}
	if len(got.FeeItems) != 1 || got.FeeItems[0].Type != "ENTRANCE" || got.FeeItems[0].Currency != "KZT" || !got.FeeItems[0].Required {
		t.Fatalf("feeItems = %+v", got.FeeItems)
	}
	if len(got.AccessOptions) != 1 || got.AccessOptions[0].TransportType != "CAR" || !got.AccessOptions[0].Requires4x4 {
		t.Fatalf("accessOptions = %+v", got.AccessOptions)
	}
	if len(got.PracticalNotes) != 1 || got.PracticalNotes[0].Priority != "IMPORTANT" {
		t.Fatalf("practicalNotes = %+v", got.PracticalNotes)
	}
	if len(got.RecommendedItems) != 1 || got.RecommendedItems[0].Importance != "REQUIRED" {
		t.Fatalf("recommendedItems = %+v", got.RecommendedItems)
	}
}

func intPtrV2(value int) *int {
	return &value
}

func floatPtrV2(value float64) *float64 {
	return &value
}
