package port

import (
	"context"

	"github.com/google/uuid"
)

type StickerMetadata struct {
	StickerID uuid.UUID
	PackID    uuid.UUID
	FileID    uuid.UUID
	Status    string
}

type StickerResolver interface {
	ValidateSend(ctx context.Context, senderUserID uuid.UUID, stickerID uuid.UUID) (*StickerMetadata, error)
}
