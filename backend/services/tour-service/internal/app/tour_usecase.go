package app

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
)

type TourAggregate struct {
	Tour               *model.Tour
	Tags               []string
	LanguageCodes      []string
	IncludedItems      []model.TourIncludedItem
	Itinerary          []*model.TourItineraryItem
	CoverFileID        *uuid.UUID
	ProductCoverFileID *uuid.UUID
}

type TourProductCardAggregate struct {
	Product *model.TourProductCard
}

type TourOfferAggregate struct {
	Offer         *model.TourOffer
	LanguageCodes []string
	IncludedItems []model.TourIncludedItem
	Itinerary     []*model.TourItineraryItem
}

type TourUseCase struct {
	repo          port.TourRepository
	guideVerifier port.GuideVerifier
	fileManager   port.TourCoverFileManager
}

func NewTourUseCase(
	repo port.TourRepository,
	guideVerifier port.GuideVerifier,
	fileManager port.TourCoverFileManager,
) *TourUseCase {
	return &TourUseCase{
		repo:          repo,
		guideVerifier: guideVerifier,
		fileManager:   fileManager,
	}
}

type TourItineraryItemInput struct {
	StartOffsetMinutes int
	DurationMinutes    *int
	Title              string
	Description        string
	Translations       model.TourItineraryTranslations
}

type TourIncludedItemInput struct {
	Text         string
	Translations model.TourLocalizedText
}

type CreateTourInput struct {
	ActorUserID         uuid.UUID
	LandmarkID          *uuid.UUID
	LandmarkName        *string
	CategorySlug        string
	ProductTranslations model.TourTranslations
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
	IncludedItems       []TourIncludedItemInput
	Itinerary           []TourItineraryItemInput
}

type UpdateTourInput struct {
	ActorUserID         uuid.UUID
	TourID              uuid.UUID
	LandmarkID          *uuid.UUID
	LandmarkName        *string
	CategorySlug        string
	ProductTranslations model.TourTranslations
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
	IncludedItems       []TourIncludedItemInput
	Itinerary           []TourItineraryItemInput
}

type CreateTourBookingInput struct {
	ActorUserID    uuid.UUID
	ProductID      uuid.UUID
	OfferID        uuid.UUID
	ScheduledFor   time.Time
	Adults         int
	Children       int
	IdempotencyKey *string
}

func (u *TourUseCase) CreateTour(ctx context.Context, input CreateTourInput) (*TourAggregate, error) {
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
		return nil, ErrTourAttractionRequired
	}

	if err = u.validateCoverFiles(ctx, input.CoverFileID, input.ProductCoverFileID); err != nil {
		return nil, err
	}
	marketingCopy := attractionBasedTourCopy(input.LandmarkName)
	categorySlug := model.NormalizeSlug(input.CategorySlug)
	if categorySlug == "" {
		categorySlug = "sightseeing"
	}

	item, err := model.NewTour(model.NewTourParams{
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
		Visibility:           enum.TourVisibility(strings.TrimSpace(input.Visibility)),
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

	relations, err := buildRelations(item.ID, nil, input.LanguageCodes, input.IncludedItems, input.CoverFileID, input.ProductCoverFileID, input.Itinerary)
	if err != nil {
		return nil, err
	}

	if err = u.repo.CreateTourAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("create tour aggregate: %w", err)
	}
	u.bindCoverFile(ctx, item.ID, input.ActorUserID, input.CoverFileID)
	u.recordEvent(ctx, item.ID, enum.TourEventTypeCreated, input.ActorUserID, map[string]any{"status": string(item.Status)})

	return &TourAggregate{
		Tour:               item,
		Tags:               relations.Tags,
		LanguageCodes:      relations.LanguageCodes,
		IncludedItems:      relations.IncludedItems,
		Itinerary:          relations.Itinerary,
		CoverFileID:        relations.CoverFileID,
		ProductCoverFileID: relations.ProductCoverFileID,
	}, nil
}

func (u *TourUseCase) UpdateTour(ctx context.Context, input UpdateTourInput) (*TourAggregate, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.TourID == uuid.Nil {
		return nil, ErrInvalidTourID
	}

	item, err := u.repo.GetTourByID(ctx, input.TourID)
	if err != nil {
		return nil, fmt.Errorf("get tour by id: %w", err)
	}
	if item == nil {
		return nil, ErrTourNotFound
	}
	if !item.IsOwnedBy(input.ActorUserID) {
		return nil, ErrTourAccessDenied
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
		return nil, ErrTourAttractionRequired
	}
	marketingCopy := attractionBasedTourCopy(item.LandmarkName)

	if err = item.ApplyUpdate(model.UpdateTourParams{
		LandmarkID:          item.LandmarkID,
		LandmarkName:        item.LandmarkName,
		Title:               marketingCopy.Title,
		Summary:             marketingCopy.Summary,
		Description:         marketingCopy.Description,
		Translations:        nil,
		CategorySlug:        item.CategorySlug,
		ProductTranslations: item.ProductTranslations,
		Visibility:          enum.TourVisibility(strings.TrimSpace(input.Visibility)),
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

	relations, err := buildRelations(item.ID, nil, input.LanguageCodes, input.IncludedItems, input.CoverFileID, input.ProductCoverFileID, input.Itinerary)
	if err != nil {
		return nil, err
	}
	if item.Status == enum.TourStatusPublished {
		if err = item.ValidatePublishable(model.PublishTourParams{LanguageCodes: relations.LanguageCodes, Itinerary: relations.Itinerary}); err != nil {
			return nil, err
		}
	}

	if err = u.repo.UpdateTourAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("update tour aggregate: %w", err)
	}
	u.bindCoverFile(ctx, item.ID, input.ActorUserID, input.CoverFileID)
	u.recordEvent(ctx, item.ID, enum.TourEventTypeUpdated, input.ActorUserID, map[string]any{"revision": item.Revision})

	return &TourAggregate{
		Tour:               item,
		Tags:               relations.Tags,
		LanguageCodes:      relations.LanguageCodes,
		IncludedItems:      relations.IncludedItems,
		Itinerary:          relations.Itinerary,
		CoverFileID:        relations.CoverFileID,
		ProductCoverFileID: relations.ProductCoverFileID,
	}, nil
}

func (u *TourUseCase) PublishTour(ctx context.Context, tourID uuid.UUID, actorUserID uuid.UUID) (*TourAggregate, error) {
	item, relations, err := u.getOwnedTourWithRelations(ctx, tourID, actorUserID)
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
	if err = item.Publish(model.PublishTourParams{
		LanguageCodes: relations.LanguageCodes,
		Itinerary:     relations.Itinerary,
	}); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateTourAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("publish tour: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.TourEventTypePublished, actorUserID, map[string]any{"publishedAt": item.PublishedAt})

	return &TourAggregate{Tour: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID}, nil
}

func (u *TourUseCase) DeleteTour(ctx context.Context, tourID uuid.UUID, actorUserID uuid.UUID) error {
	item, relations, err := u.getOwnedTourWithRelations(ctx, tourID, actorUserID)
	if err != nil {
		return err
	}
	if err = item.Archive(); err != nil {
		return err
	}
	if err = u.repo.UpdateTourAggregate(ctx, item, relations); err != nil {
		return fmt.Errorf("delete tour: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.TourEventTypeDeleted, actorUserID, map[string]any{"deletedAt": item.DeletedAt})
	return nil
}

func (u *TourUseCase) GetPublicTour(ctx context.Context, tourID uuid.UUID) (*TourAggregate, error) {
	if tourID == uuid.Nil {
		return nil, ErrInvalidTourID
	}
	item, err := u.repo.GetTourByID(ctx, tourID)
	if err != nil {
		return nil, fmt.Errorf("get tour by id: %w", err)
	}
	if item == nil || !item.IsPubliclyReadable() {
		return nil, ErrTourNotFound
	}
	return u.loadAggregate(ctx, item)
}

func (u *TourUseCase) GetMyTour(ctx context.Context, tourID uuid.UUID, actorUserID uuid.UUID) (*TourAggregate, error) {
	item, relations, err := u.getOwnedTourWithRelations(ctx, tourID, actorUserID)
	if err != nil {
		return nil, err
	}
	return &TourAggregate{Tour: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID}, nil
}

func (u *TourUseCase) ListTours(ctx context.Context, filter port.TourFilter) ([]*TourAggregate, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	filter.Statuses = []string{string(enum.TourStatusPublished)}
	items, err := u.repo.ListTours(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list tours: %w", err)
	}
	return u.loadAggregates(ctx, items)
}

func (u *TourUseCase) ListTourProducts(ctx context.Context, filter port.TourProductFilter) ([]*TourProductCardAggregate, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	items, err := u.repo.ListTourProductCards(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list tour products: %w", err)
	}
	return toProductCardAggregates(items), nil
}

func (u *TourUseCase) GetTourProduct(ctx context.Context, productID uuid.UUID) (*TourProductCardAggregate, error) {
	if productID == uuid.Nil {
		return nil, ErrInvalidTourID
	}
	item, err := u.repo.GetTourProductCardByID(ctx, productID)
	if err != nil {
		return nil, fmt.Errorf("get tour product: %w", err)
	}
	if item == nil {
		return nil, ErrTourNotFound
	}
	return &TourProductCardAggregate{Product: item}, nil
}

func (u *TourUseCase) ListTourProductOffers(ctx context.Context, filter port.TourOfferFilter) ([]*TourOfferAggregate, error) {
	if filter.ProductID == uuid.Nil {
		return nil, ErrInvalidTourID
	}
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	offers, err := u.repo.ListTourOffers(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list tour offers: %w", err)
	}
	result := make([]*TourOfferAggregate, 0, len(offers))
	for _, offer := range offers {
		if offer == nil {
			continue
		}
		relations, relErr := u.repo.LoadTourOfferRelations(ctx, offer.ID)
		if relErr != nil {
			return nil, fmt.Errorf("load tour offer relations: %w", relErr)
		}
		result = append(result, &TourOfferAggregate{
			Offer:         offer,
			LanguageCodes: relations.LanguageCodes,
			IncludedItems: relations.IncludedItems,
			Itinerary:     relations.Itinerary,
		})
	}
	return result, nil
}

func (u *TourUseCase) CreateTourBooking(ctx context.Context, input CreateTourBookingInput) (*model.TourBooking, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.ProductID == uuid.Nil || input.OfferID == uuid.Nil {
		return nil, ErrInvalidTourID
	}
	offer, err := u.repo.GetTourOfferByID(ctx, input.OfferID)
	if err != nil {
		return nil, fmt.Errorf("get tour offer: %w", err)
	}
	if offer == nil || offer.ProductID != input.ProductID {
		return nil, ErrTourOfferNotFound
	}
	if offer.DeletedAt != nil ||
		offer.Status != enum.TourStatusPublished ||
		offer.Visibility != enum.TourVisibilityPublic {
		return nil, ErrTourOfferNotBookable
	}
	if offer.GuideUserID == input.ActorUserID {
		return nil, ErrTourAccessDenied
	}
	totalSeats := input.Adults + input.Children
	if totalSeats > offer.MaxGroupSize {
		return nil, model.ErrInvalidTourBookingGuests
	}

	booking, err := model.NewTourBooking(model.NewTourBookingParams{
		ProductID:       offer.ProductID,
		OfferID:         offer.ID,
		LegacyTourID:    offer.LegacyTourID,
		GuideProfileID:  offer.GuideProfileID,
		GuideUserID:     offer.GuideUserID,
		TouristUserID:   input.ActorUserID,
		ScheduledFor:    input.ScheduledFor,
		Adults:          input.Adults,
		Children:        input.Children,
		UnitPriceAmount: offer.PriceAmount,
		Currency:        offer.Currency,
		IdempotencyKey:  input.IdempotencyKey,
	})
	if err != nil {
		return nil, err
	}
	if err = u.repo.CreateTourBooking(ctx, booking); err != nil {
		return nil, fmt.Errorf("create tour booking: %w", err)
	}
	return booking, nil
}

func (u *TourUseCase) ListMyTours(ctx context.Context, actorUserID uuid.UUID, limit int, offset int, statuses []string) ([]*TourAggregate, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	filter := port.TourFilter{
		GuideUserID: &actorUserID,
		Statuses:    statuses,
		Limit:       limit,
		Offset:      offset,
	}
	items, err := u.repo.ListTours(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list my tours: %w", err)
	}
	return u.loadAggregates(ctx, items)
}

func (u *TourUseCase) getOwnedTourWithRelations(ctx context.Context, tourID uuid.UUID, actorUserID uuid.UUID) (*model.Tour, port.TourRelations, error) {
	if actorUserID == uuid.Nil {
		return nil, port.TourRelations{}, ErrInvalidActorUserID
	}
	if tourID == uuid.Nil {
		return nil, port.TourRelations{}, ErrInvalidTourID
	}
	item, err := u.repo.GetTourByID(ctx, tourID)
	if err != nil {
		return nil, port.TourRelations{}, fmt.Errorf("get tour by id: %w", err)
	}
	if item == nil {
		return nil, port.TourRelations{}, ErrTourNotFound
	}
	if !item.IsOwnedBy(actorUserID) {
		return nil, port.TourRelations{}, ErrTourAccessDenied
	}
	relations, err := u.repo.LoadTourRelations(ctx, tourID)
	if err != nil {
		return nil, port.TourRelations{}, fmt.Errorf("load tour relations: %w", err)
	}
	return item, relations, nil
}

func (u *TourUseCase) loadAggregate(ctx context.Context, item *model.Tour) (*TourAggregate, error) {
	relations, err := u.repo.LoadTourRelations(ctx, item.ID)
	if err != nil {
		return nil, fmt.Errorf("load tour relations: %w", err)
	}
	return &TourAggregate{Tour: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID}, nil
}

func (u *TourUseCase) loadAggregates(ctx context.Context, items []*model.Tour) ([]*TourAggregate, error) {
	result := make([]*TourAggregate, 0, len(items))
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

func toProductCardAggregates(items []*model.TourProductCard) []*TourProductCardAggregate {
	result := make([]*TourProductCardAggregate, 0, len(items))
	for _, item := range items {
		if item == nil {
			continue
		}
		result = append(result, &TourProductCardAggregate{Product: item})
	}
	return result
}

func (u *TourUseCase) verifyGuide(ctx context.Context, actorUserID uuid.UUID) (port.GuideTourPermission, error) {
	if u.guideVerifier == nil {
		return port.GuideTourPermission{
			GuideProfileID: actorUserID,
			GuideUserID:    actorUserID,
			Allowed:        true,
		}, nil
	}
	permission, err := u.guideVerifier.VerifyTourGuide(ctx, actorUserID)
	if err != nil {
		return port.GuideTourPermission{}, err
	}
	if !permission.Allowed || permission.GuideProfileID == uuid.Nil || permission.GuideUserID == uuid.Nil {
		return port.GuideTourPermission{}, ErrGuideNotAllowed
	}
	return permission, nil
}

func (u *TourUseCase) validateCoverFile(ctx context.Context, fileID *uuid.UUID) error {
	if fileID == nil || *fileID == uuid.Nil || u.fileManager == nil {
		return nil
	}
	return u.fileManager.ValidateTourCoverFile(ctx, *fileID)
}

func (u *TourUseCase) validateCoverFiles(ctx context.Context, fileIDs ...*uuid.UUID) error {
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

func (u *TourUseCase) bindCoverFile(ctx context.Context, tourID uuid.UUID, actorUserID uuid.UUID, fileID *uuid.UUID) {
	if fileID == nil || *fileID == uuid.Nil || u.fileManager == nil {
		return
	}
	_ = u.fileManager.BindTourCoverFile(ctx, *fileID, tourID, actorUserID)
}

func (u *TourUseCase) recordEvent(ctx context.Context, tourID uuid.UUID, eventType enum.TourEventType, actorUserID uuid.UUID, payload any) {
	actor := actorUserID
	event, err := model.NewTourEvent(model.NewTourEventParams{
		TourID:      tourID,
		EventType:   eventType,
		ActorUserID: &actor,
		Payload:     payload,
	})
	if err != nil {
		return
	}
	_ = u.repo.CreateTourEvent(ctx, event)
}

func buildRelations(
	tourID uuid.UUID,
	tags []string,
	languageCodes []string,
	includedItems []TourIncludedItemInput,
	coverFileID *uuid.UUID,
	productCoverFileID *uuid.UUID,
	itinerary []TourItineraryItemInput,
) (port.TourRelations, error) {
	items := make([]*model.TourItineraryItem, 0, len(itinerary))
	for index, input := range itinerary {
		sortOrder := index
		item, err := model.NewTourItineraryItem(model.NewTourItineraryItemParams{
			TourID:             tourID,
			SortOrder:          sortOrder,
			StartOffsetMinutes: input.StartOffsetMinutes,
			DurationMinutes:    input.DurationMinutes,
			Title:              input.Title,
			Description:        input.Description,
			Translations:       input.Translations,
		})
		if err != nil {
			return port.TourRelations{}, err
		}
		items = append(items, item)
	}

	relations := port.TourRelations{
		Tags:               normalizeUniqueLower(tags),
		LanguageCodes:      normalizeUniqueLower(languageCodes),
		Itinerary:          items,
		CoverFileID:        normalizeUUIDPtr(coverFileID),
		ProductCoverFileID: normalizeUUIDPtr(productCoverFileID),
	}
	normalizedIncludedItems, err := normalizeIncludedItems(includedItems)
	if err != nil {
		return port.TourRelations{}, err
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

var allowedTourIncludedItemKeys = map[string]struct{}{
	"transport": {},
	"food":      {},
	"tickets":   {},
	"equipment": {},
	"guide":     {},
	"photo":     {},
}

func normalizeIncludedItems(values []TourIncludedItemInput) ([]model.TourIncludedItem, error) {
	seen := make(map[string]struct{}, len(values))
	result := make([]model.TourIncludedItem, 0, len(values))
	for _, value := range values {
		key := strings.ToLower(strings.TrimSpace(value.Text))
		if key == "" {
			continue
		}
		if _, ok := allowedTourIncludedItemKeys[key]; !ok {
			return nil, ErrInvalidTourIncludedItem
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, model.NewTourIncludedItem(key, nil))
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Text < result[j].Text
	})
	return result, nil
}

func attractionBasedTourCopy(landmarkName *string) model.TourLocalizedCopy {
	name := strings.TrimSpace(optionalStringValue(landmarkName))
	if name == "" {
		name = "FlyFy tour"
	}
	return model.TourLocalizedCopy{
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
