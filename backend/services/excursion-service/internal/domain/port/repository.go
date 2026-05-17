package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
)

type ExcursionFilter struct {
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

type ExcursionRelations struct {
	Tags               []string
	LanguageCodes      []string
	IncludedItems      []model.ExcursionIncludedItem
	Itinerary          []*model.ExcursionItineraryItem
	CoverFileID        *uuid.UUID
	ProductCoverFileID *uuid.UUID
}

type ExcursionProductFilter struct {
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

type ExcursionOfferFilter struct {
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

type ExcursionOfferRelations struct {
	LanguageCodes []string
	IncludedItems []model.ExcursionIncludedItem
	Itinerary     []*model.ExcursionItineraryItem
}

type ExcursionBookingFilter struct {
	TouristUserID *uuid.UUID
	GuideUserID   *uuid.UUID
	Limit         int
	Offset        int
}

type ExcursionReviewFilter struct {
	ProductID  *uuid.UUID
	LandmarkID *uuid.UUID
	Limit      int
	Offset     int
}

type ExcursionRepository interface {
	CreateExcursionAggregate(ctx context.Context, item *model.Excursion, relations ExcursionRelations) error
	UpdateExcursionAggregate(ctx context.Context, item *model.Excursion, relations ExcursionRelations) error
	UpdateExcursion(ctx context.Context, item *model.Excursion) error
	GetExcursionByID(ctx context.Context, excursionID uuid.UUID) (*model.Excursion, error)
	ListExcursions(ctx context.Context, filter ExcursionFilter) ([]*model.Excursion, error)
	LoadExcursionRelations(ctx context.Context, excursionID uuid.UUID) (ExcursionRelations, error)
	CreateExcursionEvent(ctx context.Context, item *model.ExcursionEvent) error
	ListExcursionProductCards(ctx context.Context, filter ExcursionProductFilter) ([]*model.ExcursionProductCard, error)
	GetExcursionProductCardByID(ctx context.Context, productID uuid.UUID) (*model.ExcursionProductCard, error)
	ListExcursionOffers(ctx context.Context, filter ExcursionOfferFilter) ([]*model.ExcursionOffer, error)
	ListExcursionLanguageCodesByGuideUserIDs(ctx context.Context, guideUserIDs []uuid.UUID) (map[uuid.UUID][]string, error)
	HasActiveExcursionForGuideLandmark(ctx context.Context, guideUserID uuid.UUID, landmarkID uuid.UUID) (bool, error)
	GetExcursionOfferByID(ctx context.Context, offerID uuid.UUID) (*model.ExcursionOffer, error)
	LoadExcursionOfferRelations(ctx context.Context, offerID uuid.UUID) (ExcursionOfferRelations, error)
	CreateExcursionBooking(ctx context.Context, item *model.ExcursionBooking) error
	ListExcursionBookings(ctx context.Context, filter ExcursionBookingFilter) ([]*model.ExcursionBookingListItem, error)
	GetExcursionBookingByID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionBooking, error)
	CreateExcursionReview(ctx context.Context, item *model.ExcursionReview) error
	GetExcursionReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionReview, error)
	ListExcursionReviews(ctx context.Context, filter ExcursionReviewFilter) ([]*model.ExcursionReview, error)
}
