package model

import (
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
)

func TestNewTourRequiresValidGuideAndCoreFields(t *testing.T) {
	_, err := NewTour(NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.Nil,
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.TourVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})

	if err != ErrInvalidGuideUserID {
		t.Fatalf("error = %v, want %v", err, ErrInvalidGuideUserID)
	}
}

func TestTourPublishRequiresBookableDetails(t *testing.T) {
	tour, err := NewTour(NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.TourVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewTour() error = %v", err)
	}

	err = tour.Publish(PublishTourParams{
		LanguageCodes: []string{"en"},
		Itinerary: []*TourItineraryItem{
			{
				ID:                 uuid.New(),
				TourID:             tour.ID,
				SortOrder:          0,
				StartOffsetMinutes: 0,
				Title:              "Hotel departure",
				Description:        "Meet your guide and start the route.",
			},
		},
	})

	if err != nil {
		t.Fatalf("Publish() error = %v", err)
	}
	if tour.Status != enum.TourStatusPublished {
		t.Fatalf("status = %q, want %q", tour.Status, enum.TourStatusPublished)
	}
	if tour.PublishedAt == nil {
		t.Fatal("PublishedAt is nil")
	}
}

func TestTourPublishRejectsMissingItinerary(t *testing.T) {
	tour, err := NewTour(NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.TourVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewTour() error = %v", err)
	}

	err = tour.Publish(PublishTourParams{LanguageCodes: []string{"en"}})

	if err != ErrTourItineraryRequired {
		t.Fatalf("error = %v, want %v", err, ErrTourItineraryRequired)
	}
}
