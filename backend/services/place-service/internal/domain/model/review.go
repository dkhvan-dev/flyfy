package model

import (
	"time"

	"github.com/google/uuid"
	"kz/inflap/backend/services/place-service/internal/domain/enum"
)

type PlaceReview struct {
	ID           uuid.UUID
	PlaceID      uuid.UUID
	AuthorUserID uuid.UUID
	Rating       float64
	Comment      string
	Media        []ReviewMedia
	CreatedAt    time.Time
	UpdatedAt    time.Time
	DeletedAt    *time.Time
}

type ReviewMedia struct {
	ID        uuid.UUID
	ReviewID  uuid.UUID
	FileID    uuid.UUID
	MediaType enum.MediaType
	Position  int
	CreatedAt time.Time
}
