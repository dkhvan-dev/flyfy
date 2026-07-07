package app

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestCreateCommunityUpsertsPublicActiveSearchDocument(t *testing.T) {
	indexer := &communitySearchIndexerStub{}
	useCase := NewPostUseCase(&postUseCaseRepositoryStub{}, nil, "https://inflap.app/posts").
		WithCommunitySearchIndexer(indexer)

	cityID := "astana"
	countryCode := "kz"
	view, err := useCase.CreateCommunity(context.Background(), CreateCommunityInput{
		Slug: "astana-guides",
		TitleI18n: map[string]string{
			"ru": "Гиды Астаны",
			"en": "Astana Guides",
			"kk": "Астана гидтері",
		},
		DescriptionI18n: map[string]string{
			"ru": "Локальные советы, маршруты и встречи в Астане",
			"en": "Local tips, routes and meetups in Astana",
			"kk": "Астанадағы жергілікті кеңестер мен кездесулер",
		},
		Topic:            "guides",
		CityID:           &cityID,
		CountryCode:      &countryCode,
		Visibility:       string(enum.CommunityVisibilityPublic),
		PostingPolicy:    string(enum.CommunityPostingPolicyOpenMembers),
		Status:           string(enum.CommunityStatusActive),
		CreatedByAdminID: uuid.New(),
	})
	if err != nil {
		t.Fatalf("CreateCommunity returned error: %v", err)
	}
	if view == nil || view.Community == nil {
		t.Fatal("CreateCommunity returned nil community")
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want 1", len(indexer.upserts))
	}
	if len(indexer.deletes) != 0 {
		t.Fatalf("deletes = %d, want 0", len(indexer.deletes))
	}

	doc := indexer.upserts[0]
	if doc.Domain != "community" || doc.EntityID != view.Community.ID.String() {
		t.Fatalf("document identity = %s/%s, want community/%s", doc.Domain, doc.EntityID, view.Community.ID)
	}
	if doc.Locale != "ru" {
		t.Fatalf("locale = %q, want ru", doc.Locale)
	}
	if doc.Title["ru"] != "Гиды Астаны" || doc.Title["en"] != "Astana Guides" || doc.Title["kk"] != "Астана гидтері" {
		t.Fatalf("title = %+v", doc.Title)
	}
	if doc.Description["en"] != "Local tips, routes and meetups in Astana" {
		t.Fatalf("description = %+v", doc.Description)
	}
	if doc.CityID != "astana" || doc.CountryCode != "KZ" {
		t.Fatalf("location = %q/%q, want astana/KZ", doc.CityID, doc.CountryCode)
	}
	if doc.DeepLink != "/communities/"+view.Community.ID.String() {
		t.Fatalf("deep link = %q", doc.DeepLink)
	}
	if doc.AvailabilityStatus != "active" || doc.Visibility != "public" || doc.ModerationStatus != "approved" {
		t.Fatalf("public states = availability:%q visibility:%q moderation:%q", doc.AvailabilityStatus, doc.Visibility, doc.ModerationStatus)
	}
	if !containsString(doc.CategoryCodes, "guides") {
		t.Fatalf("category codes = %+v, want guides", doc.CategoryCodes)
	}
	if !strings.Contains(doc.SearchTextNormalized, "astana guides") {
		t.Fatalf("normalized search text = %q, want english title", doc.SearchTextNormalized)
	}
}

func TestUpdateCommunityDeletesSearchDocumentWhenNoLongerPublic(t *testing.T) {
	communityID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		community: &model.Community{
			ID:          communityID,
			Slug:        "travel-club",
			Title:       "Travel Club",
			TitleI18n:   requiredCommunityTextFixture("Travel Club"),
			Description: "Public travel community",
			DescriptionI18n: map[string]string{
				"ru": "Public travel community",
				"en": "Public travel community",
				"kk": "Public travel community",
			},
			Topic:         "travel",
			Visibility:    enum.CommunityVisibilityPublic,
			PostingPolicy: enum.CommunityPostingPolicyOpenMembers,
			Status:        enum.CommunityStatusActive,
		},
	}
	indexer := &communitySearchIndexerStub{}
	useCase := NewPostUseCase(repo, nil, "https://inflap.app/posts").
		WithCommunitySearchIndexer(indexer)

	_, err := useCase.UpdateCommunity(context.Background(), UpdateCommunityInput{
		CommunityID: communityID,
		Slug:        "travel-club",
		TitleI18n:   requiredCommunityTextFixture("Travel Club"),
		DescriptionI18n: map[string]string{
			"ru": "Private travel community",
			"en": "Private travel community",
			"kk": "Private travel community",
		},
		Topic:            "travel",
		Visibility:       string(enum.CommunityVisibilityHidden),
		PostingPolicy:    string(enum.CommunityPostingPolicyOpenMembers),
		Status:           string(enum.CommunityStatusActive),
		UpdatedByAdminID: uuid.New(),
	})
	if err != nil {
		t.Fatalf("UpdateCommunity returned error: %v", err)
	}
	if len(indexer.upserts) != 0 {
		t.Fatalf("upserts = %d, want 0", len(indexer.upserts))
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("deletes = %d, want 1", len(indexer.deletes))
	}

	deletion := indexer.deletes[0]
	if deletion.Domain != "community" || deletion.EntityID != communityID.String() || deletion.Locale != "ru" {
		t.Fatalf("delete request = %+v", deletion)
	}
}

func TestCommunitySearchIndexingFailureDoesNotFailMutation(t *testing.T) {
	indexer := &communitySearchIndexerStub{upsertErr: errors.New("search unavailable")}
	useCase := NewPostUseCase(&postUseCaseRepositoryStub{}, nil, "https://inflap.app/posts").
		WithCommunitySearchIndexer(indexer)

	_, err := useCase.CreateCommunity(context.Background(), CreateCommunityInput{
		Slug:             "nomads",
		TitleI18n:        requiredCommunityTextFixture("Nomads"),
		DescriptionI18n:  requiredCommunityTextFixture("Nomad community"),
		Topic:            "culture",
		Visibility:       string(enum.CommunityVisibilityPublic),
		PostingPolicy:    string(enum.CommunityPostingPolicyOpenMembers),
		Status:           string(enum.CommunityStatusActive),
		CreatedByAdminID: uuid.New(),
	})
	if err != nil {
		t.Fatalf("CreateCommunity returned error: %v", err)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want attempted upsert", len(indexer.upserts))
	}
}

type communitySearchIndexerStub struct {
	upserts   []SearchIndexDocument
	deletes   []SearchIndexDelete
	upsertErr error
	deleteErr error
}

func (s *communitySearchIndexerStub) UpsertSearchDocument(_ context.Context, document SearchIndexDocument) error {
	s.upserts = append(s.upserts, document)
	return s.upsertErr
}

func (s *communitySearchIndexerStub) DeleteSearchDocument(_ context.Context, deletion SearchIndexDelete) error {
	s.deletes = append(s.deletes, deletion)
	return s.deleteErr
}

func requiredCommunityTextFixture(value string) map[string]string {
	return map[string]string{
		"ru": value,
		"en": value,
		"kk": value,
	}
}
