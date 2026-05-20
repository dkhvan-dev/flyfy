package model

import (
	"errors"
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

func TestExcursionMoveToArchiveKeepsOfferRestorable(t *testing.T) {
	excursion := newValidExcursion(t)

	if err := excursion.MoveToArchive(); err != nil {
		t.Fatalf("MoveToArchive() error = %v", err)
	}

	if excursion.Status != enum.ExcursionStatusArchived {
		t.Fatalf("status = %q, want %q", excursion.Status, enum.ExcursionStatusArchived)
	}
	if excursion.DeletedAt != nil {
		t.Fatalf("DeletedAt = %v, want nil", excursion.DeletedAt)
	}

	err := excursion.Publish(validPublishParams(excursion.ID))
	if err != nil {
		t.Fatalf("Publish() from restorable archive error = %v", err)
	}
	if excursion.Status != enum.ExcursionStatusPublished {
		t.Fatalf("status after publish = %q, want %q", excursion.Status, enum.ExcursionStatusPublished)
	}
	if excursion.PublishedAt == nil {
		t.Fatal("PublishedAt is nil after publish from archive")
	}
}

func TestNewExcursionItineraryItemAcceptsAttractionSnapshot(t *testing.T) {
	attractionID := uuid.New()
	lat := 43.238949
	lng := 76.889709
	travel := 12

	item, err := NewExcursionItineraryItem(NewExcursionItineraryItemParams{
		ExcursionID:               uuid.New(),
		SortOrder:                 1,
		StartOffsetMinutes:        60,
		DurationMinutes:           intPtr(45),
		AttractionID:              &attractionID,
		AttractionName:            stringPtr("  Medeu  "),
		Latitude:                  &lat,
		Longitude:                 &lng,
		TravelFromPreviousMinutes: &travel,
		Title:                     "Medeu stop",
		Description:               "We explore Medeu with the guide.",
	})

	if err != nil {
		t.Fatalf("NewExcursionItineraryItem() error = %v", err)
	}
	if item.AttractionID == nil || *item.AttractionID != attractionID {
		t.Fatalf("AttractionID = %v, want %s", item.AttractionID, attractionID)
	}
	if item.AttractionName == nil || *item.AttractionName != "Medeu" {
		t.Fatalf("AttractionName = %v, want Medeu", item.AttractionName)
	}
	if item.Latitude == nil || *item.Latitude != lat {
		t.Fatalf("Latitude = %v, want %f", item.Latitude, lat)
	}
	if item.Longitude == nil || *item.Longitude != lng {
		t.Fatalf("Longitude = %v, want %f", item.Longitude, lng)
	}
	if item.TravelFromPreviousMinutes == nil || *item.TravelFromPreviousMinutes != travel {
		t.Fatalf("TravelFromPreviousMinutes = %v, want %d", item.TravelFromPreviousMinutes, travel)
	}
}

func TestNewExcursionItineraryItemCopiesAttractionSnapshotPointers(t *testing.T) {
	attractionID := uuid.New()
	originalAttractionID := attractionID
	lat := 43.238949
	lng := 76.889709
	duration := 45
	travel := 12

	item, err := NewExcursionItineraryItem(NewExcursionItineraryItemParams{
		ExcursionID:               uuid.New(),
		SortOrder:                 1,
		StartOffsetMinutes:        60,
		DurationMinutes:           &duration,
		AttractionID:              &attractionID,
		Latitude:                  &lat,
		Longitude:                 &lng,
		TravelFromPreviousMinutes: &travel,
		Title:                     "Medeu stop",
		Description:               "We explore Medeu with the guide.",
	})
	if err != nil {
		t.Fatalf("NewExcursionItineraryItem() error = %v", err)
	}

	attractionID = uuid.New()
	lat = 1
	lng = 2
	duration = -1
	travel = -1

	if item.AttractionID == nil || *item.AttractionID != originalAttractionID {
		t.Fatalf("AttractionID = %v, want %s", item.AttractionID, originalAttractionID)
	}
	if item.DurationMinutes == nil || *item.DurationMinutes != 45 {
		t.Fatalf("DurationMinutes = %v, want %d", item.DurationMinutes, 45)
	}
	if item.Latitude == nil || *item.Latitude != 43.238949 {
		t.Fatalf("Latitude = %v, want %f", item.Latitude, 43.238949)
	}
	if item.Longitude == nil || *item.Longitude != 76.889709 {
		t.Fatalf("Longitude = %v, want %f", item.Longitude, 76.889709)
	}
	if item.TravelFromPreviousMinutes == nil || *item.TravelFromPreviousMinutes != 12 {
		t.Fatalf("TravelFromPreviousMinutes = %v, want %d", item.TravelFromPreviousMinutes, 12)
	}
}

func TestNewExcursionItineraryItemNormalizesNilAttractionID(t *testing.T) {
	attractionID := uuid.Nil

	item, err := NewExcursionItineraryItem(NewExcursionItineraryItemParams{
		ExcursionID:  uuid.New(),
		SortOrder:    1,
		AttractionID: &attractionID,
		Title:        "Stop",
		Description:  "A valid stop description.",
	})
	if err != nil {
		t.Fatalf("NewExcursionItineraryItem() error = %v", err)
	}
	if item.AttractionID != nil {
		t.Fatalf("AttractionID = %v, want nil", item.AttractionID)
	}
}

func TestNewExcursionItineraryItemRejectsNegativeTravelTime(t *testing.T) {
	travel := -1
	_, err := NewExcursionItineraryItem(NewExcursionItineraryItemParams{
		ExcursionID:               uuid.New(),
		SortOrder:                 1,
		StartOffsetMinutes:        60,
		TravelFromPreviousMinutes: &travel,
		Title:                     "Stop",
		Description:               "A valid stop description.",
	})

	if !errors.Is(err, ErrInvalidExcursionItineraryTravelTime) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidExcursionItineraryTravelTime)
	}
}

func TestNewExcursionItineraryItemNormalizesBlankAttractionName(t *testing.T) {
	item, err := NewExcursionItineraryItem(NewExcursionItineraryItemParams{
		ExcursionID:    uuid.New(),
		SortOrder:      1,
		Title:          "Stop",
		Description:    "A valid stop description.",
		AttractionName: stringPtr("   "),
	})
	if err != nil {
		t.Fatalf("NewExcursionItineraryItem() error = %v", err)
	}
	if item.AttractionName != nil {
		t.Fatalf("AttractionName = %q, want nil", *item.AttractionName)
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

func intPtr(value int) *int {
	return &value
}

func stringPtr(value string) *string {
	return &value
}
