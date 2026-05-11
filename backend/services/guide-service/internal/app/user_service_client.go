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
	ResolveUserIDBySubject(ctx context.Context, subject string) (uuid.UUID, error)
	GetPublicUserProfiles(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error)
	ListPublicUserIDsByCountryCodes(ctx context.Context, countryCodes []string) ([]uuid.UUID, error)
	GrantGuideRole(ctx context.Context, userID uuid.UUID, grantedBy *uuid.UUID) error
}
