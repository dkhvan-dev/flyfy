package port

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type PublicUserProfile struct {
	UserID       uuid.UUID
	DisplayName  string
	AvatarFileID *string
	IsOnline     bool
	LastSeenAt   *time.Time
}

type UserProfileResolver interface {
	GetPublicProfilesByUserIDs(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error)
}
