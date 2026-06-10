package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
)

type FileRepository interface {
	Create(ctx context.Context, file *model.File) error
	GetByID(ctx context.Context, id uuid.UUID) (*model.File, error)
	GetByObjectKey(ctx context.Context, objectKey string) (*model.File, error)
	Update(ctx context.Context, file *model.File) error
	SoftDelete(ctx context.Context, id uuid.UUID) error
	SoftDeleteUnbound(ctx context.Context, id uuid.UUID) (bool, error)
	HasActiveBinding(ctx context.Context, id uuid.UUID) (bool, error)
	ListExpiredUnboundUploads(ctx context.Context, purpose enum.FilePurpose, expiredBefore time.Time, limit int) ([]*model.File, error)
}
