package metrics

import (
	"math"
	"sync"
	"time"

	natsadapter "kz/inflap/backend/services/saved-service/internal/adapter/nats"
	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	savedruntime "kz/inflap/backend/services/saved-service/internal/runtime"
)

var (
	runtimeDurationBuckets         = []float64{0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60}
	outboxDispatchDurationBuckets  = []float64{0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30}
	maintenanceDurationBuckets     = []float64{0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60}
	reconciliationDurationBuckets  = []float64{0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60, 90}
	lifecycleDeliveryAttemptBucket = []float64{1, 2, 3, 5, 8, 13, 20}
	httpDurationBuckets            = []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10}
)

const (
	unknownLabel = "UNKNOWN"
	globalLabel  = "GLOBAL"
)

type lifecycleKey struct {
	Source string
	Value  string
}

type runtimeResultKey struct {
	Task   string
	Result string
}

type httpKey struct {
	Route       string
	Method      string
	StatusClass string
}

type histogram struct {
	Count   uint64
	Sum     float64
	Buckets []uint64
}

func (value *histogram) observe(sample float64, bounds []float64) {
	if value == nil || sample < 0 || math.IsNaN(sample) || math.IsInf(sample, 0) {
		return
	}
	if len(value.Buckets) != len(bounds)+1 {
		value.Buckets = make([]uint64, len(bounds)+1)
	}
	value.Count = saturatingAdd(value.Count, 1)
	if sample > math.MaxFloat64-value.Sum {
		value.Sum = math.MaxFloat64
	} else {
		value.Sum += sample
	}
	for index, upperBound := range bounds {
		if sample <= upperBound {
			value.Buckets[index] = saturatingAdd(value.Buckets[index], 1)
		}
	}
	value.Buckets[len(bounds)] = saturatingAdd(value.Buckets[len(bounds)], 1)
}

func (value histogram) clone() histogram {
	value.Buckets = append([]uint64(nil), value.Buckets...)
	return value
}

// Metrics is a dependency-free, bounded-cardinality Saved telemetry registry.
// Its zero value is ready for use and all methods are safe for concurrent calls.
type Metrics struct {
	mu sync.RWMutex

	lifecycleOutcomes       map[lifecycleKey]uint64
	lifecycleActions        map[lifecycleKey]uint64
	lifecycleErrors         map[lifecycleKey]uint64
	lifecycleAttempts       map[lifecycleKey]*histogram
	lifecycleCleanupDeleted uint64

	runtimeRuns                map[runtimeResultKey]uint64
	runtimeDurations           map[string]*histogram
	runtimeConsecutiveFailures map[string]uint64
	runtimeNextDelaySeconds    map[string]float64
	runtimeLastRunSuccess      map[string]float64
	runtimeLastSuccess         map[string]float64
	runtimeLastError           map[string]float64

	outboxEvents           map[string]uint64
	outboxRecovery         map[string]uint64
	outboxCleanupDeleted   uint64
	outboxLikelyMore       float64
	outboxDispatchDuration histogram

	maintenanceRows     map[string]uint64
	maintenanceEvents   map[string]uint64
	maintenanceTicks    uint64
	maintenanceBacklog  map[string]float64
	maintenanceDuration histogram

	reconciliationTotals   map[string]uint64
	reconciliationBacklog  map[string]float64
	reconciliationDuration histogram

	httpRequests  map[httpKey]uint64
	httpErrors    map[httpKey]uint64
	httpDurations map[httpKey]*histogram

	searchFirstPages map[string]uint64
}

var _ savedruntime.Observer = (*Metrics)(nil)
var _ natsadapter.Observer = (*Metrics)(nil)

func New() *Metrics {
	metrics := &Metrics{}
	metrics.mu.Lock()
	metrics.initializeLocked()
	metrics.mu.Unlock()
	return metrics
}

func (metrics *Metrics) ObserveSavedSearch(zeroResults bool) {
	if metrics == nil {
		return
	}
	result := "matches"
	if zeroResults {
		result = "zero_results"
	}
	metrics.mu.Lock()
	defer metrics.mu.Unlock()
	metrics.initializeLocked()
	addMapCounter(metrics.searchFirstPages, result, 1)
}

func (metrics *Metrics) ObserveSavedLifecycle(observation natsadapter.Observation) {
	if metrics == nil {
		return
	}
	action := normalizeLifecycleAction(observation.Action)
	source := normalizeLifecycleSource(observation.Subject, action)
	outcome, hasOutcome := normalizeLifecycleOutcome(observation.Outcome)
	errorCode, hasError := normalizeLifecycleError(observation.ErrorCode)

	metrics.mu.Lock()
	defer metrics.mu.Unlock()
	metrics.initializeLocked()
	addMapCounter(metrics.lifecycleActions, lifecycleKey{Source: source, Value: action}, 1)
	if hasOutcome {
		addMapCounter(metrics.lifecycleOutcomes, lifecycleKey{Source: source, Value: outcome}, 1)
	}
	if hasError {
		addMapCounter(metrics.lifecycleErrors, lifecycleKey{Source: source, Value: errorCode}, 1)
	}
	if observation.DeliveryAttempt > 0 {
		observeHistogram(
			metrics.lifecycleAttempts,
			lifecycleKey{Source: source, Value: action},
			float64(observation.DeliveryAttempt),
			lifecycleDeliveryAttemptBucket,
		)
	}
	if action == string(natsadapter.ObservationCleanup) && observation.DeletedRows > 0 {
		metrics.lifecycleCleanupDeleted = saturatingAdd(
			metrics.lifecycleCleanupDeleted,
			uint64(observation.DeletedRows),
		)
	}
}

func (metrics *Metrics) ObserveSavedRuntime(observation savedruntime.Observation) {
	if metrics == nil {
		return
	}
	task := normalizeRuntimeTask(observation.Task)
	result := "success"
	if observation.Err != nil {
		result = "error"
	}
	durationSeconds, hasDuration := elapsedSeconds(observation.StartedAt, observation.FinishedAt)
	finishedAtSeconds, hasFinishedAt := timestampSeconds(observation.FinishedAt)
	consecutiveFailures := boundedNonNegativeInt(observation.ConsecutiveFailures)
	nextDelaySeconds := boundedDurationSeconds(observation.NextDelay)

	metrics.mu.Lock()
	defer metrics.mu.Unlock()
	metrics.initializeLocked()
	addMapCounter(metrics.runtimeRuns, runtimeResultKey{Task: task, Result: result}, 1)
	metrics.runtimeConsecutiveFailures[task] = consecutiveFailures
	metrics.runtimeNextDelaySeconds[task] = nextDelaySeconds
	if observation.Err == nil {
		metrics.runtimeLastRunSuccess[task] = 1
		if hasFinishedAt {
			metrics.runtimeLastSuccess[task] = max(metrics.runtimeLastSuccess[task], finishedAtSeconds)
		}
	} else {
		metrics.runtimeLastRunSuccess[task] = 0
		if hasFinishedAt {
			metrics.runtimeLastError[task] = max(metrics.runtimeLastError[task], finishedAtSeconds)
		}
	}
	if hasDuration {
		observeHistogram(metrics.runtimeDurations, task, durationSeconds, runtimeDurationBuckets)
	}

	switch task {
	case string(savedruntime.TaskOutboxDispatch):
		metrics.observeOutboxDispatchLocked(observation, durationSeconds, hasDuration)
	case string(savedruntime.TaskOutboxCleanup):
		if observation.OutboxDeleted > 0 {
			metrics.outboxCleanupDeleted = saturatingAdd(
				metrics.outboxCleanupDeleted,
				uint64(observation.OutboxDeleted),
			)
		}
	case string(savedruntime.TaskMaintenance):
		metrics.observeMaintenanceLocked(observation, durationSeconds, hasDuration)
	case string(savedruntime.TaskReconciliation):
		metrics.observeReconciliationLocked(observation, durationSeconds, hasDuration)
	}
}

func (metrics *Metrics) observeReconciliationLocked(
	observation savedruntime.Observation,
	fallbackDuration float64,
	hasFallbackDuration bool,
) {
	stats := observation.ReconciliationRun
	addPositiveInt(metrics.reconciliationTotals, "candidates_claimed", stats.CandidatesClaimed)
	addPositiveInt(metrics.reconciliationTotals, "public_applied", stats.PublicApplied)
	addPositiveInt(metrics.reconciliationTotals, "deny_applied", stats.DenyApplied)
	addPositiveInt(metrics.reconciliationTotals, "metadata_only_applied", stats.MetadataOnlyApplied)
	addPositiveInt(metrics.reconciliationTotals, "no_change", stats.NoChange)
	addPositiveInt(metrics.reconciliationTotals, "stale_ignored", stats.StaleIgnored)
	addPositiveInt(metrics.reconciliationTotals, "payloads_cleared", stats.PayloadsCleared)
	addPositiveInt(metrics.reconciliationTotals, "source_advanced", stats.SourceAdvanced)
	addPositiveInt(metrics.reconciliationTotals, "projection_advanced", stats.ProjectionAdvanced)
	addPositiveInt(metrics.reconciliationTotals, "visibility_advanced", stats.VisibilityAdvanced)
	addPositiveInt(metrics.reconciliationTotals, "not_found", stats.NotFound)
	addPositiveInt(metrics.reconciliationTotals, "unsupported_type", stats.UnsupportedType)
	addPositiveInt(metrics.reconciliationTotals, "resolution_failures", stats.ResolutionFailures)
	addPositiveInt(metrics.reconciliationTotals, "resolve_retries", stats.ResolveRetries)
	addPositiveInt(metrics.reconciliationTotals, "repository_retries", stats.RepositoryRetries)
	metrics.reconciliationBacklog["capped"] = boolGauge(stats.Capped)
	metrics.reconciliationBacklog["has_more"] = boolGauge(stats.HasMore)

	duration, ok := elapsedSeconds(stats.StartedAt, stats.FinishedAt)
	if !ok {
		duration, ok = fallbackDuration, hasFallbackDuration
	}
	if ok {
		metrics.reconciliationDuration.observe(duration, reconciliationDurationBuckets)
	}
}

func (metrics *Metrics) observeOutboxDispatchLocked(
	observation savedruntime.Observation,
	fallbackDuration float64,
	hasFallbackDuration bool,
) {
	stats := observation.OutboxBatch
	addPositiveInt(metrics.outboxEvents, "claimed", stats.Claimed)
	addPositiveInt(metrics.outboxEvents, "delivered", stats.Delivered)
	addPositiveInt(metrics.outboxEvents, "retry_scheduled", stats.RetryScheduled)
	addPositiveInt(metrics.outboxEvents, "dead", stats.Dead)
	addPositiveInt(metrics.outboxRecovery, "released", stats.LeasesRecovered)
	addPositiveInt(metrics.outboxRecovery, "dead", stats.RecoveryDead)
	metrics.outboxLikelyMore = boolGauge(stats.LikelyMore)

	duration, ok := elapsedSeconds(stats.StartedAt, stats.FinishedAt)
	if !ok {
		duration, ok = fallbackDuration, hasFallbackDuration
	}
	if ok {
		metrics.outboxDispatchDuration.observe(duration, outboxDispatchDurationBuckets)
	}
}

func (metrics *Metrics) observeMaintenanceLocked(
	observation savedruntime.Observation,
	fallbackDuration float64,
	hasFallbackDuration bool,
) {
	stats := observation.MaintenanceRun
	addPositiveInt64(metrics.maintenanceRows, "pending_operations_expired", stats.PendingOperationsExpired)
	addPositiveInt64(metrics.maintenanceRows, "terminal_operations_purged", stats.TerminalOperationsPurged)
	addPositiveInt64(metrics.maintenanceRows, "terminal_outbox_purged", stats.TerminalOutboxPurged)
	addPositiveInt64(metrics.maintenanceRows, "inbox_dedup_purged", stats.InboxDedupPurged)
	addPositiveInt64(metrics.maintenanceRows, "deleted_collection_children", stats.DeletedCollectionChildren)
	addPositiveInt64(metrics.maintenanceRows, "removed_collection_items_purged", stats.RemovedCollectionItemsPurged)
	addPositiveInt64(metrics.maintenanceRows, "deleted_collections_purged", stats.DeletedCollectionsPurged)
	addPositiveInt64(metrics.maintenanceRows, "removed_saved_items_purged", stats.RemovedSavedItemsPurged)
	addPositiveInt64(metrics.maintenanceRows, "projection_candidates_marked", stats.ProjectionCandidatesMarked)
	addPositiveInt64(metrics.maintenanceRows, "ephemeral_projections_purged", stats.EphemeralProjectionsPurged)
	addPositiveInt64(metrics.maintenanceRows, "standard_projections_purged", stats.StandardProjectionsPurged)
	addPositiveInt64(metrics.maintenanceRows, "subject_purge_rows_purged", stats.SubjectPurgeRowsPurged)
	addPositiveInt64(metrics.maintenanceRows, "completed_subject_purges_purged", stats.CompletedSubjectPurgesPurged)
	addPositiveInt(metrics.maintenanceEvents, "subject_purge_phases_advanced", stats.SubjectPurgePhasesAdvanced)
	addPositiveInt(metrics.maintenanceEvents, "subject_purges_completed", stats.SubjectPurgesCompleted)
	if stats.Ticks > 0 {
		metrics.maintenanceTicks = saturatingAdd(metrics.maintenanceTicks, uint64(stats.Ticks))
	}
	metrics.maintenanceBacklog["capped"] = boolGauge(stats.Capped)
	metrics.maintenanceBacklog["has_more"] = boolGauge(stats.HasMore)

	duration, ok := elapsedSeconds(stats.StartedAt, stats.FinishedAt)
	if !ok {
		duration, ok = fallbackDuration, hasFallbackDuration
	}
	if ok {
		metrics.maintenanceDuration.observe(duration, maintenanceDurationBuckets)
	}
}

func (metrics *Metrics) initializeLocked() {
	if metrics.lifecycleOutcomes == nil {
		metrics.lifecycleOutcomes = make(map[lifecycleKey]uint64)
		metrics.lifecycleActions = make(map[lifecycleKey]uint64)
		metrics.lifecycleErrors = make(map[lifecycleKey]uint64)
		metrics.lifecycleAttempts = make(map[lifecycleKey]*histogram)
		metrics.runtimeRuns = make(map[runtimeResultKey]uint64)
		metrics.runtimeDurations = make(map[string]*histogram)
		metrics.runtimeConsecutiveFailures = make(map[string]uint64)
		metrics.runtimeNextDelaySeconds = make(map[string]float64)
		metrics.runtimeLastRunSuccess = make(map[string]float64)
		metrics.runtimeLastSuccess = make(map[string]float64)
		metrics.runtimeLastError = make(map[string]float64)
		metrics.outboxEvents = make(map[string]uint64)
		metrics.outboxRecovery = make(map[string]uint64)
		metrics.maintenanceRows = make(map[string]uint64)
		metrics.maintenanceEvents = make(map[string]uint64)
		metrics.maintenanceBacklog = make(map[string]float64)
		metrics.reconciliationTotals = make(map[string]uint64)
		metrics.reconciliationBacklog = make(map[string]float64)
		metrics.httpRequests = make(map[httpKey]uint64)
		metrics.httpErrors = make(map[httpKey]uint64)
		metrics.httpDurations = make(map[httpKey]*histogram)
		metrics.searchFirstPages = make(map[string]uint64)
	}
}

func normalizeLifecycleSource(subject, action string) string {
	switch subject {
	case savedlifecycle.ActivitySubjectV1:
		return "ACTIVITY"
	case savedlifecycle.AttractionSubjectV1:
		return "ATTRACTION"
	case savedlifecycle.GuideSubjectV1:
		return "GUIDE"
	case "":
		if action == string(natsadapter.ObservationCleanup) ||
			action == string(natsadapter.ObservationCleanupFailed) {
			return globalLabel
		}
	}
	return unknownLabel
}

func normalizeLifecycleAction(action natsadapter.ObservationAction) string {
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
		return unknownLabel
	}
}

func normalizeLifecycleOutcome(outcome savedlifecycle.OutcomeCode) (string, bool) {
	if outcome == "" {
		return "", false
	}
	switch outcome {
	case savedlifecycle.OutcomeApplied,
		savedlifecycle.OutcomeAppliedSourceOnly,
		savedlifecycle.OutcomeIgnoredUnknownTarget,
		savedlifecycle.OutcomeIgnoredStaleRevision,
		savedlifecycle.OutcomeIgnoredPublicPayloadAbsent,
		savedlifecycle.OutcomeDuplicate:
		return string(outcome), true
	default:
		return unknownLabel, true
	}
}

func normalizeLifecycleError(code savedlifecycle.ErrorCode) (string, bool) {
	if code == "" {
		return "", false
	}
	switch code {
	case savedlifecycle.ErrorCodeInvalidSubject,
		savedlifecycle.ErrorCodeMalformedProtobuf,
		savedlifecycle.ErrorCodeUnknownContractField,
		savedlifecycle.ErrorCodeInvalidEventID,
		savedlifecycle.ErrorCodeInvalidTarget,
		savedlifecycle.ErrorCodeInvalidRevision,
		savedlifecycle.ErrorCodeRevisionConflict,
		savedlifecycle.ErrorCodeInvalidTimestamp,
		savedlifecycle.ErrorCodeInvalidKindVisibility,
		savedlifecycle.ErrorCodeInvalidPublicProjection,
		savedlifecycle.ErrorCodePayloadForbidden,
		savedlifecycle.ErrorCodeEventIdentityConflict,
		savedlifecycle.ErrorCodeProjectionSourceConflict,
		savedlifecycle.ErrorCodePersistenceInvariant,
		savedlifecycle.ErrorCodeRepositoryUnavailable,
		savedlifecycle.ErrorCodeProcessingTimeout,
		savedlifecycle.ErrorCodeCanceled,
		savedlifecycle.ErrorCodeUnknown:
		return string(code), true
	default:
		return unknownLabel, true
	}
}

func normalizeRuntimeTask(task savedruntime.Task) string {
	switch task {
	case savedruntime.TaskLifecycle,
		savedruntime.TaskOutboxDispatch,
		savedruntime.TaskOutboxCleanup,
		savedruntime.TaskMaintenance,
		savedruntime.TaskReconciliation:
		return string(task)
	default:
		return unknownLabel
	}
}

func elapsedSeconds(startedAt, finishedAt time.Time) (float64, bool) {
	if startedAt.IsZero() || finishedAt.IsZero() || finishedAt.Before(startedAt) {
		return 0, false
	}
	seconds := finishedAt.Sub(startedAt).Seconds()
	if seconds < 0 || math.IsNaN(seconds) || math.IsInf(seconds, 0) {
		return 0, false
	}
	return seconds, true
}

func timestampSeconds(value time.Time) (float64, bool) {
	if value.IsZero() || value.Unix() < 0 {
		return 0, false
	}
	seconds := float64(value.Unix()) + float64(value.Nanosecond())/float64(time.Second)
	if math.IsNaN(seconds) || math.IsInf(seconds, 0) {
		return 0, false
	}
	return seconds, true
}

func boundedNonNegativeInt(value int) uint64 {
	const maximum = 1_000_000
	if value <= 0 {
		return 0
	}
	if value > maximum {
		return maximum
	}
	return uint64(value)
}

func boundedDurationSeconds(value time.Duration) float64 {
	if value <= 0 {
		return 0
	}
	return value.Seconds()
}

func boolGauge(value bool) float64 {
	if value {
		return 1
	}
	return 0
}

func addPositiveInt(values map[string]uint64, key string, value int) {
	if value > 0 {
		addMapCounter(values, key, uint64(value))
	}
}

func addPositiveInt64(values map[string]uint64, key string, value int64) {
	if value > 0 {
		addMapCounter(values, key, uint64(value))
	}
}

func addMapCounter[Key comparable](values map[Key]uint64, key Key, delta uint64) {
	values[key] = saturatingAdd(values[key], delta)
}

func saturatingAdd(current, delta uint64) uint64 {
	if math.MaxUint64-current < delta {
		return math.MaxUint64
	}
	return current + delta
}

func observeHistogram[Key comparable](
	values map[Key]*histogram,
	key Key,
	sample float64,
	bounds []float64,
) {
	value := values[key]
	if value == nil {
		value = &histogram{}
		values[key] = value
	}
	value.observe(sample, bounds)
}
