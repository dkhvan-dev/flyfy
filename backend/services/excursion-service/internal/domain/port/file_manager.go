package port

import (
	"context"

	"github.com/google/uuid"
)

type ExcursionCoverFileManager interface {
	ValidateExcursionCoverFile(ctx context.Context, fileID uuid.UUID) error
	BindExcursionCoverFile(ctx context.Context, fileID uuid.UUID, excursionID uuid.UUID, createdByUserID uuid.UUID) error
	CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error)
}
