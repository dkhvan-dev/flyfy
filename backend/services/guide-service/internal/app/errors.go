package app

import "errors"

var (
	ErrGuideProfileNotFound        = errors.New("guide profile not found")
	ErrVerificationRequestNotFound = errors.New("verification request not found")

	ErrInvalidGuideProfileID     = errors.New("invalid guide profile id")
	ErrInvalidGuideUserID        = errors.New("invalid guide user id")
	ErrGuideProfileAlreadyExists = errors.New("guide profile already exists")

	ErrUserNotFound                = errors.New("user not found")
	ErrGuideDocumentFileNotFound   = errors.New("guide document file not found")
	ErrGuideDocumentFileNotReady   = errors.New("guide document file is not ready")
	ErrGuideDocumentFileNotAllowed = errors.New("guide document file is not allowed")
)
