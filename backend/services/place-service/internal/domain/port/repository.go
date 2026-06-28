package port

import (
	"context"

	"github.com/google/uuid"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

type PlaceRepository interface {
	// Places CRUD
	CreatePlace(ctx context.Context, place *model.Place) error
	UpdatePlace(ctx context.Context, place *model.Place) error
	SoftDeletePlace(ctx context.Context, placeID uuid.UUID) error
	RecoverPlace(ctx context.Context, placeID uuid.UUID) error
	GetPlaceByID(ctx context.Context, id uuid.UUID, locale string) (*model.Place, error)
	ListPlaces(ctx context.Context, filter model.PlaceListFilter) ([]*model.Place, int, error)

	// Media
	ReplacePlaceMedia(ctx context.Context, placeID uuid.UUID, media []model.PlaceMedia) error
	ListVisitReferenceValues(ctx context.Context, locale string) ([]model.PlaceVisitReferenceValue, error)

	// Tags
	ReplaceTags(ctx context.Context, placeID uuid.UUID, tags []string) error

	// Reviews
	CreateReview(ctx context.Context, review *model.PlaceReview) error
	SoftDeleteReview(ctx context.Context, reviewID, authorUserID uuid.UUID) error
	GetReviewByID(ctx context.Context, reviewID uuid.UUID) (*model.PlaceReview, error)
	GetReviewByPlaceAndAuthor(ctx context.Context, placeID, authorUserID uuid.UUID) (*model.PlaceReview, error)
	ListReviews(ctx context.Context, placeID uuid.UUID, limit, offset int) ([]*model.PlaceReview, int, error)
	ReplaceReviewMedia(ctx context.Context, reviewID uuid.UUID, media []model.ReviewMedia) error

	// Rating
	RecalcRating(ctx context.Context, placeID uuid.UUID) (float64, int, error)
	ApplyRatingSourceSnapshot(ctx context.Context, placeID uuid.UUID, source string, ratingAvg float64, reviewCount int) (float64, int, error)
}
