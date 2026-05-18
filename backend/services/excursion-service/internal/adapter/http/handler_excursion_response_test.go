package http

import (
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
)

func TestExcursionResponseUsesProductCoverWhenOfferCoverIsMissing(t *testing.T) {
	productCoverFileID := uuid.New()
	excursion := &model.Excursion{
		ID:              uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Medeu tour",
		Summary:         "Private mountain route",
		Description:     "A detailed mountain excursion through Medeu.",
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
}

func TestExcursionReviewResponseIncludesAuthorProjection(t *testing.T) {
	authorUserID := uuid.New()
	avatarFileID := uuid.New()
	displayName := "@nomad_aru"
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
			DisplayName:  &displayName,
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
	if response.Author.DisplayName == nil || *response.Author.DisplayName != displayName {
		t.Fatalf("author display name = %v, want %s", response.Author.DisplayName, displayName)
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
