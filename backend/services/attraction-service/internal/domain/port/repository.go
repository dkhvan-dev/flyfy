package port

import (
	"context"

	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/model"
	"github.com/google/uuid"
)

type AttractionRepository interface {
	// Attractions CRUD
	CreateAttraction(ctx context.Context, attraction *model.Attraction) error
	UpdateAttraction(ctx context.Context, attraction *model.Attraction) error
	SoftDeleteAttraction(ctx context.Context, attractionID uuid.UUID) error
	RecoverAttraction(ctx context.Context, attractionID uuid.UUID) error
	GetAttractionByID(ctx context.Context, id uuid.UUID, locale string) (*model.Attraction, error)
	ListAttractions(ctx context.Context, filter model.AttractionListFilter) ([]*model.Attraction, int, error)

	// Media
	ReplaceAttractionMedia(ctx context.Context, attractionID uuid.UUID, media []model.AttractionMedia) error

	// Tags
	ReplaceTags(ctx context.Context, attractionID uuid.UUID, tags []string) error

	// Reviews
	CreateReview(ctx context.Context, review *model.AttractionReview) error
	SoftDeleteReview(ctx context.Context, reviewID, authorUserID uuid.UUID) error
	GetReviewByID(ctx context.Context, reviewID uuid.UUID) (*model.AttractionReview, error)
	GetReviewByAttractionAndAuthor(ctx context.Context, attractionID, authorUserID uuid.UUID) (*model.AttractionReview, error)
	ListReviews(ctx context.Context, attractionID uuid.UUID, limit, offset int) ([]*model.AttractionReview, int, error)
	ReplaceReviewMedia(ctx context.Context, reviewID uuid.UUID, media []model.ReviewMedia) error

	// Rating
	RecalcRating(ctx context.Context, attractionID uuid.UUID) (float64, int, error)
}
