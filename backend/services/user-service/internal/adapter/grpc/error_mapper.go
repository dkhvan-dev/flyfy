package grpc

import (
	"errors"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"kz/inflap/backend/services/user-service/internal/adapter/repository"
	"kz/inflap/backend/services/user-service/internal/app"
	"kz/inflap/backend/services/user-service/internal/domain/model"
)

func mapError(err error) error {
	switch {
	case err == nil:
		return nil

	case errors.Is(err, app.ErrInvalidUserID),
		errors.Is(err, app.ErrInvalidSubjectID),
		errors.Is(err, app.ErrInvalidPageToken),
		errors.Is(err, model.ErrInvalidLocale),
		errors.Is(err, model.ErrInvalidTimezone),
		errors.Is(err, model.ErrInvalidCurrency),
		errors.Is(err, model.ErrInvalidSystemRole),
		errors.Is(err, app.ErrNicknameRequired),
		errors.Is(err, app.ErrNicknameImmutable):
		return status.Error(codes.InvalidArgument, err.Error())

	case errors.Is(err, app.ErrUserNotFound),
		errors.Is(err, app.ErrProfileNotFound),
		errors.Is(err, app.ErrSettingsNotFound),
		errors.Is(err, app.ErrReputationNotFound):
		return status.Error(codes.NotFound, err.Error())

	case errors.Is(err, app.ErrUserAlreadyExists),
		errors.Is(err, app.ErrRoleAlreadyGranted),
		errors.Is(err, app.ErrNicknameAlreadyTaken),
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
