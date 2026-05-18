package app

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
)

type ExcursionAggregate struct {
	Excursion          *model.Excursion
	Tags               []string
	LanguageCodes      []string
	IncludedItems      []model.ExcursionIncludedItem
	Itinerary          []*model.ExcursionItineraryItem
	CoverFileID        *uuid.UUID
	ProductCoverFileID *uuid.UUID
}

type ExcursionProductCardAggregate struct {
	Product *model.ExcursionProductCard
}

type ExcursionOfferAggregate struct {
	Offer         *model.ExcursionOffer
	LanguageCodes []string
	IncludedItems []model.ExcursionIncludedItem
	Itinerary     []*model.ExcursionItineraryItem
}

type ExcursionUseCase struct {
	repo          port.ExcursionRepository
	guideVerifier port.GuideVerifier
	fileManager   port.ExcursionCoverFileManager
	translator    port.ExcursionTranslator
}

const (
	excursionScheduleBookingLeadTime            = 2 * time.Hour
	excursionScheduleSetupLeadTime              = 3 * time.Hour
	excursionScheduleAutoCancelReasonNoBookings = "NO_BOOKINGS_BEFORE_START_2H"
)

func NewExcursionUseCase(
	repo port.ExcursionRepository,
	guideVerifier port.GuideVerifier,
	fileManager port.ExcursionCoverFileManager,
	translators ...port.ExcursionTranslator,
) *ExcursionUseCase {
	var translator port.ExcursionTranslator
	if len(translators) > 0 {
		translator = translators[0]
	}
	return &ExcursionUseCase{
		repo:          repo,
		guideVerifier: guideVerifier,
		fileManager:   fileManager,
		translator:    translator,
	}
}

type ExcursionItineraryItemInput struct {
	StartOffsetMinutes int
	DurationMinutes    *int
	Title              string
	Description        string
	Translations       model.ExcursionItineraryTranslations
}

type ExcursionIncludedItemInput struct {
	Text         string
	Translations model.ExcursionLocalizedText
}

type itineraryTranslationJob struct {
	itemIndex      int
	missingLocales []string
	sourceCopy     model.ExcursionItineraryLocalizedCopy
}

type CreateExcursionInput struct {
	ActorUserID         uuid.UUID
	LandmarkID          *uuid.UUID
	LandmarkName        *string
	CategorySlug        string
	ProductTranslations model.ExcursionTranslations
	Visibility          string
	DurationMinutes     int
	MaxGroupSize        int
	LanguageCodes       []string
	CountryCode         *string
	CityName            *string
	MeetingPoint        string
	Latitude            *float64
	Longitude           *float64
	MapURL              *string
	PriceAmount         float64
	Currency            string
	CoverFileID         *uuid.UUID
	ProductCoverFileID  *uuid.UUID
	IncludedItems       []ExcursionIncludedItemInput
	Itinerary           []ExcursionItineraryItemInput
}

type UpdateExcursionInput struct {
	ActorUserID         uuid.UUID
	ExcursionID         uuid.UUID
	LandmarkID          *uuid.UUID
	LandmarkName        *string
	CategorySlug        string
	ProductTranslations model.ExcursionTranslations
	Visibility          string
	DurationMinutes     int
	MaxGroupSize        int
	LanguageCodes       []string
	CountryCode         *string
	CityName            *string
	MeetingPoint        string
	Latitude            *float64
	Longitude           *float64
	MapURL              *string
	PriceAmount         float64
	Currency            string
	CoverFileID         *uuid.UUID
	ProductCoverFileID  *uuid.UUID
	IncludedItems       []ExcursionIncludedItemInput
	Itinerary           []ExcursionItineraryItemInput
}

type CreateExcursionBookingInput struct {
	ActorUserID    uuid.UUID
	ProductID      uuid.UUID
	OfferID        uuid.UUID
	ScheduleSlotID *uuid.UUID
	ScheduledFor   time.Time
	Adults         int
	Children       int
	IdempotencyKey *string
}

type UpdateExcursionBookingGuestsInput struct {
	ActorUserID uuid.UUID
	BookingID   uuid.UUID
	Adults      int
	Children    int
}

type CreateGuideScheduleSlotInput struct {
	ActorUserID uuid.UUID
	OfferID     uuid.UUID
	StartAt     time.Time
	Timezone    string
	Capacity    int
}

type UpdateGuideScheduleSlotInput struct {
	ActorUserID uuid.UUID
	SlotID      uuid.UUID
	OfferID     uuid.UUID
	StartAt     time.Time
	Timezone    string
	Capacity    int
}

type CreateGuideScheduleSeriesInput struct {
	ActorUserID     uuid.UUID
	OfferID         uuid.UUID
	StartsOn        time.Time
	EndsOn          *time.Time
	OccurrenceLimit *int
	StartTime       string
	Timezone        string
	Weekdays        []int
	Capacity        int
}

type ListGuideScheduleInput struct {
	ActorUserID uuid.UUID
	From        time.Time
	To          time.Time
}

type ListPublicExcursionScheduleInput struct {
	ProductID uuid.UUID
	OfferID   uuid.UUID
	From      time.Time
	To        time.Time
	Seats     int
}

type CreateExcursionReviewInput struct {
	ActorUserID uuid.UUID
	BookingID   uuid.UUID
	Rating      float64
	Comment     string
}

func (u *ExcursionUseCase) CreateExcursion(ctx context.Context, input CreateExcursionInput) (*ExcursionAggregate, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}

	permission, err := u.verifyGuide(ctx, input.ActorUserID)
	if err != nil {
		return nil, err
	}
	if !permission.Allowed {
		return nil, ErrGuideNotAllowed
	}
	if input.LandmarkID == nil || *input.LandmarkID == uuid.Nil {
		return nil, ErrExcursionAttractionRequired
	}
	exists, err := u.repo.HasActiveExcursionForGuideLandmark(ctx, permission.GuideUserID, *input.LandmarkID)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, model.ErrExcursionGuideLandmarkAlreadyExists
	}

	if err = u.validateCoverFiles(ctx, input.CoverFileID, input.ProductCoverFileID); err != nil {
		return nil, err
	}
	marketingCopy := attractionBasedExcursionCopy(input.LandmarkName)
	categorySlug := model.NormalizeSlug(input.CategorySlug)
	if categorySlug == "" {
		categorySlug = "sightseeing"
	}

	item, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:       permission.GuideProfileID,
		GuideUserID:          permission.GuideUserID,
		GuideRatingAvg:       permission.RatingAvg,
		GuideReviewsCount:    permission.ReviewsCount,
		GuideExperienceYears: permission.ExperienceYears,
		GuideDisplayName:     permission.DisplayName,
		GuideSearchText:      permission.GuideSearchText,
		LandmarkID:           input.LandmarkID,
		LandmarkName:         input.LandmarkName,
		Title:                marketingCopy.Title,
		Summary:              marketingCopy.Summary,
		Description:          marketingCopy.Description,
		Translations:         nil,
		CategorySlug:         categorySlug,
		ProductTranslations:  input.ProductTranslations,
		Visibility:           enum.ExcursionVisibility(strings.TrimSpace(input.Visibility)),
		DurationMinutes:      input.DurationMinutes,
		MaxGroupSize:         input.MaxGroupSize,
		CountryCode:          input.CountryCode,
		CityName:             input.CityName,
		MeetingPoint:         input.MeetingPoint,
		Latitude:             input.Latitude,
		Longitude:            input.Longitude,
		MapURL:               input.MapURL,
		PriceAmount:          input.PriceAmount,
		Currency:             input.Currency,
	})
	if err != nil {
		return nil, err
	}

	itinerary, err := u.translateItinerary(ctx, input.Itinerary)
	if err != nil {
		return nil, err
	}
	relations, err := buildRelations(item.ID, nil, input.LanguageCodes, input.IncludedItems, input.CoverFileID, input.ProductCoverFileID, itinerary)
	if err != nil {
		return nil, err
	}

	if err = u.repo.CreateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("create excursion aggregate: %w", err)
	}
	u.bindCoverFile(ctx, item.ID, input.ActorUserID, input.CoverFileID)
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeCreated, input.ActorUserID, map[string]any{"status": string(item.Status)})

	return &ExcursionAggregate{
		Excursion:          item,
		Tags:               relations.Tags,
		LanguageCodes:      relations.LanguageCodes,
		IncludedItems:      relations.IncludedItems,
		Itinerary:          relations.Itinerary,
		CoverFileID:        relations.CoverFileID,
		ProductCoverFileID: relations.ProductCoverFileID,
	}, nil
}

func (u *ExcursionUseCase) UpdateExcursion(ctx context.Context, input UpdateExcursionInput) (*ExcursionAggregate, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.ExcursionID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}

	item, err := u.repo.GetExcursionByID(ctx, input.ExcursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion by id: %w", err)
	}
	if item == nil {
		return nil, ErrExcursionNotFound
	}
	if !item.IsOwnedBy(input.ActorUserID) {
		return nil, ErrExcursionAccessDenied
	}
	permission, err := u.verifyGuide(ctx, input.ActorUserID)
	if err != nil {
		return nil, err
	}
	item.ApplyGuideSnapshot(
		permission.RatingAvg,
		permission.ReviewsCount,
		permission.ExperienceYears,
		permission.DisplayName,
		permission.GuideSearchText,
	)
	if err = u.validateCoverFiles(ctx, input.CoverFileID, input.ProductCoverFileID); err != nil {
		return nil, err
	}
	if item.LandmarkID == nil || *item.LandmarkID == uuid.Nil {
		return nil, ErrExcursionAttractionRequired
	}
	marketingCopy := attractionBasedExcursionCopy(item.LandmarkName)

	if err = item.ApplyUpdate(model.UpdateExcursionParams{
		LandmarkID:          item.LandmarkID,
		LandmarkName:        item.LandmarkName,
		Title:               marketingCopy.Title,
		Summary:             marketingCopy.Summary,
		Description:         marketingCopy.Description,
		Translations:        nil,
		CategorySlug:        item.CategorySlug,
		ProductTranslations: item.ProductTranslations,
		Visibility:          enum.ExcursionVisibility(strings.TrimSpace(input.Visibility)),
		DurationMinutes:     input.DurationMinutes,
		MaxGroupSize:        input.MaxGroupSize,
		CountryCode:         input.CountryCode,
		CityName:            input.CityName,
		MeetingPoint:        input.MeetingPoint,
		Latitude:            input.Latitude,
		Longitude:           input.Longitude,
		MapURL:              input.MapURL,
		PriceAmount:         input.PriceAmount,
		Currency:            input.Currency,
	}); err != nil {
		return nil, err
	}

	itinerary, err := u.translateItinerary(ctx, input.Itinerary)
	if err != nil {
		return nil, err
	}
	relations, err := buildRelations(item.ID, nil, input.LanguageCodes, input.IncludedItems, input.CoverFileID, input.ProductCoverFileID, itinerary)
	if err != nil {
		return nil, err
	}
	if item.Status == enum.ExcursionStatusPublished {
		if err = item.ValidatePublishable(model.PublishExcursionParams{LanguageCodes: relations.LanguageCodes, Itinerary: relations.Itinerary}); err != nil {
			return nil, err
		}
	}

	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("update excursion aggregate: %w", err)
	}
	u.bindCoverFile(ctx, item.ID, input.ActorUserID, input.CoverFileID)
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeUpdated, input.ActorUserID, map[string]any{"revision": item.Revision})

	return &ExcursionAggregate{
		Excursion:          item,
		Tags:               relations.Tags,
		LanguageCodes:      relations.LanguageCodes,
		IncludedItems:      relations.IncludedItems,
		Itinerary:          relations.Itinerary,
		CoverFileID:        relations.CoverFileID,
		ProductCoverFileID: relations.ProductCoverFileID,
	}, nil
}

func (u *ExcursionUseCase) PublishExcursion(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) (*ExcursionAggregate, error) {
	item, relations, err := u.getOwnedExcursionWithRelations(ctx, excursionID, actorUserID)
	if err != nil {
		return nil, err
	}
	permission, err := u.verifyGuide(ctx, actorUserID)
	if err != nil {
		return nil, err
	}
	item.ApplyGuideSnapshot(
		permission.RatingAvg,
		permission.ReviewsCount,
		permission.ExperienceYears,
		permission.DisplayName,
		permission.GuideSearchText,
	)
	if err = item.Publish(model.PublishExcursionParams{
		LanguageCodes: relations.LanguageCodes,
		Itinerary:     relations.Itinerary,
	}); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("publish excursion: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypePublished, actorUserID, map[string]any{"publishedAt": item.PublishedAt})

	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) ArchiveExcursion(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) (*ExcursionAggregate, error) {
	item, relations, err := u.getOwnedExcursionWithRelations(ctx, excursionID, actorUserID)
	if err != nil {
		return nil, err
	}
	if err = item.MoveToArchive(); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("archive excursion: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeArchived, actorUserID, map[string]any{"archivedAt": item.UpdatedAt})

	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) DeleteExcursion(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) error {
	item, relations, err := u.getOwnedExcursionWithRelations(ctx, excursionID, actorUserID)
	if err != nil {
		return err
	}
	if err = item.Archive(); err != nil {
		return err
	}
	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return fmt.Errorf("delete excursion: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeDeleted, actorUserID, map[string]any{"deletedAt": item.DeletedAt})
	return nil
}

func (u *ExcursionUseCase) GetPublicExcursion(ctx context.Context, excursionID uuid.UUID) (*ExcursionAggregate, error) {
	if excursionID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	item, err := u.repo.GetExcursionByID(ctx, excursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion by id: %w", err)
	}
	if item == nil || !item.IsPubliclyReadable() {
		return nil, ErrExcursionNotFound
	}
	return u.loadAggregate(ctx, item)
}

func (u *ExcursionUseCase) GetMyExcursion(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) (*ExcursionAggregate, error) {
	item, relations, err := u.getOwnedExcursionWithRelations(ctx, excursionID, actorUserID)
	if err != nil {
		return nil, err
	}
	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) ListExcursions(ctx context.Context, filter port.ExcursionFilter) ([]*ExcursionAggregate, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	filter.Statuses = []string{string(enum.ExcursionStatusPublished)}
	items, err := u.repo.ListExcursions(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list excursions: %w", err)
	}
	return u.loadAggregates(ctx, items)
}

func (u *ExcursionUseCase) ListExcursionProducts(ctx context.Context, filter port.ExcursionProductFilter) ([]*ExcursionProductCardAggregate, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	items, err := u.repo.ListExcursionProductCards(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list excursion products: %w", err)
	}
	return toProductCardAggregates(items), nil
}

func (u *ExcursionUseCase) GetExcursionProduct(ctx context.Context, productID uuid.UUID) (*ExcursionProductCardAggregate, error) {
	if productID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	item, err := u.repo.GetExcursionProductCardByID(ctx, productID)
	if err != nil {
		return nil, fmt.Errorf("get excursion product: %w", err)
	}
	if item == nil {
		return nil, ErrExcursionNotFound
	}
	return &ExcursionProductCardAggregate{Product: item}, nil
}

func (u *ExcursionUseCase) ListExcursionProductOffers(ctx context.Context, filter port.ExcursionOfferFilter) ([]*ExcursionOfferAggregate, error) {
	if filter.ProductID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	offers, err := u.repo.ListExcursionOffers(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list excursion offers: %w", err)
	}
	result := make([]*ExcursionOfferAggregate, 0, len(offers))
	for _, offer := range offers {
		if offer == nil {
			continue
		}
		relations, relErr := u.repo.LoadExcursionOfferRelations(ctx, offer.ID)
		if relErr != nil {
			return nil, fmt.Errorf("load excursion offer relations: %w", relErr)
		}
		result = append(result, &ExcursionOfferAggregate{
			Offer:         offer,
			LanguageCodes: relations.LanguageCodes,
			IncludedItems: relations.IncludedItems,
			Itinerary:     relations.Itinerary,
		})
	}
	return result, nil
}

func (u *ExcursionUseCase) ListGuideExcursionLanguageCodes(ctx context.Context, guideUserIDs []uuid.UUID) (map[uuid.UUID][]string, error) {
	normalizedIDs := uniqueUUIDs(guideUserIDs)
	if len(normalizedIDs) == 0 {
		return map[uuid.UUID][]string{}, nil
	}
	languages, err := u.repo.ListExcursionLanguageCodesByGuideUserIDs(ctx, normalizedIDs)
	if err != nil {
		return nil, fmt.Errorf("list guide excursion languages: %w", err)
	}
	return languages, nil
}

func (u *ExcursionUseCase) CreateGuideScheduleSlot(ctx context.Context, input CreateGuideScheduleSlotInput) (*model.ExcursionScheduleSlot, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.OfferID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	offer, err := u.getExcursionOfferForSchedule(ctx, input.OfferID)
	if err != nil {
		return nil, err
	}
	if offer == nil {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.GuideUserID != input.ActorUserID {
		return nil, ErrExcursionAccessDenied
	}
	if offer.DeletedAt != nil || offer.Status != enum.ExcursionStatusPublished {
		return nil, ErrExcursionNotPublished
	}
	capacity := input.Capacity
	if capacity <= 0 {
		capacity = offer.MaxGroupSize
	}
	if capacity > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionScheduleCapacity
	}
	startAt := input.StartAt.UTC()
	if !scheduleStartAllowsGuideSetup(startAt, time.Now().UTC()) {
		return nil, ErrExcursionScheduleStartTooSoon
	}
	slot, err := model.NewExcursionScheduleSlot(model.NewExcursionScheduleSlotParams{
		GuideProfileID:    offer.GuideProfileID,
		GuideUserID:       offer.GuideUserID,
		OfferID:           offer.ID,
		ProductID:         offer.ProductID,
		LegacyExcursionID: offer.LegacyExcursionID,
		StartAt:           startAt,
		EndAt:             startAt.Add(time.Duration(offer.DurationMinutes) * time.Minute),
		Timezone:          input.Timezone,
		Capacity:          capacity,
	})
	if err != nil {
		return nil, err
	}
	slot.Title = strings.TrimSpace(offer.Title)
	if err = u.repo.CreateExcursionScheduleSlot(ctx, slot); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleConflict) {
			return nil, ErrExcursionScheduleConflict
		}
		return nil, fmt.Errorf("create excursion schedule slot: %w", err)
	}
	return slot, nil
}

func (u *ExcursionUseCase) CreateGuideScheduleSeries(ctx context.Context, input CreateGuideScheduleSeriesInput) ([]*model.ExcursionScheduleSlot, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.OfferID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	offer, err := u.getExcursionOfferForSchedule(ctx, input.OfferID)
	if err != nil {
		return nil, err
	}
	if offer == nil {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.GuideUserID != input.ActorUserID {
		return nil, ErrExcursionAccessDenied
	}
	if offer.DeletedAt != nil || offer.Status != enum.ExcursionStatusPublished {
		return nil, ErrExcursionNotPublished
	}

	capacity := input.Capacity
	if capacity <= 0 {
		capacity = offer.MaxGroupSize
	}
	if capacity > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionScheduleCapacity
	}
	defaultCapacity := capacity
	limit := 12
	if input.OccurrenceLimit != nil && *input.OccurrenceLimit > 0 {
		limit = *input.OccurrenceLimit
	}
	if limit > 52 {
		limit = 52
	}
	until := input.StartsOn.AddDate(0, 0, limit*7)
	if input.EndsOn != nil {
		until = *input.EndsOn
	}
	starts, err := weeklyOccurrences(input.StartsOn, input.Weekdays, input.StartTime, offer.DurationMinutes, input.Timezone, until, limit)
	if err != nil {
		return nil, err
	}
	if len(starts) == 0 {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}

	now := time.Now().UTC()
	for _, startAt := range starts {
		if !scheduleStartAllowsGuideSetup(startAt, now) {
			return nil, ErrExcursionScheduleStartTooSoon
		}
	}
	series := &model.ExcursionScheduleSeries{
		ID:                uuid.New(),
		GuideProfileID:    offer.GuideProfileID,
		GuideUserID:       offer.GuideUserID,
		OfferID:           offer.ID,
		ProductID:         offer.ProductID,
		LegacyExcursionID: offer.LegacyExcursionID,
		Timezone:          strings.TrimSpace(input.Timezone),
		RecurrenceType:    enum.ExcursionScheduleRecurrenceTypeWeekly,
		Weekdays:          append([]int(nil), input.Weekdays...),
		StartsOn:          input.StartsOn,
		EndsOn:            input.EndsOn,
		OccurrenceLimit:   input.OccurrenceLimit,
		DefaultStartTime:  strings.TrimSpace(input.StartTime),
		DefaultCapacity:   &defaultCapacity,
		Status:            enum.ExcursionScheduleSeriesStatusActive,
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	if err = series.Validate(); err != nil {
		return nil, err
	}
	slots := make([]*model.ExcursionScheduleSlot, 0, len(starts))
	for _, startAt := range starts {
		slot, slotErr := model.NewExcursionScheduleSlot(model.NewExcursionScheduleSlotParams{
			SeriesID:          &series.ID,
			GuideProfileID:    offer.GuideProfileID,
			GuideUserID:       offer.GuideUserID,
			OfferID:           offer.ID,
			ProductID:         offer.ProductID,
			LegacyExcursionID: offer.LegacyExcursionID,
			StartAt:           startAt,
			EndAt:             startAt.Add(time.Duration(offer.DurationMinutes) * time.Minute),
			Timezone:          input.Timezone,
			Capacity:          capacity,
		})
		if slotErr != nil {
			return nil, slotErr
		}
		slot.Title = strings.TrimSpace(offer.Title)
		slots = append(slots, slot)
	}
	if err = u.repo.CreateExcursionScheduleSeriesWithSlots(ctx, series, slots); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleConflict) {
			return nil, ErrExcursionScheduleConflict
		}
		return nil, fmt.Errorf("create excursion schedule series: %w", err)
	}
	return slots, nil
}

func (u *ExcursionUseCase) getExcursionOfferForSchedule(ctx context.Context, offerOrLegacyExcursionID uuid.UUID) (*model.ExcursionOffer, error) {
	offer, err := u.repo.GetExcursionOfferByID(ctx, offerOrLegacyExcursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer: %w", err)
	}
	if offer != nil {
		return offer, nil
	}
	offer, err = u.repo.GetExcursionOfferByLegacyExcursionID(ctx, offerOrLegacyExcursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer by legacy excursion id: %w", err)
	}
	return offer, nil
}

func (u *ExcursionUseCase) ListGuideSchedule(ctx context.Context, input ListGuideScheduleInput) ([]*model.ExcursionScheduleSlot, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.From.IsZero() || input.To.IsZero() || !input.From.Before(input.To) {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}
	now := time.Now().UTC()
	if err := u.expireUnbookedExcursionScheduleSlots(ctx, now); err != nil {
		return nil, err
	}
	guideUserID := input.ActorUserID
	items, err := u.repo.ListExcursionScheduleSlots(ctx, port.ExcursionScheduleFilter{
		GuideUserID: &guideUserID,
		From:        input.From,
		To:          input.To,
		Limit:       500,
	})
	if err != nil {
		return nil, fmt.Errorf("list excursion schedule slots: %w", err)
	}
	return items, nil
}

func (u *ExcursionUseCase) ListPublicExcursionSchedule(ctx context.Context, input ListPublicExcursionScheduleInput) ([]*model.ExcursionScheduleSlot, error) {
	if input.ProductID == uuid.Nil || input.OfferID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	if input.From.IsZero() || input.To.IsZero() || !input.From.Before(input.To) {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}
	seats := input.Seats
	if seats <= 0 {
		seats = 1
	}
	offer, err := u.repo.GetExcursionOfferByID(ctx, input.OfferID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer: %w", err)
	}
	if offer == nil || offer.ProductID != input.ProductID {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.DeletedAt != nil ||
		offer.Status != enum.ExcursionStatusPublished ||
		offer.Visibility != enum.ExcursionVisibilityPublic {
		return nil, ErrExcursionOfferNotBookable
	}
	if seats > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionBookingGuests
	}
	now := time.Now().UTC()
	if err := u.expireUnbookedExcursionScheduleSlots(ctx, now); err != nil {
		return nil, err
	}
	from := input.From.UTC()
	cutoff := excursionScheduleBookingCutoff(now)
	if from.Before(cutoff) {
		from = cutoff
	}
	if !from.Before(input.To.UTC()) {
		return []*model.ExcursionScheduleSlot{}, nil
	}

	productID := input.ProductID
	offerID := input.OfferID
	items, err := u.repo.ListExcursionScheduleSlots(ctx, port.ExcursionScheduleFilter{
		ProductID: &productID,
		OfferID:   &offerID,
		From:      from,
		To:        input.To,
		Statuses: []enum.ExcursionScheduleSlotStatus{
			enum.ExcursionScheduleSlotStatusAvailable,
			enum.ExcursionScheduleSlotStatusBooked,
		},
		Limit: 500,
	})
	if err != nil {
		return nil, fmt.Errorf("list public excursion schedule slots: %w", err)
	}

	result := make([]*model.ExcursionScheduleSlot, 0, len(items))
	for _, slot := range items {
		if !slotCanAcceptExcursionBooking(slot, seats, now) {
			continue
		}
		result = append(result, slot)
	}
	return result, nil
}

func (u *ExcursionUseCase) UpdateGuideScheduleSlot(ctx context.Context, input UpdateGuideScheduleSlotInput) (*model.ExcursionScheduleSlot, error) {
	slot, err := u.getOwnedScheduleSlot(ctx, input.ActorUserID, input.SlotID)
	if err != nil {
		return nil, err
	}
	if slot.BookedSeats > 0 {
		return nil, ErrExcursionScheduleUnavailable
	}

	offerID := input.OfferID
	if offerID == uuid.Nil {
		offerID = slot.OfferID
	}
	offer, err := u.getExcursionOfferForSchedule(ctx, offerID)
	if err != nil {
		return nil, err
	}
	if offer == nil {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.GuideUserID != input.ActorUserID {
		return nil, ErrExcursionAccessDenied
	}
	if offer.DeletedAt != nil || offer.Status != enum.ExcursionStatusPublished {
		return nil, ErrExcursionNotPublished
	}

	startAt := input.StartAt
	if startAt.IsZero() {
		startAt = slot.StartAt
	}
	startAt = startAt.UTC()
	if !scheduleStartAllowsGuideSetup(startAt, time.Now().UTC()) {
		return nil, ErrExcursionScheduleStartTooSoon
	}
	timezone := strings.TrimSpace(input.Timezone)
	if timezone == "" {
		timezone = slot.Timezone
	}
	capacity := input.Capacity
	if capacity <= 0 {
		capacity = offer.MaxGroupSize
	}
	if capacity > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionScheduleCapacity
	}

	slot.OfferID = offer.ID
	slot.ProductID = offer.ProductID
	slot.LegacyExcursionID = model.NormalizeUUIDPointer(offer.LegacyExcursionID)
	slot.StartAt = startAt
	slot.EndAt = startAt.Add(time.Duration(offer.DurationMinutes) * time.Minute).UTC()
	slot.Timezone = timezone
	slot.Capacity = capacity
	slot.Title = strings.TrimSpace(offer.Title)
	slot.UpdatedAt = time.Now().UTC()

	if err = slot.Validate(); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionScheduleSlot(ctx, slot); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleConflict) {
			return nil, ErrExcursionScheduleConflict
		}
		if errors.Is(err, port.ErrExcursionScheduleUnavailable) {
			return nil, ErrExcursionScheduleUnavailable
		}
		return nil, fmt.Errorf("update excursion schedule slot: %w", err)
	}
	return slot, nil
}

func (u *ExcursionUseCase) CloseGuideScheduleSlot(ctx context.Context, actorUserID uuid.UUID, slotID uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	slot, err := u.getOwnedScheduleSlot(ctx, actorUserID, slotID)
	if err != nil {
		return nil, err
	}
	slot.Close()
	if err = u.repo.UpdateExcursionScheduleSlot(ctx, slot); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleConflict) {
			return nil, ErrExcursionScheduleConflict
		}
		return nil, fmt.Errorf("close excursion schedule slot: %w", err)
	}
	return slot, nil
}

func (u *ExcursionUseCase) CancelGuideScheduleSlot(ctx context.Context, actorUserID uuid.UUID, slotID uuid.UUID, reason string) (*model.ExcursionScheduleSlot, error) {
	slot, err := u.getOwnedScheduleSlot(ctx, actorUserID, slotID)
	if err != nil {
		return nil, err
	}
	if err = slot.Cancel(reason); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionScheduleSlot(ctx, slot); err != nil {
		return nil, fmt.Errorf("cancel excursion schedule slot: %w", err)
	}
	return slot, nil
}

func (u *ExcursionUseCase) DeleteGuideScheduleSlot(ctx context.Context, actorUserID uuid.UUID, slotID uuid.UUID) error {
	slot, err := u.getOwnedScheduleSlot(ctx, actorUserID, slotID)
	if err != nil {
		return err
	}
	if !slot.CanHardDelete() {
		return model.ErrExcursionScheduleBookedDeleteDenied
	}
	if err = u.repo.DeleteExcursionScheduleSlot(ctx, slotID, actorUserID); err != nil {
		return fmt.Errorf("delete excursion schedule slot: %w", err)
	}
	return nil
}

func (u *ExcursionUseCase) expireUnbookedExcursionScheduleSlots(ctx context.Context, now time.Time) error {
	if err := u.repo.ExpireUnbookedExcursionScheduleSlots(
		ctx,
		excursionScheduleBookingCutoff(now),
		excursionScheduleAutoCancelReasonNoBookings,
	); err != nil {
		return fmt.Errorf("expire unbooked excursion schedule slots: %w", err)
	}
	return nil
}

func slotCanAcceptExcursionBooking(slot *model.ExcursionScheduleSlot, seats int, now time.Time) bool {
	if slot == nil || !slot.IsBookable() {
		return false
	}
	requestedSeats := seats
	if requestedSeats <= 0 {
		requestedSeats = 1
	}
	return scheduleStartAllowsExcursionBooking(slot.StartAt, now) &&
		slot.BookedSeats+requestedSeats <= slot.Capacity
}

func scheduleStartAllowsExcursionBooking(startAt time.Time, now time.Time) bool {
	return !startAt.UTC().Before(excursionScheduleBookingCutoff(now))
}

func excursionScheduleBookingCutoff(now time.Time) time.Time {
	return now.UTC().Add(excursionScheduleBookingLeadTime)
}

func scheduleStartAllowsGuideSetup(startAt time.Time, now time.Time) bool {
	if startAt.IsZero() {
		return false
	}
	return !startAt.UTC().Before(now.UTC().Add(excursionScheduleSetupLeadTime))
}

func (u *ExcursionUseCase) getOwnedScheduleSlot(ctx context.Context, actorUserID uuid.UUID, slotID uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if slotID == uuid.Nil {
		return nil, model.ErrInvalidExcursionScheduleID
	}
	slot, err := u.repo.GetExcursionScheduleSlotByID(ctx, slotID)
	if err != nil {
		return nil, fmt.Errorf("get excursion schedule slot: %w", err)
	}
	if slot == nil {
		return nil, ErrExcursionNotFound
	}
	if slot.GuideUserID != actorUserID {
		return nil, ErrExcursionAccessDenied
	}
	return slot, nil
}

func (u *ExcursionUseCase) CreateExcursionBooking(ctx context.Context, input CreateExcursionBookingInput) (*model.ExcursionBooking, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.ProductID == uuid.Nil || input.OfferID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	input.IdempotencyKey = model.NormalizeOptionalString(input.IdempotencyKey)
	existing, err := u.findExistingExcursionBookingForIdempotentRequest(ctx, input)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}
	offer, err := u.repo.GetExcursionOfferByID(ctx, input.OfferID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer: %w", err)
	}
	if offer == nil || offer.ProductID != input.ProductID {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.DeletedAt != nil ||
		offer.Status != enum.ExcursionStatusPublished ||
		offer.Visibility != enum.ExcursionVisibilityPublic {
		return nil, ErrExcursionOfferNotBookable
	}
	if offer.GuideUserID == input.ActorUserID {
		return nil, ErrExcursionAccessDenied
	}
	totalSeats := input.Adults + input.Children
	if totalSeats > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionBookingGuests
	}
	now := time.Now().UTC()
	if input.ScheduleSlotID != nil && *input.ScheduleSlotID != uuid.Nil {
		slot, err := u.repo.GetExcursionScheduleSlotByID(ctx, *input.ScheduleSlotID)
		if err != nil {
			return nil, fmt.Errorf("get excursion schedule slot: %w", err)
		}
		if slot == nil || slot.ProductID != input.ProductID || slot.OfferID != input.OfferID {
			return nil, ErrExcursionNotFound
		}
		if !slotCanAcceptExcursionBooking(slot, totalSeats, now) {
			return nil, ErrExcursionScheduleUnavailable
		}
		input.ScheduledFor = slot.StartAt
	}
	if !input.ScheduledFor.IsZero() && !scheduleStartAllowsExcursionBooking(input.ScheduledFor, now) {
		return nil, ErrExcursionScheduleUnavailable
	}

	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:         offer.ProductID,
		OfferID:           offer.ID,
		ScheduleSlotID:    input.ScheduleSlotID,
		LegacyExcursionID: offer.LegacyExcursionID,
		GuideProfileID:    offer.GuideProfileID,
		GuideUserID:       offer.GuideUserID,
		TouristUserID:     input.ActorUserID,
		ScheduledFor:      input.ScheduledFor,
		Adults:            input.Adults,
		Children:          input.Children,
		UnitPriceAmount:   offer.PriceAmount,
		Currency:          offer.Currency,
		IdempotencyKey:    input.IdempotencyKey,
	})
	if err != nil {
		return nil, err
	}
	if err = u.repo.CreateExcursionBooking(ctx, booking); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleUnavailable) {
			return nil, ErrExcursionScheduleUnavailable
		}
		if errors.Is(err, port.ErrExcursionBookingIdempotencyConflict) {
			existing, findErr := u.findExistingExcursionBookingForIdempotentRequest(ctx, input)
			if findErr != nil {
				return nil, findErr
			}
			if existing != nil {
				return existing, nil
			}
		}
		return nil, fmt.Errorf("create excursion booking: %w", err)
	}
	return booking, nil
}

func (u *ExcursionUseCase) findExistingExcursionBookingForIdempotentRequest(ctx context.Context, input CreateExcursionBookingInput) (*model.ExcursionBooking, error) {
	idempotencyKey := model.NormalizeOptionalString(input.IdempotencyKey)
	if idempotencyKey == nil {
		return nil, nil
	}
	booking, err := u.repo.GetExcursionBookingByTouristIDAndIdempotencyKey(ctx, input.ActorUserID, *idempotencyKey)
	if err != nil {
		return nil, fmt.Errorf("get excursion booking by idempotency key: %w", err)
	}
	if booking == nil {
		return nil, nil
	}
	if !excursionBookingMatchesCreateInput(booking, input) {
		return nil, ErrExcursionBookingIdempotencyConflict
	}
	return booking, nil
}

func excursionBookingMatchesCreateInput(booking *model.ExcursionBooking, input CreateExcursionBookingInput) bool {
	if booking == nil {
		return false
	}
	if booking.TouristUserID != input.ActorUserID ||
		booking.ProductID != input.ProductID ||
		booking.OfferID != input.OfferID ||
		booking.Adults != input.Adults ||
		booking.Children != input.Children {
		return false
	}
	if input.ScheduleSlotID != nil && *input.ScheduleSlotID != uuid.Nil {
		return booking.ScheduleSlotID != nil && *booking.ScheduleSlotID == *input.ScheduleSlotID
	}
	if booking.ScheduleSlotID != nil {
		return false
	}
	return !input.ScheduledFor.IsZero() && booking.ScheduledFor.Equal(input.ScheduledFor.UTC())
}

func (u *ExcursionUseCase) ListMyExcursionBookings(ctx context.Context, actorUserID uuid.UUID, limit int, offset int) ([]*model.ExcursionBookingListItem, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	touristUserID := actorUserID
	items, err := u.repo.ListExcursionBookings(ctx, port.ExcursionBookingFilter{
		TouristUserID: &touristUserID,
		Limit:         limit,
		Offset:        offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list excursion bookings: %w", err)
	}
	return items, nil
}

func (u *ExcursionUseCase) ListMyGuideExcursionBookings(ctx context.Context, actorUserID uuid.UUID, limit int, offset int) ([]*model.ExcursionBookingListItem, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	guideUserID := actorUserID
	items, err := u.repo.ListExcursionBookings(ctx, port.ExcursionBookingFilter{
		GuideUserID: &guideUserID,
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list guide excursion bookings: %w", err)
	}
	return items, nil
}

func (u *ExcursionUseCase) UpdateExcursionBookingGuests(ctx context.Context, input UpdateExcursionBookingGuestsInput) (*model.ExcursionBooking, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.BookingID == uuid.Nil {
		return nil, model.ErrInvalidExcursionBookingID
	}
	booking, err := u.repo.GetExcursionBookingByID(ctx, input.BookingID)
	if err != nil {
		return nil, fmt.Errorf("get excursion booking: %w", err)
	}
	if booking == nil || booking.TouristUserID != input.ActorUserID {
		return nil, ErrExcursionBookingNotFound
	}
	if booking.Status != enum.ExcursionBookingStatusRequested ||
		booking.CancelledAt != nil ||
		!booking.ScheduledFor.After(time.Now().UTC()) {
		return nil, ErrExcursionBookingNotEditable
	}

	offer, err := u.repo.GetExcursionOfferByID(ctx, booking.OfferID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer: %w", err)
	}
	if offer == nil || offer.ProductID != booking.ProductID {
		return nil, ErrExcursionOfferNotFound
	}
	if input.Adults+input.Children > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionBookingGuests
	}

	oldSeats := booking.TotalSeats
	seatDelta := input.Adults + input.Children - oldSeats
	if seatDelta > 0 && booking.ScheduleSlotID != nil {
		now := time.Now().UTC()
		slot, err := u.repo.GetExcursionScheduleSlotByID(ctx, *booking.ScheduleSlotID)
		if err != nil {
			return nil, fmt.Errorf("get excursion schedule slot: %w", err)
		}
		if slot == nil || slot.ProductID != booking.ProductID || slot.OfferID != booking.OfferID {
			return nil, ErrExcursionNotFound
		}
		if !slotCanAcceptExcursionBooking(slot, seatDelta, now) {
			return nil, ErrExcursionScheduleUnavailable
		}
	}

	if err := booking.UpdateGuests(input.Adults, input.Children); err != nil {
		return nil, err
	}
	if err := u.repo.UpdateExcursionBookingGuests(ctx, booking, seatDelta); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleUnavailable) {
			return nil, ErrExcursionScheduleUnavailable
		}
		return nil, fmt.Errorf("update excursion booking guests: %w", err)
	}
	return booking, nil
}

func (u *ExcursionUseCase) CreateExcursionReview(ctx context.Context, input CreateExcursionReviewInput) (*model.ExcursionReview, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.BookingID == uuid.Nil {
		return nil, model.ErrInvalidExcursionBookingID
	}
	booking, err := u.repo.GetExcursionBookingByID(ctx, input.BookingID)
	if err != nil {
		return nil, fmt.Errorf("get excursion booking: %w", err)
	}
	if booking == nil || booking.TouristUserID != input.ActorUserID {
		return nil, ErrExcursionBookingNotFound
	}
	if booking.Status != enum.ExcursionBookingStatusRequested ||
		booking.CancelledAt != nil ||
		booking.ScheduledFor.After(time.Now().UTC()) {
		return nil, ErrExcursionBookingNotReviewable
	}
	existing, err := u.repo.GetExcursionReviewByBookingID(ctx, booking.ID)
	if err != nil {
		return nil, fmt.Errorf("get excursion review: %w", err)
	}
	if existing != nil {
		return nil, model.ErrExcursionReviewAlreadyExists
	}

	review, err := model.NewExcursionReview(model.NewExcursionReviewParams{
		Booking: booking,
		Rating:  input.Rating,
		Comment: input.Comment,
	})
	if err != nil {
		return nil, err
	}
	if err = u.repo.CreateExcursionReview(ctx, review); err != nil {
		return nil, fmt.Errorf("create excursion review: %w", err)
	}
	return review, nil
}

func (u *ExcursionUseCase) ListExcursionReviews(ctx context.Context, filter port.ExcursionReviewFilter) ([]*model.ExcursionReview, error) {
	if filter.ProductID == nil && filter.LandmarkID == nil {
		return nil, ErrInvalidExcursionID
	}
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	items, err := u.repo.ListExcursionReviews(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list excursion reviews: %w", err)
	}
	return items, nil
}

func (u *ExcursionUseCase) ListMyExcursions(ctx context.Context, actorUserID uuid.UUID, limit int, offset int, statuses []string) ([]*ExcursionAggregate, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	filter := port.ExcursionFilter{
		GuideUserID: &actorUserID,
		Statuses:    statuses,
		Limit:       limit,
		Offset:      offset,
	}
	items, err := u.repo.ListExcursions(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list my excursions: %w", err)
	}
	return u.loadAggregates(ctx, items)
}

func (u *ExcursionUseCase) getOwnedExcursionWithRelations(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) (*model.Excursion, port.ExcursionRelations, error) {
	if actorUserID == uuid.Nil {
		return nil, port.ExcursionRelations{}, ErrInvalidActorUserID
	}
	if excursionID == uuid.Nil {
		return nil, port.ExcursionRelations{}, ErrInvalidExcursionID
	}
	item, err := u.repo.GetExcursionByID(ctx, excursionID)
	if err != nil {
		return nil, port.ExcursionRelations{}, fmt.Errorf("get excursion by id: %w", err)
	}
	if item == nil {
		return nil, port.ExcursionRelations{}, ErrExcursionNotFound
	}
	if !item.IsOwnedBy(actorUserID) {
		return nil, port.ExcursionRelations{}, ErrExcursionAccessDenied
	}
	relations, err := u.repo.LoadExcursionRelations(ctx, excursionID)
	if err != nil {
		return nil, port.ExcursionRelations{}, fmt.Errorf("load excursion relations: %w", err)
	}
	return item, relations, nil
}

func (u *ExcursionUseCase) loadAggregate(ctx context.Context, item *model.Excursion) (*ExcursionAggregate, error) {
	relations, err := u.repo.LoadExcursionRelations(ctx, item.ID)
	if err != nil {
		return nil, fmt.Errorf("load excursion relations: %w", err)
	}
	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) loadAggregates(ctx context.Context, items []*model.Excursion) ([]*ExcursionAggregate, error) {
	result := make([]*ExcursionAggregate, 0, len(items))
	for _, item := range items {
		if item == nil {
			continue
		}
		aggregate, err := u.loadAggregate(ctx, item)
		if err != nil {
			return nil, err
		}
		result = append(result, aggregate)
	}
	return result, nil
}

func toProductCardAggregates(items []*model.ExcursionProductCard) []*ExcursionProductCardAggregate {
	result := make([]*ExcursionProductCardAggregate, 0, len(items))
	for _, item := range items {
		if item == nil {
			continue
		}
		result = append(result, &ExcursionProductCardAggregate{Product: item})
	}
	return result
}

func (u *ExcursionUseCase) verifyGuide(ctx context.Context, actorUserID uuid.UUID) (port.GuideExcursionPermission, error) {
	if u.guideVerifier == nil {
		return port.GuideExcursionPermission{
			GuideProfileID: actorUserID,
			GuideUserID:    actorUserID,
			Allowed:        true,
		}, nil
	}
	permission, err := u.guideVerifier.VerifyExcursionGuide(ctx, actorUserID)
	if err != nil {
		return port.GuideExcursionPermission{}, err
	}
	if !permission.Allowed || permission.GuideProfileID == uuid.Nil || permission.GuideUserID == uuid.Nil {
		return port.GuideExcursionPermission{}, ErrGuideNotAllowed
	}
	return permission, nil
}

func (u *ExcursionUseCase) validateCoverFile(ctx context.Context, fileID *uuid.UUID) error {
	if fileID == nil || *fileID == uuid.Nil || u.fileManager == nil {
		return nil
	}
	return u.fileManager.ValidateExcursionCoverFile(ctx, *fileID)
}

func (u *ExcursionUseCase) validateCoverFiles(ctx context.Context, fileIDs ...*uuid.UUID) error {
	seen := make(map[uuid.UUID]struct{}, len(fileIDs))
	for _, fileID := range fileIDs {
		if fileID == nil || *fileID == uuid.Nil {
			continue
		}
		if _, ok := seen[*fileID]; ok {
			continue
		}
		seen[*fileID] = struct{}{}
		if err := u.validateCoverFile(ctx, fileID); err != nil {
			return err
		}
	}
	return nil
}

func (u *ExcursionUseCase) bindCoverFile(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID, fileID *uuid.UUID) {
	if fileID == nil || *fileID == uuid.Nil || u.fileManager == nil {
		return
	}
	_ = u.fileManager.BindExcursionCoverFile(ctx, *fileID, excursionID, actorUserID)
}

func (u *ExcursionUseCase) recordEvent(ctx context.Context, excursionID uuid.UUID, eventType enum.ExcursionEventType, actorUserID uuid.UUID, payload any) {
	actor := actorUserID
	event, err := model.NewExcursionEvent(model.NewExcursionEventParams{
		ExcursionID: excursionID,
		EventType:   eventType,
		ActorUserID: &actor,
		Payload:     payload,
	})
	if err != nil {
		return
	}
	_ = u.repo.CreateExcursionEvent(ctx, event)
}

var excursionTranslationLocales = []string{"en", "ru", "kk"}

func (u *ExcursionUseCase) translateItinerary(ctx context.Context, itinerary []ExcursionItineraryItemInput) ([]ExcursionItineraryItemInput, error) {
	if len(itinerary) == 0 {
		return itinerary, nil
	}

	result := make([]ExcursionItineraryItemInput, len(itinerary))
	copy(result, itinerary)
	jobsBySource := make(map[string][]itineraryTranslationJob)

	for index := range result {
		translations := model.NormalizeExcursionItineraryTranslations(result[index].Translations)
		sourceLocale, sourceCopy := chooseItinerarySourceCopy(result[index], translations)
		if sourceLocale == "" {
			result[index].Translations = translations
			continue
		}

		if translations == nil {
			translations = make(model.ExcursionItineraryTranslations, len(excursionTranslationLocales))
		}
		translations[sourceLocale] = sourceCopy

		missingLocales := missingItineraryTranslationLocales(sourceLocale, translations)
		if len(missingLocales) > 0 {
			jobsBySource[sourceLocale] = append(jobsBySource[sourceLocale], itineraryTranslationJob{
				itemIndex:      index,
				missingLocales: missingLocales,
				sourceCopy:     sourceCopy,
			})
		}

		result[index].Translations = model.NormalizeExcursionItineraryTranslations(translations)
	}

	if u.translator == nil || len(jobsBySource) == 0 {
		return result, nil
	}

	for sourceLocale, jobs := range jobsBySource {
		translated, err := u.translator.TranslateTexts(ctx, port.TranslationRequest{
			SourceLocale:  sourceLocale,
			TargetLocales: uniqueMissingLocales(jobs),
			Texts:         itineraryTranslationTexts(jobs),
		})
		if err != nil {
			return nil, fmt.Errorf("%w: %v", ErrExcursionTranslationFailed, err)
		}
		applyItineraryTranslationJobs(result, jobs, translated)
	}

	for index := range result {
		translations := model.NormalizeExcursionItineraryTranslations(result[index].Translations)
		sourceLocale, _ := chooseItinerarySourceCopy(result[index], translations)
		if sourceLocale != "" && len(missingItineraryTranslationLocales(sourceLocale, translations)) > 0 {
			return nil, ErrExcursionTranslationFailed
		}
		result[index].Translations = translations
	}

	return result, nil
}

func chooseItinerarySourceCopy(
	input ExcursionItineraryItemInput,
	translations model.ExcursionItineraryTranslations,
) (string, model.ExcursionItineraryLocalizedCopy) {
	for _, locale := range excursionTranslationLocales {
		copy, ok := translations[locale]
		if !ok || (strings.TrimSpace(copy.Title) == "" && strings.TrimSpace(copy.Description) == "") {
			continue
		}
		return locale, fillItineraryCopyFromBase(input, copy)
	}

	if len(translations) == 0 {
		return "", model.ExcursionItineraryLocalizedCopy{}
	}
	locales := make([]string, 0, len(translations))
	for locale := range translations {
		locales = append(locales, locale)
	}
	sort.Strings(locales)
	for _, locale := range locales {
		normalizedLocale := normalizeExcursionTranslationLocale(locale)
		if normalizedLocale == "" {
			continue
		}
		copy := fillItineraryCopyFromBase(input, translations[locale])
		if strings.TrimSpace(copy.Title) != "" || strings.TrimSpace(copy.Description) != "" {
			return normalizedLocale, copy
		}
	}
	return "", model.ExcursionItineraryLocalizedCopy{}
}

func fillItineraryCopyFromBase(
	input ExcursionItineraryItemInput,
	copy model.ExcursionItineraryLocalizedCopy,
) model.ExcursionItineraryLocalizedCopy {
	title := strings.Join(strings.Fields(strings.TrimSpace(copy.Title)), " ")
	if title == "" {
		title = strings.Join(strings.Fields(strings.TrimSpace(input.Title)), " ")
	}
	description := strings.TrimSpace(copy.Description)
	if description == "" {
		description = strings.TrimSpace(input.Description)
	}
	return model.ExcursionItineraryLocalizedCopy{Title: title, Description: description}
}

func missingItineraryTranslationLocales(
	sourceLocale string,
	translations model.ExcursionItineraryTranslations,
) []string {
	missing := make([]string, 0, len(excursionTranslationLocales)-1)
	for _, locale := range excursionTranslationLocales {
		if locale == sourceLocale {
			continue
		}
		copy := translations[locale]
		if strings.TrimSpace(copy.Title) == "" || strings.TrimSpace(copy.Description) == "" {
			missing = append(missing, locale)
		}
	}
	return missing
}

func uniqueMissingLocales(jobs []itineraryTranslationJob) []string {
	seen := make(map[string]struct{}, len(excursionTranslationLocales))
	result := make([]string, 0, len(excursionTranslationLocales))
	for _, job := range jobs {
		for _, locale := range job.missingLocales {
			if _, ok := seen[locale]; ok {
				continue
			}
			seen[locale] = struct{}{}
			result = append(result, locale)
		}
	}
	sort.Strings(result)
	return result
}

func itineraryTranslationTexts(jobs []itineraryTranslationJob) []string {
	texts := make([]string, 0, len(jobs)*2)
	for _, job := range jobs {
		texts = append(texts, job.sourceCopy.Title, job.sourceCopy.Description)
	}
	return texts
}

func applyItineraryTranslationJobs(
	items []ExcursionItineraryItemInput,
	jobs []itineraryTranslationJob,
	result port.TranslationResult,
) {
	for jobIndex, job := range jobs {
		if job.itemIndex < 0 || job.itemIndex >= len(items) {
			continue
		}
		translations := model.NormalizeExcursionItineraryTranslations(items[job.itemIndex].Translations)
		if translations == nil {
			translations = make(model.ExcursionItineraryTranslations, len(excursionTranslationLocales))
		}
		for _, locale := range job.missingLocales {
			texts := result.Translations[locale]
			titleIndex := jobIndex * 2
			descriptionIndex := titleIndex + 1
			if len(texts) <= descriptionIndex {
				continue
			}
			copy := translations[locale]
			title := strings.Join(strings.Fields(strings.TrimSpace(texts[titleIndex])), " ")
			description := strings.TrimSpace(texts[descriptionIndex])
			if title != "" {
				copy.Title = title
			}
			if description != "" {
				copy.Description = description
			}
			translations[locale] = copy
		}
		items[job.itemIndex].Translations = model.NormalizeExcursionItineraryTranslations(translations)
	}
}

func normalizeExcursionTranslationLocale(value string) string {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if index := strings.IndexAny(normalized, "-_"); index >= 0 {
		normalized = normalized[:index]
	}
	for _, locale := range excursionTranslationLocales {
		if normalized == locale {
			return normalized
		}
	}
	return ""
}

func buildRelations(
	excursionID uuid.UUID,
	tags []string,
	languageCodes []string,
	includedItems []ExcursionIncludedItemInput,
	coverFileID *uuid.UUID,
	productCoverFileID *uuid.UUID,
	itinerary []ExcursionItineraryItemInput,
) (port.ExcursionRelations, error) {
	items := make([]*model.ExcursionItineraryItem, 0, len(itinerary))
	for index, input := range itinerary {
		sortOrder := index
		item, err := model.NewExcursionItineraryItem(model.NewExcursionItineraryItemParams{
			ExcursionID:        excursionID,
			SortOrder:          sortOrder,
			StartOffsetMinutes: input.StartOffsetMinutes,
			DurationMinutes:    input.DurationMinutes,
			Title:              input.Title,
			Description:        input.Description,
			Translations:       input.Translations,
		})
		if err != nil {
			return port.ExcursionRelations{}, err
		}
		items = append(items, item)
	}

	relations := port.ExcursionRelations{
		Tags:               normalizeUniqueLower(tags),
		LanguageCodes:      normalizeUniqueLower(languageCodes),
		Itinerary:          items,
		CoverFileID:        normalizeUUIDPtr(coverFileID),
		ProductCoverFileID: normalizeUUIDPtr(productCoverFileID),
	}
	normalizedIncludedItems, err := normalizeIncludedItems(includedItems)
	if err != nil {
		return port.ExcursionRelations{}, err
	}
	relations.IncludedItems = normalizedIncludedItems
	return relations, nil
}

func normalizeUniqueLower(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		normalized := strings.ToLower(strings.TrimSpace(value))
		if normalized == "" {
			continue
		}
		if _, ok := seen[normalized]; ok {
			continue
		}
		seen[normalized] = struct{}{}
		result = append(result, normalized)
	}
	sort.Strings(result)
	return result
}

func uniqueUUIDs(values []uuid.UUID) []uuid.UUID {
	result := make([]uuid.UUID, 0, len(values))
	seen := make(map[uuid.UUID]struct{}, len(values))
	for _, value := range values {
		if value == uuid.Nil {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func weeklyOccurrences(startDate time.Time, weekdays []int, startClock string, durationMinutes int, timezone string, until time.Time, maxOccurrences int) ([]time.Time, error) {
	if durationMinutes <= 0 || maxOccurrences <= 0 {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}
	loc, err := time.LoadLocation(strings.TrimSpace(timezone))
	if err != nil {
		return nil, model.ErrInvalidExcursionScheduleTimezone
	}
	clock, err := time.Parse("15:04", strings.TrimSpace(startClock))
	if err != nil {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}
	weekdaySet := make(map[int]struct{}, len(weekdays))
	for _, weekday := range weekdays {
		if weekday < 1 || weekday > 7 {
			return nil, model.ErrInvalidExcursionScheduleInterval
		}
		weekdaySet[weekday] = struct{}{}
	}
	if len(weekdaySet) == 0 {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}

	localStart := startDate.In(loc)
	cursor := time.Date(localStart.Year(), localStart.Month(), localStart.Day(), clock.Hour(), clock.Minute(), 0, 0, loc)
	result := make([]time.Time, 0, maxOccurrences)
	for !cursor.After(until.In(loc)) && len(result) < maxOccurrences {
		isoWeekday := int(cursor.Weekday())
		if isoWeekday == 0 {
			isoWeekday = 7
		}
		if _, ok := weekdaySet[isoWeekday]; ok {
			result = append(result, cursor.UTC())
		}
		cursor = cursor.AddDate(0, 0, 1)
	}
	return result, nil
}

var allowedExcursionIncludedItemKeys = map[string]struct{}{
	"transport": {},
	"food":      {},
	"tickets":   {},
	"equipment": {},
	"guide":     {},
	"photo":     {},
}

func normalizeIncludedItems(values []ExcursionIncludedItemInput) ([]model.ExcursionIncludedItem, error) {
	seen := make(map[string]struct{}, len(values))
	result := make([]model.ExcursionIncludedItem, 0, len(values))
	for _, value := range values {
		key := strings.ToLower(strings.TrimSpace(value.Text))
		if key == "" {
			continue
		}
		if _, ok := allowedExcursionIncludedItemKeys[key]; !ok {
			return nil, ErrInvalidExcursionIncludedItem
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, model.NewExcursionIncludedItem(key, nil))
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Text < result[j].Text
	})
	return result, nil
}

func attractionBasedExcursionCopy(landmarkName *string) model.ExcursionLocalizedCopy {
	name := strings.TrimSpace(optionalStringValue(landmarkName))
	if name == "" {
		name = "FlyFy excursion"
	}
	return model.ExcursionLocalizedCopy{
		Title:       name,
		Summary:     "Compare guide offers for " + name + ".",
		Description: "Choose a guide, language, price, meeting point, schedule, and included options before booking.",
	}
}

func optionalStringValue(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func normalizeUUIDPtr(v *uuid.UUID) *uuid.UUID {
	if v == nil || *v == uuid.Nil {
		return nil
	}
	out := *v
	return &out
}
