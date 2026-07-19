package savedruntime

import (
	"time"

	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
	savedoutbox "kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	savedreconciliation "kz/inflap/backend/services/saved-service/internal/app/savedreconciliation"
)

type Task string

const (
	TaskLifecycle      Task = "LIFECYCLE"
	TaskOutboxDispatch Task = "OUTBOX_DISPATCH"
	TaskOutboxCleanup  Task = "OUTBOX_CLEANUP"
	TaskMaintenance    Task = "MAINTENANCE"
	TaskReconciliation Task = "RECONCILIATION"
)

// Observation contains bounded, non-user-identifying runtime telemetry.
// Observer implementations may be called concurrently and must return quickly.
type Observation struct {
	Task                Task
	StartedAt           time.Time
	FinishedAt          time.Time
	ConsecutiveFailures int
	NextDelay           time.Duration
	Err                 error

	OutboxBatch       savedoutbox.BatchStats
	OutboxDeleted     int64
	MaintenanceRun    savedmaintenance.Stats
	ReconciliationRun savedreconciliation.Stats
}

type Observer interface {
	ObserveSavedRuntime(Observation)
}

type ObserverFunc func(Observation)

func (function ObserverFunc) ObserveSavedRuntime(observation Observation) {
	if function != nil {
		function(observation)
	}
}

type noopObserver struct{}

func (noopObserver) ObserveSavedRuntime(Observation) {}
