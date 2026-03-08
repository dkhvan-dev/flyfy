package app

import (
	"context"

	"github.com/google/uuid"
)

type FileManagerClient interface {
	ValidateAvatarFile(ctx context.Context, fileID uuid.UUID) error
	BindAvatarToUser(ctx context.Context, fileID uuid.UUID, userID uuid.UUID, createdByUserID *uuid.UUID) error
}
