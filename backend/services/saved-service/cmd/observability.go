package main

import (
	"time"

	"github.com/rs/zerolog/log"

	metricsadapter "kz/inflap/backend/services/saved-service/internal/adapter/metrics"
	natsadapter "kz/inflap/backend/services/saved-service/internal/adapter/nats"
	"kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	savedruntime "kz/inflap/backend/services/saved-service/internal/runtime"
)

type productionRuntimeObserver struct {
	metrics *metricsadapter.Metrics
}

func (observer productionRuntimeObserver) ObserveSavedRuntime(observation savedruntime.Observation) {
	if observer.metrics != nil {
		observer.metrics.ObserveSavedRuntime(observation)
	}
	if observation.Err == nil {
		return
	}
	log.Error().
		Str("task", boundedRuntimeTask(observation.Task)).
		Int("consecutive_failures", max(observation.ConsecutiveFailures, 0)).
		Dur("next_retry_in", max(observation.NextDelay, time.Duration(0))).
		Msg("Saved background task failed")
}

type productionLifecycleObserver struct {
	metrics *metricsadapter.Metrics
}

type productionHTTPObserver struct{}

func (productionHTTPObserver) ObserveSavedHTTP(observation metricsadapter.HTTPObservation) {
	event := log.Info()
	if observation.Status >= 500 {
		event = log.Error()
	} else if observation.Status >= 400 {
		event = log.Warn()
	}
	event.
		Str("route", observation.Route).
		Str("method", observation.Method).
		Int("status", observation.Status).
		Str("status_class", observation.StatusClass).
		Dur("duration", max(observation.Duration, time.Duration(0)))
	if observation.RequestID != "" {
		event = event.Str("request_id", observation.RequestID)
	}
	if observation.OperationID != "" {
		event = event.Str("operation_id", observation.OperationID)
	}
	event.Msg("Saved HTTP request completed")
}

func (observer productionLifecycleObserver) ObserveSavedLifecycle(
	observation natsadapter.Observation,
) {
	if observer.metrics != nil {
		observer.metrics.ObserveSavedLifecycle(observation)
	}
	if observation.Action == natsadapter.ObservationAck ||
		observation.Action == natsadapter.ObservationCleanup {
		return
	}
	log.Warn().
		Str("source", boundedLifecycleSource(observation.Subject)).
		Str("action", boundedLifecycleAction(observation.Action)).
		Str("outcome", string(observation.Outcome)).
		Str("error_code", string(observation.ErrorCode)).
		Uint64("delivery_attempt", observation.DeliveryAttempt).
		Msg("Saved lifecycle delivery required recovery")
}

func boundedRuntimeTask(task savedruntime.Task) string {
	switch task {
	case savedruntime.TaskLifecycle,
		savedruntime.TaskOutboxDispatch,
		savedruntime.TaskOutboxCleanup,
		savedruntime.TaskMaintenance,
		savedruntime.TaskReconciliation:
		return string(task)
	default:
		return "UNKNOWN"
	}
}

func boundedLifecycleSource(subject string) string {
	switch subject {
	case savedlifecycle.ActivitySubjectV1:
		return "ACTIVITY"
	case savedlifecycle.AttractionSubjectV1:
		return "ATTRACTION"
	case savedlifecycle.GuideSubjectV1:
		return "GUIDE"
	default:
		return "UNKNOWN"
	}
}

func boundedLifecycleAction(action natsadapter.ObservationAction) string {
	switch action {
	case natsadapter.ObservationAck,
		natsadapter.ObservationAckFailed,
		natsadapter.ObservationRetry,
		natsadapter.ObservationRetryFailed,
		natsadapter.ObservationDLQTerminated,
		natsadapter.ObservationDLQRetry,
		natsadapter.ObservationIteratorRetry,
		natsadapter.ObservationCleanup,
		natsadapter.ObservationCleanupFailed:
		return string(action)
	default:
		return "UNKNOWN"
	}
}
