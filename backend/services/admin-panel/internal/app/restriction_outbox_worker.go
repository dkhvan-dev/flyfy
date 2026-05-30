package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/rs/zerolog/log"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

type RestrictionOutboxWorkerConfig struct {
	PollInterval time.Duration
	BatchSize    int
	MaxAttempts  int
	BaseBackoff  time.Duration
}

type RestrictionOutboxWorker struct {
	repo   port.UserRestrictionOutboxRepository
	client port.TrustRestrictionEventClient
	cfg    RestrictionOutboxWorkerConfig
}

func NewRestrictionOutboxWorker(
	repo port.UserRestrictionOutboxRepository,
	client port.TrustRestrictionEventClient,
	cfg RestrictionOutboxWorkerConfig,
) *RestrictionOutboxWorker {
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
	return &RestrictionOutboxWorker{
		repo:   repo,
		client: client,
		cfg:    cfg,
	}
}

func (w *RestrictionOutboxWorker) Start(ctx context.Context) {
	if w == nil {
		return
	}
	ticker := time.NewTicker(w.cfg.PollInterval)
	defer ticker.Stop()

	for {
		if err := w.ProcessOnce(ctx, time.Now().UTC()); err != nil {
			log.Error().Err(err).Msg("trust restriction outbox processing failed")
		}

		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

func (w *RestrictionOutboxWorker) ProcessOnce(ctx context.Context, now time.Time) error {
	if w == nil || w.repo == nil || w.client == nil {
		return fmt.Errorf("%w: restriction outbox worker dependencies are required", ErrInvalidInput)
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	events, err := w.repo.ListDueUserRestrictionEvents(ctx, w.cfg.BatchSize, now)
	if err != nil {
		return err
	}
	for _, event := range events {
		applied, err := w.client.ApplyUserRestrictionEvent(ctx, event)
		if err != nil {
			nextAttemptAt := now.Add(w.backoff(event.AttemptCount + 1))
			if markErr := w.repo.MarkUserRestrictionEventFailed(ctx, event.ID, safeOutboxError(err), nextAttemptAt); markErr != nil {
				return markErr
			}
			log.Warn().
				Err(err).
				Str("event_id", event.ID.String()).
				Str("event_type", event.EventType).
				Int("attempt_count", event.AttemptCount+1).
				Time("next_attempt_at", nextAttemptAt).
				Msg("trust restriction outbox delivery failed")
			continue
		}

		if err := w.repo.MarkUserRestrictionEventDelivered(ctx, event.ID, now); err != nil {
			return err
		}
		log.Info().
			Str("event_id", event.ID.String()).
			Str("event_type", event.EventType).
			Bool("applied", applied).
			Msg("trust restriction outbox delivered")
	}
	return nil
}

func (w *RestrictionOutboxWorker) backoff(attempt int) time.Duration {
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

func safeOutboxError(err error) string {
	if err == nil {
		return ""
	}
	value := strings.TrimSpace(err.Error())
	if len(value) > 512 {
		return value[:512]
	}
	return value
}
