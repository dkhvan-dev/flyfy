package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
)

type FileRepository interface {
	Create(ctx context.Context, file *model.File) error
	GetByID(ctx context.Context, id uuid.UUID) (*model.File, error)
	GetByObjectKey(ctx context.Context, objectKey string) (*model.File, error)
	Update(ctx context.Context, file *model.File) error
	SoftDelete(ctx context.Context, id uuid.UUID) error
}
