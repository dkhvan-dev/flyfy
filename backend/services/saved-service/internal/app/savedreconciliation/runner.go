package savedreconciliation

import (
	"context"
	"errors"
	"hash/fnv"
	"strconv"
	"time"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type Clock interface {
	Now() time.Time
}

type ClockFunc func() time.Time

func (function ClockFunc) Now() time.Time {
	if function == nil {
		return time.Time{}
	}
	return function()
}

type Runner struct {
	repository Repository
	resolver   appsource.Resolver
	config     Config
	clock      Clock
}

func NewRunner(
	repository Repository,
	resolver appsource.Resolver,
	config Config,
	clock Clock,
) (*Runner, error) {
	if repository == nil || resolver == nil || clock == nil {
		return nil, ErrInvalidDependencies
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}
	return &Runner{
		repository: repository,
		resolver:   resolver,
		config:     config,
		clock:      clock,
	}, nil
}

func NewDefaultRunner(repository Repository, resolver appsource.Resolver) (*Runner, error) {
	return NewRunner(
		repository,
		resolver,
		DefaultConfig(),
		ClockFunc(func() time.Time { return time.Now().UTC() }),
	)
}

type resolutionDisposition uint8

const (
	dispositionResolved resolutionDisposition = iota + 1
	dispositionNotFound
	dispositionUnsupported
	dispositionFailed
	dispositionInvariant
)

type resolutionAttempt struct {
	decision       Decision
	disposition    resolutionDisposition
	failure        CompletionFailure
	resolveRetries int
}

// Run claims bounded work, resolves each source outside a database transaction,
// and completes the claim with a snapshot CAS.
func (r *Runner) Run(ctx context.Context) (Stats, error) {
	if ctx == nil || r == nil || r.repository == nil || r.resolver == nil || r.clock == nil {
		return Stats{}, ErrInvalidDependencies
	}
	if err := ctx.Err(); err != nil {
		return Stats{}, err
	}
	startedAt, err := r.now()
	if err != nil {
		return Stats{}, err
	}
	runCtx, cancel := context.WithTimeout(ctx, r.config.RunTimeout)
	defer cancel()

	stats := Stats{StartedAt: startedAt}
	for stats.CandidatesClaimed < r.config.BatchSize {
		claim, found, retries, claimErr := r.claimNext(runCtx, ClaimRequest{
			StaleAfter:    r.config.StaleAfter,
			LeaseDuration: r.config.LeaseDuration,
		})
		stats.RepositoryRetries += retries
		if claimErr != nil {
			return r.finish(stats, claimErr)
		}
		if !found {
			stats.HasMore = false
			return r.finish(stats, nil)
		}

		stats.CandidatesClaimed++
		attempt, resolveErr := r.resolveCandidate(runCtx, claim.Candidate)
		stats.ResolveRetries += attempt.resolveRetries
		if resolveErr != nil {
			return r.finish(stats, resolveErr)
		}
		completion, completionErr := r.buildCompletion(claim, attempt)
		if completionErr != nil {
			return r.finish(stats, completionErr)
		}
		result, retries, completionErr := r.completeClaim(runCtx, completion)
		stats.RepositoryRetries += retries
		if completionErr != nil {
			stats.CompletionFailures++
			if errors.Is(completionErr, ErrCommitOutcomeUnknown) {
				stats.CommitUnknown++
			}
			return r.finish(stats, completionErr)
		}

		stats.recordApply(result.Applied)
		if result.LeaseLost {
			stats.LeaseConflicts++
		}
		if result.RetryScheduled {
			stats.RetriesScheduled++
		}
		if result.Quarantined {
			stats.Quarantined++
		}
		switch attempt.disposition {
		case dispositionNotFound:
			stats.NotFound++
		case dispositionUnsupported:
			stats.UnsupportedType++
		case dispositionFailed:
			stats.ResolutionFailures++
		case dispositionInvariant:
			stats.ResolutionFailures++
			stats.InvariantFailures++
		}
	}

	hasMore, retries, dueErr := r.hasDue(runCtx, DueRequest{
		StaleAfter: r.config.StaleAfter,
	})
	stats.RepositoryRetries += retries
	if dueErr != nil {
		return r.finish(stats, dueErr)
	}
	stats.Capped = hasMore
	stats.HasMore = hasMore
	return r.finish(stats, nil)
}

func (r *Runner) claimNext(
	ctx context.Context,
	request ClaimRequest,
) (Claim, bool, int, error) {
	for repositoryAttempt := 1; repositoryAttempt <= r.config.RepositoryAttempts; repositoryAttempt++ {
		claim, found, err := r.repository.ClaimNext(ctx, request)
		if err == nil {
			if found {
				if validateErr := claim.Validate(); validateErr != nil {
					return Claim{}, false, repositoryAttempt - 1, validateErr
				}
			}
			return claim, found, repositoryAttempt - 1, nil
		}
		if errors.Is(err, ErrCommitOutcomeUnknown) {
			return Claim{}, false, repositoryAttempt - 1, ErrCommitOutcomeUnknown
		}
		if ctx.Err() != nil {
			return Claim{}, false, repositoryAttempt - 1, ctx.Err()
		}
		if !errors.Is(err, ErrRepositoryUnavailable) ||
			repositoryAttempt == r.config.RepositoryAttempts {
			return Claim{}, false, repositoryAttempt - 1, coarseRepositoryError(err)
		}
		if waitErr := waitRetry(ctx, retryDelay(repositoryAttempt, r.config)); waitErr != nil {
			return Claim{}, false, repositoryAttempt - 1, waitErr
		}
	}
	return Claim{}, false, r.config.RepositoryAttempts - 1, ErrRepositoryUnavailable
}

func (r *Runner) resolveCandidate(
	ctx context.Context,
	candidate Candidate,
) (resolutionAttempt, error) {
	if err := candidate.Validate(); err != nil {
		return resolutionAttempt{}, err
	}
	expectedSource := saveditem.SourceServiceFor(candidate.Key.Target.EntityType())
	if expectedSource == "" {
		return resolutionAttempt{
			disposition: dispositionUnsupported,
			failure:     CompletionFailureUnsupported,
		}, nil
	}
	if candidate.SourceService != expectedSource {
		return resolutionAttempt{
			disposition: dispositionInvariant,
			failure:     CompletionFailureInvariant,
		}, nil
	}

	for attempt := 1; attempt <= r.config.ResolveAttempts; attempt++ {
		resolveCtx, cancel := context.WithTimeout(ctx, r.config.ResolveTimeout)
		resolution, resolveErr := r.resolver.Resolve(resolveCtx, candidate.Key.Target)
		cancel()
		if resolveErr == nil {
			now, nowErr := r.now()
			if nowErr != nil {
				return resolutionAttempt{resolveRetries: attempt - 1}, nowErr
			}
			decision, decisionErr := BuildResolvedDecision(resolution, now)
			if decisionErr != nil || decision.Target.EntityType() != candidate.Key.Target.EntityType() ||
				decision.Target.EntityID() != candidate.Key.Target.EntityID() ||
				permanentResolutionInvariant(candidate, decision) {
				return resolutionAttempt{
					disposition:    dispositionInvariant,
					failure:        CompletionFailureInvariant,
					resolveRetries: attempt - 1,
				}, nil
			}
			return resolutionAttempt{
				decision:       decision,
				disposition:    dispositionResolved,
				resolveRetries: attempt - 1,
			}, nil
		}
		if ctx.Err() != nil {
			return resolutionAttempt{resolveRetries: attempt - 1}, ctx.Err()
		}
		if errors.Is(resolveErr, domain.ErrTargetUnavailable) {
			now, nowErr := r.now()
			if nowErr != nil {
				return resolutionAttempt{resolveRetries: attempt - 1}, nowErr
			}
			decision, decisionErr := NewNotFoundDecision(candidate.Key.Target, now)
			return resolutionAttempt{
				decision:       decision,
				disposition:    dispositionNotFound,
				resolveRetries: attempt - 1,
			}, decisionErr
		}
		if errors.Is(resolveErr, domain.ErrTargetTypeUnsupported) {
			return resolutionAttempt{
				disposition:    dispositionUnsupported,
				failure:        CompletionFailureUnsupported,
				resolveRetries: attempt - 1,
			}, nil
		}
		if attempt == r.config.ResolveAttempts {
			return resolutionAttempt{
				disposition:    dispositionFailed,
				failure:        CompletionFailureTransient,
				resolveRetries: attempt - 1,
			}, nil
		}
		if waitErr := waitRetry(ctx, retryDelay(attempt, r.config)); waitErr != nil {
			return resolutionAttempt{resolveRetries: attempt - 1}, waitErr
		}
	}
	return resolutionAttempt{
		disposition:    dispositionFailed,
		failure:        CompletionFailureTransient,
		resolveRetries: r.config.ResolveAttempts - 1,
	}, nil
}

func permanentResolutionInvariant(candidate Candidate, decision Decision) bool {
	if decision.Kind != DecisionResolved {
		return false
	}
	if decision.VisibilityRevision == candidate.VisibilityRevision &&
		decision.Visibility != candidate.Visibility {
		return true
	}
	return decision.Visibility == domain.VisibilityPublic &&
		candidate.Visibility != domain.VisibilityPublic &&
		decision.VisibilityRevision > candidate.VisibilityRevision &&
		decision.ProjectionRevision < candidate.ProjectionRevision
}

func (r *Runner) buildCompletion(
	claim Claim,
	attempt resolutionAttempt,
) (CompletionRequest, error) {
	request := CompletionRequest{
		Claim:    claim,
		Decision: attempt.decision,
		Failure:  attempt.failure,
	}
	if attempt.failure == CompletionFailureNone {
		request.NextAttemptDelay = r.config.StaleAfter
	} else {
		failureCount := 1
		if claim.PreviousFailure == attempt.failure {
			failureCount = claim.FailureCount + 1
		}
		permanent := attempt.failure == CompletionFailureInvariant ||
			attempt.failure == CompletionFailureUnsupported
		request.Quarantine = permanent && failureCount >= r.config.PermanentFailures
		if !request.Quarantine {
			request.NextAttemptDelay = persistedRetryDelay(
				r.config.FailureBackoffBase,
				r.config.FailureBackoffMax,
				failureCount,
				claim.Candidate.Key.Target,
			)
		}
	}
	if err := request.Validate(); err != nil {
		return CompletionRequest{}, err
	}
	return request, nil
}

func (r *Runner) completeClaim(
	ctx context.Context,
	request CompletionRequest,
) (CompletionResult, int, error) {
	for repositoryAttempt := 1; repositoryAttempt <= r.config.RepositoryAttempts; repositoryAttempt++ {
		result, err := r.repository.Complete(ctx, request)
		if err == nil {
			if validateErr := result.Validate(); validateErr != nil {
				return CompletionResult{}, repositoryAttempt - 1, validateErr
			}
			return result, repositoryAttempt - 1, nil
		}
		if errors.Is(err, ErrCommitOutcomeUnknown) {
			return CompletionResult{}, repositoryAttempt - 1, ErrCommitOutcomeUnknown
		}
		if ctx.Err() != nil {
			return CompletionResult{}, repositoryAttempt - 1, ctx.Err()
		}
		if !errors.Is(err, ErrRepositoryUnavailable) ||
			repositoryAttempt == r.config.RepositoryAttempts {
			return CompletionResult{}, repositoryAttempt - 1, coarseRepositoryError(err)
		}
		if waitErr := waitRetry(ctx, retryDelay(repositoryAttempt, r.config)); waitErr != nil {
			return CompletionResult{}, repositoryAttempt - 1, waitErr
		}
	}
	return CompletionResult{}, r.config.RepositoryAttempts - 1, ErrRepositoryUnavailable
}

func (r *Runner) hasDue(
	ctx context.Context,
	request DueRequest,
) (bool, int, error) {
	for repositoryAttempt := 1; repositoryAttempt <= r.config.RepositoryAttempts; repositoryAttempt++ {
		hasDue, err := r.repository.HasDue(ctx, request)
		if err == nil {
			return hasDue, repositoryAttempt - 1, nil
		}
		if ctx.Err() != nil {
			return false, repositoryAttempt - 1, ctx.Err()
		}
		if !errors.Is(err, ErrRepositoryUnavailable) ||
			repositoryAttempt == r.config.RepositoryAttempts {
			return false, repositoryAttempt - 1, coarseRepositoryError(err)
		}
		if waitErr := waitRetry(ctx, retryDelay(repositoryAttempt, r.config)); waitErr != nil {
			return false, repositoryAttempt - 1, waitErr
		}
	}
	return false, r.config.RepositoryAttempts - 1, ErrRepositoryUnavailable
}

func (r *Runner) now() (time.Time, error) {
	value := r.clock.Now().UTC()
	if value.IsZero() {
		return time.Time{}, ErrInvalidDependencies
	}
	return value, nil
}

func (r *Runner) finish(stats Stats, runErr error) (Stats, error) {
	finishedAt, err := r.now()
	if err != nil {
		if runErr != nil {
			return stats, runErr
		}
		return stats, err
	}
	if finishedAt.Before(stats.StartedAt) {
		if runErr != nil {
			return stats, runErr
		}
		return stats, ErrDataInvariant
	}
	stats.FinishedAt = finishedAt
	if validateErr := stats.validate(r.config); validateErr != nil && runErr == nil {
		return stats, validateErr
	}
	return stats, runErr
}

func retryDelay(attempt int, config Config) time.Duration {
	delay := config.RetryBase
	for current := 1; current < attempt && delay < config.RetryMax; current++ {
		if delay > config.RetryMax/2 {
			return config.RetryMax
		}
		delay *= 2
	}
	if delay > config.RetryMax {
		return config.RetryMax
	}
	return delay
}

func persistedRetryDelay(
	base time.Duration,
	maximum time.Duration,
	failures int,
	target domain.SavedTarget,
) time.Duration {
	ceiling := base
	for attempt := 1; attempt < failures && ceiling < maximum; attempt++ {
		if ceiling > maximum/2 {
			ceiling = maximum
			break
		}
		ceiling *= 2
	}
	if ceiling > maximum {
		ceiling = maximum
	}
	floor := ceiling / 2
	span := ceiling - floor
	hash := fnv.New64a()
	_, _ = hash.Write([]byte(target.EntityType()))
	_, _ = hash.Write([]byte{0})
	_, _ = hash.Write([]byte(target.EntityID()))
	_, _ = hash.Write([]byte{0})
	_, _ = hash.Write([]byte(strconv.Itoa(failures)))
	return floor + time.Duration(hash.Sum64()%uint64(span+1))
}

func waitRetry(ctx context.Context, delay time.Duration) error {
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return nil
	}
}

func coarseRepositoryError(err error) error {
	if errors.Is(err, ErrCommitOutcomeUnknown) {
		return ErrCommitOutcomeUnknown
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	if errors.Is(err, ErrDataInvariant) {
		return ErrDataInvariant
	}
	return ErrRepositoryUnavailable
}
