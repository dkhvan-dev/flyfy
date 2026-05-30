package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestRestrictionOutboxWorkerDeliversCreatedEvent(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, 5, 30, 10, 0, 0, 0, time.UTC)
	event := model.UserRestrictionOutboxEvent{
		ID:          uuid.New(),
		EventType:   model.UserRestrictionOutboxEventCreated,
		AggregateID: uuid.New(),
		UserID:      uuid.New(),
		Status:      model.UserRestrictionOutboxPending,
		CreatedAt:   now.Add(-time.Minute),
	}
	repo := &restrictionOutboxRepoFake{events: []model.UserRestrictionOutboxEvent{event}}
	client := &trustRestrictionClientFake{}
	worker := NewRestrictionOutboxWorker(repo, client, RestrictionOutboxWorkerConfig{
		BatchSize:   10,
		MaxAttempts: 3,
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(ctx, now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if len(client.delivered) != 1 || client.delivered[0].ID != event.ID {
		t.Fatalf("expected trust client delivery, got %#v", client.delivered)
	}
	if repo.delivered[event.ID].IsZero() {
		t.Fatal("expected outbox event to be marked delivered")
	}
}

func TestRestrictionOutboxWorkerMarksFailureWithBackoff(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, 5, 30, 10, 5, 0, 0, time.UTC)
	event := model.UserRestrictionOutboxEvent{
		ID:          uuid.New(),
		EventType:   model.UserRestrictionOutboxEventCreated,
		AggregateID: uuid.New(),
		UserID:      uuid.New(),
		Status:      model.UserRestrictionOutboxPending,
		CreatedAt:   now.Add(-time.Minute),
	}
	repo := &restrictionOutboxRepoFake{events: []model.UserRestrictionOutboxEvent{event}}
	client := &trustRestrictionClientFake{err: errors.New("trust unavailable")}
	worker := NewRestrictionOutboxWorker(repo, client, RestrictionOutboxWorkerConfig{
		BatchSize:   10,
		MaxAttempts: 3,
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(ctx, now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	failed := repo.failed[event.ID]
	if failed.reason == "" {
		t.Fatal("expected failure reason to be stored")
	}
	if !failed.nextAttemptAt.After(now) {
		t.Fatalf("expected retry after now, got %s", failed.nextAttemptAt)
	}
}

func TestRestrictionOutboxWorkerTreatsDuplicateApplyAsDelivered(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, 5, 30, 10, 10, 0, 0, time.UTC)
	event := model.UserRestrictionOutboxEvent{
		ID:          uuid.New(),
		EventType:   model.UserRestrictionOutboxEventCreated,
		AggregateID: uuid.New(),
		UserID:      uuid.New(),
		Status:      model.UserRestrictionOutboxPending,
		CreatedAt:   now.Add(-time.Minute),
	}
	repo := &restrictionOutboxRepoFake{events: []model.UserRestrictionOutboxEvent{event}}
	client := &trustRestrictionClientFake{applied: false}
	worker := NewRestrictionOutboxWorker(repo, client, RestrictionOutboxWorkerConfig{
		BatchSize:   10,
		MaxAttempts: 3,
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(ctx, now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if repo.delivered[event.ID].IsZero() {
		t.Fatal("expected duplicate trust apply to be marked delivered")
	}
}

type restrictionOutboxRepoFake struct {
	events    []model.UserRestrictionOutboxEvent
	delivered map[uuid.UUID]time.Time
	failed    map[uuid.UUID]struct {
		reason        string
		nextAttemptAt time.Time
	}
}

func (r *restrictionOutboxRepoFake) ListDueUserRestrictionEvents(_ context.Context, limit int, _ time.Time) ([]model.UserRestrictionOutboxEvent, error) {
	if limit > 0 && len(r.events) > limit {
		return r.events[:limit], nil
	}
	return r.events, nil
}

func (r *restrictionOutboxRepoFake) MarkUserRestrictionEventDelivered(_ context.Context, eventID uuid.UUID, deliveredAt time.Time) error {
	if r.delivered == nil {
		r.delivered = make(map[uuid.UUID]time.Time)
	}
	r.delivered[eventID] = deliveredAt
	return nil
}

func (r *restrictionOutboxRepoFake) MarkUserRestrictionEventFailed(_ context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error {
	if r.failed == nil {
		r.failed = make(map[uuid.UUID]struct {
			reason        string
			nextAttemptAt time.Time
		})
	}
	r.failed[eventID] = struct {
		reason        string
		nextAttemptAt time.Time
	}{reason: reason, nextAttemptAt: nextAttemptAt}
	return nil
}

type trustRestrictionClientFake struct {
	applied   bool
	err       error
	delivered []model.UserRestrictionOutboxEvent
}

func (c *trustRestrictionClientFake) ApplyUserRestrictionEvent(_ context.Context, event model.UserRestrictionOutboxEvent) (bool, error) {
	if c.err != nil {
		return false, c.err
	}
	c.delivered = append(c.delivered, event)
	return c.applied, nil
}
