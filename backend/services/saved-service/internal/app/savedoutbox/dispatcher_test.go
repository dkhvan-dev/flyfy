package savedoutbox

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestDispatcherHandlesDeliveryRetryPoisonAndDurableDead(t *testing.T) {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	success := savedOutboxClaim(now, 1)
	retry := savedOutboxClaim(now, 1)
	poison := savedOutboxClaim(now, 1)
	poison.SchemaVersion = 2
	exhausted := savedOutboxClaim(now, 3)

	repository := &savedOutboxRepositoryStub{
		recovery: RecoveryResult{Released: 1, Dead: 1},
		claimed:  []ClaimedRecord{success, retry, poison, exhausted},
	}
	publisher := &savedOutboxPublisherStub{failures: map[uuid.UUID]error{
		retry.Lease.EventID:     errors.New("broker unavailable"),
		exhausted.Lease.EventID: errors.New("broker unavailable"),
	}}
	dispatcher := newSavedOutboxTestDispatcher(t, repository, publisher, now)

	stats, err := dispatcher.DispatchBatch(context.Background())
	if err != nil {
		t.Fatalf("DispatchBatch() error = %v", err)
	}
	if stats.LeasesRecovered != 1 || stats.RecoveryDead != 1 || stats.Claimed != 4 ||
		stats.Delivered != 1 || stats.RetryScheduled != 1 || stats.Dead != 2 {
		t.Fatalf("DispatchBatch() stats = %+v", stats)
	}
	if !stats.LikelyMore {
		t.Fatal("LikelyMore = false after full recovery batch")
	}
	if got := publisher.publishedCount(); got != 3 {
		t.Fatalf("publisher calls = %d, want 3", got)
	}

	repository.mu.Lock()
	defer repository.mu.Unlock()
	if len(repository.deliveries) != 1 || repository.deliveries[0].Lease.EventID != success.Lease.EventID {
		t.Fatalf("deliveries = %+v", repository.deliveries)
	}
	if len(repository.failures) != 3 {
		t.Fatalf("failures = %+v", repository.failures)
	}
	byEvent := make(map[uuid.UUID]Failure, len(repository.failures))
	for _, failure := range repository.failures {
		byEvent[failure.Lease.EventID] = failure
	}
	if failure := byEvent[poison.Lease.EventID]; failure.Code != FailureInvalidEvent || !failure.Permanent {
		t.Fatalf("poison failure = %+v", failure)
	}
	if failure := byEvent[retry.Lease.EventID]; failure.Code != FailurePublishFailed ||
		failure.Permanent || !failure.NextAttemptAt.After(now) {
		t.Fatalf("retry failure = %+v", failure)
	}
	if failure := byEvent[exhausted.Lease.EventID]; failure.Code != FailurePublishFailed ||
		failure.Permanent || failure.NextAttemptAt != now || !failure.MustBecomeDead() {
		t.Fatalf("exhausted failure = %+v", failure)
	}
	if repository.recoveryRequest.LeaseExpiredBefore != now.Add(-repository.configLeaseDuration) {
		t.Fatalf("recovery cutoff = %s", repository.recoveryRequest.LeaseExpiredBefore)
	}
}

func TestDispatcherPersistsPublishTimeout(t *testing.T) {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	record := savedOutboxClaim(now, 1)
	repository := &savedOutboxRepositoryStub{claimed: []ClaimedRecord{record}}
	publisher := &savedOutboxPublisherStub{waitForContext: true}
	config := savedOutboxTestConfig()
	config.BatchSize = 1
	config.Concurrency = 1
	config.PublishTimeout = 5 * time.Millisecond
	config.LeaseDuration = 20 * time.Millisecond
	dispatcher, err := NewDispatcher(repository, publisher, config, ClockFunc(func() time.Time { return now }))
	if err != nil {
		t.Fatalf("NewDispatcher() error = %v", err)
	}

	stats, err := dispatcher.DispatchBatch(context.Background())
	if err != nil {
		t.Fatalf("DispatchBatch() error = %v", err)
	}
	if stats.RetryScheduled != 1 {
		t.Fatalf("stats = %+v", stats)
	}
	repository.mu.Lock()
	defer repository.mu.Unlock()
	if len(repository.failures) != 1 || repository.failures[0].Code != FailurePublishTimeout {
		t.Fatalf("failures = %+v", repository.failures)
	}
}

func TestDispatcherSurfacesLeaseLossWithoutClaimingDelivery(t *testing.T) {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	repository := &savedOutboxRepositoryStub{
		claimed:     []ClaimedRecord{savedOutboxClaim(now, 1)},
		deliveryErr: ErrLeaseLost,
	}
	dispatcher := newSavedOutboxTestDispatcher(t, repository, &savedOutboxPublisherStub{}, now)

	stats, err := dispatcher.DispatchBatch(context.Background())
	if !errors.Is(err, ErrLeaseLost) {
		t.Fatalf("DispatchBatch() error = %v", err)
	}
	if stats.Delivered != 0 {
		t.Fatalf("stats = %+v", stats)
	}
}

func TestDispatcherCleanupIsBounded(t *testing.T) {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	repository := &savedOutboxRepositoryStub{deleted: 2}
	dispatcher := newSavedOutboxTestDispatcher(t, repository, &savedOutboxPublisherStub{}, now)

	deleted, err := dispatcher.CleanupExpired(context.Background())
	if err != nil || deleted != 2 {
		t.Fatalf("CleanupExpired() = (%d, %v)", deleted, err)
	}
	repository.mu.Lock()
	defer repository.mu.Unlock()
	if repository.cleanupRequest.Now != now || repository.cleanupRequest.Limit != 4 {
		t.Fatalf("cleanup request = %+v", repository.cleanupRequest)
	}
}

func newSavedOutboxTestDispatcher(
	t testing.TB,
	repository *savedOutboxRepositoryStub,
	publisher *savedOutboxPublisherStub,
	now time.Time,
) *Dispatcher {
	t.Helper()
	config := savedOutboxTestConfig()
	repository.configLeaseDuration = config.LeaseDuration
	dispatcher, err := NewDispatcher(
		repository,
		publisher,
		config,
		ClockFunc(func() time.Time { return now }),
	)
	if err != nil {
		t.Fatalf("NewDispatcher() error = %v", err)
	}
	return dispatcher
}

func savedOutboxTestConfig() Config {
	return Config{
		BatchSize:      4,
		Concurrency:    4,
		LeaseDuration:  2 * time.Second,
		PublishTimeout: time.Second,
		MaxAttempts:    3,
		RetryBase:      time.Second,
		RetryMax:       time.Minute,
		CleanupBatch:   4,
	}
}

func savedOutboxClaim(now time.Time, attempt int) ClaimedRecord {
	return ClaimedRecord{
		Lease: Lease{
			EventID:    uuid.New(),
			AcquiredAt: now,
			Attempt:    attempt,
		},
		Kind:          EventSavedItemActivated,
		EntityType:    domain.EntityTypeActivity,
		SchemaVersion: int32(SchemaVersionV1),
		OccurredAt:    now.Add(-time.Second),
	}
}

type savedOutboxRepositoryStub struct {
	mu                  sync.Mutex
	recoveryRequest     RecoveryRequest
	claimRequest        ClaimRequest
	cleanupRequest      CleanupRequest
	recovery            RecoveryResult
	claimed             []ClaimedRecord
	deliveries          []Delivery
	failures            []Failure
	deleted             int64
	deliveryErr         error
	configLeaseDuration time.Duration
}

func (repository *savedOutboxRepositoryStub) RecoverStaleLeases(
	_ context.Context,
	request RecoveryRequest,
) (RecoveryResult, error) {
	repository.mu.Lock()
	defer repository.mu.Unlock()
	repository.recoveryRequest = request
	return repository.recovery, nil
}

func (repository *savedOutboxRepositoryStub) ClaimDue(
	_ context.Context,
	request ClaimRequest,
) ([]ClaimedRecord, error) {
	repository.mu.Lock()
	defer repository.mu.Unlock()
	repository.claimRequest = request
	return append([]ClaimedRecord(nil), repository.claimed...), nil
}

func (repository *savedOutboxRepositoryStub) MarkDelivered(
	_ context.Context,
	delivery Delivery,
) error {
	repository.mu.Lock()
	defer repository.mu.Unlock()
	repository.deliveries = append(repository.deliveries, delivery)
	return repository.deliveryErr
}

func (repository *savedOutboxRepositoryStub) MarkFailed(
	_ context.Context,
	failure Failure,
) (FailureDisposition, error) {
	repository.mu.Lock()
	defer repository.mu.Unlock()
	repository.failures = append(repository.failures, failure)
	if failure.MustBecomeDead() {
		return FailureDead, nil
	}
	return FailureRetryScheduled, nil
}

func (repository *savedOutboxRepositoryStub) DeleteExpired(
	_ context.Context,
	request CleanupRequest,
) (int64, error) {
	repository.mu.Lock()
	defer repository.mu.Unlock()
	repository.cleanupRequest = request
	return repository.deleted, nil
}

type savedOutboxPublisherStub struct {
	mu             sync.Mutex
	failures       map[uuid.UUID]error
	published      []Event
	waitForContext bool
}

func (publisher *savedOutboxPublisherStub) Publish(ctx context.Context, event Event) error {
	publisher.mu.Lock()
	publisher.published = append(publisher.published, event)
	waitForContext := publisher.waitForContext
	failure := publisher.failures[event.EventID]
	publisher.mu.Unlock()
	if waitForContext {
		<-ctx.Done()
		return ctx.Err()
	}
	return failure
}

func (publisher *savedOutboxPublisherStub) publishedCount() int {
	publisher.mu.Lock()
	defer publisher.mu.Unlock()
	return len(publisher.published)
}
