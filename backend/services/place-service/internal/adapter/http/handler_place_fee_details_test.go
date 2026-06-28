package http

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/app"
	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestToPlaceResponseLocalizesFeeDetails(t *testing.T) {
	t.Parallel()

	amount := 648.75
	placeID := uuid.New()
	view := &app.PlaceView{
		Place: &model.Place{
			ID:            placeID,
			AuthorUserID:  uuid.New(),
			DefaultLocale: "en",
			Locale:        "ru",
			Title:         "Пик Фурманова",
			Description:   "Маршрут через национальный парк",
			CountryCode:   "KZ",
			CityID:        "almaty",
			Category:      enum.CategoryNature,
			Source:        enum.SourceImport,
			Status:        enum.StatusPublished,
			VisitInfo: model.PlaceVisitInfo{
				FeeDetails: []model.PlaceFeeDetail{
					{
						Title: map[string]string{
							"en": "National park entry",
							"ru": "Вход в национальный парк",
							"kk": "Ұлттық паркке кіру",
						},
						Description: map[string]string{
							"en": "Approximate visitor fee for protected natural areas",
							"ru": "Примерный сбор за посещение особо охраняемой природной территории",
						},
						Amount:        &amount,
						Currency:      "KZT",
						Unit:          "PERSON",
						IsApproximate: true,
						SortOrder:     10,
					},
				},
			},
			CreatedAt: time.Date(2026, 6, 24, 10, 0, 0, 0, time.UTC),
			UpdatedAt: time.Date(2026, 6, 24, 10, 0, 0, 0, time.UTC),
		},
		Author: app.PlaceAuthor{UserID: uuid.New()},
	}

	response := toPlaceResponse(view)
	if response == nil {
		t.Fatal("response is nil")
	}
	if len(response.VisitInfo.FeeDetails) != 1 {
		t.Fatalf("fee details length = %d, want 1", len(response.VisitInfo.FeeDetails))
	}

	fee := response.VisitInfo.FeeDetails[0]
	if fee.Title != "Вход в национальный парк" {
		t.Fatalf("fee title = %q, want localized russian title", fee.Title)
	}
	if fee.Description != "Примерный сбор за посещение особо охраняемой природной территории" {
		t.Fatalf("fee description = %q, want localized russian description", fee.Description)
	}
	if fee.Amount == nil || *fee.Amount != amount {
		t.Fatalf("fee amount = %v, want %v", fee.Amount, amount)
	}
	if fee.Currency != "KZT" || fee.Unit != "PERSON" || !fee.IsApproximate || fee.SortOrder != 10 {
		t.Fatalf("unexpected fee payload: %#v", fee)
	}
}

func TestToAdminPlaceResponseIncludesLocalizedVisitInfoMaps(t *testing.T) {
	t.Parallel()

	minMinutes := 90
	maxMinutes := 150
	amount := 1000.0
	place := &model.Place{
		ID:            uuid.New(),
		DefaultLocale: "ru",
		Locale:        "ru",
		Title:         "Чарынский каньон",
		Description:   "Каньон",
		CountryCode:   "KZ",
		CityID:        "almaty",
		Category:      "NATURE",
		Source:        "IMPORT",
		Status:        "PUBLISHED",
		VisitInfo: model.PlaceVisitInfo{
			OpeningHours: &model.PlaceOpeningHours{Summary: model.LocalizedText{"ru": "Ежедневно 09:00-18:00", "en": "Daily 09:00-18:00", "kk": "Күн сайын 09:00-18:00"}},
			PriceNote:    model.LocalizedText{"ru": "Билет и экосбор отдельно", "en": "Ticket and eco fee are paid separately", "kk": "Билет пен экоалым бөлек төленеді"},
			TimeOnSite:   &model.PlaceVisitDuration{MinMinutes: &minMinutes, MaxMinutes: &maxMinutes, Note: model.LocalizedText{"ru": "Без трека к реке", "en": "Without the river trail", "kk": "Өзен соқпағынсыз"}},
			FeeDetails: []model.PlaceFeeDetail{
				{
					Title:         model.LocalizedText{"ru": "Вход", "en": "Admission", "kk": "Кіру"},
					Description:   model.LocalizedText{"ru": "Базовый билет", "en": "Base ticket", "kk": "Негізгі билет"},
					Amount:        &amount,
					Currency:      "KZT",
					Unit:          "PERSON",
					IsApproximate: true,
					SortOrder:     10,
				},
			},
		},
	}

	response := toAdminPlaceResponse(&app.PlaceView{Place: place, Author: app.PlaceAuthor{UserID: uuid.New()}})
	if response.VisitInfoLocales == nil {
		t.Fatal("VisitInfoLocales was not included")
	}
	if got := response.VisitInfoLocales.PriceNote["en"]; got != "Ticket and eco fee are paid separately" {
		t.Fatalf("priceNote.en = %q", got)
	}
	if got := response.VisitInfoLocales.OpeningHours["kk"]; got != "Күн сайын 09:00-18:00" {
		t.Fatalf("openingHours.kk = %q", got)
	}
	if response.VisitInfoLocales.TimeOnSite == nil || response.VisitInfoLocales.TimeOnSite.Note["kk"] != "Өзен соқпағынсыз" {
		t.Fatalf("timeOnSite = %#v", response.VisitInfoLocales.TimeOnSite)
	}
	if len(response.VisitInfoLocales.FeeDetails) != 1 || response.VisitInfoLocales.FeeDetails[0].Title["en"] != "Admission" {
		t.Fatalf("feeDetails = %#v", response.VisitInfoLocales.FeeDetails)
	}
}
