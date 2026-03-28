package port

import (
	"context"

	"github.com/google/uuid"
)

type ActivityMediaFileManager interface {
	ValidateActivityMediaFile(ctx context.Context, fileID uuid.UUID) error
	BindActivityMediaToActivity(ctx context.Context, fileID uuid.UUID, activityID uuid.UUID, createdByUserID uuid.UUID) error
	CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error)
}
