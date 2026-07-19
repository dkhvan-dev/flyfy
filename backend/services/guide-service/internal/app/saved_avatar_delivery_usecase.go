package app

import (
	"context"
	"errors"

	"github.com/google/uuid"
)

var (
	ErrPublicSavedGuideAvatarNotFound    = errors.New("public saved guide avatar not found")
	ErrPublicSavedGuideAvatarUnavailable = errors.New("public saved guide avatar unavailable")
)

type SavedGuideAvatarDeliveryUseCase struct {
	source      *SavedGuideSourceUseCase
	fileManager DownloadURLFileManager
}

func NewSavedGuideAvatarDeliveryUseCase(
	source *SavedGuideSourceUseCase,
	fileManager DownloadURLFileManager,
) *SavedGuideAvatarDeliveryUseCase {
	return &SavedGuideAvatarDeliveryUseCase{
		source:      source,
		fileManager: fileManager,
	}
}

func (u *SavedGuideAvatarDeliveryUseCase) CreatePublicSavedGuideAvatarDownloadURL(
	ctx context.Context,
	userID uuid.UUID,
	savedRevision uint64,
) (string, error) {
	if userID == uuid.Nil || savedRevision == 0 {
		return "", ErrPublicSavedGuideAvatarNotFound
	}
	if u == nil || u.source == nil || u.fileManager == nil {
		return "", ErrPublicSavedGuideAvatarUnavailable
	}

	resolution, err := u.source.ResolveGuide(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrGuideProfileNotFound) {
			return "", ErrPublicSavedGuideAvatarNotFound
		}
		return "", ErrPublicSavedGuideAvatarUnavailable
	}
	media, ok := currentPublicSavedGuideAvatar(resolution, savedRevision)
	if !ok {
		return "", ErrPublicSavedGuideAvatarNotFound
	}
	reference, err := ParseSavedGuideAvatarReference(media.OpaqueReference)
	if err != nil || reference.GuideUserID != userID ||
		reference.Revision != media.ReferenceRevision {
		return "", ErrPublicSavedGuideAvatarNotFound
	}

	fileID, err := u.source.ResolveCurrentGuideAvatarReference(
		ctx,
		media.OpaqueReference,
		savedRevision,
	)
	if err != nil {
		if errors.Is(err, ErrSavedGuideMediaReferenceUnavailable) ||
			errors.Is(err, ErrGuideProfileNotFound) {
			return "", ErrPublicSavedGuideAvatarNotFound
		}
		return "", ErrPublicSavedGuideAvatarUnavailable
	}
	if fileID == uuid.Nil || fileID != reference.AvatarFileID {
		return "", ErrPublicSavedGuideAvatarNotFound
	}

	downloadURL, err := u.fileManager.CreateDownloadURL(ctx, fileID)
	if err != nil {
		if errors.Is(err, ErrFileManagerFileNotFound) {
			return "", ErrPublicSavedGuideAvatarNotFound
		}
		return "", ErrPublicSavedGuideAvatarUnavailable
	}
	downloadURL, err = ValidateFileManagerDownloadURL(downloadURL)
	if err != nil {
		return "", ErrPublicSavedGuideAvatarUnavailable
	}
	return downloadURL, nil
}

func currentPublicSavedGuideAvatar(
	resolution *SavedGuideResolution,
	savedRevision uint64,
) (*SavedGuideMediaReference, bool) {
	if resolution == nil || savedRevision == 0 || !resolution.Eligible ||
		resolution.Visibility != SavedGuideVisibilityPublic ||
		resolution.PublicProjection == nil ||
		resolution.PublicProjection.Media == nil {
		return nil, false
	}
	media := resolution.PublicProjection.Media
	if media.ReferenceRevision != savedRevision {
		return nil, false
	}
	return media, true
}
