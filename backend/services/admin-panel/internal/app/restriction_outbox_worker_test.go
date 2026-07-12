package app

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

func TestRestrictionOutboxWorkerDeliversCreatedEvent(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, 5, 30, 10, 0, 0, 0, time.UTC)
	event := newRestrictionOutboxEvent(t, model.UserRestrictionOutboxEventCreated, now)
	repo := &restrictionOutboxRepoFake{events: []model.UserRestrictionOutboxEvent{event}}
	client := &trustRestrictionClientFake{applied: true}
	notifier := &restrictionNotificationGatewayFake{}
	worker := NewRestrictionOutboxWorker(repo, client, notifier, RestrictionOutboxWorkerConfig{
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
	if len(notifier.sent) != 1 {
		t.Fatalf("expected one user notification, got %d", len(notifier.sent))
	}
	got := notifier.sent[0]
	if got.Priority != adminNotificationPriorityHigh || got.Data["adminEvent"] != "user_restriction_created" {
		t.Fatalf("unexpected created restriction notification: %#v", got)
	}
	if got.Data["restrictionCode"] != string(model.UserRestrictionChat) || got.Data["reasonCode"] != "spam" {
		t.Fatalf("unexpected restriction notification data: %#v", got.Data)
	}
	if repo.delivered[event.ID].IsZero() {
		t.Fatal("expected outbox event to be marked delivered")
	}
}

func TestRestrictionOutboxWorkerDeliversLiftedNotification(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, 5, 30, 10, 2, 0, 0, time.UTC)
	event := newRestrictionOutboxEvent(t, model.UserRestrictionOutboxEventLifted, now)
	repo := &restrictionOutboxRepoFake{events: []model.UserRestrictionOutboxEvent{event}}
	notifier := &restrictionNotificationGatewayFake{}
	worker := NewRestrictionOutboxWorker(
		repo,
		&trustRestrictionClientFake{applied: true},
		notifier,
		RestrictionOutboxWorkerConfig{},
	)

	if err := worker.ProcessOnce(ctx, now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if len(notifier.sent) != 1 {
		t.Fatalf("expected one user notification, got %d", len(notifier.sent))
	}
	got := notifier.sent[0]
	if got.Priority != adminNotificationPriorityNormal || got.Data["adminEvent"] != "user_restriction_lifted" {
		t.Fatalf("unexpected lifted restriction notification: %#v", got)
	}
	if !strings.HasSuffix(got.IdempotencyKey, ":lifted") {
		t.Fatalf("unexpected lifted idempotency key: %q", got.IdempotencyKey)
	}
}

func TestRestrictionOutboxWorkerMarksFailureWithBackoff(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, 5, 30, 10, 5, 0, 0, time.UTC)
	event := newRestrictionOutboxEvent(t, model.UserRestrictionOutboxEventCreated, now)
	repo := &restrictionOutboxRepoFake{events: []model.UserRestrictionOutboxEvent{event}}
	client := &trustRestrictionClientFake{err: errors.New("trust unavailable")}
	notifier := &restrictionNotificationGatewayFake{}
	worker := NewRestrictionOutboxWorker(repo, client, notifier, RestrictionOutboxWorkerConfig{
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
	if repo.failedMaxAttempts != 3 {
		t.Fatalf("max attempts = %d, want 3", repo.failedMaxAttempts)
	}
	if len(notifier.sent) != 0 {
		t.Fatalf("notification must wait for trust delivery, got %d calls", len(notifier.sent))
	}
}

func TestRestrictionOutboxWorkerTreatsDuplicateApplyAsDelivered(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, 5, 30, 10, 10, 0, 0, time.UTC)
	event := newRestrictionOutboxEvent(t, model.UserRestrictionOutboxEventCreated, now)
	repo := &restrictionOutboxRepoFake{events: []model.UserRestrictionOutboxEvent{event}}
	client := &trustRestrictionClientFake{applied: false}
	notifier := &restrictionNotificationGatewayFake{}
	worker := NewRestrictionOutboxWorker(repo, client, notifier, RestrictionOutboxWorkerConfig{
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
	if len(notifier.sent) != 1 {
		t.Fatalf("expected notification after duplicate trust apply, got %d", len(notifier.sent))
	}
}

func TestRestrictionOutboxWorkerRetriesWhenNotificationFails(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, 5, 30, 10, 15, 0, 0, time.UTC)
	event := newRestrictionOutboxEvent(t, model.UserRestrictionOutboxEventCreated, now)
	repo := &restrictionOutboxRepoFake{events: []model.UserRestrictionOutboxEvent{event}}
	client := &trustRestrictionClientFake{applied: true}
	notifier := &restrictionNotificationGatewayFake{err: errors.New("notification unavailable")}
	worker := NewRestrictionOutboxWorker(repo, client, notifier, RestrictionOutboxWorkerConfig{
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(ctx, now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if len(client.delivered) != 1 || len(notifier.sent) != 1 {
		t.Fatalf("expected trust and notification attempts, got trust=%d notification=%d", len(client.delivered), len(notifier.sent))
	}
	if _, delivered := repo.delivered[event.ID]; delivered {
		t.Fatal("event must not be delivered before notification service accepts it")
	}
	failed := repo.failed[event.ID]
	if !strings.Contains(failed.reason, "notification unavailable") || !failed.nextAttemptAt.After(now) {
		t.Fatalf("unexpected retry state: %#v", failed)
	}
}

func newRestrictionOutboxEvent(
	t *testing.T,
	eventType string,
	now time.Time,
) model.UserRestrictionOutboxEvent {
	t.Helper()
	restrictionID := uuid.New()
	userID := uuid.New()
	payload, err := json.Marshal(userRestrictionNotificationPayload{
		RestrictionID:   restrictionID,
		UserID:          userID,
		RestrictionCode: model.UserRestrictionChat,
		ReasonCode:      "spam",
	})
	if err != nil {
		t.Fatalf("marshal restriction outbox payload: %v", err)
	}
	return model.UserRestrictionOutboxEvent{
		ID:          uuid.New(),
		EventType:   eventType,
		AggregateID: restrictionID,
		UserID:      userID,
		Payload:     payload,
		Status:      model.UserRestrictionOutboxPending,
		CreatedAt:   now.Add(-time.Minute),
	}
}

type restrictionOutboxRepoFake struct {
	events            []model.UserRestrictionOutboxEvent
	delivered         map[uuid.UUID]time.Time
	failedMaxAttempts int
	failed            map[uuid.UUID]struct {
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

func (r *restrictionOutboxRepoFake) MarkUserRestrictionEventFailed(
	_ context.Context,
	eventID uuid.UUID,
	reason string,
	nextAttemptAt time.Time,
	maxAttempts int,
) error {
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
	r.failedMaxAttempts = maxAttempts
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

type restrictionNotificationGatewayFake struct {
	err  error
	sent []port.UserNotificationInput
}

func (g *restrictionNotificationGatewayFake) SendUserNotification(
	_ context.Context,
	input port.UserNotificationInput,
) error {
	g.sent = append(g.sent, input)
	return g.err
}
