package model

import (
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

type PostMedia struct {
	PostID           uuid.UUID
	FileID           uuid.UUID
	MediaType        enum.PostMediaType
	Position         int
	IsPrimary        bool
	Caption          string
	AltText          string
	Width            *int
	Height           *int
	DurationMS       *int
	ThumbnailFileID  *uuid.UUID
	ProcessingStatus enum.PostMediaProcessingStatus
	CreatedAt        time.Time
	UpdatedAt        time.Time
}
