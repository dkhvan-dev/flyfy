package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestCreatePlaceByAdminUsesConfiguredAuthorWithoutResolvingUserSubject(t *testing.T) {
	t.Parallel()

	adminAuthorID := uuid.MustParse("00000000-0000-4000-8000-000000000001")
	repo := &adminPlaceRepoStub{}
	users := &adminPlaceUserClientStub{resolveErr: errors.New("user-service must not be called")}
	uc := NewPlaceUseCase(repo, users, WithAdminAuthorUserID(adminAuthorID))

	view, err := uc.CreatePlaceByAdmin(context.Background(), CreatePlaceInput{
		Title:         "Big Almaty Lake",
		Description:   "High-mountain reservoir near Almaty.",
		DefaultLocale: "en",
		Translations: map[string]PlaceTranslationInput{
			"en": {Title: "Big Almaty Lake", Description: "High-mountain reservoir near Almaty."},
			"ru": {Title: "Большое Алматинское озеро", Description: "Высокогорное водохранилище рядом с Алматы."},
		},
		CountryCode: "KZ",
		CityID:      "almaty",
		Category:    "NATURE",
		Status:      "PUBLISHED",
	})

	if err != nil {
		t.Fatalf("CreatePlaceByAdmin() error = %v", err)
	}
	if view == nil || view.Place == nil {
		t.Fatal("CreatePlaceByAdmin() returned empty view")
	}
	if users.resolveCalls != 0 {
		t.Fatalf("ResolveUserIDBySubject() calls = %d, want 0", users.resolveCalls)
	}
	if repo.created == nil {
		t.Fatal("repository did not receive place")
	}
	if repo.created.AuthorUserID != adminAuthorID {
		t.Fatalf("authorUserID = %s, want %s", repo.created.AuthorUserID, adminAuthorID)
	}
	if repo.created.Source != enum.SourceImport {
		t.Fatalf("source = %s, want %s", repo.created.Source, enum.SourceImport)
	}
}

func TestReplacePlaceMediaByAdminPreservesImportedMediaMetadata(t *testing.T) {
	t.Parallel()

	placeID := uuid.New()
	repo := &adminPlaceRepoStub{
		created: &model.Place{ID: placeID, AuthorUserID: uuid.New()},
	}
	uc := NewPlaceUseCase(repo, &adminPlaceUserClientStub{})

	err := uc.ReplacePlaceMediaByAdmin(context.Background(), placeID, []ReplaceMediaInput{
		{
			FileID:      uuid.Nil,
			ExternalURL: " https://example.com/imported.jpg ",
			SourceURL:   " https://example.com/source ",
			Credit:      " Imported source ",
			License:     " Source terms ",
			MediaType:   "PHOTO",
			Position:    0,
		},
	})

	if err != nil {
		t.Fatalf("ReplacePlaceMediaByAdmin() error = %v", err)
	}
	if len(repo.replacedMedia) != 1 {
		t.Fatalf("replaced media count = %d, want 1: %#v", len(repo.replacedMedia), repo.replacedMedia)
	}
	got := repo.replacedMedia[0]
	if got.ExternalURL != "https://example.com/imported.jpg" ||
		got.SourceURL != "https://example.com/source" ||
		got.Credit != "Imported source" ||
		got.License != "Source terms" {
		t.Fatalf("imported metadata = %#v, want trimmed external metadata preserved", got)
	}
}

type adminPlaceRepoStub struct {
	created       *model.Place
	replacedMedia []model.PlaceMedia
}

func (r *adminPlaceRepoStub) CreatePlace(_ context.Context, place *model.Place) error {
	copied := *place
	r.created = &copied
	return nil
}

func (r *adminPlaceRepoStub) UpdatePlace(_ context.Context, place *model.Place) error {
	return nil
}

func (r *adminPlaceRepoStub) SoftDeletePlace(_ context.Context, _ uuid.UUID) error {
	return nil
}

func (r *adminPlaceRepoStub) RecoverPlace(_ context.Context, _ uuid.UUID) error {
	return nil
}

func (r *adminPlaceRepoStub) GetPlaceByID(_ context.Context, id uuid.UUID, locale string) (*model.Place, error) {
	if r.created == nil || r.created.ID != id {
		return nil, nil
	}
	copied := *r.created
	copied.Locale = locale
	return &copied, nil
}

func (r *adminPlaceRepoStub) ListPlaces(_ context.Context, _ model.PlaceListFilter) ([]*model.Place, int, error) {
	return nil, 0, nil
}

func (r *adminPlaceRepoStub) ReplacePlaceMedia(_ context.Context, _ uuid.UUID, media []model.PlaceMedia) error {
	r.replacedMedia = append([]model.PlaceMedia(nil), media...)
	return nil
}

func (r *adminPlaceRepoStub) ReplaceTags(_ context.Context, _ uuid.UUID, _ []string) error {
	return nil
}

func (r *adminPlaceRepoStub) CreateReview(_ context.Context, _ *model.PlaceReview) error {
	return nil
}

func (r *adminPlaceRepoStub) SoftDeleteReview(_ context.Context, _, _ uuid.UUID) error {
	return nil
}

func (r *adminPlaceRepoStub) GetReviewByID(_ context.Context, _ uuid.UUID) (*model.PlaceReview, error) {
	return nil, nil
}

func (r *adminPlaceRepoStub) GetReviewByPlaceAndAuthor(_ context.Context, _, _ uuid.UUID) (*model.PlaceReview, error) {
	return nil, nil
}

func (r *adminPlaceRepoStub) ListReviews(_ context.Context, _ uuid.UUID, _, _ int) ([]*model.PlaceReview, int, error) {
	return nil, 0, nil
}

func (r *adminPlaceRepoStub) ReplaceReviewMedia(_ context.Context, _ uuid.UUID, _ []model.ReviewMedia) error {
	return nil
}

func (r *adminPlaceRepoStub) RecalcRating(_ context.Context, _ uuid.UUID) (float64, int, error) {
	return 0, 0, nil
}

func (r *adminPlaceRepoStub) ApplyRatingSourceSnapshot(_ context.Context, _ uuid.UUID, _ string, _ float64, _ int) (float64, int, error) {
	return 0, 0, nil
}

type adminPlaceUserClientStub struct {
	resolveErr   error
	resolveCalls int
}

func (c *adminPlaceUserClientStub) ResolveUserIDBySubject(_ context.Context, _ string) (uuid.UUID, error) {
	c.resolveCalls++
	return uuid.Nil, c.resolveErr
}

func (c *adminPlaceUserClientStub) GetPublicUserProfiles(_ context.Context, userIDs []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error) {
	profiles := make(map[uuid.UUID]PublicUserProfile, len(userIDs))
	for _, id := range userIDs {
		profiles[id] = PublicUserProfile{UserID: id}
	}
	return profiles, nil
}
