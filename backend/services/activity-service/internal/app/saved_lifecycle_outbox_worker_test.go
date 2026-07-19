package app

import (
	"bytes"
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

func TestActivitySavedLifecycleWorkerRedeliversIdenticalEvent(t *testing.T) {
	t.Parallel()

	event := validActivitySavedLifecycleWorkerEvent()
	repo := &activitySavedLifecycleWorkerRepository{event: &event}
	publisher := &activitySavedLifecycleWorkerPublisher{failuresRemaining: 1}
	observer := new(activitySavedLifecycleWorkerObserver)
	worker := NewActivitySavedLifecycleWorker(repo, publisher, observer, activitySavedLifecycleTestConfig())
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)

	first, err := worker.ProcessOnce(context.Background(), now)
	if err != nil {
		t.Fatalf("first ProcessOnce() error = %v", err)
	}
	if first.Failed != 1 || first.Published != 0 {
		t.Fatalf("first stats = %+v", first)
	}
	second, err := worker.ProcessOnce(context.Background(), now.Add(time.Minute))
	if err != nil {
		t.Fatalf("second ProcessOnce() error = %v", err)
	}
	if second.Published != 1 || second.Failed != 0 {
		t.Fatalf("second stats = %+v", second)
	}
	if len(publisher.payloads) != 2 || !bytes.Equal(publisher.payloads[0], publisher.payloads[1]) {
		t.Fatalf("redelivery payloads differ: %q / %q", publisher.payloads[0], publisher.payloads[1])
	}
	if publisher.eventIDs[0] != publisher.eventIDs[1] {
		t.Fatalf("redelivery event ids differ: %s / %s", publisher.eventIDs[0], publisher.eventIDs[1])
	}
	if observer.failed != 1 || observer.published != 1 {
		t.Fatalf("observer = %+v", observer)
	}
}

func TestActivitySavedLifecycleWorkerMovesExhaustedEventToDead(t *testing.T) {
	t.Parallel()

	event := validActivitySavedLifecycleWorkerEvent()
	event.MaxAttempts = 2
	repo := &activitySavedLifecycleWorkerRepository{event: &event}
	publisher := &activitySavedLifecycleWorkerPublisher{failuresRemaining: 2}
	observer := new(activitySavedLifecycleWorkerObserver)
	worker := NewActivitySavedLifecycleWorker(repo, publisher, observer, activitySavedLifecycleTestConfig())
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)

	if _, err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("first ProcessOnce() error = %v", err)
	}
	stats, err := worker.ProcessOnce(context.Background(), now.Add(time.Minute))
	if err != nil {
		t.Fatalf("second ProcessOnce() error = %v", err)
	}
	if stats.Dead != 1 || repo.deadCount != 1 || observer.dead != 1 {
		t.Fatalf("dead stats/repo/observer = %+v/%d/%d", stats, repo.deadCount, observer.dead)
	}
	third, err := worker.ProcessOnce(context.Background(), now.Add(2*time.Minute))
	if err != nil {
		t.Fatalf("third ProcessOnce() error = %v", err)
	}
	if third.Claimed != 0 {
		t.Fatalf("dead event was claimed again: %+v", third)
	}
}

func TestActivitySavedLifecycleWorkerRecordsLeaseRecoveryAndCleanup(t *testing.T) {
	t.Parallel()

	event := validActivitySavedLifecycleWorkerEvent()
	event.RecoveredLease = true
	repo := &activitySavedLifecycleWorkerRepository{event: &event, cleanupCount: 3}
	publisher := new(activitySavedLifecycleWorkerPublisher)
	observer := new(activitySavedLifecycleWorkerObserver)
	worker := NewActivitySavedLifecycleWorker(repo, publisher, observer, activitySavedLifecycleTestConfig())

	stats, err := worker.ProcessOnce(context.Background(), time.Now().UTC())
	if err != nil {
		t.Fatalf("ProcessOnce() error = %v", err)
	}
	if stats.RecoveredLease != 1 || observer.recovered != 1 {
		t.Fatalf("recovery stats/observer = %+v/%d", stats, observer.recovered)
	}
	cleanup, err := worker.CleanupOnce(context.Background(), time.Now().UTC())
	if err != nil {
		t.Fatalf("CleanupOnce() error = %v", err)
	}
	if cleanup.Cleaned != 3 || observer.cleaned != 3 {
		t.Fatalf("cleanup stats/observer = %+v/%d", cleanup, observer.cleaned)
	}
}

func TestActivitySavedLifecycleWorkerRejectsInvalidPayloadWithoutPublishing(t *testing.T) {
	t.Parallel()

	event := validActivitySavedLifecycleWorkerEvent()
	event.Payload = []byte(`{"broken"`)
	repo := &activitySavedLifecycleWorkerRepository{event: &event}
	publisher := new(activitySavedLifecycleWorkerPublisher)
	worker := NewActivitySavedLifecycleWorker(repo, publisher, nil, activitySavedLifecycleTestConfig())

	stats, err := worker.ProcessOnce(context.Background(), time.Now().UTC())
	if err != nil {
		t.Fatalf("ProcessOnce() error = %v", err)
	}
	if stats.Failed != 1 || len(publisher.payloads) != 0 || repo.lastErrorCode != "INVALID_EVENT" {
		t.Fatalf("invalid event handling = %+v/%d/%s", stats, len(publisher.payloads), repo.lastErrorCode)
	}
}

func TestActivitySavedLifecycleWorkerBoundsClaimBatchToLease(t *testing.T) {
	t.Parallel()

	worker := NewActivitySavedLifecycleWorker(
		new(activitySavedLifecycleWorkerRepository),
		new(activitySavedLifecycleWorkerPublisher),
		nil,
		ActivitySavedLifecycleWorkerConfig{
			WorkerID:       "bounded-worker",
			BatchSize:      100,
			PollInterval:   time.Second,
			LeaseDuration:  30 * time.Second,
			PublishTimeout: 2 * time.Second,
		},
	)
	if worker.cfg.BatchSize != 12 {
		t.Fatalf("normalized batch size = %d, want 12", worker.cfg.BatchSize)
	}
}

type activitySavedLifecycleWorkerRepository struct {
	mu            sync.Mutex
	event         *model.ActivitySavedLifecycleOutboxEvent
	deadCount     int
	cleanupCount  int64
	lastErrorCode string
}

func (repo *activitySavedLifecycleWorkerRepository) ClaimActivitySavedLifecycleEvents(
	_ context.Context,
	workerID string,
	_ int,
	_ time.Time,
	_ time.Duration,
) ([]model.ActivitySavedLifecycleOutboxEvent, error) {
	repo.mu.Lock()
	defer repo.mu.Unlock()
	if repo.event == nil {
		return nil, nil
	}
	copy := *repo.event
	copy.Payload = append([]byte(nil), repo.event.Payload...)
	copy.Status = model.ActivitySavedLifecycleProcessing
	copy.LockedBy = &workerID
	return []model.ActivitySavedLifecycleOutboxEvent{copy}, nil
}

func (repo *activitySavedLifecycleWorkerRepository) MarkActivitySavedLifecyclePublished(
	_ context.Context,
	_ uuid.UUID,
	_ string,
	_ time.Time,
) (bool, error) {
	repo.mu.Lock()
	defer repo.mu.Unlock()
	if repo.event == nil {
		return false, nil
	}
	repo.event = nil
	return true, nil
}

func (repo *activitySavedLifecycleWorkerRepository) MarkActivitySavedLifecycleFailed(
	_ context.Context,
	_ uuid.UUID,
	_ string,
	errorCode string,
	_ time.Time,
) (bool, bool, error) {
	repo.mu.Lock()
	defer repo.mu.Unlock()
	if repo.event == nil {
		return false, false, nil
	}
	repo.lastErrorCode = errorCode
	repo.event.AttemptCount++
	if repo.event.AttemptCount >= repo.event.MaxAttempts {
		repo.deadCount++
		repo.event = nil
		return true, true, nil
	}
	return false, true, nil
}

func (repo *activitySavedLifecycleWorkerRepository) DeleteTerminalActivitySavedLifecycleEvents(
	context.Context,
	time.Time,
	int,
) (int64, error) {
	return repo.cleanupCount, nil
}

func (*activitySavedLifecycleWorkerRepository) GetActivitySavedLifecycleQueueStats(
	context.Context,
	time.Time,
) (model.ActivitySavedLifecycleQueueStats, error) {
	return model.ActivitySavedLifecycleQueueStats{}, nil
}

type activitySavedLifecycleWorkerPublisher struct {
	failuresRemaining int
	payloads          [][]byte
	eventIDs          []uuid.UUID
}

func (publisher *activitySavedLifecycleWorkerPublisher) PublishActivitySavedLifecycle(
	_ context.Context,
	event model.ActivitySavedLifecycleOutboxEvent,
) error {
	publisher.payloads = append(publisher.payloads, append([]byte(nil), event.Payload...))
	publisher.eventIDs = append(publisher.eventIDs, event.ID)
	if publisher.failuresRemaining > 0 {
		publisher.failuresRemaining--
		return errors.New("NATS unavailable")
	}
	return nil
}

type activitySavedLifecycleWorkerObserver struct {
	published int
	failed    int
	dead      int
	recovered int
	cleaned   int64
}

func (*activitySavedLifecycleWorkerObserver) SetSavedLifecycleQueueStats(model.ActivitySavedLifecycleQueueStats) {
}
func (observer *activitySavedLifecycleWorkerObserver) RecordSavedLifecyclePublished() {
	observer.published++
}
func (observer *activitySavedLifecycleWorkerObserver) RecordSavedLifecycleFailed() {
	observer.failed++
}
func (observer *activitySavedLifecycleWorkerObserver) RecordSavedLifecycleDead() {
	observer.dead++
}
func (observer *activitySavedLifecycleWorkerObserver) RecordSavedLifecycleLeaseRecovered() {
	observer.recovered++
}
func (observer *activitySavedLifecycleWorkerObserver) RecordSavedLifecycleCleaned(count int64) {
	observer.cleaned += count
}
func (*activitySavedLifecycleWorkerObserver) ObserveSavedLifecyclePublishDuration(time.Duration) {
}

func validActivitySavedLifecycleWorkerEvent() model.ActivitySavedLifecycleOutboxEvent {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	return model.ActivitySavedLifecycleOutboxEvent{
		ID:                 uuid.New(),
		ActivityID:         uuid.New(),
		Subject:            model.ActivitySavedLifecycleSubjectV1,
		SchemaVersion:      1,
		Kind:               model.ActivitySavedLifecycleUpdated,
		Visibility:         "PUBLIC",
		SourceRevision:     10,
		ProjectionRevision: 11,
		VisibilityRevision: 12,
		Payload:            []byte(`{"event_id":"stable"}`),
		Status:             model.ActivitySavedLifecyclePending,
		MaxAttempts:        3,
		OccurredAt:         now,
		CreatedAt:          now,
	}
}

func activitySavedLifecycleTestConfig() ActivitySavedLifecycleWorkerConfig {
	return ActivitySavedLifecycleWorkerConfig{
		WorkerID:         "test-worker",
		BatchSize:        10,
		PollInterval:     time.Second,
		LeaseDuration:    30 * time.Second,
		PublishTimeout:   time.Second,
		RetryBaseDelay:   time.Second,
		RetryMaxDelay:    time.Minute,
		CleanupInterval:  time.Minute,
		CleanupBatchSize: 10,
	}
}
