package app

import (
	"context"
	"encoding/json"
	"fmt"
	"hash/fnv"
	"time"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

type ActivitySavedLifecycleWorkerConfig struct {
	WorkerID         string
	BatchSize        int
	PollInterval     time.Duration
	LeaseDuration    time.Duration
	PublishTimeout   time.Duration
	RetryBaseDelay   time.Duration
	RetryMaxDelay    time.Duration
	CleanupInterval  time.Duration
	CleanupBatchSize int
}

type ActivitySavedLifecycleObserver interface {
	SetSavedLifecycleQueueStats(model.ActivitySavedLifecycleQueueStats)
	RecordSavedLifecyclePublished()
	RecordSavedLifecycleFailed()
	RecordSavedLifecycleDead()
	RecordSavedLifecycleLeaseRecovered()
	RecordSavedLifecycleCleaned(int64)
	ObserveSavedLifecyclePublishDuration(time.Duration)
}

type ActivitySavedLifecycleWorker struct {
	repo      port.ActivitySavedLifecycleOutboxRepository
	publisher port.ActivitySavedLifecyclePublisher
	observer  ActivitySavedLifecycleObserver
	cfg       ActivitySavedLifecycleWorkerConfig
}

type ActivitySavedLifecycleBatchStats struct {
	Claimed        int
	Published      int
	Failed         int
	Dead           int
	RecoveredLease int
	Cleaned        int64
}

func NewActivitySavedLifecycleWorker(
	repo port.ActivitySavedLifecycleOutboxRepository,
	publisher port.ActivitySavedLifecyclePublisher,
	observer ActivitySavedLifecycleObserver,
	cfg ActivitySavedLifecycleWorkerConfig,
) *ActivitySavedLifecycleWorker {
	return &ActivitySavedLifecycleWorker{
		repo:      repo,
		publisher: publisher,
		observer:  observer,
		cfg:       normalizeActivitySavedLifecycleWorkerConfig(cfg),
	}
}

func (worker *ActivitySavedLifecycleWorker) Run(ctx context.Context) error {
	if worker == nil || worker.repo == nil || worker.publisher == nil {
		return fmt.Errorf("activity Saved lifecycle worker dependencies are unavailable")
	}
	pollTicker := time.NewTicker(worker.cfg.PollInterval)
	cleanupTicker := time.NewTicker(worker.cfg.CleanupInterval)
	defer pollTicker.Stop()
	defer cleanupTicker.Stop()

	for {
		if _, err := worker.ProcessOnce(ctx, time.Now().UTC()); err != nil && ctx.Err() == nil {
			log.Error().Err(err).Msg("process activity Saved lifecycle outbox")
		}
		select {
		case <-ctx.Done():
			return nil
		case <-pollTicker.C:
		case now := <-cleanupTicker.C:
			if _, err := worker.CleanupOnce(ctx, now.UTC()); err != nil && ctx.Err() == nil {
				log.Error().Err(err).Msg("clean activity Saved lifecycle outbox")
			}
		}
	}
}

func (worker *ActivitySavedLifecycleWorker) ProcessOnce(
	ctx context.Context,
	now time.Time,
) (ActivitySavedLifecycleBatchStats, error) {
	var stats ActivitySavedLifecycleBatchStats
	events, err := worker.repo.ClaimActivitySavedLifecycleEvents(
		ctx,
		worker.cfg.WorkerID,
		worker.cfg.BatchSize,
		now,
		worker.cfg.LeaseDuration,
	)
	if err != nil {
		return stats, err
	}
	stats.Claimed = len(events)
	for _, event := range events {
		if ctx.Err() != nil {
			return stats, nil
		}
		if event.RecoveredLease {
			stats.RecoveredLease++
			if worker.observer != nil {
				worker.observer.RecordSavedLifecycleLeaseRecovered()
			}
		}

		errorCode := ""
		if err = event.ValidateSemanticEnvelope(); err != nil || !json.Valid(event.Payload) {
			errorCode = "INVALID_EVENT"
		} else {
			startedAt := time.Now()
			publishCtx, cancel := context.WithTimeout(ctx, worker.cfg.PublishTimeout)
			err = worker.publisher.PublishActivitySavedLifecycle(publishCtx, event)
			cancel()
			if worker.observer != nil {
				worker.observer.ObserveSavedLifecyclePublishDuration(time.Since(startedAt))
			}
			if err != nil {
				errorCode = "PUBLISH_FAILED"
			}
		}

		if errorCode != "" {
			dead, updated, markErr := worker.repo.MarkActivitySavedLifecycleFailed(
				ctx,
				event.ID,
				worker.cfg.WorkerID,
				errorCode,
				time.Now().UTC().Add(worker.retryDelay(event)),
			)
			if markErr != nil {
				return stats, markErr
			}
			if updated {
				stats.Failed++
				if worker.observer != nil {
					worker.observer.RecordSavedLifecycleFailed()
				}
			}
			if dead {
				stats.Dead++
				if worker.observer != nil {
					worker.observer.RecordSavedLifecycleDead()
				}
			}
			continue
		}

		published, markErr := worker.repo.MarkActivitySavedLifecyclePublished(
			ctx,
			event.ID,
			worker.cfg.WorkerID,
			time.Now().UTC(),
		)
		if markErr != nil {
			return stats, markErr
		}
		if published {
			stats.Published++
			if worker.observer != nil {
				worker.observer.RecordSavedLifecyclePublished()
			}
		}
	}

	if worker.observer != nil {
		queueStats, statsErr := worker.repo.GetActivitySavedLifecycleQueueStats(ctx, time.Now().UTC())
		if statsErr == nil {
			worker.observer.SetSavedLifecycleQueueStats(queueStats)
		}
	}
	return stats, nil
}

func (worker *ActivitySavedLifecycleWorker) CleanupOnce(
	ctx context.Context,
	now time.Time,
) (ActivitySavedLifecycleBatchStats, error) {
	var stats ActivitySavedLifecycleBatchStats
	cleaned, err := worker.repo.DeleteTerminalActivitySavedLifecycleEvents(
		ctx,
		now,
		worker.cfg.CleanupBatchSize,
	)
	if err != nil {
		return stats, err
	}
	stats.Cleaned = cleaned
	if worker.observer != nil && cleaned > 0 {
		worker.observer.RecordSavedLifecycleCleaned(cleaned)
	}
	return stats, nil
}

func (worker *ActivitySavedLifecycleWorker) retryDelay(
	event model.ActivitySavedLifecycleOutboxEvent,
) time.Duration {
	attempt := event.AttemptCount + 1
	if attempt < 1 {
		attempt = 1
	}
	delay := worker.cfg.RetryBaseDelay
	for index := 1; index < attempt && delay < worker.cfg.RetryMaxDelay; index++ {
		if delay > worker.cfg.RetryMaxDelay/2 {
			delay = worker.cfg.RetryMaxDelay
			break
		}
		delay *= 2
	}
	if delay > worker.cfg.RetryMaxDelay {
		delay = worker.cfg.RetryMaxDelay
	}

	// Stable per-event jitter avoids a synchronized retry wave while keeping
	// tests and redelivery timing deterministic.
	hasher := fnv.New32a()
	_, _ = hasher.Write(event.ID[:])
	jitterPercent := int(hasher.Sum32()%41) - 20
	jittered := delay + time.Duration(int64(delay)*int64(jitterPercent)/100)
	if jittered < worker.cfg.RetryBaseDelay/2 {
		return worker.cfg.RetryBaseDelay / 2
	}
	return jittered
}

func normalizeActivitySavedLifecycleWorkerConfig(
	cfg ActivitySavedLifecycleWorkerConfig,
) ActivitySavedLifecycleWorkerConfig {
	if cfg.WorkerID == "" {
		cfg.WorkerID = "activity-saved-lifecycle-worker"
	}
	if cfg.BatchSize <= 0 || cfg.BatchSize > 100 {
		cfg.BatchSize = 50
	}
	if cfg.PollInterval <= 0 {
		cfg.PollInterval = time.Second
	}
	if cfg.LeaseDuration <= 0 || cfg.LeaseDuration > 10*time.Minute {
		cfg.LeaseDuration = 2 * time.Minute
	}
	if cfg.PublishTimeout <= 0 || cfg.PublishTimeout >= cfg.LeaseDuration {
		cfg.PublishTimeout = min(2*time.Second, cfg.LeaseDuration/2)
	}
	maxSafeBatch := maxActivitySavedLifecycleBatchForLease(cfg.LeaseDuration, cfg.PublishTimeout)
	if cfg.BatchSize > maxSafeBatch {
		cfg.BatchSize = maxSafeBatch
	}
	if cfg.RetryBaseDelay <= 0 {
		cfg.RetryBaseDelay = time.Second
	}
	if cfg.RetryMaxDelay < cfg.RetryBaseDelay {
		cfg.RetryMaxDelay = 5 * time.Minute
	}
	if cfg.CleanupInterval <= 0 {
		cfg.CleanupInterval = time.Minute
	}
	if cfg.CleanupBatchSize <= 0 || cfg.CleanupBatchSize > 1000 {
		cfg.CleanupBatchSize = 200
	}
	return cfg
}

func maxActivitySavedLifecycleBatchForLease(leaseDuration time.Duration, publishTimeout time.Duration) int {
	if leaseDuration <= 0 || publishTimeout <= 0 {
		return 1
	}
	safetyMargin := min(10*time.Second, leaseDuration/5)
	processingBudget := leaseDuration - safetyMargin
	if processingBudget <= 0 {
		return 1
	}
	maxBatch := int(processingBudget / publishTimeout)
	if maxBatch < 1 {
		return 1
	}
	return min(maxBatch, 100)
}
