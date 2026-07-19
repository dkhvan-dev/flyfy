package savedlifecycle

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

type lifecycleRepositoryStub struct {
	mu          sync.Mutex
	applyCount  int
	deleteCount int
	outcome     Outcome
	applyErr    error
	deleteErr   error
}

func (r *lifecycleRepositoryStub) Apply(
	_ context.Context,
	_ Event,
	_ time.Time,
) (Outcome, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.applyCount++
	return r.outcome, r.applyErr
}

func (r *lifecycleRepositoryStub) DeleteExpired(
	_ context.Context,
	_ time.Time,
	_ int,
) (int64, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.deleteCount++
	return 3, r.deleteErr
}

func TestServiceValidatesBeforeRepositoryAndPreservesTypedOutcome(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	repository := &lifecycleRepositoryStub{outcome: Outcome{
		Code:              OutcomeApplied,
		ProjectionApplied: true,
	}}
	service, err := NewService(repository)
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	service.now = func() time.Time { return now }

	outcome, err := service.Ingest(
		context.Background(),
		validLifecycleEvent(t, domain.EntityTypeActivity, now),
	)
	if err != nil || outcome.Code != OutcomeApplied || !outcome.ProjectionApplied {
		t.Fatalf("Ingest() = (%+v, %v)", outcome, err)
	}

	invalid := validLifecycleEvent(t, domain.EntityTypeActivity, now)
	invalid.Subject = "content.saved.lifecycle.v1.attraction"
	_, err = service.Ingest(context.Background(), invalid)
	assertPermanentCode(t, err, ErrorCodeInvalidSubject)
	if repository.applyCount != 1 {
		t.Fatalf("repository apply count = %d, want 1", repository.applyCount)
	}
}

func TestServiceCancellationAndCleanupBounds(t *testing.T) {
	t.Parallel()

	repository := &lifecycleRepositoryStub{outcome: Outcome{Code: OutcomeIgnoredStaleRevision}}
	service, err := NewService(repository)
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err = service.Ingest(ctx, Event{})
	if !errors.Is(err, context.Canceled) || repository.applyCount != 0 {
		t.Fatalf("canceled Ingest() error=%v applyCount=%d", err, repository.applyCount)
	}
	if _, err = service.DeleteExpiredInbox(context.Background(), 0); !IsPermanent(err) {
		t.Fatalf("DeleteExpiredInbox(0) error = %v, want permanent", err)
	}
	deleted, err := service.DeleteExpiredInbox(context.Background(), 100)
	if err != nil || deleted != 3 || repository.deleteCount != 1 {
		t.Fatalf("DeleteExpiredInbox() = (%d, %v), calls=%d", deleted, err, repository.deleteCount)
	}
}

func TestServiceConcurrentIngestIsRaceSafe(t *testing.T) {
	now := time.Now().UTC().Truncate(time.Microsecond)
	repository := &lifecycleRepositoryStub{outcome: Outcome{
		Code:              OutcomeApplied,
		ProjectionApplied: true,
	}}
	service, err := NewService(repository)
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	service.now = func() time.Time { return now }
	event := validLifecycleEvent(t, domain.EntityTypeGuide, now)

	var failures atomic.Int64
	var workers sync.WaitGroup
	for range 64 {
		workers.Add(1)
		go func() {
			defer workers.Done()
			if _, ingestErr := service.Ingest(context.Background(), event); ingestErr != nil {
				failures.Add(1)
			}
		}()
	}
	workers.Wait()
	if failures.Load() != 0 || repository.applyCount != 64 {
		t.Fatalf("concurrent failures=%d applyCount=%d", failures.Load(), repository.applyCount)
	}
}

func TestDuplicateOutcomeRejectsUnknownOriginalCode(t *testing.T) {
	t.Parallel()

	outcome := Outcome{Code: OutcomeDuplicate, OriginalCode: OutcomeCode("UNKNOWN_OUTCOME")}
	if outcome.IsValid() {
		t.Fatal("duplicate outcome accepted an unknown original code")
	}
}
