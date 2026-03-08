package grpc

import (
	"errors"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/app"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func mapError(err error) error {
	switch {
	case err == nil:
		return nil
	case errors.Is(err, app.ErrFileNotFound):
		return status.Error(codes.NotFound, err.Error())
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
		return status.Error(codes.InvalidArgument, err.Error())
	default:
		return status.Error(codes.Internal, "internal server error")
	}
}
