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
	createdExcursion                *model.Excursion
	createdRelations                port.ExcursionRelations
	gotExcursion                    *model.Excursion
	gotOffer                        *model.ExcursionOffer
	gotOfferByLegacy                *model.ExcursionOffer
	gotOfferByLegacyID              uuid.UUID
	savedExcursion                  *model.Excursion
	savedRelations                  port.ExcursionRelations
	createdBooking                  *model.ExcursionBooking
	createBookingErr                error
	existingBookingByKey            *model.ExcursionBooking
	existingBookingAfterKeyConflict *model.ExcursionBooking
	gotIdempotencyTouristID         uuid.UUID
	gotIdempotencyKey               string
	idempotencyLookupCount          int
	createdScheduleSlot             *model.ExcursionScheduleSlot
	createdScheduleSeries           *model.ExcursionScheduleSeries
	createdSeriesSlots              []*model.ExcursionScheduleSlot
	createScheduleSeriesErr         error
	createScheduleSlotErr           error
	gotScheduleSlot                 *model.ExcursionScheduleSlot
	reservedScheduleSlotID          uuid.UUID
	reservedScheduleSeats           int
	reserveScheduleErr              error
	expiredScheduleCutoff           time.Time
	expiredScheduleReason           string
	expireScheduleErr               error
	listBookingFilter               port.ExcursionBookingFilter
	listBookingItems                []*model.ExcursionBookingListItem
	gotBooking                      *model.ExcursionBooking
	updatedBooking                  *model.ExcursionBooking
	updatedBookingSeatDelta         int
	updateBookingGuestsErr          error
	listScheduleFilter              port.ExcursionScheduleFilter
	listScheduleSlots               []*model.ExcursionScheduleSlot
	listExcursions                  []*model.Excursion
	loadedRelations                 port.ExcursionRelations
	hasGuideLandmark                bool
	createAggregateFn               func(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error
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
	return s.listExcursions, nil
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

func (s *excursionRepoStub) GetExcursionOfferByLegacyExcursionID(ctx context.Context, legacyExcursionID uuid.UUID) (*model.ExcursionOffer, error) {
	s.gotOfferByLegacyID = legacyExcursionID
	return s.gotOfferByLegacy, nil
}

func (s *excursionRepoStub) LoadExcursionOfferRelations(ctx context.Context, offerID uuid.UUID) (port.ExcursionOfferRelations, error) {
	return port.ExcursionOfferRelations{}, nil
}

func (s *excursionRepoStub) CreateExcursionBooking(ctx context.Context, item *model.ExcursionBooking) error {
	s.createdBooking = item
	return s.createBookingErr
}

func (s *excursionRepoStub) GetExcursionBookingByTouristIDAndIdempotencyKey(ctx context.Context, touristUserID uuid.UUID, idempotencyKey string) (*model.ExcursionBooking, error) {
	s.gotIdempotencyTouristID = touristUserID
	s.gotIdempotencyKey = idempotencyKey
	s.idempotencyLookupCount++
	if s.idempotencyLookupCount > 1 && s.existingBookingAfterKeyConflict != nil {
		return s.existingBookingAfterKeyConflict, nil
	}
	return s.existingBookingByKey, nil
}

func (s *excursionRepoStub) CreateExcursionScheduleSlot(ctx context.Context, slot *model.ExcursionScheduleSlot) error {
	s.createdScheduleSlot = slot
	return s.createScheduleSlotErr
}

func (s *excursionRepoStub) CreateExcursionScheduleSeriesWithSlots(ctx context.Context, series *model.ExcursionScheduleSeries, slots []*model.ExcursionScheduleSlot) error {
	s.createdScheduleSeries = series
	s.createdSeriesSlots = slots
	return s.createScheduleSeriesErr
}

func (s *excursionRepoStub) UpdateExcursionScheduleSlot(ctx context.Context, slot *model.ExcursionScheduleSlot) error {
	s.createdScheduleSlot = slot
	return nil
}

func (s *excursionRepoStub) DeleteExcursionScheduleSlot(ctx context.Context, slotID uuid.UUID, guideUserID uuid.UUID) error {
	return nil
}

func (s *excursionRepoStub) GetExcursionScheduleSlotByID(ctx context.Context, slotID uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	return s.gotScheduleSlot, nil
}

func (s *excursionRepoStub) ListExcursionScheduleSlots(ctx context.Context, filter port.ExcursionScheduleFilter) ([]*model.ExcursionScheduleSlot, error) {
	s.listScheduleFilter = filter
	return s.listScheduleSlots, nil
}

func (s *excursionRepoStub) ReserveExcursionScheduleSlotSeats(ctx context.Context, slotID uuid.UUID, seats int) error {
	s.reservedScheduleSlotID = slotID
	s.reservedScheduleSeats = seats
	return s.reserveScheduleErr
}

func (s *excursionRepoStub) ExpireUnbookedExcursionScheduleSlots(ctx context.Context, cutoff time.Time, reason string) error {
	s.expiredScheduleCutoff = cutoff
	s.expiredScheduleReason = reason
	return s.expireScheduleErr
}

func (s *excursionRepoStub) ListExcursionBookings(ctx context.Context, filter port.ExcursionBookingFilter) ([]*model.ExcursionBookingListItem, error) {
	s.listBookingFilter = filter
	return s.listBookingItems, nil
}

func (s *excursionRepoStub) GetExcursionBookingByID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionBooking, error) {
	return s.gotBooking, nil
}

func (s *excursionRepoStub) UpdateExcursionBookingGuests(ctx context.Context, item *model.ExcursionBooking, seatDelta int) error {
	s.updatedBooking = item
	s.updatedBookingSeatDelta = seatDelta
	return s.updateBookingGuestsErr
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

func TestListMyExcursionsKeepsProductCoverFallback(t *testing.T) {
	guideUserID := uuid.New()
	productCoverFileID := uuid.New()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Medeu tour",
		Summary:         "Private mountain route",
		Description:     "A detailed mountain excursion through Medeu.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 180,
		MaxGroupSize:    6,
		MeetingPoint:    "Medeu entrance",
		PriceAmount:     120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}
	repo := &excursionRepoStub{
		listExcursions: []*model.Excursion{excursion},
		loadedRelations: port.ExcursionRelations{
			ProductCoverFileID: &productCoverFileID,
		},
	}
	uc := NewExcursionUseCase(repo, nil, nil)

	items, err := uc.ListMyExcursions(context.Background(), guideUserID, 20, 0, nil)

	if err != nil {
		t.Fatalf("ListMyExcursions() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items = %d, want 1", len(items))
	}
	if items[0].CoverFileID != nil {
		t.Fatalf("cover file id = %v, want nil offer cover", items[0].CoverFileID)
	}
	if items[0].ProductCoverFileID == nil || *items[0].ProductCoverFileID != productCoverFileID {
		t.Fatalf("product cover file id = %v, want %s", items[0].ProductCoverFileID, productCoverFileID)
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

func TestArchiveExcursionKeepsOfferVisibleForGuideArchive(t *testing.T) {
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

	repo := &excursionRepoStub{gotExcursion: excursion}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	aggregate, err := uc.ArchiveExcursion(context.Background(), excursion.ID, ownerID)
	if err != nil {
		t.Fatalf("ArchiveExcursion() error = %v", err)
	}
	if aggregate.Excursion.Status != enum.ExcursionStatusArchived {
		t.Fatalf("status = %s, want %s", aggregate.Excursion.Status, enum.ExcursionStatusArchived)
	}
	if aggregate.Excursion.DeletedAt != nil {
		t.Fatalf("DeletedAt = %v, want nil", aggregate.Excursion.DeletedAt)
	}
	if repo.savedExcursion == nil {
		t.Fatal("archived excursion was not persisted")
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

func TestCreateExcursionBookingReturnsExistingForIdempotencyRetry(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	scheduledFor := time.Date(2026, 5, 18, 8, 0, 0, 0, time.UTC)
	idempotencyKey := productID.String() + ":" + offerID.String() + ":1:0"
	existing, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
		IdempotencyKey:  &idempotencyKey,
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		existingBookingByKey: existing,
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:    touristUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduledFor:   scheduledFor,
		Adults:         1,
		Children:       0,
		IdempotencyKey: &idempotencyKey,
	})

	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if booking.ID != existing.ID {
		t.Fatalf("booking id = %s, want existing %s", booking.ID, existing.ID)
	}
	if repo.createdBooking != nil {
		t.Fatal("idempotency retry inserted a new booking")
	}
	if repo.gotIdempotencyTouristID != touristUserID {
		t.Fatalf("idempotency tourist id = %s, want %s", repo.gotIdempotencyTouristID, touristUserID)
	}
	if repo.gotIdempotencyKey != idempotencyKey {
		t.Fatalf("idempotency key = %q, want %q", repo.gotIdempotencyKey, idempotencyKey)
	}
}

func TestCreateExcursionBookingReturnsExistingWhenInsertHitsIdempotencyConflict(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)
	idempotencyKey := productID.String() + ":" + offerID.String() + ":1:0"
	existing, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
		IdempotencyKey:  &idempotencyKey,
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    120,
			Currency:       "KZT",
		},
		createBookingErr:                port.ErrExcursionBookingIdempotencyConflict,
		existingBookingAfterKeyConflict: existing,
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:    touristUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduledFor:   scheduledFor,
		Adults:         1,
		Children:       0,
		IdempotencyKey: &idempotencyKey,
	})

	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if booking.ID != existing.ID {
		t.Fatalf("booking id = %s, want existing %s", booking.ID, existing.ID)
	}
	if repo.createdBooking == nil {
		t.Fatal("booking insert was not attempted before conflict resolution")
	}
	if repo.idempotencyLookupCount != 2 {
		t.Fatalf("idempotency lookups = %d, want 2", repo.idempotencyLookupCount)
	}
}

func TestCreateGuideScheduleSlotRejectsOverlap(t *testing.T) {
	guideUserID := uuid.New()
	start := time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:                uuid.New(),
			ProductID:         uuid.New(),
			LegacyExcursionID: uuidPtr(uuid.New()),
			GuideProfileID:    uuid.New(),
			GuideUserID:       guideUserID,
			Status:            enum.ExcursionStatusPublished,
			Visibility:        enum.ExcursionVisibilityPublic,
			DurationMinutes:   240,
			MaxGroupSize:      6,
			MeetingPoint:      "Medeu entrance",
			PriceAmount:       120,
			Currency:          "KZT",
		},
		createScheduleSlotErr: port.ErrExcursionScheduleConflict,
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateGuideScheduleSlot(context.Background(), CreateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		OfferID:     repo.gotOffer.ID,
		StartAt:     start,
		Timezone:    "Asia/Almaty",
		Capacity:    6,
	})

	if !errors.Is(err, ErrExcursionScheduleConflict) {
		t.Fatalf("error = %v, want ErrExcursionScheduleConflict", err)
	}
}

func TestCreateGuideScheduleSlotAcceptsLegacyExcursionID(t *testing.T) {
	guideUserID := uuid.New()
	legacyExcursionID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	start := time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC)
	repo := &excursionRepoStub{
		gotOfferByLegacy: &model.ExcursionOffer{
			ID:                offerID,
			ProductID:         productID,
			LegacyExcursionID: &legacyExcursionID,
			GuideProfileID:    uuid.New(),
			GuideUserID:       guideUserID,
			Status:            enum.ExcursionStatusPublished,
			Visibility:        enum.ExcursionVisibilityPublic,
			DurationMinutes:   180,
			MaxGroupSize:      6,
			MeetingPoint:      "Medeu entrance",
			PriceAmount:       120,
			Currency:          "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	slot, err := uc.CreateGuideScheduleSlot(context.Background(), CreateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		OfferID:     legacyExcursionID,
		StartAt:     start,
		Timezone:    "Asia/Almaty",
		Capacity:    6,
	})

	if err != nil {
		t.Fatalf("CreateGuideScheduleSlot() error = %v", err)
	}
	if repo.gotOfferByLegacyID != legacyExcursionID {
		t.Fatalf("legacy lookup id = %s, want %s", repo.gotOfferByLegacyID, legacyExcursionID)
	}
	if slot.OfferID != offerID || slot.ProductID != productID {
		t.Fatalf("slot offer/product = %s/%s, want %s/%s", slot.OfferID, slot.ProductID, offerID, productID)
	}
}

func TestCreateGuideScheduleSlotRejectsCapacityAboveOfferMax(t *testing.T) {
	guideUserID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       uuid.New(),
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    8,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateGuideScheduleSlot(context.Background(), CreateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		OfferID:     offerID,
		StartAt:     time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC),
		Timezone:    "Asia/Almaty",
		Capacity:    100,
	})

	if !errors.Is(err, model.ErrInvalidExcursionScheduleCapacity) {
		t.Fatalf("error = %v, want ErrInvalidExcursionScheduleCapacity", err)
	}
	if repo.createdScheduleSlot != nil {
		t.Fatalf("slot was persisted despite invalid capacity: %#v", repo.createdScheduleSlot)
	}
}

func TestCreateGuideScheduleSlotRejectsStartInsideSetupLeadTime(t *testing.T) {
	guideUserID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       uuid.New(),
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    8,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateGuideScheduleSlot(context.Background(), CreateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		OfferID:     offerID,
		StartAt:     time.Now().UTC().Add(2 * time.Hour),
		Timezone:    "Asia/Almaty",
		Capacity:    6,
	})

	if !errors.Is(err, ErrExcursionScheduleStartTooSoon) {
		t.Fatalf("error = %v, want ErrExcursionScheduleStartTooSoon", err)
	}
	if repo.createdScheduleSlot != nil {
		t.Fatalf("slot was persisted despite setup lead time: %#v", repo.createdScheduleSlot)
	}
}

func TestUpdateGuideScheduleSlotReschedulesWithSelectedOffer(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	oldOfferID := uuid.New()
	newOfferID := uuid.New()
	newProductID := uuid.New()
	newLegacyExcursionID := uuid.New()
	startAt := time.Date(2026, 5, 29, 9, 30, 0, 0, time.UTC)
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        oldOfferID,
			ProductID:      uuid.New(),
			StartAt:        time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC),
			EndAt:          time.Date(2026, 5, 22, 11, 0, 0, 0, time.UTC),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    0,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
		gotOffer: &model.ExcursionOffer{
			ID:                newOfferID,
			ProductID:         newProductID,
			LegacyExcursionID: &newLegacyExcursionID,
			GuideProfileID:    uuid.New(),
			GuideUserID:       guideUserID,
			Status:            enum.ExcursionStatusPublished,
			Visibility:        enum.ExcursionVisibilityPublic,
			DurationMinutes:   180,
			MaxGroupSize:      8,
			MeetingPoint:      "Medeu entrance",
			PriceAmount:       120,
			Currency:          "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	slot, err := uc.UpdateGuideScheduleSlot(context.Background(), UpdateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		SlotID:      slotID,
		OfferID:     newOfferID,
		StartAt:     startAt,
		Timezone:    "Asia/Almaty",
		Capacity:    5,
	})

	if err != nil {
		t.Fatalf("UpdateGuideScheduleSlot() error = %v", err)
	}
	if repo.createdScheduleSlot == nil {
		t.Fatal("updated slot was not persisted")
	}
	if slot.OfferID != newOfferID || slot.ProductID != newProductID {
		t.Fatalf("slot offer/product = %s/%s, want %s/%s", slot.OfferID, slot.ProductID, newOfferID, newProductID)
	}
	if slot.StartAt != startAt || slot.EndAt != startAt.Add(180*time.Minute) {
		t.Fatalf("slot interval = %s-%s, want %s + 180m", slot.StartAt, slot.EndAt, startAt)
	}
	if slot.Capacity != 5 {
		t.Fatalf("capacity = %d, want 5", slot.Capacity)
	}
}

func TestUpdateGuideScheduleSlotRejectsBookedSlot(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      uuid.New(),
			StartAt:        time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC),
			EndAt:          time.Date(2026, 5, 22, 11, 0, 0, 0, time.UTC),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    2,
			Status:         enum.ExcursionScheduleSlotStatusBooked,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.UpdateGuideScheduleSlot(context.Background(), UpdateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		SlotID:      slotID,
		OfferID:     offerID,
		StartAt:     time.Date(2026, 5, 29, 9, 30, 0, 0, time.UTC),
		Timezone:    "Asia/Almaty",
		Capacity:    5,
	})

	if !errors.Is(err, ErrExcursionScheduleUnavailable) {
		t.Fatalf("error = %v, want ErrExcursionScheduleUnavailable", err)
	}
	if repo.createdScheduleSlot != nil {
		t.Fatalf("slot was persisted despite booked seats: %#v", repo.createdScheduleSlot)
	}
}

func TestUpdateGuideScheduleSlotRejectsStartInsideSetupLeadTime(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      uuid.New(),
			StartAt:        time.Now().UTC().Add(24 * time.Hour),
			EndAt:          time.Now().UTC().Add(26 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    0,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
		gotOffer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       uuid.New(),
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    8,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.UpdateGuideScheduleSlot(context.Background(), UpdateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		SlotID:      slotID,
		OfferID:     offerID,
		StartAt:     time.Now().UTC().Add(2 * time.Hour),
		Timezone:    "Asia/Almaty",
		Capacity:    5,
	})

	if !errors.Is(err, ErrExcursionScheduleStartTooSoon) {
		t.Fatalf("error = %v, want ErrExcursionScheduleStartTooSoon", err)
	}
	if repo.createdScheduleSlot != nil {
		t.Fatalf("slot was persisted despite setup lead time: %#v", repo.createdScheduleSlot)
	}
}

func TestWeeklyOccurrencesKeepsLocalWeekdayAndClock(t *testing.T) {
	startDate := time.Date(2026, 5, 18, 12, 0, 0, 0, time.UTC)
	until := time.Date(2026, 6, 5, 23, 59, 0, 0, time.UTC)

	items, err := weeklyOccurrences(startDate, []int{5}, "09:00", 180, "Asia/Almaty", until, 3)

	if err != nil {
		t.Fatalf("weeklyOccurrences() error = %v", err)
	}
	if len(items) != 3 {
		t.Fatalf("items len = %d, want 3", len(items))
	}
	loc, err := time.LoadLocation("Asia/Almaty")
	if err != nil {
		t.Fatalf("load location: %v", err)
	}
	for _, item := range items {
		local := item.In(loc)
		if local.Weekday() != time.Friday || local.Hour() != 9 || local.Minute() != 0 {
			t.Fatalf("occurrence = %s, want Friday 09:00 Asia/Almaty", local)
		}
	}
}

func TestCreateGuideScheduleSeriesCreatesWeeklySlots(t *testing.T) {
	guideUserID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       productID,
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    6,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)
	limit := 3

	slots, err := uc.CreateGuideScheduleSeries(context.Background(), CreateGuideScheduleSeriesInput{
		ActorUserID:     guideUserID,
		OfferID:         offerID,
		StartsOn:        time.Date(2026, 5, 18, 0, 0, 0, 0, time.UTC),
		OccurrenceLimit: &limit,
		StartTime:       "09:00",
		Timezone:        "Asia/Almaty",
		Weekdays:        []int{5},
		Capacity:        5,
	})

	if err != nil {
		t.Fatalf("CreateGuideScheduleSeries() error = %v", err)
	}
	if repo.createdScheduleSeries == nil {
		t.Fatal("series was not persisted")
	}
	if len(slots) != 3 || len(repo.createdSeriesSlots) != 3 {
		t.Fatalf("slots = %d persisted = %d, want 3", len(slots), len(repo.createdSeriesSlots))
	}
	loc, err := time.LoadLocation("Asia/Almaty")
	if err != nil {
		t.Fatalf("load location: %v", err)
	}
	for _, slot := range slots {
		local := slot.StartAt.In(loc)
		if local.Weekday() != time.Friday || local.Hour() != 9 || slot.Capacity != 5 {
			t.Fatalf("slot = %+v local = %v, want Friday 09:00 capacity 5", slot, local)
		}
		if slot.SeriesID == nil || *slot.SeriesID != repo.createdScheduleSeries.ID {
			t.Fatalf("slot series id = %v, want %s", slot.SeriesID, repo.createdScheduleSeries.ID)
		}
	}
}

func TestCreateExcursionBookingUsesScheduleSlotAndLocksCapacity(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	startAt := time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    100,
			Currency:       "KZT",
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      productID,
			StartAt:        startAt,
			EndAt:          startAt.Add(4 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    0,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:    touristUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduleSlotID: &slotID,
		Adults:         2,
		Children:       0,
	})

	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if booking.ScheduleSlotID == nil || *booking.ScheduleSlotID != slotID {
		t.Fatalf("schedule slot id = %v, want %s", booking.ScheduleSlotID, slotID)
	}
	if booking.ScheduledFor != startAt {
		t.Fatalf("scheduled for = %v, want %v", booking.ScheduledFor, startAt)
	}
}

func TestCreateExcursionBookingRejectsSlotInsideBookingLeadTime(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	startAt := time.Now().UTC().Add(90 * time.Minute)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    100,
			Currency:       "KZT",
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      productID,
			StartAt:        startAt,
			EndAt:          startAt.Add(4 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    0,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:    touristUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduleSlotID: &slotID,
		Adults:         1,
		Children:       0,
	})

	if !errors.Is(err, ErrExcursionScheduleUnavailable) {
		t.Fatalf("error = %v, want ErrExcursionScheduleUnavailable", err)
	}
	if repo.createdBooking != nil {
		t.Fatal("booking was persisted despite slot being inside booking lead time")
	}
}

func TestUpdateExcursionBookingGuestsAdjustsScheduleSeatDelta(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		ScheduleSlotID:  &slotID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          2,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotBooking: booking,
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    120,
			Currency:       "KZT",
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:          slotID,
			OfferID:     offerID,
			ProductID:   productID,
			GuideUserID: guideUserID,
			StartAt:     scheduledFor,
			EndAt:       scheduledFor.Add(2 * time.Hour),
			Timezone:    "Asia/Almaty",
			Capacity:    6,
			BookedSeats: 2,
			Status:      enum.ExcursionScheduleSlotStatusBooked,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	updated, err := uc.UpdateExcursionBookingGuests(context.Background(), UpdateExcursionBookingGuestsInput{
		ActorUserID: touristUserID,
		BookingID:   booking.ID,
		Adults:      3,
		Children:    1,
	})

	if err != nil {
		t.Fatalf("UpdateExcursionBookingGuests() error = %v", err)
	}
	if updated.TotalSeats != 4 || updated.Adults != 3 || updated.Children != 1 {
		t.Fatalf("updated guests = %d/%d total %d, want 3/1 total 4", updated.Adults, updated.Children, updated.TotalSeats)
	}
	if repo.updatedBookingSeatDelta != 2 {
		t.Fatalf("seat delta = %d, want 2", repo.updatedBookingSeatDelta)
	}
	if repo.updatedBooking == nil || repo.updatedBooking.ID != booking.ID {
		t.Fatal("updated booking was not persisted")
	}
}

func TestUpdateExcursionBookingGuestsRejectsSlotCapacityOverflow(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		ScheduleSlotID:  &slotID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          2,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotBooking: booking,
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    120,
			Currency:       "KZT",
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:          slotID,
			OfferID:     offerID,
			ProductID:   productID,
			GuideUserID: guideUserID,
			StartAt:     scheduledFor,
			EndAt:       scheduledFor.Add(2 * time.Hour),
			Timezone:    "Asia/Almaty",
			Capacity:    4,
			BookedSeats: 2,
			Status:      enum.ExcursionScheduleSlotStatusBooked,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err = uc.UpdateExcursionBookingGuests(context.Background(), UpdateExcursionBookingGuestsInput{
		ActorUserID: touristUserID,
		BookingID:   booking.ID,
		Adults:      4,
		Children:    1,
	})

	if !errors.Is(err, ErrExcursionScheduleUnavailable) {
		t.Fatalf("error = %v, want ErrExcursionScheduleUnavailable", err)
	}
	if repo.updatedBooking != nil {
		t.Fatal("booking was persisted despite capacity overflow")
	}
}

func TestListPublicExcursionScheduleFiltersBookableSlotsBySeats(t *testing.T) {
	offerID := uuid.New()
	productID := uuid.New()
	guideUserID := uuid.New()
	from := time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC)
	to := from.Add(7 * 24 * time.Hour)
	availableStart := time.Date(2026, 6, 2, 9, 0, 0, 0, time.UTC)
	fullStart := time.Date(2026, 6, 3, 9, 0, 0, 0, time.UTC)
	closedStart := time.Date(2026, 6, 4, 9, 0, 0, 0, time.UTC)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   8,
			PriceAmount:    100,
			Currency:       "KZT",
		},
		listScheduleSlots: []*model.ExcursionScheduleSlot{
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        availableStart,
				EndAt:          availableStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    4,
				Status:         enum.ExcursionScheduleSlotStatusBooked,
			},
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        fullStart,
				EndAt:          fullStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    6,
				Status:         enum.ExcursionScheduleSlotStatusBooked,
			},
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        closedStart,
				EndAt:          closedStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				Status:         enum.ExcursionScheduleSlotStatusClosed,
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	slots, err := uc.ListPublicExcursionSchedule(context.Background(), ListPublicExcursionScheduleInput{
		ProductID: productID,
		OfferID:   offerID,
		From:      from,
		To:        to,
		Seats:     3,
	})

	if err != nil {
		t.Fatalf("ListPublicExcursionSchedule() error = %v", err)
	}
	if len(slots) != 1 {
		t.Fatalf("slots len = %d, want 1", len(slots))
	}
	if slots[0].StartAt != availableStart {
		t.Fatalf("slot start = %v, want %v", slots[0].StartAt, availableStart)
	}
	if repo.listScheduleFilter.OfferID == nil || *repo.listScheduleFilter.OfferID != offerID {
		t.Fatalf("offer filter = %v, want %s", repo.listScheduleFilter.OfferID, offerID)
	}
	if len(repo.listScheduleFilter.Statuses) != 2 {
		t.Fatalf("status filters = %v, want available/booked", repo.listScheduleFilter.Statuses)
	}
}

func TestListPublicExcursionScheduleRequiresTwoHourLeadTime(t *testing.T) {
	offerID := uuid.New()
	productID := uuid.New()
	guideUserID := uuid.New()
	now := time.Now().UTC()
	soonStart := now.Add(90 * time.Minute)
	futureStart := now.Add(3 * time.Hour)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   8,
			PriceAmount:    100,
			Currency:       "KZT",
		},
		listScheduleSlots: []*model.ExcursionScheduleSlot{
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        soonStart,
				EndAt:          soonStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    0,
				Status:         enum.ExcursionScheduleSlotStatusAvailable,
			},
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        futureStart,
				EndAt:          futureStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    0,
				Status:         enum.ExcursionScheduleSlotStatusAvailable,
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	slots, err := uc.ListPublicExcursionSchedule(context.Background(), ListPublicExcursionScheduleInput{
		ProductID: productID,
		OfferID:   offerID,
		From:      now.Add(-time.Hour),
		To:        now.Add(24 * time.Hour),
		Seats:     1,
	})

	if err != nil {
		t.Fatalf("ListPublicExcursionSchedule() error = %v", err)
	}
	if len(slots) != 1 || slots[0].StartAt != futureStart {
		t.Fatalf("slots = %v, want only future slot %v", slots, futureStart)
	}
	if repo.listScheduleFilter.From.Before(now.Add(2*time.Hour - time.Second)) {
		t.Fatalf("list from = %v, want at least two-hour booking lead time", repo.listScheduleFilter.From)
	}
	if repo.expiredScheduleReason == "" || repo.expiredScheduleCutoff.IsZero() {
		t.Fatal("unbooked near-start slots were not expired before public schedule list")
	}
}

func TestListGuideScheduleExpiresUnbookedSlotsBeforeBookingCutoff(t *testing.T) {
	actorUserID := uuid.New()
	now := time.Now().UTC()
	repo := &excursionRepoStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.ListGuideSchedule(context.Background(), ListGuideScheduleInput{
		ActorUserID: actorUserID,
		From:        now.Add(-24 * time.Hour),
		To:          now.Add(24 * time.Hour),
	})

	if err != nil {
		t.Fatalf("ListGuideSchedule() error = %v", err)
	}
	if repo.expiredScheduleReason == "" {
		t.Fatal("unbooked near-start slots were not expired before guide schedule list")
	}
	if repo.expiredScheduleCutoff.Before(now.Add(2*time.Hour - time.Second)) {
		t.Fatalf("expire cutoff = %v, want at least now + 2h", repo.expiredScheduleCutoff)
	}
}

func TestListMyGuideExcursionBookingsFiltersByGuideUser(t *testing.T) {
	actorUserID := uuid.New()
	repo := &excursionRepoStub{
		listBookingItems: []*model.ExcursionBookingListItem{
			{Booking: &model.ExcursionBooking{ID: uuid.New(), GuideUserID: actorUserID}},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	items, err := uc.ListMyGuideExcursionBookings(context.Background(), actorUserID, 25, 10)
	if err != nil {
		t.Fatalf("ListMyGuideExcursionBookings() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items len = %d, want 1", len(items))
	}
	if repo.listBookingFilter.GuideUserID == nil || *repo.listBookingFilter.GuideUserID != actorUserID {
		t.Fatalf("GuideUserID filter = %v, want %s", repo.listBookingFilter.GuideUserID, actorUserID)
	}
	if repo.listBookingFilter.TouristUserID != nil {
		t.Fatalf("TouristUserID filter = %v, want nil", repo.listBookingFilter.TouristUserID)
	}
	if repo.listBookingFilter.Limit != 25 || repo.listBookingFilter.Offset != 10 {
		t.Fatalf("pagination = (%d,%d), want (25,10)", repo.listBookingFilter.Limit, repo.listBookingFilter.Offset)
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
