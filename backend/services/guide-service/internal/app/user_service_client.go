package app

import (
	"context"

	"github.com/google/uuid"
)

type PublicUserProfile struct {
	UserID       uuid.UUID
	DisplayName  *string
	AvatarFileID *uuid.UUID
	CountryCode  *string
	Locale       string
	Timezone     string
	IsPublic     bool
}

type UserServiceClient interface {
	ValidateUserExists(ctx context.Context, userID uuid.UUID) error
	GetPublicUserProfiles(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error)
}
