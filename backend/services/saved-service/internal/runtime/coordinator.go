package savedruntime

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
	savedoutbox "kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	savedreconciliation "kz/inflap/backend/services/saved-service/internal/app/savedreconciliation"
)

var (
	ErrInvalidDependencies = errors.New("invalid Saved background runtime dependencies")
	ErrAlreadyStarted      = errors.New("Saved background runtime is already started")
	ErrNotStarted          = errors.New("Saved background runtime is not started")
	ErrLifecycleStopped    = errors.New("Saved lifecycle runner stopped unexpectedly")
)

// LifecycleRunner is expected to block until ctx is cancelled. Any error or
// early nil return while ctx is live is fatal because source privacy changes
// must continue to be ingested.
type LifecycleRunner interface {
	Run(context.Context) error
}

// OutboxDispatcher operations must honor ctx. The coordinator never overlaps
// two calls to the same operation and supplies a deadline for every call.
type OutboxDispatcher interface {
	DispatchBatch(context.Context) (savedoutbox.BatchStats, error)
	CleanupExpired(context.Context) (int64, error)
}

// MaintenanceRunner must honor ctx. RunOnce remains responsible for its own
// bounded batch count; the coordinator additionally bounds wall-clock time.
type MaintenanceRunner interface {
	RunOnce(context.Context) (savedmaintenance.Stats, error)
}

// ReconciliationRunner refreshes only already materialized projections and
// must keep every invocation bounded by both work and wall-clock limits.
type ReconciliationRunner interface {
	Run(context.Context) (savedreconciliation.Stats, error)
}

type delayWaiter interface {
	Wait(context.Context, time.Duration) bool
}

type timerWaiter struct{}

func (timerWaiter) Wait(ctx context.Context, delay time.Duration) bool {
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return false
	case <-timer.C:
		return true
	}
}

type coordinatorLifecycleState uint8

const (
	coordinatorStateNew coordinatorLifecycleState = iota
	coordinatorStateRunning
	coordinatorStateStopping
	coordinatorStateStopped
)

// Coordinator owns all Saved background goroutines. Start is non-blocking;
// Wait returns only after every worker exits and surfaces lifecycle failures.
// Outbox and maintenance failures are observed and retried, never returned.
type Coordinator struct {
	lifecycle      LifecycleRunner
	outbox         OutboxDispatcher
	maintenance    MaintenanceRunner
	reconciliation ReconciliationRunner
	observer       Observer
	config         Config
	waiter         delayWaiter

	mu       sync.Mutex
	state    coordinatorLifecycleState
	cancel   context.CancelFunc
	done     chan struct{}
	fatalErr error
	workers  sync.WaitGroup
}

func NewCoordinator(
	lifecycle LifecycleRunner,
	outbox OutboxDispatcher,
	maintenance MaintenanceRunner,
	reconciliation ReconciliationRunner,
	config Config,
	observer Observer,
) (*Coordinator, error) {
	return newCoordinator(lifecycle, outbox, maintenance, reconciliation, config, observer, timerWaiter{})
}

func newCoordinator(
	lifecycle LifecycleRunner,
	outbox OutboxDispatcher,
	maintenance MaintenanceRunner,
	reconciliation ReconciliationRunner,
	config Config,
	observer Observer,
	waiter delayWaiter,
) (*Coordinator, error) {
	if lifecycle == nil || outbox == nil || maintenance == nil || reconciliation == nil || waiter == nil {
		return nil, ErrInvalidDependencies
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}
	if observer == nil {
		observer = noopObserver{}
	}
	return &Coordinator{
		lifecycle:      lifecycle,
		outbox:         outbox,
		maintenance:    maintenance,
		reconciliation: reconciliation,
		observer:       observer,
		config:         config,
		waiter:         waiter,
	}, nil
}

func (coordinator *Coordinator) Start(parent context.Context) error {
	if coordinator == nil || parent == nil {
		return ErrInvalidDependencies
	}
	if err := parent.Err(); err != nil {
		return err
	}

	coordinator.mu.Lock()
	if coordinator.state != coordinatorStateNew {
		coordinator.mu.Unlock()
		return ErrAlreadyStarted
	}
	ctx, cancel := context.WithCancel(parent)
	coordinator.state = coordinatorStateRunning
	coordinator.cancel = cancel
	coordinator.done = make(chan struct{})
	coordinator.workers.Add(5)
	go coordinator.runLifecycle(ctx)
	go coordinator.runOutboxDispatch(ctx)
	go coordinator.runOutboxCleanup(ctx)
	go coordinator.runMaintenance(ctx)
	go coordinator.runReconciliation(ctx)
	go func() {
		coordinator.workers.Wait()
		coordinator.mu.Lock()
		coordinator.state = coordinatorStateStopped
		close(coordinator.done)
		coordinator.mu.Unlock()
	}()
	coordinator.mu.Unlock()
	return nil
}

// Run is a convenience for process supervisors that do not need separate
// startup and wait phases.
func (coordinator *Coordinator) Run(ctx context.Context) error {
	if err := coordinator.Start(ctx); err != nil {
		return err
	}
	return coordinator.Wait()
}

// Stop is idempotent. Wait should be used after Stop when a graceful shutdown
// must be complete before database or broker dependencies are closed.
func (coordinator *Coordinator) Stop() {
	if coordinator == nil {
		return
	}
	coordinator.mu.Lock()
	if coordinator.state == coordinatorStateNew {
		coordinator.state = coordinatorStateStopped
		coordinator.mu.Unlock()
		return
	}
	if coordinator.state == coordinatorStateRunning {
		coordinator.state = coordinatorStateStopping
	}
	cancel := coordinator.cancel
	coordinator.mu.Unlock()
	if cancel != nil {
		cancel()
	}
}

func (coordinator *Coordinator) Wait() error {
	if coordinator == nil {
		return ErrInvalidDependencies
	}
	coordinator.mu.Lock()
	if coordinator.state == coordinatorStateNew || coordinator.done == nil {
		coordinator.mu.Unlock()
		return ErrNotStarted
	}
	done := coordinator.done
	coordinator.mu.Unlock()

	<-done
	coordinator.mu.Lock()
	defer coordinator.mu.Unlock()
	return coordinator.fatalErr
}

func (coordinator *Coordinator) runLifecycle(ctx context.Context) {
	defer coordinator.workers.Done()
	startedAt := time.Now().UTC()
	err := coordinator.lifecycle.Run(ctx)
	finishedAt := time.Now().UTC()
	if ctx.Err() != nil {
		return
	}
	if err == nil {
		err = ErrLifecycleStopped
	} else {
		err = fmt.Errorf("run Saved lifecycle consumer: %w", err)
	}

	coordinator.setFatal(err)
	coordinator.observe(Observation{
		Task:       TaskLifecycle,
		StartedAt:  startedAt,
		FinishedAt: finishedAt,
		Err:        err,
	})
}

func (coordinator *Coordinator) runOutboxDispatch(ctx context.Context) {
	defer coordinator.workers.Done()
	failures := 0
	for ctx.Err() == nil {
		startedAt := time.Now().UTC()
		runCtx, cancel := context.WithTimeout(ctx, coordinator.config.OutboxDispatchTimeout)
		stats, err := coordinator.outbox.DispatchBatch(runCtx)
		cancel()
		if ctx.Err() != nil {
			return
		}

		delay := coordinator.config.OutboxPollInterval
		if err != nil {
			failures++
			delay = boundedBackoff(
				coordinator.config.OutboxBackoffBase,
				coordinator.config.OutboxBackoffMax,
				failures,
			)
		} else {
			failures = 0
			if stats.LikelyMore {
				delay = coordinator.config.OutboxBusyInterval
			}
		}
		coordinator.observe(Observation{
			Task:                TaskOutboxDispatch,
			StartedAt:           startedAt,
			FinishedAt:          time.Now().UTC(),
			ConsecutiveFailures: failures,
			NextDelay:           delay,
			Err:                 err,
			OutboxBatch:         stats,
		})
		if !coordinator.waiter.Wait(ctx, delay) {
			return
		}
	}
}

func (coordinator *Coordinator) runOutboxCleanup(ctx context.Context) {
	defer coordinator.workers.Done()
	failures := 0
	for ctx.Err() == nil {
		startedAt := time.Now().UTC()
		runCtx, cancel := context.WithTimeout(ctx, coordinator.config.OutboxCleanupTimeout)
		deleted, err := coordinator.outbox.CleanupExpired(runCtx)
		cancel()
		if ctx.Err() != nil {
			return
		}

		delay := coordinator.config.OutboxCleanupInterval
		if err != nil {
			failures++
			delay = boundedBackoff(
				coordinator.config.OutboxBackoffBase,
				coordinator.config.OutboxBackoffMax,
				failures,
			)
		} else {
			failures = 0
		}
		coordinator.observe(Observation{
			Task:                TaskOutboxCleanup,
			StartedAt:           startedAt,
			FinishedAt:          time.Now().UTC(),
			ConsecutiveFailures: failures,
			NextDelay:           delay,
			Err:                 err,
			OutboxDeleted:       deleted,
		})
		if !coordinator.waiter.Wait(ctx, delay) {
			return
		}
	}
}

func (coordinator *Coordinator) runMaintenance(ctx context.Context) {
	defer coordinator.workers.Done()
	failures := 0
	for ctx.Err() == nil {
		startedAt := time.Now().UTC()
		runCtx, cancel := context.WithTimeout(ctx, coordinator.config.MaintenanceRunTimeout)
		stats, err := coordinator.maintenance.RunOnce(runCtx)
		cancel()
		if ctx.Err() != nil {
			return
		}

		delay := coordinator.config.MaintenanceInterval
		if err != nil {
			failures++
			delay = boundedBackoff(
				coordinator.config.MaintenanceBackoffBase,
				coordinator.config.MaintenanceBackoffMax,
				failures,
			)
		} else {
			failures = 0
			if stats.Capped || stats.HasMore {
				delay = coordinator.config.MaintenanceBusyInterval
			}
		}
		coordinator.observe(Observation{
			Task:                TaskMaintenance,
			StartedAt:           startedAt,
			FinishedAt:          time.Now().UTC(),
			ConsecutiveFailures: failures,
			NextDelay:           delay,
			Err:                 err,
			MaintenanceRun:      stats,
		})
		if !coordinator.waiter.Wait(ctx, delay) {
			return
		}
	}
}

func (coordinator *Coordinator) runReconciliation(ctx context.Context) {
	defer coordinator.workers.Done()
	failures := 0
	for ctx.Err() == nil {
		startedAt := time.Now().UTC()
		runCtx, cancel := context.WithTimeout(ctx, coordinator.config.ReconciliationRunTimeout)
		stats, err := coordinator.reconciliation.Run(runCtx)
		cancel()
		if ctx.Err() != nil {
			return
		}

		delay := coordinator.config.ReconciliationInterval
		if err != nil {
			failures++
			delay = boundedBackoff(
				coordinator.config.ReconciliationBackoffBase,
				coordinator.config.ReconciliationBackoffMax,
				failures,
			)
		} else {
			failures = 0
			if stats.HasMore {
				delay = coordinator.config.ReconciliationBusyInterval
			}
		}
		coordinator.observe(Observation{
			Task:                TaskReconciliation,
			StartedAt:           startedAt,
			FinishedAt:          time.Now().UTC(),
			ConsecutiveFailures: failures,
			NextDelay:           delay,
			Err:                 err,
			ReconciliationRun:   stats,
		})
		if !coordinator.waiter.Wait(ctx, delay) {
			return
		}
	}
}

func (coordinator *Coordinator) setFatal(err error) {
	coordinator.mu.Lock()
	if coordinator.fatalErr == nil {
		coordinator.fatalErr = err
	}
	if coordinator.state == coordinatorStateRunning {
		coordinator.state = coordinatorStateStopping
	}
	cancel := coordinator.cancel
	coordinator.mu.Unlock()
	if cancel != nil {
		cancel()
	}
}

func (coordinator *Coordinator) observe(observation Observation) {
	defer func() {
		_ = recover()
	}()
	coordinator.observer.ObserveSavedRuntime(observation)
}

func boundedBackoff(base, maximum time.Duration, failures int) time.Duration {
	if failures <= 1 {
		return base
	}
	delay := base
	for attempt := 1; attempt < failures; attempt++ {
		if delay >= maximum || delay > maximum/2 {
			return maximum
		}
		delay *= 2
	}
	if delay > maximum {
		return maximum
	}
	return delay
}
