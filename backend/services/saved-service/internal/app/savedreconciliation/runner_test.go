package savedreconciliation

import (
	"context"
	"errors"
	"reflect"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"

	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type reconciliationResolverFunc func(
	context.Context,
	domain.SavedTarget,
) (appsource.Resolution, error)

func (function reconciliationResolverFunc) Resolve(
	ctx context.Context,
	target domain.SavedTarget,
) (appsource.Resolution, error) {
	return function(ctx, target)
}

type reconciliationRepositoryStub struct {
	mu                       sync.Mutex
	claims                   []Claim
	next                     int
	claimFailuresBefore      int
	completionFailuresBefore int
	completionError          error
	hasDue                   bool
	claimRequests            []ClaimRequest
	completions              []CompletionRequest
	hasDueRequests           []DueRequest
}

func (r *reconciliationRepositoryStub) ClaimNext(
	_ context.Context,
	request ClaimRequest,
) (Claim, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.claimRequests = append(r.claimRequests, request)
	if r.claimFailuresBefore > 0 {
		r.claimFailuresBefore--
		return Claim{}, false, ErrRepositoryUnavailable
	}
	if r.next >= len(r.claims) {
		return Claim{}, false, nil
	}
	claim := r.claims[r.next]
	r.next++
	return claim, true, nil
}

func (r *reconciliationRepositoryStub) Complete(
	_ context.Context,
	request CompletionRequest,
) (CompletionResult, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.completions = append(r.completions, request)
	if r.completionFailuresBefore > 0 {
		r.completionFailuresBefore--
		return CompletionResult{}, ErrRepositoryUnavailable
	}
	if r.completionError != nil {
		return CompletionResult{}, r.completionError
	}
	if request.Failure != CompletionFailureNone {
		return CompletionResult{
			Applied:        ApplyResult{Outcome: ApplyNoChange},
			RetryScheduled: !request.Quarantine,
			Quarantined:    request.Quarantine,
		}, nil
	}
	candidate := request.Claim.Candidate
	applied := ApplyResult{Outcome: ApplyNoChange}
	switch request.Decision.Kind {
	case DecisionResolved:
		if request.Decision.Visibility == domain.VisibilityPublic {
			if request.Decision.ProjectionRevision > candidate.ProjectionRevision {
				applied = ApplyResult{
					Outcome:            ApplyPublic,
					SourceAdvanced:     request.Decision.SourceRevision > candidate.SourceRevision,
					ProjectionAdvanced: true,
					VisibilityAdvanced: request.Decision.VisibilityRevision > candidate.VisibilityRevision,
				}
			} else {
				applied = ApplyResult{Outcome: ApplyMetadataOnly}
			}
		} else {
			applied = ApplyResult{
				Outcome:            ApplyDeny,
				SourceAdvanced:     request.Decision.SourceRevision > candidate.SourceRevision,
				ProjectionAdvanced: request.Decision.ProjectionRevision > candidate.ProjectionRevision,
				VisibilityAdvanced: request.Decision.VisibilityRevision > candidate.VisibilityRevision,
				PayloadCleared:     candidate.Visibility == domain.VisibilityPublic,
			}
		}
	case DecisionNotFound:
		applied = ApplyResult{
			Outcome:        ApplyDeny,
			PayloadCleared: candidate.Visibility == domain.VisibilityPublic,
		}
	}
	return CompletionResult{Applied: applied}, nil
}

func (r *reconciliationRepositoryStub) HasDue(
	_ context.Context,
	request DueRequest,
) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.hasDueRequests = append(r.hasDueRequests, request)
	return r.hasDue, nil
}

func TestRunnerClaimsResolvesAndCompletesOutsideRepositoryCall(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	activity := reconciliationClaim(t, domain.EntityTypeActivity, "activity-1", now, 0)
	user := reconciliationClaim(t, domain.EntityTypeUser, uuid.NewString(), now, 0)
	repository := &reconciliationRepositoryStub{claims: []Claim{activity, user}}
	resolver := reconciliationResolverFunc(func(
		_ context.Context,
		target domain.SavedTarget,
	) (appsource.Resolution, error) {
		if target.EntityType() == domain.EntityTypeUser {
			return appsource.Resolution{}, domain.ErrTargetUnavailable
		}
		return reconciliationPublicResolution(target, now, 2), nil
	})
	runner := newReconciliationTestRunner(t, repository, resolver, now, 10)

	stats, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if stats.CandidatesClaimed != 2 || stats.PublicApplied != 1 ||
		stats.DenyApplied != 1 || stats.NotFound != 1 ||
		stats.PayloadsCleared != 1 || stats.HasMore || stats.Capped {
		t.Fatalf("Run() stats = %+v", stats)
	}
	if len(repository.completions) != 2 {
		t.Fatalf("completion count = %d, want 2", len(repository.completions))
	}
	for _, completion := range repository.completions {
		if completion.NextAttemptDelay != runner.config.StaleAfter {
			t.Fatalf("next attempt delay = %s", completion.NextAttemptDelay)
		}
	}
}

func TestRunnerBoundsSourceAndRepositoryRetries(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	claim := reconciliationClaim(t, domain.EntityTypeAttraction, "attraction-1", now, 0)
	repository := &reconciliationRepositoryStub{
		claims:                   []Claim{claim},
		claimFailuresBefore:      1,
		completionFailuresBefore: 1,
	}
	var resolveCalls atomic.Int32
	resolver := reconciliationResolverFunc(func(
		_ context.Context,
		target domain.SavedTarget,
	) (appsource.Resolution, error) {
		if resolveCalls.Add(1) == 1 {
			return appsource.Resolution{}, domain.ErrDependencyUnavailable
		}
		return reconciliationPublicResolution(target, now, 2), nil
	})
	runner := newReconciliationTestRunner(t, repository, resolver, now, 10)

	stats, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if stats.RepositoryRetries != 2 || stats.ResolveRetries != 1 ||
		stats.PublicApplied != 1 || resolveCalls.Load() != 2 {
		t.Fatalf("Run() stats = %+v, resolve calls = %d", stats, resolveCalls.Load())
	}
}

func TestRunnerUnknownCompletionCommitDoesNotRepeatSourceRPC(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	repository := &reconciliationRepositoryStub{
		claims:          []Claim{reconciliationClaim(t, domain.EntityTypeActivity, "activity-unknown", now, 0)},
		completionError: ErrCommitOutcomeUnknown,
	}
	var resolveCalls atomic.Int32
	resolver := reconciliationResolverFunc(func(
		_ context.Context,
		target domain.SavedTarget,
	) (appsource.Resolution, error) {
		resolveCalls.Add(1)
		return reconciliationPublicResolution(target, now, 2), nil
	})
	runner := newReconciliationTestRunner(t, repository, resolver, now, 10)

	stats, err := runner.Run(context.Background())
	if !errors.Is(err, ErrCommitOutcomeUnknown) {
		t.Fatalf("Run() error = %v", err)
	}
	if resolveCalls.Load() != 1 || len(repository.completions) != 1 ||
		stats.CompletionFailures != 1 || stats.CommitUnknown != 1 {
		t.Fatalf("calls=%d completions=%d stats=%+v", resolveCalls.Load(), len(repository.completions), stats)
	}
}

func TestRunnerSchedulesTransientFailureWithBoundedJitter(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	claim := reconciliationClaim(t, domain.EntityTypeActivity, "activity-retry", now, 2)
	repository := &reconciliationRepositoryStub{claims: []Claim{claim}}
	resolver := reconciliationResolverFunc(func(
		context.Context,
		domain.SavedTarget,
	) (appsource.Resolution, error) {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	})
	runner := newReconciliationTestRunner(t, repository, resolver, now, 10)

	stats, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if stats.ResolutionFailures != 1 || stats.RetriesScheduled != 1 ||
		len(repository.completions) != 1 {
		t.Fatalf("Run() stats = %+v", stats)
	}
	delay := repository.completions[0].NextAttemptDelay
	ceiling := 4 * runner.config.FailureBackoffBase
	if delay < ceiling/2 || delay > ceiling {
		t.Fatalf("persisted retry delay = %s, want [%s,%s]", delay, ceiling/2, ceiling)
	}
}

func TestRunnerQuarantinesPermanentUnsupportedAfterBoundedAttempts(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	claim := reconciliationClaim(
		t,
		domain.EntityTypeUser,
		uuid.NewString(),
		now,
		DefaultPermanentFailures-1,
	)
	claim.PreviousFailure = CompletionFailureUnsupported
	repository := &reconciliationRepositoryStub{claims: []Claim{claim}}
	var resolveCalls atomic.Int32
	resolver := reconciliationResolverFunc(func(
		context.Context,
		domain.SavedTarget,
	) (appsource.Resolution, error) {
		resolveCalls.Add(1)
		return appsource.Resolution{}, domain.ErrTargetTypeUnsupported
	})
	runner := newReconciliationTestRunner(t, repository, resolver, now, 10)

	stats, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if stats.UnsupportedType != 1 || stats.Quarantined != 1 ||
		stats.NoChange != 1 || resolveCalls.Load() != 1 ||
		!repository.completions[0].Quarantine {
		t.Fatalf("Run() stats = %+v, completion=%+v", stats, repository.completions[0])
	}
}

func TestRunnerQuarantinesEqualVisibilityRevisionConflictAsInvariant(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	claim := reconciliationClaim(
		t,
		domain.EntityTypeActivity,
		"visibility-conflict",
		now,
		DefaultPermanentFailures-1,
	)
	claim.PreviousFailure = CompletionFailureInvariant
	repository := &reconciliationRepositoryStub{claims: []Claim{claim}}
	resolver := reconciliationResolverFunc(func(
		_ context.Context,
		target domain.SavedTarget,
	) (appsource.Resolution, error) {
		return appsource.Resolution{
			Target:     target,
			Visibility: domain.VisibilityPrivate,
			Revisions: appsource.Revisions{
				Source: 2, Projection: 2, Visibility: claim.Candidate.VisibilityRevision,
			},
			ValidatedAt: now,
		}, nil
	})
	runner := newReconciliationTestRunner(t, repository, resolver, now, 10)

	stats, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if stats.ResolutionFailures != 1 || stats.InvariantFailures != 1 ||
		stats.Quarantined != 1 || !repository.completions[0].Quarantine {
		t.Fatalf("Run() stats = %+v, completion=%+v", stats, repository.completions[0])
	}
}

func TestRunnerResetsPermanentStreakAfterDifferentFailureClass(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	claim := reconciliationClaim(
		t,
		domain.EntityTypeUser,
		uuid.NewString(),
		now,
		DefaultPermanentFailures-1,
	)
	claim.PreviousFailure = CompletionFailureTransient
	repository := &reconciliationRepositoryStub{claims: []Claim{claim}}
	runner := newReconciliationTestRunner(
		t,
		repository,
		reconciliationResolverFunc(func(
			context.Context,
			domain.SavedTarget,
		) (appsource.Resolution, error) {
			return appsource.Resolution{}, domain.ErrTargetTypeUnsupported
		}),
		now,
		10,
	)

	stats, err := runner.Run(context.Background())
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	completion := repository.completions[0]
	if stats.Quarantined != 0 || !completion.Failure.IsValid() ||
		completion.Failure != CompletionFailureUnsupported || completion.Quarantine ||
		completion.NextAttemptDelay < runner.config.FailureBackoffBase/2 ||
		completion.NextAttemptDelay > runner.config.FailureBackoffBase {
		t.Fatalf("stats = %+v, completion = %+v", stats, completion)
	}
}

func TestRunnerUsesPersistedDueCheckForHasMore(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	claims := []Claim{
		reconciliationClaim(t, domain.EntityTypeActivity, "activity-a", now, 0),
		reconciliationClaim(t, domain.EntityTypeActivity, "activity-b", now, 0),
	}
	resolver := reconciliationResolverFunc(func(
		_ context.Context,
		target domain.SavedTarget,
	) (appsource.Resolution, error) {
		return reconciliationPublicResolution(target, now, 2), nil
	})

	for _, testCase := range []struct {
		name    string
		hasDue  bool
		wantCap bool
	}{
		{name: "exact_batch", hasDue: false, wantCap: false},
		{name: "more_due", hasDue: true, wantCap: true},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			repository := &reconciliationRepositoryStub{claims: claims, hasDue: testCase.hasDue}
			runner := newReconciliationTestRunner(t, repository, resolver, now, 2)
			stats, err := runner.Run(context.Background())
			if err != nil {
				t.Fatalf("Run() error = %v", err)
			}
			if stats.HasMore != testCase.hasDue || stats.Capped != testCase.wantCap ||
				len(repository.hasDueRequests) != 1 {
				t.Fatalf("Run() stats = %+v, due requests = %d", stats, len(repository.hasDueRequests))
			}
		})
	}
}

func TestStatsObservabilityShapeContainsNoIdentifiersOrErrorText(t *testing.T) {
	typeOfStats := reflect.TypeOf(Stats{})
	for index := range typeOfStats.NumField() {
		field := typeOfStats.Field(index)
		switch field.Type.Kind() {
		case reflect.String, reflect.Slice, reflect.Map, reflect.Interface, reflect.Pointer:
			t.Errorf("Stats field %s has disallowed observability kind %s", field.Name, field.Type.Kind())
		}
	}
}

func TestConfigEnforcesWorstCaseRunAndLeaseBudgets(t *testing.T) {
	config := DefaultConfig()
	if err := config.Validate(); err != nil {
		t.Fatalf("DefaultConfig().Validate() error = %v", err)
	}
	config.LeaseDuration = config.ResolveTimeout
	if !errors.Is(config.Validate(), ErrInvalidConfig) {
		t.Fatalf("undersized lease Config.Validate() error = %v", config.Validate())
	}
	config = DefaultConfig()
	config.BatchSize = 500
	config.RunTimeout = time.Second
	if !errors.Is(config.Validate(), ErrInvalidConfig) {
		t.Fatalf("oversubscribed Config.Validate() error = %v", config.Validate())
	}
}

func TestBuildResolvedDecisionRejectsExpiredAuthoritativeValidation(t *testing.T) {
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	resolution := reconciliationPublicResolution(target, now.Add(-maxResolutionAge-time.Second), 2)
	if _, err = BuildResolvedDecision(resolution, now); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("BuildResolvedDecision() error = %v", err)
	}
}

func newReconciliationTestRunner(
	t *testing.T,
	repository Repository,
	resolver appsource.Resolver,
	now time.Time,
	batchSize int,
) *Runner {
	t.Helper()
	config := DefaultConfig()
	config.BatchSize = batchSize
	config.RunTimeout = 5 * time.Second
	config.ResolveTimeout = 100 * time.Millisecond
	config.RetryBase = time.Millisecond
	config.RetryMax = 2 * time.Millisecond
	config.LeaseDuration = time.Second
	config.FailureBackoffBase = time.Second
	config.FailureBackoffMax = time.Minute
	runner, err := NewRunner(repository, resolver, config, ClockFunc(func() time.Time { return now }))
	if err != nil {
		t.Fatalf("NewRunner() error = %v", err)
	}
	return runner
}

func reconciliationClaim(
	t testing.TB,
	entityType domain.EntityType,
	entityID string,
	now time.Time,
	failureCount int,
) Claim {
	t.Helper()
	candidate := reconciliationCandidate(t, entityType, entityID, now)
	return Claim{
		Token:           uuid.New(),
		Candidate:       candidate,
		ClaimedAt:       now,
		LeaseExpiresAt:  now.Add(time.Minute),
		FailureCount:    failureCount,
		PreviousFailure: previousReconciliationFailure(failureCount),
	}
}

func previousReconciliationFailure(failureCount int) CompletionFailure {
	if failureCount == 0 {
		return CompletionFailureNone
	}
	return CompletionFailureTransient
}

func reconciliationCandidate(
	t testing.TB,
	entityType domain.EntityType,
	entityID string,
	now time.Time,
) Candidate {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, entityID)
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	validatedAt := now.Add(-24 * time.Hour)
	var sourceService string
	switch entityType {
	case domain.EntityTypeActivity:
		sourceService = "activity-service"
	case domain.EntityTypeAttraction:
		sourceService = "place-service"
	case domain.EntityTypeUser:
		sourceService = "user-service"
	default:
		t.Fatalf("unsupported Saved entity type: %q", entityType)
	}
	return Candidate{
		Key: CandidateKey{
			VisibilityValidatedAt: &validatedAt,
			Target:                target,
		},
		SourceService:      sourceService,
		SourceRevision:     1,
		ProjectionRevision: 1,
		VisibilityRevision: 1,
		Visibility:         domain.VisibilityPublic,
	}
}

func reconciliationPublicResolution(
	target domain.SavedTarget,
	now time.Time,
	revision uint64,
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
				appsource.LocaleEN: {Title: "Fresh title"},
			},
		},
	}
}
