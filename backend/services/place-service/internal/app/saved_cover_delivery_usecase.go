package app

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"unicode"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

var (
	ErrPublicSavedAttractionCoverNotFound    = errors.New("public Saved attraction cover not found")
	ErrPublicSavedAttractionCoverUnavailable = errors.New("public Saved attraction cover unavailable")
	ErrPublicSavedAttractionCoverBadGateway  = errors.New("public Saved attraction cover dependency returned an invalid response")

	ErrSavedCoverFileNotFound           = errors.New("Saved cover file not found")
	ErrSavedCoverFileManagerUnavailable = errors.New("Saved cover file manager unavailable")
	ErrSavedCoverFileManagerBadResponse = errors.New("Saved cover file manager returned an invalid response")
	ErrSavedCoverDownloadURLInvalid     = errors.New("Saved cover download URL is invalid")
)

type SavedAttractionCoverRepository interface {
	GetSavedAttractionCoverSnapshot(
		ctx context.Context,
		attractionID uuid.UUID,
	) (*model.SavedAttractionCoverSnapshot, error)
}

type SavedCoverFileManager interface {
	CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error)
}

type SavedAttractionCoverDeliveryUseCase struct {
	repo        SavedAttractionCoverRepository
	fileManager SavedCoverFileManager
}

func NewSavedAttractionCoverDeliveryUseCase(
	repo SavedAttractionCoverRepository,
	fileManager SavedCoverFileManager,
) *SavedAttractionCoverDeliveryUseCase {
	return &SavedAttractionCoverDeliveryUseCase{
		repo:        repo,
		fileManager: fileManager,
	}
}

func (u *SavedAttractionCoverDeliveryUseCase) CreatePublicSavedAttractionCoverDownloadURL(
	ctx context.Context,
	attractionID uuid.UUID,
	savedRevision uint64,
) (string, error) {
	if attractionID == uuid.Nil || savedRevision == 0 {
		return "", ErrPublicSavedAttractionCoverNotFound
	}
	if u == nil || u.repo == nil || u.fileManager == nil {
		return "", ErrPublicSavedAttractionCoverUnavailable
	}

	snapshot, err := u.repo.GetSavedAttractionCoverSnapshot(ctx, attractionID)
	if err != nil {
		return "", ErrPublicSavedAttractionCoverUnavailable
	}
	if !isCurrentPublicSavedAttractionCover(snapshot, attractionID, savedRevision) {
		return "", ErrPublicSavedAttractionCoverNotFound
	}

	downloadURL, err := u.fileManager.CreateDownloadURL(ctx, snapshot.FileID)
	if err != nil {
		switch {
		case errors.Is(err, ErrSavedCoverFileNotFound):
			return "", ErrPublicSavedAttractionCoverNotFound
		case errors.Is(err, ErrSavedCoverFileManagerUnavailable):
			return "", ErrPublicSavedAttractionCoverUnavailable
		default:
			return "", ErrPublicSavedAttractionCoverBadGateway
		}
	}
	downloadURL, err = ValidateSavedCoverDownloadURL(downloadURL)
	if err != nil {
		return "", ErrPublicSavedAttractionCoverBadGateway
	}
	return downloadURL, nil
}

func isCurrentPublicSavedAttractionCover(
	snapshot *model.SavedAttractionCoverSnapshot,
	attractionID uuid.UUID,
	savedRevision uint64,
) bool {
	return snapshot != nil &&
		snapshot.ID == attractionID &&
		snapshot.Status == enum.StatusPublished &&
		snapshot.DeletedAt == nil &&
		snapshot.ProjectionRevision == savedRevision &&
		snapshot.ProjectionRevision > 0 &&
		snapshot.FileID != uuid.Nil
}

func ValidateSavedCoverDownloadURL(value string) (string, error) {
	if value == "" || value != strings.TrimSpace(value) ||
		strings.ContainsRune(value, '\\') || strings.ContainsFunc(value, unicode.IsControl) {
		return "", ErrSavedCoverDownloadURLInvalid
	}

	parsed, err := url.ParseRequestURI(value)
	if err != nil || parsed == nil || parsed.Opaque != "" || parsed.User != nil ||
		parsed.Host == "" || parsed.Hostname() == "" ||
		(parsed.Scheme != "http" && parsed.Scheme != "https") {
		return "", ErrSavedCoverDownloadURLInvalid
	}
	decoded, err := url.PathUnescape(value)
	if err != nil || strings.ContainsFunc(decoded, unicode.IsControl) {
		return "", ErrSavedCoverDownloadURLInvalid
	}

	return value, nil
}
