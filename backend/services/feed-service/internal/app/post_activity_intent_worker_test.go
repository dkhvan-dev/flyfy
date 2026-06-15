package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestPostActivityIntentWorkerMarksDeliveredActivity(t *testing.T) {
	event := model.PostActivityIntentEvent{
		ID:           uuid.New(),
		PostID:       uuid.New(),
		AuthorUserID: uuid.New(),
	}
	activityID := uuid.New()
	repo := &postActivityIntentRepoFake{events: []model.PostActivityIntentEvent{event}}
	publisher := &postActivityIntentPublisherFake{activityID: activityID}
	now := time.Date(2026, 6, 13, 12, 0, 0, 0, time.UTC)
	worker := NewPostActivityIntentWorker(repo, publisher, PostActivityIntentWorkerConfig{
		BatchSize:    10,
		MaxAttempts:  3,
		BaseBackoff:  time.Second,
		PollInterval: time.Second,
	})

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce() error = %v", err)
	}

	if repo.deliveredEventID != event.ID {
		t.Fatalf("delivered event id = %s, want %s", repo.deliveredEventID, event.ID)
	}
	if repo.deliveredPostID != event.PostID {
		t.Fatalf("delivered post id = %s, want %s", repo.deliveredPostID, event.PostID)
	}
	if repo.deliveredActivityID != activityID {
		t.Fatalf("delivered activity id = %s, want %s", repo.deliveredActivityID, activityID)
	}
	if publisher.publishedEvent.ID != event.ID {
		t.Fatalf("published event id = %s, want %s", publisher.publishedEvent.ID, event.ID)
	}
}

func TestPostActivityIntentWorkerMarksTerminalFailure(t *testing.T) {
	event := model.PostActivityIntentEvent{
		ID:           uuid.New(),
		PostID:       uuid.New(),
		AuthorUserID: uuid.New(),
		AttemptCount: 1,
	}
	repo := &postActivityIntentRepoFake{events: []model.PostActivityIntentEvent{event}}
	publisher := &postActivityIntentPublisherFake{err: errors.New("activity-service unavailable")}
	now := time.Date(2026, 6, 13, 12, 0, 0, 0, time.UTC)
	worker := NewPostActivityIntentWorker(repo, publisher, PostActivityIntentWorkerConfig{
		BatchSize:    10,
		MaxAttempts:  2,
		BaseBackoff:  time.Second,
		PollInterval: time.Second,
	})

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce() error = %v", err)
	}

	if repo.failedEventID != event.ID {
		t.Fatalf("failed event id = %s, want %s", repo.failedEventID, event.ID)
	}
	if !repo.failedTerminal {
		t.Fatal("failure should be terminal at max attempts")
	}
	if repo.failedNextAttemptAt != now.Add(2*time.Second) {
		t.Fatalf("next attempt = %s, want %s", repo.failedNextAttemptAt, now.Add(2*time.Second))
	}
}

type postActivityIntentRepoFake struct {
	events []model.PostActivityIntentEvent

	deliveredEventID    uuid.UUID
	deliveredPostID     uuid.UUID
	deliveredActivityID uuid.UUID

	failedEventID       uuid.UUID
	failedPostID        uuid.UUID
	failedReason        string
	failedNextAttemptAt time.Time
	failedTerminal      bool
}

func (r *postActivityIntentRepoFake) ListDuePostActivityIntentEvents(_ context.Context, _ int, _ time.Time) ([]model.PostActivityIntentEvent, error) {
	return r.events, nil
}

func (r *postActivityIntentRepoFake) MarkPostActivityIntentDelivered(_ context.Context, eventID uuid.UUID, postID uuid.UUID, sourceActivityID uuid.UUID, _ time.Time) error {
	r.deliveredEventID = eventID
	r.deliveredPostID = postID
	r.deliveredActivityID = sourceActivityID
	return nil
}

func (r *postActivityIntentRepoFake) MarkPostActivityIntentFailed(_ context.Context, eventID uuid.UUID, postID uuid.UUID, reason string, nextAttemptAt time.Time, terminal bool) error {
	r.failedEventID = eventID
	r.failedPostID = postID
	r.failedReason = reason
	r.failedNextAttemptAt = nextAttemptAt
	r.failedTerminal = terminal
	return nil
}

type postActivityIntentPublisherFake struct {
	activityID     uuid.UUID
	err            error
	publishedEvent model.PostActivityIntentEvent
}

func (p *postActivityIntentPublisherFake) PublishPostActivityIntent(_ context.Context, event model.PostActivityIntentEvent) (uuid.UUID, error) {
	p.publishedEvent = event
	if p.err != nil {
		return uuid.Nil, p.err
	}
	return p.activityID, nil
}
