package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

const (
	savedPostTitleMaxBytes    = 256
	savedPostSubtitleMaxBytes = 512
	savedPostPlaceMaxBytes    = 128
	savedPostMediaTTL         = 5 * time.Minute
)

var ErrSavedPostSourceUnavailable = errors.New("saved post source unavailable")

type SavedPostSourceVisibility string

const (
	SavedPostSourceVisibilityPublic      SavedPostSourceVisibility = "PUBLIC"
	SavedPostSourceVisibilityUnavailable SavedPostSourceVisibility = "UNAVAILABLE"
	SavedPostSourceVisibilityDeleted     SavedPostSourceVisibility = "DELETED"
	SavedPostSourceVisibilityRestricted  SavedPostSourceVisibility = "RESTRICTED"
)

type SavedPostSourceRepository interface {
	GetPostByID(context.Context, uuid.UUID) (*model.Post, error)
}

type SavedPostLocalizedProjection struct {
	Title           string
	Subtitle        string
	Country         string
	DisplayLocation string
}

type SavedPostMediaReference struct {
	OpaqueReference   string
	ReferenceRevision uint64
	ValidUntil        time.Time
}

type SavedPostPublicProjection struct {
	SourceDefaultLocale  string
	Localized            map[string]SavedPostLocalizedProjection
	CanonicalDetailRoute string
	Media                *SavedPostMediaReference
}

type SavedPostSourceResolution struct {
	Eligible           bool
	Visibility         SavedPostSourceVisibility
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
	ValidatedAt        time.Time
	PublicProjection   *SavedPostPublicProjection
}

type SavedPostSourceUseCase struct {
	repository SavedPostSourceRepository
	now        func() time.Time
}

type SavedPostSourceOption func(*SavedPostSourceUseCase)

func WithSavedPostSourceClock(now func() time.Time) SavedPostSourceOption {
	return func(useCase *SavedPostSourceUseCase) {
		if now != nil {
			useCase.now = now
		}
	}
}

func NewSavedPostSourceUseCase(
	repository SavedPostSourceRepository,
	options ...SavedPostSourceOption,
) *SavedPostSourceUseCase {
	useCase := &SavedPostSourceUseCase{repository: repository, now: time.Now}
	for _, option := range options {
		option(useCase)
	}
	return useCase
}

func (useCase *SavedPostSourceUseCase) ResolvePost(
	ctx context.Context,
	postID uuid.UUID,
) (*SavedPostSourceResolution, error) {
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}
	if useCase == nil || useCase.repository == nil || useCase.now == nil {
		return nil, ErrSavedPostSourceUnavailable
	}
	post, err := useCase.repository.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("%w: load post snapshot: %w", ErrSavedPostSourceUnavailable, err)
	}
	if post == nil {
		return nil, ErrPostNotFound
	}
	if post.ID != postID || post.Revision <= 0 {
		return nil, ErrSavedPostSourceUnavailable
	}

	validatedAt := useCase.now().UTC()
	revision := uint64(post.Revision)
	visibility, projection := resolveSavedPostSnapshot(post, validatedAt)
	resolution := &SavedPostSourceResolution{
		Visibility:         visibility,
		SourceRevision:     revision,
		ProjectionRevision: revision,
		VisibilityRevision: revision,
		ValidatedAt:        validatedAt,
	}
	if visibility != SavedPostSourceVisibilityPublic || projection == nil {
		return resolution, nil
	}
	resolution.Eligible = true
	resolution.PublicProjection = projection
	return resolution, nil
}

func resolveSavedPostSnapshot(
	post *model.Post,
	validatedAt time.Time,
) (SavedPostSourceVisibility, *SavedPostPublicProjection) {
	visibility := savedPostVisibility(post, validatedAt)
	if visibility != SavedPostSourceVisibilityPublic {
		return visibility, nil
	}
	projection, ok := savedPostPublicProjection(post, validatedAt)
	if !ok {
		return SavedPostSourceVisibilityRestricted, nil
	}
	return SavedPostSourceVisibilityPublic, projection
}

func savedPostVisibility(post *model.Post, validatedAt time.Time) SavedPostSourceVisibility {
	if post == nil {
		return SavedPostSourceVisibilityUnavailable
	}
	if post.DeletedAt != nil || post.Status == enum.PostStatusArchived || post.ArchivedAt != nil {
		return SavedPostSourceVisibilityDeleted
	}
	if post.Status != enum.PostStatusPublished {
		return SavedPostSourceVisibilityRestricted
	}
	if post.ExpiresAt != nil && !post.ExpiresAt.After(validatedAt) {
		return SavedPostSourceVisibilityUnavailable
	}
	if enum.NormalizePostMediaStatus(post.MediaStatus) != enum.PostMediaStatusReady {
		return SavedPostSourceVisibilityUnavailable
	}
	switch post.ModerationStatus {
	case enum.ModerationStatusNotRequired, enum.ModerationStatusApproved:
		return SavedPostSourceVisibilityPublic
	default:
		return SavedPostSourceVisibilityRestricted
	}
}

func savedPostPublicProjection(
	post *model.Post,
	validatedAt time.Time,
) (*SavedPostPublicProjection, bool) {
	if post == nil || post.ID == uuid.Nil || post.Revision <= 0 {
		return nil, false
	}
	title := firstBoundedSavedPostText(
		savedPostTitleMaxBytes,
		post.Title,
		post.ContentPlainText,
		post.Excerpt,
	)
	if title == "" {
		return nil, false
	}
	subtitle := firstBoundedSavedPostText(
		savedPostSubtitleMaxBytes,
		post.Excerpt,
		post.ContentPlainText,
	)
	if subtitle == title {
		subtitle = ""
	}
	localizedValue := SavedPostLocalizedProjection{
		Title:           title,
		Subtitle:        subtitle,
		Country:         boundedSavedPostText(strings.ToUpper(valueOrEmpty(post.PlaceCountryCode)), savedPostPlaceMaxBytes),
		DisplayLocation: boundedSavedPostText(valueOrEmpty(post.PlaceName), savedPostPlaceMaxBytes),
	}
	projection := &SavedPostPublicProjection{
		SourceDefaultLocale: "en",
		Localized: map[string]SavedPostLocalizedProjection{
			"en": localizedValue,
			"ru": localizedValue,
			"kk": localizedValue,
		},
		CanonicalDetailRoute: "/posts/" + post.ID.String(),
	}
	if post.CoverFileID != nil && *post.CoverFileID != uuid.Nil {
		revision := uint64(post.Revision)
		projection.Media = &SavedPostMediaReference{
			OpaqueReference: fmt.Sprintf(
				"post-cover:%s:%s:%d",
				post.ID,
				post.CoverFileID.String(),
				revision,
			),
			ReferenceRevision: revision,
			ValidUntil:        validatedAt.Add(savedPostMediaTTL),
		}
	}
	return projection, true
}

func boundedSavedPostText(value string, maxBytes int) string {
	value = strings.Map(func(character rune) rune {
		if unicode.IsControl(character) {
			return ' '
		}
		return character
	}, value)
	value = strings.Join(strings.Fields(value), " ")
	if value == "" || len(value) <= maxBytes {
		return value
	}
	end := 0
	for index := range value {
		if index > maxBytes {
			break
		}
		end = index
	}
	if end == 0 {
		_, size := utf8.DecodeRuneInString(value)
		if size > maxBytes {
			return ""
		}
		end = size
	}
	return strings.TrimSpace(value[:end])
}

func firstBoundedSavedPostText(maxBytes int, values ...string) string {
	for _, value := range values {
		if bounded := boundedSavedPostText(value, maxBytes); bounded != "" {
			return bounded
		}
	}
	return ""
}

func valueOrEmpty(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
