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

const (
	ErrorCodeFileNotFound          = "file_not_found"
	ErrorCodeFileNotReady          = "file_not_ready"
	ErrorCodeFileNotPublic         = "file_not_public"
	ErrorCodeUploadTooLarge        = "upload_too_large"
	ErrorCodeInvalidOwnerID        = "invalid_owner_id"
	ErrorCodeInvalidFileID         = "invalid_file_id"
	ErrorCodeForbiddenPurpose      = "invalid_purpose"
	ErrorCodeForbiddenVisibility   = "invalid_visibility"
	ErrorCodeForbiddenOwnerType    = "invalid_owner_type"
	ErrorCodeExtensionNotAllowed   = "extension_not_allowed"
	ErrorCodeContentTypeNotAllowed = "content_type_not_allowed"
	ErrorCodeFilenameRequired      = "filename_required"
	ErrorCodeContentTypeRequired   = "content_type_required"
	ErrorCodeInvalidFileSize       = "invalid_file_size"
	ErrorCodeIdempotencyConflict   = "idempotency_conflict"
)

func BusinessErrorCode(err error) (string, bool) {
	switch {
	case errors.Is(err, ErrFileNotFound):
		return ErrorCodeFileNotFound, true
	case errors.Is(err, ErrFileNotReady):
		return ErrorCodeFileNotReady, true
	case errors.Is(err, ErrFileNotPublic):
		return ErrorCodeFileNotPublic, true
	case errors.Is(err, ErrUploadTooLarge):
		return ErrorCodeUploadTooLarge, true
	case errors.Is(err, ErrInvalidOwnerID):
		return ErrorCodeInvalidOwnerID, true
	case errors.Is(err, ErrInvalidFileID):
		return ErrorCodeInvalidFileID, true
	case errors.Is(err, ErrForbiddenPurpose):
		return ErrorCodeForbiddenPurpose, true
	case errors.Is(err, ErrForbiddenVisibility):
		return ErrorCodeForbiddenVisibility, true
	case errors.Is(err, ErrForbiddenOwnerType):
		return ErrorCodeForbiddenOwnerType, true
	case errors.Is(err, ErrExtensionNotAllowed):
		return ErrorCodeExtensionNotAllowed, true
	case errors.Is(err, ErrContentTypeNotAllowed):
		return ErrorCodeContentTypeNotAllowed, true
	case errors.Is(err, ErrFilenameRequired):
		return ErrorCodeFilenameRequired, true
	case errors.Is(err, ErrContentTypeRequired):
		return ErrorCodeContentTypeRequired, true
	case errors.Is(err, ErrInvalidFileSize):
		return ErrorCodeInvalidFileSize, true
	case errors.Is(err, ErrIdempotencyConflict):
		return ErrorCodeIdempotencyConflict, true
	default:
		return "", false
	}
}
