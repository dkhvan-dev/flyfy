package app

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/attraction-service/internal/domain/model"
)

type ratingRepoStub struct {
	recalculatedAttractionID uuid.UUID
	sourceAttractionID       uuid.UUID
	source                   string
	sourceRatingAvg          float64
	sourceReviewCount        int
	rating                   float64
	reviewCount              int
}

func (s *ratingRepoStub) CreateAttraction(context.Context, *model.Attraction) error { return nil }
func (s *ratingRepoStub) UpdateAttraction(context.Context, *model.Attraction) error { return nil }
func (s *ratingRepoStub) SoftDeleteAttraction(context.Context, uuid.UUID) error     { return nil }
func (s *ratingRepoStub) RecoverAttraction(context.Context, uuid.UUID) error        { return nil }
func (s *ratingRepoStub) GetAttractionByID(context.Context, uuid.UUID, string) (*model.Attraction, error) {
	return nil, nil
}
func (s *ratingRepoStub) ListAttractions(context.Context, model.AttractionListFilter) ([]*model.Attraction, int, error) {
	return nil, 0, nil
}
func (s *ratingRepoStub) ReplaceAttractionMedia(context.Context, uuid.UUID, []model.AttractionMedia) error {
	return nil
}
func (s *ratingRepoStub) ReplaceTags(context.Context, uuid.UUID, []string) error { return nil }
func (s *ratingRepoStub) CreateReview(context.Context, *model.AttractionReview) error {
	return nil
}
func (s *ratingRepoStub) SoftDeleteReview(context.Context, uuid.UUID, uuid.UUID) error { return nil }
func (s *ratingRepoStub) GetReviewByID(context.Context, uuid.UUID) (*model.AttractionReview, error) {
	return nil, nil
}
func (s *ratingRepoStub) GetReviewByAttractionAndAuthor(context.Context, uuid.UUID, uuid.UUID) (*model.AttractionReview, error) {
	return nil, nil
}
func (s *ratingRepoStub) ListReviews(context.Context, uuid.UUID, int, int) ([]*model.AttractionReview, int, error) {
	return nil, 0, nil
}
func (s *ratingRepoStub) ReplaceReviewMedia(context.Context, uuid.UUID, []model.ReviewMedia) error {
	return nil
}
func (s *ratingRepoStub) RecalcRating(ctx context.Context, attractionID uuid.UUID) (float64, int, error) {
	s.recalculatedAttractionID = attractionID
	return s.rating, s.reviewCount, nil
}
func (s *ratingRepoStub) ApplyRatingSourceSnapshot(ctx context.Context, attractionID uuid.UUID, source string, ratingAvg float64, reviewCount int) (float64, int, error) {
	s.sourceAttractionID = attractionID
	s.source = source
	s.sourceRatingAvg = ratingAvg
	s.sourceReviewCount = reviewCount
	return s.rating, s.reviewCount, nil
}

func TestRecalculateRatingDelegatesToRepository(t *testing.T) {
	attractionID := uuid.New()
	repo := &ratingRepoStub{rating: 4.75, reviewCount: 8}
	uc := NewAttractionUseCase(repo, nil)

	rating, reviewCount, err := uc.RecalculateRating(context.Background(), attractionID)
	if err != nil {
		t.Fatalf("RecalculateRating() error = %v", err)
	}
	if repo.recalculatedAttractionID != attractionID {
		t.Fatalf("recalculated id = %s, want %s", repo.recalculatedAttractionID, attractionID)
	}
	if rating != 4.75 || reviewCount != 8 {
		t.Fatalf("rating/count = %.2f/%d, want 4.75/8", rating, reviewCount)
	}
}

func TestApplyRatingSourceSnapshotDelegatesToRepository(t *testing.T) {
	attractionID := uuid.New()
	repo := &ratingRepoStub{rating: 4.6, reviewCount: 11}
	uc := NewAttractionUseCase(repo, nil)

	rating, reviewCount, err := uc.ApplyRatingSourceSnapshot(context.Background(), RatingSourceSnapshotInput{
		AttractionID: attractionID,
		Source:       "excursion_reviews",
		RatingAvg:    4.4,
		ReviewCount:  7,
	})
	if err != nil {
		t.Fatalf("ApplyRatingSourceSnapshot() error = %v", err)
	}
	if repo.sourceAttractionID != attractionID ||
		repo.source != "excursion_reviews" ||
		repo.sourceRatingAvg != 4.4 ||
		repo.sourceReviewCount != 7 {
		t.Fatalf("source snapshot = %s/%s/%.1f/%d, want %s/excursion_reviews/4.4/7",
			repo.sourceAttractionID, repo.source, repo.sourceRatingAvg, repo.sourceReviewCount, attractionID)
	}
	if rating != 4.6 || reviewCount != 11 {
		t.Fatalf("rating/count = %.2f/%d, want 4.6/11", rating, reviewCount)
	}
}
