package port

import (
	"context"

	"github.com/google/uuid"
)

type PlaceRatingSnapshot struct {
	PlaceID     uuid.UUID
	Source      string
	RatingAvg   float64
	ReviewCount int
}

type PlaceRatingUpdater interface {
	ApplyPlaceRatingSnapshot(ctx context.Context, snapshot PlaceRatingSnapshot) error
}
