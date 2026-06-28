package model

import (
	"encoding/json"
	"testing"
	"time"
)

func TestPlaceVisitInfo_OpeningHoursV2RoundTrip(t *testing.T) {
	raw := `{
		"openingHours": {
			"is24Hours": false,
			"days": {"mon": "closed", "tue": {"open": "10:00", "close": "18:00"}},
			"seasonal": {"en": "Summer only", "ru": "Только летом", "kk": "Тек жазда"},
			"summary": {"en": "Tue-Sun 10:00-18:00", "ru": "Вт-Вс 10:00-18:00", "kk": "Сс-Жс 10:00-18:00"}
		},
		"season": {"months": [5,6,7,8,9], "note": {"en": "Best late spring to early autumn"}},
		"gettingThere": {"en": "3 h drive from Almaty"},
		"included": [{"en": "Area entry"}],
		"excluded": [{"en": "Guide"}],
		"links": [{"kind": "WEBSITE", "url": "https://example.kz"}]
	}`

	var info PlaceVisitInfo
	if err := json.Unmarshal([]byte(raw), &info); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if info.OpeningHours == nil || info.OpeningHours.Summary["en"] != "Tue-Sun 10:00-18:00" {
		t.Fatalf("openingHours not parsed: %+v", info.OpeningHours)
	}
	if info.OpeningHours.Days["mon"] != "closed" {
		t.Fatalf("days[mon] = %v, want \"closed\"", info.OpeningHours.Days["mon"])
	}
	if info.Season == nil || len(info.Season.Months) != 5 || info.Season.Months[0] != 5 {
		t.Fatalf("season months = %+v", info.Season)
	}
	if info.GettingThere["en"] != "3 h drive from Almaty" {
		t.Fatalf("gettingThere = %v", info.GettingThere)
	}
	if len(info.Included) != 1 || info.Included[0]["en"] != "Area entry" {
		t.Fatalf("included = %v", info.Included)
	}
	if len(info.Links) != 1 || info.Links[0].Kind != "WEBSITE" {
		t.Fatalf("links = %v", info.Links)
	}

	out, err := json.Marshal(info)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var info2 PlaceVisitInfo
	if err := json.Unmarshal(out, &info2); err != nil {
		t.Fatalf("re-unmarshal: %v", err)
	}
	if info2.OpeningHours == nil || info2.OpeningHours.Summary["ru"] != "Вт-Вс 10:00-18:00" {
		t.Fatalf("round-trip lost data: %s", out)
	}
}

func TestPlaceVisitInfo_PlanningFieldsRoundTrip(t *testing.T) {
	raw := `{
		"priceNote": {"ru": "Нужны наличные на экосбор"},
		"timeOnSite": {"minMinutes": 90, "maxMinutes": 150, "note": {"ru": "Без трека к водопаду"}},
		"carTravelTime": {"minMinutes": 120, "maxMinutes": 180, "note": {"ru": "От центра Алматы без пробок"}},
		"roadCondition": "GRAVEL",
		"feeItems": [{
			"type": "entrance",
			"title": {"ru": "Вход в нацпарк"},
			"description": {"ru": "Билет на человека"},
			"minAmount": 650,
			"maxAmount": 650,
			"currency": "KZT",
			"unit": "PERSON",
			"required": true,
			"note": {"ru": "Цена может меняться"},
			"sortOrder": 10
		}],
		"accessOptions": [{
			"transportType": "car",
			"durationMinMinutes": 120,
			"durationMaxMinutes": 180,
			"distanceKm": 92.5,
			"routeHint": {"ru": "Ориентир — пост нацпарка"},
			"roadCondition": "GRAVEL",
			"requires4x4": true,
			"parkingNote": {"ru": "Парковка у кордона"},
			"lastSegmentNote": {"ru": "Последние километры по грунтовке"},
			"note": {"ru": "После дождя ехать осторожно"},
			"sortOrder": 20
		}],
		"practicalNotes": [{
			"noteType": "connection",
			"title": {"ru": "Связь"},
			"body": {"ru": "Местами пропадает мобильный интернет"},
			"priority": "important",
			"sortOrder": 30
		}],
		"recommendedItems": [{
			"itemType": "water",
			"title": {"ru": "Вода"},
			"note": {"ru": "Минимум 1 литр на человека"},
			"importance": "required",
			"season": "summer",
			"sortOrder": 40
		}]
	}`

	var info PlaceVisitInfo
	if err := json.Unmarshal([]byte(raw), &info); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if info.PriceNote["ru"] != "Нужны наличные на экосбор" {
		t.Fatalf("priceNote = %v", info.PriceNote)
	}
	if info.TimeOnSite == nil || info.TimeOnSite.MinMinutes == nil || *info.TimeOnSite.MinMinutes != 90 {
		t.Fatalf("timeOnSite = %+v", info.TimeOnSite)
	}
	if info.CarTravelTime == nil || info.CarTravelTime.MaxMinutes == nil || *info.CarTravelTime.MaxMinutes != 180 {
		t.Fatalf("carTravelTime = %+v", info.CarTravelTime)
	}
	if len(info.FeeItems) != 1 || info.FeeItems[0].Type != "entrance" || !info.FeeItems[0].Required {
		t.Fatalf("feeItems = %+v", info.FeeItems)
	}
	if len(info.AccessOptions) != 1 || !info.AccessOptions[0].Requires4x4 {
		t.Fatalf("accessOptions = %+v", info.AccessOptions)
	}
	if len(info.PracticalNotes) != 1 || info.PracticalNotes[0].Title["ru"] != "Связь" {
		t.Fatalf("practicalNotes = %+v", info.PracticalNotes)
	}
	if len(info.RecommendedItems) != 1 || info.RecommendedItems[0].Importance != "required" {
		t.Fatalf("recommendedItems = %+v", info.RecommendedItems)
	}

	out, err := json.Marshal(info)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	var info2 PlaceVisitInfo
	if err := json.Unmarshal(out, &info2); err != nil {
		t.Fatalf("re-unmarshal: %v", err)
	}
	if len(info2.RecommendedItems) != 1 || info2.RecommendedItems[0].Note["ru"] != "Минимум 1 литр на человека" {
		t.Fatalf("round-trip lost planning fields: %s", out)
	}
}

func TestPlaceVisitInfo_LastVerifiedAtAcceptsDateOnly(t *testing.T) {
	raw := `{"lastVerifiedAt":"2026-06-26"}`

	var info PlaceVisitInfo
	if err := json.Unmarshal([]byte(raw), &info); err != nil {
		t.Fatalf("unmarshal date-only lastVerifiedAt: %v", err)
	}

	if info.LastVerifiedAt == nil {
		t.Fatal("lastVerifiedAt = nil")
	}
	if got := info.LastVerifiedAt.Format(time.DateOnly); got != "2026-06-26" {
		t.Fatalf("lastVerifiedAt = %s, want 2026-06-26", got)
	}
}
