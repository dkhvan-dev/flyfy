package model

import (
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
)

func TestNewExcursionRequiresValidGuideAndCoreFields(t *testing.T) {
	_, err := NewExcursion(NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.Nil,
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
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

func TestExcursionPublishRequiresBookableDetails(t *testing.T) {
	excursion, err := NewExcursion(NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}

	err = excursion.Publish(PublishExcursionParams{
		LanguageCodes: []string{"en"},
		Itinerary: []*ExcursionItineraryItem{
			{
				ID:                 uuid.New(),
				ExcursionID:        excursion.ID,
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
	if excursion.Status != enum.ExcursionStatusPublished {
		t.Fatalf("status = %q, want %q", excursion.Status, enum.ExcursionStatusPublished)
	}
	if excursion.PublishedAt == nil {
		t.Fatal("PublishedAt is nil")
	}
}

func TestExcursionPublishRejectsMissingItinerary(t *testing.T) {
	excursion, err := NewExcursion(NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}

	err = excursion.Publish(PublishExcursionParams{LanguageCodes: []string{"en"}})

	if err != ErrExcursionItineraryRequired {
		t.Fatalf("error = %v, want %v", err, ErrExcursionItineraryRequired)
	}
}

func TestExcursionPublishIsIdempotentForAlreadyPublishedExcursion(t *testing.T) {
	excursion := newValidExcursion(t)

	err := excursion.Publish(validPublishParams(excursion.ID))
	if err != nil {
		t.Fatalf("Publish() error = %v", err)
	}
	publishedAt := *excursion.PublishedAt
	revision := excursion.Revision

	err = excursion.Publish(validPublishParams(excursion.ID))
	if err != nil {
		t.Fatalf("second Publish() error = %v", err)
	}
	if excursion.PublishedAt == nil || !excursion.PublishedAt.Equal(publishedAt) {
		t.Fatalf("PublishedAt = %v, want %v", excursion.PublishedAt, publishedAt)
	}
	if excursion.Revision != revision {
		t.Fatalf("revision = %d, want %d", excursion.Revision, revision)
	}
}

func TestExcursionPublishRejectsArchivedExcursion(t *testing.T) {
	excursion := newValidExcursion(t)
	if err := excursion.Archive(); err != nil {
		t.Fatalf("Archive() error = %v", err)
	}

	err := excursion.Publish(validPublishParams(excursion.ID))

	if err != ErrExcursionAlreadyArchived {
		t.Fatalf("error = %v, want %v", err, ErrExcursionAlreadyArchived)
	}
	if excursion.Status != enum.ExcursionStatusArchived {
		t.Fatalf("status = %q, want %q", excursion.Status, enum.ExcursionStatusArchived)
	}
	if excursion.DeletedAt == nil {
		t.Fatal("DeletedAt is nil")
	}
}

func newValidExcursion(t *testing.T) *Excursion {
	t.Helper()
	excursion, err := NewExcursion(NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}
	return excursion
}

func validPublishParams(excursionID uuid.UUID) PublishExcursionParams {
	return PublishExcursionParams{
		LanguageCodes: []string{"en"},
		Itinerary: []*ExcursionItineraryItem{
			{
				ID:                 uuid.New(),
				ExcursionID:        excursionID,
				SortOrder:          0,
				StartOffsetMinutes: 0,
				Title:              "Hotel departure",
				Description:        "Meet your guide and start the route.",
			},
		},
	}
}
