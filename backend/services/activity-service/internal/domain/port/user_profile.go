package port

import (
	"context"

	"github.com/google/uuid"
)

type UserProfileProjection struct {
	UserID       uuid.UUID
	Nickname     *string
	AvatarFileID *uuid.UUID
}

type UserProfileResolver interface {
	DisplayNameForUserID(ctx context.Context, userID uuid.UUID) (string, error)
	FilterFriendUserIDs(ctx context.Context, userID uuid.UUID, candidateUserIDs []uuid.UUID) ([]uuid.UUID, error)
	GetUserProfileProjections(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]UserProfileProjection, error)
}

type UserEmailResolver interface {
	EmailForUserID(ctx context.Context, userID uuid.UUID) (string, error)
}
