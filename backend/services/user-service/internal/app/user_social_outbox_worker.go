package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/user-service/internal/domain/model"
	"kz/inflap/backend/services/user-service/internal/domain/port"
)

type UserSocialOutboxWorkerConfig struct {
	PollInterval time.Duration
	BatchSize    int
	MaxAttempts  int
	BaseBackoff  time.Duration
}

type UserSocialOutboxWorker struct {
	repo      port.UserSocialOutboxRepository
	publisher port.UserSocialEventPublisher
	cfg       UserSocialOutboxWorkerConfig
}

type UserSocialOutboxWorkerBatchStats struct {
	Fetched   int
	Published int
	Delivered int
	Failed    int
	Invalid   int
}

func NewUserSocialOutboxWorker(
	repo port.UserSocialOutboxRepository,
	publisher port.UserSocialEventPublisher,
	cfg UserSocialOutboxWorkerConfig,
) *UserSocialOutboxWorker {
	return &UserSocialOutboxWorker{
		repo:      repo,
		publisher: publisher,
		cfg:       normalizeUserSocialOutboxWorkerConfig(cfg),
	}
}

func (w *UserSocialOutboxWorker) Start(ctx context.Context) {
	if w == nil || w.repo == nil || w.publisher == nil {
		return
	}
	ticker := time.NewTicker(w.cfg.PollInterval)
	defer ticker.Stop()

	for {
		if _, err := w.ProcessOnce(ctx, time.Now().UTC()); err != nil {
			log.Error().Err(err).Msg("process user social outbox batch")
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

func (w *UserSocialOutboxWorker) processOnce(ctx context.Context, now time.Time) {
	_, _ = w.ProcessOnce(ctx, now)
}

func (w *UserSocialOutboxWorker) ProcessOnce(ctx context.Context, now time.Time) (UserSocialOutboxWorkerBatchStats, error) {
	var stats UserSocialOutboxWorkerBatchStats
	if w == nil || w.repo == nil || w.publisher == nil {
		return stats, nil
	}
	events, err := w.repo.ListDueUserSocialOutboxEvents(ctx, w.cfg.BatchSize, now)
	if err != nil {
		return stats, fmt.Errorf("list due user social outbox events: %w", err)
	}
	stats.Fetched = len(events)
	for _, event := range events {
		if err = validateUserSocialOutboxEvent(event); err != nil {
			stats.Failed++
			stats.Invalid++
			nextAttemptAt := now.Add(w.backoff(event.AttemptCount + 1))
			if markErr := w.repo.MarkUserSocialOutboxFailed(ctx, event.ID, safeUserSocialOutboxError(err), nextAttemptAt); markErr != nil {
				log.Error().Err(markErr).Str("event_id", event.ID.String()).Msg("mark invalid user social outbox failed")
			}
			continue
		}
		if err = w.publisher.PublishUserSocialEvent(ctx, event); err != nil {
			stats.Failed++
			nextAttemptAt := now.Add(w.backoff(event.AttemptCount + 1))
			if markErr := w.repo.MarkUserSocialOutboxFailed(ctx, event.ID, safeUserSocialOutboxError(err), nextAttemptAt); markErr != nil {
				log.Error().Err(markErr).Str("event_id", event.ID.String()).Msg("mark user social outbox failed")
			}
			continue
		}
		stats.Published++
		if err = w.repo.MarkUserSocialOutboxDelivered(ctx, event.ID, now); err != nil {
			log.Error().Err(err).Str("event_id", event.ID.String()).Msg("mark user social outbox delivered")
			continue
		}
		stats.Delivered++
	}
	return stats, nil
}

func (w *UserSocialOutboxWorker) backoff(attempt int) time.Duration {
	if attempt <= 0 {
		attempt = 1
	}
	if attempt > w.cfg.MaxAttempts {
		attempt = w.cfg.MaxAttempts
	}
	backoff := w.cfg.BaseBackoff
	for i := 1; i < attempt; i++ {
		backoff *= 2
	}
	maxBackoff := 5 * time.Minute
	if backoff > maxBackoff {
		return maxBackoff
	}
	return backoff
}

func normalizeUserSocialOutboxWorkerConfig(cfg UserSocialOutboxWorkerConfig) UserSocialOutboxWorkerConfig {
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
	return cfg
}

func safeUserSocialOutboxError(err error) string {
	if err == nil {
		return ""
	}
	msg := strings.TrimSpace(err.Error())
	if msg == "" {
		return ""
	}
	if len(msg) > 500 {
		return msg[:500]
	}
	return msg
}

func validateUserSocialOutboxEvent(event model.UserSocialOutboxEvent) error {
	if event.ID == uuid.Nil ||
		event.ViewerUserID == uuid.Nil ||
		event.TargetUserID == uuid.Nil ||
		event.ViewerUserID == event.TargetUserID {
		return fmt.Errorf("invalid social outbox event ids")
	}
	switch event.EdgeType {
	case model.UserSocialEdgeFollowing, model.UserSocialEdgeFriend:
	default:
		return fmt.Errorf("invalid social outbox edge type")
	}
	switch event.EventType {
	case model.UserSocialEventFollowCreated:
		if event.EdgeType != model.UserSocialEdgeFollowing || !event.Active {
			return fmt.Errorf("invalid social outbox event semantics")
		}
	case model.UserSocialEventFollowDeleted:
		if event.EdgeType != model.UserSocialEdgeFollowing || event.Active {
			return fmt.Errorf("invalid social outbox event semantics")
		}
	case model.UserSocialEventFriendshipCreated:
		if event.EdgeType != model.UserSocialEdgeFriend || !event.Active {
			return fmt.Errorf("invalid social outbox event semantics")
		}
	case model.UserSocialEventFriendshipDeleted:
		if event.EdgeType != model.UserSocialEdgeFriend || event.Active {
			return fmt.Errorf("invalid social outbox event semantics")
		}
	default:
		return fmt.Errorf("invalid social outbox event type")
	}
	return nil
}
