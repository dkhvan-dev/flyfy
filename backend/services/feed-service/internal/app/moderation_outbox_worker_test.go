package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestPostModerationOutboxWorkerDeliversPendingEvent(t *testing.T) {
	now := time.Date(2026, 6, 12, 10, 0, 0, 0, time.UTC)
	event := model.PostModerationOutboxEvent{
		ID:          uuid.New(),
		EventType:   model.PostModerationOutboxEventReportCreated,
		AggregateID: uuid.New(),
		Status:      model.PostModerationOutboxPending,
		CreatedAt:   now.Add(-time.Minute),
	}
	repo := &postModerationOutboxRepoFake{events: []model.PostModerationOutboxEvent{event}}
	publisher := &postModerationOutboxPublisherFake{}
	worker := NewPostModerationOutboxWorker(repo, publisher, PostModerationOutboxWorkerConfig{
		BatchSize:   10,
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if len(publisher.published) != 1 || publisher.published[0].ID != event.ID {
		t.Fatalf("published events = %+v, want event %s", publisher.published, event.ID)
	}
	if len(repo.delivered) != 1 || repo.delivered[0] != event.ID {
		t.Fatalf("delivered events = %+v, want %s", repo.delivered, event.ID)
	}
}

func TestPostModerationOutboxWorkerMarksFailureWithBackoff(t *testing.T) {
	now := time.Date(2026, 6, 12, 10, 0, 0, 0, time.UTC)
	event := model.PostModerationOutboxEvent{
		ID:           uuid.New(),
		EventType:    model.PostModerationOutboxEventReportResolved,
		AggregateID:  uuid.New(),
		Status:       model.PostModerationOutboxPending,
		AttemptCount: 1,
		CreatedAt:    now.Add(-time.Minute),
	}
	repo := &postModerationOutboxRepoFake{events: []model.PostModerationOutboxEvent{event}}
	publisher := &postModerationOutboxPublisherFake{err: errors.New("broker unavailable")}
	worker := NewPostModerationOutboxWorker(repo, publisher, PostModerationOutboxWorkerConfig{
		BatchSize:   10,
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if len(repo.failed) != 1 || repo.failed[0].id != event.ID {
		t.Fatalf("failed events = %+v, want %s", repo.failed, event.ID)
	}
	if got, want := repo.failed[0].nextAttemptAt, now.Add(2*time.Second); !got.Equal(want) {
		t.Fatalf("next attempt = %v, want %v", got, want)
	}
	if repo.failed[0].reason != "broker unavailable" {
		t.Fatalf("failure reason = %q, want broker unavailable", repo.failed[0].reason)
	}
}

func TestPostModerationOutboxWorkerTreatsNoopPublishAsDelivered(t *testing.T) {
	now := time.Date(2026, 6, 12, 10, 0, 0, 0, time.UTC)
	event := model.PostModerationOutboxEvent{
		ID:          uuid.New(),
		EventType:   model.PostModerationOutboxEventPostReviewed,
		AggregateID: uuid.New(),
		Status:      model.PostModerationOutboxPending,
		CreatedAt:   now.Add(-time.Minute),
	}
	repo := &postModerationOutboxRepoFake{events: []model.PostModerationOutboxEvent{event}}
	publisher := &postModerationOutboxPublisherFake{applied: false, appliedSet: true}
	worker := NewPostModerationOutboxWorker(repo, publisher, PostModerationOutboxWorkerConfig{
		BatchSize:   10,
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if len(repo.delivered) != 1 || repo.delivered[0] != event.ID {
		t.Fatalf("delivered events = %+v, want %s", repo.delivered, event.ID)
	}
}

type postModerationOutboxRepoFake struct {
	events    []model.PostModerationOutboxEvent
	delivered []uuid.UUID
	failed    []postModerationOutboxFailure
}

type postModerationOutboxFailure struct {
	id            uuid.UUID
	reason        string
	nextAttemptAt time.Time
}

func (r *postModerationOutboxRepoFake) ListDuePostModerationOutboxEvents(_ context.Context, limit int, _ time.Time) ([]model.PostModerationOutboxEvent, error) {
	if limit <= 0 || limit > len(r.events) {
		limit = len(r.events)
	}
	items := make([]model.PostModerationOutboxEvent, limit)
	copy(items, r.events[:limit])
	return items, nil
}

func (r *postModerationOutboxRepoFake) MarkPostModerationOutboxDelivered(_ context.Context, eventID uuid.UUID, _ time.Time) error {
	r.delivered = append(r.delivered, eventID)
	return nil
}

func (r *postModerationOutboxRepoFake) MarkPostModerationOutboxFailed(_ context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error {
	r.failed = append(r.failed, postModerationOutboxFailure{id: eventID, reason: reason, nextAttemptAt: nextAttemptAt})
	return nil
}

type postModerationOutboxPublisherFake struct {
	applied    bool
	appliedSet bool
	err        error
	published  []model.PostModerationOutboxEvent
}

func (p *postModerationOutboxPublisherFake) PublishPostModerationOutboxEvent(_ context.Context, event model.PostModerationOutboxEvent) (bool, error) {
	p.published = append(p.published, event)
	if p.err != nil {
		return false, p.err
	}
	if p.appliedSet {
		return p.applied, nil
	}
	return true, nil
}
