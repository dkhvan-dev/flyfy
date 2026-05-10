package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
)

type TourFilter struct {
	GuideUserID     *uuid.UUID
	Statuses        []string
	Visibility      *string
	CategorySlug    *string
	CountryCode     *string
	CityName        *string
	LanguageCode    *string
	SearchQuery     *string
	PriceMin        *float64
	PriceMax        *float64
	DurationMin     *int
	DurationMax     *int
	MaxGroupSizeMin *int
	Limit           int
	Offset          int
}

type TourRelations struct {
	Tags          []string
	LanguageCodes []string
	IncludedItems []string
	Itinerary     []*model.TourItineraryItem
	CoverFileID   *uuid.UUID
}

type TourRepository interface {
	CreateTourAggregate(ctx context.Context, item *model.Tour, relations TourRelations) error
	UpdateTourAggregate(ctx context.Context, item *model.Tour, relations TourRelations) error
	UpdateTour(ctx context.Context, item *model.Tour) error
	GetTourByID(ctx context.Context, tourID uuid.UUID) (*model.Tour, error)
	ListTours(ctx context.Context, filter TourFilter) ([]*model.Tour, error)
	LoadTourRelations(ctx context.Context, tourID uuid.UUID) (TourRelations, error)
	CreateTourEvent(ctx context.Context, item *model.TourEvent) error
}
