package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

type ActivitySavedLifecycleOutboxRepository interface {
	ClaimActivitySavedLifecycleEvents(
		ctx context.Context,
		workerID string,
		limit int,
		now time.Time,
		leaseDuration time.Duration,
	) ([]model.ActivitySavedLifecycleOutboxEvent, error)
	MarkActivitySavedLifecyclePublished(
		ctx context.Context,
		eventID uuid.UUID,
		workerID string,
		publishedAt time.Time,
	) (bool, error)
	MarkActivitySavedLifecycleFailed(
		ctx context.Context,
		eventID uuid.UUID,
		workerID string,
		errorCode string,
		nextAttemptAt time.Time,
	) (dead bool, updated bool, err error)
	DeleteTerminalActivitySavedLifecycleEvents(
		ctx context.Context,
		before time.Time,
		limit int,
	) (int64, error)
	GetActivitySavedLifecycleQueueStats(
		ctx context.Context,
		now time.Time,
	) (model.ActivitySavedLifecycleQueueStats, error)
}

type ActivitySavedLifecyclePublisher interface {
	PublishActivitySavedLifecycle(
		ctx context.Context,
		event model.ActivitySavedLifecycleOutboxEvent,
	) error
}
