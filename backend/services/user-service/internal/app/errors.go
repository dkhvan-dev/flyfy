package app

import "errors"

var (
	ErrUserNotFound       = errors.New("user not found")
	ErrProfileNotFound    = errors.New("user profile not found")
	ErrSettingsNotFound   = errors.New("user settings not found")
	ErrReputationNotFound = errors.New("user reputation not found")

	ErrInvalidUserID      = errors.New("invalid user id")
	ErrInvalidSubjectID   = errors.New("invalid auth subject id")
	ErrUserAlreadyExists  = errors.New("user already exists")
	ErrRoleAlreadyGranted = errors.New("role already granted")

	ErrAvatarFileNotFound   = errors.New("avatar file not found")
	ErrAvatarFileNotReady   = errors.New("avatar file is not ready")
	ErrAvatarFileNotAllowed = errors.New("avatar file is not allowed")

	ErrDisplayNameAlreadyTaken  = errors.New("display name is already taken")
	ErrCannotFollowSelf         = errors.New("you cannot follow yourself")
	ErrFollowFeatureUnavailable = errors.New("follow feature is temporarily unavailable")
)
