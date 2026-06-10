package app

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
)

type ExpiredUnboundUploadCleaner interface {
	CleanupExpiredUnboundUploads(ctx context.Context, purpose enum.FilePurpose, limit int) (int, error)
}

type ExpiredUploadCleanupWorker struct {
	cleaner  ExpiredUnboundUploadCleaner
	purpose  enum.FilePurpose
	interval time.Duration
	limit    int
}

func NewExpiredUploadCleanupWorker(
	cleaner ExpiredUnboundUploadCleaner,
	purpose enum.FilePurpose,
	interval time.Duration,
	limit int,
) *ExpiredUploadCleanupWorker {
	if interval <= 0 {
		interval = time.Hour
	}
	if limit <= 0 {
		limit = 100
	}

	return &ExpiredUploadCleanupWorker{
		cleaner:  cleaner,
		purpose:  purpose,
		interval: interval,
		limit:    limit,
	}
}

func (w *ExpiredUploadCleanupWorker) Start(ctx context.Context) {
	ticker := time.NewTicker(w.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			deleted, err := w.cleaner.CleanupExpiredUnboundUploads(ctx, w.purpose, w.limit)
			if err != nil {
				log.Error().
					Err(err).
					Str("purpose", string(w.purpose)).
					Msg("expired unbound upload cleanup failed")
				continue
			}

			if deleted > 0 {
				log.Info().
					Int("deleted", deleted).
					Str("purpose", string(w.purpose)).
					Msg("expired unbound uploads cleaned")
			}
		}
	}
}
