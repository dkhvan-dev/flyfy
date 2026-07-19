package savedmaintenance

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
)

const (
	taskExpireOperations = iota
	taskPurgeOperations
	taskPurgeOutbox
	taskPurgeInbox
	taskCleanupCollectionChildren
	taskPurgeCollectionItems
	taskPurgeCollections
	taskPurgeSavedItems
	taskMarkProjections
	taskPurgeEphemeralProjections
	taskPurgeStandardProjections
	taskPurgeCompletedSubjectJobs
	taskCount
)

func TestDefaultConfigAndValidation(t *testing.T) {
	t.Parallel()

	config := DefaultConfig()
	if err := config.Validate(); err != nil {
		t.Fatalf("DefaultConfig().Validate() error = %v", err)
	}
	if config.OperationRetention != 14*24*time.Hour || config.ProjectionRetention != 14*24*time.Hour {
		t.Fatalf("default retention = (%s, %s)", config.OperationRetention, config.ProjectionRetention)
	}

	invalid := config
	invalid.OperationRetention--
	if !errors.Is(invalid.Validate(), ErrInvalidConfig) {
		t.Fatalf("operation retention validation error = %v", invalid.Validate())
	}
	invalid = config
	invalid.BatchSize = 0
	if !errors.Is(invalid.Validate(), ErrInvalidConfig) {
		t.Fatalf("batch size validation error = %v", invalid.Validate())
	}
}

func TestRunnerTickAggregatesInDependencyOrder(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	repository := newFakeMaintenanceRepository()
	repository.subjectResults = []SubjectPurgeBatchResult{{
		Found:         true,
		OperationID:   uuid.New(),
		PhaseBefore:   SubjectPurgePhaseOutbox,
		PhaseAfter:    SubjectPurgePhaseCollectionItems,
		RowsPurged:    1,
		PhaseAdvanced: true,
		HasMore:       true,
	}}
	for task := 0; task < taskCount; task++ {
		repository.results[task] = []BatchResult{{Affected: int64(task + 1)}}
	}

	runner, err := NewRunner(repository, DefaultConfig(), func() time.Time { return now })
	if err != nil {
		t.Fatalf("NewRunner() error = %v", err)
	}
	stats, err := runner.Tick(context.Background())
	if err != nil {
		t.Fatalf("Tick() error = %v", err)
	}
	if stats.Ticks != 1 || stats.SubjectPurgeRowsPurged != 1 || stats.SubjectPurgePhasesAdvanced != 1 {
		t.Fatalf("Tick() subject stats = %+v", stats)
	}
	if stats.PendingOperationsExpired != 1 || stats.StandardProjectionsPurged != 11 ||
		stats.CompletedSubjectPurgesPurged != 12 || !stats.HasMore {
		t.Fatalf("Tick() stats = %+v", stats)
	}

	wantCalls := []int{
		taskExpireOperations,
		taskPurgeOperations,
		taskPurgeOutbox,
		taskPurgeInbox,
		taskCleanupCollectionChildren,
		taskPurgeCollectionItems,
		taskPurgeCollections,
		taskPurgeSavedItems,
		taskMarkProjections,
		taskPurgeEphemeralProjections,
		taskPurgeStandardProjections,
		taskPurgeCompletedSubjectJobs,
	}
	if calls := repository.snapshotCalls(); !equalInts(calls, wantCalls) {
		t.Fatalf("repository calls = %v, want %v", calls, wantCalls)
	}
}

func TestRunnerRunOnceDrainsAndCaps(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	config := DefaultConfig()
	config.BatchSize = 2
	config.MaxBatchesPerRun = 3

	t.Run("drains", func(t *testing.T) {
		repository := newFakeMaintenanceRepository()
		repository.results[taskExpireOperations] = []BatchResult{
			{Affected: 2, HasMore: true},
			{Affected: 1},
		}
		runner, err := NewRunner(repository, config, func() time.Time { return now })
		if err != nil {
			t.Fatalf("NewRunner() error = %v", err)
		}
		stats, err := runner.RunOnce(context.Background())
		if err != nil {
			t.Fatalf("RunOnce() error = %v", err)
		}
		if stats.Ticks != 2 || stats.PendingOperationsExpired != 3 || stats.Capped || stats.HasMore {
			t.Fatalf("RunOnce() stats = %+v", stats)
		}
	})

	t.Run("caps continuous backlog", func(t *testing.T) {
		repository := newFakeMaintenanceRepository()
		repository.defaultResults[taskExpireOperations] = BatchResult{Affected: 2, HasMore: true}
		runner, err := NewRunner(repository, config, func() time.Time { return now })
		if err != nil {
			t.Fatalf("NewRunner() error = %v", err)
		}
		stats, err := runner.RunOnce(context.Background())
		if err != nil {
			t.Fatalf("RunOnce() error = %v", err)
		}
		if stats.Ticks != 3 || stats.PendingOperationsExpired != 6 || !stats.Capped || !stats.HasMore {
			t.Fatalf("RunOnce() stats = %+v", stats)
		}
	})
}

func TestRunnerCancellationAndTypedErrors(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	repository := newFakeMaintenanceRepository()
	runner, err := NewRunner(repository, DefaultConfig(), func() time.Time { return now })
	if err != nil {
		t.Fatalf("NewRunner() error = %v", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := runner.Tick(ctx); !errors.Is(err, context.Canceled) {
		t.Fatalf("Tick(cancelled) error = %v", err)
	}
	if calls := repository.snapshotCalls(); len(calls) != 0 {
		t.Fatalf("cancelled Tick() called repository: %v", calls)
	}

	repository.taskErrors[taskExpireOperations] = errors.New("database unavailable")
	_, err = runner.Tick(context.Background())
	if err == nil || !IsRetryable(err) {
		t.Fatalf("Tick(repository error) = %v, want retryable error", err)
	}
	var typed *Error
	if !errors.As(err, &typed) || typed.Operation != "expire pending operations" {
		t.Fatalf("Tick(repository error) typed = %#v", typed)
	}
}

func TestRunnerConcurrentTicksAreRaceSafe(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 0, 0, 0, time.UTC)
	repository := newFakeMaintenanceRepository()
	runner, err := NewRunner(repository, DefaultConfig(), func() time.Time { return now })
	if err != nil {
		t.Fatalf("NewRunner() error = %v", err)
	}

	const workers = 32
	start := make(chan struct{})
	errorsChannel := make(chan error, workers)
	var ready sync.WaitGroup
	ready.Add(workers)
	for range workers {
		go func() {
			ready.Done()
			<-start
			_, err := runner.Tick(context.Background())
			errorsChannel <- err
		}()
	}
	ready.Wait()
	close(start)
	for range workers {
		if err := <-errorsChannel; err != nil {
			t.Fatalf("concurrent Tick() error = %v", err)
		}
	}
}

type fakeMaintenanceRepository struct {
	mu             sync.Mutex
	results        [taskCount][]BatchResult
	defaultResults [taskCount]BatchResult
	taskErrors     [taskCount]error
	calls          []int
	subjectResults []SubjectPurgeBatchResult
	subjectJob     SubjectPurgeJob
}

func newFakeMaintenanceRepository() *fakeMaintenanceRepository {
	return &fakeMaintenanceRepository{}
}

func (r *fakeMaintenanceRepository) run(task int) (BatchResult, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.calls = append(r.calls, task)
	if r.taskErrors[task] != nil {
		return BatchResult{}, r.taskErrors[task]
	}
	if len(r.results[task]) > 0 {
		result := r.results[task][0]
		r.results[task] = r.results[task][1:]
		return result, nil
	}
	return r.defaultResults[task], nil
}

func (r *fakeMaintenanceRepository) snapshotCalls() []int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]int(nil), r.calls...)
}

func (r *fakeMaintenanceRepository) ProcessSubjectPurge(
	_ context.Context,
	_ SubjectPurgeBatchRequest,
) (SubjectPurgeBatchResult, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if len(r.subjectResults) == 0 {
		return SubjectPurgeBatchResult{}, nil
	}
	result := r.subjectResults[0]
	r.subjectResults = r.subjectResults[1:]
	return result, nil
}

func (r *fakeMaintenanceRepository) StartSubjectPurge(
	_ context.Context,
	start SubjectPurgeStart,
	now time.Time,
) (SubjectPurgeJob, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.subjectJob.OperationID == uuid.Nil {
		next := now.UTC()
		r.subjectJob = SubjectPurgeJob{
			OperationID:   start.OperationID,
			Subject:       start.Subject,
			OwnerUserID:   start.OwnerUserID,
			Phase:         SubjectPurgePhaseOutbox,
			NextAttemptAt: &next,
			CreatedAt:     next,
			UpdatedAt:     next,
		}
	}
	return r.subjectJob, nil
}

func (r *fakeMaintenanceRepository) GetSubjectPurge(context.Context, uuid.UUID) (SubjectPurgeJob, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.subjectJob.OperationID == uuid.Nil {
		return SubjectPurgeJob{}, ErrSubjectPurgeNotFound
	}
	return r.subjectJob, nil
}

func (r *fakeMaintenanceRepository) ExpirePendingOperations(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskExpireOperations)
}
func (r *fakeMaintenanceRepository) PurgeTerminalOperations(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeOperations)
}
func (r *fakeMaintenanceRepository) PurgeTerminalOutbox(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeOutbox)
}
func (r *fakeMaintenanceRepository) PurgeInboxDedup(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeInbox)
}
func (r *fakeMaintenanceRepository) CleanupDeletedCollectionChildren(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskCleanupCollectionChildren)
}
func (r *fakeMaintenanceRepository) PurgeRemovedCollectionItems(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeCollectionItems)
}
func (r *fakeMaintenanceRepository) PurgeDeletedCollections(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeCollections)
}
func (r *fakeMaintenanceRepository) PurgeRemovedSavedItems(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeSavedItems)
}
func (r *fakeMaintenanceRepository) MarkProjectionGCCandidates(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskMarkProjections)
}
func (r *fakeMaintenanceRepository) PurgeEphemeralProjections(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeEphemeralProjections)
}
func (r *fakeMaintenanceRepository) PurgeStandardProjections(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeStandardProjections)
}
func (r *fakeMaintenanceRepository) PurgeCompletedSubjectPurges(context.Context, BatchRequest) (BatchResult, error) {
	return r.run(taskPurgeCompletedSubjectJobs)
}

func equalInts(left, right []int) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}
