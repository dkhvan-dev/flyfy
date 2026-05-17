package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
)

type excursionRepoStub struct {
	createdExcursion  *model.Excursion
	createdRelations  port.ExcursionRelations
	gotExcursion      *model.Excursion
	gotOffer          *model.ExcursionOffer
	savedExcursion    *model.Excursion
	savedRelations    port.ExcursionRelations
	createdBooking    *model.ExcursionBooking
	loadedRelations   port.ExcursionRelations
	hasGuideLandmark  bool
	createAggregateFn func(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error
}

func (s *excursionRepoStub) CreateExcursionAggregate(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error {
	s.createdExcursion = item
	s.createdRelations = relations
	if s.createAggregateFn != nil {
		return s.createAggregateFn(ctx, item, relations)
	}
	return nil
}

func (s *excursionRepoStub) UpdateExcursionAggregate(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error {
	s.savedExcursion = item
	s.savedRelations = relations
	return nil
}

func (s *excursionRepoStub) UpdateExcursion(ctx context.Context, item *model.Excursion) error {
	s.savedExcursion = item
	return nil
}

func (s *excursionRepoStub) GetExcursionByID(ctx context.Context, excursionID uuid.UUID) (*model.Excursion, error) {
	return s.gotExcursion, nil
}

func (s *excursionRepoStub) ListExcursions(ctx context.Context, filter port.ExcursionFilter) ([]*model.Excursion, error) {
	return nil, nil
}

func (s *excursionRepoStub) LoadExcursionRelations(ctx context.Context, excursionID uuid.UUID) (port.ExcursionRelations, error) {
	return s.loadedRelations, nil
}

func (s *excursionRepoStub) CreateExcursionEvent(ctx context.Context, item *model.ExcursionEvent) error {
	return nil
}

func (s *excursionRepoStub) ListExcursionProductCards(ctx context.Context, filter port.ExcursionProductFilter) ([]*model.ExcursionProductCard, error) {
	return nil, nil
}

func (s *excursionRepoStub) GetExcursionProductCardByID(ctx context.Context, productID uuid.UUID) (*model.ExcursionProductCard, error) {
	return nil, nil
}

func (s *excursionRepoStub) ListExcursionOffers(ctx context.Context, filter port.ExcursionOfferFilter) ([]*model.ExcursionOffer, error) {
	return nil, nil
}

func (s *excursionRepoStub) ListExcursionLanguageCodesByGuideUserIDs(ctx context.Context, guideUserIDs []uuid.UUID) (map[uuid.UUID][]string, error) {
	return nil, nil
}

func (s *excursionRepoStub) HasActiveExcursionForGuideLandmark(ctx context.Context, guideUserID uuid.UUID, landmarkID uuid.UUID) (bool, error) {
	return s.hasGuideLandmark, nil
}

func (s *excursionRepoStub) GetExcursionOfferByID(ctx context.Context, offerID uuid.UUID) (*model.ExcursionOffer, error) {
	return s.gotOffer, nil
}

func (s *excursionRepoStub) LoadExcursionOfferRelations(ctx context.Context, offerID uuid.UUID) (port.ExcursionOfferRelations, error) {
	return port.ExcursionOfferRelations{}, nil
}

func (s *excursionRepoStub) CreateExcursionBooking(ctx context.Context, item *model.ExcursionBooking) error {
	s.createdBooking = item
	return nil
}

func (s *excursionRepoStub) ListExcursionBookings(ctx context.Context, filter port.ExcursionBookingFilter) ([]*model.ExcursionBookingListItem, error) {
	return nil, nil
}

func (s *excursionRepoStub) GetExcursionBookingByID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionBooking, error) {
	return nil, nil
}

func (s *excursionRepoStub) CreateExcursionReview(ctx context.Context, item *model.ExcursionReview) error {
	return nil
}

func (s *excursionRepoStub) GetExcursionReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionReview, error) {
	return nil, nil
}

func (s *excursionRepoStub) ListExcursionReviews(ctx context.Context, filter port.ExcursionReviewFilter) ([]*model.ExcursionReview, error) {
	return nil, nil
}

type guideVerifierStub struct {
	result port.GuideExcursionPermission
	err    error
}

func (s guideVerifierStub) VerifyExcursionGuide(ctx context.Context, userID uuid.UUID) (port.GuideExcursionPermission, error) {
	return s.result, s.err
}

type fileManagerStub struct {
	validated *uuid.UUID
	bound     *uuid.UUID
}

func (s *fileManagerStub) ValidateExcursionCoverFile(ctx context.Context, fileID uuid.UUID) error {
	s.validated = &fileID
	return nil
}

func (s *fileManagerStub) BindExcursionCoverFile(ctx context.Context, fileID uuid.UUID, excursionID uuid.UUID, createdByUserID uuid.UUID) error {
	s.bound = &fileID
	return nil
}

func (s *fileManagerStub) CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error) {
	return "https://cdn.example.test/excursion-cover.jpg", nil
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

func TestCreateExcursionRequiresActiveExcursionGuide(t *testing.T) {
	repo := &excursionRepoStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{err: ErrGuideNotAllowed}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     uuid.New(),
		CategorySlug:    "nature",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrGuideNotAllowed) {
		t.Fatalf("error = %v, want %v", err, ErrGuideNotAllowed)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted for a non-authorized guide")
	}
}

func TestCreateExcursionRequiresAttraction(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkName:    stringPtr("Custom place"),
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrExcursionAttractionRequired) {
		t.Fatalf("error = %v, want %v", err, ErrExcursionAttractionRequired)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted without an attraction")
	}
}

func TestCreateExcursionPersistsDraftAggregate(t *testing.T) {
	coverFileID := uuid.New()
	repo := &excursionRepoStub{}
	files := &fileManagerStub{}
	guideProfileID := uuid.New()
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: guideProfileID,
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, files)

	aggregate, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
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
		IncludedItems: []ExcursionIncludedItemInput{
			{Text: "transport"},
			{Text: "food"},
		},
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}
	if aggregate.Excursion.GuideProfileID != guideProfileID {
		t.Fatalf("guide profile id = %s, want %s", aggregate.Excursion.GuideProfileID, guideProfileID)
	}
	if repo.createdExcursion == nil {
		t.Fatal("excursion was not persisted")
	}
	if len(repo.createdRelations.LanguageCodes) != 2 || repo.createdRelations.LanguageCodes[0] != "en" {
		t.Fatalf("language codes = %#v, want normalized codes", repo.createdRelations.LanguageCodes)
	}
	if files.validated == nil || *files.validated != coverFileID {
		t.Fatal("cover file was not validated")
	}
	if files.bound == nil || *files.bound != coverFileID {
		t.Fatal("cover file was not bound to the excursion")
	}
	if len(repo.createdRelations.IncludedItems) != 2 ||
		repo.createdRelations.IncludedItems[0].Text != "food" ||
		repo.createdRelations.IncludedItems[1].Text != "transport" {
		t.Fatalf("included items = %#v, want stable dictionary keys", repo.createdRelations.IncludedItems)
	}
}

func TestCreateExcursionRejectsDuplicateGuideLandmark(t *testing.T) {
	repo := &excursionRepoStub{hasGuideLandmark: true}
	guideUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     guideUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Katon-Karagay National Park"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		MeetingPoint:    "Visitor center",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Start", Description: "Meet your guide."},
		},
	})

	if !errors.Is(err, model.ErrExcursionGuideLandmarkAlreadyExists) {
		t.Fatalf("error = %v, want %v", err, model.ErrExcursionGuideLandmarkAlreadyExists)
	}
	if repo.createdExcursion != nil {
		t.Fatal("duplicate guide landmark excursion was persisted")
	}
}

func TestCreateExcursionTranslatesItineraryBeforePersisting(t *testing.T) {
	repo := &excursionRepoStub{}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Hotel departure", "Meet your guide and start the route."},
				"kk": {"Қонақүйден шығу", "Гидпен кездесіп, маршрутты бастаңыз."},
			},
		},
	}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
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
		Itinerary: []ExcursionItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
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

func TestCreateExcursionBatchesItineraryTranslationBySourceLocale(t *testing.T) {
	repo := &excursionRepoStub{}
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
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
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
		Itinerary: []ExcursionItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
			{
				StartOffsetMinutes: 60,
				Title:              "Прогулка к смотровой",
				Description:        "Останавливаемся для фото.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Прогулка к смотровой", Description: "Останавливаемся для фото."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
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

func TestCreateExcursionRejectsIncompleteItineraryTranslation(t *testing.T) {
	repo := &excursionRepoStub{}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Hotel departure", "Meet your guide and start the route."},
			},
		},
	}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
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
		Itinerary: []ExcursionItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
		},
	})

	if !errors.Is(err, ErrExcursionTranslationFailed) {
		t.Fatalf("error = %v, want %v", err, ErrExcursionTranslationFailed)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted with incomplete itinerary translations")
	}
}

func TestCreateExcursionRejectsFreeTextIncludedItem(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
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
		IncludedItems: []ExcursionIncludedItemInput{
			{Text: "Private SUV"},
		},
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrInvalidExcursionIncludedItem) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidExcursionIncludedItem)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted with a free-text included item")
	}
}

func TestCreateExcursionPersistsGuideSearchSnapshot(t *testing.T) {
	repo := &excursionRepoStub{}
	guideProfileID := uuid.New()
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID:  guideProfileID,
			GuideUserID:     actorUserID,
			Allowed:         true,
			DisplayName:     "Aruzhan T.",
			GuideSearchText: "Aruzhan T. @aru_t local canyon expert",
		},
	}, nil)

	aggregate, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
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
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}
	if aggregate.Excursion.GuideDisplayName != "Aruzhan T." {
		t.Fatalf("guide display name = %q, want snapshot display name", aggregate.Excursion.GuideDisplayName)
	}
	if aggregate.Excursion.GuideSearchText != "Aruzhan T. @aru_t local canyon expert" {
		t.Fatalf("guide search text = %q, want snapshot search text", aggregate.Excursion.GuideSearchText)
	}
	if repo.createdExcursion.GuideDisplayName != aggregate.Excursion.GuideDisplayName ||
		repo.createdExcursion.GuideSearchText != aggregate.Excursion.GuideSearchText {
		t.Fatal("guide search snapshot was not persisted with the excursion aggregate")
	}
}

func TestUpdateExcursionRejectsNonOwner(t *testing.T) {
	ownerID := uuid.New()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
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
		t.Fatalf("NewExcursion() error = %v", err)
	}

	repo := &excursionRepoStub{gotExcursion: excursion}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err = uc.UpdateExcursion(context.Background(), UpdateExcursionInput{
		ActorUserID:     uuid.New(),
		ExcursionID:     excursion.ID,
		CategorySlug:    "nature",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrExcursionAccessDenied) {
		t.Fatalf("error = %v, want %v", err, ErrExcursionAccessDenied)
	}
	if repo.savedExcursion != nil {
		t.Fatal("excursion was updated by a non-owner")
	}
}

func TestUpdatePublishedExcursionKeepsOriginalPublicationTime(t *testing.T) {
	ownerID := uuid.New()
	publishedAt := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
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
	excursion.Status = enum.ExcursionStatusPublished
	excursion.PublishedAt = &publishedAt

	repo := &excursionRepoStub{gotExcursion: excursion}
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: excursion.GuideProfileID,
			GuideUserID:    ownerID,
			Allowed:        true,
		},
	}, nil)

	_, err = uc.UpdateExcursion(context.Background(), UpdateExcursionInput{
		ActorUserID:     ownerID,
		ExcursionID:     excursion.ID,
		CategorySlug:    "nature",
		Visibility:      string(enum.ExcursionVisibilityPublic),
		DurationMinutes: 260,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en", "ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     140,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})
	if err != nil {
		t.Fatalf("UpdateExcursion() error = %v", err)
	}
	if repo.savedExcursion == nil {
		t.Fatal("excursion was not saved")
	}
	if repo.savedExcursion.Status != enum.ExcursionStatusPublished {
		t.Fatalf("status = %s, want %s", repo.savedExcursion.Status, enum.ExcursionStatusPublished)
	}
	if repo.savedExcursion.PublishedAt == nil || !repo.savedExcursion.PublishedAt.Equal(publishedAt) {
		t.Fatalf("publishedAt = %v, want %v", repo.savedExcursion.PublishedAt, publishedAt)
	}
}

func TestUpdateExcursionTranslatesItineraryBeforePersisting(t *testing.T) {
	ownerID := uuid.New()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
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
		t.Fatalf("NewExcursion() error = %v", err)
	}

	repo := &excursionRepoStub{gotExcursion: excursion}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Walk to the viewpoint", "We stop for photos and a short story."},
				"kk": {"Шолу алаңына серуен", "Суретке түсіп, қысқа әңгіме тыңдаймыз."},
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: excursion.GuideProfileID,
			GuideUserID:    ownerID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err = uc.UpdateExcursion(context.Background(), UpdateExcursionInput{
		ActorUserID:     ownerID,
		ExcursionID:     excursion.ID,
		CategorySlug:    "nature",
		Visibility:      string(enum.ExcursionVisibilityPublic),
		DurationMinutes: 260,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     140,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{
				StartOffsetMinutes: 60,
				Title:              "Прогулка к смотровой",
				Description:        "Останавливаемся для фото и короткого рассказа.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Прогулка к смотровой", Description: "Останавливаемся для фото и короткого рассказа."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("UpdateExcursion() error = %v", err)
	}
	got := repo.savedRelations.Itinerary[0].Translations
	if got["en"].Title != "Walk to the viewpoint" || got["kk"].Description == "" {
		t.Fatalf("translations = %#v, want generated copies before save", got)
	}
}

func TestCreateExcursionBookingPersistsRequestForSelectedOffer(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	legacyExcursionID := uuid.New()
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)

	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:                offerID,
			ProductID:         productID,
			LegacyExcursionID: &legacyExcursionID,
			GuideProfileID:    uuid.New(),
			GuideUserID:       guideUserID,
			Status:            enum.ExcursionStatusPublished,
			Visibility:        enum.ExcursionVisibilityPublic,
			DurationMinutes:   240,
			MaxGroupSize:      8,
			MeetingPoint:      "Hotel pickup",
			PriceAmount:       120,
			Currency:          "USD",
			Revision:          1,
			CreatedAt:         time.Now().UTC(),
			UpdatedAt:         time.Now().UTC(),
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:  touristUserID,
		ProductID:    productID,
		OfferID:      offerID,
		ScheduledFor: scheduledFor,
		Adults:       2,
		Children:     1,
	})
	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if repo.createdBooking == nil {
		t.Fatal("booking was not persisted")
	}
	if booking.OfferID != offerID {
		t.Fatalf("booking offer id = %s, want %s", booking.OfferID, offerID)
	}
	if booking.LegacyExcursionID == nil || *booking.LegacyExcursionID != legacyExcursionID {
		t.Fatalf("legacy excursion id = %v, want %s", booking.LegacyExcursionID, legacyExcursionID)
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

func TestCreateExcursionBookingRejectsOwnOffer(t *testing.T) {
	actorUserID := uuid.New()
	productID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   4,
			PriceAmount:    80,
			Currency:       "USD",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:  actorUserID,
		ProductID:    productID,
		OfferID:      offerID,
		ScheduledFor: time.Now().UTC().Add(24 * time.Hour),
		Adults:       1,
	})

	if !errors.Is(err, ErrExcursionAccessDenied) {
		t.Fatalf("error = %v, want %v", err, ErrExcursionAccessDenied)
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
