package port

import (
	"context"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
)

type UserConnectionListOptions struct {
	SearchQuery   string
	Sort          string
	SortDirection string
	OnlineOnly    bool
	Limit         int
	Offset        int
}

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
	ListAdminUsers(
		ctx context.Context,
		filter model.AdminUserListFilter,
	) ([]model.AdminUserListItem, string, error)
	GetAdminUserDetail(ctx context.Context, userID uuid.UUID) (model.AdminUserDetail, error)

	GetProfileByUserID(ctx context.Context, userID uuid.UUID) (*model.UserProfile, error)
	IsDisplayNameTaken(ctx context.Context, displayName string, excludeUserID uuid.UUID) (bool, error)
	GetSettingsByUserID(ctx context.Context, userID uuid.UUID) (*model.UserSettings, error)
	GetReputationByUserID(ctx context.Context, userID uuid.UUID) (*model.UserReputation, error)
	ListRolesByUserID(ctx context.Context, userID uuid.UUID) ([]*model.UserSystemRole, error)
	CountFollowersByUserID(ctx context.Context, userID uuid.UUID) (int, error)
	IsFollowing(ctx context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) (bool, error)
	GetFriendship(ctx context.Context, userAID uuid.UUID, userBID uuid.UUID) (*model.UserFriendship, error)

	UpdateProfile(ctx context.Context, profile *model.UserProfile) error
	UpdateLastSeen(ctx context.Context, userID uuid.UUID) (*model.User, error)
	UpdateSettings(ctx context.Context, settings *model.UserSettings) error
	FollowUser(ctx context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) error
	UnfollowUser(ctx context.Context, followerUserID uuid.UUID, followedUserID uuid.UUID) error
	CreateFriendRequest(ctx context.Context, requesterUserID uuid.UUID, addresseeUserID uuid.UUID) error
	AcceptFriendRequest(ctx context.Context, requesterUserID uuid.UUID, addresseeUserID uuid.UUID) error
	DeleteFriendship(ctx context.Context, userAID uuid.UUID, userBID uuid.UUID) error

	GrantRole(ctx context.Context, role *model.UserSystemRole) error
	RevokeRole(ctx context.Context, userID uuid.UUID, role enum.SystemRole) error
	HasRole(ctx context.Context, userID uuid.UUID, role enum.SystemRole) (bool, error)

	ListPublicProfiles(ctx context.Context, limit int, offset int) ([]*model.UserProfile, error)
	GetPublicProfilesByUserIDs(ctx context.Context, userIDs []uuid.UUID) ([]*model.UserProfile, error)
	ListPublicUserIDsByCountryCodes(ctx context.Context, countryCodes []string) ([]uuid.UUID, error)
	ListFollowersByUserID(
		ctx context.Context,
		userID uuid.UUID,
		searchQuery string,
		limit int,
		offset int,
	) ([]*model.UserProfile, error)
	ListFriendsByUserID(
		ctx context.Context,
		userID uuid.UUID,
		options UserConnectionListOptions,
	) ([]*model.UserProfile, error)
	ListIncomingFriendRequestsByUserID(
		ctx context.Context,
		userID uuid.UUID,
		options UserConnectionListOptions,
	) ([]*model.UserFriendRequest, error)
	ListFollowingByUserID(
		ctx context.Context,
		userID uuid.UUID,
		options UserConnectionListOptions,
	) ([]*model.UserProfile, error)

	PatchUserIdentityBySubject(
		ctx context.Context,
		subjectID string,
		primaryPhone *string,
		primaryEmail *string,
	) error
}
