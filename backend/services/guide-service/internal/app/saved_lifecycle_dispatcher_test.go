package app

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

func TestSavedLifecycleDispatcherRetriesThenMarksDead(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	config := DefaultSavedLifecycleDispatcherConfig()
	config.BatchSize = 1
	config.Concurrency = 1
	repo := &savedLifecycleOutboxRepoStub{}
	publisher := &savedLifecyclePublisherStub{err: errors.New("nats unavailable")}
	dispatcher, err := NewSavedLifecycleDispatcher(repo, publisher, config)
	if err != nil {
		t.Fatalf("NewSavedLifecycleDispatcher() error = %v", err)
	}
	dispatcher.now = func() time.Time { return now }

	retryMessage := newClaimedLifecycleMessage(1, 3, now)
	repo.claimed = []*model.SavedLifecycleOutboxMessage{retryMessage}
	if _, err = dispatcher.DispatchBatch(context.Background()); err != nil {
		t.Fatalf("DispatchBatch() error = %v", err)
	}
	wantRetryAt := now.Add(savedLifecycleRetryDelay(1, retryMessage.EventID))
	if len(repo.failed) != 1 || repo.failed[0].dead || repo.failed[0].nextAttemptAt != wantRetryAt {
		t.Fatalf("retry = %+v", repo.failed)
	}

	repo.claimed = []*model.SavedLifecycleOutboxMessage{newClaimedLifecycleMessage(3, 3, now)}
	if _, err = dispatcher.DispatchBatch(context.Background()); err != nil {
		t.Fatalf("dead DispatchBatch() error = %v", err)
	}
	if len(repo.failed) != 2 || !repo.failed[1].dead || repo.failed[1].retention != config.DeadRetention {
		t.Fatalf("dead transition = %+v", repo.failed)
	}
}

func TestSavedLifecycleDispatcherMarksDeliveredAfterPublishAck(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	config := DefaultSavedLifecycleDispatcherConfig()
	config.BatchSize = 2
	config.Concurrency = 2
	repo := &savedLifecycleOutboxRepoStub{claimed: []*model.SavedLifecycleOutboxMessage{
		newClaimedLifecycleMessage(1, 3, now),
		newClaimedLifecycleMessage(1, 3, now),
	}}
	publisher := &savedLifecyclePublisherStub{}
	dispatcher, err := NewSavedLifecycleDispatcher(repo, publisher, config)
	if err != nil {
		t.Fatalf("NewSavedLifecycleDispatcher() error = %v", err)
	}
	dispatcher.now = func() time.Time { return now }

	processed, err := dispatcher.DispatchBatch(context.Background())
	if err != nil {
		t.Fatalf("DispatchBatch() error = %v", err)
	}
	if processed != 2 || publisher.count() != 2 || repo.deliveredCount() != 2 {
		t.Fatalf("processed/published/delivered = %d/%d/%d", processed, publisher.count(), repo.deliveredCount())
	}
}

func newClaimedLifecycleMessage(attempt, maxAttempts int, now time.Time) *model.SavedLifecycleOutboxMessage {
	return &model.SavedLifecycleOutboxMessage{
		EventID: uuid.New(), TargetUserID: uuid.New(),
		Kind:           model.SavedLifecycleEventUpdated,
		SourceRevision: 3, ProjectionRevision: 2, VisibilityRevision: 1,
		OccurredAt: now.Add(-time.Second), Visibility: model.SavedLifecycleVisibilityPublic,
		AttemptCount: attempt, MaxAttempts: maxAttempts, LeaseToken: uuid.New(),
	}
}

type savedLifecycleFailure struct {
	dead          bool
	nextAttemptAt time.Time
	retention     time.Duration
}

type savedLifecycleOutboxRepoStub struct {
	mu        sync.Mutex
	claimed   []*model.SavedLifecycleOutboxMessage
	delivered int
	failed    []savedLifecycleFailure
}

func (r *savedLifecycleOutboxRepoStub) ClaimSavedLifecycleOutbox(
	context.Context, time.Time, int, time.Duration,
) ([]*model.SavedLifecycleOutboxMessage, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	items := r.claimed
	r.claimed = nil
	return items, nil
}

func (r *savedLifecycleOutboxRepoStub) MarkSavedLifecycleDelivered(
	context.Context, uuid.UUID, uuid.UUID, time.Time, time.Duration,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.delivered++
	return nil
}

func (r *savedLifecycleOutboxRepoStub) MarkSavedLifecycleFailed(
	_ context.Context,
	_ uuid.UUID,
	_ uuid.UUID,
	_ time.Time,
	nextAttemptAt time.Time,
	_ string,
	dead bool,
	retention time.Duration,
) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.failed = append(r.failed, savedLifecycleFailure{dead: dead, nextAttemptAt: nextAttemptAt, retention: retention})
	return nil
}

func (r *savedLifecycleOutboxRepoStub) DeleteSavedLifecycleTerminal(context.Context, time.Time, int) (int64, error) {
	return 0, nil
}

func (r *savedLifecycleOutboxRepoStub) deliveredCount() int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.delivered
}

type savedLifecyclePublisherStub struct {
	mu        sync.Mutex
	published int
	err       error
}

func (p *savedLifecyclePublisherStub) PublishSavedLifecycle(
	context.Context,
	*model.SavedLifecycleOutboxMessage,
) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.published++
	return p.err
}

func (p *savedLifecyclePublisherStub) count() int {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.published
}
