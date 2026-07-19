package app

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestSavedLifecycleDispatcherDeliversClaimedEventsConcurrently(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 11, 0, 0, 0, time.UTC)
	events := make([]model.ClaimedSavedLifecycleEvent, 8)
	for index := range events {
		events[index] = dispatcherTestClaim(now, 0)
	}
	outbox := &savedLifecycleOutboxStub{claimBatches: [][]model.ClaimedSavedLifecycleEvent{events}}
	var active atomic.Int32
	var maximum atomic.Int32
	publisher := &savedLifecyclePublisherStub{
		publish: func(context.Context, model.SavedLifecycleEvent) error {
			current := active.Add(1)
			defer active.Add(-1)
			for {
				previous := maximum.Load()
				if current <= previous || maximum.CompareAndSwap(previous, current) {
					break
				}
			}
			time.Sleep(10 * time.Millisecond)
			return nil
		},
	}
	dispatcher := newSavedLifecycleTestDispatcher(t, outbox, publisher, now, func(config *SavedLifecycleDispatcherConfig) {
		config.Concurrency = 4
		config.BatchSize = 8
	})

	processed, err := dispatcher.RunOnce(context.Background())
	if err != nil {
		t.Fatalf("RunOnce() error = %v", err)
	}
	if processed != len(events) || outbox.deliveredCount() != len(events) {
		t.Fatalf("processed/delivered = %d/%d, want %d", processed, outbox.deliveredCount(), len(events))
	}
	if maximum.Load() < 2 || maximum.Load() > 4 {
		t.Fatalf("maximum publish concurrency = %d, want in [2,4]", maximum.Load())
	}
}

func TestSavedLifecycleDispatcherRetriesThenRetainsPoisonAsDead(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 11, 30, 0, 0, time.UTC)
	first := dispatcherTestClaim(now, 0)
	second := first
	second.AttemptCount = 1
	second.LeaseID = uuid.New()
	outbox := &savedLifecycleOutboxStub{
		claimBatches:  [][]model.ClaimedSavedLifecycleEvent{{first}, {second}},
		failureStates: []model.SavedLifecycleDeliveryState{model.SavedLifecycleDeliveryPending, model.SavedLifecycleDeliveryDead},
	}
	publisher := &savedLifecyclePublisherStub{
		publish: func(context.Context, model.SavedLifecycleEvent) error {
			return errors.New("broker unavailable")
		},
	}
	dispatcher := newSavedLifecycleTestDispatcher(t, outbox, publisher, now, func(config *SavedLifecycleDispatcherConfig) {
		config.MaxAttempts = 2
	})

	if processed, err := dispatcher.RunOnce(context.Background()); err != nil || processed != 1 {
		t.Fatalf("first RunOnce() = %d, %v", processed, err)
	}
	if outbox.failureCount() != 1 || outbox.deadCount() != 0 {
		t.Fatalf("first failure/dead transitions = %d/%d, want 1/0", outbox.failureCount(), outbox.deadCount())
	}
	if processed, err := dispatcher.RunOnce(context.Background()); err != nil || processed != 1 {
		t.Fatalf("second RunOnce() = %d, %v", processed, err)
	}
	if outbox.failureCount() != 2 || outbox.deadCount() != 1 || publisher.publishCount() != 2 {
		t.Fatalf(
			"failures/dead/source publishes = %d/%d/%d, want 2/1/2",
			outbox.failureCount(),
			outbox.deadCount(),
			publisher.publishCount(),
		)
	}
}

func TestSavedLifecycleDispatcherRunStopsGracefully(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 30, 0, 0, time.UTC)
	dispatcher := newSavedLifecycleTestDispatcher(
		t,
		&savedLifecycleOutboxStub{},
		&savedLifecyclePublisherStub{},
		now,
		func(config *SavedLifecycleDispatcherConfig) {
			config.PollInterval = time.Minute
		},
	)
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan error, 1)
	go func() { done <- dispatcher.Run(ctx) }()
	cancel()
	select {
	case err := <-done:
		if err != nil {
			t.Fatalf("Run() error = %v", err)
		}
	case <-time.After(time.Second):
		t.Fatal("Run() did not stop after context cancellation")
	}
}

func TestSavedLifecycleBackoffIsExponentialAndBounded(t *testing.T) {
	t.Parallel()

	base := time.Second
	maximum := 10 * time.Second
	want := []time.Duration{time.Second, 2 * time.Second, 4 * time.Second, 8 * time.Second, 10 * time.Second, 10 * time.Second}
	for index, expected := range want {
		if got := savedLifecycleBackoff(index+1, base, maximum); got != expected {
			t.Fatalf("backoff attempt %d = %s, want %s", index+1, got, expected)
		}
	}
}

func newSavedLifecycleTestDispatcher(
	t *testing.T,
	outbox SavedLifecycleOutbox,
	publisher SavedLifecyclePublisher,
	now time.Time,
	mutateConfig func(*SavedLifecycleDispatcherConfig),
) *SavedLifecycleDispatcher {
	t.Helper()
	config := SavedLifecycleDispatcherConfig{
		BatchSize:       10,
		Concurrency:     2,
		PollInterval:    5 * time.Millisecond,
		LeaseDuration:   10 * time.Second,
		PublishTimeout:  time.Second,
		MaxAttempts:     3,
		RetryBase:       time.Second,
		RetryMax:        time.Minute,
		CleanupInterval: time.Hour,
		CleanupBatch:    100,
	}
	if mutateConfig != nil {
		mutateConfig(&config)
	}
	dispatcher, err := NewSavedLifecycleDispatcher(
		outbox,
		publisher,
		config,
		WithSavedLifecycleDispatcherClock(func() time.Time { return now }),
	)
	if err != nil {
		t.Fatalf("NewSavedLifecycleDispatcher() error = %v", err)
	}
	return dispatcher
}

func dispatcherTestClaim(
	now time.Time,
	attempts int,
) model.ClaimedSavedLifecycleEvent {
	return model.ClaimedSavedLifecycleEvent{
		Event: model.SavedLifecycleEvent{
			EventID:            uuid.New(),
			SchemaVersion:      1,
			EventType:          model.SavedLifecycleUpdated,
			EntityID:           uuid.New(),
			SourceRevision:     1,
			ProjectionRevision: 2,
			VisibilityRevision: 3,
			Visibility:         model.SavedLifecycleVisibilityPublic,
			OccurredAt:         now,
		},
		DeliveryState: model.SavedLifecycleDeliveryPending,
		AttemptCount:  attempts,
		LeaseID:       uuid.New(),
	}
}

type savedLifecycleOutboxStub struct {
	mu            sync.Mutex
	claimBatches  [][]model.ClaimedSavedLifecycleEvent
	delivered     []uuid.UUID
	failures      []uuid.UUID
	dead          []uuid.UUID
	failureStates []model.SavedLifecycleDeliveryState
}

func (stub *savedLifecycleOutboxStub) ClaimDueSavedLifecycleEvents(
	context.Context,
	time.Time,
	time.Time,
	int,
) ([]model.ClaimedSavedLifecycleEvent, error) {
	stub.mu.Lock()
	defer stub.mu.Unlock()
	if len(stub.claimBatches) == 0 {
		return nil, nil
	}
	batch := stub.claimBatches[0]
	stub.claimBatches = stub.claimBatches[1:]
	return append([]model.ClaimedSavedLifecycleEvent(nil), batch...), nil
}

func (stub *savedLifecycleOutboxStub) MarkSavedLifecycleDelivered(
	_ context.Context,
	eventID uuid.UUID,
	_ uuid.UUID,
	_ time.Time,
) error {
	stub.mu.Lock()
	defer stub.mu.Unlock()
	stub.delivered = append(stub.delivered, eventID)
	return nil
}

func (stub *savedLifecycleOutboxStub) MarkSavedLifecycleFailure(
	_ context.Context,
	eventID uuid.UUID,
	_ uuid.UUID,
	_ time.Time,
	_ time.Time,
	_ int,
	_ string,
) (model.SavedLifecycleDeliveryState, error) {
	stub.mu.Lock()
	defer stub.mu.Unlock()
	stub.failures = append(stub.failures, eventID)
	if len(stub.failureStates) == 0 {
		return model.SavedLifecycleDeliveryPending, nil
	}
	state := stub.failureStates[0]
	stub.failureStates = stub.failureStates[1:]
	if state == model.SavedLifecycleDeliveryDead {
		stub.dead = append(stub.dead, eventID)
	}
	return state, nil
}

func (*savedLifecycleOutboxStub) DeleteExpiredSavedLifecycleEvents(
	context.Context,
	time.Time,
	int,
) (int64, error) {
	return 0, nil
}

func (stub *savedLifecycleOutboxStub) deliveredCount() int {
	stub.mu.Lock()
	defer stub.mu.Unlock()
	return len(stub.delivered)
}

func (stub *savedLifecycleOutboxStub) failureCount() int {
	stub.mu.Lock()
	defer stub.mu.Unlock()
	return len(stub.failures)
}

func (stub *savedLifecycleOutboxStub) deadCount() int {
	stub.mu.Lock()
	defer stub.mu.Unlock()
	return len(stub.dead)
}

type savedLifecyclePublisherStub struct {
	mu           sync.Mutex
	publish      func(context.Context, model.SavedLifecycleEvent) error
	publishCalls int
}

func (stub *savedLifecyclePublisherStub) PublishSavedLifecycle(
	ctx context.Context,
	event model.SavedLifecycleEvent,
) error {
	stub.mu.Lock()
	stub.publishCalls++
	stub.mu.Unlock()
	if stub.publish == nil {
		return nil
	}
	return stub.publish(ctx, event)
}

func (stub *savedLifecyclePublisherStub) publishCount() int {
	stub.mu.Lock()
	defer stub.mu.Unlock()
	return stub.publishCalls
}
