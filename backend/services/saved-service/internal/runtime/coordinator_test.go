package savedruntime

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
	savedoutbox "kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	savedreconciliation "kz/inflap/backend/services/saved-service/internal/app/savedreconciliation"
)

type lifecycleRunnerFunc func(context.Context) error

func (function lifecycleRunnerFunc) Run(ctx context.Context) error {
	return function(ctx)
}

type outboxDispatcherStub struct {
	dispatch func(context.Context) (savedoutbox.BatchStats, error)
	cleanup  func(context.Context) (int64, error)
}

func (stub *outboxDispatcherStub) DispatchBatch(ctx context.Context) (savedoutbox.BatchStats, error) {
	return stub.dispatch(ctx)
}

func (stub *outboxDispatcherStub) CleanupExpired(ctx context.Context) (int64, error) {
	return stub.cleanup(ctx)
}

type maintenanceRunnerFunc func(context.Context) (savedmaintenance.Stats, error)

func (function maintenanceRunnerFunc) RunOnce(ctx context.Context) (savedmaintenance.Stats, error) {
	return function(ctx)
}

type reconciliationRunnerFunc func(context.Context) (savedreconciliation.Stats, error)

func (function reconciliationRunnerFunc) Run(ctx context.Context) (savedreconciliation.Stats, error) {
	return function(ctx)
}

type recordingObserver struct {
	mu           sync.Mutex
	observations []Observation
}

func (observer *recordingObserver) ObserveSavedRuntime(observation Observation) {
	observer.mu.Lock()
	observer.observations = append(observer.observations, observation)
	observer.mu.Unlock()
}

func (observer *recordingObserver) snapshot() []Observation {
	observer.mu.Lock()
	defer observer.mu.Unlock()
	return append([]Observation(nil), observer.observations...)
}

func TestCoordinatorLifecycleFailureIsFatalAndCancelsEveryWorker(t *testing.T) {
	t.Parallel()

	lifecycleStarted := make(chan struct{})
	dispatchStarted := make(chan struct{})
	cleanupStarted := make(chan struct{})
	maintenanceStarted := make(chan struct{})
	releaseLifecycle := make(chan struct{})
	lifecycleFailure := errors.New("provision lifecycle consumer")
	var active atomic.Int32

	lifecycle := lifecycleRunnerFunc(func(ctx context.Context) error {
		active.Add(1)
		defer active.Add(-1)
		close(lifecycleStarted)
		select {
		case <-releaseLifecycle:
			return lifecycleFailure
		case <-ctx.Done():
			return ctx.Err()
		}
	})
	outbox := &outboxDispatcherStub{
		dispatch: blockingOutboxBatch(&active, dispatchStarted),
		cleanup:  blockingOutboxCleanup(&active, cleanupStarted),
	}
	maintenance := maintenanceRunnerFunc(blockingMaintenance(&active, maintenanceStarted))
	observer := &recordingObserver{}
	coordinator := mustCoordinator(t, lifecycle, outbox, maintenance, observer, testConfig())
	defer coordinator.Stop()

	if err := coordinator.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	waitSignal(t, lifecycleStarted)
	waitSignal(t, dispatchStarted)
	waitSignal(t, cleanupStarted)
	waitSignal(t, maintenanceStarted)
	close(releaseLifecycle)

	err := waitCoordinator(t, coordinator)
	if !errors.Is(err, lifecycleFailure) {
		t.Fatalf("Wait() error = %v, want wrapped lifecycle failure", err)
	}
	if got := active.Load(); got != 0 {
		t.Fatalf("active workers after Wait() = %d, want 0", got)
	}
	assertObservedError(t, observer.snapshot(), TaskLifecycle, lifecycleFailure)
}

func TestCoordinatorParentCancellationIsGraceful(t *testing.T) {
	t.Parallel()

	lifecycleStarted := make(chan struct{})
	dispatchStarted := make(chan struct{})
	cleanupStarted := make(chan struct{})
	maintenanceStarted := make(chan struct{})
	var active atomic.Int32

	lifecycle := lifecycleRunnerFunc(func(ctx context.Context) error {
		active.Add(1)
		defer active.Add(-1)
		close(lifecycleStarted)
		<-ctx.Done()
		return ctx.Err()
	})
	outbox := &outboxDispatcherStub{
		dispatch: blockingOutboxBatch(&active, dispatchStarted),
		cleanup:  blockingOutboxCleanup(&active, cleanupStarted),
	}
	maintenance := maintenanceRunnerFunc(blockingMaintenance(&active, maintenanceStarted))
	coordinator := mustCoordinator(t, lifecycle, outbox, maintenance, nil, testConfig())

	ctx, cancel := context.WithCancel(context.Background())
	if err := coordinator.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	waitSignal(t, lifecycleStarted)
	waitSignal(t, dispatchStarted)
	waitSignal(t, cleanupStarted)
	waitSignal(t, maintenanceStarted)
	cancel()

	if err := waitCoordinator(t, coordinator); err != nil {
		t.Fatalf("Wait() error = %v, want nil", err)
	}
	if got := active.Load(); got != 0 {
		t.Fatalf("active workers after Wait() = %d, want 0", got)
	}
}

func TestTransientTaskFailuresAreObservedRetriedAndNonFatal(t *testing.T) {
	t.Parallel()

	dispatchFailure := errors.New("outbox unavailable")
	cleanupFailure := errors.New("outbox cleanup unavailable")
	maintenanceFailure := errors.New("maintenance unavailable")
	dispatchRetried := make(chan struct{})
	cleanupRetried := make(chan struct{})
	maintenanceRetried := make(chan struct{})
	var dispatchCalls atomic.Int32
	var cleanupCalls atomic.Int32
	var maintenanceCalls atomic.Int32

	lifecycle := lifecycleRunnerFunc(func(ctx context.Context) error {
		<-ctx.Done()
		return ctx.Err()
	})
	outbox := &outboxDispatcherStub{
		dispatch: func(context.Context) (savedoutbox.BatchStats, error) {
			if dispatchCalls.Add(1) == 1 {
				return savedoutbox.BatchStats{}, dispatchFailure
			}
			signalOnce(dispatchRetried)
			return savedoutbox.BatchStats{Delivered: 1}, nil
		},
		cleanup: func(context.Context) (int64, error) {
			if cleanupCalls.Add(1) == 1 {
				return 0, cleanupFailure
			}
			signalOnce(cleanupRetried)
			return 2, nil
		},
	}
	maintenance := maintenanceRunnerFunc(func(context.Context) (savedmaintenance.Stats, error) {
		if maintenanceCalls.Add(1) == 1 {
			return savedmaintenance.Stats{}, maintenanceFailure
		}
		signalOnce(maintenanceRetried)
		return savedmaintenance.Stats{Ticks: 1}, nil
	})
	observer := &recordingObserver{}
	coordinator := mustCoordinator(t, lifecycle, outbox, maintenance, observer, testConfig())
	defer coordinator.Stop()

	ctx, cancel := context.WithCancel(context.Background())
	if err := coordinator.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	waitSignal(t, dispatchRetried)
	waitSignal(t, cleanupRetried)
	waitSignal(t, maintenanceRetried)
	waitForObservedSuccess(t, observer, TaskOutboxDispatch)
	waitForObservedSuccess(t, observer, TaskOutboxCleanup)
	waitForObservedSuccess(t, observer, TaskMaintenance)

	waitResult := make(chan error, 1)
	go func() { waitResult <- coordinator.Wait() }()
	select {
	case err := <-waitResult:
		t.Fatalf("coordinator exited after transient error: %v", err)
	default:
	}
	cancel()
	select {
	case err := <-waitResult:
		if err != nil {
			t.Fatalf("Wait() error = %v, want nil", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("Wait() did not finish after cancellation")
	}

	observations := observer.snapshot()
	assertObservedRetry(
		t,
		observations,
		TaskOutboxDispatch,
		dispatchFailure,
		testConfig().OutboxBackoffBase,
	)
	assertObservedRetry(
		t,
		observations,
		TaskOutboxCleanup,
		cleanupFailure,
		testConfig().OutboxBackoffBase,
	)
	assertObservedRetry(
		t,
		observations,
		TaskMaintenance,
		maintenanceFailure,
		testConfig().MaintenanceBackoffBase,
	)
	assertObservedSuccess(t, observations, TaskOutboxDispatch)
	assertObservedSuccess(t, observations, TaskOutboxCleanup)
	assertObservedSuccess(t, observations, TaskMaintenance)
}

func TestCoordinatorSuppliesDeadlineToEveryBoundedTask(t *testing.T) {
	t.Parallel()

	dispatchDeadline := make(chan deadlineSample, 1)
	cleanupDeadline := make(chan deadlineSample, 1)
	maintenanceDeadline := make(chan deadlineSample, 1)
	reconciliationDeadline := make(chan deadlineSample, 1)
	config := testConfig()
	config.OutboxDispatchTimeout = 70 * time.Millisecond
	config.OutboxCleanupTimeout = 80 * time.Millisecond
	config.MaintenanceRunTimeout = 90 * time.Millisecond
	config.ReconciliationRunTimeout = 100 * time.Millisecond

	lifecycle := lifecycleRunnerFunc(func(ctx context.Context) error {
		<-ctx.Done()
		return ctx.Err()
	})
	outbox := &outboxDispatcherStub{
		dispatch: func(ctx context.Context) (savedoutbox.BatchStats, error) {
			recordDeadline(dispatchDeadline, sampleDeadline(ctx))
			return savedoutbox.BatchStats{}, nil
		},
		cleanup: func(ctx context.Context) (int64, error) {
			recordDeadline(cleanupDeadline, sampleDeadline(ctx))
			return 0, nil
		},
	}
	maintenance := maintenanceRunnerFunc(func(ctx context.Context) (savedmaintenance.Stats, error) {
		recordDeadline(maintenanceDeadline, sampleDeadline(ctx))
		return savedmaintenance.Stats{}, nil
	})
	reconciliation := reconciliationRunnerFunc(func(ctx context.Context) (savedreconciliation.Stats, error) {
		recordDeadline(reconciliationDeadline, sampleDeadline(ctx))
		return savedreconciliation.Stats{}, nil
	})
	coordinator := mustCoordinator(
		t,
		lifecycle,
		outbox,
		maintenance,
		nil,
		config,
		reconciliation,
	)
	defer coordinator.Stop()

	ctx, cancel := context.WithCancel(context.Background())
	if err := coordinator.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	assertBoundedDeadline(t, <-dispatchDeadline, config.OutboxDispatchTimeout)
	assertBoundedDeadline(t, <-cleanupDeadline, config.OutboxCleanupTimeout)
	assertBoundedDeadline(t, <-maintenanceDeadline, config.MaintenanceRunTimeout)
	assertBoundedDeadline(t, <-reconciliationDeadline, config.ReconciliationRunTimeout)
	cancel()
	if err := waitCoordinator(t, coordinator); err != nil {
		t.Fatalf("Wait() error = %v, want nil", err)
	}
}

func TestUnexpectedLifecycleReturnIsFatal(t *testing.T) {
	t.Parallel()

	lifecycle := lifecycleRunnerFunc(func(context.Context) error { return nil })
	outbox := &outboxDispatcherStub{
		dispatch: func(context.Context) (savedoutbox.BatchStats, error) {
			return savedoutbox.BatchStats{}, nil
		},
		cleanup: func(context.Context) (int64, error) { return 0, nil },
	}
	maintenance := maintenanceRunnerFunc(func(context.Context) (savedmaintenance.Stats, error) {
		return savedmaintenance.Stats{}, nil
	})
	coordinator := mustCoordinator(t, lifecycle, outbox, maintenance, nil, testConfig())

	if err := coordinator.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	if err := waitCoordinator(t, coordinator); !errors.Is(err, ErrLifecycleStopped) {
		t.Fatalf("Wait() error = %v, want ErrLifecycleStopped", err)
	}
}

func TestCoordinatorLifecycleMethodsAreStateSafe(t *testing.T) {
	t.Parallel()

	lifecycle := lifecycleRunnerFunc(func(ctx context.Context) error {
		<-ctx.Done()
		return ctx.Err()
	})
	outbox := &outboxDispatcherStub{
		dispatch: func(context.Context) (savedoutbox.BatchStats, error) {
			return savedoutbox.BatchStats{}, nil
		},
		cleanup: func(context.Context) (int64, error) { return 0, nil },
	}
	maintenance := maintenanceRunnerFunc(func(context.Context) (savedmaintenance.Stats, error) {
		return savedmaintenance.Stats{}, nil
	})
	observerCalled := make(chan struct{})
	var observerOnce sync.Once
	coordinator := mustCoordinator(t, lifecycle, outbox, maintenance, ObserverFunc(func(observation Observation) {
		if observation.Task == TaskOutboxDispatch {
			observerOnce.Do(func() { close(observerCalled) })
		}
		panic("observer must not own runtime liveness")
	}), testConfig())
	defer coordinator.Stop()

	if err := coordinator.Wait(); !errors.Is(err, ErrNotStarted) {
		t.Fatalf("Wait() before Start error = %v, want ErrNotStarted", err)
	}
	cancelled, cancel := context.WithCancel(context.Background())
	cancel()
	if err := coordinator.Start(cancelled); !errors.Is(err, context.Canceled) {
		t.Fatalf("Start(cancelled) error = %v, want context.Canceled", err)
	}
	if err := coordinator.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	waitSignal(t, observerCalled)
	if err := coordinator.Start(context.Background()); !errors.Is(err, ErrAlreadyStarted) {
		t.Fatalf("second Start() error = %v, want ErrAlreadyStarted", err)
	}
	coordinator.Stop()
	coordinator.Stop()
	if err := waitCoordinator(t, coordinator); err != nil {
		t.Fatalf("Wait() error = %v, want nil", err)
	}
}

func TestCoordinatorStopWinningStartRaceCannotResurrectWorkers(t *testing.T) {
	t.Parallel()

	var calls atomic.Int32
	lifecycle := lifecycleRunnerFunc(func(context.Context) error {
		calls.Add(1)
		return nil
	})
	outbox := &outboxDispatcherStub{
		dispatch: func(context.Context) (savedoutbox.BatchStats, error) {
			calls.Add(1)
			return savedoutbox.BatchStats{}, nil
		},
		cleanup: func(context.Context) (int64, error) {
			calls.Add(1)
			return 0, nil
		},
	}
	maintenance := maintenanceRunnerFunc(func(context.Context) (savedmaintenance.Stats, error) {
		calls.Add(1)
		return savedmaintenance.Stats{}, nil
	})
	coordinator := mustCoordinator(t, lifecycle, outbox, maintenance, nil, testConfig())

	startGate := make(chan struct{})
	startResult := make(chan error, 1)
	go func() {
		<-startGate
		startResult <- coordinator.Start(context.Background())
	}()
	stopFinished := make(chan struct{})
	go func() {
		coordinator.Stop()
		close(stopFinished)
	}()
	waitSignal(t, stopFinished)
	close(startGate)

	if err := <-startResult; !errors.Is(err, ErrAlreadyStarted) {
		t.Fatalf("Start() after concurrent Stop error = %v, want ErrAlreadyStarted", err)
	}
	if err := coordinator.Wait(); !errors.Is(err, ErrNotStarted) {
		t.Fatalf("Wait() error = %v, want ErrNotStarted", err)
	}
	if calls.Load() != 0 {
		t.Fatalf("worker calls after Stop won = %d, want 0", calls.Load())
	}
}

func TestReconciliationBusyDelayRequiresConfirmedHasMore(t *testing.T) {
	t.Parallel()

	for _, testCase := range []struct {
		name      string
		stats     savedreconciliation.Stats
		wantDelay time.Duration
	}{
		{
			name:      "batch_exactly_consumed",
			stats:     savedreconciliation.Stats{Capped: true, HasMore: false},
			wantDelay: testConfig().ReconciliationInterval,
		},
		{
			name:      "more_due_now",
			stats:     savedreconciliation.Stats{Capped: true, HasMore: true},
			wantDelay: testConfig().ReconciliationBusyInterval,
		},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			waiter := &capturingDelayWaiter{delays: make(chan time.Duration, 1)}
			reconciliation := reconciliationRunnerFunc(func(context.Context) (savedreconciliation.Stats, error) {
				return testCase.stats, nil
			})
			coordinator := mustCoordinator(
				t,
				lifecycleRunnerFunc(func(context.Context) error { return nil }),
				&outboxDispatcherStub{
					dispatch: func(context.Context) (savedoutbox.BatchStats, error) {
						return savedoutbox.BatchStats{}, nil
					},
					cleanup: func(context.Context) (int64, error) { return 0, nil },
				},
				maintenanceRunnerFunc(func(context.Context) (savedmaintenance.Stats, error) {
					return savedmaintenance.Stats{}, nil
				}),
				nil,
				testConfig(),
				reconciliation,
			)
			coordinator.waiter = waiter
			coordinator.workers.Add(1)
			go coordinator.runReconciliation(context.Background())

			select {
			case delay := <-waiter.delays:
				if delay != testCase.wantDelay {
					t.Fatalf("reconciliation delay = %s, want %s", delay, testCase.wantDelay)
				}
			case <-time.After(time.Second):
				t.Fatal("timed out waiting for reconciliation delay")
			}
			coordinator.workers.Wait()
		})
	}
}

func blockingOutboxBatch(active *atomic.Int32, started chan struct{}) func(context.Context) (savedoutbox.BatchStats, error) {
	return func(ctx context.Context) (savedoutbox.BatchStats, error) {
		active.Add(1)
		defer active.Add(-1)
		close(started)
		<-ctx.Done()
		return savedoutbox.BatchStats{}, ctx.Err()
	}
}

func blockingOutboxCleanup(active *atomic.Int32, started chan struct{}) func(context.Context) (int64, error) {
	return func(ctx context.Context) (int64, error) {
		active.Add(1)
		defer active.Add(-1)
		close(started)
		<-ctx.Done()
		return 0, ctx.Err()
	}
}

func blockingMaintenance(active *atomic.Int32, started chan struct{}) func(context.Context) (savedmaintenance.Stats, error) {
	return func(ctx context.Context) (savedmaintenance.Stats, error) {
		active.Add(1)
		defer active.Add(-1)
		close(started)
		<-ctx.Done()
		return savedmaintenance.Stats{}, ctx.Err()
	}
}

func testConfig() Config {
	return Config{
		OutboxPollInterval:         4 * time.Millisecond,
		OutboxBusyInterval:         time.Millisecond,
		OutboxDispatchTimeout:      250 * time.Millisecond,
		OutboxCleanupInterval:      4 * time.Millisecond,
		OutboxCleanupTimeout:       250 * time.Millisecond,
		OutboxBackoffBase:          time.Millisecond,
		OutboxBackoffMax:           4 * time.Millisecond,
		MaintenanceInterval:        4 * time.Millisecond,
		MaintenanceBusyInterval:    time.Millisecond,
		MaintenanceRunTimeout:      250 * time.Millisecond,
		MaintenanceBackoffBase:     time.Millisecond,
		MaintenanceBackoffMax:      4 * time.Millisecond,
		ReconciliationInterval:     4 * time.Millisecond,
		ReconciliationBusyInterval: time.Millisecond,
		ReconciliationRunTimeout:   250 * time.Millisecond,
		ReconciliationBackoffBase:  time.Millisecond,
		ReconciliationBackoffMax:   4 * time.Millisecond,
	}
}

func mustCoordinator(
	t *testing.T,
	lifecycle LifecycleRunner,
	outbox OutboxDispatcher,
	maintenance MaintenanceRunner,
	observer Observer,
	config Config,
	reconciliationRunners ...ReconciliationRunner,
) *Coordinator {
	t.Helper()
	reconciliation := reconciliationRunnerFunc(func(context.Context) (savedreconciliation.Stats, error) {
		return savedreconciliation.Stats{}, nil
	})
	if len(reconciliationRunners) > 1 {
		t.Fatal("mustCoordinator accepts at most one reconciliation runner")
	}
	if len(reconciliationRunners) == 1 {
		if reconciliationRunners[0] == nil {
			t.Fatal("reconciliation runner must not be nil")
		}
	}
	var reconciliationRunner ReconciliationRunner = reconciliation
	if len(reconciliationRunners) == 1 {
		reconciliationRunner = reconciliationRunners[0]
	}
	coordinator, err := NewCoordinator(
		lifecycle,
		outbox,
		maintenance,
		reconciliationRunner,
		config,
		observer,
	)
	if err != nil {
		t.Fatalf("NewCoordinator() error = %v", err)
	}
	return coordinator
}

func waitSignal(t *testing.T, signal <-chan struct{}) {
	t.Helper()
	select {
	case <-signal:
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for worker signal")
	}
}

func waitCoordinator(t *testing.T, coordinator *Coordinator) error {
	t.Helper()
	result := make(chan error, 1)
	go func() { result <- coordinator.Wait() }()
	select {
	case err := <-result:
		return err
	case <-time.After(2 * time.Second):
		coordinator.Stop()
		t.Fatal("timed out waiting for coordinator shutdown")
		return nil
	}
}

func signalOnce(signal chan struct{}) {
	select {
	case <-signal:
	default:
		close(signal)
	}
}

func assertObservedError(t *testing.T, observations []Observation, task Task, want error) {
	t.Helper()
	for _, observation := range observations {
		if observation.Task == task && errors.Is(observation.Err, want) {
			return
		}
	}
	t.Fatalf("no %s observation wrapping %v: %#v", task, want, observations)
}

func assertObservedRetry(
	t *testing.T,
	observations []Observation,
	task Task,
	want error,
	wantDelay time.Duration,
) {
	t.Helper()
	for _, observation := range observations {
		if observation.Task == task && errors.Is(observation.Err, want) {
			if observation.ConsecutiveFailures != 1 || observation.NextDelay != wantDelay {
				t.Fatalf(
					"%s retry = (failures=%d, delay=%s), want (1, %s)",
					task,
					observation.ConsecutiveFailures,
					observation.NextDelay,
					wantDelay,
				)
			}
			return
		}
	}
	t.Fatalf("no %s retry observation wrapping %v: %#v", task, want, observations)
}

func assertObservedSuccess(t *testing.T, observations []Observation, task Task) {
	t.Helper()
	for _, observation := range observations {
		if observation.Task == task && observation.Err == nil {
			return
		}
	}
	t.Fatalf("no successful %s observation: %#v", task, observations)
}

func waitForObservedSuccess(t *testing.T, observer *recordingObserver, task Task) {
	t.Helper()
	timeout := time.NewTimer(2 * time.Second)
	defer timeout.Stop()
	ticker := time.NewTicker(time.Millisecond)
	defer ticker.Stop()
	for {
		for _, observation := range observer.snapshot() {
			if observation.Task == task && observation.Err == nil {
				return
			}
		}
		select {
		case <-ticker.C:
		case <-timeout.C:
			t.Fatalf("timed out waiting for successful %s observation", task)
		}
	}
}

type deadlineSample struct {
	present   bool
	remaining time.Duration
}

func sampleDeadline(ctx context.Context) deadlineSample {
	deadline, present := ctx.Deadline()
	return deadlineSample{present: present, remaining: time.Until(deadline)}
}

func recordDeadline(destination chan<- deadlineSample, sample deadlineSample) {
	select {
	case destination <- sample:
	default:
	}
}

func assertBoundedDeadline(t *testing.T, sample deadlineSample, maximum time.Duration) {
	t.Helper()
	if !sample.present {
		t.Fatal("task context has no deadline")
	}
	if sample.remaining <= 0 || sample.remaining > maximum {
		t.Fatalf("task deadline remaining = %s, want in (0,%s]", sample.remaining, maximum)
	}
}

type capturingDelayWaiter struct {
	delays chan time.Duration
}

func (waiter *capturingDelayWaiter) Wait(_ context.Context, delay time.Duration) bool {
	waiter.delays <- delay
	return false
}
