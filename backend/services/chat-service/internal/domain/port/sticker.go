package port

import (
	"context"

	"github.com/google/uuid"
)

type StickerMetadata struct {
	StickerID      uuid.UUID
	PackID         uuid.UUID
	PackSlug       string
	Slug           string
	FileID         uuid.UUID
	FallbackFileID uuid.UUID
	PreviewFileID  *uuid.UUID
	ContentType    string
	Width          int
	Height         int
	DurationMS     int
	Status         string
}

type StickerResolver interface {
	ValidateSend(ctx context.Context, senderUserID uuid.UUID, stickerID uuid.UUID) (*StickerMetadata, error)
}
