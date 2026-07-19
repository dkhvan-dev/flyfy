package app

import (
	"context"
	"encoding/binary"
	"errors"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

const savedLifecyclePublishFailureCode = "NATS_PUBLISH_FAILED"

type SavedLifecyclePublisher interface {
	PublishSavedLifecycle(ctx context.Context, message *model.SavedLifecycleOutboxMessage) error
}

type SavedLifecycleDispatcherConfig struct {
	BatchSize          int
	Concurrency        int
	PollInterval       time.Duration
	LeaseDuration      time.Duration
	PublishTimeout     time.Duration
	DeliveredRetention time.Duration
	DeadRetention      time.Duration
	CleanupInterval    time.Duration
	CleanupBatchSize   int
}

func DefaultSavedLifecycleDispatcherConfig() SavedLifecycleDispatcherConfig {
	return SavedLifecycleDispatcherConfig{
		BatchSize:          50,
		Concurrency:        8,
		PollInterval:       250 * time.Millisecond,
		LeaseDuration:      30 * time.Second,
		PublishTimeout:     3 * time.Second,
		DeliveredRetention: 14 * 24 * time.Hour,
		DeadRetention:      90 * 24 * time.Hour,
		CleanupInterval:    time.Hour,
		CleanupBatchSize:   200,
	}
}

func (c SavedLifecycleDispatcherConfig) Validate() error {
	if c.BatchSize < 1 || c.BatchSize > 200 || c.Concurrency < 1 || c.Concurrency > 32 ||
		c.PollInterval < 50*time.Millisecond || c.LeaseDuration <= c.PublishTimeout ||
		c.PublishTimeout <= 0 || c.DeliveredRetention <= 0 || c.DeadRetention <= 0 ||
		c.CleanupInterval <= 0 || c.CleanupBatchSize < 1 || c.CleanupBatchSize > 200 {
		return model.ErrInvalidSavedLifecycleState
	}
	return nil
}

type SavedLifecycleDispatcher struct {
	repo      port.SavedLifecycleOutboxRepository
	publisher SavedLifecyclePublisher
	config    SavedLifecycleDispatcherConfig
	now       func() time.Time
}

func NewSavedLifecycleDispatcher(
	repo port.SavedLifecycleOutboxRepository,
	publisher SavedLifecyclePublisher,
	config SavedLifecycleDispatcherConfig,
) (*SavedLifecycleDispatcher, error) {
	if repo == nil || publisher == nil {
		return nil, model.ErrInvalidSavedLifecycleState
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}
	return &SavedLifecycleDispatcher{
		repo:      repo,
		publisher: publisher,
		config:    config,
		now:       time.Now,
	}, nil
}

func (d *SavedLifecycleDispatcher) Run(ctx context.Context) error {
	if d == nil || d.repo == nil || d.publisher == nil || d.now == nil {
		return model.ErrInvalidSavedLifecycleState
	}
	pollTimer := time.NewTimer(0)
	defer pollTimer.Stop()
	cleanupTicker := time.NewTicker(d.config.CleanupInterval)
	defer cleanupTicker.Stop()

	for {
		select {
		case <-ctx.Done():
			return nil
		case <-cleanupTicker.C:
			if _, err := d.repo.DeleteSavedLifecycleTerminal(
				ctx,
				d.now().UTC(),
				d.config.CleanupBatchSize,
			); err != nil && !errors.Is(err, context.Canceled) {
				log.Error().Err(err).Msg("Saved lifecycle outbox cleanup failed")
			}
		case <-pollTimer.C:
			processed, err := d.DispatchBatch(ctx)
			if err != nil && !errors.Is(err, context.Canceled) {
				log.Error().Err(err).Msg("Saved lifecycle outbox dispatch failed")
			}
			delay := d.config.PollInterval
			if processed == d.config.BatchSize {
				delay = 0
			}
			pollTimer.Reset(delay)
		}
	}
}

func (d *SavedLifecycleDispatcher) DispatchBatch(ctx context.Context) (int, error) {
	if d == nil || d.repo == nil || d.publisher == nil || d.now == nil {
		return 0, model.ErrInvalidSavedLifecycleState
	}
	claimedAt := d.now().UTC()
	items, err := d.repo.ClaimSavedLifecycleOutbox(
		ctx,
		claimedAt,
		d.config.BatchSize,
		d.config.LeaseDuration,
	)
	if err != nil {
		return 0, err
	}
	if len(items) == 0 {
		return 0, nil
	}

	jobs := make(chan *model.SavedLifecycleOutboxMessage)
	var workers sync.WaitGroup
	workerCount := min(d.config.Concurrency, len(items))
	workers.Add(workerCount)
	for range workerCount {
		go func() {
			defer workers.Done()
			for item := range jobs {
				d.dispatchOne(ctx, item)
			}
		}()
	}
	for _, item := range items {
		select {
		case jobs <- item:
		case <-ctx.Done():
			close(jobs)
			workers.Wait()
			return len(items), ctx.Err()
		}
	}
	close(jobs)
	workers.Wait()
	return len(items), nil
}

func (d *SavedLifecycleDispatcher) dispatchOne(
	ctx context.Context,
	item *model.SavedLifecycleOutboxMessage,
) {
	if item == nil || item.Validate() != nil {
		return
	}
	publishCtx, cancel := context.WithTimeout(ctx, d.config.PublishTimeout)
	err := d.publisher.PublishSavedLifecycle(publishCtx, item)
	cancel()
	finishedAt := d.now().UTC()
	if err == nil {
		if markErr := d.repo.MarkSavedLifecycleDelivered(
			ctx,
			item.EventID,
			item.LeaseToken,
			finishedAt,
			d.config.DeliveredRetention,
		); markErr != nil && !errors.Is(markErr, context.Canceled) {
			log.Error().Err(markErr).Msg("failed to mark Saved lifecycle event delivered")
		}
		return
	}
	if ctx.Err() != nil {
		return
	}

	dead := item.AttemptCount >= item.MaxAttempts
	nextAttemptAt := finishedAt
	retention := time.Duration(0)
	if dead {
		retention = d.config.DeadRetention
	} else {
		nextAttemptAt = finishedAt.Add(savedLifecycleRetryDelay(item.AttemptCount, item.EventID))
	}
	if markErr := d.repo.MarkSavedLifecycleFailed(
		ctx,
		item.EventID,
		item.LeaseToken,
		finishedAt,
		nextAttemptAt,
		savedLifecyclePublishFailureCode,
		dead,
		retention,
	); markErr != nil && !errors.Is(markErr, context.Canceled) {
		log.Error().Err(markErr).Msg("failed to persist Saved lifecycle delivery failure")
	}
}

func savedLifecycleRetryDelay(attempt int, eventID uuid.UUID) time.Duration {
	if attempt < 1 {
		attempt = 1
	}
	shift := min(attempt-1, 8)
	delay := time.Second * time.Duration(1<<shift)
	if eventID != uuid.Nil {
		jitterWindow := delay / 5
		if jitterWindow > 0 {
			delay += time.Duration(binary.BigEndian.Uint16(eventID[:2])) % jitterWindow
		}
	}
	if delay > 5*time.Minute {
		return 5 * time.Minute
	}
	return delay
}
