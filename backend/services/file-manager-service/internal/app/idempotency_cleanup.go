package app

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"
)

type ExpiredIdempotencyCleaner interface {
	DeleteExpired(ctx context.Context, limit int) (int64, error)
}

type IdempotencyCleanupWorker struct {
	repo     ExpiredIdempotencyCleaner
	interval time.Duration
	limit    int
}

func NewIdempotencyCleanupWorker(
	repo ExpiredIdempotencyCleaner,
	interval time.Duration,
	limit int,
) *IdempotencyCleanupWorker {
	if interval <= 0 {
		interval = time.Hour
	}
	if limit <= 0 {
		limit = 1000
	}

	return &IdempotencyCleanupWorker{
		repo:     repo,
		interval: interval,
		limit:    limit,
	}
}

func (w *IdempotencyCleanupWorker) Start(ctx context.Context) {
	ticker := time.NewTicker(w.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			deleted, err := w.repo.DeleteExpired(ctx, w.limit)
			if err != nil {
				log.Error().Err(err).Msg("idempotency cleanup failed")
				continue
			}

			if deleted > 0 {
				log.Info().Int64("deleted", deleted).Msg("expired idempotency keys cleaned")
			}
		}
	}
}
