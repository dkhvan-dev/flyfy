package main

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	gonats "github.com/nats-io/nats.go"

	natsadapter "kz/inflap/backend/services/saved-service/internal/adapter/nats"
	repositoryadapter "kz/inflap/backend/services/saved-service/internal/adapter/repository"
	"kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	"kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
	"kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	"kz/inflap/backend/services/saved-service/internal/app/savedreconciliation"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/config"
	savedruntime "kz/inflap/backend/services/saved-service/internal/runtime"
)

type savedBackgroundRuntime struct {
	connection  savedBackgroundConnection
	coordinator savedBackgroundCoordinator
	maintenance *savedmaintenance.Runner

	mu           sync.RWMutex
	state        savedBackgroundLifecycleState
	done         chan struct{}
	doneOnce     sync.Once
	shutdownDone chan struct{}
	shutdownOnce sync.Once
	err          error
	shutdownErr  error
}

type savedBackgroundConnection interface {
	IsConnected() bool
	IsClosed() bool
	Drain() error
	Close()
}

type savedBackgroundCoordinator interface {
	Start(context.Context) error
	Stop()
	Wait() error
}

type savedBackgroundLifecycleState uint8

const savedBackgroundDrainPollInterval = 5 * time.Millisecond

const (
	savedBackgroundStateNew savedBackgroundLifecycleState = iota
	savedBackgroundStateStarting
	savedBackgroundStateRunning
	savedBackgroundStateStopping
	savedBackgroundStateStopped
)

func newSavedBackgroundRuntime(
	ctx context.Context,
	cfg *config.Config,
	pool *pgxpool.Pool,
	sourceResolver appsource.Resolver,
	runtimeObserver savedruntime.Observer,
	lifecycleObserver natsadapter.Observer,
) (*savedBackgroundRuntime, error) {
	if ctx == nil || cfg == nil || pool == nil || sourceResolver == nil {
		return nil, errors.New("Saved background runtime dependencies are incomplete")
	}
	options, err := cfg.NATSConnectionOptions()
	if err != nil {
		return nil, fmt.Errorf("configure NATS connection: %w", err)
	}
	options = append(options, gonats.DrainTimeout(cfg.HTTP.ShutdownTimeout))
	connection, err := gonats.Connect(cfg.NATS.URL, options...)
	if err != nil {
		return nil, fmt.Errorf("connect Saved NATS transport: %w", err)
	}
	closeOnError := true
	defer func() {
		if closeOnError {
			connection.Close()
		}
	}()

	lifecycleRepository, err := repositoryadapter.NewPGSavedLifecycleRepository(pool)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved lifecycle repository: %w", err)
	}
	lifecycleService, err := savedlifecycle.NewService(lifecycleRepository)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved lifecycle service: %w", err)
	}
	lifecycleConsumer, err := natsadapter.NewSavedLifecycleConsumer(
		connection,
		lifecycleService,
		natsadapter.DefaultConsumerConfig(),
		lifecycleObserver,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved lifecycle consumer: %w", err)
	}

	outboxRepository, err := repositoryadapter.NewPGSavedOutboxRepository(pool)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved outbox repository: %w", err)
	}
	outboxPublisher, err := natsadapter.NewSavedOutboxPublisher(connection, cfg.NATS.StreamReplicas)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved outbox publisher: %w", err)
	}
	provisionCtx, cancelProvision := context.WithTimeout(ctx, 5*time.Second)
	err = outboxPublisher.EnsureStream(provisionCtx)
	cancelProvision()
	if err != nil {
		return nil, fmt.Errorf("provision Saved domain stream: %w", err)
	}
	outboxDispatcher, err := savedoutbox.NewDispatcher(
		outboxRepository,
		outboxPublisher,
		savedoutbox.DefaultConfig(),
		savedoutbox.SystemClock{},
	)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved outbox dispatcher: %w", err)
	}

	maintenanceRepository, err := repositoryadapter.NewPGSavedMaintenanceRepository(pool)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved maintenance repository: %w", err)
	}
	maintenanceRunner, err := savedmaintenance.NewDefaultRunner(maintenanceRepository)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved maintenance runner: %w", err)
	}
	reconciliationRepository, err := repositoryadapter.NewPGSavedReconciliationRepository(pool)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved reconciliation repository: %w", err)
	}
	reconciliationRunner, err := savedreconciliation.NewDefaultRunner(
		reconciliationRepository,
		sourceResolver,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved reconciliation runner: %w", err)
	}
	coordinator, err := savedruntime.NewCoordinator(
		lifecycleConsumer,
		outboxDispatcher,
		maintenanceRunner,
		reconciliationRunner,
		savedruntime.DefaultConfig(),
		runtimeObserver,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved background coordinator: %w", err)
	}

	closeOnError = false
	return &savedBackgroundRuntime{
		connection:   connection,
		coordinator:  coordinator,
		maintenance:  maintenanceRunner,
		done:         make(chan struct{}),
		shutdownDone: make(chan struct{}),
	}, nil
}

func (runtime *savedBackgroundRuntime) Start(ctx context.Context) error {
	if runtime == nil || runtime.connection == nil || runtime.coordinator == nil ||
		runtime.maintenance == nil || ctx == nil {
		return errors.New("Saved background runtime is unavailable")
	}
	runtime.mu.Lock()
	if runtime.state != savedBackgroundStateNew {
		runtime.mu.Unlock()
		return savedruntime.ErrAlreadyStarted
	}
	runtime.ensureLifecycleChannelsLocked()
	runtime.state = savedBackgroundStateStarting
	if err := runtime.coordinator.Start(ctx); err != nil {
		runtime.state = savedBackgroundStateNew
		runtime.mu.Unlock()
		return err
	}
	runtime.state = savedBackgroundStateRunning
	go runtime.awaitCoordinator()
	runtime.mu.Unlock()
	return nil
}

func (runtime *savedBackgroundRuntime) awaitCoordinator() {
	err := runtime.coordinator.Wait()
	runtime.mu.Lock()
	runtime.err = err
	runtime.doneOnce.Do(func() { close(runtime.done) })
	runtime.mu.Unlock()
}

func (runtime *savedBackgroundRuntime) Done() <-chan struct{} {
	if runtime == nil {
		closed := make(chan struct{})
		close(closed)
		return closed
	}
	runtime.mu.RLock()
	done := runtime.done
	runtime.mu.RUnlock()
	if done != nil {
		return done
	}
	closed := make(chan struct{})
	close(closed)
	return closed
}

func (runtime *savedBackgroundRuntime) Err() error {
	if runtime == nil {
		return errors.New("Saved background runtime is unavailable")
	}
	runtime.mu.RLock()
	defer runtime.mu.RUnlock()
	return runtime.err
}

func (runtime *savedBackgroundRuntime) Check(ctx context.Context) error {
	if ctx == nil {
		return errors.New("Saved readiness context is unavailable")
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	if runtime == nil || runtime.connection == nil || runtime.coordinator == nil {
		return errors.New("Saved background runtime is unavailable")
	}
	if !runtime.connection.IsConnected() {
		return errors.New("Saved NATS transport is not connected")
	}
	runtime.mu.RLock()
	state := runtime.state
	err := runtime.err
	runtime.mu.RUnlock()
	if state != savedBackgroundStateRunning {
		return errors.New("Saved background runtime is not started")
	}
	select {
	case <-runtime.done:
		if err != nil {
			return err
		}
		return errors.New("Saved background runtime stopped")
	default:
		return nil
	}
}

func (runtime *savedBackgroundRuntime) Shutdown(ctx context.Context) error {
	if runtime == nil {
		return nil
	}
	if ctx == nil {
		return errors.New("Saved shutdown context is unavailable")
	}
	runtime.mu.Lock()
	runtime.ensureLifecycleChannelsLocked()
	shutdownDone := runtime.shutdownDone
	owner := false
	started := false
	switch runtime.state {
	case savedBackgroundStateNew:
		runtime.state = savedBackgroundStateStopping
		runtime.doneOnce.Do(func() { close(runtime.done) })
		owner = true
	case savedBackgroundStateRunning:
		runtime.state = savedBackgroundStateStopping
		owner = true
		started = true
	case savedBackgroundStateStarting:
		runtime.mu.Unlock()
		return errors.New("Saved background runtime start transition is incomplete")
	case savedBackgroundStateStopping:
	case savedBackgroundStateStopped:
		err := runtime.shutdownErr
		runtime.mu.Unlock()
		return err
	}
	runtime.mu.Unlock()

	if !owner {
		select {
		case <-shutdownDone:
			runtime.mu.RLock()
			err := runtime.shutdownErr
			runtime.mu.RUnlock()
			return err
		case <-ctx.Done():
			return ctx.Err()
		}
	}
	if started && runtime.coordinator != nil {
		runtime.coordinator.Stop()
	}
	if started {
		select {
		case <-runtime.done:
		case <-ctx.Done():
			if runtime.connection != nil {
				runtime.connection.Close()
			}
			return runtime.finishShutdown(ctx.Err())
		}
	}
	if runtime.connection == nil || runtime.connection.IsClosed() {
		return runtime.finishShutdown(nil)
	}
	if err := runtime.connection.Drain(); err != nil {
		runtime.connection.Close()
		return runtime.finishShutdown(fmt.Errorf("drain Saved NATS transport: %w", err))
	}
	if err := waitForSavedBackgroundConnectionClose(ctx, runtime.connection); err != nil {
		runtime.connection.Close()
		return runtime.finishShutdown(err)
	}
	return runtime.finishShutdown(nil)
}

func waitForSavedBackgroundConnectionClose(
	ctx context.Context,
	connection savedBackgroundConnection,
) error {
	if connection.IsClosed() {
		return nil
	}
	ticker := time.NewTicker(savedBackgroundDrainPollInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			if connection.IsClosed() {
				return nil
			}
		}
	}
}

func (runtime *savedBackgroundRuntime) finishShutdown(err error) error {
	runtime.mu.Lock()
	runtime.shutdownErr = err
	runtime.state = savedBackgroundStateStopped
	runtime.shutdownOnce.Do(func() { close(runtime.shutdownDone) })
	runtime.mu.Unlock()
	return err
}

func (runtime *savedBackgroundRuntime) ensureLifecycleChannelsLocked() {
	if runtime.done == nil {
		runtime.done = make(chan struct{})
	}
	if runtime.shutdownDone == nil {
		runtime.shutdownDone = make(chan struct{})
	}
}

type compositeReadiness struct {
	checkers []readinessChecker
}

func (readiness compositeReadiness) Check(ctx context.Context) error {
	if ctx == nil || len(readiness.checkers) == 0 {
		return errors.New("Saved readiness dependencies are unavailable")
	}
	for _, checker := range readiness.checkers {
		if err := ctx.Err(); err != nil {
			return err
		}
		if checker == nil {
			return errors.New("Saved readiness checker is unavailable")
		}
		if err := checker.Check(ctx); err != nil {
			return err
		}
	}
	return nil
}
