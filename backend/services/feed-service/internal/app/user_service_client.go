package app

import (
	"context"

	"github.com/google/uuid"
)

type PublicUserProfile struct {
	UserID       uuid.UUID
	Nickname     *string
	AvatarFileID *uuid.UUID
	CountryCode  *string
	Locale       string
	Timezone     string
}

type UserServiceClient interface {
	ResolveUserIDBySubject(ctx context.Context, subject string) (uuid.UUID, error)
	GetPublicUserProfiles(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error)
	FilterFriendUserIDs(ctx context.Context, viewerUserID uuid.UUID, candidateUserIDs []uuid.UUID) (map[uuid.UUID]bool, error)
	FilterFollowingUserIDs(ctx context.Context, viewerUserID uuid.UUID, candidateUserIDs []uuid.UUID) (map[uuid.UUID]bool, error)
}
