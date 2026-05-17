package http

import (
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
