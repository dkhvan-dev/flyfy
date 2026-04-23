package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
)

type UserRepository interface {
	CreateUserAggregate(
		ctx context.Context,
		user *model.User,
		profile *model.UserProfile,
		settings *model.UserSettings,
		reputation *model.UserReputation,
		defaultRole *model.UserSystemRole,
	) error

	GetUserByID(ctx context.Context, userID uuid.UUID) (*model.User, error)
	GetUserBySubject(ctx context.Context, subject string) (*model.User, error)

	GetProfileByUserID(ctx context.Context, userID uuid.UUID) (*model.UserProfile, error)
	IsDisplayNameTaken(ctx context.Context, displayName string, excludeUserID uuid.UUID) (bool, error)
	GetSettingsByUserID(ctx context.Context, userID uuid.UUID) (*model.UserSettings, error)
	GetReputationByUserID(ctx context.Context, userID uuid.UUID) (*model.UserReputation, error)
	ListRolesByUserID(ctx context.Context, userID uuid.UUID) ([]*model.UserSystemRole, error)
	CountFollowersByUserID(ctx context.Context, userID uuid.UUID) (int, error)
	IsFollowing(ctx context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) (bool, error)

	UpdateProfile(ctx context.Context, profile *model.UserProfile) error
	UpdateLastSeen(ctx context.Context, userID uuid.UUID) (*model.User, error)
	UpdateSettings(ctx context.Context, settings *model.UserSettings) error
	FollowUser(ctx context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) error
	UnfollowUser(ctx context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) error

	GrantRole(ctx context.Context, role *model.UserSystemRole) error
	HasRole(ctx context.Context, userID uuid.UUID, role enum.SystemRole) (bool, error)

	ListPublicProfiles(ctx context.Context, limit int, offset int) ([]*model.UserProfile, error)
	GetPublicProfilesByUserIDs(ctx context.Context, userIDs []uuid.UUID) ([]*model.UserProfile, error)
	ListFollowersByUserID(
		ctx context.Context,
		userID uuid.UUID,
		searchQuery string,
		limit int,
		offset int,
	) ([]*model.UserProfile, error)

	PatchUserIdentityBySubject(
		ctx context.Context,
		subjectID string,
		primaryPhone *string,
		primaryEmail *string,
	) error
}
