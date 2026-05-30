package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/attraction-service/internal/domain/enum"
	"kz/inflap/backend/services/attraction-service/internal/domain/model"
)

func TestCreateAttractionByAdminUsesConfiguredAuthorWithoutResolvingUserSubject(t *testing.T) {
	t.Parallel()

	adminAuthorID := uuid.MustParse("00000000-0000-4000-8000-000000000001")
	repo := &adminAttractionRepoStub{}
	users := &adminAttractionUserClientStub{resolveErr: errors.New("user-service must not be called")}
	uc := NewAttractionUseCase(repo, users, WithAdminAuthorUserID(adminAuthorID))

	view, err := uc.CreateAttractionByAdmin(context.Background(), CreateAttractionInput{
		Title:         "Big Almaty Lake",
		Description:   "High-mountain reservoir near Almaty.",
		DefaultLocale: "en",
		Translations: map[string]AttractionTranslationInput{
			"en": {Title: "Big Almaty Lake", Description: "High-mountain reservoir near Almaty."},
			"ru": {Title: "Большое Алматинское озеро", Description: "Высокогорное водохранилище рядом с Алматы."},
		},
		CountryCode: "KZ",
		CityID:      "almaty",
		Category:    "NATURE",
		Status:      "PUBLISHED",
	})

	if err != nil {
		t.Fatalf("CreateAttractionByAdmin() error = %v", err)
	}
	if view == nil || view.Attraction == nil {
		t.Fatal("CreateAttractionByAdmin() returned empty view")
	}
	if users.resolveCalls != 0 {
		t.Fatalf("ResolveUserIDBySubject() calls = %d, want 0", users.resolveCalls)
	}
	if repo.created == nil {
		t.Fatal("repository did not receive attraction")
	}
	if repo.created.AuthorUserID != adminAuthorID {
		t.Fatalf("authorUserID = %s, want %s", repo.created.AuthorUserID, adminAuthorID)
	}
	if repo.created.Source != enum.SourceImport {
		t.Fatalf("source = %s, want %s", repo.created.Source, enum.SourceImport)
	}
}

func TestReplaceAttractionMediaByAdminPreservesImportedMediaMetadata(t *testing.T) {
	t.Parallel()

	attractionID := uuid.New()
	repo := &adminAttractionRepoStub{
		created: &model.Attraction{ID: attractionID, AuthorUserID: uuid.New()},
	}
	uc := NewAttractionUseCase(repo, &adminAttractionUserClientStub{})

	err := uc.ReplaceAttractionMediaByAdmin(context.Background(), attractionID, []ReplaceMediaInput{
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
		t.Fatalf("ReplaceAttractionMediaByAdmin() error = %v", err)
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

type adminAttractionRepoStub struct {
	created       *model.Attraction
	replacedMedia []model.AttractionMedia
}

func (r *adminAttractionRepoStub) CreateAttraction(_ context.Context, attraction *model.Attraction) error {
	copied := *attraction
	r.created = &copied
	return nil
}

func (r *adminAttractionRepoStub) UpdateAttraction(_ context.Context, attraction *model.Attraction) error {
	return nil
}

func (r *adminAttractionRepoStub) SoftDeleteAttraction(_ context.Context, _ uuid.UUID) error {
	return nil
}

func (r *adminAttractionRepoStub) RecoverAttraction(_ context.Context, _ uuid.UUID) error {
	return nil
}

func (r *adminAttractionRepoStub) GetAttractionByID(_ context.Context, id uuid.UUID, locale string) (*model.Attraction, error) {
	if r.created == nil || r.created.ID != id {
		return nil, nil
	}
	copied := *r.created
	copied.Locale = locale
	return &copied, nil
}

func (r *adminAttractionRepoStub) ListAttractions(_ context.Context, _ model.AttractionListFilter) ([]*model.Attraction, int, error) {
	return nil, 0, nil
}

func (r *adminAttractionRepoStub) ReplaceAttractionMedia(_ context.Context, _ uuid.UUID, media []model.AttractionMedia) error {
	r.replacedMedia = append([]model.AttractionMedia(nil), media...)
	return nil
}

func (r *adminAttractionRepoStub) ReplaceTags(_ context.Context, _ uuid.UUID, _ []string) error {
	return nil
}

func (r *adminAttractionRepoStub) CreateReview(_ context.Context, _ *model.AttractionReview) error {
	return nil
}

func (r *adminAttractionRepoStub) SoftDeleteReview(_ context.Context, _, _ uuid.UUID) error {
	return nil
}

func (r *adminAttractionRepoStub) GetReviewByID(_ context.Context, _ uuid.UUID) (*model.AttractionReview, error) {
	return nil, nil
}

func (r *adminAttractionRepoStub) GetReviewByAttractionAndAuthor(_ context.Context, _, _ uuid.UUID) (*model.AttractionReview, error) {
	return nil, nil
}

func (r *adminAttractionRepoStub) ListReviews(_ context.Context, _ uuid.UUID, _, _ int) ([]*model.AttractionReview, int, error) {
	return nil, 0, nil
}

func (r *adminAttractionRepoStub) ReplaceReviewMedia(_ context.Context, _ uuid.UUID, _ []model.ReviewMedia) error {
	return nil
}

func (r *adminAttractionRepoStub) RecalcRating(_ context.Context, _ uuid.UUID) (float64, int, error) {
	return 0, 0, nil
}

func (r *adminAttractionRepoStub) ApplyRatingSourceSnapshot(_ context.Context, _ uuid.UUID, _ string, _ float64, _ int) (float64, int, error) {
	return 0, 0, nil
}

type adminAttractionUserClientStub struct {
	resolveErr   error
	resolveCalls int
}

func (c *adminAttractionUserClientStub) ResolveUserIDBySubject(_ context.Context, _ string) (uuid.UUID, error) {
	c.resolveCalls++
	return uuid.Nil, c.resolveErr
}

func (c *adminAttractionUserClientStub) GetPublicUserProfiles(_ context.Context, userIDs []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error) {
	profiles := make(map[uuid.UUID]PublicUserProfile, len(userIDs))
	for _, id := range userIDs {
		profiles[id] = PublicUserProfile{UserID: id}
	}
	return profiles, nil
}
