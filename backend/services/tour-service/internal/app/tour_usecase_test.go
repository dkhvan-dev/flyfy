package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
)

type tourRepoStub struct {
	createdTour       *model.Tour
	createdRelations  port.TourRelations
	gotTour           *model.Tour
	savedTour         *model.Tour
	savedRelations    port.TourRelations
	loadedRelations   port.TourRelations
	createAggregateFn func(ctx context.Context, item *model.Tour, relations port.TourRelations) error
}

func (s *tourRepoStub) CreateTourAggregate(ctx context.Context, item *model.Tour, relations port.TourRelations) error {
	s.createdTour = item
	s.createdRelations = relations
	if s.createAggregateFn != nil {
		return s.createAggregateFn(ctx, item, relations)
	}
	return nil
}

func (s *tourRepoStub) UpdateTourAggregate(ctx context.Context, item *model.Tour, relations port.TourRelations) error {
	s.savedTour = item
	s.savedRelations = relations
	return nil
}

func (s *tourRepoStub) UpdateTour(ctx context.Context, item *model.Tour) error {
	s.savedTour = item
	return nil
}

func (s *tourRepoStub) GetTourByID(ctx context.Context, tourID uuid.UUID) (*model.Tour, error) {
	return s.gotTour, nil
}

func (s *tourRepoStub) ListTours(ctx context.Context, filter port.TourFilter) ([]*model.Tour, error) {
	return nil, nil
}

func (s *tourRepoStub) LoadTourRelations(ctx context.Context, tourID uuid.UUID) (port.TourRelations, error) {
	return s.loadedRelations, nil
}

func (s *tourRepoStub) CreateTourEvent(ctx context.Context, item *model.TourEvent) error {
	return nil
}

type guideVerifierStub struct {
	result port.GuideTourPermission
	err    error
}

func (s guideVerifierStub) VerifyTourGuide(ctx context.Context, userID uuid.UUID) (port.GuideTourPermission, error) {
	return s.result, s.err
}

type fileManagerStub struct {
	validated *uuid.UUID
	bound     *uuid.UUID
}

func (s *fileManagerStub) ValidateTourCoverFile(ctx context.Context, fileID uuid.UUID) error {
	s.validated = &fileID
	return nil
}

func (s *fileManagerStub) BindTourCoverFile(ctx context.Context, fileID uuid.UUID, tourID uuid.UUID, createdByUserID uuid.UUID) error {
	s.bound = &fileID
	return nil
}

func (s *fileManagerStub) CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error) {
	return "https://cdn.example.test/tour-cover.jpg", nil
}

func TestCreateTourRequiresActiveTourGuide(t *testing.T) {
	repo := &tourRepoStub{}
	uc := NewTourUseCase(repo, guideVerifierStub{err: ErrGuideNotAllowed}, nil)

	_, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []TourItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrGuideNotAllowed) {
		t.Fatalf("error = %v, want %v", err, ErrGuideNotAllowed)
	}
	if repo.createdTour != nil {
		t.Fatal("tour was persisted for a non-authorized guide")
	}
}

func TestCreateTourPersistsDraftAggregate(t *testing.T) {
	coverFileID := uuid.New()
	repo := &tourRepoStub{}
	files := &fileManagerStub{}
	guideProfileID := uuid.New()
	actorUserID := uuid.New()
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID: guideProfileID,
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, files)

	aggregate, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     actorUserID,
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Tags:            []string{"mountains", "private"},
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"EN", "ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "usd",
		CoverFileID:     &coverFileID,
		IncludedItems:   []string{"Private SUV", "Gourmet picnic"},
		Itinerary: []TourItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if err != nil {
		t.Fatalf("CreateTour() error = %v", err)
	}
	if aggregate.Tour.GuideProfileID != guideProfileID {
		t.Fatalf("guide profile id = %s, want %s", aggregate.Tour.GuideProfileID, guideProfileID)
	}
	if repo.createdTour == nil {
		t.Fatal("tour was not persisted")
	}
	if len(repo.createdRelations.LanguageCodes) != 2 || repo.createdRelations.LanguageCodes[0] != "en" {
		t.Fatalf("language codes = %#v, want normalized codes", repo.createdRelations.LanguageCodes)
	}
	if files.validated == nil || *files.validated != coverFileID {
		t.Fatal("cover file was not validated")
	}
	if files.bound == nil || *files.bound != coverFileID {
		t.Fatal("cover file was not bound to the tour")
	}
}

func TestUpdateTourRejectsNonOwner(t *testing.T) {
	ownerID := uuid.New()
	tour, err := model.NewTour(model.NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewTour() error = %v", err)
	}

	repo := &tourRepoStub{gotTour: tour}
	uc := NewTourUseCase(repo, guideVerifierStub{}, nil)

	_, err = uc.UpdateTour(context.Background(), UpdateTourInput{
		ActorUserID:     uuid.New(),
		TourID:          tour.ID,
		Title:           "Updated",
		Summary:         "Updated summary",
		Description:     "Updated guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []TourItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrTourAccessDenied) {
		t.Fatalf("error = %v, want %v", err, ErrTourAccessDenied)
	}
	if repo.savedTour != nil {
		t.Fatal("tour was updated by a non-owner")
	}
}

func TestUpdatePublishedTourKeepsOriginalPublicationTime(t *testing.T) {
	ownerID := uuid.New()
	publishedAt := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
	tour, err := model.NewTour(model.NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
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
	tour.Status = enum.TourStatusPublished
	tour.PublishedAt = &publishedAt

	repo := &tourRepoStub{gotTour: tour}
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID: tour.GuideProfileID,
			GuideUserID:    ownerID,
			Allowed:        true,
		},
	}, nil)

	_, err = uc.UpdateTour(context.Background(), UpdateTourInput{
		ActorUserID:     ownerID,
		TourID:          tour.ID,
		Title:           "Almaty Mountain Escape Updated",
		Summary:         "Updated private mountain route",
		Description:     "An updated guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      string(enum.TourVisibilityPublic),
		DurationMinutes: 260,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en", "ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     140,
		Currency:        "USD",
		Itinerary: []TourItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})
	if err != nil {
		t.Fatalf("UpdateTour() error = %v", err)
	}
	if repo.savedTour == nil {
		t.Fatal("tour was not saved")
	}
	if repo.savedTour.Status != enum.TourStatusPublished {
		t.Fatalf("status = %s, want %s", repo.savedTour.Status, enum.TourStatusPublished)
	}
	if repo.savedTour.PublishedAt == nil || !repo.savedTour.PublishedAt.Equal(publishedAt) {
		t.Fatalf("publishedAt = %v, want %v", repo.savedTour.PublishedAt, publishedAt)
	}
}

func stringPtr(v string) *string {
	return &v
}
