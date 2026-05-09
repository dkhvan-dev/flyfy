package port

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type CreateStickerUploadRequest struct {
	UserID       uuid.UUID
	OriginalName string
	ContentType  string
	SizeBytes    int64
}

type CreateStickerUploadResponse struct {
	FileID    uuid.UUID
	Method    string
	URL       string
	Headers   map[string]string
	ExpiresAt time.Time
}

type FileMetadata struct {
	ID          uuid.UUID
	Status      string
	ContentType string
	SizeBytes   int64
}

type FileManagerClient interface {
	CreateStickerUploadRequest(
		ctx context.Context,
		input CreateStickerUploadRequest,
	) (*CreateStickerUploadResponse, error)
	GetFile(ctx context.Context, fileID uuid.UUID) (*FileMetadata, error)
	BindStickerFileToUser(ctx context.Context, fileID uuid.UUID, userID uuid.UUID) error
}
