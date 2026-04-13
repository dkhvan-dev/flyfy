package app

import "errors"

var (
	ErrFileNotFound        = errors.New("file not found")
	ErrFileNotReady        = errors.New("file is not ready")
	ErrFileNotPublic       = errors.New("file is not public")
	ErrUploadTooLarge      = errors.New("upload size exceeds configured limit")
	ErrInvalidOwnerID      = errors.New("invalid owner id")
	ErrInvalidFileID       = errors.New("invalid file id")
	ErrForbiddenPurpose    = errors.New("invalid purpose value")
	ErrForbiddenVisibility = errors.New("invalid visibility value")
	ErrForbiddenOwnerType  = errors.New("invalid owner type value")

	ErrExtensionNotAllowed   = errors.New("file extension is not allowed")
	ErrContentTypeNotAllowed = errors.New("content type is not allowed")
	ErrFilenameRequired      = errors.New("original file name is required")
	ErrContentTypeRequired   = errors.New("content type is required")
	ErrInvalidFileSize       = errors.New("invalid file size")

	ErrIdempotencyConflict = errors.New("idempotency key reuse with different request payload")
)
