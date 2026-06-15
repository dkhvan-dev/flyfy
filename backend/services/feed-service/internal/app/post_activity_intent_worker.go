package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

type PostActivityIntentWorkerConfig struct {
	PollInterval time.Duration
	BatchSize    int
	MaxAttempts  int
	BaseBackoff  time.Duration
}

type PostActivityIntentWorker struct {
	repo      port.PostActivityIntentRepository
	publisher port.PostActivityIntentPublisher
	cfg       PostActivityIntentWorkerConfig
}

func NewPostActivityIntentWorker(
	repo port.PostActivityIntentRepository,
	publisher port.PostActivityIntentPublisher,
	cfg PostActivityIntentWorkerConfig,
) *PostActivityIntentWorker {
	if cfg.PollInterval <= 0 {
		cfg.PollInterval = 5 * time.Second
	}
	if cfg.BatchSize <= 0 {
		cfg.BatchSize = 50
	}
	if cfg.MaxAttempts <= 0 {
		cfg.MaxAttempts = 20
	}
	if cfg.BaseBackoff <= 0 {
		cfg.BaseBackoff = time.Second
	}
	return &PostActivityIntentWorker{
		repo:      repo,
		publisher: publisher,
		cfg:       cfg,
	}
}

func (w *PostActivityIntentWorker) Start(ctx context.Context) {
	if w == nil {
		return
	}
	ticker := time.NewTicker(w.cfg.PollInterval)
	defer ticker.Stop()

	for {
		_ = w.ProcessOnce(ctx, time.Now().UTC())

		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

func (w *PostActivityIntentWorker) ProcessOnce(ctx context.Context, now time.Time) error {
	if w == nil || w.repo == nil || w.publisher == nil {
		return fmt.Errorf("post activity intent worker dependencies are required")
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	events, err := w.repo.ListDuePostActivityIntentEvents(ctx, w.cfg.BatchSize, now)
	if err != nil {
		return err
	}
	for _, event := range events {
		activityID, publishErr := w.publisher.PublishPostActivityIntent(ctx, event)
		if publishErr != nil {
			attempt := event.AttemptCount + 1
			nextAttemptAt := now.Add(w.backoff(attempt))
			terminal := attempt >= w.cfg.MaxAttempts
			if markErr := w.repo.MarkPostActivityIntentFailed(
				ctx,
				event.ID,
				event.PostID,
				safePostActivityIntentWorkerError(publishErr),
				nextAttemptAt,
				terminal,
			); markErr != nil {
				return markErr
			}
			continue
		}
		if err = w.repo.MarkPostActivityIntentDelivered(ctx, event.ID, event.PostID, activityID, now); err != nil {
			return err
		}
	}
	return nil
}

func (w *PostActivityIntentWorker) backoff(attempt int) time.Duration {
	if attempt < 1 {
		attempt = 1
	}
	if w.cfg.MaxAttempts > 0 && attempt > w.cfg.MaxAttempts {
		attempt = w.cfg.MaxAttempts
	}
	if attempt > 6 {
		attempt = 6
	}
	return w.cfg.BaseBackoff * time.Duration(1<<uint(attempt-1))
}

func safePostActivityIntentWorkerError(err error) string {
	if err == nil {
		return ""
	}
	value := strings.TrimSpace(err.Error())
	if len(value) > 512 {
		return value[:512]
	}
	return value
}
