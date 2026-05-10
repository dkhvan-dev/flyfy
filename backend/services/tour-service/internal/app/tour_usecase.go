package app

import (
	"context"
	"fmt"
	"sort"
	"strings"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
)

type TourAggregate struct {
	Tour          *model.Tour
	Tags          []string
	LanguageCodes []string
	IncludedItems []string
	Itinerary     []*model.TourItineraryItem
	CoverFileID   *uuid.UUID
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
}

type CreateTourInput struct {
	ActorUserID     uuid.UUID
	LandmarkID      *uuid.UUID
	LandmarkName    *string
	Title           string
	Summary         string
	Description     string
	CategorySlug    string
	Tags            []string
	Visibility      string
	DurationMinutes int
	MaxGroupSize    int
	LanguageCodes   []string
	CountryCode     *string
	CityName        *string
	MeetingPoint    string
	Latitude        *float64
	Longitude       *float64
	MapURL          *string
	PriceAmount     float64
	Currency        string
	CoverFileID     *uuid.UUID
	IncludedItems   []string
	Itinerary       []TourItineraryItemInput
}

type UpdateTourInput struct {
	ActorUserID     uuid.UUID
	TourID          uuid.UUID
	LandmarkID      *uuid.UUID
	LandmarkName    *string
	Title           string
	Summary         string
	Description     string
	CategorySlug    string
	Tags            []string
	Visibility      string
	DurationMinutes int
	MaxGroupSize    int
	LanguageCodes   []string
	CountryCode     *string
	CityName        *string
	MeetingPoint    string
	Latitude        *float64
	Longitude       *float64
	MapURL          *string
	PriceAmount     float64
	Currency        string
	CoverFileID     *uuid.UUID
	IncludedItems   []string
	Itinerary       []TourItineraryItemInput
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

	if err = u.validateCoverFile(ctx, input.CoverFileID); err != nil {
		return nil, err
	}

	item, err := model.NewTour(model.NewTourParams{
		GuideProfileID:  permission.GuideProfileID,
		GuideUserID:     permission.GuideUserID,
		LandmarkID:      input.LandmarkID,
		LandmarkName:    input.LandmarkName,
		Title:           input.Title,
		Summary:         input.Summary,
		Description:     input.Description,
		CategorySlug:    input.CategorySlug,
		Visibility:      enum.TourVisibility(strings.TrimSpace(input.Visibility)),
		DurationMinutes: input.DurationMinutes,
		MaxGroupSize:    input.MaxGroupSize,
		CountryCode:     input.CountryCode,
		CityName:        input.CityName,
		MeetingPoint:    input.MeetingPoint,
		Latitude:        input.Latitude,
		Longitude:       input.Longitude,
		MapURL:          input.MapURL,
		PriceAmount:     input.PriceAmount,
		Currency:        input.Currency,
	})
	if err != nil {
		return nil, err
	}

	relations, err := buildRelations(item.ID, input.Tags, input.LanguageCodes, input.IncludedItems, input.CoverFileID, input.Itinerary)
	if err != nil {
		return nil, err
	}

	if err = u.repo.CreateTourAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("create tour aggregate: %w", err)
	}
	u.bindCoverFile(ctx, item.ID, input.ActorUserID, input.CoverFileID)
	u.recordEvent(ctx, item.ID, enum.TourEventTypeCreated, input.ActorUserID, map[string]any{"status": string(item.Status)})

	return &TourAggregate{
		Tour:          item,
		Tags:          relations.Tags,
		LanguageCodes: relations.LanguageCodes,
		IncludedItems: relations.IncludedItems,
		Itinerary:     relations.Itinerary,
		CoverFileID:   relations.CoverFileID,
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
	if _, err = u.verifyGuide(ctx, input.ActorUserID); err != nil {
		return nil, err
	}
	if err = u.validateCoverFile(ctx, input.CoverFileID); err != nil {
		return nil, err
	}

	if err = item.ApplyUpdate(model.UpdateTourParams{
		LandmarkID:      input.LandmarkID,
		LandmarkName:    input.LandmarkName,
		Title:           input.Title,
		Summary:         input.Summary,
		Description:     input.Description,
		CategorySlug:    input.CategorySlug,
		Visibility:      enum.TourVisibility(strings.TrimSpace(input.Visibility)),
		DurationMinutes: input.DurationMinutes,
		MaxGroupSize:    input.MaxGroupSize,
		CountryCode:     input.CountryCode,
		CityName:        input.CityName,
		MeetingPoint:    input.MeetingPoint,
		Latitude:        input.Latitude,
		Longitude:       input.Longitude,
		MapURL:          input.MapURL,
		PriceAmount:     input.PriceAmount,
		Currency:        input.Currency,
	}); err != nil {
		return nil, err
	}

	relations, err := buildRelations(item.ID, input.Tags, input.LanguageCodes, input.IncludedItems, input.CoverFileID, input.Itinerary)
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
		Tour:          item,
		Tags:          relations.Tags,
		LanguageCodes: relations.LanguageCodes,
		IncludedItems: relations.IncludedItems,
		Itinerary:     relations.Itinerary,
		CoverFileID:   relations.CoverFileID,
	}, nil
}

func (u *TourUseCase) PublishTour(ctx context.Context, tourID uuid.UUID, actorUserID uuid.UUID) (*TourAggregate, error) {
	item, relations, err := u.getOwnedTourWithRelations(ctx, tourID, actorUserID)
	if err != nil {
		return nil, err
	}
	if _, err = u.verifyGuide(ctx, actorUserID); err != nil {
		return nil, err
	}
	if err = item.Publish(model.PublishTourParams{
		LanguageCodes: relations.LanguageCodes,
		Itinerary:     relations.Itinerary,
	}); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateTour(ctx, item); err != nil {
		return nil, fmt.Errorf("publish tour: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.TourEventTypePublished, actorUserID, map[string]any{"publishedAt": item.PublishedAt})

	return &TourAggregate{Tour: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID}, nil
}

func (u *TourUseCase) DeleteTour(ctx context.Context, tourID uuid.UUID, actorUserID uuid.UUID) error {
	item, _, err := u.getOwnedTourWithRelations(ctx, tourID, actorUserID)
	if err != nil {
		return err
	}
	if err = item.Archive(); err != nil {
		return err
	}
	if err = u.repo.UpdateTour(ctx, item); err != nil {
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
	includedItems []string,
	coverFileID *uuid.UUID,
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
		})
		if err != nil {
			return port.TourRelations{}, err
		}
		items = append(items, item)
	}

	return port.TourRelations{
		Tags:          normalizeUniqueLower(tags),
		LanguageCodes: normalizeUniqueLower(languageCodes),
		IncludedItems: normalizeIncludedItems(includedItems),
		Itinerary:     items,
		CoverFileID:   normalizeUUIDPtr(coverFileID),
	}, nil
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

func normalizeIncludedItems(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		normalized := strings.TrimSpace(value)
		key := strings.ToLower(normalized)
		if normalized == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, normalized)
	}
	return result
}

func normalizeUUIDPtr(v *uuid.UUID) *uuid.UUID {
	if v == nil || *v == uuid.Nil {
		return nil
	}
	out := *v
	return &out
}
