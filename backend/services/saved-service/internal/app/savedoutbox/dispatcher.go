package savedoutbox

import (
	"context"
	"encoding/binary"
	"errors"
	"fmt"
	"hash/fnv"
	"sync"
	"time"

	"github.com/google/uuid"
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

type SystemClock struct{}

func (SystemClock) Now() time.Time { return time.Now().UTC() }

type Dispatcher struct {
	repository Repository
	publisher  Publisher
	config     Config
	clock      Clock
}

func NewDispatcher(
	repository Repository,
	publisher Publisher,
	config Config,
	clock Clock,
) (*Dispatcher, error) {
	if repository == nil || publisher == nil || clock == nil {
		return nil, ErrInvalidDependencies
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}
	return &Dispatcher{
		repository: repository,
		publisher:  publisher,
		config:     config,
		clock:      clock,
	}, nil
}

type BatchStats struct {
	StartedAt       time.Time
	FinishedAt      time.Time
	LeasesRecovered int
	RecoveryDead    int
	Claimed         int
	Delivered       int
	RetryScheduled  int
	Dead            int
	LikelyMore      bool
}

func (dispatcher *Dispatcher) DispatchBatch(ctx context.Context) (BatchStats, error) {
	if ctx == nil || dispatcher == nil || dispatcher.repository == nil ||
		dispatcher.publisher == nil || dispatcher.clock == nil {
		return BatchStats{}, ErrInvalidDependencies
	}
	if err := ctx.Err(); err != nil {
		return BatchStats{}, err
	}
	startedAt, err := dispatcher.now()
	if err != nil {
		return BatchStats{}, err
	}
	stats := BatchStats{StartedAt: startedAt}

	recoveryRequest := RecoveryRequest{
		Now:                startedAt,
		LeaseExpiredBefore: startedAt.Add(-dispatcher.config.LeaseDuration),
		TerminalExpiresAt:  startedAt.Add(TerminalRetention),
		Limit:              dispatcher.config.BatchSize,
		MaxAttempts:        dispatcher.config.MaxAttempts,
	}
	recovered, err := dispatcher.repository.RecoverStaleLeases(ctx, recoveryRequest)
	if err != nil {
		return dispatcher.finish(stats, fmt.Errorf("recover stale saved outbox leases: %w", err))
	}
	if err = recovered.Validate(recoveryRequest.Limit); err != nil {
		return dispatcher.finish(stats, err)
	}
	stats.LeasesRecovered = recovered.Released
	stats.RecoveryDead = recovered.Dead
	stats.LikelyMore = recovered.Released+recovered.Dead == recoveryRequest.Limit

	claimed, err := dispatcher.repository.ClaimDue(ctx, ClaimRequest{
		Now:         startedAt,
		Limit:       dispatcher.config.BatchSize,
		MaxAttempts: dispatcher.config.MaxAttempts,
	})
	if err != nil {
		return dispatcher.finish(stats, fmt.Errorf("claim due saved outbox events: %w", err))
	}
	if len(claimed) > dispatcher.config.BatchSize {
		return dispatcher.finish(stats, ErrPersistenceInvariant)
	}
	stats.Claimed = len(claimed)
	stats.LikelyMore = stats.LikelyMore || len(claimed) == dispatcher.config.BatchSize
	if len(claimed) == 0 {
		return dispatcher.finish(stats, nil)
	}

	results := dispatcher.processBatch(ctx, claimed)
	var firstProcessError error
	for result := range results {
		stats.Delivered += result.delivered
		stats.RetryScheduled += result.retryScheduled
		stats.Dead += result.dead
		if result.err != nil && firstProcessError == nil {
			firstProcessError = result.err
		}
	}
	return dispatcher.finish(stats, firstProcessError)
}

func (dispatcher *Dispatcher) CleanupExpired(ctx context.Context) (int64, error) {
	if ctx == nil || dispatcher == nil || dispatcher.repository == nil || dispatcher.clock == nil {
		return 0, ErrInvalidDependencies
	}
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	now, err := dispatcher.now()
	if err != nil {
		return 0, err
	}
	request := CleanupRequest{Now: now, Limit: dispatcher.config.CleanupBatch}
	deleted, err := dispatcher.repository.DeleteExpired(ctx, request)
	if err != nil {
		return 0, fmt.Errorf("delete expired saved outbox events: %w", err)
	}
	if deleted < 0 || deleted > int64(request.Limit) {
		return 0, ErrPersistenceInvariant
	}
	return deleted, nil
}

type processResult struct {
	delivered      int
	retryScheduled int
	dead           int
	err            error
}

func (dispatcher *Dispatcher) processBatch(
	ctx context.Context,
	claimed []ClaimedRecord,
) <-chan processResult {
	jobs := make(chan ClaimedRecord, len(claimed))
	for _, record := range claimed {
		jobs <- record
	}
	close(jobs)

	results := make(chan processResult, len(claimed))
	workerCount := min(dispatcher.config.Concurrency, len(claimed))
	var workers sync.WaitGroup
	workers.Add(workerCount)
	for range workerCount {
		go func() {
			defer workers.Done()
			for record := range jobs {
				results <- dispatcher.processClaimed(ctx, record)
			}
		}()
	}
	go func() {
		workers.Wait()
		close(results)
	}()
	return results
}

func (dispatcher *Dispatcher) processClaimed(
	ctx context.Context,
	record ClaimedRecord,
) processResult {
	if err := ctx.Err(); err != nil {
		return processResult{err: err}
	}
	event, err := MapClaimedRecord(record)
	if err != nil {
		return dispatcher.recordFailure(ctx, record.Lease, FailureInvalidEvent, true)
	}

	publishCtx, cancel := context.WithTimeout(ctx, dispatcher.config.PublishTimeout)
	publishErr := dispatcher.publisher.Publish(publishCtx, event)
	publishContextErr := publishCtx.Err()
	cancel()
	if publishErr != nil {
		if err := ctx.Err(); err != nil {
			return processResult{err: err}
		}
		code := FailurePublishFailed
		if errors.Is(publishErr, context.DeadlineExceeded) ||
			errors.Is(publishContextErr, context.DeadlineExceeded) {
			code = FailurePublishTimeout
		}
		return dispatcher.recordFailure(ctx, record.Lease, code, false)
	}

	deliveredAt, err := dispatcher.nowNotBefore(record.Lease.AcquiredAt)
	if err != nil {
		return processResult{err: err}
	}
	delivery := Delivery{
		Lease:       record.Lease,
		DeliveredAt: deliveredAt,
		RetainUntil: deliveredAt.Add(TerminalRetention),
	}
	if err = dispatcher.repository.MarkDelivered(ctx, delivery); err != nil {
		return processResult{err: fmt.Errorf("mark saved outbox event delivered: %w", err)}
	}
	return processResult{delivered: 1}
}

func (dispatcher *Dispatcher) recordFailure(
	ctx context.Context,
	lease Lease,
	code FailureCode,
	permanent bool,
) processResult {
	failedAt, err := dispatcher.nowNotBefore(lease.AcquiredAt)
	if err != nil {
		return processResult{err: err}
	}
	nextAttemptAt := failedAt
	if !permanent && lease.Attempt < dispatcher.config.MaxAttempts {
		nextAttemptAt = failedAt.Add(retryDelay(
			lease.EventID,
			lease.Attempt,
			dispatcher.config.RetryBase,
			dispatcher.config.RetryMax,
		))
	}
	failure := Failure{
		Lease:         lease,
		Code:          code,
		FailedAt:      failedAt,
		NextAttemptAt: nextAttemptAt,
		RetainUntil:   failedAt.Add(TerminalRetention),
		MaxAttempts:   dispatcher.config.MaxAttempts,
		Permanent:     permanent,
	}
	disposition, err := dispatcher.repository.MarkFailed(ctx, failure)
	if err != nil {
		return processResult{err: fmt.Errorf("record saved outbox delivery failure: %w", err)}
	}
	if !disposition.IsValid() || (disposition == FailureDead) != failure.MustBecomeDead() {
		return processResult{err: ErrPersistenceInvariant}
	}
	if disposition == FailureDead {
		return processResult{dead: 1}
	}
	return processResult{retryScheduled: 1}
}

func (dispatcher *Dispatcher) now() (time.Time, error) {
	value := dispatcher.clock.Now().UTC()
	if !validOutboxTime(value) {
		return time.Time{}, ErrInvalidClock
	}
	return value, nil
}

func (dispatcher *Dispatcher) nowNotBefore(earliest time.Time) (time.Time, error) {
	value, err := dispatcher.now()
	if err != nil {
		return time.Time{}, err
	}
	if value.Before(earliest) {
		return time.Time{}, ErrInvalidClock
	}
	return value, nil
}

func (dispatcher *Dispatcher) finish(stats BatchStats, processErr error) (BatchStats, error) {
	finishedAt, err := dispatcher.nowNotBefore(stats.StartedAt)
	if err != nil {
		if processErr == nil {
			processErr = err
		} else {
			processErr = errors.Join(processErr, err)
		}
		return stats, processErr
	}
	stats.FinishedAt = finishedAt
	return stats, processErr
}

func retryDelay(eventID uuid.UUID, attempt int, base, maximum time.Duration) time.Duration {
	ceiling := base
	for current := 1; current < attempt && ceiling < maximum; current++ {
		if ceiling > maximum/2 {
			ceiling = maximum
			break
		}
		ceiling *= 2
	}
	if ceiling > maximum {
		ceiling = maximum
	}

	// Equal jitter prevents synchronized retry waves while preserving a useful
	// minimum delay and deterministic tests.
	floor := ceiling / 2
	span := ceiling - floor
	hasher := fnv.New64a()
	_, _ = hasher.Write(eventID[:])
	var attemptBytes [8]byte
	binary.LittleEndian.PutUint64(attemptBytes[:], uint64(attempt))
	_, _ = hasher.Write(attemptBytes[:])
	return floor + time.Duration(hasher.Sum64()%uint64(span+1))
}
