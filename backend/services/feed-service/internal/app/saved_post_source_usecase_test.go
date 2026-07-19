package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

type savedPostSourceRepositoryStub struct {
	post *model.Post
	err  error
}

func (stub savedPostSourceRepositoryStub) GetPostByID(
	context.Context,
	uuid.UUID,
) (*model.Post, error) {
	return stub.post, stub.err
}

func TestSavedPostSourceUseCaseBuildsPublicProjection(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 18, 9, 30, 0, 0, time.UTC)
	postID := uuid.MustParse("81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de")
	coverID := uuid.MustParse("301d2c5e-cd67-45e9-9c6f-6323b5016254")
	placeName := " Алматы "
	countryCode := "kz"
	post := publicSavedPost(postID, coverID, now)
	post.PlaceName = &placeName
	post.PlaceCountryCode = &countryCode
	useCase := NewSavedPostSourceUseCase(
		savedPostSourceRepositoryStub{post: post},
		WithSavedPostSourceClock(func() time.Time { return now }),
	)

	resolution, err := useCase.ResolvePost(context.Background(), postID)
	if err != nil {
		t.Fatalf("ResolvePost() error = %v", err)
	}
	if !resolution.Eligible || resolution.Visibility != SavedPostSourceVisibilityPublic {
		t.Fatalf("resolution eligibility/visibility = %v/%s", resolution.Eligible, resolution.Visibility)
	}
	if resolution.SourceRevision != 7 || resolution.ProjectionRevision != 7 ||
		resolution.VisibilityRevision != 7 || !resolution.ValidatedAt.Equal(now) {
		t.Fatalf("unexpected resolution revisions/time: %+v", resolution)
	}
	projection := resolution.PublicProjection
	if projection == nil || projection.CanonicalDetailRoute != "/posts/"+postID.String() {
		t.Fatalf("public projection = %#v", projection)
	}
	for _, locale := range []string{"en", "ru", "kk"} {
		localized := projection.Localized[locale]
		if localized.Title != "Поездка в Алматы" ||
			localized.Subtitle != "Маршрут на один день" ||
			localized.Country != "KZ" || localized.DisplayLocation != "Алматы" {
			t.Fatalf("localized[%s] = %#v", locale, localized)
		}
	}
	if projection.Media == nil ||
		projection.Media.OpaqueReference != "post-cover:"+postID.String()+":"+coverID.String()+":7" ||
		projection.Media.ReferenceRevision != 7 ||
		!projection.Media.ValidUntil.Equal(now.Add(savedPostMediaTTL)) {
		t.Fatalf("media projection = %#v", projection.Media)
	}
}

func TestSavedPostSourceUseCasePreservesIntentForNonPublicStates(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 18, 10, 0, 0, 0, time.UTC)
	postID := uuid.MustParse("81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de")
	coverID := uuid.MustParse("301d2c5e-cd67-45e9-9c6f-6323b5016254")
	tests := []struct {
		name       string
		mutate     func(*model.Post)
		visibility SavedPostSourceVisibility
	}{
		{
			name:       "draft",
			mutate:     func(post *model.Post) { post.Status = enum.PostStatusDraft },
			visibility: SavedPostSourceVisibilityRestricted,
		},
		{
			name:       "pending moderation",
			mutate:     func(post *model.Post) { post.ModerationStatus = enum.ModerationStatusPending },
			visibility: SavedPostSourceVisibilityRestricted,
		},
		{
			name:       "archived",
			mutate:     func(post *model.Post) { post.Status = enum.PostStatusArchived },
			visibility: SavedPostSourceVisibilityDeleted,
		},
		{
			name:       "deleted",
			mutate:     func(post *model.Post) { post.DeletedAt = &now },
			visibility: SavedPostSourceVisibilityDeleted,
		},
		{
			name:       "expired",
			mutate:     func(post *model.Post) { post.ExpiresAt = &now },
			visibility: SavedPostSourceVisibilityUnavailable,
		},
		{
			name:       "media binding",
			mutate:     func(post *model.Post) { post.MediaStatus = enum.PostMediaStatusPendingBind },
			visibility: SavedPostSourceVisibilityUnavailable,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			post := publicSavedPost(postID, coverID, now)
			test.mutate(post)
			useCase := NewSavedPostSourceUseCase(
				savedPostSourceRepositoryStub{post: post},
				WithSavedPostSourceClock(func() time.Time { return now }),
			)
			resolution, err := useCase.ResolvePost(context.Background(), postID)
			if err != nil {
				t.Fatalf("ResolvePost() error = %v", err)
			}
			if resolution.Eligible || resolution.Visibility != test.visibility ||
				resolution.PublicProjection != nil {
				t.Fatalf("resolution = %+v, want ineligible %s", resolution, test.visibility)
			}
		})
	}
}

func TestSavedPostSourceUseCaseSupportsTextOnlyQuickPost(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 18, 10, 0, 0, 0, time.UTC)
	postID := uuid.MustParse("81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de")
	post := publicSavedPost(postID, uuid.Nil, now)
	post.Title = ""
	post.Excerpt = ""
	post.ContentPlainText = "  Первый день поездки\nбез отдельного заголовка  "
	post.CoverFileID = nil
	useCase := NewSavedPostSourceUseCase(
		savedPostSourceRepositoryStub{post: post},
		WithSavedPostSourceClock(func() time.Time { return now }),
	)

	resolution, err := useCase.ResolvePost(context.Background(), postID)
	if err != nil {
		t.Fatalf("ResolvePost() error = %v", err)
	}
	localized := resolution.PublicProjection.Localized["ru"]
	if localized.Title != "Первый день поездки без отдельного заголовка" || localized.Subtitle != "" {
		t.Fatalf("quick post projection = %#v", localized)
	}
	if resolution.PublicProjection.Media != nil {
		t.Fatalf("text-only post media = %#v, want nil", resolution.PublicProjection.Media)
	}
}

func TestSavedPostSourceUseCaseMapsMissingAndCanceledReads(t *testing.T) {
	t.Parallel()

	postID := uuid.MustParse("81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de")
	missing := NewSavedPostSourceUseCase(savedPostSourceRepositoryStub{})
	if _, err := missing.ResolvePost(context.Background(), postID); !errors.Is(err, ErrPostNotFound) {
		t.Fatalf("missing ResolvePost() error = %v, want ErrPostNotFound", err)
	}
	canceled := NewSavedPostSourceUseCase(savedPostSourceRepositoryStub{err: context.Canceled})
	if _, err := canceled.ResolvePost(context.Background(), postID); !errors.Is(err, context.Canceled) || !errors.Is(err, ErrSavedPostSourceUnavailable) {
		t.Fatalf("canceled ResolvePost() error = %v", err)
	}
}

func publicSavedPost(postID uuid.UUID, coverID uuid.UUID, now time.Time) *model.Post {
	post := &model.Post{
		ID:               postID,
		Title:            "Поездка в Алматы",
		Excerpt:          "Маршрут на один день",
		ContentPlainText: "Полный текст поста",
		Status:           enum.PostStatusPublished,
		MediaStatus:      enum.PostMediaStatusReady,
		ModerationStatus: enum.ModerationStatusNotRequired,
		Revision:         7,
		PublishedAt:      &now,
		CreatedAt:        now.Add(-time.Hour),
		UpdatedAt:        now,
	}
	if coverID != uuid.Nil {
		post.CoverFileID = &coverID
	}
	return post
}
