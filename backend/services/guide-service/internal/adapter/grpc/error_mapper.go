package grpc

import (
	"errors"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"kz/inflap/backend/services/guide-service/internal/adapter/repository"
	"kz/inflap/backend/services/guide-service/internal/app"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

func mapError(err error) error {
	switch {
	case err == nil:
		return nil

	case errors.Is(err, app.ErrInvalidGuideProfileID),
		errors.Is(err, app.ErrInvalidGuideUserID),
		errors.Is(err, model.ErrInvalidGuideType),
		errors.Is(err, model.ErrInvalidGuideStatus),
		errors.Is(err, model.ErrInvalidExperienceYears),
		errors.Is(err, model.ErrInvalidGuideLanguageCode),
		errors.Is(err, model.ErrInvalidGuideLanguageProficiencyLevel),
		errors.Is(err, model.ErrInvalidGuideSpecializationCode),
		errors.Is(err, model.ErrInvalidGuideDocumentType),
		errors.Is(err, model.ErrInvalidVerificationStatus),
		errors.Is(err, app.ErrGuideDocumentFileNotFound),
		errors.Is(err, app.ErrGuideDocumentFileNotReady),
		errors.Is(err, app.ErrGuideDocumentFileNotAllowed):
		return status.Error(codes.InvalidArgument, err.Error())

	case errors.Is(err, app.ErrGuideProfileNotFound),
		errors.Is(err, app.ErrVerificationRequestNotFound),
		errors.Is(err, app.ErrUserNotFound):
		return status.Error(codes.NotFound, err.Error())

	case errors.Is(err, app.ErrGuideProfileAlreadyExists),
		errors.Is(err, repository.ErrConflict):
		return status.Error(codes.AlreadyExists, err.Error())

	default:
		return status.Error(codes.Internal, "internal server error")
	}
}
