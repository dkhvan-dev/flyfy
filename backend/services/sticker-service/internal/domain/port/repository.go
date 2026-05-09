package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/model"
)

type StickerRepository interface {
	ListDefaultPacks(ctx context.Context) ([]*model.StickerPackWithStickers, error)
	ListUserPacks(ctx context.Context, userID uuid.UUID) ([]*model.StickerPackWithStickers, error)
	GetPackByID(ctx context.Context, packID uuid.UUID) (*model.StickerPack, error)
	GetStickerByID(ctx context.Context, stickerID uuid.UUID) (*model.Sticker, error)
	GetStickerByPackAndFile(ctx context.Context, packID uuid.UUID, fileID uuid.UUID) (*model.Sticker, error)
	EnsureCustomPack(ctx context.Context, userID uuid.UUID) (*model.StickerPack, error)
	InstallPack(ctx context.Context, userID, packID uuid.UUID, source string) error
	RemovePack(ctx context.Context, userID, packID uuid.UUID) error
	CreateUploadSession(ctx context.Context, session *model.UploadSession) error
	GetUploadSessionForUpdate(ctx context.Context, sessionID uuid.UUID) (*model.UploadSession, error)
	CreateSticker(ctx context.Context, sticker *model.Sticker) error
	UserHasPackAccess(ctx context.Context, userID, packID uuid.UUID) (bool, error)
	WithTx(ctx context.Context, fn func(repo StickerRepository) error) error
}
