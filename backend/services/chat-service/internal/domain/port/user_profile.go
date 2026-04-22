package port

import (
	"context"

	"github.com/google/uuid"
)

type PublicUserProfile struct {
	UserID       uuid.UUID
	DisplayName  string
	AvatarFileID *string
}

type UserProfileResolver interface {
	GetPublicProfilesByUserIDs(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error)
}
