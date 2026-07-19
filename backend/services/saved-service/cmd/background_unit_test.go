package main

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
	savedruntime "kz/inflap/backend/services/saved-service/internal/runtime"
)

func TestSavedBackgroundRuntimeRejectsMissingContexts(t *testing.T) {
	t.Parallel()

	runtime := &savedBackgroundRuntime{}
	if err := runtime.Check(nil); err == nil {
		t.Fatal("Check(nil) error = nil")
	}
	if err := runtime.Shutdown(nil); err == nil {
		t.Fatal("Shutdown(nil) error = nil")
	}
}

func TestSavedBackgroundRuntimeStartShutdownRaceHasSingleTerminalState(t *testing.T) {
	t.Parallel()

	coordinator := &blockingBackgroundCoordinator{
		startEntered: make(chan struct{}),
		releaseStart: make(chan struct{}),
		stopped:      make(chan struct{}),
	}
	drainStarted := make(chan struct{})
	drainRelease := make(chan struct{})
	connection := &backgroundConnectionStub{
		connected:    true,
		drainStarted: drainStarted,
		drainRelease: drainRelease,
	}
	runtime := &savedBackgroundRuntime{
		connection:   connection,
		coordinator:  coordinator,
		maintenance:  &savedmaintenance.Runner{},
		done:         make(chan struct{}),
		shutdownDone: make(chan struct{}),
	}

	startResult := make(chan error, 1)
	go func() { startResult <- runtime.Start(context.Background()) }()
	select {
	case <-coordinator.startEntered:
	case <-time.After(time.Second):
		t.Fatal("Start() did not enter coordinator")
	}
	if runtime.mu.TryLock() {
		runtime.mu.Unlock()
		t.Fatal("runtime lifecycle lock was not held during start transition")
	}

	shutdownAttempted := make(chan struct{})
	shutdownResult := make(chan error, 1)
	shutdownCtx, cancelShutdown := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancelShutdown()
	go func() {
		close(shutdownAttempted)
		shutdownResult <- runtime.Shutdown(shutdownCtx)
	}()
	<-shutdownAttempted
	close(coordinator.releaseStart)

	if err := <-startResult; err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	select {
	case <-drainStarted:
	case <-time.After(time.Second):
		t.Fatal("Shutdown() did not start NATS drain")
	}
	select {
	case err := <-shutdownResult:
		t.Fatalf("Shutdown() returned before async drain closed: %v", err)
	default:
	}
	close(drainRelease)
	if err := <-shutdownResult; err != nil {
		t.Fatalf("Shutdown() error = %v", err)
	}
	if coordinator.stopCalls.Load() != 1 || connection.drainCalls.Load() != 1 {
		t.Fatalf(
			"stop calls = %d, drain calls = %d, want 1 each",
			coordinator.stopCalls.Load(),
			connection.drainCalls.Load(),
		)
	}
	runtime.mu.RLock()
	state := runtime.state
	runtime.mu.RUnlock()
	if state != savedBackgroundStateStopped {
		t.Fatalf("runtime state = %d, want stopped", state)
	}
	if err := runtime.Start(context.Background()); !errors.Is(err, savedruntime.ErrAlreadyStarted) {
		t.Fatalf("Start() after Shutdown error = %v, want ErrAlreadyStarted", err)
	}
}

func TestSavedBackgroundRuntimeShutdownDeadlineForcesNATSClose(t *testing.T) {
	t.Parallel()

	drainStarted := make(chan struct{})
	drainRelease := make(chan struct{})
	connection := &backgroundConnectionStub{
		connected:    true,
		drainStarted: drainStarted,
		drainRelease: drainRelease,
	}
	runtime := &savedBackgroundRuntime{
		connection:   connection,
		coordinator:  &failingBackgroundCoordinator{},
		maintenance:  &savedmaintenance.Runner{},
		done:         make(chan struct{}),
		shutdownDone: make(chan struct{}),
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Millisecond)
	defer cancel()
	err := runtime.Shutdown(ctx)
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("Shutdown() error = %v, want deadline exceeded", err)
	}
	if connection.drainCalls.Load() != 1 || connection.closeCalls.Load() != 1 ||
		!connection.IsClosed() {
		t.Fatalf(
			"drain calls = %d, close calls = %d, closed = %t",
			connection.drainCalls.Load(),
			connection.closeCalls.Load(),
			connection.IsClosed(),
		)
	}
	close(drainRelease)
}

func TestSavedBackgroundRuntimeStartupFailureCanDrainOnShutdown(t *testing.T) {
	t.Parallel()

	startErr := errors.New("subscription startup failed")
	drainRelease := make(chan struct{})
	connection := &backgroundConnectionStub{
		connected:    true,
		drainStarted: make(chan struct{}),
		drainRelease: drainRelease,
	}
	coordinator := &failingBackgroundCoordinator{startErr: startErr}
	runtime := &savedBackgroundRuntime{
		connection:   connection,
		coordinator:  coordinator,
		maintenance:  &savedmaintenance.Runner{},
		done:         make(chan struct{}),
		shutdownDone: make(chan struct{}),
	}
	if err := runtime.Start(context.Background()); !errors.Is(err, startErr) {
		t.Fatalf("Start() error = %v, want %v", err, startErr)
	}
	shutdownResult := make(chan error, 1)
	go func() { shutdownResult <- runtime.Shutdown(context.Background()) }()
	select {
	case <-connection.drainStarted:
	case <-time.After(time.Second):
		t.Fatal("startup-failure Shutdown() did not drain NATS")
	}
	close(drainRelease)
	if err := <-shutdownResult; err != nil {
		t.Fatalf("Shutdown() error = %v", err)
	}
	if connection.drainCalls.Load() != 1 || connection.closeCalls.Load() != 0 {
		t.Fatalf(
			"drain calls = %d, close calls = %d",
			connection.drainCalls.Load(),
			connection.closeCalls.Load(),
		)
	}
}

func TestCompositeReadinessStopsOnCancelledContext(t *testing.T) {
	t.Parallel()

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	called := false
	readiness := compositeReadiness{checkers: []readinessChecker{
		readinessCheckerFunc(func(context.Context) error {
			called = true
			return nil
		}),
	}}

	err := readiness.Check(ctx)
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("Check() error = %v, want context.Canceled", err)
	}
	if called {
		t.Fatal("readiness dependency called after context cancellation")
	}
}

type readinessCheckerFunc func(context.Context) error

func (function readinessCheckerFunc) Check(ctx context.Context) error {
	return function(ctx)
}

type blockingBackgroundCoordinator struct {
	startEntered chan struct{}
	releaseStart chan struct{}
	stopped      chan struct{}
	stopOnce     sync.Once
	stopCalls    atomic.Int32
}

type failingBackgroundCoordinator struct {
	startErr error
}

func (coordinator *failingBackgroundCoordinator) Start(context.Context) error {
	return coordinator.startErr
}

func (*failingBackgroundCoordinator) Stop() {}

func (*failingBackgroundCoordinator) Wait() error { return nil }

func (coordinator *blockingBackgroundCoordinator) Start(context.Context) error {
	close(coordinator.startEntered)
	<-coordinator.releaseStart
	return nil
}

func (coordinator *blockingBackgroundCoordinator) Stop() {
	coordinator.stopCalls.Add(1)
	coordinator.stopOnce.Do(func() { close(coordinator.stopped) })
}

func (coordinator *blockingBackgroundCoordinator) Wait() error {
	<-coordinator.stopped
	return nil
}

type backgroundConnectionStub struct {
	connected    bool
	drainStarted chan struct{}
	drainRelease <-chan struct{}
	drainOnce    sync.Once
	closed       atomic.Bool
	drainCalls   atomic.Int32
	closeCalls   atomic.Int32
}

func (connection *backgroundConnectionStub) IsConnected() bool {
	return connection.connected && !connection.closed.Load()
}

func (connection *backgroundConnectionStub) IsClosed() bool {
	return connection.closed.Load()
}

func (connection *backgroundConnectionStub) Drain() error {
	connection.drainCalls.Add(1)
	connection.drainOnce.Do(func() {
		if connection.drainStarted != nil {
			close(connection.drainStarted)
		}
		if connection.drainRelease == nil {
			connection.closed.Store(true)
			return
		}
		go func() {
			<-connection.drainRelease
			connection.closed.Store(true)
		}()
	})
	return nil
}

func (connection *backgroundConnectionStub) Close() {
	connection.closeCalls.Add(1)
	connection.closed.Store(true)
}
