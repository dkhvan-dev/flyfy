package repository

import (
	"context"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	savedreconciliation "kz/inflap/backend/services/saved-service/internal/app/savedreconciliation"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestPGSavedReconciliationMonotonicPublicUpdatePreservesUserState(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	state := seedSavedReconciliationTarget(
		t,
		pool,
		domain.EntityTypeActivity,
		"reconcile-monotonic",
		5,
		now.Add(-24*time.Hour),
		true,
		nil,
		true,
	)

	staleClaim := claimSavedReconciliation(t, repository, now)
	stale, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(
			staleClaim,
			reconciliationPublicDecision(t, staleClaim.Candidate.Key.Target, now, 4, "stale title"),
			now,
		),
	)
	if err != nil || stale.Applied.Outcome != savedreconciliation.ApplyStale {
		t.Fatalf("Complete(stale) = (%+v, %v)", stale, err)
	}
	assertSavedReconciliationProjection(t, pool, state.target, "PUBLIC", 5, 5, 5, "Original title")

	later := now.Add(7 * time.Hour)
	makeSavedReconciliationDue(t, pool, state.target)
	updatedClaim := claimSavedReconciliation(t, repository, later)
	updated, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(
			updatedClaim,
			reconciliationPublicDecision(t, updatedClaim.Candidate.Key.Target, later, 6, "Fresh title"),
			later,
		),
	)
	if err != nil || updated.Applied.Outcome != savedreconciliation.ApplyPublic ||
		!updated.Applied.SourceAdvanced || !updated.Applied.ProjectionAdvanced ||
		!updated.Applied.VisibilityAdvanced {
		t.Fatalf("Complete(fresh) = (%+v, %v)", updated, err)
	}
	assertSavedReconciliationProjection(t, pool, state.target, "PUBLIC", 6, 6, 6, "Fresh title")
	assertSavedReconciliationUserStateUnchanged(t, pool, state)
}

func makeSavedReconciliationDue(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
) {
	t.Helper()
	if _, err := pool.Exec(
		context.Background(),
		`UPDATE saved_content_projections
		 SET reconciliation_next_attempt_at = clock_timestamp() - INTERVAL '1 second',
		     reconciliation_lease_token = NULL,
		     reconciliation_lease_expires_at = NULL
		 WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()),
		target.EntityID(),
	); err != nil {
		t.Fatalf("make reconciliation target due: %v", err)
	}
}

func TestPGSavedReconciliationPrivateAndUnversionedNotFoundFailClosedRecovery(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	privateState := seedSavedReconciliationTarget(
		t, pool, domain.EntityTypeActivity, "reconcile-private", 5,
		now.Add(-24*time.Hour), true, nil, false,
	)
	privateClaim := claimSavedReconciliation(t, repository, now)
	privateDecision, err := savedreconciliation.BuildResolvedDecision(appsource.Resolution{
		Target:     privateClaim.Candidate.Key.Target,
		Visibility: domain.VisibilityPrivate,
		Revisions: appsource.Revisions{
			Source: 6, Projection: 6, Visibility: 6,
		},
		ValidatedAt: now,
	}, now)
	if err != nil {
		t.Fatalf("BuildResolvedDecision(PRIVATE) error = %v", err)
	}
	privateResult, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(privateClaim, privateDecision, now),
	)
	if err != nil || privateResult.Applied.Outcome != savedreconciliation.ApplyDeny ||
		!privateResult.Applied.PayloadCleared {
		t.Fatalf("Complete(PRIVATE) = (%+v, %v)", privateResult, err)
	}
	assertSavedReconciliationProjection(t, pool, privateState.target, "PRIVATE", 6, 6, 6, "")
	assertSavedReconciliationPayloadCleared(t, pool, privateState.target)
	makeSavedReconciliationDue(t, pool, privateState.target)
	recoveryClaim := claimSavedReconciliation(t, repository, now)
	recoveryResolution := repositoryPublicResolution(
		recoveryClaim.Candidate.Key.Target,
		now,
		6,
		"Recovered equal projection",
	)
	recoveryResolution.Revisions.Source = 7
	recoveryResolution.Revisions.Visibility = 7
	recoveryDecision, err := savedreconciliation.BuildResolvedDecision(recoveryResolution, now)
	if err != nil {
		t.Fatalf("BuildResolvedDecision(PUBLIC recovery) error = %v", err)
	}
	recoveryResult, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(recoveryClaim, recoveryDecision, now),
	)
	if err != nil || recoveryResult.Applied.Outcome != savedreconciliation.ApplyPublic ||
		recoveryResult.Applied.ProjectionAdvanced ||
		!recoveryResult.Applied.VisibilityAdvanced {
		t.Fatalf("Complete(PUBLIC equal-projection recovery) = (%+v, %v)", recoveryResult, err)
	}
	assertSavedReconciliationProjection(
		t,
		pool,
		privateState.target,
		"PUBLIC",
		7,
		6,
		7,
		"Recovered equal projection",
	)

	notFoundState := seedSavedReconciliationTarget(
		t, pool, domain.EntityTypeGuide, "reconcile-not-found", 7,
		now.Add(-23*time.Hour), true, nil, false,
	)
	notFoundClaim := claimSavedReconciliation(t, repository, now)
	notFoundDecision, err := savedreconciliation.NewNotFoundDecision(
		notFoundClaim.Candidate.Key.Target,
		now,
	)
	if err != nil {
		t.Fatalf("NewNotFoundDecision() error = %v", err)
	}
	notFoundResult, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(notFoundClaim, notFoundDecision, now),
	)
	if err != nil || notFoundResult.Applied.Outcome != savedreconciliation.ApplyDeny ||
		!notFoundResult.Applied.PayloadCleared {
		t.Fatalf("Complete(NOT_FOUND) = (%+v, %v)", notFoundResult, err)
	}
	assertSavedReconciliationProjection(t, pool, notFoundState.target, "PUBLIC", 7, 7, 7, "")
	assertSavedReconciliationPayloadCleared(t, pool, notFoundState.target)
	assertSavedReconciliationFailClosed(t, pool, notFoundState.target, true)

	lifecycleRepository, err := NewPGSavedLifecycleRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedLifecycleRepository() error = %v", err)
	}
	recoveryAt := time.Now().UTC().Truncate(time.Microsecond)
	equalSnapshot := repositoryLifecycleEventForTarget(
		t,
		repositoryLifecycleContract(t, domain.EntityTypeGuide),
		notFoundState.target,
		recoveryAt,
		7,
		7,
		7,
		domain.VisibilityPublic,
		true,
	)
	outcome, err := lifecycleRepository.Apply(
		context.Background(),
		equalSnapshot,
		recoveryAt.Add(time.Second),
	)
	if err != nil || outcome.Code != savedlifecycle.OutcomeIgnoredStaleRevision ||
		outcome.SourceApplied || outcome.ProjectionApplied || outcome.VisibilityApplied {
		t.Fatalf("Apply(equal fail-closed snapshot) = (%+v, %v)", outcome, err)
	}
	assertSavedReconciliationPayloadCleared(t, pool, notFoundState.target)
	assertSavedReconciliationFailClosed(t, pool, notFoundState.target, true)

	recovery := repositoryLifecycleEventForTarget(
		t,
		repositoryLifecycleContract(t, domain.EntityTypeGuide),
		notFoundState.target,
		recoveryAt.Add(2*time.Second),
		8,
		7,
		8,
		domain.VisibilityPublic,
		true,
	)
	outcome, err = lifecycleRepository.Apply(
		context.Background(),
		recovery,
		recoveryAt.Add(3*time.Second),
	)
	if err != nil || !outcome.SourceApplied || !outcome.ProjectionApplied ||
		!outcome.VisibilityApplied {
		t.Fatalf("Apply(fail-closed visibility recovery) = (%+v, %v)", outcome, err)
	}
	assertSavedReconciliationProjection(t, pool, notFoundState.target, "PUBLIC", 8, 7, 8, "Public title")
	assertSavedReconciliationFailClosed(t, pool, notFoundState.target, false)
}

func TestPGSavedReconciliationSkipsGCOrphansAndEphemeralRows(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	gcCandidateAt := now.Add(-12 * time.Hour)
	orphan := seedSavedReconciliationTarget(
		t, pool, domain.EntityTypeGuide, "reconcile-gc-orphan", 3,
		now.Add(-24*time.Hour), false, &gcCandidateAt, false,
	)
	seedSavedReconciliationEphemeral(t, pool, "reconcile-ephemeral", now)

	claim, found, err := repository.ClaimNext(
		context.Background(),
		reconciliationClaimRequest(now),
	)
	if err != nil || found {
		t.Fatalf("ClaimNext() = (%+v, %t, %v), want no candidate", claim, found, err)
	}
	var persistedCandidateAt time.Time
	if err := pool.QueryRow(
		context.Background(),
		`SELECT gc_candidate_at FROM saved_content_projections
         WHERE entity_type = $1 AND entity_id = $2`,
		string(orphan.target.EntityType()), orphan.target.EntityID(),
	).Scan(&persistedCandidateAt); err != nil {
		t.Fatalf("read gc_candidate_at: %v", err)
	}
	if !persistedCandidateAt.Equal(gcCandidateAt) {
		t.Fatalf("gc_candidate_at = %s, want %s", persistedCandidateAt, gcCandidateAt)
	}
}

func TestPGSavedReconciliationConcurrentWorkersUseSkipLocked(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	const targetCount = 12
	for index := range targetCount {
		seedSavedReconciliationTarget(
			t,
			pool,
			domain.EntityTypeActivity,
			"reconcile-concurrent-"+string(rune('a'+index)),
			1,
			now.Add(-24*time.Hour),
			true,
			nil,
			false,
		)
	}

	var entered atomic.Int32
	var processed atomic.Int32
	ready := make(chan struct{})
	var readyOnce sync.Once
	resolve := func(
		ctx context.Context,
		candidate savedreconciliation.Candidate,
	) (savedreconciliation.Decision, error) {
		if entered.Add(1) == 2 {
			readyOnce.Do(func() { close(ready) })
		}
		select {
		case <-ready:
		case <-ctx.Done():
			return savedreconciliation.Decision{}, ctx.Err()
		}
		return savedreconciliation.BuildResolvedDecision(
			repositoryPublicResolution(
				candidate.Key.Target,
				now,
				candidate.ProjectionRevision+1,
				"Concurrent title",
			),
			now,
		)
	}

	start := make(chan struct{})
	errorsByWorker := make(chan error, 2)
	var workers sync.WaitGroup
	for range 2 {
		workers.Add(1)
		go func() {
			defer workers.Done()
			<-start
			for {
				claim, found, reconcileErr := repository.ClaimNext(
					context.Background(),
					reconciliationClaimRequest(now),
				)
				if reconcileErr != nil {
					errorsByWorker <- reconcileErr
					return
				}
				if !found {
					errorsByWorker <- nil
					return
				}
				decision, resolveErr := resolve(context.Background(), claim.Candidate)
				if resolveErr != nil {
					errorsByWorker <- resolveErr
					return
				}
				_, reconcileErr = repository.Complete(
					context.Background(),
					reconciliationCompletion(claim, decision, now),
				)
				if reconcileErr != nil {
					errorsByWorker <- reconcileErr
					return
				}
				processed.Add(1)
			}
		}()
	}
	close(start)
	workers.Wait()
	close(errorsByWorker)
	for workerErr := range errorsByWorker {
		if workerErr != nil {
			t.Fatalf("concurrent worker error = %v", workerErr)
		}
	}
	if processed.Load() != targetCount {
		t.Fatalf("processed = %d, want %d", processed.Load(), targetCount)
	}
	var updated int
	if err := pool.QueryRow(
		context.Background(),
		`SELECT count(*) FROM saved_content_projections
         WHERE entity_id LIKE 'reconcile-concurrent-%'
           AND projection_revision = 2
           AND visibility_validated_at = $1`,
		now,
	).Scan(&updated); err != nil {
		t.Fatalf("count reconciled projections: %v", err)
	}
	if updated != targetCount {
		t.Fatalf("updated = %d, want %d", updated, targetCount)
	}
}

func TestPGSavedReconciliationPrivacyLifecycleDoesNotWaitForLeaseAndWinsCAS(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	state := seedSavedReconciliationTarget(
		t, pool, domain.EntityTypeActivity, "reconcile-privacy-cas", 5,
		now.Add(-24*time.Hour), true, nil, false,
	)
	claim := claimSavedReconciliation(t, repository, now)

	privacyCtx, cancelPrivacy := context.WithTimeout(context.Background(), time.Second)
	defer cancelPrivacy()
	if _, err := pool.Exec(
		privacyCtx,
		applySavedLifecycleDenySQL,
		string(state.target.EntityType()),
		state.target.EntityID(),
		int64(6),
		int64(6),
		string(domain.VisibilityRestricted),
		now,
		now,
	); err != nil {
		t.Fatalf("apply concurrent privacy lifecycle update: %v", err)
	}

	result, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(
			claim,
			reconciliationPublicDecision(t, claim.Candidate.Key.Target, now, 7, "must not leak"),
			now,
		),
	)
	if err != nil || !result.LeaseLost || result.Applied.Outcome != savedreconciliation.ApplyStale {
		t.Fatalf("Complete(after privacy update) = (%+v, %v)", result, err)
	}
	assertSavedReconciliationProjection(t, pool, state.target, "RESTRICTED", 5, 6, 6, "")
	assertSavedReconciliationPayloadCleared(t, pool, state.target)
}

func TestPGSavedReconciliationEqualRevisionsPreserveVisibilityAndPayload(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	projectionState := seedSavedReconciliationTarget(
		t, pool, domain.EntityTypeActivity, "reconcile-equal-projection", 5,
		now.Add(-24*time.Hour), true, nil, false,
	)
	oldMediaValidUntil := now.Add(-24*time.Hour + 5*time.Minute)
	if _, err := pool.Exec(
		context.Background(),
		`UPDATE saved_content_projections
		 SET media_reference = 'old-media',
		     media_reference_revision = 5,
		     media_valid_until = $3
		 WHERE entity_type = $1 AND entity_id = $2`,
		string(projectionState.target.EntityType()),
		projectionState.target.EntityID(),
		oldMediaValidUntil,
	); err != nil {
		t.Fatalf("seed expired reconciliation media lease: %v", err)
	}
	projectionClaim := claimSavedReconciliation(t, repository, now)
	projectionResolution := repositoryPublicResolution(
		projectionClaim.Candidate.Key.Target,
		now,
		5,
		"replacement must be ignored",
	)
	projectionResolution.Revisions.Source = 6
	projectionResolution.Revisions.Visibility = 6
	projectionResolution.PublicProjection.Media = &appsource.MediaReference{
		OpaqueReference:   "fresh-media",
		ReferenceRevision: 5,
		ValidUntil:        now.Add(5 * time.Minute),
	}
	projectionDecision, err := savedreconciliation.BuildResolvedDecision(projectionResolution, now)
	if err != nil {
		t.Fatalf("BuildResolvedDecision(equal projection) error = %v", err)
	}
	projectionResult, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(projectionClaim, projectionDecision, now),
	)
	if err != nil || projectionResult.Applied.Outcome != savedreconciliation.ApplyMetadataOnly {
		t.Fatalf("Complete(equal projection) = (%+v, %v)", projectionResult, err)
	}
	assertSavedReconciliationProjection(t, pool, projectionState.target, "PUBLIC", 6, 5, 6, "Original title")
	var mediaReference *string
	var mediaValidUntil *time.Time
	if err = pool.QueryRow(
		context.Background(),
		`SELECT media_reference, media_valid_until
		 FROM saved_content_projections
		 WHERE entity_type = $1 AND entity_id = $2`,
		string(projectionState.target.EntityType()),
		projectionState.target.EntityID(),
	).Scan(&mediaReference, &mediaValidUntil); err != nil {
		t.Fatalf("read refreshed reconciliation media lease: %v", err)
	}
	if mediaReference == nil || *mediaReference != "fresh-media" ||
		mediaValidUntil == nil || !mediaValidUntil.Equal(now.Add(5*time.Minute)) {
		t.Fatalf("refreshed media = (%v, %v)", mediaReference, mediaValidUntil)
	}

	visibilityState := seedSavedReconciliationTarget(
		t, pool, domain.EntityTypeActivity, "reconcile-equal-visibility", 5,
		now.Add(-23*time.Hour), true, nil, false,
	)
	visibilityClaim := claimSavedReconciliation(t, repository, now)
	visibilityDecision := savedreconciliation.Decision{
		Kind:               savedreconciliation.DecisionResolved,
		Target:             visibilityClaim.Candidate.Key.Target,
		SourceRevision:     6,
		ProjectionRevision: 6,
		VisibilityRevision: 5,
		Visibility:         domain.VisibilityPrivate,
		ValidatedAt:        now,
	}
	visibilityResult, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(visibilityClaim, visibilityDecision, now),
	)
	if err != nil || visibilityResult.Applied.Outcome != savedreconciliation.ApplyMetadataOnly {
		t.Fatalf("Complete(equal visibility) = (%+v, %v)", visibilityResult, err)
	}
	assertSavedReconciliationProjection(t, pool, visibilityState.target, "PUBLIC", 6, 5, 5, "Original title")
}

func TestPGSavedReconciliationNoopSchedulingIsFairAndNotImmediatelyDue(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	for _, entityID := range []string{"reconcile-fair-a", "reconcile-fair-b"} {
		seedSavedReconciliationTarget(
			t, pool, domain.EntityTypeActivity, entityID, 5,
			now.Add(-24*time.Hour), true, nil, false,
		)
	}

	first := claimSavedReconciliation(t, repository, now)
	firstResult, err := repository.Complete(
		context.Background(),
		reconciliationCompletion(
			first,
			savedreconciliation.NewNoopDecision(first.Candidate.Key.Target),
			now,
		),
	)
	if err != nil || firstResult.Applied.Outcome != savedreconciliation.ApplyNoChange {
		t.Fatalf("Complete(first noop) = (%+v, %v)", firstResult, err)
	}
	second := claimSavedReconciliation(t, repository, now)
	if second.Candidate.Key.Target.EntityID() == first.Candidate.Key.Target.EntityID() {
		t.Fatalf("second claim repeated %s", first.Candidate.Key.Target.EntityID())
	}
	if _, err = repository.Complete(
		context.Background(),
		reconciliationCompletion(
			second,
			savedreconciliation.NewNoopDecision(second.Candidate.Key.Target),
			now,
		),
	); err != nil {
		t.Fatalf("Complete(second noop) error = %v", err)
	}
	hasDue, err := repository.HasDue(context.Background(), savedreconciliation.DueRequest{
		StaleAfter: time.Hour,
	})
	if err != nil || hasDue {
		t.Fatalf("HasDue() = (%t, %v), want false", hasDue, err)
	}
	var scheduled int
	if err = pool.QueryRow(
		context.Background(),
		`SELECT count(*) FROM saved_content_projections
         WHERE entity_id LIKE 'reconcile-fair-%'
		   AND reconciliation_last_attempt_at IS NOT NULL
		   AND reconciliation_next_attempt_at >=
		       reconciliation_last_attempt_at + INTERVAL '6 hours'
		   AND reconciliation_next_attempt_at <
		       reconciliation_last_attempt_at + INTERVAL '6 hours 5 seconds'`,
	).Scan(&scheduled); err != nil {
		t.Fatalf("count scheduled noop projections: %v", err)
	}
	if scheduled != 2 {
		t.Fatalf("scheduled noop projections = %d, want 2", scheduled)
	}
}

func TestPGSavedReconciliationClaimUsesDatabaseClockDespiteWorkerSkew(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	seedSavedReconciliationTarget(
		t,
		pool,
		domain.EntityTypeActivity,
		"reconcile-db-clock",
		1,
		now.Add(-24*time.Hour),
		true,
		nil,
		false,
	)

	var dbBefore, dbAfter time.Time
	if err := pool.QueryRow(context.Background(), "SELECT clock_timestamp()").Scan(&dbBefore); err != nil {
		t.Fatalf("read database clock before claim: %v", err)
	}
	workerClock := now.Add(20 * 365 * 24 * time.Hour)
	claim, found, err := repository.ClaimNext(
		context.Background(),
		reconciliationClaimRequest(workerClock),
	)
	if err != nil || !found {
		t.Fatalf("ClaimNext(skewed worker) = (%+v, %t, %v)", claim, found, err)
	}
	if err = pool.QueryRow(context.Background(), "SELECT clock_timestamp()").Scan(&dbAfter); err != nil {
		t.Fatalf("read database clock after claim: %v", err)
	}
	if claim.ClaimedAt.Before(dbBefore) || claim.ClaimedAt.After(dbAfter) ||
		claim.LeaseExpiresAt.Sub(claim.ClaimedAt) != 10*time.Second {
		t.Fatalf(
			"claim times = (%s,%s), database window = [%s,%s]",
			claim.ClaimedAt,
			claim.LeaseExpiresAt,
			dbBefore,
			dbAfter,
		)
	}
}

func TestPGSavedReconciliationCompletionLockWaitCrossingLeaseExpiryLosesFence(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	state := seedSavedReconciliationTarget(
		t,
		pool,
		domain.EntityTypeGuide,
		"reconcile-lock-wait-expiry",
		1,
		now.Add(-24*time.Hour),
		true,
		nil,
		false,
	)
	claim, found, err := repository.ClaimNext(context.Background(), savedreconciliation.ClaimRequest{
		StaleAfter:    time.Hour,
		LeaseDuration: 250 * time.Millisecond,
	})
	if err != nil || !found {
		t.Fatalf("ClaimNext() = (%+v, %t, %v)", claim, found, err)
	}

	locker, err := pool.BeginTx(context.Background(), pgx.TxOptions{})
	if err != nil {
		t.Fatalf("begin row locker: %v", err)
	}
	defer func() { _ = locker.Rollback(context.Background()) }()
	if _, err = locker.Exec(
		context.Background(),
		`SELECT 1 FROM saved_content_projections
		 WHERE entity_type = $1 AND entity_id = $2
		 FOR UPDATE`,
		string(state.target.EntityType()),
		state.target.EntityID(),
	); err != nil {
		t.Fatalf("lock projection row: %v", err)
	}

	resultCh := make(chan savedreconciliation.CompletionResult, 1)
	errCh := make(chan error, 1)
	go func() {
		result, completeErr := repository.Complete(
			context.Background(),
			savedreconciliation.CompletionRequest{
				Claim:            claim,
				Decision:         savedreconciliation.NewNoopDecision(claim.Candidate.Key.Target),
				NextAttemptDelay: time.Hour,
			},
		)
		resultCh <- result
		errCh <- completeErr
	}()
	time.Sleep(400 * time.Millisecond)
	if err = locker.Commit(context.Background()); err != nil {
		t.Fatalf("release projection row lock: %v", err)
	}
	result := <-resultCh
	if err = <-errCh; err != nil || !result.LeaseLost ||
		result.Applied.Outcome != savedreconciliation.ApplyStale {
		t.Fatalf("Complete(after lease expired while waiting) = (%+v, %v)", result, err)
	}
}

func TestPGSavedReconciliationNeverValidatedFairnessUsesCreatedAt(t *testing.T) {
	pool, repository := openSavedReconciliationIntegration(t)
	now := time.Now().UTC().Truncate(time.Microsecond)
	seedNeverValidatedSavedReconciliationTarget(
		t,
		pool,
		"a-newer-by-entity-order",
		now.Add(-time.Hour),
	)
	older := seedNeverValidatedSavedReconciliationTarget(
		t,
		pool,
		"z-older-by-created-at",
		now.Add(-2*time.Hour),
	)

	claim, found, err := repository.ClaimNext(
		context.Background(),
		savedreconciliation.ClaimRequest{StaleAfter: time.Hour, LeaseDuration: time.Second},
	)
	if err != nil || !found {
		t.Fatalf("ClaimNext() = (%+v, %t, %v)", claim, found, err)
	}
	if claim.Candidate.Key.Target.EntityID() != older.EntityID() {
		t.Fatalf(
			"claimed %q, want oldest created_at target %q",
			claim.Candidate.Key.Target.EntityID(),
			older.EntityID(),
		)
	}
}

func reconciliationClaimRequest(now time.Time) savedreconciliation.ClaimRequest {
	_ = now
	return savedreconciliation.ClaimRequest{
		StaleAfter:    time.Hour,
		LeaseDuration: 10 * time.Second,
	}
}

func claimSavedReconciliation(
	t testing.TB,
	repository *PGSavedReconciliationRepository,
	now time.Time,
) savedreconciliation.Claim {
	t.Helper()
	claim, found, err := repository.ClaimNext(
		context.Background(),
		reconciliationClaimRequest(now),
	)
	if err != nil || !found {
		t.Fatalf("ClaimNext() = (%+v, %t, %v)", claim, found, err)
	}
	return claim
}

func reconciliationCompletion(
	claim savedreconciliation.Claim,
	decision savedreconciliation.Decision,
	now time.Time,
) savedreconciliation.CompletionRequest {
	_ = now
	return savedreconciliation.CompletionRequest{
		Claim:            claim,
		Decision:         decision,
		NextAttemptDelay: 6 * time.Hour,
	}
}

type savedReconciliationSeedState struct {
	target                domain.SavedTarget
	owner                 uuid.UUID
	savedItemID           uuid.UUID
	savedAt               time.Time
	relationshipVersion   int64
	membershipVersion     int64
	collectionOrganizedAt time.Time
}

func openSavedReconciliationIntegration(
	t *testing.T,
) (*pgxpool.Pool, *PGSavedReconciliationRepository) {
	t.Helper()
	pool, _ := openSavedLifecycleIntegration(t)
	up006a := readSavedLifecycleMigration(t, "006a_saved_reconciliation_scheduler_index.up.sql")
	down006a := readSavedLifecycleMigration(t, "006a_saved_reconciliation_scheduler_index.down.sql")
	if _, err := pool.Exec(context.Background(), up006a); err != nil {
		t.Fatalf("apply reconciliation scheduler index: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if _, err := pool.Exec(cleanupCtx, down006a); err != nil {
			t.Errorf("rollback reconciliation scheduler index: %v", err)
		}
	})
	repository, err := NewPGSavedReconciliationRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedReconciliationRepository() error = %v", err)
	}
	return pool, repository
}

func seedSavedReconciliationTarget(
	t testing.TB,
	pool *pgxpool.Pool,
	entityType domain.EntityType,
	entityID string,
	revision int64,
	validatedAt time.Time,
	activeReference bool,
	gcCandidateAt *time.Time,
	withCollection bool,
) savedReconciliationSeedState {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, entityID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	sourceService := "guide-service"
	switch entityType {
	case domain.EntityTypeActivity:
		sourceService = "activity-service"
	case domain.EntityTypeAttraction:
		sourceService = "place-service"
	}
	createdAt := validatedAt.Add(-time.Hour)
	_, err = pool.Exec(
		context.Background(),
		`INSERT INTO saved_content_projections (
             entity_type, entity_id, source_service,
             source_revision, projection_revision, visibility_revision,
             visibility_status, visibility_validated_at,
             source_default_locale, title_en,
             search_document_version, normalized_search_document_en,
             ever_referenced, gc_candidate_at, created_at, updated_at
         ) VALUES (
             $1, $2, $3, $4, $4, $4, 'PUBLIC', $5,
             'EN', 'Original title', $4, 'original title',
             TRUE, $6, $7, $7
         )`,
		string(entityType), entityID, sourceService, revision,
		validatedAt.UTC(), gcCandidateAt, createdAt.UTC(),
	)
	if err != nil {
		t.Fatalf("insert reconciliation projection: %v", err)
	}
	state := savedReconciliationSeedState{target: target}
	if !activeReference {
		return state
	}
	state.owner = uuid.New()
	state.savedItemID = uuid.New()
	state.savedAt = validatedAt.Add(30 * time.Minute)
	state.relationshipVersion = 7
	_, err = pool.Exec(
		context.Background(),
		`INSERT INTO saved_items (
             id, owner_user_id, entity_type, entity_id, relationship_state,
             state_generation, relationship_attribution_id,
             relationship_version, dependent_membership_version,
             saved_at, created_at, updated_at
         ) VALUES ($1, $2, $3, $4, 'ACTIVE', $5, $6, $7, 3, $8, $8, $8)`,
		state.savedItemID,
		state.owner,
		string(entityType),
		entityID,
		uuid.New(),
		uuid.New(),
		state.relationshipVersion,
		state.savedAt.UTC(),
	)
	if err != nil {
		t.Fatalf("insert reconciliation saved item: %v", err)
	}
	if !withCollection {
		return state
	}
	collectionID := uuid.New()
	state.collectionOrganizedAt = state.savedAt.Add(time.Hour)
	state.membershipVersion = 4
	_, err = pool.Exec(
		context.Background(),
		`INSERT INTO saved_collections (
             id, owner_user_id, client_creation_id, title, normalized_title_key,
             lifecycle_state, lifecycle_version, metadata_version,
             items_version, active_item_count,
             created_at, organized_at, updated_at
         ) VALUES ($1, $2, $3, 'Trip', 'trip', 'ACTIVE', 2, 3, 5, 1, $4, $4, $4)`,
		collectionID,
		state.owner,
		uuid.New(),
		state.collectionOrganizedAt.UTC(),
	)
	if err != nil {
		t.Fatalf("insert reconciliation collection: %v", err)
	}
	_, err = pool.Exec(
		context.Background(),
		`INSERT INTO saved_collection_items (
             id, owner_user_id, collection_id, saved_item_id,
             membership_state, membership_version, saved_at_snapshot,
             added_at, updated_at
         ) VALUES ($1, $2, $3, $4, 'ACTIVE', $5, $6, $7, $7)`,
		uuid.New(),
		state.owner,
		collectionID,
		state.savedItemID,
		state.membershipVersion,
		state.savedAt.UTC(),
		state.collectionOrganizedAt.UTC(),
	)
	if err != nil {
		t.Fatalf("insert reconciliation collection item: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if _, cleanupErr := pool.Exec(
			cleanupCtx,
			"DELETE FROM saved_collection_items WHERE owner_user_id = $1 AND collection_id = $2",
			state.owner,
			collectionID,
		); cleanupErr != nil {
			t.Errorf("delete reconciliation collection items: %v", cleanupErr)
			return
		}
		if _, cleanupErr := pool.Exec(
			cleanupCtx,
			"DELETE FROM saved_collections WHERE owner_user_id = $1 AND id = $2",
			state.owner,
			collectionID,
		); cleanupErr != nil {
			t.Errorf("delete reconciliation collection: %v", cleanupErr)
		}
	})
	return state
}

func seedSavedReconciliationEphemeral(
	t testing.TB,
	pool *pgxpool.Pool,
	entityID string,
	now time.Time,
) {
	t.Helper()
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, entityID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	seedLifecycleProjectionShell(
		t,
		pool,
		target,
		"activity-service",
		now.Add(-10*time.Minute),
	)
}

func seedNeverValidatedSavedReconciliationTarget(
	t testing.TB,
	pool *pgxpool.Pool,
	entityID string,
	createdAt time.Time,
) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(domain.EntityTypeGuide, entityID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	_, err = pool.Exec(
		context.Background(),
		`INSERT INTO saved_content_projections (
		     entity_type, entity_id, source_service,
		     visibility_status, visibility_validated_at,
		     ever_referenced, created_at, updated_at
		 ) VALUES ($1, $2, 'guide-service', 'UNKNOWN', NULL, TRUE, $3, $3)`,
		string(target.EntityType()),
		target.EntityID(),
		createdAt.UTC(),
	)
	if err != nil {
		t.Fatalf("insert never-validated projection: %v", err)
	}
	owner := uuid.New()
	savedItemID := uuid.New()
	_, err = pool.Exec(
		context.Background(),
		`INSERT INTO saved_items (
		     id, owner_user_id, entity_type, entity_id, relationship_state,
		     state_generation, relationship_attribution_id,
		     relationship_version, dependent_membership_version,
		     saved_at, created_at, updated_at
		 ) VALUES ($1, $2, $3, $4, 'ACTIVE', $5, $6, 1, 0, $7, $7, $7)`,
		savedItemID,
		owner,
		string(target.EntityType()),
		target.EntityID(),
		uuid.New(),
		uuid.New(),
		createdAt.UTC(),
	)
	if err != nil {
		t.Fatalf("insert never-validated saved item: %v", err)
	}
	return target
}

func repositoryPublicResolution(
	target domain.SavedTarget,
	now time.Time,
	revision uint64,
	title string,
) appsource.Resolution {
	return appsource.Resolution{
		Target:     target,
		Eligible:   true,
		Visibility: domain.VisibilityPublic,
		Revisions: appsource.Revisions{
			Source: revision, Projection: revision, Visibility: revision,
		},
		ValidatedAt: now,
		PublicProjection: &appsource.PublicCardProjection{
			SourceDefaultLocale: appsource.LocaleEN,
			Localized: map[appsource.Locale]appsource.LocalizedCardProjection{
				appsource.LocaleEN: {Title: title},
			},
		},
	}
}

func assertSavedReconciliationProjection(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	visibility string,
	sourceRevision, projectionRevision, visibilityRevision int64,
	title string,
) {
	t.Helper()
	var actualVisibility string
	var actualSource, actualProjection, actualVisibilityRevision int64
	var actualTitle, actualSearchTitle *string
	err := pool.QueryRow(
		context.Background(),
		`SELECT visibility_status, source_revision, projection_revision,
		        visibility_revision, title_en, search_title_en_v1
         FROM saved_content_projections
         WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID(),
	).Scan(
		&actualVisibility,
		&actualSource,
		&actualProjection,
		&actualVisibilityRevision,
		&actualTitle,
		&actualSearchTitle,
	)
	if err != nil {
		t.Fatalf("read reconciliation projection: %v", err)
	}
	if actualVisibility != visibility || actualSource != sourceRevision ||
		actualProjection != projectionRevision ||
		actualVisibilityRevision != visibilityRevision {
		t.Fatalf(
			"projection = (%s,%d,%d,%d), want (%s,%d,%d,%d)",
			actualVisibility,
			actualSource,
			actualProjection,
			actualVisibilityRevision,
			visibility,
			sourceRevision,
			projectionRevision,
			visibilityRevision,
		)
	}
	if title == "" && actualTitle != nil {
		t.Fatalf("title = %q, want NULL", *actualTitle)
	}
	if title == "" && actualSearchTitle != nil {
		t.Fatalf("search title = %q, want NULL", *actualSearchTitle)
	}
	if title != "" && (actualTitle == nil || *actualTitle != title) {
		t.Fatalf("title = %v, want %q", actualTitle, title)
	}
	if title != "" && (actualSearchTitle == nil || *actualSearchTitle != strings.ToLower(title)) {
		t.Fatalf("search title = %v, want %q", actualSearchTitle, strings.ToLower(title))
	}
}

func assertSavedReconciliationPayloadCleared(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
) {
	t.Helper()
	var payloadColumns int
	err := pool.QueryRow(
		context.Background(),
		`SELECT num_nonnulls(
             source_default_locale, title_en, title_ru, title_kk,
             normalized_search_document_en, normalized_search_document_ru,
             normalized_search_document_kk, media_reference,
             canonical_detail_route
         )
         FROM saved_content_projections
         WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID(),
	).Scan(&payloadColumns)
	if err != nil {
		t.Fatalf("read reconciliation payload: %v", err)
	}
	if payloadColumns != 0 {
		t.Fatalf("non-null public payload columns = %d", payloadColumns)
	}
}

func assertSavedReconciliationFailClosed(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	want bool,
) {
	t.Helper()
	var failClosed bool
	var reason *string
	err := pool.QueryRow(
		context.Background(),
		`SELECT reconciliation_fail_closed_at IS NOT NULL,
		        reconciliation_fail_closed_reason
		 FROM saved_content_projections
		 WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()),
		target.EntityID(),
	).Scan(&failClosed, &reason)
	if err != nil {
		t.Fatalf("read reconciliation fail-closed state: %v", err)
	}
	if failClosed != want || (want && (reason == nil || *reason != "UNVERSIONED_NOT_FOUND")) ||
		(!want && reason != nil) {
		t.Fatalf("fail-closed state = (%t,%v), want %t", failClosed, reason, want)
	}
}

func assertSavedReconciliationUserStateUnchanged(
	t testing.TB,
	pool *pgxpool.Pool,
	state savedReconciliationSeedState,
) {
	t.Helper()
	var savedAt time.Time
	var relationshipVersion, dependentMembershipVersion int64
	err := pool.QueryRow(
		context.Background(),
		`SELECT saved_at, relationship_version, dependent_membership_version
         FROM saved_items WHERE owner_user_id = $1 AND id = $2`,
		state.owner,
		state.savedItemID,
	).Scan(&savedAt, &relationshipVersion, &dependentMembershipVersion)
	if err != nil {
		t.Fatalf("read saved relationship: %v", err)
	}
	if !savedAt.Equal(state.savedAt) || relationshipVersion != state.relationshipVersion ||
		dependentMembershipVersion != 3 {
		t.Fatalf(
			"saved relationship changed: saved_at=%s relationship=%d dependent=%d",
			savedAt,
			relationshipVersion,
			dependentMembershipVersion,
		)
	}
	var organizedAt, addedAt time.Time
	var membershipVersion int64
	err = pool.QueryRow(
		context.Background(),
		`SELECT collection.organized_at, item.added_at, item.membership_version
         FROM saved_collection_items AS item
         JOIN saved_collections AS collection
           ON collection.owner_user_id = item.owner_user_id
          AND collection.id = item.collection_id
         WHERE item.owner_user_id = $1 AND item.saved_item_id = $2`,
		state.owner,
		state.savedItemID,
	).Scan(&organizedAt, &addedAt, &membershipVersion)
	if err != nil {
		t.Fatalf("read collection relationship: %v", err)
	}
	if !organizedAt.Equal(state.collectionOrganizedAt) ||
		!addedAt.Equal(state.collectionOrganizedAt) ||
		membershipVersion != state.membershipVersion {
		t.Fatalf(
			"collection state changed: organized=%s added=%s membership=%d",
			organizedAt,
			addedAt,
			membershipVersion,
		)
	}
}
