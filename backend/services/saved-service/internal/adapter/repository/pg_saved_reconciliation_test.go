package repository

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	savedreconciliation "kz/inflap/backend/services/saved-service/internal/app/savedreconciliation"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedReconciliationRollbackUsesIndependentBoundedContext(t *testing.T) {
	t.Parallel()

	parent, cancelParent := context.WithCancel(context.Background())
	cancelParent()
	tx := &rollbackContextTx{}
	rollbackSavedReconciliationTx(parent, tx)

	if tx.contextErr != nil {
		t.Fatalf("rollback context error at call = %v, want nil", tx.contextErr)
	}
	if !tx.deadlinePresent || tx.remaining <= 0 ||
		tx.remaining > savedReconciliationRollbackTimeout {
		t.Fatalf(
			"rollback deadline = (present=%t, remaining=%s), want bounded by %s",
			tx.deadlinePresent,
			tx.remaining,
			savedReconciliationRollbackTimeout,
		)
	}
}

func TestSavedReconciliationCommitFailureIsClassifiedAsUnknown(t *testing.T) {
	t.Parallel()

	tx := &commitErrorTx{err: errors.New("connection lost after COMMIT")}
	err := commitSavedReconciliationTx(context.Background(), tx)
	if !errors.Is(err, savedreconciliation.ErrCommitOutcomeUnknown) {
		t.Fatalf("commitSavedReconciliationTx() error = %v", err)
	}
}

func TestSavedReconciliationSQLUsesShortFairClaimsAndSnapshotCAS(t *testing.T) {
	for _, required := range []string{
		"set_config('statement_timeout', '5s', TRUE)",
		"set_config('lock_timeout', '1s', TRUE)",
		"set_config('idle_in_transaction_session_timeout', '10s', TRUE)",
	} {
		if !strings.Contains(configureSavedReconciliationTxSQL, required) {
			t.Errorf("transaction config does not contain %q", required)
		}
	}
	claimUpper := strings.ToUpper(claimSavedReconciliationSQL)
	for _, required := range []string{
		"CANDIDATE AS",
		"LIMIT 1",
		"FOR UPDATE OF PROJECTION SKIP LOCKED",
		"RECONCILIATION_NEXT_ATTEMPT_AT",
		"GREATEST(",
		"CLOCK_TIMESTAMP()",
		"PROJECTION.CREATED_AT",
		"RECONCILIATION_LAST_ATTEMPT_AT",
		"RECONCILIATION_LEASE_EXPIRES_AT <= DB_CLOCK.CLAIMED_AT",
		"RECONCILIATION_QUARANTINED_AT IS NULL",
		"GC_CANDIDATE_AT IS NULL",
		"RELATIONSHIP_STATE = 'ACTIVE'",
		"ENTITY_TYPE IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')",
		"UPDATE SAVED_CONTENT_PROJECTIONS",
	} {
		if !strings.Contains(claimUpper, required) {
			t.Errorf("claim query does not contain %q", required)
		}
	}
	if strings.Contains(claimUpper, "INSERT") {
		t.Fatal("claim query can materialize an unknown target")
	}
	if strings.Contains(claimUpper, "-INFINITY") {
		t.Fatal("claim query ranks never-validated rows ahead of persisted created_at")
	}
	if !strings.Contains(strings.ToUpper(hasDueSavedReconciliationSQL), "CLOCK_TIMESTAMP()") {
		t.Fatal("HasDue query does not use the PostgreSQL clock")
	}
	for name, query := range map[string]string{
		"noop":            completeSavedReconciliationNoopSQL,
		"metadata":        updateSavedReconciliationMetadataSQL,
		"public_metadata": refreshSavedReconciliationPublicMetadataSQL,
		"public":          applySavedReconciliationPublicSQL,
		"deny":            applySavedReconciliationDenySQL,
		"fail_closed":     applySavedReconciliationFailClosedSQL,
		"failure":         completeSavedReconciliationFailureSQL,
	} {
		upper := strings.ToUpper(query)
		for _, required := range []string{
			"RECONCILIATION_LEASE_TOKEN = @LEASE_TOKEN",
			"RECONCILIATION_LEASE_EXPIRES_AT > CLOCK_TIMESTAMP()",
			"SOURCE_REVISION = @EXPECTED_SOURCE_REVISION",
			"PROJECTION_REVISION = @EXPECTED_PROJECTION_REVISION",
			"VISIBILITY_REVISION = @EXPECTED_VISIBILITY_REVISION",
			"VISIBILITY_STATUS = @EXPECTED_VISIBILITY",
			"VISIBILITY_VALIDATED_AT IS NOT DISTINCT FROM @EXPECTED_VISIBILITY_VALIDATED_AT",
			"RECONCILIATION_FAIL_CLOSED_AT IS NOT DISTINCT FROM @EXPECTED_FAIL_CLOSED_AT",
			"RECONCILIATION_FAILURE_KIND IS NOT DISTINCT FROM @EXPECTED_FAILURE_KIND",
		} {
			if !strings.Contains(upper, required) {
				t.Errorf("%s completion query does not contain CAS fragment %q", name, required)
			}
		}
		if strings.Contains(upper, "@COMPLETED_AT") ||
			!strings.Contains(upper, "INTERVAL '1 MICROSECOND'") {
			t.Errorf("%s completion query uses worker time or lacks interval scheduling", name)
		}
	}
	if !strings.Contains(strings.ToUpper(releaseLostSavedReconciliationLeaseSQL), "CLOCK_TIMESTAMP()") {
		t.Fatal("lost-lease release scheduling does not use the PostgreSQL clock")
	}
}

type rollbackContextTx struct {
	pgx.Tx
	contextErr      error
	deadlinePresent bool
	remaining       time.Duration
}

func (tx *rollbackContextTx) Rollback(ctx context.Context) error {
	tx.contextErr = ctx.Err()
	deadline, present := ctx.Deadline()
	tx.deadlinePresent = present
	if present {
		tx.remaining = time.Until(deadline)
	}
	return nil
}

type commitErrorTx struct {
	pgx.Tx
	err error
}

func (tx *commitErrorTx) Commit(context.Context) error {
	return tx.err
}

func TestSavedReconciliationUpdatesCannotTouchRelationshipOrGCLifecycle(t *testing.T) {
	for name, query := range map[string]string{
		"noop":            completeSavedReconciliationNoopSQL,
		"metadata":        updateSavedReconciliationMetadataSQL,
		"public_metadata": refreshSavedReconciliationPublicMetadataSQL,
		"public":          applySavedReconciliationPublicSQL,
		"deny":            applySavedReconciliationDenySQL,
		"fail_closed":     applySavedReconciliationFailClosedSQL,
		"failure":         completeSavedReconciliationFailureSQL,
	} {
		lower := strings.ToLower(query)
		setClause := strings.SplitN(lower, "where", 2)[0]
		for _, forbidden := range []string{
			"saved_at",
			"organized_at",
			"relationship_version",
			"membership_version",
			"gc_candidate_at",
			"shell_expires_at",
			"saved_items",
			"saved_collection_items",
		} {
			if strings.Contains(setClause, forbidden) {
				t.Errorf("%s update contains forbidden field/table %q", name, forbidden)
			}
		}
	}
}

func TestSavedReconciliationUnversionedNotFoundPreservesSourceVisibilityState(t *testing.T) {
	t.Parallel()

	setClause := strings.SplitN(
		strings.ToLower(applySavedReconciliationFailClosedSQL),
		"where",
		2,
	)[0]
	for _, forbidden := range []string{
		"source_revision =",
		"projection_revision =",
		"visibility_revision =",
		"visibility_status =",
		"visibility_validated_at =",
	} {
		if strings.Contains(setClause, forbidden) {
			t.Errorf("local fail-closed update mutates source-owned field %q", forbidden)
		}
	}
	for _, required := range []string{
		"reconciliation_fail_closed_at = clock_timestamp()",
		"reconciliation_fail_closed_reason = 'unversioned_not_found'",
		"title_en = null",
		"normalized_search_document_en = null",
		"media_reference = null",
		"canonical_detail_route = null",
	} {
		if !strings.Contains(setClause, required) {
			t.Errorf("local fail-closed update is missing %q", required)
		}
	}
}

func TestSavedProjectionReadsEnforceLocalFailClosedState(t *testing.T) {
	t.Parallel()

	for name, query := range map[string]string{
		"list":   savedItemsListSelectSQL,
		"status": savedTargetStatusesSQL,
		"search": savedSearchSelectSQL,
		"cover":  savedCollectionReadSelectSQL,
	} {
		if !strings.Contains(strings.ToLower(query), "reconciliation_fail_closed_at") {
			t.Errorf("%s query does not enforce local fail-closed state", name)
		}
	}
}

func TestDecideSavedReconciliationMutationEqualVisibilityRevisionPreservesStatus(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, "equal-visibility")
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	oldValidatedAt := now.Add(-24 * time.Hour)
	candidate := savedreconciliation.Candidate{
		Key: savedreconciliation.CandidateKey{
			VisibilityValidatedAt: &oldValidatedAt,
			Target:                target,
		},
		SourceService:      "activity-service",
		SourceRevision:     5,
		ProjectionRevision: 5,
		VisibilityRevision: 5,
		Visibility:         domain.VisibilityPublic,
	}
	decision := savedreconciliation.Decision{
		Kind:               savedreconciliation.DecisionResolved,
		Target:             target,
		SourceRevision:     6,
		ProjectionRevision: 6,
		VisibilityRevision: 5,
		Visibility:         domain.VisibilityPrivate,
		ValidatedAt:        now,
	}
	if err = decision.Validate(target); err != nil {
		t.Fatalf("Decision.Validate() error = %v", err)
	}

	mutation, err := decideSavedReconciliationMutation(candidate, decision)
	if err != nil {
		t.Fatalf("decideSavedReconciliationMutation() error = %v", err)
	}
	if mutation.visibility != domain.VisibilityPublic || mutation.visibilityRevision != 5 ||
		mutation.kind != savedReconciliationMetadata || mutation.result.Outcome != savedreconciliation.ApplyMetadataOnly ||
		mutation.result.PayloadCleared {
		t.Fatalf("mutation = %+v", mutation)
	}
}

func TestDecideSavedReconciliationMutationEqualProjectionRevisionRefreshesMediaLease(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, "equal-projection")
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	oldValidatedAt := now.Add(-24 * time.Hour)
	candidate := savedreconciliation.Candidate{
		Key: savedreconciliation.CandidateKey{
			VisibilityValidatedAt: &oldValidatedAt,
			Target:                target,
		},
		SourceService:      "activity-service",
		SourceRevision:     5,
		ProjectionRevision: 5,
		VisibilityRevision: 5,
		Visibility:         domain.VisibilityPublic,
	}
	resolution := repositoryPublicResolution(target, now, 5, "must not replace payload")
	resolution.Revisions.Source = 6
	resolution.Revisions.Visibility = 6
	decision, err := savedreconciliation.BuildResolvedDecision(resolution, now)
	if err != nil {
		t.Fatalf("BuildResolvedDecision() error = %v", err)
	}

	mutation, err := decideSavedReconciliationMutation(candidate, decision)
	if err != nil {
		t.Fatalf("decideSavedReconciliationMutation() error = %v", err)
	}
	if mutation.kind != savedReconciliationPublicMetadata || mutation.publicProjection == nil ||
		mutation.projectionRevision != 5 || mutation.result.ProjectionAdvanced ||
		mutation.result.Outcome != savedreconciliation.ApplyMetadataOnly {
		t.Fatalf("mutation = %+v", mutation)
	}
}

func TestDecideSavedReconciliationMutationRehydratesEqualProjectionAfterDeny(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, "deny-public-recovery")
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	validatedAt := now.Add(-time.Hour)
	candidate := savedreconciliation.Candidate{
		Key: savedreconciliation.CandidateKey{
			VisibilityValidatedAt: &validatedAt,
			Target:                target,
		},
		SourceService:      "activity-service",
		SourceRevision:     6,
		ProjectionRevision: 5,
		VisibilityRevision: 6,
		Visibility:         domain.VisibilityPrivate,
	}
	resolution := repositoryPublicResolution(target, now, 5, "rehydrated payload")
	resolution.Revisions.Source = 7
	resolution.Revisions.Visibility = 7
	decision, err := savedreconciliation.BuildResolvedDecision(resolution, now)
	if err != nil {
		t.Fatalf("BuildResolvedDecision() error = %v", err)
	}

	mutation, err := decideSavedReconciliationMutation(candidate, decision)
	if err != nil {
		t.Fatalf("decideSavedReconciliationMutation() error = %v", err)
	}
	if mutation.kind != savedReconciliationPublic || mutation.projectionRevision != 5 ||
		mutation.result.ProjectionAdvanced || !mutation.result.VisibilityAdvanced ||
		mutation.visibility != domain.VisibilityPublic || mutation.publicProjection == nil {
		t.Fatalf("mutation = %+v", mutation)
	}
}

func TestDecideSavedReconciliationMutationDoesNotRehydrateEqualFailClosedSnapshot(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	validatedAt := now.Add(-time.Hour)
	failClosedAt := now.Add(-time.Minute)
	candidate := savedreconciliation.Candidate{
		Key: savedreconciliation.CandidateKey{
			VisibilityValidatedAt: &validatedAt,
			Target:                target,
		},
		SourceService:      "user-service",
		SourceRevision:     7,
		ProjectionRevision: 7,
		VisibilityRevision: 7,
		Visibility:         domain.VisibilityPublic,
		FailClosedAt:       &failClosedAt,
	}
	decision := reconciliationPublicDecision(t, target, now, 7, "equal recovery")

	mutation, err := decideSavedReconciliationMutation(candidate, decision)
	if err != nil {
		t.Fatalf("decideSavedReconciliationMutation() error = %v", err)
	}
	if mutation.kind != savedReconciliationMetadata || mutation.result.ProjectionAdvanced ||
		mutation.result.VisibilityAdvanced || mutation.publicProjection != nil ||
		mutation.result.Outcome != savedreconciliation.ApplyMetadataOnly {
		t.Fatalf("mutation = %+v", mutation)
	}
}

func TestDecideSavedReconciliationMutationRehydratesFailClosedWithVisibilityAdvance(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	validatedAt := now.Add(-time.Hour)
	failClosedAt := now.Add(-time.Minute)
	candidate := savedreconciliation.Candidate{
		Key: savedreconciliation.CandidateKey{
			VisibilityValidatedAt: &validatedAt,
			Target:                target,
		},
		SourceService:      "user-service",
		SourceRevision:     7,
		ProjectionRevision: 7,
		VisibilityRevision: 7,
		Visibility:         domain.VisibilityPublic,
		FailClosedAt:       &failClosedAt,
	}
	resolution := repositoryPublicResolution(target, now, 7, "visibility recovery")
	resolution.Revisions.Source = 8
	resolution.Revisions.Visibility = 8
	decision, err := savedreconciliation.BuildResolvedDecision(resolution, now)
	if err != nil {
		t.Fatalf("BuildResolvedDecision() error = %v", err)
	}

	mutation, err := decideSavedReconciliationMutation(candidate, decision)
	if err != nil {
		t.Fatalf("decideSavedReconciliationMutation() error = %v", err)
	}
	if mutation.kind != savedReconciliationPublic || mutation.result.ProjectionAdvanced ||
		!mutation.result.VisibilityAdvanced || mutation.publicProjection == nil ||
		mutation.result.Outcome != savedreconciliation.ApplyPublic {
		t.Fatalf("mutation = %+v", mutation)
	}
}

func TestDecideSavedReconciliationMutationRejectsStalePublicSnapshot(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, "stale-activity")
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	oldValidatedAt := now.Add(-24 * time.Hour)
	candidate := savedreconciliation.Candidate{
		Key: savedreconciliation.CandidateKey{
			VisibilityValidatedAt: &oldValidatedAt,
			Target:                target,
		},
		SourceService:      "activity-service",
		SourceRevision:     10,
		ProjectionRevision: 10,
		VisibilityRevision: 10,
		Visibility:         domain.VisibilityPublic,
	}
	decision := savedreconciliation.Decision{
		Kind:               savedreconciliation.DecisionResolved,
		Target:             target,
		SourceRevision:     9,
		ProjectionRevision: 9,
		VisibilityRevision: 9,
		Visibility:         domain.VisibilityPublic,
		ValidatedAt:        now,
	}
	// The decision shape is intentionally completed with a snapshot only to
	// exercise the repository's monotonic decision independently of source IO.
	public := reconciliationPublicDecision(t, target, now, 9, "stale title")
	decision.PublicProjection = public.PublicProjection

	mutation, err := decideSavedReconciliationMutation(candidate, decision)
	if err != nil {
		t.Fatalf("decideSavedReconciliationMutation() error = %v", err)
	}
	if mutation.kind != savedReconciliationNoop ||
		mutation.result.Outcome != savedreconciliation.ApplyStale {
		t.Fatalf("mutation = %+v", mutation)
	}
}

func TestDecideSavedReconciliationMutationAdvancesIndependentComponentsMonotonically(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, "independent-revisions")
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	oldValidatedAt := now.Add(-24 * time.Hour)
	candidate := savedreconciliation.Candidate{
		Key: savedreconciliation.CandidateKey{
			VisibilityValidatedAt: &oldValidatedAt,
			Target:                target,
		},
		SourceService:      "activity-service",
		SourceRevision:     10,
		ProjectionRevision: 5,
		VisibilityRevision: 5,
		Visibility:         domain.VisibilityPublic,
	}
	resolution := repositoryPublicResolution(target, now, 6, "new projection")
	resolution.Revisions.Source = 9
	decision, err := savedreconciliation.BuildResolvedDecision(resolution, now)
	if err != nil {
		t.Fatalf("BuildResolvedDecision() error = %v", err)
	}

	mutation, err := decideSavedReconciliationMutation(candidate, decision)
	if err != nil {
		t.Fatalf("decideSavedReconciliationMutation() error = %v", err)
	}
	if mutation.kind != savedReconciliationPublic || mutation.sourceRevision != 10 ||
		mutation.projectionRevision != 6 || mutation.visibilityRevision != 6 ||
		mutation.result.SourceAdvanced || !mutation.result.ProjectionAdvanced ||
		!mutation.result.VisibilityAdvanced {
		t.Fatalf("mutation = %+v", mutation)
	}
}

func TestDecideSavedReconciliationMutationAppliesDeletedDeny(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	oldValidatedAt := now.Add(-24 * time.Hour)
	candidate := savedreconciliation.Candidate{
		Key: savedreconciliation.CandidateKey{
			VisibilityValidatedAt: &oldValidatedAt,
			Target:                target,
		},
		SourceService:      "user-service",
		SourceRevision:     3,
		ProjectionRevision: 3,
		VisibilityRevision: 3,
		Visibility:         domain.VisibilityPublic,
	}
	decision := savedreconciliation.Decision{
		Kind:               savedreconciliation.DecisionResolved,
		Target:             target,
		SourceRevision:     4,
		ProjectionRevision: 4,
		VisibilityRevision: 4,
		Visibility:         domain.VisibilityDeleted,
		ValidatedAt:        now,
	}
	if err = decision.Validate(target); err != nil {
		t.Fatalf("Decision.Validate() error = %v", err)
	}

	mutation, err := decideSavedReconciliationMutation(candidate, decision)
	if err != nil {
		t.Fatalf("decideSavedReconciliationMutation() error = %v", err)
	}
	if mutation.kind != savedReconciliationDeny ||
		mutation.visibility != domain.VisibilityDeleted ||
		!mutation.result.PayloadCleared {
		t.Fatalf("mutation = %+v", mutation)
	}
}

func reconciliationPublicDecision(
	t testing.TB,
	target domain.SavedTarget,
	now time.Time,
	revision uint64,
	title string,
) savedreconciliation.Decision {
	t.Helper()
	resolution := repositoryPublicResolution(target, now, revision, title)
	decision, err := savedreconciliation.BuildResolvedDecision(resolution, now)
	if err != nil {
		t.Fatalf("BuildResolvedDecision() error = %v", err)
	}
	return decision
}
