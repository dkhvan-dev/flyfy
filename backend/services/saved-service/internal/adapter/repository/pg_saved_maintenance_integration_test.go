package repository

import (
	"bytes"
	"context"
	"encoding/base64"
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
	"github.com/jackc/pgx/v5/pgxpool"

	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
)

const savedMaintenanceIntegrationDSNEnv = "SAVED_SERVICE_REPOSITORY_TEST_DSN"

func TestPGSavedMaintenanceOperationExpiryConcurrencyAndRecovery(t *testing.T) {
	pool, repository := openSavedMaintenanceIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.NewString()

	type operationExpectation struct {
		id    uuid.UUID
		scope string
	}
	expired := []operationExpectation{
		{insertMaintenancePendingOperation(t, pool, subject, "SAVE_TARGET", now.Add(-12*time.Second), now.Add(-2*time.Second), 1), "SAVED_ITEMS"},
		{insertMaintenancePendingOperation(t, pool, subject, "UNSAVE_TARGET", now.Add(-12*time.Second), now.Add(-2*time.Second), 2), "BOTH"},
		{insertMaintenancePendingOperation(t, pool, subject, "CREATE_COLLECTION", now.Add(-12*time.Second), now.Add(-2*time.Second), 3), "COLLECTIONS"},
	}
	futureID := insertMaintenancePendingOperation(
		t,
		pool,
		subject,
		"SAVE_TARGET",
		now,
		now.Add(10*time.Second),
		4,
	)

	request := maintenanceBatch(now, 2)
	start := make(chan struct{})
	results := make(chan savedmaintenance.BatchResult, 2)
	errorsChannel := make(chan error, 2)
	var ready sync.WaitGroup
	ready.Add(2)
	for range 2 {
		go func() {
			ready.Done()
			<-start
			result, err := repository.ExpirePendingOperations(context.Background(), request)
			results <- result
			errorsChannel <- err
		}()
	}
	ready.Wait()
	close(start)

	var affected int64
	for range 2 {
		if err := <-errorsChannel; err != nil {
			t.Fatalf("ExpirePendingOperations() error = %v", err)
		}
		affected += (<-results).Affected
	}
	if affected != 3 {
		t.Fatalf("concurrent expiry affected = %d, want 3", affected)
	}
	for _, expectation := range expired {
		var status, scope, outcome string
		var retryable bool
		var completedAt, retentionExpiresAt time.Time
		if err := pool.QueryRow(
			context.Background(),
			`SELECT status, refresh_scope, outcome_code, outcome_retryable, completed_at, retention_expires_at
             FROM saved_operations WHERE operation_id = $1`,
			expectation.id,
		).Scan(&status, &scope, &outcome, &retryable, &completedAt, &retentionExpiresAt); err != nil {
			t.Fatalf("read expired operation: %v", err)
		}
		if status != "EXPIRED" || scope != expectation.scope || outcome != "EXPIRED" || retryable ||
			!retentionExpiresAt.Equal(completedAt.Add(savedmaintenance.DefaultOperationRetention)) {
			t.Fatalf("expired operation = (%s, %s, %s, %t, %s, %s)",
				status, scope, outcome, retryable, completedAt, retentionExpiresAt)
		}
	}
	var futureStatus string
	if err := pool.QueryRow(
		context.Background(),
		"SELECT status FROM saved_operations WHERE operation_id = $1",
		futureID,
	).Scan(&futureStatus); err != nil {
		t.Fatalf("read future operation: %v", err)
	}
	if futureStatus != "PENDING" {
		t.Fatalf("future operation status = %s", futureStatus)
	}

	replay, err := repository.ExpirePendingOperations(context.Background(), maintenanceBatch(now, 100))
	if err != nil || replay.Affected != 0 {
		t.Fatalf("replayed expiry = (%+v, %v), want zero", replay, err)
	}

	lockedID := insertMaintenancePendingOperation(
		t,
		pool,
		subject,
		"DELETE_COLLECTION",
		now.Add(-12*time.Second),
		now.Add(-time.Second),
		5,
	)
	lockTx, err := pool.Begin(context.Background())
	if err != nil {
		t.Fatalf("begin lock transaction: %v", err)
	}
	if _, err := lockTx.Exec(
		context.Background(),
		"SELECT operation_id FROM saved_operations WHERE operation_id = $1 FOR UPDATE",
		lockedID,
	); err != nil {
		_ = lockTx.Rollback(context.Background())
		t.Fatalf("lock pending operation: %v", err)
	}
	skipped, err := repository.ExpirePendingOperations(context.Background(), maintenanceBatch(now, 100))
	if err != nil || skipped.Affected != 0 {
		_ = lockTx.Rollback(context.Background())
		t.Fatalf("locked expiry = (%+v, %v), want SKIP LOCKED", skipped, err)
	}
	if err := lockTx.Rollback(context.Background()); err != nil {
		t.Fatalf("rollback lock transaction: %v", err)
	}
	recovered, err := repository.ExpirePendingOperations(context.Background(), maintenanceBatch(now, 100))
	if err != nil || recovered.Affected != 1 {
		t.Fatalf("recovered expiry = (%+v, %v), want one", recovered, err)
	}

	purgeNow := now.Add(savedmaintenance.DefaultOperationRetention + time.Second)
	var purged int64
	for {
		result, err := repository.PurgeTerminalOperations(
			context.Background(),
			maintenanceBatch(purgeNow, 2),
		)
		if err != nil {
			t.Fatalf("PurgeTerminalOperations() error = %v", err)
		}
		if result.Affected > 2 {
			t.Fatalf("terminal purge exceeded bound: %+v", result)
		}
		purged += result.Affected
		if result.Affected < 2 {
			break
		}
	}
	if purged != 4 {
		t.Fatalf("terminal operations purged = %d, want 4", purged)
	}
}

func TestPGSavedMaintenanceRetentionFKOrderAndProjectionGC(t *testing.T) {
	pool, repository := openSavedMaintenanceIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	owner := uuid.New()
	processedAt := now.Add(-15 * 24 * time.Hour)
	if _, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_inbox_dedup (
             source_service, event_id, event_type, processing_state,
             processed_at, retention_expires_at, subject, schema_version,
             target_entity_type, envelope_fingerprint, source_revision,
             projection_revision, visibility_revision, source_applied,
             projection_applied, visibility_applied
         ) VALUES (
             'activity-service', $1, 'content.deleted', 'IGNORED_UNKNOWN_TARGET',
             $2, $3, 'saved.source.activity.lifecycle.v1', 1, 'ACTIVITY', $4,
             1, 1, 1, FALSE, FALSE, FALSE
         )`,
		uuid.New(),
		processedAt,
		processedAt.Add(14*24*time.Hour),
		bytes.Repeat([]byte{0x44}, 32),
	); err != nil {
		t.Fatalf("insert lifecycle inbox retention row: %v", err)
	}
	inboxResult, err := repository.PurgeInboxDedup(context.Background(), maintenanceBatch(now, 1))
	requireNoMaintenanceError(t, "purge lifecycle inbox", inboxResult, err)
	if inboxResult.Affected != 1 {
		t.Fatalf("lifecycle inbox purge = %+v", inboxResult)
	}

	insertMaintenanceProjection(t, pool, "removed-target", true, nil, nil, now.Add(-30*24*time.Hour))
	removedItem := insertMaintenanceSavedItem(
		t,
		pool,
		owner,
		"removed-target",
		"REMOVED",
		now.Add(-30*24*time.Hour),
		now.Add(-15*24*time.Hour),
	)
	activeCollection := insertMaintenanceCollection(t, pool, owner, false, now)
	insertMaintenanceMembership(
		t,
		pool,
		owner,
		activeCollection,
		removedItem.id,
		"REMOVED",
		now.Add(-15*24*time.Hour),
	)
	insertMaintenanceOutbox(t, pool, owner, removedItem, now.Add(-15*24*time.Hour))

	blockedItem, err := repository.PurgeRemovedSavedItems(context.Background(), maintenanceBatch(now, 10))
	requireNoMaintenanceError(t, "purge blocked saved item", blockedItem, err)
	if blockedItem.Affected != 0 {
		t.Fatalf("saved item purged before children/outbox: %+v", blockedItem)
	}
	blockedProjection, err := repository.MarkProjectionGCCandidates(
		context.Background(),
		maintenanceBatch(now, 10),
	)
	requireNoMaintenanceError(t, "mark relationship-blocked projection", blockedProjection, err)
	if blockedProjection.Affected != 0 {
		t.Fatalf("projection marked while REMOVED relationship exists: %+v", blockedProjection)
	}

	result, err := repository.PurgeRemovedCollectionItems(context.Background(), maintenanceBatch(now, 1))
	requireNoMaintenanceError(t, "purge removed membership", result, err)
	if result.Affected != 1 {
		t.Fatalf("removed membership purge = %+v", result)
	}
	result, err = repository.PurgeTerminalOutbox(context.Background(), maintenanceBatch(now, 1))
	requireNoMaintenanceError(t, "purge terminal outbox", result, err)
	if result.Affected != 1 {
		t.Fatalf("terminal outbox purge = %+v", result)
	}
	result, err = repository.PurgeRemovedSavedItems(context.Background(), maintenanceBatch(now, 1))
	requireNoMaintenanceError(t, "purge removed saved item", result, err)
	if result.Affected != 1 {
		t.Fatalf("removed saved item purge = %+v", result)
	}
	if count := countMaintenanceRows(t, pool, "saved_items", "owner_user_id = $1", owner); count != 0 {
		t.Fatalf("removed saved items remaining = %d", count)
	}

	insertMaintenanceProjection(t, pool, "collection-child-a", true, nil, nil, now.Add(-30*24*time.Hour))
	insertMaintenanceProjection(t, pool, "collection-child-b", true, nil, nil, now.Add(-30*24*time.Hour))
	childA := insertMaintenanceSavedItem(t, pool, owner, "collection-child-a", "ACTIVE", now.Add(-20*24*time.Hour), time.Time{})
	childB := insertMaintenanceSavedItem(t, pool, owner, "collection-child-b", "ACTIVE", now.Add(-20*24*time.Hour), time.Time{})
	deletedCollection := insertMaintenanceCollection(t, pool, owner, true, now.Add(-15*24*time.Hour))
	insertMaintenanceMembership(t, pool, owner, deletedCollection, childA.id, "ACTIVE", time.Time{})
	insertMaintenanceMembership(t, pool, owner, deletedCollection, childB.id, "REMOVED", now.Add(-2*24*time.Hour))
	insertMaintenanceTerminalCollectionOperation(t, pool, owner.String(), deletedCollection, now.Add(-15*24*time.Hour), 90)

	for child := 0; child < 2; child++ {
		result, err = repository.CleanupDeletedCollectionChildren(
			context.Background(),
			maintenanceBatch(now, 1),
		)
		requireNoMaintenanceError(t, "cleanup deleted collection child", result, err)
		if result.Affected != 1 {
			t.Fatalf("deleted collection child cleanup = %+v", result)
		}
	}
	if count := countMaintenanceRows(t, pool, "saved_collection_items", "collection_id = $1", deletedCollection); count != 0 {
		t.Fatalf("deleted collection children remaining = %d", count)
	}
	blockedCollection, err := repository.PurgeDeletedCollections(
		context.Background(),
		maintenanceBatch(now, 10),
	)
	requireNoMaintenanceError(t, "purge operation-blocked collection", blockedCollection, err)
	if blockedCollection.Affected != 0 {
		t.Fatalf("collection purged with retained operation dependency: %+v", blockedCollection)
	}
	result, err = repository.PurgeTerminalOperations(context.Background(), maintenanceBatch(now, 10))
	requireNoMaintenanceError(t, "purge collection operation dependency", result, err)
	if result.Affected != 1 {
		t.Fatalf("collection operation purge = %+v", result)
	}
	result, err = repository.PurgeDeletedCollections(context.Background(), maintenanceBatch(now, 10))
	requireNoMaintenanceError(t, "purge deleted collection", result, err)
	if result.Affected != 1 {
		t.Fatalf("deleted collection purge = %+v", result)
	}

	result, err = repository.MarkProjectionGCCandidates(context.Background(), maintenanceBatch(now, 10))
	requireNoMaintenanceError(t, "mark projection candidate", result, err)
	if result.Affected != 1 {
		t.Fatalf("projection candidates marked = %+v, want removed-target only", result)
	}
	var candidateAt time.Time
	if err := pool.QueryRow(
		context.Background(),
		"SELECT gc_candidate_at FROM saved_content_projections WHERE entity_id = 'removed-target'",
	).Scan(&candidateAt); err != nil {
		t.Fatalf("read projection candidate: %v", err)
	}
	if !candidateAt.Equal(now) {
		t.Fatalf("gc_candidate_at = %s, want %s", candidateAt, now)
	}

	insertMaintenanceProjection(
		t,
		pool,
		"expired-shell",
		false,
		timePointer(now.Add(-time.Minute)),
		nil,
		now.Add(-30*time.Minute),
	)
	insertMaintenanceProjection(
		t,
		pool,
		"future-shell",
		false,
		timePointer(now.Add(10*time.Minute)),
		nil,
		now.Add(-time.Minute),
	)
	result, err = repository.PurgeEphemeralProjections(context.Background(), maintenanceBatch(now, 10))
	requireNoMaintenanceError(t, "purge expired shell", result, err)
	if result.Affected != 1 || countMaintenanceRows(
		t,
		pool,
		"saved_content_projections",
		"entity_id = 'future-shell'",
	) != 1 {
		t.Fatalf("ephemeral purge = %+v", result)
	}

	standardPurgeAt := now.Add(savedmaintenance.DefaultProjectionRetention + time.Second)
	result, err = repository.PurgeStandardProjections(
		context.Background(),
		maintenanceBatch(standardPurgeAt, 10),
	)
	requireNoMaintenanceError(t, "purge standard projection", result, err)
	if result.Affected != 1 {
		t.Fatalf("standard projection purge = %+v", result)
	}
	for _, retained := range []string{"collection-child-a", "collection-child-b", "future-shell"} {
		if count := countMaintenanceRows(
			t,
			pool,
			"saved_content_projections",
			"entity_id = $1",
			retained,
		); count != 1 {
			t.Fatalf("retained projection %s count = %d", retained, count)
		}
	}
}

func TestPGSavedMaintenanceProjectionGCSkipsLockedRows(t *testing.T) {
	pool, repository := openSavedMaintenanceIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	insertMaintenanceProjection(
		t,
		pool,
		"locked-shell",
		false,
		timePointer(now.Add(-time.Minute)),
		nil,
		now.Add(-30*time.Minute),
	)

	tx, err := pool.Begin(context.Background())
	if err != nil {
		t.Fatalf("begin projection lock: %v", err)
	}
	if _, err := tx.Exec(
		context.Background(),
		"SELECT entity_id FROM saved_content_projections WHERE entity_id = 'locked-shell' FOR UPDATE",
	); err != nil {
		_ = tx.Rollback(context.Background())
		t.Fatalf("lock projection: %v", err)
	}
	result, err := repository.PurgeEphemeralProjections(context.Background(), maintenanceBatch(now, 10))
	requireNoMaintenanceError(t, "purge locked projection", result, err)
	if result.Affected != 0 {
		_ = tx.Rollback(context.Background())
		t.Fatalf("locked projection purge = %+v", result)
	}
	if err := tx.Rollback(context.Background()); err != nil {
		t.Fatalf("rollback projection lock: %v", err)
	}
	result, err = repository.PurgeEphemeralProjections(context.Background(), maintenanceBatch(now, 10))
	requireNoMaintenanceError(t, "recover projection purge", result, err)
	if result.Affected != 1 {
		t.Fatalf("recovered projection purge = %+v", result)
	}
}

func TestPGSavedMaintenanceSubjectPurgeResumesAfterInterruption(t *testing.T) {
	pool, repository := openSavedMaintenanceIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	owner := uuid.New()
	subject := owner.String()

	insertMaintenanceProjection(t, pool, "subject-target-a", true, nil, nil, now.Add(-10*24*time.Hour))
	insertMaintenanceProjection(t, pool, "subject-target-b", true, nil, nil, now.Add(-10*24*time.Hour))
	itemA := insertMaintenanceSavedItem(t, pool, owner, "subject-target-a", "ACTIVE", now.Add(-9*24*time.Hour), time.Time{})
	itemB := insertMaintenanceSavedItem(t, pool, owner, "subject-target-b", "ACTIVE", now.Add(-8*24*time.Hour), time.Time{})
	collectionID := insertMaintenanceCollection(t, pool, owner, false, now)
	insertMaintenanceMembership(t, pool, owner, collectionID, itemA.id, "ACTIVE", time.Time{})
	insertMaintenanceMembership(t, pool, owner, collectionID, itemB.id, "ACTIVE", time.Time{})
	insertMaintenanceOutbox(t, pool, owner, itemA, now)
	insertMaintenanceOutbox(t, pool, owner, itemB, now)
	insertMaintenancePendingOperation(t, pool, subject, "SAVE_TARGET", now, now.Add(10*time.Second), 61)
	insertMaintenancePendingOperation(t, pool, subject, "UNSAVE_TARGET", now, now.Add(10*time.Second), 62)
	if _, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_user_usage (owner_user_id, active_saved_items_count, usage_version)
         VALUES ($1, 2, 1)`,
		owner,
	); err != nil {
		t.Fatalf("insert user usage: %v", err)
	}
	if _, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_collection_usage (
             owner_user_id, active_collections_count, active_memberships_count, usage_version
         ) VALUES ($1, 1, 2, 1)`,
		owner,
	); err != nil {
		t.Fatalf("insert collection usage: %v", err)
	}
	otherOwner := uuid.New()
	if _, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_user_usage (owner_user_id, active_saved_items_count, usage_version)
         VALUES ($1, 0, 0)`,
		otherOwner,
	); err != nil {
		t.Fatalf("insert other-owner usage: %v", err)
	}

	startRequest := savedmaintenance.SubjectPurgeStart{
		OperationID:  uuid.New(),
		Subject:      subject,
		OwnerUserID:  owner,
		WritesFenced: true,
	}
	const starters = 8
	startGate := make(chan struct{})
	jobs := make(chan savedmaintenance.SubjectPurgeJob, starters)
	errorsChannel := make(chan error, starters)
	var ready sync.WaitGroup
	ready.Add(starters)
	for range starters {
		go func() {
			ready.Done()
			<-startGate
			job, err := repository.StartSubjectPurge(context.Background(), startRequest, now)
			jobs <- job
			errorsChannel <- err
		}()
	}
	ready.Wait()
	close(startGate)
	for range starters {
		if err := <-errorsChannel; err != nil {
			t.Fatalf("concurrent StartSubjectPurge() error = %v", err)
		}
		job := <-jobs
		if job.OperationID != startRequest.OperationID || job.Phase != savedmaintenance.SubjectPurgePhaseOutbox {
			t.Fatalf("concurrent subject purge job = %+v", job)
		}
	}
	if count := countMaintenanceRows(t, pool, "saved_subject_purge_operations", "subject = $1", subject); count != 1 {
		t.Fatalf("subject purge jobs = %d, want 1", count)
	}

	clash := startRequest
	clash.OperationID = uuid.New()
	if _, err := repository.StartSubjectPurge(context.Background(), clash, now); err == nil ||
		savedmaintenance.IsRetryable(err) {
		t.Fatalf("identity clash error = %v, want non-retryable", err)
	}

	operationID := startRequest.OperationID
	checkpointLock, err := pool.Begin(context.Background())
	if err != nil {
		t.Fatalf("begin checkpoint lock: %v", err)
	}
	if _, err := checkpointLock.Exec(
		context.Background(),
		"SELECT operation_id FROM saved_subject_purge_operations WHERE operation_id = $1 FOR UPDATE",
		operationID,
	); err != nil {
		_ = checkpointLock.Rollback(context.Background())
		t.Fatalf("lock subject purge checkpoint: %v", err)
	}
	_, lockedErr := repository.ProcessSubjectPurge(context.Background(), savedmaintenance.SubjectPurgeBatchRequest{
		Batch:       maintenanceBatch(now, 1),
		OperationID: &operationID,
	})
	if !savedmaintenance.IsRetryable(lockedErr) {
		_ = checkpointLock.Rollback(context.Background())
		t.Fatalf("locked ProcessSubjectPurge() error = %v, want retryable contention", lockedErr)
	}
	if err := checkpointLock.Rollback(context.Background()); err != nil {
		t.Fatalf("rollback checkpoint lock: %v", err)
	}

	first, err := repository.ProcessSubjectPurge(context.Background(), savedmaintenance.SubjectPurgeBatchRequest{
		Batch:       maintenanceBatch(now, 1),
		OperationID: &operationID,
	})
	if err != nil {
		t.Fatalf("first ProcessSubjectPurge() error = %v", err)
	}
	if first.RowsPurged != 1 || first.PhaseBefore != savedmaintenance.SubjectPurgePhaseOutbox ||
		first.PhaseAdvanced {
		t.Fatalf("first subject purge batch = %+v", first)
	}

	// A new repository instance represents process recovery; the durable phase
	// and remaining rows are the only checkpoint needed.
	recoveredRepository, err := NewPGSavedMaintenanceRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedMaintenanceRepository(recovered) error = %v", err)
	}
	completed := false
	for batch := 0; batch < 64; batch++ {
		result, err := recoveredRepository.ProcessSubjectPurge(
			context.Background(),
			savedmaintenance.SubjectPurgeBatchRequest{
				Batch:       maintenanceBatch(now, 1),
				OperationID: &operationID,
			},
		)
		if err != nil {
			t.Fatalf("recovered ProcessSubjectPurge() error = %v", err)
		}
		if result.RowsPurged > 1 {
			t.Fatalf("subject purge exceeded bound: %+v", result)
		}
		if result.Completed {
			completed = true
			break
		}
	}
	if !completed {
		t.Fatal("subject purge did not complete within bounded phase count")
	}

	for _, table := range []string{
		"saved_outbox",
		"saved_collection_items",
		"saved_collections",
		"saved_items",
		"saved_user_usage",
		"saved_collection_usage",
	} {
		if count := countMaintenanceRows(t, pool, table, "owner_user_id = $1", owner); count != 0 {
			t.Errorf("%s owner rows remaining = %d", table, count)
		}
	}
	if count := countMaintenanceRows(t, pool, "saved_operations", "subject = $1", subject); count != 0 {
		t.Errorf("saved_operations subject rows remaining = %d", count)
	}
	if count := countMaintenanceRows(t, pool, "saved_user_usage", "owner_user_id = $1", otherOwner); count != 1 {
		t.Errorf("other-owner usage count = %d", count)
	}
	if count := countMaintenanceRows(
		t,
		pool,
		"saved_content_projections",
		"entity_id IN ('subject-target-a', 'subject-target-b') AND gc_candidate_at IS NULL",
	); count != 2 {
		t.Fatalf("shared projections were deleted or mutated by subject purge: %d", count)
	}
	marked, err := recoveredRepository.MarkProjectionGCCandidates(
		context.Background(),
		maintenanceBatch(now, 10),
	)
	requireNoMaintenanceError(t, "mark subject-orphaned projections", marked, err)
	if marked.Affected != 2 {
		t.Fatalf("subject-orphaned projection marks = %+v", marked)
	}

	job, err := recoveredRepository.GetSubjectPurge(context.Background(), operationID)
	if err != nil {
		t.Fatalf("GetSubjectPurge() error = %v", err)
	}
	if job.Phase != savedmaintenance.SubjectPurgePhaseCompleted || job.CompletedAt == nil ||
		job.RetentionExpiresAt == nil {
		t.Fatalf("completed subject purge job = %+v", job)
	}
	beforeRetention, err := recoveredRepository.PurgeCompletedSubjectPurges(
		context.Background(),
		maintenanceBatch(now, 10),
	)
	requireNoMaintenanceError(t, "retain completed subject purge", beforeRetention, err)
	if beforeRetention.Affected != 0 {
		t.Fatalf("completed subject purge removed early: %+v", beforeRetention)
	}
	afterRetention, err := recoveredRepository.PurgeCompletedSubjectPurges(
		context.Background(),
		maintenanceBatch(now.Add(savedmaintenance.DefaultOperationRetention+time.Second), 10),
	)
	requireNoMaintenanceError(t, "purge completed subject purge", afterRetention, err)
	if afterRetention.Affected != 1 {
		t.Fatalf("completed subject purge retention = %+v", afterRetention)
	}
}

func TestSavedMaintenanceIndexesHaveExpectedPlans(t *testing.T) {
	pool, _ := openSavedMaintenanceIntegration(t)
	conn, err := pool.Acquire(context.Background())
	if err != nil {
		t.Fatalf("acquire EXPLAIN connection: %v", err)
	}
	defer conn.Release()
	if _, err := conn.Exec(context.Background(), "SET enable_seqscan = off"); err != nil {
		t.Fatalf("disable sequential scans: %v", err)
	}

	owner := uuid.New()
	collectionID := uuid.New()
	queries := map[string]struct {
		query string
		args  []any
	}{
		"idx_saved_collection_items_deleted_parent_cleanup": {
			query: `SELECT owner_user_id, id FROM saved_collection_items
                    WHERE owner_user_id = $1 AND collection_id = $2 ORDER BY id LIMIT 10`,
			args: []any{owner, collectionID},
		},
		"idx_saved_operations_collection_dependency": {
			query: "SELECT applied_collection_id FROM saved_operations WHERE applied_collection_id = $1",
			args:  []any{collectionID},
		},
		"idx_saved_outbox_owner_purge": {
			query: "SELECT owner_user_id, id FROM saved_outbox WHERE owner_user_id = $1 ORDER BY id LIMIT 10",
			args:  []any{owner},
		},
		"idx_saved_content_projections_gc_discovery": {
			query: `SELECT entity_type, entity_id FROM saved_content_projections
                    WHERE ever_referenced = TRUE AND gc_candidate_at IS NULL
                    ORDER BY entity_type, entity_id LIMIT 10`,
		},
	}
	for indexName, contract := range queries {
		plan := explainMaintenanceQuery(t, conn, contract.query, contract.args...)
		if !strings.Contains(plan, indexName) {
			t.Errorf("EXPLAIN does not use %s:\n%s", indexName, plan)
		}
	}
}

func TestSavedMaintenanceMigrationsRoundTripPostgres(t *testing.T) {
	pool, _ := openSavedMaintenanceIntegration(t)
	for _, migration := range []string{
		"005_saved_maintenance_indexes.down.sql",
		"004_saved_lifecycle_inbox.down.sql",
		"003_saved_search.down.sql",
		"002_saved_collections.down.sql",
		"001_saved_core.down.sql",
	} {
		if _, err := pool.Exec(context.Background(), readSavedMaintenanceMigration(t, migration)); err != nil {
			t.Fatalf("apply %s: %v", migration, err)
		}
	}
	var coreTable *string
	if err := pool.QueryRow(context.Background(), "SELECT to_regclass('saved_operations')::text").Scan(&coreTable); err != nil {
		t.Fatalf("check migration rollback: %v", err)
	}
	if coreTable != nil {
		t.Fatalf("saved_operations remains after rollback: %s", *coreTable)
	}
}

func maintenanceBatch(now time.Time, limit int) savedmaintenance.BatchRequest {
	return savedmaintenance.BatchRequest{
		Now:                 now.UTC(),
		Limit:               limit,
		OperationRetention:  savedmaintenance.DefaultOperationRetention,
		ProjectionRetention: savedmaintenance.DefaultProjectionRetention,
	}
}

func insertMaintenancePendingOperation(
	t testing.TB,
	pool *pgxpool.Pool,
	subject string,
	kind string,
	createdAt time.Time,
	commitDeadline time.Time,
	seed byte,
) uuid.UUID {
	t.Helper()
	operationID := uuid.New()
	_, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_operations (
             subject, session_generation, operation_id, operation_kind,
             idempotency_key, semantic_request_hmac, request_hmac_key_version,
             first_seen_source_surface, accepted_platform_access_policy_revision,
             status, commit_deadline, created_at
         ) VALUES ($1, $2, $3, $4, $5, $6, 1, 'CARD', 1, 'PENDING', $7, $8)`,
		subject,
		uuid.New(),
		operationID,
		kind,
		base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{seed}, 16)),
		bytes.Repeat([]byte{seed}, 32),
		commitDeadline.UTC(),
		createdAt.UTC(),
	)
	if err != nil {
		t.Fatalf("insert pending maintenance operation: %v", err)
	}
	return operationID
}

type maintenanceSavedItem struct {
	id            uuid.UUID
	generation    uuid.UUID
	attributionID uuid.UUID
	entityID      string
}

func insertMaintenanceProjection(
	t testing.TB,
	pool *pgxpool.Pool,
	entityID string,
	everReferenced bool,
	shellExpiresAt *time.Time,
	gcCandidateAt *time.Time,
	createdAt time.Time,
) {
	t.Helper()
	_, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_content_projections (
             entity_type, entity_id, source_service, visibility_status,
             shell_expires_at, ever_referenced, gc_candidate_at, created_at, updated_at
         ) VALUES ('ACTIVITY', $1, 'activity-service', 'UNKNOWN', $2, $3, $4, $5, $5)`,
		entityID,
		shellExpiresAt,
		everReferenced,
		gcCandidateAt,
		createdAt.UTC(),
	)
	if err != nil {
		t.Fatalf("insert projection %s: %v", entityID, err)
	}
}

func insertMaintenanceSavedItem(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	entityID string,
	state string,
	savedAt time.Time,
	removedAt time.Time,
) maintenanceSavedItem {
	t.Helper()
	item := maintenanceSavedItem{
		id:            uuid.New(),
		generation:    uuid.New(),
		attributionID: uuid.New(),
		entityID:      entityID,
	}
	if state == "ACTIVE" {
		_, err := pool.Exec(
			context.Background(),
			`INSERT INTO saved_items (
                 id, owner_user_id, entity_type, entity_id, relationship_state,
                 state_generation, relationship_attribution_id,
                 relationship_version, saved_at, created_at, updated_at
             ) VALUES ($1, $2, 'ACTIVITY', $3, 'ACTIVE', $4, $5, 1, $6, $6, $6)`,
			item.id,
			owner,
			entityID,
			item.generation,
			item.attributionID,
			savedAt.UTC(),
		)
		if err != nil {
			t.Fatalf("insert active saved item %s: %v", entityID, err)
		}
		return item
	}
	_, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_items (
             id, owner_user_id, entity_type, entity_id, relationship_state,
             state_generation, relationship_attribution_id,
             relationship_version, saved_at, removed_at, purge_eligible_at,
             created_at, updated_at
         ) VALUES ($1, $2, 'ACTIVITY', $3, 'REMOVED', $4, $5, 2, $6, $7, $8, $6, $7)`,
		item.id,
		owner,
		entityID,
		item.generation,
		item.attributionID,
		savedAt.UTC(),
		removedAt.UTC(),
		removedAt.Add(14*24*time.Hour).UTC(),
	)
	if err != nil {
		t.Fatalf("insert removed saved item %s: %v", entityID, err)
	}
	return item
}

func insertMaintenanceCollection(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	deleted bool,
	lifecycleAt time.Time,
) uuid.UUID {
	t.Helper()
	collectionID := uuid.New()
	clientID := uuid.New()
	if !deleted {
		title := "maintenance-" + collectionID.String()[:8]
		_, err := pool.Exec(
			context.Background(),
			`INSERT INTO saved_collections (
                 id, owner_user_id, client_creation_id, title, normalized_title_key,
                 lifecycle_state, created_at, organized_at, updated_at
             ) VALUES ($1, $2, $3, $4, $4, 'ACTIVE', $5, $5, $5)`,
			collectionID,
			owner,
			clientID,
			title,
			lifecycleAt.Add(-30*24*time.Hour).UTC(),
		)
		if err != nil {
			t.Fatalf("insert active collection: %v", err)
		}
		return collectionID
	}
	createdAt := lifecycleAt.Add(-15 * 24 * time.Hour)
	_, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_collections (
             id, owner_user_id, client_creation_id, title, normalized_title_key,
             lifecycle_state, lifecycle_version, metadata_version, items_version,
             active_item_count, created_at, organized_at, updated_at,
             deleted_at, purge_eligible_at
         ) VALUES (
             $1, $2, $3, NULL, NULL, 'DELETED', 2, 1, 2, 0,
             $4, $4, $5, $5, $6
         )`,
		collectionID,
		owner,
		clientID,
		createdAt.UTC(),
		lifecycleAt.UTC(),
		lifecycleAt.Add(14*24*time.Hour).UTC(),
	)
	if err != nil {
		t.Fatalf("insert deleted collection: %v", err)
	}
	return collectionID
}

func insertMaintenanceMembership(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	collectionID uuid.UUID,
	savedItemID uuid.UUID,
	state string,
	removedAt time.Time,
) {
	t.Helper()
	membershipID := uuid.New()
	if state == "ACTIVE" {
		addedAt := time.Now().UTC().Add(-10 * 24 * time.Hour).Truncate(time.Microsecond)
		_, err := pool.Exec(
			context.Background(),
			`INSERT INTO saved_collection_items (
                 id, owner_user_id, collection_id, saved_item_id, membership_state,
                 membership_version, saved_at_snapshot, added_at, updated_at
             ) VALUES ($1, $2, $3, $4, 'ACTIVE', 1, $5, $6, $6)`,
			membershipID,
			owner,
			collectionID,
			savedItemID,
			addedAt.Add(-time.Hour),
			addedAt,
		)
		if err != nil {
			t.Fatalf("insert active membership: %v", err)
		}
		return
	}
	addedAt := removedAt.Add(-24 * time.Hour)
	_, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_collection_items (
             id, owner_user_id, collection_id, saved_item_id, membership_state,
             membership_version, saved_at_snapshot, removal_reason,
             added_at, updated_at, removed_at, purge_eligible_at
         ) VALUES ($1, $2, $3, $4, 'REMOVED', 2, $5, 'MAINTENANCE_TEST', $6, $7, $7, $8)`,
		membershipID,
		owner,
		collectionID,
		savedItemID,
		addedAt.Add(-time.Hour),
		addedAt,
		removedAt.UTC(),
		removedAt.Add(14*24*time.Hour).UTC(),
	)
	if err != nil {
		t.Fatalf("insert removed membership: %v", err)
	}
}

func insertMaintenanceOutbox(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	item maintenanceSavedItem,
	deliveredAt time.Time,
) {
	t.Helper()
	createdAt := deliveredAt.Add(-time.Hour)
	_, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_outbox (
             id, owner_user_id, saved_item_id, event_type, entity_type, entity_id,
             relationship_state, state_generation, relationship_attribution_id,
             relationship_version, status, next_attempt_at, delivered_at,
             retention_expires_at, created_at, updated_at
         ) VALUES (
             $1, $2, $3, 'SAVED_ITEM_REMOVED', 'ACTIVITY', $4,
             'REMOVED', $5, $6, 2, 'DELIVERED', $7, $8, $9, $7, $8
         )`,
		uuid.New(),
		owner,
		item.id,
		item.entityID,
		item.generation,
		item.attributionID,
		createdAt.UTC(),
		deliveredAt.UTC(),
		deliveredAt.Add(14*24*time.Hour).UTC(),
	)
	if err != nil {
		t.Fatalf("insert outbox: %v", err)
	}
}

func insertMaintenanceTerminalCollectionOperation(
	t testing.TB,
	pool *pgxpool.Pool,
	subject string,
	collectionID uuid.UUID,
	createdAt time.Time,
	seed byte,
) {
	t.Helper()
	completedAt := createdAt.Add(5 * time.Second)
	_, err := pool.Exec(
		context.Background(),
		`INSERT INTO saved_operations (
             subject, session_generation, operation_id, operation_kind,
             idempotency_key, semantic_request_hmac, request_hmac_key_version,
             first_seen_source_surface, accepted_platform_access_policy_revision,
             status, commit_deadline, outcome_code, outcome_retryable, refresh_scope,
             applied_collection_id, applied_collection_metadata_version,
             applied_collection_lifecycle_version, created_at, completed_at,
             retention_expires_at
         ) VALUES (
             $1, $2, $3, 'DELETE_COLLECTION', $4, $5, 1, 'SAVED_COLLECTION', 1,
             'SUCCEEDED', $6, 'APPLIED', FALSE, 'BOTH', $7, 1, 2, $8, $9, $10
         )`,
		subject,
		uuid.New(),
		uuid.New(),
		base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{seed}, 16)),
		bytes.Repeat([]byte{seed}, 32),
		createdAt.Add(10*time.Second).UTC(),
		collectionID,
		createdAt.UTC(),
		completedAt.UTC(),
		completedAt.Add(savedmaintenance.DefaultOperationRetention).UTC(),
	)
	if err != nil {
		t.Fatalf("insert terminal collection operation: %v", err)
	}
}

func timePointer(value time.Time) *time.Time {
	value = value.UTC()
	return &value
}

func openSavedMaintenanceIntegration(t *testing.T) (*pgxpool.Pool, *PGSavedMaintenanceRepository) {
	t.Helper()

	dsn := strings.TrimSpace(os.Getenv(savedMaintenanceIntegrationDSNEnv))
	if dsn == "" {
		t.Skipf("%s is not set", savedMaintenanceIntegrationDSNEnv)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	adminPool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect integration database: %v", err)
	}
	if err := adminPool.Ping(ctx); err != nil {
		adminPool.Close()
		t.Fatalf("ping integration database: %v", err)
	}

	schema := "saved_maintenance_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	quotedSchema := pgx.Identifier{schema}.Sanitize()
	if _, err := adminPool.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		adminPool.Close()
		t.Fatalf("create isolated schema: %v", err)
	}

	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		dropMaintenanceSchema(adminPool, quotedSchema)
		t.Fatalf("parse integration DSN: %v", err)
	}
	poolConfig.ConnConfig.RuntimeParams["search_path"] = quotedSchema
	poolConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		dropMaintenanceSchema(adminPool, quotedSchema)
		t.Fatalf("connect isolated schema: %v", err)
	}

	t.Cleanup(func() {
		pool.Close()
		dropMaintenanceSchema(adminPool, quotedSchema)
		adminPool.Close()
	})

	for _, migration := range []string{
		"001_saved_core.up.sql",
		"002_saved_collections.up.sql",
		"003_saved_search.up.sql",
		"004_saved_lifecycle_inbox.up.sql",
		"005_saved_maintenance_indexes.up.sql",
	} {
		if _, err := pool.Exec(ctx, readSavedMaintenanceMigration(t, migration)); err != nil {
			t.Fatalf("apply %s: %v", migration, err)
		}
	}
	repository, err := NewPGSavedMaintenanceRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedMaintenanceRepository() error = %v", err)
	}
	return pool, repository
}

func readSavedMaintenanceMigration(t testing.TB, name string) string {
	t.Helper()
	if directory := strings.TrimSpace(os.Getenv("SAVED_SERVICE_MIGRATIONS_DIR")); directory != "" {
		contents, err := os.ReadFile(filepath.Join(directory, name))
		if err != nil {
			t.Fatalf("read maintenance migration %s: %v", name, err)
		}
		return string(contents)
	}
	_, currentFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("resolve maintenance integration test path")
	}
	path := filepath.Join(filepath.Dir(currentFile), "..", "..", "..", "migrations", name)
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read maintenance migration %s: %v", name, err)
	}
	return string(contents)
}

func dropMaintenanceSchema(adminPool *pgxpool.Pool, quotedSchema string) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	_, _ = adminPool.Exec(ctx, "DROP SCHEMA "+quotedSchema+" CASCADE")
}

func countMaintenanceRows(t testing.TB, pool *pgxpool.Pool, table string, predicate string, args ...any) int {
	t.Helper()
	query := fmt.Sprintf("SELECT count(*) FROM %s", pgx.Identifier{table}.Sanitize())
	if predicate != "" {
		query += " WHERE " + predicate
	}
	var count int
	if err := pool.QueryRow(context.Background(), query, args...).Scan(&count); err != nil {
		t.Fatalf("count %s: %v", table, err)
	}
	return count
}

func explainMaintenanceQuery(
	t testing.TB,
	conn *pgxpool.Conn,
	query string,
	arguments ...any,
) string {
	t.Helper()
	rows, err := conn.Query(context.Background(), "EXPLAIN (COSTS OFF) "+query, arguments...)
	if err != nil {
		t.Fatalf("EXPLAIN query: %v", err)
	}
	defer rows.Close()
	var lines []string
	for rows.Next() {
		var line string
		if err := rows.Scan(&line); err != nil {
			t.Fatalf("scan EXPLAIN: %v", err)
		}
		lines = append(lines, line)
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("read EXPLAIN: %v", err)
	}
	return strings.Join(lines, "\n")
}

func requireNoMaintenanceError(t testing.TB, operation string, result savedmaintenance.BatchResult, err error) {
	t.Helper()
	if err != nil {
		t.Fatalf("%s error = %v", operation, err)
	}
}
