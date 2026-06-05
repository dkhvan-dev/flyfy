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

func TestToAppItineraryMapsAttractionRouteFields(t *testing.T) {
	attractionID := uuid.New()
	lat := 43.238949
	lng := 76.889709
	travel := 12

	input := []dto.ExcursionItineraryItemRequest{
		{
			AttractionID:              ptrString(attractionID.String()),
			AttractionName:            ptrString("Medeu"),
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
	if got[0].AttractionID == nil || *got[0].AttractionID != attractionID {
		t.Fatalf("AttractionID = %v, want %s", got[0].AttractionID, attractionID)
	}
	if got[0].AttractionName == nil || *got[0].AttractionName != "Medeu" {
		t.Fatalf("AttractionName = %v, want Medeu", got[0].AttractionName)
	}
	if got[0].TravelFromPreviousMinutes == nil || *got[0].TravelFromPreviousMinutes != travel {
		t.Fatalf("TravelFromPreviousMinutes = %v, want %d", got[0].TravelFromPreviousMinutes, travel)
	}
}

func TestToAppItineraryRejectsInvalidAttractionID(t *testing.T) {
	_, err := toAppItinerary([]dto.ExcursionItineraryItemRequest{
		{
			AttractionID:       ptrString("not-a-uuid"),
			StartOffsetMinutes: 0,
			Title:              "Medeu",
			Description:        "Explore Medeu with a guide.",
		},
	})

	if err == nil {
		t.Fatal("toAppItinerary() error = nil, want invalid attraction id error")
	}
}

func TestToItineraryResponseMapsAttractionRouteFields(t *testing.T) {
	attractionID := uuid.New()
	attractionName := "Medeu"
	lat := 43.238949
	lng := 76.889709
	travel := 12

	response := toItineraryResponse([]*model.ExcursionItineraryItem{
		{
			ID:                        uuid.New(),
			AttractionID:              &attractionID,
			AttractionName:            &attractionName,
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
	if response[0].AttractionID == nil || *response[0].AttractionID != attractionID.String() {
		t.Fatalf("AttractionID = %v, want %s", response[0].AttractionID, attractionID)
	}
	if response[0].AttractionName == nil || *response[0].AttractionName != attractionName {
		t.Fatalf("AttractionName = %v, want %s", response[0].AttractionName, attractionName)
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

	response := toExcursionProductCardResponse(&app.ExcursionProductCardAggregate{
		Product: &model.ExcursionProductCard{
			ID:               uuid.New(),
			RouteKind:        model.ExcursionRouteKindCombinedRoute,
			RouteFingerprint: &fingerprint,
			AttractionIDs:    []uuid.UUID{a, b},
			AttractionNames:  []string{"Kok-Tobe", "Cathedral"},
			StopCount:        2,
			TransportMode:    "WALKING",
			RouteTheme:       &theme,
			DurationBucket:   &bucket,
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
	if len(response.AttractionIDs) != 2 || response.AttractionIDs[0] != a.String() || response.AttractionIDs[1] != b.String() {
		t.Fatalf("AttractionIDs = %#v, want [%s %s]", response.AttractionIDs, a, b)
	}
	if len(response.AttractionNames) != 2 || response.AttractionNames[0] != "Kok-Tobe" || response.AttractionNames[1] != "Cathedral" {
		t.Fatalf("AttractionNames = %#v, want route names", response.AttractionNames)
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
}

func ptrString(value string) *string {
	return &value
}
