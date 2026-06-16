package app

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/model"
)

func TestUserSocialOutboxWorkerMarksDeliveredAfterPublish(t *testing.T) {
	event := model.UserSocialOutboxEvent{
		ID:              uuid.New(),
		EventType:       model.UserSocialEventFollowCreated,
		ViewerUserID:    uuid.New(),
		TargetUserID:    uuid.New(),
		EdgeType:        model.UserSocialEdgeFollowing,
		Active:          true,
		SourceUpdatedAt: time.Date(2026, 6, 15, 10, 0, 0, 0, time.UTC),
	}
	repo := &userSocialOutboxRepoFake{events: []model.UserSocialOutboxEvent{event}}
	publisher := &userSocialPublisherFake{}
	worker := NewUserSocialOutboxWorker(repo, publisher, UserSocialOutboxWorkerConfig{
		BatchSize: 10,
	})
	now := time.Date(2026, 6, 15, 10, 1, 0, 0, time.UTC)

	worker.processOnce(context.Background(), now)

	if len(publisher.published) != 1 || publisher.published[0].ID != event.ID {
		t.Fatalf("published events = %+v, want event %s", publisher.published, event.ID)
	}
	if len(repo.delivered) != 1 || repo.delivered[0] != event.ID {
		t.Fatalf("delivered events = %+v, want event %s", repo.delivered, event.ID)
	}
	if len(repo.failed) != 0 {
		t.Fatalf("failed events = %+v, want none", repo.failed)
	}
}

func TestUserSocialOutboxWorkerProcessOnceReportsBatchStats(t *testing.T) {
	valid := model.UserSocialOutboxEvent{
		ID:              uuid.New(),
		EventType:       model.UserSocialEventFollowCreated,
		ViewerUserID:    uuid.New(),
		TargetUserID:    uuid.New(),
		EdgeType:        model.UserSocialEdgeFollowing,
		Active:          true,
		SourceUpdatedAt: time.Date(2026, 6, 15, 10, 0, 0, 0, time.UTC),
	}
	invalid := model.UserSocialOutboxEvent{
		ID:              uuid.New(),
		EventType:       model.UserSocialEventFollowDeleted,
		ViewerUserID:    uuid.New(),
		TargetUserID:    uuid.New(),
		EdgeType:        model.UserSocialEdgeFollowing,
		Active:          true,
		SourceUpdatedAt: time.Date(2026, 6, 15, 10, 0, 0, 0, time.UTC),
	}
	repo := &userSocialOutboxRepoFake{events: []model.UserSocialOutboxEvent{valid, invalid}}
	publisher := &userSocialPublisherFake{}
	worker := NewUserSocialOutboxWorker(repo, publisher, UserSocialOutboxWorkerConfig{
		BatchSize:   10,
		BaseBackoff: time.Second,
	})
	now := time.Date(2026, 6, 15, 10, 1, 0, 0, time.UTC)

	stats, err := worker.ProcessOnce(context.Background(), now)
	if err != nil {
		t.Fatalf("ProcessOnce returned error: %v", err)
	}

	if stats.Fetched != 2 ||
		stats.Published != 1 ||
		stats.Delivered != 1 ||
		stats.Failed != 1 ||
		stats.Invalid != 1 {
		t.Fatalf("stats = %+v, want fetched=2 published=1 delivered=1 failed=1 invalid=1", stats)
	}
}

func TestUserSocialOutboxWorkerSchedulesRetryAfterPublishFailure(t *testing.T) {
	event := model.UserSocialOutboxEvent{
		ID:              uuid.New(),
		EventType:       model.UserSocialEventFriendshipCreated,
		ViewerUserID:    uuid.New(),
		TargetUserID:    uuid.New(),
		EdgeType:        model.UserSocialEdgeFriend,
		Active:          true,
		SourceUpdatedAt: time.Date(2026, 6, 15, 10, 0, 0, 0, time.UTC),
	}
	repo := &userSocialOutboxRepoFake{events: []model.UserSocialOutboxEvent{event}}
	publisher := &userSocialPublisherFake{err: errors.New("feed unavailable")}
	worker := NewUserSocialOutboxWorker(repo, publisher, UserSocialOutboxWorkerConfig{
		BaseBackoff: time.Second,
	})
	now := time.Date(2026, 6, 15, 10, 1, 0, 0, time.UTC)

	worker.processOnce(context.Background(), now)

	if len(repo.delivered) != 0 {
		t.Fatalf("delivered events = %+v, want none", repo.delivered)
	}
	if len(repo.failed) != 1 || repo.failed[0].eventID != event.ID {
		t.Fatalf("failed events = %+v, want event %s", repo.failed, event.ID)
	}
	if !repo.failed[0].nextAttemptAt.After(now) {
		t.Fatalf("next attempt = %s, want after %s", repo.failed[0].nextAttemptAt, now)
	}
}

func TestUserSocialOutboxWorkerRejectsInvalidEventsBeforePublishing(t *testing.T) {
	event := model.UserSocialOutboxEvent{
		ID:              uuid.New(),
		EventType:       model.UserSocialEventFollowCreated,
		ViewerUserID:    uuid.New(),
		TargetUserID:    uuid.Nil,
		EdgeType:        model.UserSocialEdgeFollowing,
		Active:          true,
		SourceUpdatedAt: time.Date(2026, 6, 15, 10, 0, 0, 0, time.UTC),
	}
	repo := &userSocialOutboxRepoFake{events: []model.UserSocialOutboxEvent{event}}
	publisher := &userSocialPublisherFake{}
	worker := NewUserSocialOutboxWorker(repo, publisher, UserSocialOutboxWorkerConfig{
		BaseBackoff: time.Second,
	})
	now := time.Date(2026, 6, 15, 10, 1, 0, 0, time.UTC)

	worker.processOnce(context.Background(), now)

	if len(publisher.published) != 0 {
		t.Fatalf("published events = %+v, want none for invalid event", publisher.published)
	}
	if len(repo.delivered) != 0 {
		t.Fatalf("delivered events = %+v, want none", repo.delivered)
	}
	if len(repo.failed) != 1 || repo.failed[0].eventID != event.ID {
		t.Fatalf("failed events = %+v, want invalid event %s", repo.failed, event.ID)
	}
	if !strings.Contains(repo.failed[0].reason, "invalid social outbox event ids") {
		t.Fatalf("failure reason = %q, want validation error", repo.failed[0].reason)
	}
}

func TestUserSocialOutboxWorkerRejectsInconsistentEventSemantics(t *testing.T) {
	event := model.UserSocialOutboxEvent{
		ID:              uuid.New(),
		EventType:       model.UserSocialEventFollowDeleted,
		ViewerUserID:    uuid.New(),
		TargetUserID:    uuid.New(),
		EdgeType:        model.UserSocialEdgeFollowing,
		Active:          true,
		SourceUpdatedAt: time.Date(2026, 6, 15, 10, 0, 0, 0, time.UTC),
	}
	repo := &userSocialOutboxRepoFake{events: []model.UserSocialOutboxEvent{event}}
	publisher := &userSocialPublisherFake{}
	worker := NewUserSocialOutboxWorker(repo, publisher, UserSocialOutboxWorkerConfig{
		BaseBackoff: time.Second,
	})
	now := time.Date(2026, 6, 15, 10, 1, 0, 0, time.UTC)

	worker.processOnce(context.Background(), now)

	if len(publisher.published) != 0 {
		t.Fatalf("published events = %+v, want none for inconsistent event", publisher.published)
	}
	if len(repo.failed) != 1 || repo.failed[0].eventID != event.ID {
		t.Fatalf("failed events = %+v, want inconsistent event %s", repo.failed, event.ID)
	}
	if !strings.Contains(repo.failed[0].reason, "invalid social outbox event semantics") {
		t.Fatalf("failure reason = %q, want semantic validation error", repo.failed[0].reason)
	}
}

func TestUserSocialOutboxReconcilerBackfillsAndDrainsOnStartup(t *testing.T) {
	event := model.UserSocialOutboxEvent{
		ID:              uuid.New(),
		EventType:       model.UserSocialEventFollowCreated,
		ViewerUserID:    uuid.New(),
		TargetUserID:    uuid.New(),
		EdgeType:        model.UserSocialEdgeFollowing,
		Active:          true,
		SourceUpdatedAt: time.Date(2026, 6, 15, 10, 0, 0, 0, time.UTC),
	}
	now := time.Date(2026, 6, 15, 10, 1, 0, 0, time.UTC)
	repo := &userSocialOutboxRepoFake{
		events:        []model.UserSocialOutboxEvent{event},
		backfillCount: 3,
	}
	publisher := &userSocialPublisherFake{}

	stats, err := ReconcileUserSocialOutbox(context.Background(), repo, publisher, UserSocialOutboxReconcilerConfig{
		BackfillEnabled: true,
		DrainEnabled:    true,
		MaxDrainBatches: 1,
		WorkerConfig: UserSocialOutboxWorkerConfig{
			BatchSize: 10,
		},
	}, now)
	if err != nil {
		t.Fatalf("ReconcileUserSocialOutbox returned error: %v", err)
	}

	if repo.backfillAt == nil || !repo.backfillAt.Equal(now) {
		t.Fatalf("backfill time = %v, want %s", repo.backfillAt, now)
	}
	if stats.Backfilled != 3 || stats.Drained != 1 || stats.DrainBatches != 1 {
		t.Fatalf("stats = %+v, want backfilled=3 drained=1 drainBatches=1", stats)
	}
	if len(publisher.published) != 1 || publisher.published[0].ID != event.ID {
		t.Fatalf("published events = %+v, want event %s", publisher.published, event.ID)
	}
}

func TestUserSocialOutboxReconcilerSkipsBackfillWhenDisabled(t *testing.T) {
	repo := &userSocialOutboxRepoFake{backfillCount: 3}

	stats, err := ReconcileUserSocialOutbox(context.Background(), repo, nil, UserSocialOutboxReconcilerConfig{}, time.Now().UTC())
	if err != nil {
		t.Fatalf("ReconcileUserSocialOutbox returned error: %v", err)
	}

	if repo.backfillAt != nil {
		t.Fatalf("backfill time = %v, want no backfill", repo.backfillAt)
	}
	if stats.Backfilled != 0 || stats.Drained != 0 || stats.DrainBatches != 0 {
		t.Fatalf("stats = %+v, want empty stats", stats)
	}
}

type userSocialOutboxRepoFake struct {
	events        []model.UserSocialOutboxEvent
	delivered     []uuid.UUID
	failed        []userSocialOutboxFailure
	backfillCount int64
	backfillAt    *time.Time
}

type userSocialOutboxFailure struct {
	eventID       uuid.UUID
	reason        string
	nextAttemptAt time.Time
}

func (r *userSocialOutboxRepoFake) ListDueUserSocialOutboxEvents(context.Context, int, time.Time) ([]model.UserSocialOutboxEvent, error) {
	return append([]model.UserSocialOutboxEvent(nil), r.events...), nil
}

func (r *userSocialOutboxRepoFake) MarkUserSocialOutboxDelivered(_ context.Context, eventID uuid.UUID, _ time.Time) error {
	r.delivered = append(r.delivered, eventID)
	return nil
}

func (r *userSocialOutboxRepoFake) MarkUserSocialOutboxFailed(_ context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error {
	r.failed = append(r.failed, userSocialOutboxFailure{
		eventID:       eventID,
		reason:        reason,
		nextAttemptAt: nextAttemptAt,
	})
	return nil
}

func (r *userSocialOutboxRepoFake) BackfillFeedSocialOutbox(_ context.Context, now time.Time) (int64, error) {
	r.backfillAt = &now
	return r.backfillCount, nil
}

type userSocialPublisherFake struct {
	published []model.UserSocialOutboxEvent
	err       error
}

func (p *userSocialPublisherFake) PublishUserSocialEvent(_ context.Context, event model.UserSocialOutboxEvent) error {
	if p.err != nil {
		return p.err
	}
	p.published = append(p.published, event)
	return nil
}
