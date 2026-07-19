package app

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

const savedLifecycleTerminalRetention = 14 * 24 * time.Hour

var ErrSavedLifecycleDispatcherConfig = errors.New("invalid Saved lifecycle dispatcher configuration")

type SavedLifecycleOutbox interface {
	ClaimDueSavedLifecycleEvents(
		ctx context.Context,
		now time.Time,
		leaseCutoff time.Time,
		limit int,
	) ([]model.ClaimedSavedLifecycleEvent, error)
	MarkSavedLifecycleDelivered(
		ctx context.Context,
		eventID uuid.UUID,
		leaseID uuid.UUID,
		deliveredAt time.Time,
	) error
	MarkSavedLifecycleFailure(
		ctx context.Context,
		eventID uuid.UUID,
		leaseID uuid.UUID,
		failedAt time.Time,
		nextAttemptAt time.Time,
		maxAttempts int,
		errorCode string,
	) (model.SavedLifecycleDeliveryState, error)
	DeleteExpiredSavedLifecycleEvents(ctx context.Context, now time.Time, limit int) (int64, error)
}

type SavedLifecyclePublisher interface {
	PublishSavedLifecycle(ctx context.Context, event model.SavedLifecycleEvent) error
}

type SavedLifecycleDispatcherObserver interface {
	ObserveSavedLifecycleClaimed(count int)
	ObserveSavedLifecycleDelivered()
	ObserveSavedLifecycleRetry()
	ObserveSavedLifecycleDead()
	ObserveSavedLifecycleCleaned(count int64)
	ObserveSavedLifecycleError(code string)
}

type noopSavedLifecycleDispatcherObserver struct{}

func (noopSavedLifecycleDispatcherObserver) ObserveSavedLifecycleClaimed(int)   {}
func (noopSavedLifecycleDispatcherObserver) ObserveSavedLifecycleDelivered()    {}
func (noopSavedLifecycleDispatcherObserver) ObserveSavedLifecycleRetry()        {}
func (noopSavedLifecycleDispatcherObserver) ObserveSavedLifecycleDead()         {}
func (noopSavedLifecycleDispatcherObserver) ObserveSavedLifecycleCleaned(int64) {}
func (noopSavedLifecycleDispatcherObserver) ObserveSavedLifecycleError(string)  {}

type SavedLifecycleDispatcherConfig struct {
	BatchSize       int
	Concurrency     int
	PollInterval    time.Duration
	LeaseDuration   time.Duration
	PublishTimeout  time.Duration
	MaxAttempts     int
	RetryBase       time.Duration
	RetryMax        time.Duration
	CleanupInterval time.Duration
	CleanupBatch    int
}

func (cfg SavedLifecycleDispatcherConfig) Validate() error {
	switch {
	case cfg.BatchSize <= 0 || cfg.BatchSize > 500:
		return fmt.Errorf("%w: batch size must be in [1,500]", ErrSavedLifecycleDispatcherConfig)
	case cfg.Concurrency <= 0 || cfg.Concurrency > cfg.BatchSize:
		return fmt.Errorf("%w: concurrency must be in [1,batch size]", ErrSavedLifecycleDispatcherConfig)
	case cfg.PollInterval <= 0:
		return fmt.Errorf("%w: poll interval must be positive", ErrSavedLifecycleDispatcherConfig)
	case cfg.PollInterval > time.Minute:
		return fmt.Errorf("%w: poll interval must not exceed one minute", ErrSavedLifecycleDispatcherConfig)
	case cfg.PublishTimeout <= 0 || cfg.PublishTimeout > 30*time.Second:
		return fmt.Errorf("%w: publish timeout must be in (0,30s]", ErrSavedLifecycleDispatcherConfig)
	case cfg.LeaseDuration < minimumSavedLifecycleLease(cfg) || cfg.LeaseDuration > time.Hour:
		return fmt.Errorf("%w: lease duration does not cover a bounded batch", ErrSavedLifecycleDispatcherConfig)
	case cfg.MaxAttempts <= 0 || cfg.MaxAttempts > 100:
		return fmt.Errorf("%w: max attempts must be in [1,100]", ErrSavedLifecycleDispatcherConfig)
	case cfg.RetryBase <= 0 || cfg.RetryMax < cfg.RetryBase || cfg.RetryMax > 24*time.Hour:
		return fmt.Errorf("%w: retry bounds are invalid", ErrSavedLifecycleDispatcherConfig)
	case cfg.CleanupInterval <= 0 || cfg.CleanupInterval > 24*time.Hour:
		return fmt.Errorf("%w: cleanup interval must be positive", ErrSavedLifecycleDispatcherConfig)
	case cfg.CleanupBatch <= 0 || cfg.CleanupBatch > 5000:
		return fmt.Errorf("%w: cleanup batch must be in [1,5000]", ErrSavedLifecycleDispatcherConfig)
	default:
		return nil
	}
}

func minimumSavedLifecycleLease(cfg SavedLifecycleDispatcherConfig) time.Duration {
	waves := (cfg.BatchSize + cfg.Concurrency - 1) / cfg.Concurrency
	return 2 * time.Duration(waves) * cfg.PublishTimeout
}

type SavedLifecycleDispatcher struct {
	outbox    SavedLifecycleOutbox
	publisher SavedLifecyclePublisher
	observer  SavedLifecycleDispatcherObserver
	config    SavedLifecycleDispatcherConfig
	now       func() time.Time
}

type SavedLifecycleDispatcherOption func(*SavedLifecycleDispatcher)

func WithSavedLifecycleDispatcherClock(now func() time.Time) SavedLifecycleDispatcherOption {
	return func(dispatcher *SavedLifecycleDispatcher) {
		if now != nil {
			dispatcher.now = now
		}
	}
}

func WithSavedLifecycleDispatcherObserver(
	observer SavedLifecycleDispatcherObserver,
) SavedLifecycleDispatcherOption {
	return func(dispatcher *SavedLifecycleDispatcher) {
		if observer != nil {
			dispatcher.observer = observer
		}
	}
}

func NewSavedLifecycleDispatcher(
	outbox SavedLifecycleOutbox,
	publisher SavedLifecyclePublisher,
	config SavedLifecycleDispatcherConfig,
	options ...SavedLifecycleDispatcherOption,
) (*SavedLifecycleDispatcher, error) {
	if outbox == nil || publisher == nil {
		return nil, fmt.Errorf("%w: outbox and publisher are required", ErrSavedLifecycleDispatcherConfig)
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}
	dispatcher := &SavedLifecycleDispatcher{
		outbox:    outbox,
		publisher: publisher,
		observer:  noopSavedLifecycleDispatcherObserver{},
		config:    config,
		now:       time.Now,
	}
	for _, option := range options {
		if option != nil {
			option(dispatcher)
		}
	}
	return dispatcher, nil
}

func (dispatcher *SavedLifecycleDispatcher) Run(ctx context.Context) error {
	if dispatcher == nil {
		return fmt.Errorf("%w: dispatcher is nil", ErrSavedLifecycleDispatcherConfig)
	}
	cleanupTimer := time.NewTimer(0)
	defer cleanupTimer.Stop()

	for {
		processed, err := dispatcher.RunOnce(ctx)
		if err != nil && !errors.Is(err, context.Canceled) {
			dispatcher.observer.ObserveSavedLifecycleError("DISPATCH_BATCH_FAILED")
			log.Error().Err(err).Msg("Saved lifecycle dispatch batch failed")
		}

		select {
		case <-cleanupTimer.C:
			if _, cleanupErr := dispatcher.CleanupOnce(ctx); cleanupErr != nil &&
				!errors.Is(cleanupErr, context.Canceled) {
				dispatcher.observer.ObserveSavedLifecycleError("OUTBOX_CLEANUP_FAILED")
				log.Error().Err(cleanupErr).Msg("Saved lifecycle outbox cleanup failed")
			}
			cleanupTimer.Reset(dispatcher.config.CleanupInterval)
		default:
		}

		if ctx.Err() != nil {
			return nil
		}
		if processed >= dispatcher.config.BatchSize {
			continue
		}

		timer := time.NewTimer(dispatcher.config.PollInterval)
		select {
		case <-ctx.Done():
			if !timer.Stop() {
				<-timer.C
			}
			return nil
		case <-timer.C:
		}
	}
}

func (dispatcher *SavedLifecycleDispatcher) RunOnce(ctx context.Context) (int, error) {
	if dispatcher == nil || dispatcher.outbox == nil || dispatcher.publisher == nil || dispatcher.now == nil {
		return 0, fmt.Errorf("%w: dispatcher is unavailable", ErrSavedLifecycleDispatcherConfig)
	}
	now := dispatcher.now().UTC()
	claimed, err := dispatcher.outbox.ClaimDueSavedLifecycleEvents(
		ctx,
		now,
		now.Add(-dispatcher.config.LeaseDuration),
		dispatcher.config.BatchSize,
	)
	if err != nil {
		return 0, fmt.Errorf("claim Saved lifecycle events: %w", err)
	}
	if len(claimed) == 0 {
		return 0, nil
	}
	dispatcher.observer.ObserveSavedLifecycleClaimed(len(claimed))

	workerCount := min(dispatcher.config.Concurrency, len(claimed))
	jobs := make(chan model.ClaimedSavedLifecycleEvent)
	var workers sync.WaitGroup
	var errorLock sync.Mutex
	var firstError error

	for range workerCount {
		workers.Add(1)
		go func() {
			defer workers.Done()
			for event := range jobs {
				if processErr := dispatcher.processClaimed(ctx, event); processErr != nil {
					errorLock.Lock()
					if firstError == nil {
						firstError = processErr
					}
					errorLock.Unlock()
				}
			}
		}()
	}

sendLoop:
	for _, event := range claimed {
		select {
		case <-ctx.Done():
			break sendLoop
		case jobs <- event:
		}
	}
	close(jobs)
	workers.Wait()
	return len(claimed), firstError
}

func (dispatcher *SavedLifecycleDispatcher) processClaimed(
	ctx context.Context,
	claimed model.ClaimedSavedLifecycleEvent,
) error {
	if err := claimed.Validate(); err != nil {
		dispatcher.observer.ObserveSavedLifecycleError("INVALID_OUTBOX_EVENT")
		return err
	}

	publishCtx, cancel := context.WithTimeout(ctx, dispatcher.config.PublishTimeout)
	defer cancel()
	if err := dispatcher.publisher.PublishSavedLifecycle(publishCtx, claimed.Event); err != nil {
		failedAt := dispatcher.now().UTC()
		nextAttemptNumber := claimed.AttemptCount + 1
		nextAttemptAt := failedAt.Add(savedLifecycleBackoff(
			nextAttemptNumber,
			dispatcher.config.RetryBase,
			dispatcher.config.RetryMax,
		))
		state, markErr := dispatcher.outbox.MarkSavedLifecycleFailure(
			ctx,
			claimed.Event.EventID,
			claimed.LeaseID,
			failedAt,
			nextAttemptAt,
			dispatcher.config.MaxAttempts,
			"NATS_PUBLISH_FAILED",
		)
		if markErr != nil {
			dispatcher.observer.ObserveSavedLifecycleError("FAILURE_STATE_FAILED")
			return fmt.Errorf("record Saved lifecycle publish failure: %w", markErr)
		}
		if state == model.SavedLifecycleDeliveryDead {
			dispatcher.observer.ObserveSavedLifecycleDead()
			log.Error().
				Str("event_id", claimed.Event.EventID.String()).
				Int("attempt_count", nextAttemptNumber).
				Str("error_code", "NATS_PUBLISH_FAILED").
				Msg("Saved lifecycle event retained in durable DEAD outbox state")
		} else {
			dispatcher.observer.ObserveSavedLifecycleRetry()
		}
		return nil
	}

	deliveredAt := dispatcher.now().UTC()
	if err := dispatcher.outbox.MarkSavedLifecycleDelivered(
		ctx,
		claimed.Event.EventID,
		claimed.LeaseID,
		deliveredAt,
	); err != nil {
		dispatcher.observer.ObserveSavedLifecycleError("DELIVERY_STATE_FAILED")
		return fmt.Errorf("mark Saved lifecycle event delivered: %w", err)
	}
	dispatcher.observer.ObserveSavedLifecycleDelivered()
	return nil
}

func (dispatcher *SavedLifecycleDispatcher) CleanupOnce(ctx context.Context) (int64, error) {
	if dispatcher == nil || dispatcher.outbox == nil || dispatcher.now == nil {
		return 0, fmt.Errorf("%w: dispatcher is unavailable", ErrSavedLifecycleDispatcherConfig)
	}
	deleted, err := dispatcher.outbox.DeleteExpiredSavedLifecycleEvents(
		ctx,
		dispatcher.now().UTC(),
		dispatcher.config.CleanupBatch,
	)
	if err != nil {
		return 0, fmt.Errorf("delete expired Saved lifecycle events: %w", err)
	}
	if deleted > 0 {
		dispatcher.observer.ObserveSavedLifecycleCleaned(deleted)
	}
	return deleted, nil
}

func savedLifecycleBackoff(attempt int, base, maximum time.Duration) time.Duration {
	if attempt <= 1 {
		return base
	}
	backoff := base
	for current := 1; current < attempt; current++ {
		if backoff >= maximum || backoff > maximum/2 {
			return maximum
		}
		backoff *= 2
	}
	if backoff > maximum {
		return maximum
	}
	return backoff
}

func SavedLifecycleTerminalRetention() time.Duration {
	return savedLifecycleTerminalRetention
}
