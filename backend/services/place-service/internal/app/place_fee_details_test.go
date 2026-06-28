package app

import (
	"testing"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestNormalizeVisitInfoPreservesExistingFeeDetailsWhenInputOmitsThem(t *testing.T) {
	t.Parallel()

	amount := 1297.5
	existing := &model.PlaceVisitInfo{
		FeeDetails: []model.PlaceFeeDetail{
			{
				Title: map[string]string{
					"en": "Car access",
					"ru": "Въезд на авто",
				},
				Amount:        &amount,
				Currency:      "KZT",
				Unit:          "CAR",
				IsApproximate: true,
				SortOrder:     20,
			},
		},
	}

	normalized, err := normalizeVisitInfo(&PlaceVisitInfoInput{
		BestTime: "morning",
	}, existing)
	if err != nil {
		t.Fatalf("normalizeVisitInfo() error = %v", err)
	}

	if len(normalized.FeeDetails) != 1 {
		t.Fatalf("fee details length = %d, want 1", len(normalized.FeeDetails))
	}
	if normalized.FeeDetails[0].Title["ru"] != "Въезд на авто" {
		t.Fatalf("preserved fee title = %q", normalized.FeeDetails[0].Title["ru"])
	}
}

func TestNormalizeVisitInfoMergesPartialLocalizedPlanningUpdates(t *testing.T) {
	t.Parallel()

	existing := &model.PlaceVisitInfo{
		PriceNote: model.LocalizedText{
			"ru": "Старая цена",
			"en": "Old price",
			"kk": "Ескі баға",
		},
		FeeItems: []model.PlaceFeeItem{
			{
				Type: "ENTRANCE",
				Title: model.LocalizedText{
					"ru": "Старый вход",
					"en": "Entrance",
					"kk": "Кіру",
				},
				Note: model.LocalizedText{
					"ru": "Старая заметка",
					"en": "Old note",
					"kk": "Ескі ескерту",
				},
				Currency:  "KZT",
				Unit:      "PERSON",
				SortOrder: 10,
			},
		},
		AccessOptions: []model.PlaceAccessOption{
			{
				TransportType: "CAR",
				RouteHint: model.LocalizedText{
					"ru": "Старый ориентир",
					"en": "Old route",
					"kk": "Ескі бағдар",
				},
				SortOrder: 10,
			},
		},
		PracticalNotes: []model.PlacePracticalNote{
			{
				NoteType: "WEATHER",
				Body: model.LocalizedText{
					"ru": "Старый текст",
					"en": "Old body",
					"kk": "Ескі мәтін",
				},
				SortOrder: 10,
			},
		},
		RecommendedItems: []model.PlaceRecommendedItem{
			{
				ItemType: "WATER",
				Title: model.LocalizedText{
					"ru": "Старая вода",
					"en": "Water",
					"kk": "Су",
				},
				SortOrder: 10,
			},
		},
	}

	normalized, err := normalizeVisitInfo(&PlaceVisitInfoInput{
		PriceNote: model.LocalizedText{"ru": "Новая цена"},
		FeeItems: []PlaceFeeDetailInput{
			{
				Type:      "ENTRANCE",
				Title:     model.LocalizedText{"ru": "Новый вход"},
				Note:      model.LocalizedText{"ru": "Новая заметка"},
				Currency:  "KZT",
				Unit:      "PERSON",
				SortOrder: 10,
			},
		},
		AccessOptions: []model.PlaceAccessOption{
			{
				TransportType: "CAR",
				RouteHint:     model.LocalizedText{"ru": "Новый ориентир"},
				SortOrder:     10,
			},
		},
		PracticalNotes: []model.PlacePracticalNote{
			{
				NoteType:  "WEATHER",
				Body:      model.LocalizedText{"ru": "Новый текст"},
				SortOrder: 10,
			},
		},
		RecommendedItems: []model.PlaceRecommendedItem{
			{
				ItemType:  "WATER",
				Title:     model.LocalizedText{"ru": "Новая вода"},
				SortOrder: 10,
			},
		},
	}, existing)
	if err != nil {
		t.Fatalf("normalizeVisitInfo() error = %v", err)
	}

	if normalized.PriceNote["ru"] != "Новая цена" || normalized.PriceNote["en"] != "Old price" || normalized.PriceNote["kk"] != "Ескі баға" {
		t.Fatalf("merged priceNote = %#v", normalized.PriceNote)
	}
	if normalized.FeeItems[0].Title["ru"] != "Новый вход" || normalized.FeeItems[0].Title["en"] != "Entrance" || normalized.FeeItems[0].Title["kk"] != "Кіру" {
		t.Fatalf("merged fee item title = %#v", normalized.FeeItems[0].Title)
	}
	if normalized.FeeItems[0].Note["en"] != "Old note" || normalized.FeeItems[0].Note["kk"] != "Ескі ескерту" {
		t.Fatalf("merged fee item note = %#v", normalized.FeeItems[0].Note)
	}
	if normalized.AccessOptions[0].RouteHint["en"] != "Old route" || normalized.AccessOptions[0].RouteHint["ru"] != "Новый ориентир" {
		t.Fatalf("merged route hint = %#v", normalized.AccessOptions[0].RouteHint)
	}
	if normalized.PracticalNotes[0].Body["en"] != "Old body" || normalized.PracticalNotes[0].Body["ru"] != "Новый текст" {
		t.Fatalf("merged practical note = %#v", normalized.PracticalNotes[0].Body)
	}
	if normalized.RecommendedItems[0].Title["en"] != "Water" || normalized.RecommendedItems[0].Title["ru"] != "Новая вода" {
		t.Fatalf("merged recommended item = %#v", normalized.RecommendedItems[0].Title)
	}
}
