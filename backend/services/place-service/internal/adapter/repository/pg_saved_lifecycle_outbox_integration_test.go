package repository

import (
	"context"
	"errors"
	"os"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestPGSavedLifecycleOutboxTransactionalSemantics(t *testing.T) {
	pool := newSavedLifecycleIntegrationPool(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	rollbackID := uuid.New()
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin rollback probe: %v", err)
	}
	insertPublishedAttractionTx(t, ctx, tx, rollbackID, uuid.New(), false)
	if count := countSavedLifecycleEvents(t, ctx, tx, rollbackID); count != 1 {
		t.Fatalf("events inside rollback transaction = %d, want 1", count)
	}
	if err = tx.Rollback(ctx); err != nil {
		t.Fatalf("rollback probe: %v", err)
	}
	if count := countSavedLifecycleEvents(t, ctx, pool, rollbackID); count != 0 {
		t.Fatalf("rollback persisted %d lifecycle events", count)
	}

	attractionID := uuid.New()
	tx, err = pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin create probe: %v", err)
	}
	insertPublishedAttractionTx(t, ctx, tx, attractionID, uuid.New(), true)
	if err = tx.Commit(ctx); err != nil {
		t.Fatalf("commit create probe: %v", err)
	}
	createEvent := assertLatestSavedLifecycleEvent(
		t,
		ctx,
		pool,
		attractionID,
		1,
		model.SavedLifecyclePublished,
		model.SavedLifecycleVisibilityPublic,
	)
	_, err = pool.Exec(ctx, `
		UPDATE place_saved_lifecycle_outbox
		SET source_revision = source_revision + 1
		WHERE entity_id = $1
	`, attractionID)
	assertSavedLifecycleSQLState(t, err, "55000", "post-commit envelope mutation")

	if _, err = pool.Exec(ctx, `
		UPDATE place_translations
		SET updated_at = clock_timestamp()
		WHERE place_id = $1 AND locale = 'en'
	`, attractionID); err != nil {
		t.Fatalf("technical translation update: %v", err)
	}
	if _, err = pool.Exec(ctx, `
		UPDATE places
		SET tags = ARRAY['technical-only'], updated_at = clock_timestamp()
		WHERE id = $1
	`, attractionID); err != nil {
		t.Fatalf("technical place update: %v", err)
	}
	if count := countSavedLifecycleEvents(t, ctx, pool, attractionID); count != 1 {
		t.Fatalf("technical updates emitted events: count = %d, want 1", count)
	}

	if _, err = pool.Exec(ctx, `
		UPDATE place_translations
		SET title = 'Updated public attraction', updated_at = clock_timestamp()
		WHERE place_id = $1 AND locale = 'en'
	`, attractionID); err != nil {
		t.Fatalf("projection update: %v", err)
	}
	translationEvent := assertLatestSavedLifecycleEvent(
		t,
		ctx,
		pool,
		attractionID,
		2,
		model.SavedLifecycleUpdated,
		model.SavedLifecycleVisibilityPublic,
	)
	if translationEvent.VisibilityRevision <= createEvent.VisibilityRevision {
		t.Fatalf(
			"translation visibility revision = %d, want > %d",
			translationEvent.VisibilityRevision,
			createEvent.VisibilityRevision,
		)
	}

	tx, err = pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin media replacement: %v", err)
	}
	if _, err = tx.Exec(ctx, `DELETE FROM place_media WHERE place_id = $1`, attractionID); err != nil {
		t.Fatalf("delete media: %v", err)
	}
	if _, err = tx.Exec(ctx, `
		INSERT INTO place_media (id, place_id, file_id, media_type, position)
		VALUES ($1, $3, $2, 'PHOTO', 0), ($4, $3, $5, 'PHOTO', 1)
	`, uuid.New(), uuid.New(), attractionID, uuid.New(), uuid.New()); err != nil {
		t.Fatalf("insert replacement media: %v", err)
	}
	if err = tx.Commit(ctx); err != nil {
		t.Fatalf("commit media replacement: %v", err)
	}
	mediaEvent := assertLatestSavedLifecycleEvent(
		t,
		ctx,
		pool,
		attractionID,
		3,
		model.SavedLifecycleUpdated,
		model.SavedLifecycleVisibilityPublic,
	)
	if mediaEvent.VisibilityRevision != translationEvent.VisibilityRevision {
		t.Fatalf(
			"media-only visibility revision = %d, want unchanged %d",
			mediaEvent.VisibilityRevision,
			translationEvent.VisibilityRevision,
		)
	}

	var projectionBeforeDeny int64
	if err = pool.QueryRow(ctx, `
		SELECT saved_projection_revision FROM places WHERE id = $1
	`, attractionID).Scan(&projectionBeforeDeny); err != nil {
		t.Fatalf("load projection revision before deny: %v", err)
	}
	oldOpaqueReference := "attraction-cover:" + attractionID.String() + ":" +
		strconv.FormatInt(projectionBeforeDeny, 10)
	if _, err = pool.Exec(ctx, `
		UPDATE places SET status = 'DRAFT', updated_at = clock_timestamp() WHERE id = $1
	`, attractionID); err != nil {
		t.Fatalf("deny attraction: %v", err)
	}
	event := assertLatestSavedLifecycleEvent(
		t,
		ctx,
		pool,
		attractionID,
		4,
		model.SavedLifecycleVisibilityChanged,
		model.SavedLifecycleVisibilityRestricted,
	)
	if int64(event.ProjectionRevision) <= projectionBeforeDeny {
		t.Fatalf(
			"PUBLIC-to-deny projection revision = %d, want > %d",
			event.ProjectionRevision,
			projectionBeforeDeny,
		)
	}
	referenceForRotatedRevision := "attraction-cover:" + attractionID.String() + ":" +
		strconv.FormatUint(event.ProjectionRevision, 10)
	if referenceForRotatedRevision == oldOpaqueReference {
		t.Fatalf("PUBLIC-to-deny retained stale media reference %q", oldOpaqueReference)
	}

	if _, err = pool.Exec(ctx, `
		UPDATE places SET status = 'PUBLISHED', updated_at = clock_timestamp() WHERE id = $1
	`, attractionID); err != nil {
		t.Fatalf("republish attraction: %v", err)
	}
	publicEvent := assertLatestSavedLifecycleEvent(
		t,
		ctx,
		pool,
		attractionID,
		5,
		model.SavedLifecyclePublished,
		model.SavedLifecycleVisibilityPublic,
	)

	if _, err = pool.Exec(ctx, `
		DELETE FROM place_translations WHERE place_id = $1 AND locale = 'en'
	`, attractionID); err != nil {
		t.Fatalf("remove required projection: %v", err)
	}
	unavailableEvent := assertLatestSavedLifecycleEvent(
		t,
		ctx,
		pool,
		attractionID,
		6,
		model.SavedLifecycleUnavailable,
		model.SavedLifecycleVisibilityUnavailable,
	)
	if unavailableEvent.VisibilityRevision <= publicEvent.VisibilityRevision {
		t.Fatalf(
			"PUBLIC-to-UNAVAILABLE visibility revision = %d, want > %d",
			unavailableEvent.VisibilityRevision,
			publicEvent.VisibilityRevision,
		)
	}

	if _, err = pool.Exec(ctx, `
		INSERT INTO place_translations (place_id, locale, title, description)
		VALUES ($1, 'en', 'Restored attraction', '')
	`, attractionID); err != nil {
		t.Fatalf("restore required projection: %v", err)
	}
	assertLatestSavedLifecycleEvent(
		t,
		ctx,
		pool,
		attractionID,
		7,
		model.SavedLifecycleUpdated,
		model.SavedLifecycleVisibilityPublic,
	)

	if _, err = pool.Exec(ctx, `
		UPDATE places SET deleted_at = clock_timestamp(), updated_at = clock_timestamp() WHERE id = $1
	`, attractionID); err != nil {
		t.Fatalf("delete attraction: %v", err)
	}
	assertLatestSavedLifecycleEvent(
		t,
		ctx,
		pool,
		attractionID,
		8,
		model.SavedLifecycleDeleted,
		model.SavedLifecycleVisibilityDeleted,
	)

	var payloadColumnCount int
	if err = pool.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM information_schema.columns
		WHERE table_schema = current_schema()
		  AND table_name = 'place_saved_lifecycle_outbox'
		  AND column_name IN ('payload', 'public_projection', 'envelope')
	`).Scan(&payloadColumnCount); err != nil {
		t.Fatalf("inspect payload columns: %v", err)
	}
	if payloadColumnCount != 0 {
		t.Fatalf("deny-capable outbox has %d payload columns", payloadColumnCount)
	}
}

func TestPGSavedLifecycleOutboxConcurrentClaimRecoveryRetryAndDurableDead(t *testing.T) {
	pool := newSavedLifecycleIntegrationPool(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	attractionID := uuid.New()
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin attraction create: %v", err)
	}
	insertPublishedAttractionTx(t, ctx, tx, attractionID, uuid.New(), false)
	if err = tx.Commit(ctx); err != nil {
		t.Fatalf("commit attraction create: %v", err)
	}

	repository := NewPGSavedLifecycleOutboxRepository(pool)
	now := time.Now().UTC().Add(time.Second).Truncate(time.Microsecond)
	const claimers = 8
	var waitGroup sync.WaitGroup
	results := make(chan []model.ClaimedSavedLifecycleEvent, claimers)
	errorsChannel := make(chan error, claimers)
	for range claimers {
		waitGroup.Add(1)
		go func() {
			defer waitGroup.Done()
			claimed, claimErr := repository.ClaimDueSavedLifecycleEvents(
				ctx,
				now,
				now.Add(-time.Minute),
				1,
			)
			if claimErr != nil {
				errorsChannel <- claimErr
				return
			}
			results <- claimed
		}()
	}
	waitGroup.Wait()
	close(results)
	close(errorsChannel)
	for claimErr := range errorsChannel {
		if claimErr != nil {
			t.Fatalf("concurrent claim error: %v", claimErr)
		}
	}
	var first model.ClaimedSavedLifecycleEvent
	claimedCount := 0
	for claimed := range results {
		claimedCount += len(claimed)
		if len(claimed) == 1 {
			first = claimed[0]
		}
	}
	if claimedCount != 1 {
		t.Fatalf("concurrent claims returned %d events, want 1", claimedCount)
	}

	recoveryTime := now.Add(3 * time.Minute)
	recovered, err := repository.ClaimDueSavedLifecycleEvents(
		ctx,
		recoveryTime,
		recoveryTime.Add(-2*time.Minute),
		1,
	)
	if err != nil || len(recovered) != 1 {
		t.Fatalf("lease recovery = %d events, %v", len(recovered), err)
	}
	if recovered[0].Event.EventID != first.Event.EventID || recovered[0].LeaseID == first.LeaseID {
		t.Fatalf("recovered immutable identity/lease = %s/%s", recovered[0].Event.EventID, recovered[0].LeaseID)
	}
	if err = repository.MarkSavedLifecycleDelivered(
		ctx,
		first.Event.EventID,
		first.LeaseID,
		recoveryTime,
	); !errors.Is(err, ErrSavedLifecycleLeaseLost) {
		t.Fatalf("stale lease mark error = %v, want ErrSavedLifecycleLeaseLost", err)
	}

	nextAttempt := recoveryTime.Add(2 * time.Second)
	state, err := repository.MarkSavedLifecycleFailure(
		ctx,
		recovered[0].Event.EventID,
		recovered[0].LeaseID,
		recoveryTime,
		nextAttempt,
		2,
		"NATS_PUBLISH_FAILED",
	)
	if err != nil || state != model.SavedLifecycleDeliveryPending {
		t.Fatalf("retryable failure state = %s, %v", state, err)
	}

	notDue, err := repository.ClaimDueSavedLifecycleEvents(
		ctx,
		recoveryTime.Add(time.Second),
		recoveryTime.Add(-time.Minute),
		1,
	)
	if err != nil || len(notDue) != 0 {
		t.Fatalf("early retry claim = %#v, %v", notDue, err)
	}
	retryClaim, err := repository.ClaimDueSavedLifecycleEvents(
		ctx,
		nextAttempt,
		nextAttempt.Add(-time.Minute),
		1,
	)
	if err != nil || len(retryClaim) != 1 || retryClaim[0].AttemptCount != 1 ||
		retryClaim[0].DeliveryState != model.SavedLifecycleDeliveryPending {
		t.Fatalf("retry claim = %#v, %v", retryClaim, err)
	}

	deadAt := nextAttempt.Add(time.Second).Truncate(time.Microsecond)
	state, err = repository.MarkSavedLifecycleFailure(
		ctx,
		retryClaim[0].Event.EventID,
		retryClaim[0].LeaseID,
		deadAt,
		deadAt.Add(time.Minute),
		2,
		"NATS_PUBLISH_FAILED",
	)
	if err != nil || state != model.SavedLifecycleDeliveryDead {
		t.Fatalf("terminal failure state = %s, %v", state, err)
	}
	terminalClaim, err := repository.ClaimDueSavedLifecycleEvents(
		ctx,
		deadAt.Add(time.Hour),
		deadAt,
		1,
	)
	if err != nil || len(terminalClaim) != 0 {
		t.Fatalf("terminal DEAD row was dispatchable: %#v, %v", terminalClaim, err)
	}
	var (
		status             string
		attemptCount       int
		retentionExpiresAt time.Time
	)
	if err = pool.QueryRow(ctx, `
		SELECT status, attempt_count, retention_expires_at
		FROM place_saved_lifecycle_outbox
		WHERE event_id = $1
	`, retryClaim[0].Event.EventID).Scan(&status, &attemptCount, &retentionExpiresAt); err != nil {
		t.Fatalf("load terminal outbox row: %v", err)
	}
	if status != "DEAD" || attemptCount != 2 || !retentionExpiresAt.Equal(deadAt.Add(14*24*time.Hour)) {
		t.Fatalf("terminal status/attempts/retention = %s/%d/%s", status, attemptCount, retentionExpiresAt)
	}
	_, err = pool.Exec(ctx, `
		UPDATE place_saved_lifecycle_outbox
		SET
			status = 'PENDING',
			dead_at = NULL,
			retention_expires_at = NULL
		WHERE event_id = $1
	`, retryClaim[0].Event.EventID)
	assertSavedLifecycleSQLState(t, err, "55000", "terminal state regression")
	deleted, err := repository.DeleteExpiredSavedLifecycleEvents(
		ctx,
		retentionExpiresAt.Add(time.Nanosecond),
		10,
	)
	if err != nil || deleted != 1 {
		t.Fatalf("retention cleanup = %d, %v", deleted, err)
	}
}

func assertSavedLifecycleSQLState(t *testing.T, err error, code string, operation string) {
	t.Helper()
	var pgError *pgconn.PgError
	if !errors.As(err, &pgError) || pgError.Code != code {
		t.Fatalf("%s error = %v, want SQLSTATE %s", operation, err, code)
	}
}

func TestSavedLifecycleMigrationUpDownOnPostgreSQL17(t *testing.T) {
	pool := newSavedLifecycleIntegrationPool(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	attractionID := uuid.New()
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin migration rollback guard probe: %v", err)
	}
	insertPublishedAttractionTx(t, ctx, tx, attractionID, uuid.New(), false)
	if err = tx.Commit(ctx); err != nil {
		t.Fatalf("commit migration rollback guard probe: %v", err)
	}

	_, err = pool.Exec(ctx, readSavedLifecycleMigration(t, "215_saved_lifecycle_outbox.down.sql"))
	var pgError *pgconn.PgError
	if !errors.As(err, &pgError) || pgError.Code != "55000" {
		t.Fatalf("guarded down error = %v, want SQLSTATE 55000", err)
	}
	if _, err = pool.Exec(ctx, `DELETE FROM place_saved_lifecycle_outbox`); err != nil {
		t.Fatalf("drain outbox for rollback: %v", err)
	}
	if _, err = pool.Exec(ctx, `DELETE FROM places`); err != nil {
		t.Fatalf("delete migration probe place: %v", err)
	}
	if _, err = pool.Exec(ctx, readSavedLifecycleMigration(t, "215_saved_lifecycle_outbox.down.sql")); err != nil {
		t.Fatalf("215 down migration: %v", err)
	}
	var tableExists bool
	if err = pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1
			FROM information_schema.tables
			WHERE table_schema = current_schema()
			  AND table_name = 'place_saved_lifecycle_outbox'
		)
	`).Scan(&tableExists); err != nil {
		t.Fatalf("inspect removed outbox table: %v", err)
	}
	if tableExists {
		t.Fatal("outbox table still exists after down")
	}
	if _, err = pool.Exec(ctx, readSavedLifecycleMigration(t, "214_saved_source_revisions.down.sql")); err != nil {
		t.Fatalf("214 down migration after 215 rollback: %v", err)
	}
}

type lifecycleQueryRower interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}

func countSavedLifecycleEvents(
	t *testing.T,
	ctx context.Context,
	queryer lifecycleQueryRower,
	attractionID uuid.UUID,
) int {
	t.Helper()
	var count int
	if err := queryer.QueryRow(ctx, `
		SELECT COUNT(*) FROM place_saved_lifecycle_outbox WHERE entity_id = $1
	`, attractionID).Scan(&count); err != nil {
		t.Fatalf("count Saved lifecycle events: %v", err)
	}
	return count
}

func assertLatestSavedLifecycleEvent(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	attractionID uuid.UUID,
	wantCount int,
	wantType model.SavedLifecycleEventType,
	wantVisibility model.SavedLifecycleVisibility,
) model.SavedLifecycleEvent {
	t.Helper()
	if count := countSavedLifecycleEvents(t, ctx, pool, attractionID); count != wantCount {
		t.Fatalf("Saved lifecycle event count = %d, want %d", count, wantCount)
	}
	var (
		event              model.SavedLifecycleEvent
		eventType          string
		visibility         string
		sourceRevision     int64
		projectionRevision int64
		visibilityRevision int64
		schemaVersion      int16
	)
	if err := pool.QueryRow(ctx, `
		SELECT
			event_id,
			schema_version,
			event_type,
			entity_id,
			source_revision,
			projection_revision,
			visibility_revision,
			visibility,
			occurred_at
		FROM place_saved_lifecycle_outbox
		WHERE entity_id = $1
		ORDER BY occurred_at DESC, event_id DESC
		LIMIT 1
	`, attractionID).Scan(
		&event.EventID,
		&schemaVersion,
		&eventType,
		&event.EntityID,
		&sourceRevision,
		&projectionRevision,
		&visibilityRevision,
		&visibility,
		&event.OccurredAt,
	); err != nil {
		t.Fatalf("load latest Saved lifecycle event: %v", err)
	}
	event.EventType = model.SavedLifecycleEventType(eventType)
	event.SchemaVersion = uint16(schemaVersion)
	event.Visibility = model.SavedLifecycleVisibility(visibility)
	event.SourceRevision = uint64(sourceRevision)
	event.ProjectionRevision = uint64(projectionRevision)
	event.VisibilityRevision = uint64(visibilityRevision)
	if err := event.Validate(); err != nil {
		t.Fatalf("latest Saved lifecycle event invalid: %v", err)
	}
	if event.EventType != wantType || event.Visibility != wantVisibility {
		t.Fatalf("latest Saved lifecycle event = %s/%s, want %s/%s", event.EventType, event.Visibility, wantType, wantVisibility)
	}
	return event
}

func insertPublishedAttractionTx(
	t *testing.T,
	ctx context.Context,
	tx interface {
		Exec(context.Context, string, ...any) (pgconn.CommandTag, error)
	},
	attractionID uuid.UUID,
	authorID uuid.UUID,
	withMedia bool,
) {
	t.Helper()
	if _, err := tx.Exec(ctx, `
		INSERT INTO places (
			id, author_user_id, default_locale, country_code, city_id,
			category, source, status
		) VALUES ($1, $2, 'en', 'KZ', 'almaty', 'NATURE', 'IMPORT', 'PUBLISHED')
	`, attractionID, authorID); err != nil {
		t.Fatalf("insert published attraction: %v", err)
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO place_translations (place_id, locale, title, description)
		VALUES
			($1, 'en', 'Lifecycle attraction', 'Public source copy'),
			($1, 'ru', 'Lifecycle attraction RU', 'Public source copy RU')
	`, attractionID); err != nil {
		t.Fatalf("insert attraction translations: %v", err)
	}
	if withMedia {
		if _, err := tx.Exec(ctx, `
			INSERT INTO place_media (id, place_id, file_id, media_type, position)
			VALUES ($1, $2, $3, 'PHOTO', 0)
		`, uuid.New(), attractionID, uuid.New()); err != nil {
			t.Fatalf("insert attraction media: %v", err)
		}
	}
}

func newSavedLifecycleIntegrationPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	dsn := strings.TrimSpace(os.Getenv("PLACE_SERVICE_REPOSITORY_TEST_DSN"))
	if dsn == "" {
		t.Skip("set PLACE_SERVICE_REPOSITORY_TEST_DSN to run Saved lifecycle PostgreSQL integration tests")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	basePool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect Saved lifecycle integration database: %v", err)
	}
	if err = basePool.Ping(ctx); err != nil {
		basePool.Close()
		t.Fatalf("ping Saved lifecycle integration database: %v", err)
	}
	var versionRaw string
	if err = basePool.QueryRow(ctx, `SHOW server_version_num`).Scan(&versionRaw); err != nil {
		basePool.Close()
		t.Fatalf("read PostgreSQL version: %v", err)
	}
	version, err := strconv.Atoi(versionRaw)
	if err != nil || version < 170000 || version >= 180000 {
		basePool.Close()
		t.Fatalf("Saved lifecycle migration tests require PostgreSQL 17, got %q", versionRaw)
	}

	schema := "saved_lifecycle_test_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	if _, err = basePool.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		basePool.Close()
		t.Fatalf("create Saved lifecycle test schema: %v", err)
	}
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		basePool.Close()
		t.Fatalf("parse Saved lifecycle integration DSN: %v", err)
	}
	config.ConnConfig.RuntimeParams["search_path"] = schema + ",public"
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		basePool.Close()
		t.Fatalf("open isolated Saved lifecycle pool: %v", err)
	}
	for _, migration := range []string{
		"001_init.up.sql",
		"214_saved_source_revisions.up.sql",
		"215_saved_lifecycle_outbox.up.sql",
	} {
		if _, err = pool.Exec(ctx, readSavedLifecycleMigration(t, migration)); err != nil {
			pool.Close()
			_, _ = basePool.Exec(context.Background(), "DROP SCHEMA "+schema+" CASCADE")
			basePool.Close()
			t.Fatalf("apply %s in PostgreSQL 17 schema: %v", migration, err)
		}
	}
	t.Cleanup(func() {
		pool.Close()
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cleanupCancel()
		_, _ = basePool.Exec(cleanupCtx, "DROP SCHEMA "+schema+" CASCADE")
		basePool.Close()
	})
	return pool
}
