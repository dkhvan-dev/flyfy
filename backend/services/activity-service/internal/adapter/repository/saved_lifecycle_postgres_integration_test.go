package repository

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/protobuf/encoding/protojson"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const activitySavedLifecycleIntegrationDSNEnv = "ACTIVITY_SAVED_LIFECYCLE_TEST_DSN"

func TestActivitySavedLifecyclePostgres17Integration(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv(activitySavedLifecycleIntegrationDSNEnv))
	if dsn == "" {
		t.Skip(activitySavedLifecycleIntegrationDSNEnv + " is not set")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	pool, cleanup := newActivitySavedLifecycleIntegrationPool(t, ctx, dsn)
	defer cleanup()
	assertActivitySavedLifecyclePostgres17(t, ctx, pool)
	applyActivityMigrations(t, ctx, pool)
	repo := NewPGActivityRepository(pool)

	t.Run("transaction rollback emits nothing", func(t *testing.T) {
		item := newActivitySavedLifecycleIntegrationActivity(t)
		tx, err := pool.BeginTx(ctx, pgx.TxOptions{})
		if err != nil {
			t.Fatalf("begin rollback probe: %v", err)
		}
		if err = insertActivity(ctx, tx, item); err != nil {
			_ = tx.Rollback(ctx)
			t.Fatalf("insert rollback probe: %v", err)
		}
		if err = enqueueActivitySavedLifecycleTransition(ctx, tx, nil, item, nil, nil, item.UpdatedAt); err != nil {
			_ = tx.Rollback(ctx)
			t.Fatalf("enqueue rollback probe: %v", err)
		}
		if err = tx.Rollback(ctx); err != nil {
			t.Fatalf("rollback probe: %v", err)
		}
		if count := countActivitySavedLifecycleEvents(t, ctx, pool, item.ID); count != 0 {
			t.Fatalf("rollback outbox count = %d, want 0", count)
		}
	})

	item := newActivitySavedLifecycleIntegrationActivity(t)
	if err := repo.CreateActivity(ctx, item); err != nil {
		t.Fatalf("create public activity: %v", err)
	}
	if item.SavedSourceRevision == 0 || item.SavedProjectionRevision == 0 || item.SavedVisibilityRevision == 0 {
		t.Fatalf("created Saved revisions = %d/%d/%d", item.SavedSourceRevision, item.SavedProjectionRevision, item.SavedVisibilityRevision)
	}
	assertActivitySavedLifecycleCount(t, ctx, pool, item.ID, 1)
	assertLatestActivitySavedLifecycleEvent(t, ctx, pool, item.ID, "PUBLISHED", "PUBLIC", true)

	t.Run("unrelated update emits no event", func(t *testing.T) {
		current := loadActivitySavedLifecycleIntegrationActivity(t, ctx, repo, item.ID)
		beforeSource := current.SavedSourceRevision
		beforeProjection := current.SavedProjectionRevision
		beforeVisibility := current.SavedVisibilityRevision
		current.RequiresProfileCompletion = !current.RequiresProfileCompletion
		current.Revision++
		current.UpdatedAt = time.Now().UTC()
		if err := repo.UpdateActivity(ctx, current); err != nil {
			t.Fatalf("update unrelated field: %v", err)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, item.ID, 1)
		if current.SavedSourceRevision != beforeSource ||
			current.SavedProjectionRevision != beforeProjection ||
			current.SavedVisibilityRevision != beforeVisibility {
			t.Fatalf(
				"unrelated update revisions = %d/%d/%d, want %d/%d/%d",
				current.SavedSourceRevision,
				current.SavedProjectionRevision,
				current.SavedVisibilityRevision,
				beforeSource,
				beforeProjection,
				beforeVisibility,
			)
		}
	})

	t.Run("projection and visibility transitions emit once", func(t *testing.T) {
		current := loadActivitySavedLifecycleIntegrationActivity(t, ctx, repo, item.ID)
		current.Title = "Updated Saved title"
		current.Translations["en"] = model.ActivityLocalizedCopy{
			Title:       current.Title,
			Description: current.Description,
		}
		current.Revision++
		current.UpdatedAt = time.Now().UTC()
		if err := repo.UpdateActivity(ctx, current); err != nil {
			t.Fatalf("update projection: %v", err)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, item.ID, 2)
		assertLatestActivitySavedLifecycleEvent(t, ctx, pool, item.ID, "UPDATED", "PUBLIC", true)

		beforePrivateProjectionRevision := current.SavedProjectionRevision
		passwordHash := "private-owner-secret-hash"
		current.Visibility = enum.ActivityVisibilityPrivate
		current.VisibilityPasswordHash = &passwordHash
		current.Revision++
		current.UpdatedAt = time.Now().UTC()
		if err := repo.UpdateActivity(ctx, current); err != nil {
			t.Fatalf("make private: %v", err)
		}
		if current.SavedProjectionRevision <= beforePrivateProjectionRevision {
			t.Fatalf(
				"private projection revision = %d, want > %d",
				current.SavedProjectionRevision,
				beforePrivateProjectionRevision,
			)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, item.ID, 3)
		payload := assertLatestActivitySavedLifecycleEvent(t, ctx, pool, item.ID, "VISIBILITY_CHANGED", "PRIVATE", false)
		if strings.Contains(string(payload), current.Title) || strings.Contains(string(payload), passwordHash) {
			t.Fatalf("private event leaked payload: %s", payload)
		}

		privateProjectionRevision := current.SavedProjectionRevision
		current.Visibility = enum.ActivityVisibilityPublic
		current.VisibilityPasswordHash = nil
		current.Revision++
		current.UpdatedAt = time.Now().UTC()
		if err := repo.UpdateActivity(ctx, current); err != nil {
			t.Fatalf("restore public: %v", err)
		}
		if current.SavedProjectionRevision <= privateProjectionRevision {
			t.Fatalf(
				"restored projection revision = %d, want > %d",
				current.SavedProjectionRevision,
				privateProjectionRevision,
			)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, item.ID, 4)
		assertLatestActivitySavedLifecycleEvent(t, ctx, pool, item.ID, "VISIBILITY_CHANGED", "PUBLIC", true)

		beforeCancellationProjectionRevision := current.SavedProjectionRevision
		cancelledAt := time.Now().UTC()
		current.Status = enum.ActivityStatusCancelled
		current.CancelledAt = &cancelledAt
		current.Revision++
		current.UpdatedAt = cancelledAt
		if err := repo.UpdateActivity(ctx, current); err != nil {
			t.Fatalf("cancel activity: %v", err)
		}
		if current.SavedProjectionRevision <= beforeCancellationProjectionRevision {
			t.Fatalf(
				"cancelled projection revision = %d, want > %d",
				current.SavedProjectionRevision,
				beforeCancellationProjectionRevision,
			)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, item.ID, 5)
		assertLatestActivitySavedLifecycleEvent(t, ctx, pool, item.ID, "UNAVAILABLE", "UNAVAILABLE", false)

		current.Status = enum.ActivityStatusArchived
		current.Revision++
		current.UpdatedAt = time.Now().UTC()
		if err := repo.UpdateActivity(ctx, current); err != nil {
			t.Fatalf("archive activity: %v", err)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, item.ID, 6)
		assertLatestActivitySavedLifecycleEvent(t, ctx, pool, item.ID, "DELETED", "DELETED", false)
	})

	t.Run("restricted transition emits one rotated payload-free event", func(t *testing.T) {
		restricted := newActivitySavedLifecycleIntegrationActivity(t)
		if err := repo.CreateActivity(ctx, restricted); err != nil {
			t.Fatalf("create restricted candidate: %v", err)
		}
		beforeProjectionRevision := restricted.SavedProjectionRevision
		restricted.ModerationStatus = enum.ActivityModerationStatusRejected
		restricted.Revision++
		restricted.UpdatedAt = time.Now().UTC()
		if err := repo.UpdateActivity(ctx, restricted); err != nil {
			t.Fatalf("restrict activity: %v", err)
		}
		if restricted.SavedProjectionRevision <= beforeProjectionRevision {
			t.Fatalf(
				"restricted projection revision = %d, want > %d",
				restricted.SavedProjectionRevision,
				beforeProjectionRevision,
			)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, restricted.ID, 2)
		assertLatestActivitySavedLifecycleEvent(t, ctx, pool, restricted.ID, "VISIBILITY_CHANGED", "RESTRICTED", false)
	})

	t.Run("media transition rotates projection revision once", func(t *testing.T) {
		mediaActivity := newActivitySavedLifecycleIntegrationActivity(t)
		if err := repo.CreateActivity(ctx, mediaActivity); err != nil {
			t.Fatalf("create media activity: %v", err)
		}
		beforeProjection := mediaActivity.SavedProjectionRevision
		media, err := model.NewActivityMedia(model.NewActivityMediaParams{
			ActivityID: mediaActivity.ID,
			FileID:     uuid.New(),
			MediaType:  model.ActivityMediaTypeImage,
			IsCover:    true,
		})
		if err != nil {
			t.Fatalf("new media: %v", err)
		}
		if err = repo.ReplaceMedia(ctx, mediaActivity.ID, []*model.ActivityMedia{media}); err != nil {
			t.Fatalf("replace media: %v", err)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, mediaActivity.ID, 2)
		latest := loadActivitySavedLifecycleIntegrationActivity(t, ctx, repo, mediaActivity.ID)
		if latest.SavedProjectionRevision <= beforeProjection {
			t.Fatalf("media projection revision = %d, want > %d", latest.SavedProjectionRevision, beforeProjection)
		}
		payload := assertLatestActivitySavedLifecycleEvent(t, ctx, pool, mediaActivity.ID, "UPDATED", "PUBLIC", true)
		if !strings.Contains(string(payload), "saved_revision=") {
			t.Fatalf("media event lacks revision-bound reference: %s", payload)
		}

		publicMediaProjectionRevision := latest.SavedProjectionRevision
		latest.Visibility = enum.ActivityVisibilityPrivate
		latest.Revision++
		latest.UpdatedAt = time.Now().UTC()
		if err = repo.UpdateActivity(ctx, latest); err != nil {
			t.Fatalf("deny media activity: %v", err)
		}
		if latest.SavedProjectionRevision <= publicMediaProjectionRevision {
			t.Fatalf(
				"denied media projection revision = %d, want > %d",
				latest.SavedProjectionRevision,
				publicMediaProjectionRevision,
			)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, mediaActivity.ID, 3)
		assertLatestActivitySavedLifecycleEvent(t, ctx, pool, mediaActivity.ID, "VISIBILITY_CHANGED", "PRIVATE", false)

		deniedMediaProjectionRevision := latest.SavedProjectionRevision
		latest.Visibility = enum.ActivityVisibilityPublic
		latest.Revision++
		latest.UpdatedAt = time.Now().UTC()
		if err = repo.UpdateActivity(ctx, latest); err != nil {
			t.Fatalf("restore media activity: %v", err)
		}
		if latest.SavedProjectionRevision <= deniedMediaProjectionRevision {
			t.Fatalf(
				"restored media projection revision = %d, want > %d",
				latest.SavedProjectionRevision,
				deniedMediaProjectionRevision,
			)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, mediaActivity.ID, 4)
		payload = assertLatestActivitySavedLifecycleEvent(t, ctx, pool, mediaActivity.ID, "VISIBILITY_CHANGED", "PUBLIC", true)
		newReference := fmt.Sprintf("saved_revision=%d", latest.SavedProjectionRevision)
		oldReference := fmt.Sprintf("saved_revision=%d", publicMediaProjectionRevision)
		if !strings.Contains(string(payload), newReference) || strings.Contains(string(payload), oldReference) {
			t.Fatalf("restored media reference was not rotated: %s", payload)
		}
	})

	t.Run("hard delete is transactional and payload free", func(t *testing.T) {
		deleted := newActivitySavedLifecycleIntegrationActivity(t)
		if err := repo.CreateActivity(ctx, deleted); err != nil {
			t.Fatalf("create hard-delete activity: %v", err)
		}
		before := countActivitySavedLifecycleEvents(t, ctx, pool, deleted.ID)
		if _, err := pool.Exec(ctx, `DELETE FROM activities WHERE id = $1`, deleted.ID); err != nil {
			t.Fatalf("hard delete activity: %v", err)
		}
		assertActivitySavedLifecycleCount(t, ctx, pool, deleted.ID, before+1)
		assertLatestActivitySavedLifecycleEvent(t, ctx, pool, deleted.ID, "DELETED", "DELETED", false)
	})

	t.Run("concurrent claim uses disjoint skip locked batches and recovers lease", func(t *testing.T) {
		for range 6 {
			candidate := newActivitySavedLifecycleIntegrationActivity(t)
			if err := repo.CreateActivity(ctx, candidate); err != nil {
				t.Fatalf("create claim candidate: %v", err)
			}
		}
		now := time.Now().UTC().Add(time.Second)
		start := make(chan struct{})
		type claimResult struct {
			worker string
			items  []model.ActivitySavedLifecycleOutboxEvent
			err    error
		}
		results := make(chan claimResult, 2)
		var wait sync.WaitGroup
		for _, workerID := range []string{"claim-worker-a", "claim-worker-b"} {
			wait.Add(1)
			go func(worker string) {
				defer wait.Done()
				<-start
				items, err := repo.ClaimActivitySavedLifecycleEvents(ctx, worker, 2, now, 5*time.Second)
				results <- claimResult{worker: worker, items: items, err: err}
			}(workerID)
		}
		close(start)
		wait.Wait()
		close(results)

		seen := make(map[uuid.UUID]model.ActivitySavedLifecycleOutboxEvent)
		var first model.ActivitySavedLifecycleOutboxEvent
		for result := range results {
			if result.err != nil {
				t.Fatalf("claim %s: %v", result.worker, result.err)
			}
			if len(result.items) != 2 {
				t.Fatalf("claim %s count = %d, want 2", result.worker, len(result.items))
			}
			for _, event := range result.items {
				if _, duplicate := seen[event.ID]; duplicate {
					t.Fatalf("event %s claimed by both workers", event.ID)
				}
				seen[event.ID] = event
				if first.ID == uuid.Nil {
					first = event
				}
			}
		}

		recovered, err := repo.ClaimActivitySavedLifecycleEvents(
			ctx,
			"recovery-worker",
			100,
			now.Add(10*time.Second),
			5*time.Second,
		)
		if err != nil {
			t.Fatalf("recover expired leases: %v", err)
		}
		found := false
		for _, event := range recovered {
			if event.ID != first.ID {
				continue
			}
			found = true
			if !event.RecoveredLease || !strings.EqualFold(string(event.Payload), string(first.Payload)) {
				t.Fatalf("recovered event changed semantics: %+v", event)
			}
		}
		if !found {
			t.Fatalf("expired event %s was not recovered", first.ID)
		}
	})

	t.Run("bounded retries reach durable dead state", func(t *testing.T) {
		if _, err := pool.Exec(ctx, `DELETE FROM activity_saved_lifecycle_outbox`); err != nil {
			t.Fatalf("clear previous test events: %v", err)
		}
		if _, err := pool.Exec(ctx, `ALTER TABLE activity_saved_lifecycle_outbox ALTER COLUMN max_attempts SET DEFAULT 2`); err != nil {
			t.Fatalf("set test max attempts: %v", err)
		}
		candidate := newActivitySavedLifecycleIntegrationActivity(t)
		if err := repo.CreateActivity(ctx, candidate); err != nil {
			t.Fatalf("create retry candidate: %v", err)
		}
		if _, err := pool.Exec(ctx, `ALTER TABLE activity_saved_lifecycle_outbox ALTER COLUMN max_attempts SET DEFAULT 12`); err != nil {
			t.Fatalf("restore max attempts default: %v", err)
		}

		now := time.Now().UTC().Add(time.Second)
		claimed, err := repo.ClaimActivitySavedLifecycleEvents(ctx, "retry-worker-1", 1, now, time.Second)
		if err != nil || len(claimed) != 1 {
			t.Fatalf("first retry claim = %d/%v", len(claimed), err)
		}
		dead, updated, err := repo.MarkActivitySavedLifecycleFailed(
			ctx,
			claimed[0].ID,
			"retry-worker-1",
			"PUBLISH_FAILED",
			now,
		)
		if err != nil || dead || !updated {
			t.Fatalf("first failure = dead:%v updated:%v err:%v", dead, updated, err)
		}
		claimed, err = repo.ClaimActivitySavedLifecycleEvents(ctx, "retry-worker-2", 1, now.Add(time.Second), time.Second)
		if err != nil || len(claimed) != 1 {
			t.Fatalf("second retry claim = %d/%v", len(claimed), err)
		}
		dead, updated, err = repo.MarkActivitySavedLifecycleFailed(
			ctx,
			claimed[0].ID,
			"retry-worker-2",
			"PUBLISH_FAILED",
			now.Add(time.Second),
		)
		if err != nil || !dead || !updated {
			t.Fatalf("second failure = dead:%v updated:%v err:%v", dead, updated, err)
		}
		var status string
		var attempts int
		if err = pool.QueryRow(ctx, `
			SELECT status, attempt_count
			FROM activity_saved_lifecycle_outbox
			WHERE id = $1
		`, claimed[0].ID).Scan(&status, &attempts); err != nil {
			t.Fatalf("load dead event: %v", err)
		}
		if status != "DEAD" || attempts != 2 {
			t.Fatalf("dead event status/attempts = %s/%d", status, attempts)
		}
	})

	downSQL, err := os.ReadFile("../../../migrations/022_saved_lifecycle_outbox.down.sql")
	if err != nil {
		t.Fatalf("read guarded down migration: %v", err)
	}
	if _, err = pool.Exec(ctx, string(downSQL)); err == nil {
		t.Fatal("down migration succeeded with live outbox data")
	} else {
		var pgErr *pgconn.PgError
		if !errors.As(err, &pgErr) || pgErr.Code != "55000" {
			t.Fatalf("guarded down error = %v, want SQLSTATE 55000", err)
		}
	}
}

func TestActivitySavedLifecycleMigrationUpDownPostgres17(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv(activitySavedLifecycleIntegrationDSNEnv))
	if dsn == "" {
		t.Skip(activitySavedLifecycleIntegrationDSNEnv + " is not set")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	pool, cleanup := newActivitySavedLifecycleIntegrationPool(t, ctx, dsn)
	defer cleanup()
	assertActivitySavedLifecyclePostgres17(t, ctx, pool)
	applyActivityMigrations(t, ctx, pool)

	downSQL, err := os.ReadFile("../../../migrations/022_saved_lifecycle_outbox.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}
	if _, err = pool.Exec(ctx, string(downSQL)); err != nil {
		t.Fatalf("apply empty down migration: %v", err)
	}
	var outboxExists bool
	if err = pool.QueryRow(ctx, `
		SELECT to_regclass('activity_saved_lifecycle_outbox') IS NOT NULL
	`).Scan(&outboxExists); err != nil {
		t.Fatalf("check dropped outbox: %v", err)
	}
	if outboxExists {
		t.Fatal("activity Saved lifecycle outbox still exists after down migration")
	}
	var revisionColumns int
	if err = pool.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM information_schema.columns
		WHERE table_schema = current_schema()
		  AND table_name = 'activities'
		  AND column_name IN (
		    'saved_source_revision',
		    'saved_projection_revision',
		    'saved_visibility_revision'
		  )
	`).Scan(&revisionColumns); err != nil {
		t.Fatalf("check dropped revision columns: %v", err)
	}
	if revisionColumns != 0 {
		t.Fatalf("Saved revision columns remaining after down = %d", revisionColumns)
	}
}

func newActivitySavedLifecycleIntegrationPool(
	t *testing.T,
	ctx context.Context,
	dsn string,
) (*pgxpool.Pool, func()) {
	t.Helper()
	adminConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		t.Fatalf("parse integration DSN: %v", err)
	}
	adminPool, err := pgxpool.NewWithConfig(ctx, adminConfig)
	if err != nil {
		t.Fatalf("open integration admin pool: %v", err)
	}
	schema := "activity_saved_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	identifier := pgx.Identifier{schema}.Sanitize()
	if _, err = adminPool.Exec(ctx, "CREATE SCHEMA "+identifier); err != nil {
		adminPool.Close()
		t.Fatalf("create integration schema: %v", err)
	}

	testConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		adminPool.Close()
		t.Fatalf("parse test pool DSN: %v", err)
	}
	if testConfig.ConnConfig.RuntimeParams == nil {
		testConfig.ConnConfig.RuntimeParams = make(map[string]string)
	}
	testConfig.ConnConfig.RuntimeParams["search_path"] = schema
	pool, err := pgxpool.NewWithConfig(ctx, testConfig)
	if err != nil {
		_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+identifier+" CASCADE")
		adminPool.Close()
		t.Fatalf("open integration test pool: %v", err)
	}
	cleanup := func() {
		pool.Close()
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		_, _ = adminPool.Exec(cleanupCtx, "DROP SCHEMA "+identifier+" CASCADE")
		adminPool.Close()
	}
	return pool, cleanup
}

func assertActivitySavedLifecyclePostgres17(t *testing.T, ctx context.Context, pool *pgxpool.Pool) {
	t.Helper()
	var raw string
	if err := pool.QueryRow(ctx, `SHOW server_version_num`).Scan(&raw); err != nil {
		t.Fatalf("read PostgreSQL version: %v", err)
	}
	version, err := strconv.Atoi(raw)
	if err != nil || version < 170000 || version >= 180000 {
		t.Fatalf("PostgreSQL server_version_num = %q, want 17.x", raw)
	}
}

func applyActivityMigrations(t *testing.T, ctx context.Context, pool *pgxpool.Pool) {
	t.Helper()
	files, err := filepath.Glob("../../../migrations/*.up.sql")
	if err != nil {
		t.Fatalf("list activity migrations: %v", err)
	}
	sort.Strings(files)
	for _, path := range files {
		migration, readErr := os.ReadFile(path)
		if readErr != nil {
			t.Fatalf("read migration %s: %v", path, readErr)
		}
		if _, execErr := pool.Exec(ctx, string(migration)); execErr != nil {
			t.Fatalf("apply migration %s: %v", filepath.Base(path), execErr)
		}
	}
}

func newActivitySavedLifecycleIntegrationActivity(t *testing.T) *model.Activity {
	t.Helper()
	now := time.Now().UTC()
	country := "KZ"
	city := "Almaty"
	address := "Dostyk Avenue 1"
	item, err := model.NewActivity(model.NewActivityParams{
		HostUserID:           uuid.New(),
		Title:                "Production Saved Activity",
		Description:          "A sufficiently detailed public Activity description",
		SourceLanguage:       "en",
		Format:               enum.ActivityFormatOffline,
		Visibility:           enum.ActivityVisibilityPublic,
		CategorySlug:         "walking",
		LanguageCode:         "en",
		Timezone:             "Asia/Almaty",
		StartAt:              now.Add(48 * time.Hour),
		EndAt:                now.Add(50 * time.Hour),
		RegistrationDeadline: now.Add(47 * time.Hour),
		CapacityType:         enum.ActivityCapacityTypeUnlimited,
		PriceType:            enum.ActivityPriceTypeFree,
		CountryCode:          &country,
		CityName:             &city,
		AddressText:          &address,
	})
	if err != nil {
		t.Fatalf("new integration activity: %v", err)
	}
	return item
}

func loadActivitySavedLifecycleIntegrationActivity(
	t *testing.T,
	ctx context.Context,
	repo *PGActivityRepository,
	activityID uuid.UUID,
) *model.Activity {
	t.Helper()
	item, err := repo.GetActivityByID(ctx, activityID)
	if err != nil {
		t.Fatalf("load integration activity: %v", err)
	}
	if item == nil {
		t.Fatal("integration activity is missing")
	}
	return item
}

func countActivitySavedLifecycleEvents(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	activityID uuid.UUID,
) int {
	t.Helper()
	var count int
	if err := pool.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM activity_saved_lifecycle_outbox
		WHERE activity_id = $1
	`, activityID).Scan(&count); err != nil {
		t.Fatalf("count lifecycle events: %v", err)
	}
	return count
}

func assertActivitySavedLifecycleCount(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	activityID uuid.UUID,
	want int,
) {
	t.Helper()
	if got := countActivitySavedLifecycleEvents(t, ctx, pool, activityID); got != want {
		t.Fatalf("activity lifecycle event count = %d, want %d", got, want)
	}
}

func assertLatestActivitySavedLifecycleEvent(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	activityID uuid.UUID,
	wantKind string,
	wantVisibility string,
	wantProjection bool,
) []byte {
	t.Helper()
	var kind string
	var visibility string
	var hasProjection bool
	var payload []byte
	err := pool.QueryRow(ctx, `
		SELECT event_kind, visibility, has_public_projection, payload
		FROM activity_saved_lifecycle_outbox
		WHERE activity_id = $1
		ORDER BY source_revision DESC, visibility_revision DESC, projection_revision DESC, id DESC
		LIMIT 1
	`, activityID).Scan(&kind, &visibility, &hasProjection, &payload)
	if err != nil {
		t.Fatalf("load latest lifecycle event: %v", err)
	}
	if kind != wantKind || visibility != wantVisibility || hasProjection != wantProjection {
		t.Fatalf(
			"latest lifecycle event = %s/%s/%v, want %s/%s/%v",
			kind,
			visibility,
			hasProjection,
			wantKind,
			wantVisibility,
			wantProjection,
		)
	}
	if wantProjection != strings.Contains(string(payload), "public_projection") {
		t.Fatalf("payload projection presence mismatch: %s", payload)
	}
	decoded := new(contentv1.SavedSourceLifecycleEvent)
	if err = (protojson.UnmarshalOptions{DiscardUnknown: false}).Unmarshal(payload, decoded); err != nil {
		t.Fatalf("latest lifecycle payload is not strict proto JSON: %v: %s", err, payload)
	}
	if decoded.GetTarget().GetEntityId() != activityID.String() {
		t.Fatalf("latest lifecycle payload target = %+v", decoded.GetTarget())
	}
	if (decoded.GetPublicProjection() != nil) != wantProjection {
		t.Fatalf("decoded lifecycle projection presence mismatch: %s", payload)
	}
	return payload
}

func Example_activitySavedLifecycleIntegrationDSN() {
	fmt.Println("postgres://activity_service:activity_secret_dev@localhost:5438/activity_service_db?sslmode=disable")
	// Output: postgres://activity_service:activity_secret_dev@localhost:5438/activity_service_db?sslmode=disable
}
