package repository

import (
	"context"
	"crypto/sha256"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const savedLifecycleIntegrationDSNEnv = "SAVED_SERVICE_REPOSITORY_TEST_DSN"

func TestPGSavedLifecycleRepositoryDedupPrivacyAndIndependentRevisions(t *testing.T) {
	pool, repository := openSavedLifecycleIntegration(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	contract := repositoryLifecycleContract(t, domain.EntityTypeActivity)
	target := integrationLifecycleTarget(t, domain.EntityTypeActivity)
	seedLifecycleProjectionShell(t, pool, target, contract.SourceService, now)

	publicEvent := repositoryLifecycleEventForTarget(t, contract, target, now, 1, 1, 1, domain.VisibilityPublic, true)
	outcome, err := repository.Apply(ctx, publicEvent, now)
	if err != nil || outcome.Code != savedlifecycle.OutcomeApplied ||
		!outcome.SourceApplied || !outcome.ProjectionApplied || !outcome.VisibilityApplied {
		t.Fatalf("Apply(PUBLIC) = (%+v, %v)", outcome, err)
	}
	assertLifecycleProjection(t, pool, target, "PUBLIC", 1, 1, 1, true)

	duplicate, err := repository.Apply(ctx, publicEvent, now.Add(time.Second))
	if err != nil || duplicate.Code != savedlifecycle.OutcomeDuplicate ||
		duplicate.OriginalCode != savedlifecycle.OutcomeApplied {
		t.Fatalf("Apply(duplicate) = (%+v, %v)", duplicate, err)
	}
	assertLifecycleInboxCount(t, pool, 1)

	conflict := publicEvent
	conflict.EnvelopeFingerprint = sha256.Sum256([]byte("different immutable semantics"))
	_, err = repository.Apply(ctx, conflict, now.Add(2*time.Second))
	assertLifecyclePermanentCode(t, err, savedlifecycle.ErrorCodeEventIdentityConflict)
	assertLifecycleInboxCount(t, pool, 1)

	privateEvent := repositoryLifecycleEventForTarget(
		t, contract, target, now.Add(3*time.Second), 2, 1, 2, domain.VisibilityPrivate, false,
	)
	outcome, err = repository.Apply(ctx, privateEvent, now.Add(3*time.Second))
	if err != nil || outcome.Code != savedlifecycle.OutcomeApplied || !outcome.VisibilityApplied {
		t.Fatalf("Apply(PRIVATE) = (%+v, %v)", outcome, err)
	}
	assertLifecycleProjection(t, pool, target, "PRIVATE", 2, 1, 2, false)
	assertLifecyclePublicColumnsCleared(t, pool, target)

	stalePublic := repositoryLifecycleEventForTarget(
		t, contract, target, now.Add(4*time.Second), 3, 2, 1, domain.VisibilityPublic, true,
	)
	outcome, err = repository.Apply(ctx, stalePublic, now.Add(4*time.Second))
	if err != nil || outcome.Code != savedlifecycle.OutcomeAppliedSourceOnly ||
		!outcome.SourceApplied || outcome.ProjectionApplied || outcome.VisibilityApplied {
		t.Fatalf("Apply(stale PUBLIC) = (%+v, %v)", outcome, err)
	}
	assertLifecycleProjection(t, pool, target, "PRIVATE", 3, 1, 2, false)
	assertLifecyclePublicColumnsCleared(t, pool, target)

	restored := repositoryLifecycleEventForTarget(
		t, contract, target, now.Add(5*time.Second), 4, 1, 4, domain.VisibilityPublic, true,
	)
	restored.Kind = savedlifecycle.EventVisibilityChanged
	if _, err = repository.Apply(ctx, restored, now.Add(5*time.Second)); err != nil {
		t.Fatalf("Apply(restored PUBLIC) error = %v", err)
	}
	assertLifecycleProjection(t, pool, target, "PUBLIC", 4, 1, 4, true)

	projectionOnly := repositoryLifecycleEventForTarget(
		t, contract, target, now.Add(6*time.Second), 3, 2, 4, domain.VisibilityPublic, true,
	)
	projectionOnly.PublicProjection.Localized.EN.Title = "Newer projection"
	outcome, err = repository.Apply(ctx, projectionOnly, now.Add(6*time.Second))
	if err != nil || outcome.SourceApplied || !outcome.ProjectionApplied || outcome.VisibilityApplied {
		t.Fatalf("Apply(projection-only) = (%+v, %v)", outcome, err)
	}
	assertLifecycleProjection(t, pool, target, "PUBLIC", 4, 2, 4, true)

	publicWithoutPayload := repositoryLifecycleEventForTarget(
		t, contract, target, now.Add(7*time.Second), 6, 3, 5, domain.VisibilityPublic, false,
	)
	outcome, err = repository.Apply(ctx, publicWithoutPayload, now.Add(7*time.Second))
	if err != nil || !outcome.SourceApplied || outcome.ProjectionApplied || !outcome.VisibilityApplied {
		t.Fatalf("Apply(PUBLIC no payload) = (%+v, %v)", outcome, err)
	}
	assertLifecycleProjection(t, pool, target, "PUBLIC", 6, 2, 5, true)
}

func TestPGSavedLifecycleRepositoryUnknownTargetAtomicityAndRetention(t *testing.T) {
	pool, repository := openSavedLifecycleIntegration(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Microsecond)
	contract := repositoryLifecycleContract(t, domain.EntityTypeGuide)
	unknownTarget := integrationLifecycleTarget(t, domain.EntityTypeGuide)
	event := repositoryLifecycleEventForTarget(
		t, contract, unknownTarget, now, 1, 1, 1, domain.VisibilityPublic, false,
	)
	outcome, err := repository.Apply(ctx, event, now)
	if err != nil || outcome.Code != savedlifecycle.OutcomeIgnoredUnknownTarget {
		t.Fatalf("Apply(unknown) = (%+v, %v)", outcome, err)
	}
	assertLifecycleProjectionCount(t, pool, unknownTarget, 0)
	assertLifecycleInboxCount(t, pool, 1)

	activityContract := repositoryLifecycleContract(t, domain.EntityTypeActivity)
	mismatchedTarget := integrationLifecycleTarget(t, domain.EntityTypeActivity)
	seedLifecycleProjectionShell(t, pool, mismatchedTarget, "place-service", now)
	mismatch := repositoryLifecycleEventForTarget(
		t, activityContract, mismatchedTarget, now.Add(time.Second), 1, 1, 1, domain.VisibilityPublic, true,
	)
	_, err = repository.Apply(ctx, mismatch, now.Add(time.Second))
	assertLifecyclePermanentCode(t, err, savedlifecycle.ErrorCodeProjectionSourceConflict)
	assertLifecycleInboxCount(t, pool, 1)

	expiredAt := now.Add(-savedlifecycle.InboxRetention - time.Hour)
	expiredTarget := integrationLifecycleTarget(t, domain.EntityTypeGuide)
	expired := repositoryLifecycleEventForTarget(
		t, contract, expiredTarget, expiredAt, 1, 1, 1, domain.VisibilityPublic, false,
	)
	if _, err = repository.Apply(ctx, expired, expiredAt); err != nil {
		t.Fatalf("Apply(expired inbox seed) error = %v", err)
	}
	deleted, err := repository.DeleteExpired(ctx, now, 1)
	if err != nil || deleted != 1 {
		t.Fatalf("DeleteExpired() = (%d, %v)", deleted, err)
	}
	assertLifecycleInboxCount(t, pool, 1)
}

func TestPGSavedLifecycleRepositoryConcurrentPublicDenyConvergesToNewerDeny(t *testing.T) {
	pool, repository := openSavedLifecycleIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	contract := repositoryLifecycleContract(t, domain.EntityTypeActivity)
	target := integrationLifecycleTarget(t, domain.EntityTypeActivity)
	seedLifecycleProjectionShell(t, pool, target, contract.SourceService, now)
	publicEvent := repositoryLifecycleEventForTarget(
		t, contract, target, now.Add(time.Second), 10, 10, 10, domain.VisibilityPublic, true,
	)
	denyEvent := repositoryLifecycleEventForTarget(
		t, contract, target, now.Add(2*time.Second), 11, 11, 11, domain.VisibilityPrivate, false,
	)

	start := make(chan struct{})
	errorsByEvent := make(chan error, 2)
	var workers sync.WaitGroup
	for _, event := range []savedlifecycle.Event{publicEvent, denyEvent} {
		event := event
		workers.Add(1)
		go func() {
			defer workers.Done()
			<-start
			_, applyErr := repository.Apply(context.Background(), event, now.Add(3*time.Second))
			errorsByEvent <- applyErr
		}()
	}
	close(start)
	workers.Wait()
	close(errorsByEvent)
	for applyErr := range errorsByEvent {
		if applyErr != nil {
			t.Fatalf("concurrent Apply() error = %v", applyErr)
		}
	}
	assertLifecycleProjection(t, pool, target, "PRIVATE", 11, 11, 11, false)
	assertLifecyclePublicColumnsCleared(t, pool, target)
	assertLifecycleInboxCount(t, pool, 2)
}

func TestPGSavedLifecycleNewerSourceRevisionClearsReconciliationQuarantine(t *testing.T) {
	pool, repository := openSavedLifecycleIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	contract := repositoryLifecycleContract(t, domain.EntityTypeGuide)
	target := integrationLifecycleTarget(t, domain.EntityTypeGuide)
	seedLifecycleProjectionShell(t, pool, target, contract.SourceService, now)
	initial := repositoryLifecycleEventForTarget(
		t,
		contract,
		target,
		now,
		1,
		1,
		1,
		domain.VisibilityPublic,
		true,
	)
	if _, err := repository.Apply(context.Background(), initial, now); err != nil {
		t.Fatalf("Apply(initial PUBLIC) error = %v", err)
	}
	if _, err := pool.Exec(
		context.Background(),
		`UPDATE saved_content_projections
		 SET reconciliation_failure_count = 3,
		     reconciliation_failure_kind = 'INVARIANT',
		     reconciliation_quarantined_at = clock_timestamp(),
		     reconciliation_quarantine_reason = 'INVARIANT',
		     reconciliation_next_attempt_at = NULL
		 WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()),
		target.EntityID(),
	); err != nil {
		t.Fatalf("seed reconciliation quarantine: %v", err)
	}

	newerSource := repositoryLifecycleEventForTarget(
		t,
		contract,
		target,
		now.Add(time.Second),
		2,
		1,
		1,
		domain.VisibilityPublic,
		true,
	)
	outcome, err := repository.Apply(
		context.Background(),
		newerSource,
		now.Add(time.Second),
	)
	if err != nil || outcome.Code != savedlifecycle.OutcomeAppliedSourceOnly ||
		!outcome.SourceApplied || outcome.ProjectionApplied || outcome.VisibilityApplied {
		t.Fatalf("Apply(newer source) = (%+v, %v)", outcome, err)
	}
	var failureCount int
	var failureKind, quarantinedAt, quarantineReason any
	if err = pool.QueryRow(
		context.Background(),
		`SELECT COALESCE(reconciliation_failure_count, 0),
		        reconciliation_failure_kind,
		        reconciliation_quarantined_at,
		        reconciliation_quarantine_reason
		 FROM saved_content_projections
		 WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()),
		target.EntityID(),
	).Scan(&failureCount, &failureKind, &quarantinedAt, &quarantineReason); err != nil {
		t.Fatalf("read reconciliation quarantine state: %v", err)
	}
	if failureCount != 0 || failureKind != nil || quarantinedAt != nil || quarantineReason != nil {
		t.Fatalf(
			"quarantine state = (%d,%v,%v,%v), want reset",
			failureCount,
			failureKind,
			quarantinedAt,
			quarantineReason,
		)
	}
}

func openSavedLifecycleIntegration(
	t *testing.T,
) (*pgxpool.Pool, *PGSavedLifecycleRepository) {
	t.Helper()
	dsn := strings.TrimSpace(os.Getenv(savedLifecycleIntegrationDSNEnv))
	if dsn == "" {
		t.Skipf("%s is not set", savedLifecycleIntegrationDSNEnv)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	adminPool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect integration database: %v", err)
	}
	if err = adminPool.Ping(ctx); err != nil {
		adminPool.Close()
		t.Fatalf("ping integration database: %v", err)
	}

	schema := "saved_lifecycle_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	quotedSchema := pgx.Identifier{schema}.Sanitize()
	if _, err = adminPool.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		adminPool.Close()
		t.Fatalf("create isolated schema: %v", err)
	}
	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		t.Fatalf("parse integration DSN: %v", err)
	}
	poolConfig.ConnConfig.RuntimeParams["search_path"] = quotedSchema
	poolConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		t.Fatalf("connect isolated schema: %v", err)
	}

	up001 := readSavedLifecycleMigration(t, "001_saved_core.up.sql")
	up002 := readSavedLifecycleMigration(t, "002_saved_collections.up.sql")
	up003 := readSavedLifecycleMigration(t, "003_saved_search.up.sql")
	up004 := readSavedLifecycleMigration(t, "004_saved_lifecycle_inbox.up.sql")
	up006 := readSavedLifecycleMigration(t, "006_saved_reconciliation_scheduler.up.sql")
	contract006b := readSavedLifecycleMigration(t, "006b_saved_reconciliation_scheduler_contract.sql")
	down006 := readSavedLifecycleMigration(t, "006_saved_reconciliation_scheduler.down.sql")
	down004 := readSavedLifecycleMigration(t, "004_saved_lifecycle_inbox.down.sql")
	down003 := readSavedLifecycleMigration(t, "003_saved_search.down.sql")
	down002 := readSavedLifecycleMigration(t, "002_saved_collections.down.sql")
	down001 := readSavedLifecycleMigration(t, "001_saved_core.down.sql")
	for _, migration := range []struct {
		name string
		sql  string
	}{{"001", up001}, {"002", up002}, {"003", up003}, {"004", up004}, {"006", up006}, {"006b", contract006b}} {
		if _, err = pool.Exec(ctx, migration.sql); err != nil {
			pool.Close()
			_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
			adminPool.Close()
			t.Fatalf("apply migration %s: %v", migration.name, err)
		}
	}

	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cleanupCancel()
		for _, migration := range []struct {
			name string
			sql  string
		}{{"006", down006}, {"004", down004}, {"003", down003}, {"002", down002}, {"001", down001}} {
			if _, cleanupErr := pool.Exec(cleanupCtx, migration.sql); cleanupErr != nil {
				t.Errorf("apply migration %s down: %v", migration.name, cleanupErr)
			}
		}
		pool.Close()
		if _, cleanupErr := adminPool.Exec(cleanupCtx, "DROP SCHEMA "+quotedSchema+" CASCADE"); cleanupErr != nil {
			t.Errorf("drop isolated schema: %v", cleanupErr)
		}
		adminPool.Close()
	})

	repository, err := NewPGSavedLifecycleRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedLifecycleRepository() error = %v", err)
	}
	return pool, repository
}

func readSavedLifecycleMigration(t testing.TB, name string) string {
	t.Helper()
	path := filepath.Join("..", "..", "..", "migrations", name)
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}
	return string(contents)
}

func integrationLifecycleTarget(t testing.TB, entityType domain.EntityType) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	return target
}

func seedLifecycleProjectionShell(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	sourceService string,
	createdAt time.Time,
) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
        INSERT INTO saved_content_projections (
            entity_type, entity_id, source_service,
            source_revision, projection_revision, visibility_revision,
            visibility_status, visibility_validated_at,
            search_document_version, shell_expires_at, ever_referenced,
            created_at, updated_at
        ) VALUES ($1, $2, $3, 0, 0, 0, 'UNKNOWN', NULL, 0, $4, FALSE, $5, $5)`,
		string(target.EntityType()), target.EntityID(), sourceService,
		createdAt.Add(15*time.Minute), createdAt,
	)
	if err != nil {
		t.Fatalf("seed projection shell: %v", err)
	}
}

func assertLifecycleProjection(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	wantVisibility string,
	wantSource int64,
	wantProjection int64,
	wantVisibilityRevision int64,
	wantPayload bool,
) {
	t.Helper()
	var visibility string
	var sourceRevision, projectionRevision, visibilityRevision int64
	var hasTitle bool
	err := pool.QueryRow(context.Background(), `
        SELECT visibility_status, source_revision, projection_revision, visibility_revision,
               title_en IS NOT NULL
        FROM saved_content_projections
        WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID(),
	).Scan(&visibility, &sourceRevision, &projectionRevision, &visibilityRevision, &hasTitle)
	if err != nil {
		t.Fatalf("read lifecycle projection: %v", err)
	}
	if visibility != wantVisibility || sourceRevision != wantSource ||
		projectionRevision != wantProjection || visibilityRevision != wantVisibilityRevision ||
		hasTitle != wantPayload {
		t.Fatalf("projection = visibility=%s revisions=%d/%d/%d payload=%v, want %s %d/%d/%d %v",
			visibility, sourceRevision, projectionRevision, visibilityRevision, hasTitle,
			wantVisibility, wantSource, wantProjection, wantVisibilityRevision, wantPayload)
	}
}

func assertLifecyclePublicColumnsCleared(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
) {
	t.Helper()
	var populated int64
	err := pool.QueryRow(context.Background(), `
        SELECT count(*)
        FROM saved_content_projections
        WHERE entity_type = $1
          AND entity_id = $2
          AND (
              source_default_locale IS NOT NULL OR title_en IS NOT NULL OR subtitle_en IS NOT NULL
              OR city_en IS NOT NULL OR country_en IS NOT NULL OR display_location_en IS NOT NULL
              OR normalized_search_document_en IS NOT NULL OR media_reference IS NOT NULL
              OR canonical_detail_route IS NOT NULL OR rating_value IS NOT NULL
              OR price_summary IS NOT NULL OR availability_summary IS NOT NULL
          )`, string(target.EntityType()), target.EntityID()).Scan(&populated)
	if err != nil {
		t.Fatalf("check cleared projection: %v", err)
	}
	if populated != 0 {
		t.Fatalf("non-public projection still has public columns")
	}
}

func assertLifecycleInboxCount(t testing.TB, pool *pgxpool.Pool, want int64) {
	t.Helper()
	var count int64
	if err := pool.QueryRow(context.Background(), "SELECT count(*) FROM saved_inbox_dedup").Scan(&count); err != nil {
		t.Fatalf("count lifecycle inbox: %v", err)
	}
	if count != want {
		t.Fatalf("inbox count = %d, want %d", count, want)
	}
}

func assertLifecycleProjectionCount(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	want int64,
) {
	t.Helper()
	var count int64
	if err := pool.QueryRow(context.Background(), `
        SELECT count(*) FROM saved_content_projections
        WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID()).Scan(&count); err != nil {
		t.Fatalf("count lifecycle projection: %v", err)
	}
	if count != want {
		t.Fatalf("projection count = %d, want %d", count, want)
	}
}

func assertLifecyclePermanentCode(
	t testing.TB,
	err error,
	want savedlifecycle.ErrorCode,
) {
	t.Helper()
	var permanent *savedlifecycle.PermanentError
	if !errors.As(err, &permanent) || permanent.Code != want {
		t.Fatalf("error = %v, want permanent %s", err, want)
	}
}
