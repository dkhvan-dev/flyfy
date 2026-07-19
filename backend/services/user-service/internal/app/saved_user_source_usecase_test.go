package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
)

func TestSavedUserSourceResolvesEveryActiveUserAsPublic(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	avatarFileID := uuid.New()
	now := time.Date(2026, 7, 16, 8, 0, 0, 0, time.UTC)
	firstName := "Aruzhan"
	lastName := "Sarsen"
	nickname := "@aruzhan"
	country := "kz"
	repository := newFriendshipTestRepository(userID)
	repository.users[userID].UpdatedAt = now.Add(-2 * time.Minute)
	repository.profiles[userID] = &model.UserProfile{
		UserID:       userID,
		FirstName:    &firstName,
		LastName:     &lastName,
		Nickname:     &nickname,
		AvatarFileID: &avatarFileID,
		CountryCode:  &country,
		Locale:       "kk",
		Timezone:     "Asia/Almaty",
		CreatedAt:    now.Add(-time.Hour),
		UpdatedAt:    now.Add(-time.Minute),
	}
	useCase := NewSavedUserSourceUseCase(
		repository,
		WithSavedUserSourceClock(func() time.Time { return now }),
	)

	resolution, err := useCase.ResolveUser(context.Background(), userID)
	if err != nil {
		t.Fatalf("ResolveUser() error = %v", err)
	}
	if !resolution.Eligible || resolution.Visibility != SavedUserVisibilityPublic {
		t.Fatalf("resolution eligibility=%v visibility=%q", resolution.Eligible, resolution.Visibility)
	}
	if resolution.PublicProjection == nil {
		t.Fatal("public projection is nil")
	}
	projection := resolution.PublicProjection
	if projection.SourceDefaultLocale != "kk" ||
		projection.CanonicalDetailRoute != "/users/"+userID.String()+"/profile" {
		t.Fatalf("projection locale=%q route=%q", projection.SourceDefaultLocale, projection.CanonicalDetailRoute)
	}
	for _, locale := range []string{"en", "ru", "kk"} {
		localized := projection.Localized[locale]
		if localized.Title != "Aruzhan Sarsen" || localized.Subtitle != "@aruzhan" ||
			localized.Country != "KZ" {
			t.Fatalf("localized[%s] = %+v", locale, localized)
		}
	}
	if projection.Media == nil || projection.Media.ReferenceRevision != resolution.ProjectionRevision ||
		projection.Media.OpaqueReference == "" || !projection.Media.ValidUntil.Equal(now.Add(savedUserMediaTTL)) {
		t.Fatalf("media = %+v", projection.Media)
	}
}

func TestSavedUserSourceReturnsNeutralNonPublicStateForUnavailableAccounts(t *testing.T) {
	t.Parallel()

	for _, testCase := range []struct {
		name       string
		status     enum.UserStatus
		isDeleted  bool
		visibility SavedUserVisibility
	}{
		{name: "moderated", status: enum.UserStatusBlocked, visibility: SavedUserVisibilityRestricted},
		{name: "deleted", status: enum.UserStatusDeleted, isDeleted: true, visibility: SavedUserVisibilityDeleted},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			userID := uuid.New()
			now := time.Date(2026, 7, 16, 8, 0, 0, 0, time.UTC)
			repository := newFriendshipTestRepository(userID)
			repository.users[userID].Status = testCase.status
			repository.users[userID].IsDeleted = testCase.isDeleted
			repository.users[userID].UpdatedAt = now.Add(-time.Minute)
			useCase := NewSavedUserSourceUseCase(
				repository,
				WithSavedUserSourceClock(func() time.Time { return now }),
			)

			resolution, err := useCase.ResolveUser(context.Background(), userID)
			if err != nil {
				t.Fatalf("ResolveUser() error = %v", err)
			}
			if resolution.Eligible || resolution.Visibility != testCase.visibility ||
				resolution.PublicProjection != nil {
				t.Fatalf("resolution = %+v", resolution)
			}
		})
	}
}

func TestSavedUserSourceUsesLocalizedGenericTitleForIncompleteProfile(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	now := time.Date(2026, 7, 16, 8, 0, 0, 0, time.UTC)
	repository := newFriendshipTestRepository(userID)
	repository.users[userID].UpdatedAt = now.Add(-time.Minute)
	repository.profiles[userID] = &model.UserProfile{
		UserID:    userID,
		Locale:    "ru",
		Timezone:  "Asia/Almaty",
		CreatedAt: now.Add(-time.Hour),
		UpdatedAt: now.Add(-time.Minute),
	}
	useCase := NewSavedUserSourceUseCase(
		repository,
		WithSavedUserSourceClock(func() time.Time { return now }),
	)

	resolution, err := useCase.ResolveUser(context.Background(), userID)
	if err != nil {
		t.Fatalf("ResolveUser() error = %v", err)
	}
	projection := resolution.PublicProjection
	if projection == nil || projection.Localized["en"].Title != "Traveler" ||
		projection.Localized["ru"].Title != "Путешественник" ||
		projection.Localized["kk"].Title != "Саяхатшы" {
		t.Fatalf("projection = %+v", projection)
	}
}
