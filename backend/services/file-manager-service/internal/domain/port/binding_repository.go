package port

import (
	"context"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
)

type FileBindingRepository interface {
	Create(ctx context.Context, binding *model.FileBinding) error
	GetPrimaryByOwnerAndPurpose(ctx context.Context, ownerType enum.OwnerType, ownerID uuid.UUID, purpose enum.FilePurpose) (*model.FileBinding, error)
	SoftDeletePrimaryByOwnerAndPurpose(ctx context.Context, ownerType enum.OwnerType, ownerID uuid.UUID, purpose enum.FilePurpose) error
	ListByFileID(ctx context.Context, fileID uuid.UUID) ([]*model.FileBinding, error)
	ListByOwnerAndPurpose(ctx context.Context, ownerType enum.OwnerType, ownerID uuid.UUID, purpose enum.FilePurpose, limit int) ([]*model.FileBinding, error)

	CreateWithPrimarySwitchTx(
		ctx context.Context,
		binding *model.FileBinding,
	) error
}
