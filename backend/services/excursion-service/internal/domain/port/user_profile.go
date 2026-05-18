package port

import (
	"context"

	"github.com/google/uuid"
)

type UserProfileProjection struct {
	UserID       uuid.UUID
	DisplayName  *string
	AvatarFileID *uuid.UUID
}

type UserProfileResolver interface {
	GetUserProfileProjections(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]UserProfileProjection, error)
}
