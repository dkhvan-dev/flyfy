package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestBackfillCommunitySearchIndexReconcilesDocuments(t *testing.T) {
	publicCommunity := &model.Community{
		ID:          uuid.New(),
		Slug:        "charyn-travelers",
		Title:       "Charyn travelers",
		TitleI18n:   requiredCommunityTextFixture("Charyn travelers"),
		Description: "Trips and tips around Charyn canyon",
		DescriptionI18n: map[string]string{
			"ru": "Поездки и советы по Чарынскому каньону",
			"en": "Trips and tips around Charyn canyon",
			"kk": "Шарын шатқалы бойынша сапарлар мен кеңестер",
		},
		Topic:         "nature",
		LanguageCode:  "ru",
		Visibility:    enum.CommunityVisibilityPublic,
		PostingPolicy: enum.CommunityPostingPolicyOpenMembers,
		Status:        enum.CommunityStatusActive,
		FollowerCount: 42,
		PostCount:     7,
		UpdatedAt:     time.Unix(100, 0),
	}
	hiddenCommunity := &model.Community{
		ID:         uuid.New(),
		Slug:       "hidden-community",
		Title:      "Hidden community",
		TitleI18n:  requiredCommunityTextFixture("Hidden community"),
		Visibility: enum.CommunityVisibilityHidden,
		Status:     enum.CommunityStatusActive,
		UpdatedAt:  time.Unix(200, 0),
	}
	repo := &communitySearchBackfillRepoStub{
		pages: [][]*model.Community{
			{publicCommunity},
			{hiddenCommunity},
		},
	}
	indexer := &communitySearchIndexerStub{}

	stats, err := BackfillCommunitySearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		BatchSize:   1,
		DeleteStale: true,
	})
	if err != nil {
		t.Fatalf("BackfillCommunitySearchIndex() error = %v", err)
	}

	if stats.Scanned != 2 || stats.Upserted != 1 || stats.Deleted != 1 || stats.Skipped != 0 || stats.Failed != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want 1", len(indexer.upserts))
	}
	if indexer.upserts[0].EntityID != publicCommunity.ID.String() {
		t.Fatalf("upsert entity = %s, want %s", indexer.upserts[0].EntityID, publicCommunity.ID)
	}
	if !containsString(indexer.upserts[0].CategoryCodes, "nature") {
		t.Fatalf("category codes = %#v", indexer.upserts[0].CategoryCodes)
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].EntityID != hiddenCommunity.ID.String() {
		t.Fatalf("delete entity = %s, want %s", indexer.deletes[0].EntityID, hiddenCommunity.ID)
	}
	if !repo.listCalls[0].IncludeDeleted {
		t.Fatal("IncludeDeleted = false, want true when DeleteStale is enabled")
	}
}

func TestBackfillCommunitySearchIndexDryRunDoesNotPublish(t *testing.T) {
	community := &model.Community{
		ID:         uuid.New(),
		Slug:       "almaty-guides",
		Title:      "Almaty guides",
		TitleI18n:  requiredCommunityTextFixture("Almaty guides"),
		Visibility: enum.CommunityVisibilityPublic,
		Status:     enum.CommunityStatusActive,
		UpdatedAt:  time.Unix(300, 0),
	}
	repo := &communitySearchBackfillRepoStub{pages: [][]*model.Community{{community}}}
	indexer := &communitySearchIndexerStub{}

	stats, err := BackfillCommunitySearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		DryRun: true,
	})
	if err != nil {
		t.Fatalf("BackfillCommunitySearchIndex() error = %v", err)
	}
	if stats.Scanned != 1 || stats.Upserted != 1 || stats.Deleted != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 0 || len(indexer.deletes) != 0 {
		t.Fatalf("dry run published upserts=%d deletes=%d, want none", len(indexer.upserts), len(indexer.deletes))
	}
}

type communitySearchBackfillRepoStub struct {
	pages     [][]*model.Community
	listCalls []model.CommunityListFilter
}

func (s *communitySearchBackfillRepoStub) ListCommunities(
	_ context.Context,
	filter model.CommunityListFilter,
) ([]*model.Community, error) {
	s.listCalls = append(s.listCalls, filter)
	index := len(s.listCalls) - 1
	if index >= len(s.pages) {
		return nil, nil
	}
	return s.pages[index], nil
}
