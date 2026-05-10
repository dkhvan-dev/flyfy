package port

import (
	"context"

	"github.com/google/uuid"
)

type TourCoverFileManager interface {
	ValidateTourCoverFile(ctx context.Context, fileID uuid.UUID) error
	BindTourCoverFile(ctx context.Context, fileID uuid.UUID, tourID uuid.UUID, createdByUserID uuid.UUID) error
	CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error)
}
