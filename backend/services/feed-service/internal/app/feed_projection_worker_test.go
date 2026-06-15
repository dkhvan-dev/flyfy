package app

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestPostFeedProjectionWorkerProjectsPendingEvent(t *testing.T) {
	now := time.Date(2026, 6, 12, 11, 0, 0, 0, time.UTC)
	event := model.PostFeedProjectionOutboxEvent{
		ID:           uuid.New(),
		EventType:    model.PostFeedProjectionEventUpsert,
		PostID:       uuid.New(),
		PostRevision: 3,
		Status:       model.PostFeedProjectionOutboxPending,
		CreatedAt:    now.Add(-time.Minute),
	}
	repo := &postFeedProjectionRepoFake{events: []model.PostFeedProjectionOutboxEvent{event}}
	worker := NewPostFeedProjectionWorker(repo, PostFeedProjectionWorkerConfig{
		BatchSize:   10,
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if len(repo.projected) != 1 || repo.projected[0].ID != event.ID {
		t.Fatalf("projected events = %+v, want event %s", repo.projected, event.ID)
	}
	if len(repo.delivered) != 1 || repo.delivered[0] != event.ID {
		t.Fatalf("delivered events = %+v, want %s", repo.delivered, event.ID)
	}
}

func TestPostFeedProjectionWorkerMarksFailureWithBackoff(t *testing.T) {
	now := time.Date(2026, 6, 12, 11, 0, 0, 0, time.UTC)
	event := model.PostFeedProjectionOutboxEvent{
		ID:           uuid.New(),
		EventType:    model.PostFeedProjectionEventDelete,
		PostID:       uuid.New(),
		PostRevision: 4,
		Status:       model.PostFeedProjectionOutboxPending,
		AttemptCount: 2,
		CreatedAt:    now.Add(-time.Minute),
	}
	repo := &postFeedProjectionRepoFake{
		events: []model.PostFeedProjectionOutboxEvent{event},
		err:    errors.New("postgres timeout"),
	}
	worker := NewPostFeedProjectionWorker(repo, PostFeedProjectionWorkerConfig{
		BatchSize:   10,
		BaseBackoff: time.Second,
	})

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if len(repo.failed) != 1 || repo.failed[0].id != event.ID {
		t.Fatalf("failed events = %+v, want %s", repo.failed, event.ID)
	}
	if got, want := repo.failed[0].nextAttemptAt, now.Add(4*time.Second); !got.Equal(want) {
		t.Fatalf("next attempt = %v, want %v", got, want)
	}
	if repo.failed[0].reason != "postgres timeout" {
		t.Fatalf("failure reason = %q, want postgres timeout", repo.failed[0].reason)
	}
}

func TestPostFeedProjectionWorkerBumpsFeedCacheVersionAfterProjection(t *testing.T) {
	now := time.Date(2026, 6, 12, 11, 0, 0, 0, time.UTC)
	event := model.PostFeedProjectionOutboxEvent{
		ID:           uuid.New(),
		EventType:    model.PostFeedProjectionEventUpsert,
		PostID:       uuid.New(),
		PostRevision: 5,
		Status:       model.PostFeedProjectionOutboxPending,
		CreatedAt:    now.Add(-time.Minute),
	}
	repo := &postFeedProjectionRepoFake{events: []model.PostFeedProjectionOutboxEvent{event}}
	cache := &postFeedCacheFake{posts: make(map[string][]*model.Post)}
	worker := NewPostFeedProjectionWorker(repo, PostFeedProjectionWorkerConfig{
		BatchSize:   10,
		BaseBackoff: time.Second,
	}).WithPostFeedCache(cache)

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	if cache.bumps != 1 {
		t.Fatalf("cache bumps = %d, want 1", cache.bumps)
	}
}

func TestPostFeedProjectionWorkerBumpsAffectedFeedCacheScopes(t *testing.T) {
	now := time.Date(2026, 6, 12, 11, 0, 0, 0, time.UTC)
	postID := uuid.New()
	authorID := uuid.New()
	communityID := uuid.New()
	payload, err := json.Marshal(map[string]any{
		"postId":       postID.String(),
		"authorUserId": authorID.String(),
		"communityId":  communityID.String(),
		"category":     "GUIDE",
	})
	if err != nil {
		t.Fatalf("marshal payload: %v", err)
	}
	event := model.PostFeedProjectionOutboxEvent{
		ID:           uuid.New(),
		EventType:    model.PostFeedProjectionEventUpsert,
		PostID:       postID,
		PostRevision: 6,
		Payload:      payload,
		Status:       model.PostFeedProjectionOutboxPending,
		CreatedAt:    now.Add(-time.Minute),
	}
	repo := &postFeedProjectionRepoFake{events: []model.PostFeedProjectionOutboxEvent{event}}
	cache := &postFeedCacheFake{posts: make(map[string][]*model.Post)}
	worker := NewPostFeedProjectionWorker(repo, PostFeedProjectionWorkerConfig{
		BatchSize:   10,
		BaseBackoff: time.Second,
	}).WithPostFeedCache(cache)

	if err := worker.ProcessOnce(context.Background(), now); err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}
	for _, scope := range []string{
		postFeedCacheGlobalScope,
		postFeedCacheAuthorScope(authorID),
		postFeedCacheCommunityScope(communityID),
		postFeedCacheCategoryScope("guide"),
	} {
		if !containsString(cache.bumpedScopes, scope) {
			t.Fatalf("bumped scopes = %#v, want %q", cache.bumpedScopes, scope)
		}
	}
}

type postFeedProjectionRepoFake struct {
	events    []model.PostFeedProjectionOutboxEvent
	err       error
	projected []model.PostFeedProjectionOutboxEvent
	delivered []uuid.UUID
	failed    []postFeedProjectionFailure
}

type postFeedProjectionFailure struct {
	id            uuid.UUID
	reason        string
	nextAttemptAt time.Time
}

func (r *postFeedProjectionRepoFake) ListDuePostFeedProjectionEvents(_ context.Context, limit int, _ time.Time) ([]model.PostFeedProjectionOutboxEvent, error) {
	if limit <= 0 || limit > len(r.events) {
		limit = len(r.events)
	}
	items := make([]model.PostFeedProjectionOutboxEvent, limit)
	copy(items, r.events[:limit])
	return items, nil
}

func (r *postFeedProjectionRepoFake) ProjectPostFeedItem(_ context.Context, event model.PostFeedProjectionOutboxEvent) (bool, error) {
	r.projected = append(r.projected, event)
	if r.err != nil {
		return false, r.err
	}
	return true, nil
}

func (r *postFeedProjectionRepoFake) MarkPostFeedProjectionOutboxDelivered(_ context.Context, eventID uuid.UUID, _ time.Time) error {
	r.delivered = append(r.delivered, eventID)
	return nil
}

func (r *postFeedProjectionRepoFake) MarkPostFeedProjectionOutboxFailed(_ context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error {
	r.failed = append(r.failed, postFeedProjectionFailure{id: eventID, reason: reason, nextAttemptAt: nextAttemptAt})
	return nil
}
