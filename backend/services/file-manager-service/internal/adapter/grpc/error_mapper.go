package grpc

import (
	"errors"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/app"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func mapError(err error) error {
	switch {
	case err == nil:
		return nil
	case errors.Is(err, app.ErrFileNotFound):
		return status.Error(codes.NotFound, app.ErrorCodeFileNotFound)
	case errors.Is(err, app.ErrFileNotReady):
		return status.Error(codes.FailedPrecondition, app.ErrorCodeFileNotReady)
	case errors.Is(err, app.ErrFileNotPublic):
		return status.Error(codes.PermissionDenied, app.ErrorCodeFileNotPublic)
	case errors.Is(err, app.ErrIdempotencyConflict):
		return status.Error(codes.Aborted, app.ErrorCodeIdempotencyConflict)
	case errors.Is(err, app.ErrInvalidFileID),
		errors.Is(err, app.ErrInvalidOwnerID),
		errors.Is(err, app.ErrForbiddenPurpose),
		errors.Is(err, app.ErrForbiddenVisibility),
		errors.Is(err, app.ErrForbiddenOwnerType),
		errors.Is(err, app.ErrExtensionNotAllowed),
		errors.Is(err, app.ErrContentTypeNotAllowed),
		errors.Is(err, app.ErrFilenameRequired),
		errors.Is(err, app.ErrContentTypeRequired),
		errors.Is(err, app.ErrInvalidFileSize),
		errors.Is(err, app.ErrUploadTooLarge):
		code, _ := app.BusinessErrorCode(err)
		return status.Error(codes.InvalidArgument, code)
	default:
		log.Error().Err(err).Str("transport", "grpc").Msg("grpc technical error")
		return status.Error(codes.Internal, "technical_error")
	}
}
