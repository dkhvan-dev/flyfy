package app

import "errors"

var (
	ErrUserNotFound       = errors.New("user not found")
	ErrProfileNotFound    = errors.New("user profile not found")
	ErrSettingsNotFound   = errors.New("user settings not found")
	ErrReputationNotFound = errors.New("user reputation not found")

	ErrInvalidUserID      = errors.New("invalid user id")
	ErrInvalidSubjectID   = errors.New("invalid auth subject id")
	ErrInvalidPageToken   = errors.New("invalid page token")
	ErrUserAlreadyExists  = errors.New("user already exists")
	ErrRoleAlreadyGranted = errors.New("role already granted")

	ErrAvatarFileNotFound   = errors.New("avatar file not found")
	ErrAvatarFileNotReady   = errors.New("avatar file is not ready")
	ErrAvatarFileNotAllowed = errors.New("avatar file is not allowed")

	ErrNicknameRequired             = errors.New("nickname is required")
	ErrNicknameImmutable            = errors.New("nickname cannot be changed")
	ErrNicknameAlreadyTaken         = errors.New("nickname is already taken")
	ErrCannotFollowSelf             = errors.New("you cannot follow yourself")
	ErrFollowFeatureUnavailable     = errors.New("follow feature is temporarily unavailable")
	ErrCannotFriendSelf             = errors.New("you cannot add yourself as a friend")
	ErrFriendRequestNotFound        = errors.New("friend request not found")
	ErrFriendshipAlreadyExists      = errors.New("friendship already exists")
	ErrFriendshipFeatureUnavailable = errors.New("friendship feature is temporarily unavailable")
)
