package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestBackfillPlaceSearchIndexUpsertsPublishedPlaces(t *testing.T) {
	placeID := uuid.New()
	repo := &placeSearchBackfillRepoStub{
		places: []*model.Place{
			{
				ID:            placeID,
				DefaultLocale: "ru",
				Title:         "Чарынский каньон",
				Description:   "Каньон в Алматинской области",
				CountryCode:   "KZ",
				CityID:        "almaty",
				Category:      enum.CategoryNature,
				Status:        enum.StatusPublished,
				UpdatedAt:     time.Unix(100, 0),
			},
		},
	}
	indexer := &placeSearchBackfillIndexerStub{}

	stats, err := BackfillPlaceSearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		BatchSize: 10,
	})

	if err != nil {
		t.Fatalf("BackfillPlaceSearchIndex returned error: %v", err)
	}
	if stats.Scanned != 1 || stats.Upserted != 1 || stats.Deleted != 0 || stats.Skipped != 0 || stats.Failed != 0 {
		t.Fatalf("stats = %+v, want scanned=1 upserted=1", stats)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want 1", len(indexer.upserts))
	}
	doc := indexer.upserts[0]
	if doc.Domain != "place" || doc.EntityID != placeID.String() {
		t.Fatalf("document identity = %s/%s, want place/%s", doc.Domain, doc.EntityID, placeID)
	}
	if doc.Title["ru"] != "Чарынский каньон" {
		t.Fatalf("title[ru] = %q, want Charyn title", doc.Title["ru"])
	}
}

func TestBackfillPlaceSearchIndexDeletesStalePlaces(t *testing.T) {
	placeID := uuid.New()
	deletedAt := time.Unix(200, 0)
	repo := &placeSearchBackfillRepoStub{
		places: []*model.Place{
			{
				ID:            placeID,
				DefaultLocale: "ru",
				Title:         "Draft place",
				Status:        enum.StatusDraft,
				DeletedAt:     &deletedAt,
			},
		},
	}
	indexer := &placeSearchBackfillIndexerStub{}

	stats, err := BackfillPlaceSearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		BatchSize:   10,
		DeleteStale: true,
	})

	if err != nil {
		t.Fatalf("BackfillPlaceSearchIndex returned error: %v", err)
	}
	if stats.Scanned != 1 || stats.Deleted != 1 || stats.Upserted != 0 {
		t.Fatalf("stats = %+v, want scanned=1 deleted=1", stats)
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("deletes = %d, want 1", len(indexer.deletes))
	}
	if got := indexer.deletes[0].EntityID; got != placeID.String() {
		t.Fatalf("deleted entity = %q, want %q", got, placeID.String())
	}
	if !repo.lastFilter.IncludeDeleted {
		t.Fatal("IncludeDeleted = false, want true when DeleteStale is enabled")
	}
}

func TestBackfillPlaceSearchIndexDryRunDoesNotPublish(t *testing.T) {
	repo := &placeSearchBackfillRepoStub{
		places: []*model.Place{
			{
				ID:            uuid.New(),
				DefaultLocale: "ru",
				Title:         "Алматы",
				Status:        enum.StatusPublished,
				UpdatedAt:     time.Unix(300, 0),
			},
		},
	}
	indexer := &placeSearchBackfillIndexerStub{}

	stats, err := BackfillPlaceSearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		DryRun: true,
	})

	if err != nil {
		t.Fatalf("BackfillPlaceSearchIndex returned error: %v", err)
	}
	if stats.Scanned != 1 || stats.Upserted != 1 {
		t.Fatalf("stats = %+v, want scanned=1 upserted=1", stats)
	}
	if len(indexer.upserts) != 0 || len(indexer.deletes) != 0 {
		t.Fatalf("dry run published upserts=%d deletes=%d, want none", len(indexer.upserts), len(indexer.deletes))
	}
}

type placeSearchBackfillRepoStub struct {
	places     []*model.Place
	lastFilter model.PlaceListFilter
}

func (r *placeSearchBackfillRepoStub) ListPlaces(
	_ context.Context,
	filter model.PlaceListFilter,
) ([]*model.Place, int, error) {
	r.lastFilter = filter
	start := filter.Offset
	if start > len(r.places) {
		start = len(r.places)
	}
	end := start + filter.Limit
	if filter.Limit <= 0 || end > len(r.places) {
		end = len(r.places)
	}
	return r.places[start:end], len(r.places), nil
}

type placeSearchBackfillIndexerStub struct {
	upserts []SearchIndexDocument
	deletes []SearchIndexDelete
}

func (s *placeSearchBackfillIndexerStub) UpsertSearchDocument(_ context.Context, document SearchIndexDocument) error {
	s.upserts = append(s.upserts, document)
	return nil
}

func (s *placeSearchBackfillIndexerStub) DeleteSearchDocument(_ context.Context, deletion SearchIndexDelete) error {
	s.deletes = append(s.deletes, deletion)
	return nil
}
