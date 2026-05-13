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
	Tags               []string
	LanguageCodes      []string
	IncludedItems      []model.TourIncludedItem
	Itinerary          []*model.TourItineraryItem
	CoverFileID        *uuid.UUID
	ProductCoverFileID *uuid.UUID
}

type TourProductFilter struct {
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

type TourOfferFilter struct {
	ProductID            uuid.UUID
	LanguageCode         *string
	SearchQuery          *string
	PriceMin             *float64
	PriceMax             *float64
	MaxGroupSizeMin      *int
	PreferredGuideUserID *uuid.UUID
	Sort                 string
	SortDirection        string
	Limit                int
	Offset               int
}

type TourOfferRelations struct {
	LanguageCodes []string
	IncludedItems []model.TourIncludedItem
	Itinerary     []*model.TourItineraryItem
}

type TourRepository interface {
	CreateTourAggregate(ctx context.Context, item *model.Tour, relations TourRelations) error
	UpdateTourAggregate(ctx context.Context, item *model.Tour, relations TourRelations) error
	UpdateTour(ctx context.Context, item *model.Tour) error
	GetTourByID(ctx context.Context, tourID uuid.UUID) (*model.Tour, error)
	ListTours(ctx context.Context, filter TourFilter) ([]*model.Tour, error)
	LoadTourRelations(ctx context.Context, tourID uuid.UUID) (TourRelations, error)
	CreateTourEvent(ctx context.Context, item *model.TourEvent) error
	ListTourProductCards(ctx context.Context, filter TourProductFilter) ([]*model.TourProductCard, error)
	GetTourProductCardByID(ctx context.Context, productID uuid.UUID) (*model.TourProductCard, error)
	ListTourOffers(ctx context.Context, filter TourOfferFilter) ([]*model.TourOffer, error)
	GetTourOfferByID(ctx context.Context, offerID uuid.UUID) (*model.TourOffer, error)
	LoadTourOfferRelations(ctx context.Context, offerID uuid.UUID) (TourOfferRelations, error)
	CreateTourBooking(ctx context.Context, item *model.TourBooking) error
}
