package repository

import (
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

const guideRepositoryTestDSNEnv = "GUIDE_SERVICE_REPOSITORY_TEST_DSN"

func TestSavedLifecycleMigrationAndPostgresSemantics(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv(guideRepositoryTestDSNEnv))
	if dsn == "" {
		t.Skip("set " + guideRepositoryTestDSNEnv + " to run PostgreSQL integration tests")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()
	pool, cleanup := newSavedLifecycleTestPool(t, ctx, dsn)
	defer cleanup()
	applyGuideMigrations(t, ctx, pool)
	assertPostgres17(t, ctx, pool)

	repo := NewPGGuideRepository(pool)
	profileID := uuid.New()
	userID := uuid.New()
	now := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	insertGuideFixture(t, ctx, pool, profileID, userID, now)

	initialCount := savedOutboxCount(t, ctx, pool)
	if initialCount != 1 {
		t.Fatalf("initial outbox count = %d, want one payload-free unavailable event", initialCount)
	}
	assertLatestSavedEvent(t, ctx, pool, userID, "UNAVAILABLE", "UNAVAILABLE", true)
	assertSavedEventSemanticsAreImmutable(t, ctx, pool, userID, now)

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin rollback probe: %v", err)
	}
	if _, err = tx.Exec(ctx, `UPDATE guide_profiles SET headline = 'rolled back' WHERE id = $1`, profileID); err != nil {
		t.Fatalf("update rollback probe: %v", err)
	}
	var insideCount int64
	if err = tx.QueryRow(ctx, `SELECT count(*) FROM guide_saved_lifecycle_outbox`).Scan(&insideCount); err != nil {
		t.Fatalf("count outbox inside transaction: %v", err)
	}
	if insideCount != initialCount+1 {
		t.Fatalf("outbox inside transaction = %d, want %d", insideCount, initialCount+1)
	}
	if err = tx.Rollback(ctx); err != nil {
		t.Fatalf("rollback probe: %v", err)
	}
	if got := savedOutboxCount(t, ctx, pool); got != initialCount {
		t.Fatalf("rollback left an event: count = %d, want %d", got, initialCount)
	}

	forceReconcileDue(t, ctx, pool, profileID, now)
	lease := claimSingleReconciliation(t, ctx, repo, now.Add(time.Second))
	avatarID := uuid.New()
	fingerprint := sha256.Sum256([]byte("public-guide-v1"))
	accountUpdatedAt := now.Add(2 * time.Second)
	profileUpdatedAt := now.Add(3 * time.Second)
	if err = repo.ApplySavedGuideExternalUserState(
		ctx,
		lease,
		model.SavedGuideExternalUserState{
			AccountStatus: "ACTIVE", AccountUpdatedAt: accountUpdatedAt,
			ProfileUpdatedAt: &profileUpdatedAt, ProjectionFingerprint: fingerprint[:],
			AvatarFileID: &avatarID, ObservedAt: now.Add(4 * time.Second),
		},
		now.Add(5*time.Minute),
	); err != nil {
		t.Fatalf("apply active user state: %v", err)
	}
	assertLatestSavedEvent(t, ctx, pool, userID, "UNAVAILABLE", "UNAVAILABLE", true)

	verificationID := uuid.New()
	if _, err = pool.Exec(ctx, `
		INSERT INTO guide_verification_requests (
			id, guide_profile_id, status, created_at, updated_at
		) VALUES ($1, $2, 'APPROVED', $3, $3)
	`, verificationID, profileID, now.Add(5*time.Second)); err != nil {
		t.Fatalf("insert approved verification: %v", err)
	}
	if _, err = pool.Exec(ctx, `
		UPDATE guide_profiles SET status = 'ACTIVE', updated_at = $2 WHERE id = $1
	`, profileID, now.Add(6*time.Second)); err != nil {
		t.Fatalf("activate guide: %v", err)
	}
	var stateVisibility, accountStatus, profileStatus, verificationStatus string
	var externalKnown, externalDeleted bool
	if err = pool.QueryRow(ctx, `
		SELECT state.current_visibility, state.external_known,
			state.external_account_status, state.external_is_deleted,
			profile.status,
			(SELECT status FROM guide_verification_requests
			 WHERE guide_profile_id = profile.id
			 ORDER BY created_at DESC, id DESC LIMIT 1)
		FROM guide_saved_lifecycle_state state
		JOIN guide_profiles profile ON profile.id = state.guide_profile_id
		WHERE profile.id = $1
	`, profileID).Scan(
		&stateVisibility,
		&externalKnown,
		&accountStatus,
		&externalDeleted,
		&profileStatus,
		&verificationStatus,
	); err != nil {
		t.Fatalf("read activation lifecycle inputs: %v", err)
	}
	if stateVisibility != "PUBLIC" || !externalKnown || accountStatus != "ACTIVE" ||
		externalDeleted || profileStatus != "ACTIVE" || verificationStatus != "APPROVED" {
		t.Fatalf(
			"activation inputs: state=%s known=%v account=%s deleted=%v profile=%s verification=%s",
			stateVisibility,
			externalKnown,
			accountStatus,
			externalDeleted,
			profileStatus,
			verificationStatus,
		)
	}
	publicEvent := assertLatestSavedEvent(t, ctx, pool, userID, "PUBLISHED", "PUBLIC", true)
	assertMediaState(t, ctx, pool, profileID, true, avatarID, 1)
	var mediaRevisionBeforeTimestampOnly int64
	if err = pool.QueryRow(ctx, `
		SELECT media_reference_revision
		FROM guide_saved_lifecycle_state
		WHERE guide_profile_id = $1
	`, profileID).Scan(&mediaRevisionBeforeTimestampOnly); err != nil {
		t.Fatalf("read media revision before timestamp-only reconcile: %v", err)
	}
	timestampOnlyEventCount := savedOutboxCount(t, ctx, pool)
	forceReconcileDue(t, ctx, pool, profileID, now.Add(6200*time.Millisecond))
	lease = claimSingleReconciliation(t, ctx, repo, now.Add(6300*time.Millisecond))
	accountUpdatedAt = now.Add(6400 * time.Millisecond)
	profileUpdatedAt = now.Add(6500 * time.Millisecond)
	if err = repo.ApplySavedGuideExternalUserState(
		ctx,
		lease,
		model.SavedGuideExternalUserState{
			AccountStatus: "ACTIVE", AccountUpdatedAt: accountUpdatedAt,
			ProfileUpdatedAt: &profileUpdatedAt, ProjectionFingerprint: fingerprint[:],
			AvatarFileID: &avatarID, ObservedAt: now.Add(6600 * time.Millisecond),
		},
		now.Add(5*time.Minute),
	); err != nil {
		t.Fatalf("apply timestamp-only user state: %v", err)
	}
	if got := savedOutboxCount(t, ctx, pool); got != timestampOnlyEventCount {
		t.Fatalf("timestamp-only reconcile emitted an event: count = %d, want %d", got, timestampOnlyEventCount)
	}
	var mediaRevisionAfterTimestampOnly int64
	if err = pool.QueryRow(ctx, `
		SELECT media_reference_revision
		FROM guide_saved_lifecycle_state
		WHERE guide_profile_id = $1
	`, profileID).Scan(&mediaRevisionAfterTimestampOnly); err != nil {
		t.Fatalf("read media revision after timestamp-only reconcile: %v", err)
	}
	if mediaRevisionAfterTimestampOnly != mediaRevisionBeforeTimestampOnly {
		t.Fatalf(
			"timestamp-only reconcile rotated media: before=%d after=%d",
			mediaRevisionBeforeTimestampOnly,
			mediaRevisionAfterTimestampOnly,
		)
	}

	if _, err = pool.Exec(ctx, `
		UPDATE guide_profiles SET headline = 'Updated public guide', updated_at = $2 WHERE id = $1
	`, profileID, now.Add(7*time.Second)); err != nil {
		t.Fatalf("update public projection: %v", err)
	}
	updatedEvent := assertLatestSavedEvent(t, ctx, pool, userID, "UPDATED", "PUBLIC", true)
	if updatedEvent.projectionRevision <= publicEvent.projectionRevision ||
		updatedEvent.visibilityRevision != publicEvent.visibilityRevision {
		t.Fatalf("updated revisions = %+v, published = %+v", updatedEvent, publicEvent)
	}
	var publicMediaRevision int64
	if err = pool.QueryRow(ctx, `
		SELECT media_reference_revision
		FROM guide_saved_lifecycle_state
		WHERE guide_profile_id = $1
	`, profileID).Scan(&publicMediaRevision); err != nil {
		t.Fatalf("read public media revision: %v", err)
	}

	denyTx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin deny transaction: %v", err)
	}
	if _, err = denyTx.Exec(ctx, `
		UPDATE guide_profiles SET status = 'SUSPENDED', updated_at = $2 WHERE id = $1
	`, profileID, now.Add(8*time.Second)); err != nil {
		t.Fatalf("suspend guide: %v", err)
	}
	var mediaActive bool
	var denyMediaRevision int64
	var denyPayload []byte
	if err = denyTx.QueryRow(ctx, `
		SELECT state.media_reference_active, state.media_reference_revision,
			event.public_projection
		FROM guide_saved_lifecycle_state state
		JOIN LATERAL (
			SELECT public_projection
			FROM guide_saved_lifecycle_outbox
			WHERE target_user_id = state.user_id
			ORDER BY created_at DESC, event_id DESC
			LIMIT 1
		) event ON TRUE
		WHERE state.guide_profile_id = $1
	`, profileID).Scan(&mediaActive, &denyMediaRevision, &denyPayload); err != nil {
		t.Fatalf("read atomic deny state: %v", err)
	}
	if mediaActive || denyMediaRevision <= publicMediaRevision || len(denyPayload) != 0 {
		t.Fatalf(
			"deny transaction failed media revoke: active=%v revision=%d previous=%d payload=%x",
			mediaActive,
			denyMediaRevision,
			publicMediaRevision,
			denyPayload,
		)
	}
	if err = denyTx.Commit(ctx); err != nil {
		t.Fatalf("commit deny transaction: %v", err)
	}
	denyEvent := assertLatestSavedEvent(t, ctx, pool, userID, "UNAVAILABLE", "UNAVAILABLE", true)
	if denyEvent.visibilityRevision <= updatedEvent.visibilityRevision {
		t.Fatalf("deny visibility revision = %d, want > %d", denyEvent.visibilityRevision, updatedEvent.visibilityRevision)
	}

	if _, err = pool.Exec(ctx, `UPDATE guide_profiles SET status = 'ACTIVE' WHERE id = $1`, profileID); err != nil {
		t.Fatalf("reactivate guide: %v", err)
	}
	assertLatestSavedEvent(t, ctx, pool, userID, "PUBLISHED", "PUBLIC", true)
	forceReconcileDue(t, ctx, pool, profileID, now.Add(9*time.Second))
	lease = claimSingleReconciliation(t, ctx, repo, now.Add(10*time.Second))
	blockedAt := now.Add(11 * time.Second)
	if err = repo.ApplySavedGuideExternalUserState(
		ctx,
		lease,
		model.SavedGuideExternalUserState{
			AccountStatus: "BLOCKED", AccountUpdatedAt: blockedAt,
			ProfileUpdatedAt: &profileUpdatedAt, ProjectionFingerprint: fingerprint[:],
			AvatarFileID: &avatarID, ObservedAt: blockedAt,
		},
		blockedAt.Add(5*time.Minute),
	); err != nil {
		t.Fatalf("apply blocked user state: %v", err)
	}
	assertLatestSavedEvent(t, ctx, pool, userID, "UNAVAILABLE", "UNAVAILABLE", true)
	assertMediaState(t, ctx, pool, profileID, false, avatarID, 0)

	beforeNotFound := savedOutboxCount(t, ctx, pool)
	notFoundAt := now.Add(12 * time.Second)
	forceReconcileDue(t, ctx, pool, profileID, notFoundAt)
	lease = claimSingleReconciliation(t, ctx, repo, notFoundAt.Add(time.Second))
	if err = repo.ApplySavedGuideExternalUserState(
		ctx,
		lease,
		model.SavedGuideExternalUserState{
			AccountStatus: "DELETED", IsDeleted: true,
			AccountUpdatedAt: notFoundAt, ObservedAt: notFoundAt,
		},
		notFoundAt.Add(time.Minute),
	); err != nil {
		t.Fatalf("apply authoritative user not-found: %v", err)
	}
	if got := savedOutboxCount(t, ctx, pool); got != beforeNotFound+1 {
		t.Fatalf("first user not-found event count = %d, want %d", got, beforeNotFound+1)
	}
	forceReconcileDue(t, ctx, pool, profileID, notFoundAt.Add(2*time.Second))
	lease = claimSingleReconciliation(t, ctx, repo, notFoundAt.Add(3*time.Second))
	if err = repo.ApplySavedGuideExternalUserState(
		ctx,
		lease,
		model.SavedGuideExternalUserState{
			AccountStatus: "DELETED", IsDeleted: true,
			AccountUpdatedAt: notFoundAt.Add(3 * time.Second),
			ObservedAt:       notFoundAt.Add(3 * time.Second),
		},
		notFoundAt.Add(time.Minute),
	); err != nil {
		t.Fatalf("repeat authoritative user not-found: %v", err)
	}
	if got := savedOutboxCount(t, ctx, pool); got != beforeNotFound+1 {
		t.Fatalf("repeat user not-found emitted an event: count = %d", got)
	}

	dispatchProbeAt := time.Now().UTC().Add(time.Second).Truncate(time.Microsecond)
	testConcurrentOutboxClaims(t, ctx, pool, repo, dispatchProbeAt)
	testOutboxRetryDeadAndLeaseRecovery(t, ctx, pool, repo, dispatchProbeAt.Add(time.Minute), userID)
}

func TestSavedLifecycleMigrationRollbackIsGuardedAndReversible(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv(guideRepositoryTestDSNEnv))
	if dsn == "" {
		t.Skip("set " + guideRepositoryTestDSNEnv + " to run PostgreSQL integration tests")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	pool, cleanup := newSavedLifecycleTestPool(t, ctx, dsn)
	defer cleanup()
	applyGuideMigrations(t, ctx, pool)

	insertGuideFixture(t, ctx, pool, uuid.New(), uuid.New(), time.Now().UTC().Truncate(time.Microsecond))
	down := readMigration(t, "000006_saved_lifecycle_outbox.down.sql")
	connection, err := pool.Acquire(ctx)
	if err != nil {
		t.Fatalf("acquire rollback probe connection: %v", err)
	}
	_, err = connection.Exec(ctx, down)
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "55000" {
		connection.Release()
		t.Fatalf("guarded down error = %v, want SQLSTATE 55000", err)
	}
	if _, rollbackErr := connection.Exec(ctx, "ROLLBACK"); rollbackErr != nil {
		connection.Release()
		t.Fatalf("rollback rejected down transaction: %v", rollbackErr)
	}
	connection.Release()
	if _, err = pool.Exec(ctx, `
		UPDATE guide_saved_lifecycle_outbox
		SET status = 'DELIVERED', next_attempt_at = NULL, lease_token = NULL,
			leased_until = NULL, delivered_at = clock_timestamp(),
			retention_expires_at = clock_timestamp() + interval '14 days',
			updated_at = clock_timestamp()
		WHERE status = 'PENDING'
	`); err != nil {
		t.Fatalf("drain outbox for rollback: %v", err)
	}
	if _, err = pool.Exec(ctx, down); err != nil {
		t.Fatalf("compatible Saved lifecycle down failed: %v", err)
	}
	var profileTable string
	if err = pool.QueryRow(ctx, `SELECT to_regclass('guide_profiles')::TEXT`).Scan(&profileTable); err != nil {
		t.Fatalf("verify core guide schema after down: %v", err)
	}
	if profileTable != "guide_profiles" {
		t.Fatalf("guide_profiles missing after Saved lifecycle down: %q", profileTable)
	}
}

type savedEventProbe struct {
	sourceRevision     int64
	projectionRevision int64
	visibilityRevision int64
}

func assertLatestSavedEvent(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	wantKind string,
	wantVisibility string,
	wantPayloadFree bool,
) savedEventProbe {
	t.Helper()
	var (
		kind, visibility string
		payload          []byte
		probe            savedEventProbe
		eventID          uuid.UUID
		occurredAt       time.Time
	)
	err := pool.QueryRow(ctx, `
		SELECT event_id, event_kind, visibility, source_revision,
			projection_revision, visibility_revision, occurred_at, public_projection
		FROM guide_saved_lifecycle_outbox
		WHERE target_user_id = $1
		ORDER BY created_at DESC, event_id DESC
		LIMIT 1
	`, userID).Scan(
		&eventID,
		&kind,
		&visibility,
		&probe.sourceRevision,
		&probe.projectionRevision,
		&probe.visibilityRevision,
		&occurredAt,
		&payload,
	)
	if err != nil {
		t.Fatalf("read latest Saved lifecycle event: %v", err)
	}
	if eventID == uuid.Nil || occurredAt.IsZero() || kind != wantKind || visibility != wantVisibility ||
		probe.sourceRevision <= 0 || probe.projectionRevision <= 0 || probe.visibilityRevision <= 0 {
		t.Fatalf("latest event = id=%s kind=%s visibility=%s revisions=%+v at=%s", eventID, kind, visibility, probe, occurredAt)
	}
	if wantPayloadFree && len(payload) != 0 {
		t.Fatalf("event %s leaked projection payload: %x", eventID, payload)
	}
	return probe
}

func assertSavedEventSemanticsAreImmutable(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
	now time.Time,
) {
	t.Helper()
	_, err := pool.Exec(ctx, `
		UPDATE guide_saved_lifecycle_outbox
		SET visibility_revision = visibility_revision + 1
		WHERE target_user_id = $1
	`, userID)
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23514" {
		t.Fatalf("semantic mutation error = %v, want SQLSTATE 23514", err)
	}

	_, err = pool.Exec(ctx, `
		INSERT INTO guide_saved_lifecycle_outbox (
			event_id, event_kind, target_user_id, source_revision,
			projection_revision, visibility_revision, occurred_at, visibility,
			public_projection, status, attempt_count, max_attempts,
			next_attempt_at, created_at, updated_at
		) VALUES ($1, 'UNAVAILABLE', $2, 1, 1, 1, $3, 'UNAVAILABLE',
			decode('01', 'hex'), 'PENDING', 0, 12, $3, $3, $3)
	`, uuid.New(), userID, now)
	pgErr = nil
	if !errors.As(err, &pgErr) || pgErr.Code != "23514" {
		t.Fatalf("deny payload error = %v, want SQLSTATE 23514", err)
	}
}

func assertMediaState(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	profileID uuid.UUID,
	wantActive bool,
	wantAvatar uuid.UUID,
	minimumRevision int64,
) {
	t.Helper()
	var active bool
	var avatarID *uuid.UUID
	var revision int64
	if err := pool.QueryRow(ctx, `
		SELECT media_reference_active, external_avatar_file_id, media_reference_revision
		FROM guide_saved_lifecycle_state WHERE guide_profile_id = $1
	`, profileID).Scan(&active, &avatarID, &revision); err != nil {
		t.Fatalf("read Saved media state: %v", err)
	}
	if active != wantActive || avatarID == nil || *avatarID != wantAvatar || revision < minimumRevision {
		t.Fatalf("media state = active=%v avatar=%v revision=%d", active, avatarID, revision)
	}
}

func testConcurrentOutboxClaims(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	repo *PGGuideRepository,
	now time.Time,
) {
	t.Helper()
	if _, err := pool.Exec(ctx, `
		UPDATE guide_saved_lifecycle_outbox
		SET status = 'DELIVERED', next_attempt_at = NULL, lease_token = NULL,
			leased_until = NULL, delivered_at = $1,
			retention_expires_at = $1::TIMESTAMPTZ + interval '14 days', updated_at = $1
		WHERE status = 'PENDING'
	`, now); err != nil {
		t.Fatalf("close existing outbox before concurrency probe: %v", err)
	}
	for index := range 20 {
		createdAt := now.Add(time.Duration(index) * time.Microsecond)
		if _, err := pool.Exec(ctx, `
			INSERT INTO guide_saved_lifecycle_outbox (
				event_id, event_kind, target_user_id, source_revision,
				projection_revision, visibility_revision, occurred_at, visibility,
				status, attempt_count, max_attempts, next_attempt_at, created_at, updated_at
			) VALUES ($1, 'UPDATED', $2, $3, $3, $3, $4, 'PUBLIC',
				'PENDING', 0, 12, $4, $4, $4)
		`, uuid.New(), uuid.New(), int64(index+1), createdAt); err != nil {
			t.Fatalf("insert concurrent outbox fixture: %v", err)
		}
	}

	start := make(chan struct{})
	results := make(chan []*model.SavedLifecycleOutboxMessage, 2)
	errorsCh := make(chan error, 2)
	var wait sync.WaitGroup
	for range 2 {
		wait.Add(1)
		go func() {
			defer wait.Done()
			<-start
			items, err := repo.ClaimSavedLifecycleOutbox(ctx, now.Add(time.Second), 10, 30*time.Second)
			if err != nil {
				errorsCh <- err
				return
			}
			results <- items
		}()
	}
	close(start)
	wait.Wait()
	close(results)
	close(errorsCh)
	for err := range errorsCh {
		t.Fatalf("concurrent claim failed: %v", err)
	}
	seen := make(map[uuid.UUID]struct{}, 20)
	for items := range results {
		for _, item := range items {
			if _, duplicate := seen[item.EventID]; duplicate {
				t.Fatalf("event %s was claimed concurrently", item.EventID)
			}
			seen[item.EventID] = struct{}{}
		}
	}
	if len(seen) != 20 {
		t.Fatalf("concurrent claims returned %d events, want 20", len(seen))
	}
}

func testOutboxRetryDeadAndLeaseRecovery(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	repo *PGGuideRepository,
	now time.Time,
	userID uuid.UUID,
) {
	t.Helper()
	if _, err := pool.Exec(ctx, `
		UPDATE guide_saved_lifecycle_outbox
		SET status = 'DELIVERED', next_attempt_at = NULL, lease_token = NULL,
			leased_until = NULL, delivered_at = $1,
			retention_expires_at = $1::TIMESTAMPTZ + interval '14 days', updated_at = $1
		WHERE status IN ('PENDING', 'PROCESSING')
	`, now); err != nil {
		t.Fatalf("close outbox before recovery probe: %v", err)
	}
	eventID := uuid.New()
	if _, err := pool.Exec(ctx, `
		INSERT INTO guide_saved_lifecycle_outbox (
			event_id, event_kind, target_user_id, source_revision,
			projection_revision, visibility_revision, occurred_at, visibility,
			status, attempt_count, max_attempts, next_attempt_at, created_at, updated_at
		) VALUES ($1, 'UNAVAILABLE', $2, 1, 1, 1, $3, 'UNAVAILABLE',
			'PENDING', 0, 2, $3, $3, $3)
	`, eventID, userID, now); err != nil {
		t.Fatalf("insert recovery event: %v", err)
	}
	first, err := repo.ClaimSavedLifecycleOutbox(ctx, now.Add(time.Second), 1, 5*time.Second)
	if err != nil || len(first) != 1 {
		t.Fatalf("first recovery claim = %v, %v", first, err)
	}
	second, err := repo.ClaimSavedLifecycleOutbox(ctx, now.Add(7*time.Second), 1, 5*time.Second)
	if err != nil || len(second) != 1 {
		t.Fatalf("lease recovery claim = %v, %v", second, err)
	}
	if second[0].EventID != eventID || second[0].AttemptCount != first[0].AttemptCount ||
		second[0].LeaseToken == first[0].LeaseToken {
		t.Fatalf("lease recovery changed semantics/attempt: first=%+v second=%+v", first[0], second[0])
	}
	retryAt := now.Add(10 * time.Second)
	if err = repo.MarkSavedLifecycleFailed(
		ctx, eventID, second[0].LeaseToken, now.Add(8*time.Second), retryAt,
		"NATS_PUBLISH_FAILED", false, 0,
	); err != nil {
		t.Fatalf("schedule retry: %v", err)
	}
	third, err := repo.ClaimSavedLifecycleOutbox(ctx, retryAt, 1, 5*time.Second)
	if err != nil || len(third) != 1 || third[0].AttemptCount != 2 {
		t.Fatalf("retry claim = %+v, %v", third, err)
	}
	if err = repo.MarkSavedLifecycleFailed(
		ctx, eventID, third[0].LeaseToken, retryAt.Add(time.Second), time.Time{},
		"NATS_PUBLISH_FAILED", true, 90*24*time.Hour,
	); err != nil {
		t.Fatalf("mark event dead: %v", err)
	}
	var status string
	var payload []byte
	if err = pool.QueryRow(ctx, `
		SELECT status, public_projection FROM guide_saved_lifecycle_outbox WHERE event_id = $1
	`, eventID).Scan(&status, &payload); err != nil {
		t.Fatalf("read dead event: %v", err)
	}
	if status != "DEAD" || len(payload) != 0 {
		t.Fatalf("dead event status/payload = %s/%x", status, payload)
	}
	cleanupEventID := uuid.New()
	cleanupCreatedAt := time.Now().UTC().Add(-2 * time.Hour).Truncate(time.Microsecond)
	cleanupDeliveredAt := cleanupCreatedAt.Add(time.Hour)
	cleanupExpiresAt := time.Now().UTC().Add(-time.Second).Truncate(time.Microsecond)
	if _, err = pool.Exec(ctx, `
		INSERT INTO guide_saved_lifecycle_outbox (
			event_id, event_kind, target_user_id, source_revision,
			projection_revision, visibility_revision, occurred_at, visibility,
			status, attempt_count, max_attempts, next_attempt_at,
			delivered_at, retention_expires_at, created_at, updated_at
		) VALUES ($1, 'UNAVAILABLE', $2, 1, 1, 1, $3, 'UNAVAILABLE',
			'DELIVERED', 1, 2, NULL, $4, $5, $3, $4)
	`, cleanupEventID, userID, cleanupCreatedAt, cleanupDeliveredAt, cleanupExpiresAt); err != nil {
		t.Fatalf("insert retention cleanup fixture: %v", err)
	}
	deleted, err := repo.DeleteSavedLifecycleTerminal(ctx, time.Now().UTC(), 200)
	if err != nil || deleted < 1 {
		t.Fatalf("terminal retention cleanup = %d, %v", deleted, err)
	}
	var exists bool
	if err = pool.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM guide_saved_lifecycle_outbox WHERE event_id = $1)
	`, cleanupEventID).Scan(&exists); err != nil {
		t.Fatalf("verify terminal cleanup: %v", err)
	}
	if exists {
		t.Fatal("retention cleanup left the expired terminal event")
	}
}

func insertGuideFixture(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	profileID uuid.UUID,
	userID uuid.UUID,
	now time.Time,
) {
	t.Helper()
	if _, err := pool.Exec(ctx, `
		INSERT INTO guide_profiles (
			id, user_id, type, status, headline, experience_years,
			is_private_guide_available, is_activity_host_available,
			is_excursion_guide_available, rating_avg, reviews_count,
			created_at, updated_at
		) VALUES ($1, $2, 'INDEPENDENT', 'DRAFT', 'Initial guide', 1,
			FALSE, FALSE, FALSE, 0, 0, $3, $3)
	`, profileID, userID, now); err != nil {
		t.Fatalf("insert guide fixture: %v", err)
	}
}

func forceReconcileDue(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	profileID uuid.UUID,
	now time.Time,
) {
	t.Helper()
	if _, err := pool.Exec(ctx, `
		UPDATE guide_saved_lifecycle_state
		SET next_reconcile_at = $2, reconcile_lease_token = NULL,
			reconcile_leased_until = NULL, updated_at = $2
		WHERE guide_profile_id = $1
	`, profileID, now); err != nil {
		t.Fatalf("force reconciliation due: %v", err)
	}
}

func claimSingleReconciliation(
	t *testing.T,
	ctx context.Context,
	repo *PGGuideRepository,
	now time.Time,
) model.SavedGuideUserReconcileLease {
	t.Helper()
	items, err := repo.ClaimSavedGuideUserReconciliations(ctx, now, 1, 15*time.Second)
	if err != nil || len(items) != 1 {
		t.Fatalf("claim reconciliation = %+v, %v", items, err)
	}
	return *items[0]
}

func savedOutboxCount(t *testing.T, ctx context.Context, pool *pgxpool.Pool) int64 {
	t.Helper()
	var count int64
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM guide_saved_lifecycle_outbox`).Scan(&count); err != nil {
		t.Fatalf("count Saved lifecycle outbox: %v", err)
	}
	return count
}

func assertPostgres17(t *testing.T, ctx context.Context, pool *pgxpool.Pool) {
	t.Helper()
	var raw string
	if err := pool.QueryRow(ctx, `SHOW server_version_num`).Scan(&raw); err != nil {
		t.Fatalf("read PostgreSQL version: %v", err)
	}
	version, err := strconv.Atoi(raw)
	if err != nil || version < 170000 || version >= 180000 {
		t.Fatalf("PostgreSQL version = %q, want 17.x", raw)
	}
}

func applyGuideMigrations(t *testing.T, ctx context.Context, pool *pgxpool.Pool) {
	t.Helper()
	files, err := filepath.Glob("../../../migrations/*.up.sql")
	if err != nil {
		t.Fatalf("glob guide migrations: %v", err)
	}
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

func readMigration(t *testing.T, name string) string {
	t.Helper()
	content, err := os.ReadFile(filepath.Join("../../../migrations", name))
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}
	return string(content)
}

func newSavedLifecycleTestPool(
	t *testing.T,
	ctx context.Context,
	dsn string,
) (*pgxpool.Pool, func()) {
	t.Helper()
	adminConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		t.Fatalf("parse PostgreSQL test DSN: %v", err)
	}
	adminConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	adminPool, err := pgxpool.NewWithConfig(ctx, adminConfig)
	if err != nil {
		t.Fatalf("connect PostgreSQL test admin pool: %v", err)
	}
	schema := "guide_saved_lifecycle_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	if _, err = adminPool.Exec(ctx, "CREATE SCHEMA "+pgx.Identifier{schema}.Sanitize()); err != nil {
		adminPool.Close()
		t.Fatalf("create PostgreSQL test schema: %v", err)
	}

	testConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		adminPool.Close()
		t.Fatalf("parse PostgreSQL test pool config: %v", err)
	}
	testConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	testConfig.ConnConfig.RuntimeParams["search_path"] = fmt.Sprintf("%s,public", schema)
	pool, err := pgxpool.NewWithConfig(ctx, testConfig)
	if err != nil {
		adminPool.Close()
		t.Fatalf("connect PostgreSQL test pool: %v", err)
	}
	return pool, func() {
		pool.Close()
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		_, _ = adminPool.Exec(cleanupCtx, "DROP SCHEMA "+pgx.Identifier{schema}.Sanitize()+" CASCADE")
		adminPool.Close()
	}
}
