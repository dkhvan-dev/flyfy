package app

import (
	"context"
	"fmt"
	"time"

	"kz/inflap/backend/services/user-service/internal/domain/port"
)

type UserSocialOutboxBackfillRepository interface {
	BackfillFeedSocialOutbox(ctx context.Context, now time.Time) (int64, error)
}

type UserSocialOutboxReconcilerConfig struct {
	BackfillEnabled bool
	DrainEnabled    bool
	MaxDrainBatches int
	WorkerConfig    UserSocialOutboxWorkerConfig
}

type UserSocialOutboxReconcilerStats struct {
	Backfilled   int64
	Drained      int
	DrainBatches int
}

func ReconcileUserSocialOutbox(
	ctx context.Context,
	repo interface {
		UserSocialOutboxBackfillRepository
		port.UserSocialOutboxRepository
	},
	publisher port.UserSocialEventPublisher,
	cfg UserSocialOutboxReconcilerConfig,
	now time.Time,
) (UserSocialOutboxReconcilerStats, error) {
	var stats UserSocialOutboxReconcilerStats
	if repo == nil || !cfg.BackfillEnabled {
		return stats, nil
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	backfilled, err := repo.BackfillFeedSocialOutbox(ctx, now.UTC())
	if err != nil {
		return stats, fmt.Errorf("backfill feed social outbox: %w", err)
	}
	stats.Backfilled = backfilled

	if !cfg.DrainEnabled {
		return stats, nil
	}
	if publisher == nil {
		return stats, fmt.Errorf("feed social outbox drain publisher is not configured")
	}

	worker := NewUserSocialOutboxWorker(repo, publisher, cfg.WorkerConfig)
	maxBatches := cfg.MaxDrainBatches
	if maxBatches < 0 {
		maxBatches = 0
	}
	for {
		if maxBatches > 0 && stats.DrainBatches >= maxBatches {
			return stats, nil
		}
		batchStats, processErr := worker.ProcessOnce(ctx, time.Now().UTC())
		if processErr != nil {
			return stats, fmt.Errorf("drain feed social outbox: %w", processErr)
		}
		if batchStats.Fetched == 0 {
			return stats, nil
		}
		stats.DrainBatches++
		stats.Drained += batchStats.Delivered
	}
}
