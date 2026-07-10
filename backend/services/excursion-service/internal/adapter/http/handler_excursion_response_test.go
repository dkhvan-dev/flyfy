package http

import (
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/app"
	"kz/inflap/backend/services/excursion-service/internal/domain/enum"
	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/transport/dto"
)

func TestExcursionResponseUsesProductCoverWhenOfferCoverIsMissing(t *testing.T) {
	productCoverFileID := uuid.New()
	excursion := &model.Excursion{
		ID:               uuid.New(),
		GuideProfileID:   uuid.New(),
		GuideUserID:      uuid.New(),
		GuideDisplayName: "Aruzhan T.",
		GuideNickname:    "@nomad_aru",
		GuideFirstName:   "Aruzhan",
		GuideLastName:    "Khan",
		Title:            "Medeu tour",
		Summary:          "Private mountain route",
		Description:      "A detailed mountain excursion through Medeu.",
		ProductTranslations: model.ExcursionTranslations{
			"ru": {Title: "Высокогорный каток Медеу"},
			"en": {Title: "Medeu Alpine Skating Rink"},
		},
		CategorySlug:    "nature",
		Status:          enum.ExcursionStatusDraft,
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 180,
		MaxGroupSize:    6,
		MeetingPoint:    "Medeu entrance",
		PriceAmount:     120,
		Currency:        "KZT",
		Revision:        1,
		CreatedAt:       time.Now().UTC(),
		UpdatedAt:       time.Now().UTC(),
	}

	response := toExcursionResponse(&app.ExcursionAggregate{
		Excursion:          excursion,
		ProductCoverFileID: &productCoverFileID,
	})

	if response.CoverFileID == nil || *response.CoverFileID != productCoverFileID.String() {
		t.Fatalf("cover file id = %v, want product cover %s", response.CoverFileID, productCoverFileID)
	}
	if response.CoverImageURL != nil {
		t.Fatalf("cover image url = %v, want nil when only product cover is available", *response.CoverImageURL)
	}
	if response.GuideDisplayName != "Aruzhan T." {
		t.Fatalf("guide nickname = %q, want snapshot nickname", response.GuideDisplayName)
	}
	if response.GuideNickname != "@nomad_aru" {
		t.Fatalf("guide nickname = %q, want snapshot nickname", response.GuideNickname)
	}
	if response.GuideLastName != "Khan" || response.GuideFirstName != "Aruzhan" {
		t.Fatalf("guide full name = %q %q, want Khan Aruzhan", response.GuideLastName, response.GuideFirstName)
	}
	if response.ProductTranslations["ru"].Title != "Высокогорный каток Медеу" {
		t.Fatalf("localized product title = %q, want Russian title", response.ProductTranslations["ru"].Title)
	}
}

func TestExcursionResponseUsesProductCoverImageURLWhenFileCoverIsMissing(t *testing.T) {
	productCoverImageURL := "https://upload.wikimedia.org/dragon-bridge.jpg"
	excursion := &model.Excursion{
		ID:               uuid.New(),
		GuideProfileID:   uuid.New(),
		GuideUserID:      uuid.New(),
		GuideDisplayName: "Aruzhan T.",
		Title:            "Dragon Bridge",
		Summary:          "Private city route",
		Description:      "A detailed city excursion through Da Nang.",
		CategorySlug:     "architecture",
		Status:           enum.ExcursionStatusDraft,
		Visibility:       enum.ExcursionVisibilityPublic,
		DurationMinutes:  120,
		MaxGroupSize:     6,
		MeetingPoint:     "Dragon Bridge",
		PriceAmount:      120,
		Currency:         "USD",
		Revision:         1,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	}

	response := toExcursionResponse(&app.ExcursionAggregate{
		Excursion:            excursion,
		ProductCoverImageURL: &productCoverImageURL,
	})

	if response.CoverFileID != nil {
		t.Fatalf("cover file id = %v, want nil", response.CoverFileID)
	}
	if response.CoverImageURL == nil || *response.CoverImageURL != productCoverImageURL {
		t.Fatalf("cover image url = %v, want %s", response.CoverImageURL, productCoverImageURL)
	}
}

func TestExcursionResponseIncludesTranslationInfoForMachineTranslatedDetails(t *testing.T) {
	excursion := &model.Excursion{
		ID:               uuid.New(),
		GuideProfileID:   uuid.New(),
		GuideUserID:      uuid.New(),
		GuideDisplayName: "Aruzhan T.",
		Title:            "Charyn Canyon",
		Summary:          "Private canyon route",
		Description:      "A detailed canyon excursion.",
		CategorySlug:     "nature",
		Status:           enum.ExcursionStatusDraft,
		Visibility:       enum.ExcursionVisibilityPublic,
		DurationMinutes:  120,
		MaxGroupSize:     6,
		MeetingPoint:     "Charyn entrance",
		PriceAmount:      120,
		Currency:         "KZT",
		Revision:         1,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	}

	response := toExcursionResponse(&app.ExcursionAggregate{
		Excursion: excursion,
		Itinerary: []*model.ExcursionItineraryItem{
			{
				ID:                 uuid.New(),
				ExcursionID:        excursion.ID,
				SortOrder:          0,
				StartOffsetMinutes: 0,
				Title:              "Чарынский каньон",
				Description:        "Русское описание маршрута.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Чарынский каньон", Description: "Русское описание маршрута."},
					"en": {Title: "Charyn Canyon", Description: "English route description."},
				},
				CreatedAt: time.Now().UTC(),
				UpdatedAt: time.Now().UTC(),
			},
		},
	})

	if response.TranslationInfo == nil {
		t.Fatal("translation info is nil, want machine translation metadata")
	}
	if !response.TranslationInfo.Translated {
		t.Fatal("translation info translated = false, want true")
	}
	if response.TranslationInfo.SourceLanguage != "ru" {
		t.Fatalf("source language = %q, want ru", response.TranslationInfo.SourceLanguage)
	}
	if got := response.TranslationInfo.TargetLanguages; len(got) != 1 || got[0] != "en" {
		t.Fatalf("target languages = %#v, want [en]", got)
	}
}

func TestInferItinerarySourceLanguageHandlesNil(t *testing.T) {
	if got := inferItinerarySourceLanguage(nil); got != "" {
		t.Fatalf("source language = %q, want empty for nil itinerary item", got)
	}
}

func TestExcursionResponseTranslationInfoUsesSelectedAppLanguage(t *testing.T) {
	excursionID := uuid.New()
	excursion := &model.Excursion{
		ID:                excursionID,
		SourceLanguage:    "ru",
		TranslationStatus: model.ExcursionTranslationCompleted,
	}
	response := toExcursionResponse(&app.ExcursionAggregate{
		Excursion: excursion,
		Itinerary: []*model.ExcursionItineraryItem{
			{
				ID:          uuid.New(),
				ExcursionID: excursionID,
				Title:       "Старт",
				Description: "Описание маршрута",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Старт", Description: "Описание маршрута"},
					"en": {Title: "Start", Description: "Route description"},
				},
			},
		},
	}, "en")

	if response.TranslationInfo == nil {
		t.Fatal("translation info is nil")
	}
	if response.TranslationInfo.CurrentLanguage != "en" || !response.TranslationInfo.IsTranslated {
		t.Fatalf("translation info = %+v, want translated en state", response.TranslationInfo)
	}
	if response.TranslationInfo.Status != "COMPLETED" {
		t.Fatalf("status = %q, want COMPLETED", response.TranslationInfo.Status)
	}
}

func TestExcursionResponseTranslationInfoIncludesPendingAndFailedLanguages(t *testing.T) {
	excursionID := uuid.New()
	itemID := uuid.New()
	failedMessage := "quota_exhausted"
	response := toExcursionResponse(&app.ExcursionAggregate{
		Excursion: &model.Excursion{
			ID:                excursionID,
			SourceLanguage:    "ru",
			TranslationStatus: model.ExcursionTranslationPartial,
		},
		Itinerary: []*model.ExcursionItineraryItem{
			{
				ID:           itemID,
				ExcursionID:  excursionID,
				Title:        "Старт",
				Description:  "Описание маршрута",
				Translations: model.ExcursionItineraryTranslations{"ru": {Title: "Старт", Description: "Описание маршрута"}},
			},
		},
		TranslationJobs: []model.ExcursionTranslationJob{
			{TargetLanguage: "en", Status: model.ExcursionTranslationJobPending},
			{TargetLanguage: "kk", Status: model.ExcursionTranslationJobFailed, LastError: &failedMessage},
		},
	}, "en")

	if response.TranslationInfo == nil {
		t.Fatal("translation info is nil")
	}
	if got := response.TranslationInfo.PendingLanguages; len(got) != 1 || got[0] != "en" {
		t.Fatalf("pending languages = %#v, want [en]", got)
	}
	if got := response.TranslationInfo.FailedLanguages; len(got) != 1 || got[0] != "kk" {
		t.Fatalf("failed languages = %#v, want [kk]", got)
	}
	if response.TranslationInfo.IsTranslated {
		t.Fatal("pending current language must not be marked translated")
	}
}

func TestRequestedExcursionLanguagePrefersAppLanguageHeader(t *testing.T) {
	request := httptest.NewRequest("GET", "/v1/excursions/example", nil)
	request.Header.Set("Accept-Language", "en-US,en;q=0.9")
	request.Header.Set("X-Language", "kk")

	if got := requestedExcursionLanguage(request); got != "kk" {
		t.Fatalf("requested language = %q, want kk", got)
	}
}

func TestExcursionResponseIncludesTranslationInfoFromProductTranslations(t *testing.T) {
	excursion := &model.Excursion{
		ID:               uuid.New(),
		GuideProfileID:   uuid.New(),
		GuideUserID:      uuid.New(),
		GuideDisplayName: "Aruzhan T.",
		Title:            "Чарынский каньон на рассвете",
		Summary:          "Русский краткий текст.",
		Description:      "Русское исходное описание.",
		ProductTranslations: model.ExcursionTranslations{
			"ru": {
				Title:       "Чарынский каньон на рассвете",
				Summary:     "Русский краткий текст.",
				Description: "Русское исходное описание.",
			},
			"en": {
				Title:       "Charyn Canyon sunrise",
				Summary:     "English summary.",
				Description: "English translated detail text.",
			},
			"kk": {
				Title:       "Шарын шатқалы таң ата",
				Summary:     "Қазақша қысқа мәтін.",
				Description: "Қазақша аударылған сипаттама.",
			},
		},
		CategorySlug:    "nature",
		Status:          enum.ExcursionStatusDraft,
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 120,
		MaxGroupSize:    6,
		MeetingPoint:    "Charyn entrance",
		PriceAmount:     120,
		Currency:        "KZT",
		Revision:        1,
		CreatedAt:       time.Now().UTC(),
		UpdatedAt:       time.Now().UTC(),
	}

	response := toExcursionResponse(&app.ExcursionAggregate{
		Excursion: excursion,
	})

	if response.TranslationInfo == nil {
		t.Fatal("translation info is nil, want product translation metadata")
	}
	if response.TranslationInfo.SourceLanguage != "ru" {
		t.Fatalf("source language = %q, want ru", response.TranslationInfo.SourceLanguage)
	}
	got := response.TranslationInfo.TargetLanguages
	if len(got) != 2 || got[0] != "en" || got[1] != "kk" {
		t.Fatalf("target languages = %#v, want [en kk]", got)
	}
}

func TestExcursionResponseIncludesOrderedGalleryPhotos(t *testing.T) {
	coverFileID := uuid.New()
	secondFileID := uuid.New()
	externalImageURL := "https://upload.wikimedia.org/dragon-bridge.jpg"
	excursion := &model.Excursion{
		ID:               uuid.New(),
		GuideProfileID:   uuid.New(),
		GuideUserID:      uuid.New(),
		GuideDisplayName: "Aruzhan T.",
		Title:            "Dragon Bridge",
		Summary:          "Private city route",
		Description:      "A detailed city excursion through Da Nang.",
		CategorySlug:     "architecture",
		Status:           enum.ExcursionStatusDraft,
		Visibility:       enum.ExcursionVisibilityPublic,
		DurationMinutes:  120,
		MaxGroupSize:     6,
		MeetingPoint:     "Dragon Bridge",
		PriceAmount:      120,
		Currency:         "USD",
		Revision:         1,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	}

	response := toExcursionResponse(&app.ExcursionAggregate{
		Excursion:      excursion,
		PhotoFileIDs:   []uuid.UUID{coverFileID, secondFileID},
		PhotoImageURLs: []string{externalImageURL},
	})

	if len(response.PhotoFileIDs) != 2 ||
		response.PhotoFileIDs[0] != coverFileID.String() ||
		response.PhotoFileIDs[1] != secondFileID.String() {
		t.Fatalf("photo file ids = %#v, want ordered file ids", response.PhotoFileIDs)
	}
	if len(response.PhotoImageURLs) != 1 || response.PhotoImageURLs[0] != externalImageURL {
		t.Fatalf("photo image urls = %#v, want ordered external urls", response.PhotoImageURLs)
	}
}

func TestExcursionReviewResponseIncludesAuthorProjection(t *testing.T) {
	authorUserID := uuid.New()
	avatarFileID := uuid.New()
	nickname := "@nomad_aru"
	review := &model.ExcursionReview{
		ID:             uuid.New(),
		BookingID:      uuid.New(),
		ProductID:      uuid.New(),
		OfferID:        uuid.New(),
		GuideProfileID: uuid.New(),
		GuideUserID:    uuid.New(),
		TouristUserID:  authorUserID,
		Author: model.ExcursionReviewAuthor{
			UserID:       authorUserID,
			Nickname:     &nickname,
			AvatarFileID: &avatarFileID,
		},
		Rating:    5,
		Comment:   "Best mountain route",
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}

	response := toExcursionReviewResponse(review, "")

	if response == nil {
		t.Fatal("response is nil")
	}
	if response.Author.UserID != authorUserID.String() {
		t.Fatalf("author user id = %q, want %s", response.Author.UserID, authorUserID)
	}
	if response.Author.Nickname == nil || *response.Author.Nickname != nickname {
		t.Fatalf("author nickname = %v, want %s", response.Author.Nickname, nickname)
	}
	if response.Author.AvatarFileID == nil || *response.Author.AvatarFileID != avatarFileID.String() {
		t.Fatalf("author avatar file id = %v, want %s", response.Author.AvatarFileID, avatarFileID)
	}
}

func TestParseExcursionProductFilterAcceptsLandmarkID(t *testing.T) {
	landmarkID := uuid.New()
	req := httptest.NewRequest(
		"GET",
		"/v1/excursion-products?limit=1&landmarkId="+landmarkID.String(),
		nil,
	)

	filter := parseExcursionProductFilter(req, 2)

	if filter.LandmarkID == nil || *filter.LandmarkID != landmarkID {
		t.Fatalf("landmark id = %v, want %s", filter.LandmarkID, landmarkID)
	}
}

func TestToAppItineraryMapsPlaceRouteFields(t *testing.T) {
	placeID := uuid.New()
	lat := 43.238949
	lng := 76.889709
	travel := 12

	input := []dto.ExcursionItineraryItemRequest{
		{
			PlaceID:                   ptrString(placeID.String()),
			PlaceName:                 ptrString("Medeu"),
			Latitude:                  &lat,
			Longitude:                 &lng,
			TravelFromPreviousMinutes: &travel,
			StartOffsetMinutes:        60,
			Title:                     "Medeu",
			Description:               "Explore Medeu with a guide.",
		},
	}

	got, err := toAppItinerary(input)
	if err != nil {
		t.Fatalf("toAppItinerary() error = %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("items = %d, want 1", len(got))
	}
	if got[0].PlaceID == nil || *got[0].PlaceID != placeID {
		t.Fatalf("PlaceID = %v, want %s", got[0].PlaceID, placeID)
	}
	if got[0].PlaceName == nil || *got[0].PlaceName != "Medeu" {
		t.Fatalf("PlaceName = %v, want Medeu", got[0].PlaceName)
	}
	if got[0].TravelFromPreviousMinutes == nil || *got[0].TravelFromPreviousMinutes != travel {
		t.Fatalf("TravelFromPreviousMinutes = %v, want %d", got[0].TravelFromPreviousMinutes, travel)
	}
}

func TestToAppItineraryRejectsInvalidPlaceID(t *testing.T) {
	_, err := toAppItinerary([]dto.ExcursionItineraryItemRequest{
		{
			PlaceID:            ptrString("not-a-uuid"),
			StartOffsetMinutes: 0,
			Title:              "Medeu",
			Description:        "Explore Medeu with a guide.",
		},
	})

	if err == nil {
		t.Fatal("toAppItinerary() error = nil, want invalid place id error")
	}
}

func TestToItineraryResponseMapsPlaceRouteFields(t *testing.T) {
	placeID := uuid.New()
	placeName := "Medeu"
	lat := 43.238949
	lng := 76.889709
	travel := 12

	response := toItineraryResponse([]*model.ExcursionItineraryItem{
		{
			ID:                        uuid.New(),
			PlaceID:                   &placeID,
			PlaceName:                 &placeName,
			Latitude:                  &lat,
			Longitude:                 &lng,
			TravelFromPreviousMinutes: &travel,
			Title:                     "Medeu",
			Description:               "Explore Medeu with a guide.",
			CreatedAt:                 time.Now().UTC(),
			UpdatedAt:                 time.Now().UTC(),
		},
	})

	if len(response) != 1 {
		t.Fatalf("items = %d, want 1", len(response))
	}
	if response[0].PlaceID == nil || *response[0].PlaceID != placeID.String() {
		t.Fatalf("PlaceID = %v, want %s", response[0].PlaceID, placeID)
	}
	if response[0].PlaceName == nil || *response[0].PlaceName != placeName {
		t.Fatalf("PlaceName = %v, want %s", response[0].PlaceName, placeName)
	}
	if response[0].Latitude == nil || *response[0].Latitude != lat {
		t.Fatalf("Latitude = %v, want %f", response[0].Latitude, lat)
	}
	if response[0].Longitude == nil || *response[0].Longitude != lng {
		t.Fatalf("Longitude = %v, want %f", response[0].Longitude, lng)
	}
	if response[0].TravelFromPreviousMinutes == nil || *response[0].TravelFromPreviousMinutes != travel {
		t.Fatalf("TravelFromPreviousMinutes = %v, want %d", response[0].TravelFromPreviousMinutes, travel)
	}
}

func TestExcursionProductCardResponseMapsRouteMetadata(t *testing.T) {
	a := uuid.New()
	b := uuid.New()
	fingerprint := "route:kz:almaty:culture:2-4h:walking:" + a.String() + "," + b.String()
	theme := "culture"
	bucket := "2-4h"
	ratingAvg := 4.75
	reviewsCount := 12

	response := toExcursionProductCardResponse(&app.ExcursionProductCardAggregate{
		Product: &model.ExcursionProductCard{
			ID:               uuid.New(),
			RouteKind:        model.ExcursionRouteKindCombinedRoute,
			RouteFingerprint: &fingerprint,
			PlaceIDs:         []uuid.UUID{a, b},
			PlaceNames:       []string{"Kok-Tobe", "Cathedral"},
			StopCount:        2,
			TransportMode:    "WALKING",
			RouteTheme:       &theme,
			DurationBucket:   &bucket,
			RatingAvg:        ratingAvg,
			ReviewsCount:     reviewsCount,
			Title:            "Kok-Tobe + Cathedral",
			Status:           enum.ExcursionStatusPublished,
			Visibility:       enum.ExcursionVisibilityPublic,
			CreatedAt:        time.Now().UTC(),
			UpdatedAt:        time.Now().UTC(),
		},
	})

	if response.RouteKind != string(model.ExcursionRouteKindCombinedRoute) {
		t.Fatalf("RouteKind = %q, want COMBINED_ROUTE", response.RouteKind)
	}
	if response.RouteFingerprint == nil || *response.RouteFingerprint != fingerprint {
		t.Fatalf("RouteFingerprint = %v, want %s", response.RouteFingerprint, fingerprint)
	}
	if len(response.PlaceIDs) != 2 || response.PlaceIDs[0] != a.String() || response.PlaceIDs[1] != b.String() {
		t.Fatalf("PlaceIDs = %#v, want [%s %s]", response.PlaceIDs, a, b)
	}
	if len(response.PlaceNames) != 2 || response.PlaceNames[0] != "Kok-Tobe" || response.PlaceNames[1] != "Cathedral" {
		t.Fatalf("PlaceNames = %#v, want route names", response.PlaceNames)
	}
	if response.StopCount != 2 {
		t.Fatalf("StopCount = %d, want 2", response.StopCount)
	}
	if response.TransportMode != "WALKING" {
		t.Fatalf("TransportMode = %q, want WALKING", response.TransportMode)
	}
	if response.RouteTheme == nil || *response.RouteTheme != theme {
		t.Fatalf("RouteTheme = %v, want %s", response.RouteTheme, theme)
	}
	if response.DurationBucket == nil || *response.DurationBucket != bucket {
		t.Fatalf("DurationBucket = %v, want %s", response.DurationBucket, bucket)
	}
	if response.RatingAvg != ratingAvg {
		t.Fatalf("RatingAvg = %v, want %v", response.RatingAvg, ratingAvg)
	}
	if response.ReviewsCount != reviewsCount {
		t.Fatalf("ReviewsCount = %d, want %d", response.ReviewsCount, reviewsCount)
	}
}

func TestExcursionProductCardResponseIncludesTranslationInfo(t *testing.T) {
	response := toExcursionProductCardResponse(&app.ExcursionProductCardAggregate{
		Product: &model.ExcursionProductCard{
			ID:          uuid.New(),
			RouteKind:   model.ExcursionRouteKindSinglePlace,
			Title:       "Чарынский каньон",
			Summary:     "Русский краткий текст.",
			Description: "Русское исходное описание.",
			Translations: model.ExcursionTranslations{
				"ru": {
					Title:       "Чарынский каньон",
					Summary:     "Русский краткий текст.",
					Description: "Русское исходное описание.",
				},
				"en": {
					Title:       "Charyn Canyon",
					Summary:     "English summary.",
					Description: "English translated detail text.",
				},
			},
			Status:     enum.ExcursionStatusPublished,
			Visibility: enum.ExcursionVisibilityPublic,
			CreatedAt:  time.Now().UTC(),
			UpdatedAt:  time.Now().UTC(),
		},
	})

	if response.TranslationInfo == nil {
		t.Fatal("translation info is nil, want product card translation metadata")
	}
	if response.TranslationInfo.SourceLanguage != "ru" {
		t.Fatalf("source language = %q, want ru", response.TranslationInfo.SourceLanguage)
	}
	if got := response.TranslationInfo.TargetLanguages; len(got) != 1 || got[0] != "en" {
		t.Fatalf("target languages = %#v, want [en]", got)
	}
}

func ptrString(value string) *string {
	return &value
}
