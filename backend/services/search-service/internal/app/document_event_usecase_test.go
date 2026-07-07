package app

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

func TestDocumentEventUseCaseEnqueuesValidatedEvent(t *testing.T) {
	repo := &fakeDocumentEventRepository{}
	uc := NewDocumentEventUseCase(repo, NewIndexingUseCase(&fakeIndexRepository{}))

	payload := json.RawMessage(`{"domain":"place","entityId":"place-1","title":{"en":"Almaty"},"deepLink":"/places/place-1"}`)
	err := uc.EnqueueDocumentEvent(context.Background(), EnqueueDocumentEventInput{
		SourceService: "place-service",
		SourceEventID: "event-1",
		AggregateType: "place",
		AggregateID:   "place-1",
		EventType:     DocumentEventTypeUpsert,
		Payload:       payload,
	})

	if err != nil {
		t.Fatalf("EnqueueDocumentEvent returned error: %v", err)
	}
	if repo.enqueueCalls != 1 {
		t.Fatalf("enqueue calls = %d, want 1", repo.enqueueCalls)
	}
	event := repo.enqueuedEvent
	if event.SourceService != "place-service" ||
		event.SourceEventID != "event-1" ||
		event.AggregateType != "place" ||
		event.AggregateID != "place-1" ||
		event.EventType != DocumentEventTypeUpsert ||
		string(event.Payload) != string(payload) {
		t.Fatalf("event = %+v", event)
	}
}

func TestDocumentEventUseCaseProcessesDueUpsertAndDeleteEvents(t *testing.T) {
	now := time.Date(2026, 7, 5, 12, 0, 0, 0, time.UTC)
	indexRepo := &fakeIndexRepository{}
	eventRepo := &fakeDocumentEventRepository{
		dueEvents: []model.SearchDocumentEvent{
			{
				ID:            "event-upsert",
				EventType:     DocumentEventTypeUpsert,
				Payload:       json.RawMessage(`{"domain":"place","entityId":"place-1","title":{"en":"Almaty"},"deepLink":"/places/place-1"}`),
				AttemptCount:  0,
				NextAttemptAt: now,
				CreatedAt:     now.Add(-10 * time.Second),
			},
			{
				ID:            "event-delete",
				EventType:     DocumentEventTypeDelete,
				Payload:       json.RawMessage(`{"domain":"guide","entityId":"guide-1","locale":"kk"}`),
				AttemptCount:  0,
				NextAttemptAt: now,
				CreatedAt:     now.Add(-3 * time.Second),
			},
		},
	}
	uc := NewDocumentEventUseCase(eventRepo, NewIndexingUseCase(indexRepo))

	stats, err := uc.ProcessDueDocumentEvents(context.Background(), ProcessDocumentEventOptions{
		BatchSize:   10,
		MaxAttempts: 3,
		BaseBackoff: time.Second,
		Now:         now,
	})

	if err != nil {
		t.Fatalf("ProcessDueDocumentEvents returned error: %v", err)
	}
	if stats.Scanned != 2 || stats.Delivered != 2 || stats.RetryScheduled != 0 || stats.Dead != 0 {
		t.Fatalf("stats = %+v, want scanned 2 delivered 2", stats)
	}
	if stats.MaxIndexLagSeconds != 10 {
		t.Fatalf("max index lag = %.0f, want 10", stats.MaxIndexLagSeconds)
	}
	if indexRepo.upsertCalls != 1 || indexRepo.lastDocument.EntityID != "place-1" {
		t.Fatalf("upsert calls = %d document = %+v", indexRepo.upsertCalls, indexRepo.lastDocument)
	}
	if indexRepo.deleteCalls != 1 || indexRepo.lastDeleteEntityID != "guide-1" || indexRepo.lastDeleteLocale != "kk" {
		t.Fatalf("delete calls = %d identity = %s/%s", indexRepo.deleteCalls, indexRepo.lastDeleteEntityID, indexRepo.lastDeleteLocale)
	}
	if len(eventRepo.deliveredIDs) != 2 {
		t.Fatalf("delivered ids = %+v, want both events", eventRepo.deliveredIDs)
	}
}

func TestDocumentEventUseCaseRetriesThenMarksDead(t *testing.T) {
	now := time.Date(2026, 7, 5, 12, 0, 0, 0, time.UTC)
	indexRepo := &fakeIndexRepository{upsertErr: errors.New("database unavailable")}
	eventRepo := &fakeDocumentEventRepository{
		dueEvents: []model.SearchDocumentEvent{
			{
				ID:            "event-retry",
				EventType:     DocumentEventTypeUpsert,
				Payload:       json.RawMessage(`{"domain":"place","entityId":"place-1","title":{"en":"Almaty"},"deepLink":"/places/place-1"}`),
				AttemptCount:  1,
				NextAttemptAt: now,
			},
			{
				ID:            "event-dead",
				EventType:     DocumentEventTypeUpsert,
				Payload:       json.RawMessage(`{"domain":"place","entityId":"place-2","title":{"en":"Astana"},"deepLink":"/places/place-2"}`),
				AttemptCount:  2,
				NextAttemptAt: now,
			},
		},
	}
	uc := NewDocumentEventUseCase(eventRepo, NewIndexingUseCase(indexRepo))

	stats, err := uc.ProcessDueDocumentEvents(context.Background(), ProcessDocumentEventOptions{
		BatchSize:   10,
		MaxAttempts: 3,
		BaseBackoff: time.Minute,
		Now:         now,
	})

	if err != nil {
		t.Fatalf("ProcessDueDocumentEvents returned error: %v", err)
	}
	if stats.Scanned != 2 || stats.Delivered != 0 || stats.RetryScheduled != 1 || stats.Dead != 1 {
		t.Fatalf("stats = %+v, want one retry and one dead", stats)
	}
	if stats.FailedEventsTotal != 1 {
		t.Fatalf("failed events total = %d, want 1", stats.FailedEventsTotal)
	}
	if len(eventRepo.retryEvents) != 1 || eventRepo.retryEvents[0].eventID != "event-retry" {
		t.Fatalf("retry events = %+v", eventRepo.retryEvents)
	}
	if !eventRepo.retryEvents[0].nextAttemptAt.After(now) {
		t.Fatalf("retry next attempt = %s, want after %s", eventRepo.retryEvents[0].nextAttemptAt, now)
	}
	if len(eventRepo.deadEvents) != 1 || eventRepo.deadEvents[0].eventID != "event-dead" {
		t.Fatalf("dead events = %+v", eventRepo.deadEvents)
	}
}

type fakeDocumentEventRepository struct {
	enqueueCalls  int
	enqueuedEvent model.SearchDocumentEvent
	dueEvents     []model.SearchDocumentEvent
	deliveredIDs  []string
	retryEvents   []fakeDocumentEventRetry
	deadEvents    []fakeDocumentEventDead
}

type fakeDocumentEventRetry struct {
	eventID       string
	reason        string
	nextAttemptAt time.Time
}

type fakeDocumentEventDead struct {
	eventID string
	reason  string
}

func (r *fakeDocumentEventRepository) EnqueueDocumentEvent(_ context.Context, event model.SearchDocumentEvent) error {
	r.enqueueCalls++
	r.enqueuedEvent = event
	return nil
}

func (r *fakeDocumentEventRepository) ListDueDocumentEvents(_ context.Context, _ int, _ time.Time) ([]model.SearchDocumentEvent, error) {
	return r.dueEvents, nil
}

func (r *fakeDocumentEventRepository) MarkDocumentEventDelivered(_ context.Context, eventID string, _ time.Time) error {
	r.deliveredIDs = append(r.deliveredIDs, eventID)
	return nil
}

func (r *fakeDocumentEventRepository) MarkDocumentEventRetry(_ context.Context, eventID string, reason string, nextAttemptAt time.Time) error {
	r.retryEvents = append(r.retryEvents, fakeDocumentEventRetry{
		eventID:       eventID,
		reason:        reason,
		nextAttemptAt: nextAttemptAt,
	})
	return nil
}

func (r *fakeDocumentEventRepository) MarkDocumentEventDead(_ context.Context, eventID string, reason string, _ time.Time) error {
	r.deadEvents = append(r.deadEvents, fakeDocumentEventDead{eventID: eventID, reason: reason})
	return nil
}
