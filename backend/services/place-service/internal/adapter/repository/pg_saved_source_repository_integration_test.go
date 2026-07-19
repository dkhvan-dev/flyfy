package repository

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
)

func TestPGPlaceRepositorySavedSourceSnapshotAndRevisions(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv("PLACE_SERVICE_REPOSITORY_TEST_DSN"))
	if dsn == "" {
		t.Skip("set PLACE_SERVICE_REPOSITORY_TEST_DSN to run live Saved source repository test")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect repository test database: %v", err)
	}
	defer pool.Close()
	if err = pool.Ping(ctx); err != nil {
		t.Fatalf("ping repository test database: %v", err)
	}

	attractionID := uuid.New()
	authorID := uuid.New()
	fileID := uuid.New()
	_, err = pool.Exec(ctx, `
		INSERT INTO places (
			id, author_user_id, default_locale, country_code, city_id,
			category, rating, review_count, source, status
		) VALUES ($1, $2, 'en', 'KZ', 'almaty', 'NATURE', 4.6, 27, 'IMPORT', 'PUBLISHED')
	`, attractionID, authorID)
	if err != nil {
		t.Fatalf("insert attraction: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		_, _ = pool.Exec(cleanupCtx, `DELETE FROM place_saved_lifecycle_outbox WHERE entity_id = $1`, attractionID)
		_, _ = pool.Exec(cleanupCtx, `DELETE FROM places WHERE id = $1`, attractionID)
	})
	_, err = pool.Exec(ctx, `
		INSERT INTO place_translations (place_id, locale, title, description)
		VALUES
			($1, 'en', 'Integration attraction', 'English source copy'),
			($1, 'ru', 'Интеграционная достопримечательность', 'Русский исходный текст')
	`, attractionID)
	if err != nil {
		t.Fatalf("insert translations: %v", err)
	}
	_, err = pool.Exec(ctx, `
		INSERT INTO place_media (id, place_id, file_id, media_type, position)
		VALUES ($1, $2, $3, 'PHOTO', 0)
	`, uuid.New(), attractionID, fileID)
	if err != nil {
		t.Fatalf("insert media: %v", err)
	}

	repository := NewPGPlaceRepository(pool)
	snapshot, err := repository.GetSavedSourceAttraction(ctx, attractionID)
	if err != nil {
		t.Fatalf("GetSavedSourceAttraction() error = %v", err)
	}
	if snapshot == nil || snapshot.ID != attractionID || snapshot.Status != enum.StatusPublished {
		t.Fatalf("snapshot = %#v", snapshot)
	}
	if snapshot.SourceRevision == 0 || snapshot.ProjectionRevision == 0 || snapshot.VisibilityRevision == 0 {
		t.Fatalf("snapshot revisions = %d/%d/%d", snapshot.SourceRevision, snapshot.ProjectionRevision, snapshot.VisibilityRevision)
	}
	if len(snapshot.Translations) != 2 || len(snapshot.Media) != 1 || snapshot.Media[0].FileID != fileID {
		t.Fatalf("snapshot payload translations/media = %d/%#v", len(snapshot.Translations), snapshot.Media)
	}
	cover, err := repository.GetSavedAttractionCoverSnapshot(ctx, attractionID)
	if err != nil {
		t.Fatalf("GetSavedAttractionCoverSnapshot() error = %v", err)
	}
	if cover == nil || cover.ID != attractionID || cover.Status != enum.StatusPublished ||
		cover.ProjectionRevision != snapshot.ProjectionRevision || cover.FileID != fileID {
		t.Fatalf("cover snapshot = %#v", cover)
	}

	replacementFileID := uuid.New()
	previousCoverRevision := cover.ProjectionRevision
	_, err = pool.Exec(ctx, `
		UPDATE place_media
		SET file_id = $2
		WHERE place_id = $1 AND media_type = 'PHOTO' AND position = 0
	`, attractionID, replacementFileID)
	if err != nil {
		t.Fatalf("replace cover file: %v", err)
	}
	cover, err = repository.GetSavedAttractionCoverSnapshot(ctx, attractionID)
	if err != nil {
		t.Fatalf("GetSavedAttractionCoverSnapshot() after cover update error = %v", err)
	}
	if cover == nil || cover.FileID != replacementFileID ||
		cover.ProjectionRevision <= previousCoverRevision {
		t.Fatalf("updated cover snapshot = %#v, previous revision = %d", cover, previousCoverRevision)
	}

	initialSource := snapshot.SourceRevision
	initialProjection := snapshot.ProjectionRevision
	initialVisibility := snapshot.VisibilityRevision
	_, err = pool.Exec(ctx, `
		UPDATE place_translations
		SET title = 'Updated integration attraction', updated_at = clock_timestamp()
		WHERE place_id = $1 AND locale = 'en'
	`, attractionID)
	if err != nil {
		t.Fatalf("update translation: %v", err)
	}
	snapshot, err = repository.GetSavedSourceAttraction(ctx, attractionID)
	if err != nil {
		t.Fatalf("GetSavedSourceAttraction() after projection update error = %v", err)
	}
	if snapshot.SourceRevision <= initialSource || snapshot.ProjectionRevision <= initialProjection {
		t.Fatalf("projection update revisions = %d/%d, want > %d/%d", snapshot.SourceRevision, snapshot.ProjectionRevision, initialSource, initialProjection)
	}
	if snapshot.VisibilityRevision != initialVisibility {
		t.Fatalf("visibility revision = %d, want unchanged %d", snapshot.VisibilityRevision, initialVisibility)
	}

	previousVisibility := snapshot.VisibilityRevision
	_, err = pool.Exec(ctx, `UPDATE places SET status = 'DRAFT', updated_at = clock_timestamp() WHERE id = $1`, attractionID)
	if err != nil {
		t.Fatalf("make attraction draft: %v", err)
	}
	snapshot, err = repository.GetSavedSourceAttraction(ctx, attractionID)
	if err != nil {
		t.Fatalf("GetSavedSourceAttraction() for draft error = %v", err)
	}
	if snapshot.Status != enum.StatusDraft || snapshot.VisibilityRevision <= previousVisibility {
		t.Fatalf("draft status/revision = %s/%d", snapshot.Status, snapshot.VisibilityRevision)
	}
	if len(snapshot.Translations) != 0 || len(snapshot.Media) != 0 {
		t.Fatal("draft snapshot crossed projection payload into resolver")
	}
	cover, err = repository.GetSavedAttractionCoverSnapshot(ctx, attractionID)
	if err != nil {
		t.Fatalf("GetSavedAttractionCoverSnapshot() for draft error = %v", err)
	}
	if cover == nil || cover.Status != enum.StatusDraft || cover.FileID != uuid.Nil || cover.ExternalURL != "" {
		t.Fatalf("draft cover snapshot crossed media payload: %#v", cover)
	}

	_, err = pool.Exec(ctx, `UPDATE places SET deleted_at = clock_timestamp(), updated_at = clock_timestamp() WHERE id = $1`, attractionID)
	if err != nil {
		t.Fatalf("delete attraction: %v", err)
	}
	deleted, err := repository.GetSavedSourceAttraction(ctx, attractionID)
	if err != nil {
		t.Fatalf("GetSavedSourceAttraction() for deleted error = %v", err)
	}
	if deleted == nil || deleted.DeletedAt == nil || deleted.VisibilityRevision <= snapshot.VisibilityRevision {
		t.Fatalf("deleted snapshot = %#v", deleted)
	}
	if len(deleted.Translations) != 0 || len(deleted.Media) != 0 {
		t.Fatal("deleted snapshot crossed projection payload into resolver")
	}
	cover, err = repository.GetSavedAttractionCoverSnapshot(ctx, attractionID)
	if err != nil {
		t.Fatalf("GetSavedAttractionCoverSnapshot() for deleted error = %v", err)
	}
	if cover == nil || cover.DeletedAt == nil || cover.FileID != uuid.Nil || cover.ExternalURL != "" {
		t.Fatalf("deleted cover snapshot crossed media payload: %#v", cover)
	}

	unknown, err := repository.GetSavedSourceAttraction(ctx, uuid.New())
	if err != nil || unknown != nil {
		t.Fatalf("unknown snapshot = %#v, %v", unknown, err)
	}
	unknownCover, err := repository.GetSavedAttractionCoverSnapshot(ctx, uuid.New())
	if err != nil || unknownCover != nil {
		t.Fatalf("unknown cover snapshot = %#v, %v", unknownCover, err)
	}
}
