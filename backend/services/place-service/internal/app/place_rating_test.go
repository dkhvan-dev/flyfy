package app

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

type ratingRepoStub struct {
	recalculatedPlaceID uuid.UUID
	sourcePlaceID       uuid.UUID
	source              string
	sourceRatingAvg     float64
	sourceReviewCount   int
	rating              float64
	reviewCount         int
}

func (s *ratingRepoStub) CreatePlace(context.Context, *model.Place) error  { return nil }
func (s *ratingRepoStub) UpdatePlace(context.Context, *model.Place) error  { return nil }
func (s *ratingRepoStub) SoftDeletePlace(context.Context, uuid.UUID) error { return nil }
func (s *ratingRepoStub) RecoverPlace(context.Context, uuid.UUID) error    { return nil }
func (s *ratingRepoStub) GetPlaceByID(context.Context, uuid.UUID, string) (*model.Place, error) {
	return nil, nil
}
func (s *ratingRepoStub) ListPlaces(context.Context, model.PlaceListFilter) ([]*model.Place, int, error) {
	return nil, 0, nil
}
func (s *ratingRepoStub) ReplacePlaceMedia(context.Context, uuid.UUID, []model.PlaceMedia) error {
	return nil
}
func (s *ratingRepoStub) ListVisitReferenceValues(context.Context, string) ([]model.PlaceVisitReferenceValue, error) {
	return nil, nil
}
func (s *ratingRepoStub) ReplaceTags(context.Context, uuid.UUID, []string) error { return nil }
func (s *ratingRepoStub) CreateReview(context.Context, *model.PlaceReview) error {
	return nil
}
func (s *ratingRepoStub) SoftDeleteReview(context.Context, uuid.UUID, uuid.UUID) error { return nil }
func (s *ratingRepoStub) GetReviewByID(context.Context, uuid.UUID) (*model.PlaceReview, error) {
	return nil, nil
}
func (s *ratingRepoStub) GetReviewByPlaceAndAuthor(context.Context, uuid.UUID, uuid.UUID) (*model.PlaceReview, error) {
	return nil, nil
}
func (s *ratingRepoStub) ListReviews(context.Context, uuid.UUID, int, int) ([]*model.PlaceReview, int, error) {
	return nil, 0, nil
}
func (s *ratingRepoStub) ReplaceReviewMedia(context.Context, uuid.UUID, []model.ReviewMedia) error {
	return nil
}
func (s *ratingRepoStub) RecalcRating(ctx context.Context, placeID uuid.UUID) (float64, int, error) {
	s.recalculatedPlaceID = placeID
	return s.rating, s.reviewCount, nil
}
func (s *ratingRepoStub) ApplyRatingSourceSnapshot(ctx context.Context, placeID uuid.UUID, source string, ratingAvg float64, reviewCount int) (float64, int, error) {
	s.sourcePlaceID = placeID
	s.source = source
	s.sourceRatingAvg = ratingAvg
	s.sourceReviewCount = reviewCount
	return s.rating, s.reviewCount, nil
}

func TestRecalculateRatingDelegatesToRepository(t *testing.T) {
	placeID := uuid.New()
	repo := &ratingRepoStub{rating: 4.75, reviewCount: 8}
	uc := NewPlaceUseCase(repo, nil)

	rating, reviewCount, err := uc.RecalculateRating(context.Background(), placeID)
	if err != nil {
		t.Fatalf("RecalculateRating() error = %v", err)
	}
	if repo.recalculatedPlaceID != placeID {
		t.Fatalf("recalculated id = %s, want %s", repo.recalculatedPlaceID, placeID)
	}
	if rating != 4.75 || reviewCount != 8 {
		t.Fatalf("rating/count = %.2f/%d, want 4.75/8", rating, reviewCount)
	}
}

func TestApplyRatingSourceSnapshotDelegatesToRepository(t *testing.T) {
	placeID := uuid.New()
	repo := &ratingRepoStub{rating: 4.6, reviewCount: 11}
	uc := NewPlaceUseCase(repo, nil)

	rating, reviewCount, err := uc.ApplyRatingSourceSnapshot(context.Background(), RatingSourceSnapshotInput{
		PlaceID:     placeID,
		Source:      "excursion_reviews",
		RatingAvg:   4.4,
		ReviewCount: 7,
	})
	if err != nil {
		t.Fatalf("ApplyRatingSourceSnapshot() error = %v", err)
	}
	if repo.sourcePlaceID != placeID ||
		repo.source != "excursion_reviews" ||
		repo.sourceRatingAvg != 4.4 ||
		repo.sourceReviewCount != 7 {
		t.Fatalf("source snapshot = %s/%s/%.1f/%d, want %s/excursion_reviews/4.4/7",
			repo.sourcePlaceID, repo.source, repo.sourceRatingAvg, repo.sourceReviewCount, placeID)
	}
	if rating != 4.6 || reviewCount != 11 {
		t.Fatalf("rating/count = %.2f/%d, want 4.6/11", rating, reviewCount)
	}
}
