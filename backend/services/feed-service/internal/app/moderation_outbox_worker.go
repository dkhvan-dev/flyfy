package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

type PostModerationOutboxWorkerConfig struct {
	PollInterval time.Duration
	BatchSize    int
	MaxAttempts  int
	BaseBackoff  time.Duration
}

type PostModerationOutboxWorker struct {
	repo      port.PostModerationOutboxRepository
	publisher port.PostModerationOutboxPublisher
	cfg       PostModerationOutboxWorkerConfig
}

func NewPostModerationOutboxWorker(
	repo port.PostModerationOutboxRepository,
	publisher port.PostModerationOutboxPublisher,
	cfg PostModerationOutboxWorkerConfig,
) *PostModerationOutboxWorker {
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
	return &PostModerationOutboxWorker{
		repo:      repo,
		publisher: publisher,
		cfg:       cfg,
	}
}

func (w *PostModerationOutboxWorker) Start(ctx context.Context) {
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

func (w *PostModerationOutboxWorker) ProcessOnce(ctx context.Context, now time.Time) error {
	if w == nil || w.repo == nil || w.publisher == nil {
		return fmt.Errorf("post moderation outbox worker dependencies are required")
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	events, err := w.repo.ListDuePostModerationOutboxEvents(ctx, w.cfg.BatchSize, now)
	if err != nil {
		return err
	}
	for _, event := range events {
		if _, err = w.publisher.PublishPostModerationOutboxEvent(ctx, event); err != nil {
			nextAttemptAt := now.Add(w.backoff(event.AttemptCount + 1))
			if markErr := w.repo.MarkPostModerationOutboxFailed(ctx, event.ID, safePostModerationOutboxError(err), nextAttemptAt); markErr != nil {
				return markErr
			}
			continue
		}
		if err = w.repo.MarkPostModerationOutboxDelivered(ctx, event.ID, now); err != nil {
			return err
		}
	}
	return nil
}

func (w *PostModerationOutboxWorker) backoff(attempt int) time.Duration {
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

func safePostModerationOutboxError(err error) string {
	if err == nil {
		return ""
	}
	value := strings.TrimSpace(err.Error())
	if len(value) > 512 {
		return value[:512]
	}
	return value
}
