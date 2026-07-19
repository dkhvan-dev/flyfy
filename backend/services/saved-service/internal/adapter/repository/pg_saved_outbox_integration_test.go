package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	savedoutbox "kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const savedOutboxIntegrationDSNEnv = "SAVED_SERVICE_REPOSITORY_TEST_DSN"

func TestPGSavedOutboxConcurrentClaimAndPrivacySafeMapping(t *testing.T) {
	pool, repository := openSavedOutboxIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	fixtures := make([]savedOutboxFixture, 0, 6)
	entityTypes := []domain.EntityType{
		domain.EntityTypeActivity,
		domain.EntityTypeAttraction,
		domain.EntityTypeGuide,
		domain.EntityTypeActivity,
		domain.EntityTypeAttraction,
		domain.EntityTypeGuide,
	}
	for index, entityType := range entityTypes {
		kind := savedoutbox.EventSavedItemActivated
		if index%2 == 1 {
			kind = savedoutbox.EventSavedItemRemoved
		}
		fixtures = append(fixtures, insertSavedOutboxFixture(
			t,
			pool,
			kind,
			entityType,
			now.Add(-time.Duration(10-index)*time.Minute),
		))
	}

	start := make(chan struct{})
	type claimResult struct {
		records []savedoutbox.ClaimedRecord
		err     error
	}
	results := make(chan claimResult, 2)
	var workers sync.WaitGroup
	for range 2 {
		workers.Add(1)
		go func() {
			defer workers.Done()
			<-start
			records, err := repository.ClaimDue(context.Background(), savedoutbox.ClaimRequest{
				Now:         now,
				Limit:       3,
				MaxAttempts: 3,
			})
			results <- claimResult{records: records, err: err}
		}()
	}
	close(start)
	workers.Wait()
	close(results)

	claimed := make([]savedoutbox.ClaimedRecord, 0, len(fixtures))
	seen := make(map[uuid.UUID]bool, len(fixtures))
	for result := range results {
		if result.err != nil {
			t.Fatalf("ClaimDue() error = %v", result.err)
		}
		for _, record := range result.records {
			if seen[record.Lease.EventID] {
				t.Fatalf("event %s claimed more than once", record.Lease.EventID)
			}
			seen[record.Lease.EventID] = true
			if record.Lease.Attempt != 1 || record.Lease.AcquiredAt != now {
				t.Fatalf("claim lease = %+v", record.Lease)
			}
			claimed = append(claimed, record)
		}
	}
	if len(claimed) != len(fixtures) {
		t.Fatalf("claimed = %d, want %d", len(claimed), len(fixtures))
	}

	fixturesByEvent := make(map[uuid.UUID]savedOutboxFixture, len(fixtures))
	for _, fixture := range fixtures {
		fixturesByEvent[fixture.eventID] = fixture
	}
	for _, record := range claimed {
		event, err := savedoutbox.MapClaimedRecord(record)
		if err != nil {
			t.Fatalf("MapClaimedRecord() error = %v", err)
		}
		payload, err := json.Marshal(event)
		if err != nil {
			t.Fatalf("json.Marshal() error = %v", err)
		}
		fixture := fixturesByEvent[event.EventID]
		for _, secret := range []string{fixture.ownerID.String(), fixture.entityID, fixture.itemID.String()} {
			if strings.Contains(string(payload), secret) {
				t.Fatalf("payload leaks persisted identifier %q: %s", secret, payload)
			}
		}
		deliveredAt := now.Add(time.Second)
		if err = repository.MarkDelivered(context.Background(), savedoutbox.Delivery{
			Lease:       record.Lease,
			DeliveredAt: deliveredAt,
			RetainUntil: deliveredAt.Add(savedoutbox.TerminalRetention),
		}); err != nil {
			t.Fatalf("MarkDelivered() error = %v", err)
		}
	}
	assertSavedOutboxStatusCount(t, pool, "DELIVERED", len(fixtures))
}

func TestPGSavedOutboxStaleLeaseRetryDeadFencingAndCleanup(t *testing.T) {
	pool, repository := openSavedOutboxIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	fixture := insertSavedOutboxFixture(
		t,
		pool,
		savedoutbox.EventSavedItemRemoved,
		domain.EntityTypeActivity,
		now.Add(-time.Minute),
	)

	first := claimOneSavedOutbox(t, repository, now, 3)
	early, err := repository.RecoverStaleLeases(context.Background(), savedoutbox.RecoveryRequest{
		Now:                now.Add(9 * time.Second),
		LeaseExpiredBefore: now.Add(-time.Second),
		TerminalExpiresAt:  now.Add(9*time.Second + savedoutbox.TerminalRetention),
		Limit:              10,
		MaxAttempts:        3,
	})
	if err != nil || early != (savedoutbox.RecoveryResult{}) {
		t.Fatalf("early RecoverStaleLeases() = (%+v, %v)", early, err)
	}

	recoveredAt := now.Add(11 * time.Second)
	recovered, err := repository.RecoverStaleLeases(context.Background(), savedoutbox.RecoveryRequest{
		Now:                recoveredAt,
		LeaseExpiredBefore: now.Add(time.Second),
		TerminalExpiresAt:  recoveredAt.Add(savedoutbox.TerminalRetention),
		Limit:              10,
		MaxAttempts:        3,
	})
	if err != nil || recovered.Released != 1 || recovered.Dead != 0 {
		t.Fatalf("RecoverStaleLeases() = (%+v, %v)", recovered, err)
	}

	second := claimOneSavedOutbox(t, repository, recoveredAt, 3)
	if second.Lease.EventID != fixture.eventID || second.Lease.Attempt != 2 {
		t.Fatalf("second claim = %+v", second)
	}
	oldDeliveryAt := recoveredAt.Add(time.Second)
	err = repository.MarkDelivered(context.Background(), savedoutbox.Delivery{
		Lease:       first.Lease,
		DeliveredAt: oldDeliveryAt,
		RetainUntil: oldDeliveryAt.Add(savedoutbox.TerminalRetention),
	})
	if !errors.Is(err, savedoutbox.ErrLeaseLost) {
		t.Fatalf("stale MarkDelivered() error = %v", err)
	}

	failedAt := recoveredAt.Add(time.Second)
	retryAt := failedAt.Add(time.Second)
	disposition, err := repository.MarkFailed(context.Background(), savedoutbox.Failure{
		Lease:         second.Lease,
		Code:          savedoutbox.FailurePublishFailed,
		FailedAt:      failedAt,
		NextAttemptAt: retryAt,
		RetainUntil:   failedAt.Add(savedoutbox.TerminalRetention),
		MaxAttempts:   3,
	})
	if err != nil || disposition != savedoutbox.FailureRetryScheduled {
		t.Fatalf("MarkFailed(retry) = (%s, %v)", disposition, err)
	}

	third := claimOneSavedOutbox(t, repository, retryAt, 3)
	if third.Lease.Attempt != 3 {
		t.Fatalf("third attempt = %d", third.Lease.Attempt)
	}
	deadAt := retryAt.Add(time.Second)
	retainUntil := deadAt.Add(savedoutbox.TerminalRetention)
	disposition, err = repository.MarkFailed(context.Background(), savedoutbox.Failure{
		Lease:         third.Lease,
		Code:          savedoutbox.FailurePublishFailed,
		FailedAt:      deadAt,
		NextAttemptAt: deadAt,
		RetainUntil:   retainUntil,
		MaxAttempts:   3,
	})
	if err != nil || disposition != savedoutbox.FailureDead {
		t.Fatalf("MarkFailed(dead) = (%s, %v)", disposition, err)
	}
	assertSavedOutboxTerminalState(
		t,
		pool,
		fixture.eventID,
		"DEAD",
		3,
		string(savedoutbox.FailurePublishFailed),
		deadAt,
		retainUntil,
	)

	deleted, err := repository.DeleteExpired(context.Background(), savedoutbox.CleanupRequest{
		Now: retainUntil.Add(-time.Microsecond), Limit: 10,
	})
	if err != nil || deleted != 0 {
		t.Fatalf("DeleteExpired(before retention) = (%d, %v)", deleted, err)
	}
	deleted, err = repository.DeleteExpired(context.Background(), savedoutbox.CleanupRequest{
		Now: retainUntil, Limit: 10,
	})
	if err != nil || deleted != 1 {
		t.Fatalf("DeleteExpired(at retention) = (%d, %v)", deleted, err)
	}

	crashed := insertSavedOutboxFixture(
		t,
		pool,
		savedoutbox.EventSavedItemActivated,
		domain.EntityTypeGuide,
		now,
	)
	crashedClaim := claimOneSavedOutbox(t, repository, now.Add(time.Hour), 1)
	if crashedClaim.Lease.EventID != crashed.eventID || crashedClaim.Lease.Attempt != 1 {
		t.Fatalf("final crashed claim = %+v", crashedClaim)
	}
	crashRecoveredAt := now.Add(time.Hour + 11*time.Second)
	recovered, err = repository.RecoverStaleLeases(context.Background(), savedoutbox.RecoveryRequest{
		Now:                crashRecoveredAt,
		LeaseExpiredBefore: now.Add(time.Hour + time.Second),
		TerminalExpiresAt:  crashRecoveredAt.Add(savedoutbox.TerminalRetention),
		Limit:              10,
		MaxAttempts:        1,
	})
	if err != nil || recovered.Released != 0 || recovered.Dead != 1 {
		t.Fatalf("RecoverStaleLeases(final attempt) = (%+v, %v)", recovered, err)
	}
	assertSavedOutboxTerminalState(
		t,
		pool,
		crashed.eventID,
		"DEAD",
		1,
		string(savedoutbox.FailureAttemptsExhausted),
		crashRecoveredAt,
		crashRecoveredAt.Add(savedoutbox.TerminalRetention),
	)
}

type savedOutboxFixture struct {
	eventID  uuid.UUID
	ownerID  uuid.UUID
	itemID   uuid.UUID
	entityID string
}

func insertSavedOutboxFixture(
	t testing.TB,
	pool *pgxpool.Pool,
	kind savedoutbox.EventKind,
	entityType domain.EntityType,
	createdAt time.Time,
) savedOutboxFixture {
	t.Helper()
	fixture := savedOutboxFixture{
		eventID:  uuid.New(),
		ownerID:  uuid.New(),
		itemID:   uuid.New(),
		entityID: "private-target-" + uuid.NewString(),
	}
	stateGeneration := uuid.New()
	attributionID := uuid.New()
	itemCreatedAt := createdAt.Add(-2 * time.Minute)
	savedAt := createdAt.Add(-time.Minute)
	_, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_content_projections (
             entity_type, entity_id, source_service,
             source_revision, projection_revision, visibility_revision,
             visibility_status, visibility_validated_at,
             source_default_locale, title_en, ever_referenced,
             created_at, updated_at
         ) VALUES (
             $1, $2, 'integration-test', 1, 1, 1,
             'PUBLIC', $3, 'EN', 'Private fixture title', TRUE, $3, $3
         )`,
		string(entityType),
		fixture.entityID,
		itemCreatedAt,
	)
	if err != nil {
		t.Fatalf("insert projection fixture: %v", err)
	}

	relationshipState := "ACTIVE"
	relationshipVersion := int64(1)
	var removedAt, purgeEligibleAt any
	if kind == savedoutbox.EventSavedItemRemoved {
		relationshipState = "REMOVED"
		relationshipVersion = 2
		removedAt = createdAt
		purgeEligibleAt = createdAt.Add(14 * 24 * time.Hour)
	}
	_, err = pool.Exec(
		context.Background(),
		`INSERT INTO saved_items (
             id, owner_user_id, entity_type, entity_id, relationship_state,
             state_generation, relationship_attribution_id, relationship_version,
             dependent_membership_version, saved_at, removed_at, purge_eligible_at,
             created_at, updated_at
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 0, $9, $10, $11, $12, $13)`,
		fixture.itemID,
		fixture.ownerID,
		string(entityType),
		fixture.entityID,
		relationshipState,
		stateGeneration,
		attributionID,
		relationshipVersion,
		savedAt,
		removedAt,
		purgeEligibleAt,
		itemCreatedAt,
		createdAt,
	)
	if err != nil {
		t.Fatalf("insert saved item fixture: %v", err)
	}

	_, err = pool.Exec(
		context.Background(),
		`INSERT INTO saved_outbox (
             id, owner_user_id, saved_item_id, event_schema_version,
             event_type, entity_type, entity_id, relationship_state,
             state_generation, relationship_attribution_id, relationship_version,
             status, attempt_count, next_attempt_at, created_at, updated_at
         ) VALUES (
             $1, $2, $3, 1, $4, $5, $6, $7, $8, $9, $10,
             'PENDING', 0, $11, $11, $11
         )`,
		fixture.eventID,
		fixture.ownerID,
		fixture.itemID,
		string(kind),
		string(entityType),
		fixture.entityID,
		relationshipState,
		stateGeneration,
		attributionID,
		relationshipVersion,
		createdAt,
	)
	if err != nil {
		t.Fatalf("insert outbox fixture: %v", err)
	}
	return fixture
}

func claimOneSavedOutbox(
	t testing.TB,
	repository *PGSavedOutboxRepository,
	now time.Time,
	maxAttempts int,
) savedoutbox.ClaimedRecord {
	t.Helper()
	claimed, err := repository.ClaimDue(context.Background(), savedoutbox.ClaimRequest{
		Now: now, Limit: 1, MaxAttempts: maxAttempts,
	})
	if err != nil || len(claimed) != 1 {
		t.Fatalf("ClaimDue() = (%+v, %v)", claimed, err)
	}
	return claimed[0]
}

func assertSavedOutboxStatusCount(
	t testing.TB,
	pool *pgxpool.Pool,
	status string,
	want int,
) {
	t.Helper()
	var count int
	if err := pool.QueryRow(
		context.Background(),
		"SELECT count(*) FROM saved_outbox WHERE status = $1",
		status,
	).Scan(&count); err != nil {
		t.Fatalf("count outbox status %s: %v", status, err)
	}
	if count != want {
		t.Fatalf("outbox status %s count = %d, want %d", status, count, want)
	}
}

func assertSavedOutboxTerminalState(
	t testing.TB,
	pool *pgxpool.Pool,
	eventID uuid.UUID,
	wantStatus string,
	wantAttempts int,
	wantErrorCode string,
	wantTerminalAt time.Time,
	wantRetention time.Time,
) {
	t.Helper()
	var status, errorCode string
	var attempts int
	var lockedAt pgtype.Timestamptz
	var deadAt, retention time.Time
	if err := pool.QueryRow(
		context.Background(),
		`SELECT status, attempt_count, locked_at, last_error_code, dead_at, retention_expires_at
         FROM saved_outbox WHERE id = $1`,
		eventID,
	).Scan(&status, &attempts, &lockedAt, &errorCode, &deadAt, &retention); err != nil {
		t.Fatalf("read terminal outbox row: %v", err)
	}
	if status != wantStatus || attempts != wantAttempts || lockedAt.Valid ||
		errorCode != wantErrorCode || !deadAt.Equal(wantTerminalAt) || !retention.Equal(wantRetention) {
		t.Fatalf(
			"terminal row = status:%s attempts:%d lock:%v code:%s dead:%s retention:%s",
			status,
			attempts,
			lockedAt,
			errorCode,
			deadAt,
			retention,
		)
	}
}

func openSavedOutboxIntegration(
	t *testing.T,
) (*pgxpool.Pool, *PGSavedOutboxRepository) {
	t.Helper()
	dsn := strings.TrimSpace(os.Getenv(savedOutboxIntegrationDSNEnv))
	if dsn == "" {
		t.Skipf("%s is not set", savedOutboxIntegrationDSNEnv)
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

	schema := "saved_outbox_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	quotedSchema := pgx.Identifier{schema}.Sanitize()
	if _, err = adminPool.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		adminPool.Close()
		t.Fatalf("create isolated schema: %v", err)
	}
	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		dropSavedOutboxSchema(adminPool, quotedSchema)
		adminPool.Close()
		t.Fatalf("parse integration DSN: %v", err)
	}
	poolConfig.ConnConfig.RuntimeParams["search_path"] = quotedSchema
	poolConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		dropSavedOutboxSchema(adminPool, quotedSchema)
		adminPool.Close()
		t.Fatalf("connect isolated schema: %v", err)
	}

	t.Cleanup(func() {
		pool.Close()
		dropSavedOutboxSchema(adminPool, quotedSchema)
		adminPool.Close()
	})
	if _, err = pool.Exec(ctx, readSavedOutboxMigration(t, "001_saved_core.up.sql")); err != nil {
		t.Fatalf("apply Saved core migration: %v", err)
	}
	repository, err := NewPGSavedOutboxRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedOutboxRepository() error = %v", err)
	}
	return pool, repository
}

func readSavedOutboxMigration(t testing.TB, name string) string {
	t.Helper()
	_, currentFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("resolve saved outbox integration test path")
	}
	path := filepath.Join(filepath.Dir(currentFile), "..", "..", "..", "migrations", name)
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}
	if len(contents) == 0 {
		t.Fatalf("migration %s is empty", name)
	}
	return string(contents)
}

func dropSavedOutboxSchema(adminPool *pgxpool.Pool, quotedSchema string) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	_, _ = adminPool.Exec(ctx, fmt.Sprintf("DROP SCHEMA %s CASCADE", quotedSchema))
}
