package app

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/enum"
	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

func TestBackfillExcursionSearchIndexReconcilesDocuments(t *testing.T) {
	t.Parallel()

	publicExcursion := mustNewAppTestExcursion(t, uuid.New(), uuid.New())
	publicExcursion.Status = enum.ExcursionStatusPublished
	publicExcursion.Visibility = enum.ExcursionVisibilityPublic
	publicExcursion.Title = "Charyn canyon tour"
	publicExcursion.CategorySlug = "nature"

	privateExcursion := mustNewAppTestExcursion(t, uuid.New(), uuid.New())
	privateExcursion.Status = enum.ExcursionStatusPublished
	privateExcursion.Visibility = enum.ExcursionVisibilityPrivate

	repo := &excursionSearchBackfillRepoStub{
		pages: [][]*model.Excursion{
			{publicExcursion},
			{privateExcursion},
		},
		relationsByID: map[uuid.UUID]port.ExcursionRelations{
			publicExcursion.ID: {
				Tags:          []string{" Canyon ", "Nature"},
				LanguageCodes: []string{"en", "ru"},
			},
		},
	}
	indexer := &excursionSearchIndexerStub{}

	stats, err := BackfillExcursionSearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		BatchSize:   1,
		DeleteStale: true,
	})
	if err != nil {
		t.Fatalf("BackfillExcursionSearchIndex() error = %v", err)
	}

	if stats.Scanned != 2 || stats.Upserted != 1 || stats.Deleted != 1 || stats.Skipped != 0 || stats.Failed != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want 1", len(indexer.upserts))
	}
	if indexer.upserts[0].EntityID != publicExcursion.ID.String() {
		t.Fatalf("upsert entity = %s, want %s", indexer.upserts[0].EntityID, publicExcursion.ID)
	}
	if !containsString(indexer.upserts[0].Tags, "canyon") || !containsString(indexer.upserts[0].Tags, "nature") {
		t.Fatalf("upsert tags = %#v", indexer.upserts[0].Tags)
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].EntityID != privateExcursion.ID.String() {
		t.Fatalf("delete entity = %s, want %s", indexer.deletes[0].EntityID, privateExcursion.ID)
	}
}

func TestBackfillExcursionSearchIndexDryRunDoesNotPublish(t *testing.T) {
	t.Parallel()

	excursion := mustNewAppTestExcursion(t, uuid.New(), uuid.New())
	excursion.Status = enum.ExcursionStatusPublished
	excursion.Visibility = enum.ExcursionVisibilityPublic
	repo := &excursionSearchBackfillRepoStub{
		pages: [][]*model.Excursion{{excursion}},
		relationsByID: map[uuid.UUID]port.ExcursionRelations{
			excursion.ID: {LanguageCodes: []string{"en"}},
		},
	}
	indexer := &excursionSearchIndexerStub{}

	stats, err := BackfillExcursionSearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		DryRun: true,
	})
	if err != nil {
		t.Fatalf("BackfillExcursionSearchIndex() error = %v", err)
	}
	if stats.Scanned != 1 || stats.Upserted != 1 || stats.Deleted != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 0 || len(indexer.deletes) != 0 {
		t.Fatalf("dry run published upserts=%d deletes=%d, want none", len(indexer.upserts), len(indexer.deletes))
	}
}

type excursionSearchBackfillRepoStub struct {
	pages         [][]*model.Excursion
	relationsByID map[uuid.UUID]port.ExcursionRelations
	listCalls     []port.ExcursionFilter
}

func (s *excursionSearchBackfillRepoStub) ListExcursions(
	_ context.Context,
	filter port.ExcursionFilter,
) ([]*model.Excursion, error) {
	s.listCalls = append(s.listCalls, filter)
	index := len(s.listCalls) - 1
	if index >= len(s.pages) {
		return nil, nil
	}
	return s.pages[index], nil
}

func (s *excursionSearchBackfillRepoStub) LoadExcursionRelations(
	_ context.Context,
	excursionID uuid.UUID,
) (port.ExcursionRelations, error) {
	return s.relationsByID[excursionID], nil
}
