package grpc

import (
	"errors"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func mapError(err error) error {
	switch {
	case err == nil:
		return nil

	case errors.Is(err, app.ErrInvalidUserID),
		errors.Is(err, app.ErrInvalidSubjectID),
		errors.Is(err, model.ErrInvalidLocale),
		errors.Is(err, model.ErrInvalidTimezone),
		errors.Is(err, model.ErrInvalidCurrency),
		errors.Is(err, model.ErrInvalidSystemRole):
		return status.Error(codes.InvalidArgument, err.Error())

	case errors.Is(err, app.ErrUserNotFound),
		errors.Is(err, app.ErrProfileNotFound),
		errors.Is(err, app.ErrSettingsNotFound),
		errors.Is(err, app.ErrReputationNotFound):
		return status.Error(codes.NotFound, err.Error())

	case errors.Is(err, app.ErrUserAlreadyExists),
		errors.Is(err, app.ErrRoleAlreadyGranted),
		errors.Is(err, repository.ErrConflict):
		return status.Error(codes.AlreadyExists, err.Error())

	case errors.Is(err, app.ErrInvalidUserID),
		errors.Is(err, app.ErrInvalidSubjectID),
		errors.Is(err, model.ErrInvalidLocale),
		errors.Is(err, model.ErrInvalidTimezone),
		errors.Is(err, model.ErrInvalidCurrency),
		errors.Is(err, model.ErrInvalidSystemRole),
		errors.Is(err, app.ErrAvatarFileNotFound),
		errors.Is(err, app.ErrAvatarFileNotReady),
		errors.Is(err, app.ErrAvatarFileNotAllowed):
		return status.Error(codes.InvalidArgument, err.Error())

	default:
		return status.Error(codes.Internal, "internal server error")
	}
}
