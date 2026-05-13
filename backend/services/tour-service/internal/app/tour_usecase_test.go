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
	gotOffer          *model.TourOffer
	savedTour         *model.Tour
	savedRelations    port.TourRelations
	createdBooking    *model.TourBooking
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

func (s *tourRepoStub) ListTourProductCards(ctx context.Context, filter port.TourProductFilter) ([]*model.TourProductCard, error) {
	return nil, nil
}

func (s *tourRepoStub) GetTourProductCardByID(ctx context.Context, productID uuid.UUID) (*model.TourProductCard, error) {
	return nil, nil
}

func (s *tourRepoStub) ListTourOffers(ctx context.Context, filter port.TourOfferFilter) ([]*model.TourOffer, error) {
	return nil, nil
}

func (s *tourRepoStub) GetTourOfferByID(ctx context.Context, offerID uuid.UUID) (*model.TourOffer, error) {
	return s.gotOffer, nil
}

func (s *tourRepoStub) LoadTourOfferRelations(ctx context.Context, offerID uuid.UUID) (port.TourOfferRelations, error) {
	return port.TourOfferRelations{}, nil
}

func (s *tourRepoStub) CreateTourBooking(ctx context.Context, item *model.TourBooking) error {
	s.createdBooking = item
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

type translatorStub struct {
	result port.TranslationResult
	err    error
	calls  []port.TranslationRequest
}

func (s *translatorStub) TranslateTexts(ctx context.Context, input port.TranslationRequest) (port.TranslationResult, error) {
	s.calls = append(s.calls, input)
	return s.result, s.err
}

func TestCreateTourRequiresActiveTourGuide(t *testing.T) {
	repo := &tourRepoStub{}
	uc := NewTourUseCase(repo, guideVerifierStub{err: ErrGuideNotAllowed}, nil)

	_, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     uuid.New(),
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

func TestCreateTourRequiresAttraction(t *testing.T) {
	repo := &tourRepoStub{}
	actorUserID := uuid.New()
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     actorUserID,
		LandmarkName:    stringPtr("Custom place"),
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

	if !errors.Is(err, ErrTourAttractionRequired) {
		t.Fatalf("error = %v, want %v", err, ErrTourAttractionRequired)
	}
	if repo.createdTour != nil {
		t.Fatal("tour was persisted without an attraction")
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
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"EN", "ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "usd",
		CoverFileID:     &coverFileID,
		IncludedItems: []TourIncludedItemInput{
			{Text: "transport"},
			{Text: "food"},
		},
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
	if len(repo.createdRelations.IncludedItems) != 2 ||
		repo.createdRelations.IncludedItems[0].Text != "food" ||
		repo.createdRelations.IncludedItems[1].Text != "transport" {
		t.Fatalf("included items = %#v, want stable dictionary keys", repo.createdRelations.IncludedItems)
	}
}

func TestCreateTourTranslatesItineraryBeforePersisting(t *testing.T) {
	repo := &tourRepoStub{}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Hotel departure", "Meet your guide and start the route."},
				"kk": {"Қонақүйден шығу", "Гидпен кездесіп, маршрутты бастаңыз."},
			},
		},
	}
	actorUserID := uuid.New()
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []TourItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.TourItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("CreateTour() error = %v", err)
	}
	if len(translator.calls) != 1 {
		t.Fatalf("translator calls = %d, want 1", len(translator.calls))
	}
	if translator.calls[0].SourceLocale != "ru" {
		t.Fatalf("source locale = %q, want ru", translator.calls[0].SourceLocale)
	}
	got := repo.createdRelations.Itinerary[0].Translations
	if got["ru"].Title != "Выезд из отеля" || got["ru"].Description == "" {
		t.Fatalf("source translation = %#v, want persisted ru copy", got["ru"])
	}
	if got["en"].Title != "Hotel departure" || got["kk"].Title != "Қонақүйден шығу" {
		t.Fatalf("translations = %#v, want generated en and kk copies", got)
	}
}

func TestCreateTourBatchesItineraryTranslationBySourceLocale(t *testing.T) {
	repo := &tourRepoStub{}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {
					"Hotel departure", "Meet your guide and start the route.",
					"Viewpoint walk", "We stop for photos.",
				},
				"kk": {
					"Қонақүйден шығу", "Гидпен кездесіп, маршрутты бастаңыз.",
					"Шолу алаңына серуен", "Суретке түсу үшін тоқтаймыз.",
				},
			},
		},
	}
	actorUserID := uuid.New()
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []TourItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.TourItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
			{
				StartOffsetMinutes: 60,
				Title:              "Прогулка к смотровой",
				Description:        "Останавливаемся для фото.",
				Translations: model.TourItineraryTranslations{
					"ru": {Title: "Прогулка к смотровой", Description: "Останавливаемся для фото."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("CreateTour() error = %v", err)
	}
	if len(translator.calls) != 1 {
		t.Fatalf("translator calls = %d, want 1 batched call", len(translator.calls))
	}
	if len(translator.calls[0].Texts) != 4 {
		t.Fatalf("translated text count = %d, want 4", len(translator.calls[0].Texts))
	}
	got := repo.createdRelations.Itinerary[1].Translations
	if got["en"].Title != "Viewpoint walk" || got["kk"].Description != "Суретке түсу үшін тоқтаймыз." {
		t.Fatalf("second item translations = %#v, want batched generated copies", got)
	}
}

func TestCreateTourRejectsIncompleteItineraryTranslation(t *testing.T) {
	repo := &tourRepoStub{}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Hotel departure", "Meet your guide and start the route."},
			},
		},
	}
	actorUserID := uuid.New()
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []TourItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.TourItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
		},
	})

	if !errors.Is(err, ErrTourTranslationFailed) {
		t.Fatalf("error = %v, want %v", err, ErrTourTranslationFailed)
	}
	if repo.createdTour != nil {
		t.Fatal("tour was persisted with incomplete itinerary translations")
	}
}

func TestCreateTourRejectsFreeTextIncludedItem(t *testing.T) {
	repo := &tourRepoStub{}
	actorUserID := uuid.New()
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		IncludedItems: []TourIncludedItemInput{
			{Text: "Private SUV"},
		},
		Itinerary: []TourItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrInvalidTourIncludedItem) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidTourIncludedItem)
	}
	if repo.createdTour != nil {
		t.Fatal("tour was persisted with a free-text included item")
	}
}

func TestCreateTourPersistsGuideSearchSnapshot(t *testing.T) {
	repo := &tourRepoStub{}
	guideProfileID := uuid.New()
	actorUserID := uuid.New()
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID:  guideProfileID,
			GuideUserID:     actorUserID,
			Allowed:         true,
			DisplayName:     "Aruzhan T.",
			GuideSearchText: "Aruzhan T. @aru_t local canyon expert",
		},
	}, nil)

	aggregate, err := uc.CreateTour(context.Background(), CreateTourInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Charyn Canyon"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
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

	if err != nil {
		t.Fatalf("CreateTour() error = %v", err)
	}
	if aggregate.Tour.GuideDisplayName != "Aruzhan T." {
		t.Fatalf("guide display name = %q, want snapshot display name", aggregate.Tour.GuideDisplayName)
	}
	if aggregate.Tour.GuideSearchText != "Aruzhan T. @aru_t local canyon expert" {
		t.Fatalf("guide search text = %q, want snapshot search text", aggregate.Tour.GuideSearchText)
	}
	if repo.createdTour.GuideDisplayName != aggregate.Tour.GuideDisplayName ||
		repo.createdTour.GuideSearchText != aggregate.Tour.GuideSearchText {
		t.Fatal("guide search snapshot was not persisted with the tour aggregate")
	}
}

func TestUpdateTourRejectsNonOwner(t *testing.T) {
	ownerID := uuid.New()
	tour, err := model.NewTour(model.NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
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
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
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

func TestUpdateTourTranslatesItineraryBeforePersisting(t *testing.T) {
	ownerID := uuid.New()
	tour, err := model.NewTour(model.NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Medeu",
		Summary:         "Compare guide offers for Medeu.",
		Description:     "Choose a guide, language, price, meeting point, schedule, and included options before booking.",
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
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Walk to the viewpoint", "We stop for photos and a short story."},
				"kk": {"Шолу алаңына серуен", "Суретке түсіп, қысқа әңгіме тыңдаймыз."},
			},
		},
	}
	uc := NewTourUseCase(repo, guideVerifierStub{
		result: port.GuideTourPermission{
			GuideProfileID: tour.GuideProfileID,
			GuideUserID:    ownerID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err = uc.UpdateTour(context.Background(), UpdateTourInput{
		ActorUserID:     ownerID,
		TourID:          tour.ID,
		CategorySlug:    "nature",
		Visibility:      string(enum.TourVisibilityPublic),
		DurationMinutes: 260,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     140,
		Currency:        "USD",
		Itinerary: []TourItineraryItemInput{
			{
				StartOffsetMinutes: 60,
				Title:              "Прогулка к смотровой",
				Description:        "Останавливаемся для фото и короткого рассказа.",
				Translations: model.TourItineraryTranslations{
					"ru": {Title: "Прогулка к смотровой", Description: "Останавливаемся для фото и короткого рассказа."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("UpdateTour() error = %v", err)
	}
	got := repo.savedRelations.Itinerary[0].Translations
	if got["en"].Title != "Walk to the viewpoint" || got["kk"].Description == "" {
		t.Fatalf("translations = %#v, want generated copies before save", got)
	}
}

func TestCreateTourBookingPersistsRequestForSelectedOffer(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	legacyTourID := uuid.New()
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)

	repo := &tourRepoStub{
		gotOffer: &model.TourOffer{
			ID:              offerID,
			ProductID:       productID,
			LegacyTourID:    &legacyTourID,
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.TourStatusPublished,
			Visibility:      enum.TourVisibilityPublic,
			DurationMinutes: 240,
			MaxGroupSize:    8,
			MeetingPoint:    "Hotel pickup",
			PriceAmount:     120,
			Currency:        "USD",
			Revision:        1,
			CreatedAt:       time.Now().UTC(),
			UpdatedAt:       time.Now().UTC(),
		},
	}
	uc := NewTourUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateTourBooking(context.Background(), CreateTourBookingInput{
		ActorUserID:  touristUserID,
		ProductID:    productID,
		OfferID:      offerID,
		ScheduledFor: scheduledFor,
		Adults:       2,
		Children:     1,
	})
	if err != nil {
		t.Fatalf("CreateTourBooking() error = %v", err)
	}
	if repo.createdBooking == nil {
		t.Fatal("booking was not persisted")
	}
	if booking.OfferID != offerID {
		t.Fatalf("booking offer id = %s, want %s", booking.OfferID, offerID)
	}
	if booking.LegacyTourID == nil || *booking.LegacyTourID != legacyTourID {
		t.Fatalf("legacy tour id = %v, want %s", booking.LegacyTourID, legacyTourID)
	}
	if booking.GuideUserID != guideUserID {
		t.Fatalf("guide user id = %s, want %s", booking.GuideUserID, guideUserID)
	}
	if booking.TouristUserID != touristUserID {
		t.Fatalf("tourist user id = %s, want %s", booking.TouristUserID, touristUserID)
	}
	if booking.TotalSeats != 3 {
		t.Fatalf("total seats = %d, want 3", booking.TotalSeats)
	}
	if booking.TotalPriceAmount <= booking.UnitPriceAmount {
		t.Fatalf("total price = %v, want subtotal plus service fee", booking.TotalPriceAmount)
	}
}

func TestCreateTourBookingRejectsOwnOffer(t *testing.T) {
	actorUserID := uuid.New()
	productID := uuid.New()
	offerID := uuid.New()
	repo := &tourRepoStub{
		gotOffer: &model.TourOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Status:         enum.TourStatusPublished,
			Visibility:     enum.TourVisibilityPublic,
			MaxGroupSize:   4,
			PriceAmount:    80,
			Currency:       "USD",
		},
	}
	uc := NewTourUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateTourBooking(context.Background(), CreateTourBookingInput{
		ActorUserID:  actorUserID,
		ProductID:    productID,
		OfferID:      offerID,
		ScheduledFor: time.Now().UTC().Add(24 * time.Hour),
		Adults:       1,
	})

	if !errors.Is(err, ErrTourAccessDenied) {
		t.Fatalf("error = %v, want %v", err, ErrTourAccessDenied)
	}
	if repo.createdBooking != nil {
		t.Fatal("guide booked their own offer")
	}
}

func stringPtr(v string) *string {
	return &v
}

func uuidPtr(v uuid.UUID) *uuid.UUID {
	return &v
}
