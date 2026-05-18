package port

import (
	"context"

	"github.com/google/uuid"
)

type AttractionRatingSnapshot struct {
	AttractionID uuid.UUID
	Source       string
	RatingAvg    float64
	ReviewCount  int
}

type AttractionRatingUpdater interface {
	ApplyAttractionRatingSnapshot(ctx context.Context, snapshot AttractionRatingSnapshot) error
}
