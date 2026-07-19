package repository

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	operationapp "kz/inflap/backend/services/saved-service/internal/app/operation"
	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestPGSavedItemRepositoryLifecycleAndQuota(t *testing.T) {
	pool, operationStore, repository := openSavedItemKernelIntegration(t)
	truncateSavedItemKernel(t, pool)

	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	target := integrationSavedTarget(t, domain.EntityTypeAttraction)

	identity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 1, base, base.Add(10*time.Second))
	command := integrationSaveCommand(t, identity, owner, target, base, 1)
	receipt, err := repository.Save(context.Background(), command)
	if err != nil {
		t.Fatalf("Save(absent) error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	firstGeneration := receipt.AppliedRelationship().Generation
	if receipt.AppliedRelationship().Version != 1 || *receipt.AppliedUserUsageVersion() != 1 {
		t.Fatalf("first save versions = %+v usage=%v", receipt.AppliedRelationship(), receipt.AppliedUserUsageVersion())
	}
	assertSavedProjectionPayload(t, pool, target, true, 1)
	assertSavedProjectionLeases(t, pool, target, command.Projection)
	assertSavedKernelCounts(t, pool, owner, 1, 1)

	noOpAt := base.Add(time.Second)
	identity = createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 2, noOpAt, noOpAt.Add(10*time.Second))
	noOpCommand := integrationSaveCommand(t, identity, owner, target, noOpAt, 2)
	receipt, err = repository.Save(context.Background(), noOpCommand)
	if err != nil {
		t.Fatalf("Save(active) error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeNoOp)
	if receipt.AppliedRelationship().Generation != firstGeneration || receipt.AppliedRelationship().Version != 1 ||
		*receipt.AppliedUserUsageVersion() != 1 {
		t.Fatalf("no-op changed relationship or usage: relationship=%+v usage=%v", receipt.AppliedRelationship(), receipt.AppliedUserUsageVersion())
	}
	assertSavedProjectionPayload(t, pool, target, true, 2)
	assertSavedProjectionLeases(t, pool, target, noOpCommand.Projection)
	assertSavedKernelCounts(t, pool, owner, 1, 1)

	quotaAt := base.Add(2 * time.Second)
	quotaTarget := integrationSavedTarget(t, domain.EntityTypeGuide)
	identity = createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 3, quotaAt, quotaAt.Add(10*time.Second))
	quotaCommand := integrationSaveCommand(t, identity, owner, quotaTarget, quotaAt, 1)
	quotaCommand.MaxActiveSaves = 1
	receipt, err = repository.Save(context.Background(), quotaCommand)
	if err != nil {
		t.Fatalf("Save(quota) error = %v", err)
	}
	assertRejectedOperation(t, receipt, domain.ErrorCodeItemLimitReached)
	assertSavedProjectionPayload(t, pool, quotaTarget, false, 1)
	assertSavedProjectionLeases(t, pool, quotaTarget, quotaCommand.Projection)
	assertSavedKernelCounts(t, pool, owner, 1, 1)

	unsaveAt := base.Add(3 * time.Second)
	identity = createKernelOperation(t, operationStore, subject, session, domain.OperationKindUnsave, 4, unsaveAt, unsaveAt.Add(10*time.Second))
	unsaveCommand := integrationUnsaveCommand(identity, owner, target, unsaveAt)
	receipt, err = repository.GlobalUnsave(context.Background(), unsaveCommand)
	if err != nil {
		t.Fatalf("GlobalUnsave() error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)

	reactivateAt := base.Add(4 * time.Second)
	identity = createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 5, reactivateAt, reactivateAt.Add(10*time.Second))
	reactivateCommand := integrationSaveCommand(t, identity, owner, target, reactivateAt, 3)
	receipt, err = repository.Save(context.Background(), reactivateCommand)
	if err != nil {
		t.Fatalf("Save(reactivate) error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	if receipt.AppliedRelationship().Generation != reactivateCommand.StateGeneration ||
		receipt.AppliedRelationship().Generation == firstGeneration || receipt.AppliedRelationship().Version != 3 ||
		*receipt.AppliedUserUsageVersion() != 3 {
		t.Fatalf("reactivation versions = relationship=%+v usage=%v", receipt.AppliedRelationship(), receipt.AppliedUserUsageVersion())
	}
	assertSavedKernelCounts(t, pool, owner, 1, 3)
	assertTableCount(t, pool, "saved_outbox", 3)
}

func TestPGSavedItemRepositoryGlobalUnsaveMemberships(t *testing.T) {
	pool, operationStore, repository := openSavedItemKernelIntegration(t)
	truncateSavedItemKernel(t, pool)

	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	target := integrationSavedTarget(t, domain.EntityTypeActivity)
	saveIdentity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 10, base, base.Add(10*time.Second))
	if _, err := repository.Save(context.Background(), integrationSaveCommand(t, saveIdentity, owner, target, base, 1)); err != nil {
		t.Fatalf("seed Save() error = %v", err)
	}

	savedItemID, savedAt := seedSavedMemberships(t, pool, owner, target, base.Add(time.Second))
	unsaveAt := base.Add(2 * time.Second)
	unsaveIdentity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindUnsave, 11, unsaveAt, unsaveAt.Add(10*time.Second))
	receipt, err := repository.GlobalUnsave(
		context.Background(),
		integrationUnsaveCommand(unsaveIdentity, owner, target, unsaveAt),
	)
	if err != nil {
		t.Fatalf("GlobalUnsave() error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeApplied)
	if receipt.RefreshScope() != domain.RefreshScopeBoth || *receipt.AppliedDependentMembershipVersion() != 3 {
		t.Fatalf("unsave effects = scope=%s dependent=%v", receipt.RefreshScope(), receipt.AppliedDependentMembershipVersion())
	}

	var relationshipState string
	var relationshipVersion int64
	var dependentVersion int64
	var removedAt time.Time
	var relationshipPurgeAt time.Time
	if err := pool.QueryRow(context.Background(), `
        SELECT relationship_state, relationship_version, dependent_membership_version,
               removed_at, purge_eligible_at
        FROM saved_items
        WHERE owner_user_id = $1 AND id = $2`, owner.String(), savedItemID.String()).Scan(
		&relationshipState, &relationshipVersion, &dependentVersion, &removedAt, &relationshipPurgeAt,
	); err != nil {
		t.Fatalf("read removed relationship: %v", err)
	}
	if relationshipState != "REMOVED" || relationshipVersion != 2 || dependentVersion != 3 ||
		!removedAt.Equal(unsaveAt) || relationshipPurgeAt.Sub(removedAt) != 14*24*time.Hour {
		t.Fatalf("removed relationship = state=%s version=%d dependent=%d removed=%s purge=%s",
			relationshipState, relationshipVersion, dependentVersion, removedAt, relationshipPurgeAt)
	}

	rows, err := pool.Query(context.Background(), `
        SELECT membership_state, membership_version, removal_reason, removed_at,
               purge_eligible_at, saved_at_snapshot
        FROM saved_collection_items
        WHERE owner_user_id = $1
        ORDER BY collection_id`, owner.String())
	if err != nil {
		t.Fatalf("read memberships: %v", err)
	}
	defer rows.Close()
	membershipCount := 0
	for rows.Next() {
		var state string
		var version int64
		var reason string
		var removed time.Time
		var purge time.Time
		var snapshot time.Time
		if err := rows.Scan(&state, &version, &reason, &removed, &purge, &snapshot); err != nil {
			t.Fatalf("scan membership: %v", err)
		}
		if state != "REMOVED" || version != 2 || reason != "GLOBAL_UNSAVE" ||
			!removed.Equal(unsaveAt) || purge.Sub(removed) != 14*24*time.Hour || !snapshot.Equal(savedAt) {
			t.Fatalf("removed membership = %s v%d %s removed=%s purge=%s snapshot=%s",
				state, version, reason, removed, purge, snapshot)
		}
		membershipCount++
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("iterate memberships: %v", err)
	}
	if membershipCount != 2 {
		t.Fatalf("membership count = %d, want 2", membershipCount)
	}

	var wrongCollections int
	if err := pool.QueryRow(context.Background(), `
        SELECT count(*)
        FROM saved_collections
        WHERE owner_user_id = $1
          AND (active_item_count <> 0 OR items_version <> 2 OR organized_at <> $2 OR updated_at <> $2)`,
		owner.String(), unsaveAt).Scan(&wrongCollections); err != nil {
		t.Fatalf("verify collections: %v", err)
	}
	if wrongCollections != 0 {
		t.Fatalf("collections with inconsistent counters = %d", wrongCollections)
	}
	assertUsageRows(t, pool, owner, 0, 2, 0, 2)
	assertTableCount(t, pool, "saved_outbox", 2)

	absentAt := base.Add(4 * time.Second)
	absentTarget := integrationSavedTarget(t, domain.EntityTypeGuide)
	absentIdentity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindUnsave, 13, absentAt, absentAt.Add(10*time.Second))
	receipt, err = repository.GlobalUnsave(context.Background(), integrationUnsaveCommand(absentIdentity, owner, absentTarget, absentAt))
	if err != nil {
		t.Fatalf("absent GlobalUnsave() error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeNoOp)
	assertUsageRows(t, pool, owner, 0, 2, 0, 2)
	assertTableCount(t, pool, "saved_outbox", 2)

	noOpAt := base.Add(3 * time.Second)
	noOpIdentity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindUnsave, 12, noOpAt, noOpAt.Add(10*time.Second))
	receipt, err = repository.GlobalUnsave(context.Background(), integrationUnsaveCommand(noOpIdentity, owner, target, noOpAt))
	if err != nil {
		t.Fatalf("second GlobalUnsave() error = %v", err)
	}
	assertOperationOutcome(t, receipt, domain.OperationStatusSucceeded, domain.OperationOutcomeNoOp)
	assertUsageRows(t, pool, owner, 0, 2, 0, 2)
	assertTableCount(t, pool, "saved_outbox", 2)
}

func TestPGSavedItemRepositoryOperationReplayExpiryAndStatus(t *testing.T) {
	pool, operationStore, repository := openSavedItemKernelIntegration(t)
	truncateSavedItemKernel(t, pool)

	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	target := integrationSavedTarget(t, domain.EntityTypeGuide)
	identity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 20, base, base.Add(10*time.Second))
	command := integrationSaveCommand(t, identity, owner, target, base, 1)
	first, err := repository.Save(context.Background(), command)
	if err != nil {
		t.Fatalf("Save() error = %v", err)
	}
	replayed, err := repository.Save(context.Background(), command)
	if err != nil {
		t.Fatalf("Save(replay) error = %v", err)
	}
	if replayed.OperationID() != first.OperationID() || replayed.Status() != first.Status() || replayed.Outcome() != first.Outcome() {
		t.Fatalf("replay receipt differs: first=%+v replay=%+v", first.PersistenceState(), replayed.PersistenceState())
	}
	assertTableCount(t, pool, "saved_items", 1)
	assertTableCount(t, pool, "saved_outbox", 1)

	status, err := repository.GetOperation(context.Background(), saveditemapp.OperationLookup{
		SubjectID: subject, SessionGeneration: session, OperationID: identity.OperationID, ServerNow: base,
	})
	if err != nil || status.Outcome() != domain.OperationOutcomeApplied {
		t.Fatalf("GetOperation() = (%v, %v)", status, err)
	}
	_, err = repository.GetOperation(context.Background(), saveditemapp.OperationLookup{
		SubjectID: uuid.New(), SessionGeneration: session, OperationID: identity.OperationID, ServerNow: base,
	})
	if !errors.Is(err, saveditemapp.ErrOperationNotFound) {
		t.Fatalf("foreign GetOperation() error = %v", err)
	}

	expiredNow := base.Add(20 * time.Second)
	expiredIdentity := createKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSave, 21,
		expiredNow.Add(-20*time.Second), expiredNow.Add(-10*time.Second),
	)
	expiredCommand := integrationSaveCommand(t, expiredIdentity, owner, integrationSavedTarget(t, domain.EntityTypeAttraction), expiredNow, 1)
	expired, err := repository.Save(context.Background(), expiredCommand)
	if err != nil {
		t.Fatalf("Save(expired) error = %v", err)
	}
	assertOperationOutcome(t, expired, domain.OperationStatusExpired, domain.OperationOutcomeExpired)
	if expired.RetentionExpiresAt().Sub(*expired.CompletedAt()) != 14*24*time.Hour {
		t.Fatalf("expired retention = %s", expired.RetentionExpiresAt().Sub(*expired.CompletedAt()))
	}

	pendingAt := base.Add(30 * time.Second)
	pendingIdentity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 22, pendingAt, pendingAt.Add(10*time.Second))
	mismatchCommand := integrationSaveCommand(t, pendingIdentity, owner, integrationSavedTarget(t, domain.EntityTypeActivity), pendingAt, 1)
	mismatchCommand.Identity.SemanticRequestHMAC = bytes.Repeat([]byte{0xff}, 32)
	_, err = repository.Save(context.Background(), mismatchCommand)
	if !errors.Is(err, domain.ErrReplayMismatch) {
		t.Fatalf("Save(HMAC mismatch) error = %v", err)
	}
	status, err = repository.GetOperation(context.Background(), saveditemapp.OperationLookup{
		SubjectID: subject, SessionGeneration: session, OperationID: pendingIdentity.OperationID, ServerNow: pendingAt,
	})
	if err != nil || status.Status() != domain.OperationStatusPending {
		t.Fatalf("mismatched operation status = (%v, %v)", status, err)
	}

	readExpiryAt := base.Add(50 * time.Second)
	readExpiryDeadline := readExpiryAt.Add(10 * time.Second)
	readExpiryIdentity := createKernelOperation(
		t, operationStore, subject, session, domain.OperationKindSetTargetCollections, 24,
		readExpiryAt, readExpiryDeadline,
	)
	status, err = repository.GetOperation(context.Background(), saveditemapp.OperationLookup{
		SubjectID:         subject,
		SessionGeneration: session,
		OperationID:       readExpiryIdentity.OperationID,
		ServerNow:         readExpiryDeadline,
	})
	if err != nil {
		t.Fatalf("GetOperation(expired pending) error = %v", err)
	}
	assertOperationOutcome(t, status, domain.OperationStatusExpired, domain.OperationOutcomeExpired)
	if status.RefreshScope() != domain.RefreshScopeBoth ||
		status.CompletedAt() == nil || !status.CompletedAt().Equal(readExpiryDeadline) {
		t.Fatalf("read-expired operation state = %+v", status.PersistenceState())
	}

	rejectAt := base.Add(31 * time.Second)
	rejectIdentity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 23, rejectAt, rejectAt.Add(10*time.Second))
	rejected, err := repository.RejectPending(context.Background(), saveditemapp.RejectPendingCommand{
		Identity:     rejectIdentity,
		Cause:        domain.ErrDependencyUnavailable,
		RefreshScope: domain.RefreshScopeNone,
		ServerNow:    rejectAt,
	})
	if err != nil {
		t.Fatalf("RejectPending() error = %v", err)
	}
	assertRejectedOperation(t, rejected, domain.ErrorCodeDependencyUnavailable)
	rejectedReplay, err := repository.RejectPending(context.Background(), saveditemapp.RejectPendingCommand{
		Identity:     rejectIdentity,
		Cause:        domain.ErrTargetUnavailable,
		RefreshScope: domain.RefreshScopeSavedItems,
		ServerNow:    rejectAt.Add(time.Second),
	})
	if err != nil || rejectedReplay.Failure().Code != domain.ErrorCodeDependencyUnavailable {
		t.Fatalf("RejectPending(replay) = (%v, %v)", operationState(rejectedReplay), err)
	}
}

func TestPGSavedItemRepositoryRevisionRollbackAndTransactionRollback(t *testing.T) {
	pool, operationStore, repository := openSavedItemKernelIntegration(t)
	truncateSavedItemKernel(t, pool)

	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	target := integrationSavedTarget(t, domain.EntityTypeAttraction)
	identity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 30, base, base.Add(10*time.Second))
	firstCommand := integrationSaveCommand(t, identity, owner, target, base, 5)
	if _, err := repository.Save(context.Background(), firstCommand); err != nil {
		t.Fatalf("initial Save() error = %v", err)
	}

	rollbackAt := base.Add(time.Second)
	identity = createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 31, rollbackAt, rollbackAt.Add(10*time.Second))
	staleCommand := integrationSaveCommand(t, identity, owner, target, rollbackAt, 4)
	receipt, err := repository.Save(context.Background(), staleCommand)
	if err != nil {
		t.Fatalf("stale Save() error = %v", err)
	}
	assertRejectedOperation(t, receipt, domain.ErrorCodeMutationStale)
	assertSavedProjectionPayload(t, pool, target, true, 5)
	assertSavedKernelCounts(t, pool, owner, 1, 1)

	failedAt := base.Add(2 * time.Second)
	failedTarget := integrationSavedTarget(t, domain.EntityTypeGuide)
	failedIdentity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 32, failedAt, failedAt.Add(10*time.Second))
	failedCommand := integrationSaveCommand(t, failedIdentity, owner, failedTarget, failedAt, 6)
	failedCommand.ActivatedOutboxEventID = firstCommand.ActivatedOutboxEventID
	_, err = repository.Save(context.Background(), failedCommand)
	if !errors.Is(err, domain.ErrMutationStale) {
		t.Fatalf("Save(outbox collision) error = %v", err)
	}
	assertSavedKernelCounts(t, pool, owner, 1, 1)
	assertTableCount(t, pool, "saved_outbox", 1)
	assertTargetRowCount(t, pool, "saved_items", failedTarget, 0)
	assertTargetRowCount(t, pool, "saved_content_projections", failedTarget, 0)
	status, err := repository.GetOperation(context.Background(), saveditemapp.OperationLookup{
		SubjectID: subject, SessionGeneration: session, OperationID: failedIdentity.OperationID, ServerNow: failedAt,
	})
	if err != nil || status.Status() != domain.OperationStatusPending {
		t.Fatalf("rolled-back operation status = (%v, %v)", status, err)
	}
}

func TestPGSavedItemRepositoryCrossOwnerIsolation(t *testing.T) {
	pool, operationStore, repository := openSavedItemKernelIntegration(t)
	truncateSavedItemKernel(t, pool)

	base := time.Now().UTC().Truncate(time.Microsecond)
	target := integrationSavedTarget(t, domain.EntityTypeGuide)
	ownerA := uuid.New()
	ownerB := uuid.New()
	subjectA := uuid.New()
	subjectB := uuid.New()
	sessionA := uuid.New()
	sessionB := uuid.New()
	identityA := createKernelOperation(t, operationStore, subjectA, sessionA, domain.OperationKindSave, 40, base, base.Add(10*time.Second))
	identityB := createKernelOperation(t, operationStore, subjectB, sessionB, domain.OperationKindSave, 41, base, base.Add(10*time.Second))
	if _, err := repository.Save(context.Background(), integrationSaveCommand(t, identityA, ownerA, target, base, 1)); err != nil {
		t.Fatalf("Save(owner A) error = %v", err)
	}
	if _, err := repository.Save(context.Background(), integrationSaveCommand(t, identityB, ownerB, target, base, 1)); err != nil {
		t.Fatalf("Save(owner B) error = %v", err)
	}

	unsaveAt := base.Add(time.Second)
	unsaveIdentity := createKernelOperation(t, operationStore, subjectA, sessionA, domain.OperationKindUnsave, 42, unsaveAt, unsaveAt.Add(10*time.Second))
	if _, err := repository.GlobalUnsave(context.Background(), integrationUnsaveCommand(unsaveIdentity, ownerA, target, unsaveAt)); err != nil {
		t.Fatalf("GlobalUnsave(owner A) error = %v", err)
	}
	assertOwnerRelationshipState(t, pool, ownerA, target, "REMOVED")
	assertOwnerRelationshipState(t, pool, ownerB, target, "ACTIVE")
	assertUsageRows(t, pool, ownerA, 0, 2, 0, 0)
	assertUsageRows(t, pool, ownerB, 1, 1, 0, 0)

	_, err := repository.GetOperation(context.Background(), saveditemapp.OperationLookup{
		SubjectID: subjectB, SessionGeneration: sessionA, OperationID: unsaveIdentity.OperationID, ServerNow: unsaveAt,
	})
	if !errors.Is(err, saveditemapp.ErrOperationNotFound) {
		t.Fatalf("cross-subject operation lookup error = %v", err)
	}
}

func TestPGSavedItemRepositoryConcurrentSaveUnsaveConverges(t *testing.T) {
	pool, operationStore, repository := openSavedItemKernelIntegration(t)
	truncateSavedItemKernel(t, pool)

	base := time.Now().UTC().Truncate(time.Microsecond)
	subject := uuid.New()
	session := uuid.New()
	owner := uuid.New()
	target := integrationSavedTarget(t, domain.EntityTypeActivity)
	seedIdentity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, 50, base, base.Add(10*time.Second))
	if _, err := repository.Save(context.Background(), integrationSaveCommand(t, seedIdentity, owner, target, base, 1)); err != nil {
		t.Fatalf("seed Save() error = %v", err)
	}

	const workers = 12
	serverNow := base.Add(time.Second)
	commands := make([]func(context.Context) (*domain.SavedOperation, error), 0, workers)
	for index := 0; index < workers; index++ {
		seed := byte(51 + index)
		if index%2 == 0 {
			identity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindSave, seed, serverNow, serverNow.Add(10*time.Second))
			command := integrationSaveCommand(t, identity, owner, target, serverNow, 2)
			commands = append(commands, func(ctx context.Context) (*domain.SavedOperation, error) {
				return repository.Save(ctx, command)
			})
		} else {
			identity := createKernelOperation(t, operationStore, subject, session, domain.OperationKindUnsave, seed, serverNow, serverNow.Add(10*time.Second))
			command := integrationUnsaveCommand(identity, owner, target, serverNow)
			commands = append(commands, func(ctx context.Context) (*domain.SavedOperation, error) {
				return repository.GlobalUnsave(ctx, command)
			})
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	start := make(chan struct{})
	errorsChannel := make(chan error, workers)
	var ready sync.WaitGroup
	ready.Add(workers)
	for _, run := range commands {
		go func(run func(context.Context) (*domain.SavedOperation, error)) {
			ready.Done()
			<-start
			receipt, err := run(ctx)
			if err == nil && (receipt == nil || receipt.Status() != domain.OperationStatusSucceeded) {
				err = fmt.Errorf("non-terminal receipt")
			}
			errorsChannel <- err
		}(run)
	}
	ready.Wait()
	close(start)
	for index := 0; index < workers; index++ {
		if err := <-errorsChannel; err != nil {
			t.Fatalf("concurrent mutation error = %v", err)
		}
	}

	var relationshipState string
	if err := pool.QueryRow(context.Background(), `
        SELECT relationship_state
        FROM saved_items
        WHERE owner_user_id = $1 AND entity_type = $2 AND entity_id = $3`,
		owner.String(), string(target.EntityType()), target.EntityID()).Scan(&relationshipState); err != nil {
		t.Fatalf("read converged relationship: %v", err)
	}
	var activeCount int64
	if err := pool.QueryRow(context.Background(), `
        SELECT active_saved_items_count
        FROM saved_user_usage
        WHERE owner_user_id = $1`, owner.String()).Scan(&activeCount); err != nil {
		t.Fatalf("read converged usage: %v", err)
	}
	wantActive := int64(0)
	if relationshipState == "ACTIVE" {
		wantActive = 1
	} else if relationshipState != "REMOVED" {
		t.Fatalf("unexpected relationship state %q", relationshipState)
	}
	if activeCount != wantActive {
		t.Fatalf("usage active count = %d, relationship state = %s", activeCount, relationshipState)
	}
	assertTableCount(t, pool, "saved_items", 1)
}

func openSavedItemKernelIntegration(t *testing.T) (*pgxpool.Pool, *PGOperationStore, *PGSavedItemRepository) {
	t.Helper()
	pool, operationStore := openOperationStoreIntegration(t)
	repository, err := NewPGSavedItemRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedItemRepository() error = %v", err)
	}
	t.Cleanup(func() { truncateSavedItemKernel(t, pool) })
	return pool, operationStore, repository
}

func truncateSavedItemKernel(t testing.TB, pool *pgxpool.Pool) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, err := pool.Exec(ctx, `TRUNCATE TABLE
        saved_outbox,
        saved_collection_items,
        saved_collections,
        saved_items,
        saved_content_projections,
        saved_operations,
        saved_collection_usage,
        saved_user_usage
        CASCADE`)
	if err != nil {
		t.Fatalf("truncate Saved mutation kernel: %v", err)
	}
}

func createKernelOperation(
	t testing.TB,
	store *PGOperationStore,
	subject uuid.UUID,
	session uuid.UUID,
	kind domain.OperationKind,
	seed byte,
	createdAt time.Time,
	deadline time.Time,
) saveditemapp.MutationIdentity {
	t.Helper()
	operationID := uuid.New()
	hmac := bytes.Repeat([]byte{seed}, 32)
	idempotencyKey := base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{seed}, 16))
	pending, err := domain.NewPendingOperation(
		operationID,
		subject,
		session,
		kind,
		idempotencyKey,
		hmac,
		1,
		domain.SourceSurfaceCard,
		1,
		createdAt,
		deadline,
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	result, err := store.CreateOrFind(context.Background(), pending)
	if err != nil || !result.Created {
		t.Fatalf("CreateOrFind() = (%+v, %v)", result, err)
	}
	return saveditemapp.MutationIdentity{
		SubjectID:             subject,
		SessionGeneration:     session,
		OperationID:           operationID,
		Kind:                  kind,
		SemanticRequestHMAC:   hmac,
		RequestHMACKeyVersion: 1,
	}
}

func integrationSaveCommand(
	t testing.TB,
	identity saveditemapp.MutationIdentity,
	owner uuid.UUID,
	target domain.SavedTarget,
	serverNow time.Time,
	revision uint64,
) saveditemapp.SaveCommand {
	t.Helper()
	titleEN := "National Museum"
	titleRU := "Национальный музей"
	searchEN := "national museum astana"
	priceEN := "from 20 USD"
	availabilityRU := "доступно сегодня"
	route := "/saved-target/" + target.EntityID()
	asOf := serverNow.Add(-time.Minute)
	validUntil := serverNow.Add(time.Hour)
	return saveditemapp.SaveCommand{
		Identity:    identity,
		OwnerUserID: owner,
		Projection: saveditemapp.PublicProjectionSnapshot{
			Target:                   target,
			SourceService:            sourceServiceForTarget(target),
			SourceRevision:           revision,
			ProjectionRevision:       revision,
			VisibilityRevision:       revision,
			VisibilityValidatedAt:    serverNow.Add(-time.Second),
			SourceDefaultLocale:      saveditemapp.LocaleEN,
			Title:                    saveditemapp.LocalizedText{EN: &titleEN, RU: &titleRU},
			SearchDocumentVersion:    revision,
			NormalizedSearchDocument: saveditemapp.LocalizedText{EN: &searchEN},
			Media: &saveditemapp.MediaReference{
				OpaqueReference:   "media:public:cover",
				ReferenceRevision: revision,
				ValidUntil:        serverNow.Add(5 * time.Minute),
			},
			Rating:               &saveditemapp.Rating{Value: 4.8, ReviewCount: 412, ScaleMax: 5},
			PriceSummary:         saveditemapp.LocalizedText{EN: &priceEN},
			AvailabilitySummary:  saveditemapp.LocalizedText{RU: &availabilityRU},
			AsOf:                 &asOf,
			ValidUntil:           &validUntil,
			CanonicalDetailRoute: &route,
			ShellExpiresAt:       serverNow.Add(15 * time.Minute),
		},
		SavedItemID:               uuid.New(),
		StateGeneration:           uuid.New(),
		RelationshipAttributionID: uuid.New(),
		ActivatedOutboxEventID:    uuid.New(),
		ServerNow:                 serverNow,
	}
}

func integrationUnsaveCommand(
	identity saveditemapp.MutationIdentity,
	owner uuid.UUID,
	target domain.SavedTarget,
	serverNow time.Time,
) saveditemapp.GlobalUnsaveCommand {
	return saveditemapp.GlobalUnsaveCommand{
		Identity:             identity,
		OwnerUserID:          owner,
		Target:               target,
		RemovedOutboxEventID: uuid.New(),
		ServerNow:            serverNow,
	}
}

func integrationSavedTarget(t testing.TB, entityType domain.EntityType) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	return target
}

func sourceServiceForTarget(target domain.SavedTarget) string {
	switch target.EntityType() {
	case domain.EntityTypeAttraction:
		return "place-service"
	case domain.EntityTypeActivity:
		return "activity-service"
	case domain.EntityTypeGuide:
		return "guide-service"
	default:
		return "saved-source"
	}
}

func seedSavedMemberships(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	target domain.SavedTarget,
	organizedAt time.Time,
) (uuid.UUID, time.Time) {
	t.Helper()
	ctx := context.Background()
	var savedItemIDText string
	var savedAt time.Time
	if err := pool.QueryRow(ctx, `
        UPDATE saved_items
        SET dependent_membership_version = 2, updated_at = $4
        WHERE owner_user_id = $1 AND entity_type = $2 AND entity_id = $3
        RETURNING id::text, saved_at`,
		owner.String(), string(target.EntityType()), target.EntityID(), organizedAt).Scan(&savedItemIDText, &savedAt); err != nil {
		t.Fatalf("prepare saved item memberships: %v", err)
	}
	savedItemID, err := uuid.Parse(savedItemIDText)
	if err != nil {
		t.Fatalf("parse saved item ID: %v", err)
	}
	for index := 0; index < 2; index++ {
		collectionID := uuid.New()
		clientCreationID := uuid.New()
		title := fmt.Sprintf("Collection %d", index+1)
		normalized := fmt.Sprintf("collection %d", index+1)
		if _, err := pool.Exec(ctx, `
            INSERT INTO saved_collections (
                id, owner_user_id, client_creation_id, title, normalized_title_key,
                lifecycle_state, lifecycle_version, metadata_version, items_version,
                active_item_count, created_at, organized_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, 'ACTIVE', 1, 1, 1, 1, $6, $6, $6)`,
			collectionID.String(), owner.String(), clientCreationID.String(), title, normalized, organizedAt); err != nil {
			t.Fatalf("insert collection: %v", err)
		}
		if _, err := pool.Exec(ctx, `
            INSERT INTO saved_collection_items (
                id, owner_user_id, collection_id, saved_item_id, membership_state,
                membership_version, saved_at_snapshot, added_at, updated_at
            ) VALUES ($1, $2, $3, $4, 'ACTIVE', 1, $5, $6, $6)`,
			uuid.NewString(), owner.String(), collectionID.String(), savedItemID.String(), savedAt, organizedAt); err != nil {
			t.Fatalf("insert membership: %v", err)
		}
	}
	if _, err := pool.Exec(ctx, `
        INSERT INTO saved_collection_usage (
            owner_user_id, active_collections_count, active_memberships_count,
            usage_version, created_at, updated_at
        ) VALUES ($1, 2, 2, 1, $2, $2)`, owner.String(), organizedAt); err != nil {
		t.Fatalf("insert collection usage: %v", err)
	}
	return savedItemID, savedAt.UTC()
}

func assertOperationOutcome(
	t testing.TB,
	receipt *domain.SavedOperation,
	status domain.OperationStatus,
	outcome domain.OperationOutcome,
) {
	t.Helper()
	if receipt == nil || receipt.Status() != status || receipt.Outcome() != outcome {
		t.Fatalf("operation = (%v, %v), want (%s, %s)", receipt, operationState(receipt), status, outcome)
	}
}

func assertRejectedOperation(t testing.TB, receipt *domain.SavedOperation, code domain.ErrorCode) {
	t.Helper()
	assertOperationOutcome(t, receipt, domain.OperationStatusRejected, domain.OperationOutcomeRejected)
	failure := receipt.Failure()
	if failure == nil || failure.Code != code {
		t.Fatalf("operation failure = %+v, want %s", failure, code)
	}
}

func operationState(receipt *domain.SavedOperation) any {
	if receipt == nil {
		return nil
	}
	return receipt.PersistenceState()
}

func assertSavedProjectionPayload(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	everReferenced bool,
	revision int64,
) {
	t.Helper()
	var sourceRevision int64
	var projectionRevision int64
	var visibilityRevision int64
	var mediaRevision int64
	var ratingScale float64
	var priceEN string
	var availabilityRU string
	var referenced bool
	var shellPresent bool
	err := pool.QueryRow(context.Background(), `
        SELECT source_revision, projection_revision, visibility_revision,
               media_reference_revision, rating_scale_max::float8,
               price_summary->>'en', availability_summary->>'ru',
               ever_referenced, shell_expires_at IS NOT NULL
        FROM saved_content_projections
        WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID()).Scan(
		&sourceRevision, &projectionRevision, &visibilityRevision,
		&mediaRevision, &ratingScale, &priceEN, &availabilityRU,
		&referenced, &shellPresent,
	)
	if err != nil {
		t.Fatalf("read projection: %v", err)
	}
	if sourceRevision != revision || projectionRevision != revision || visibilityRevision != revision ||
		mediaRevision != revision || ratingScale != 5 || priceEN != "from 20 USD" ||
		availabilityRU != "доступно сегодня" || referenced != everReferenced || shellPresent == everReferenced {
		t.Fatalf("projection mismatch: revisions=(%d,%d,%d) media=%d scale=%v price=%q availability=%q referenced=%v shell=%v",
			sourceRevision, projectionRevision, visibilityRevision, mediaRevision, ratingScale,
			priceEN, availabilityRU, referenced, shellPresent)
	}
}

func assertSavedProjectionLeases(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	want saveditemapp.PublicProjectionSnapshot,
) {
	t.Helper()
	var mediaReference string
	var mediaRevision int64
	var mediaValidUntil time.Time
	var ratingValue float64
	var ratingCount int64
	var ratingScale float64
	var summaryAsOf time.Time
	var summaryValidUntil time.Time
	var searchVersion int64
	err := pool.QueryRow(context.Background(), `
        SELECT media_reference, media_reference_revision, media_valid_until,
               rating_value::float8, rating_count, rating_scale_max::float8,
               summary_as_of, summary_valid_until, search_document_version
        FROM saved_content_projections
        WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID()).Scan(
		&mediaReference, &mediaRevision, &mediaValidUntil,
		&ratingValue, &ratingCount, &ratingScale,
		&summaryAsOf, &summaryValidUntil, &searchVersion,
	)
	if err != nil {
		t.Fatalf("read projection leases: %v", err)
	}
	if want.Media == nil || want.Rating == nil || want.AsOf == nil || want.ValidUntil == nil {
		t.Fatal("test projection is missing expected lease fields")
	}
	if mediaReference != want.Media.OpaqueReference || mediaRevision != int64(want.Media.ReferenceRevision) ||
		!mediaValidUntil.Equal(want.Media.ValidUntil) || ratingValue != want.Rating.Value ||
		ratingCount != int64(want.Rating.ReviewCount) || ratingScale != want.Rating.ScaleMax ||
		!summaryAsOf.Equal(*want.AsOf) || !summaryValidUntil.Equal(*want.ValidUntil) ||
		searchVersion != int64(want.SearchDocumentVersion) {
		t.Fatalf("projection lease fields were not preserved")
	}
}

func assertSavedKernelCounts(t testing.TB, pool *pgxpool.Pool, owner uuid.UUID, activeCount, usageVersion int64) {
	t.Helper()
	var activeItems int64
	if err := pool.QueryRow(context.Background(), `
        SELECT count(*)
        FROM saved_items
        WHERE owner_user_id = $1 AND relationship_state = 'ACTIVE'`, owner.String()).Scan(&activeItems); err != nil {
		t.Fatalf("count active saved items: %v", err)
	}
	if activeItems != activeCount {
		t.Fatalf("active saved items = %d, want %d", activeItems, activeCount)
	}
	var usageCount int64
	var version int64
	if err := pool.QueryRow(context.Background(), `
        SELECT active_saved_items_count, usage_version
        FROM saved_user_usage
        WHERE owner_user_id = $1`, owner.String()).Scan(&usageCount, &version); err != nil {
		t.Fatalf("read saved usage: %v", err)
	}
	if usageCount != activeCount || version != usageVersion {
		t.Fatalf("saved usage = (%d,%d), want (%d,%d)", usageCount, version, activeCount, usageVersion)
	}
}

func assertUsageRows(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	savedCount, savedVersion, membershipCount, collectionUsageVersion int64,
) {
	t.Helper()
	var actualSavedCount int64
	var actualSavedVersion int64
	if err := pool.QueryRow(context.Background(), `
        SELECT active_saved_items_count, usage_version
        FROM saved_user_usage WHERE owner_user_id = $1`, owner.String()).Scan(
		&actualSavedCount, &actualSavedVersion,
	); err != nil {
		t.Fatalf("read saved usage: %v", err)
	}
	if actualSavedCount != savedCount || actualSavedVersion != savedVersion {
		t.Fatalf("saved usage = (%d,%d), want (%d,%d)", actualSavedCount, actualSavedVersion, savedCount, savedVersion)
	}
	if collectionUsageVersion == 0 {
		return
	}
	var actualMembershipCount int64
	var actualCollectionVersion int64
	if err := pool.QueryRow(context.Background(), `
        SELECT active_memberships_count, usage_version
        FROM saved_collection_usage WHERE owner_user_id = $1`, owner.String()).Scan(
		&actualMembershipCount, &actualCollectionVersion,
	); err != nil {
		t.Fatalf("read collection usage: %v", err)
	}
	if actualMembershipCount != membershipCount || actualCollectionVersion != collectionUsageVersion {
		t.Fatalf("collection usage = (%d,%d), want (%d,%d)", actualMembershipCount, actualCollectionVersion, membershipCount, collectionUsageVersion)
	}
}

func assertTableCount(t testing.TB, pool *pgxpool.Pool, table string, want int64) {
	t.Helper()
	allowed := map[string]bool{"saved_items": true, "saved_outbox": true}
	if !allowed[table] {
		t.Fatalf("unsupported count table %q", table)
	}
	var count int64
	if err := pool.QueryRow(context.Background(), "SELECT count(*) FROM "+table).Scan(&count); err != nil {
		t.Fatalf("count %s: %v", table, err)
	}
	if count != want {
		t.Fatalf("%s count = %d, want %d", table, count, want)
	}
}

func assertTargetRowCount(
	t testing.TB,
	pool *pgxpool.Pool,
	table string,
	target domain.SavedTarget,
	want int64,
) {
	t.Helper()
	allowed := map[string]bool{"saved_items": true, "saved_content_projections": true}
	if !allowed[table] {
		t.Fatalf("unsupported target table %q", table)
	}
	var count int64
	query := "SELECT count(*) FROM " + table + " WHERE entity_type = $1 AND entity_id = $2"
	if err := pool.QueryRow(context.Background(), query, string(target.EntityType()), target.EntityID()).Scan(&count); err != nil {
		t.Fatalf("count target rows in %s: %v", table, err)
	}
	if count != want {
		t.Fatalf("target rows in %s = %d, want %d", table, count, want)
	}
}

func assertOwnerRelationshipState(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	target domain.SavedTarget,
	want string,
) {
	t.Helper()
	var state string
	if err := pool.QueryRow(context.Background(), `
        SELECT relationship_state
        FROM saved_items
        WHERE owner_user_id = $1 AND entity_type = $2 AND entity_id = $3`,
		owner.String(), string(target.EntityType()), target.EntityID()).Scan(&state); err != nil {
		t.Fatalf("read owner relationship: %v", err)
	}
	if state != want {
		t.Fatalf("owner relationship state = %q, want %q", state, want)
	}
}

var _ operationapp.OperationStore = (*PGOperationStore)(nil)
