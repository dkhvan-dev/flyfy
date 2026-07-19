package metrics

import (
	"fmt"
	"math"
	"net/http"
	"sort"
	"strconv"
	"strings"
)

var (
	runtimeTaskOrder = []string{
		"LIFECYCLE",
		"OUTBOX_DISPATCH",
		"OUTBOX_CLEANUP",
		"MAINTENANCE",
		"RECONCILIATION",
	}
	outboxEventOrder    = []string{"claimed", "delivered", "retry_scheduled", "dead"}
	outboxRecoveryOrder = []string{"released", "dead"}
	maintenanceRowOrder = []string{
		"pending_operations_expired",
		"terminal_operations_purged",
		"terminal_outbox_purged",
		"inbox_dedup_purged",
		"deleted_collection_children",
		"removed_collection_items_purged",
		"deleted_collections_purged",
		"removed_saved_items_purged",
		"projection_candidates_marked",
		"ephemeral_projections_purged",
		"standard_projections_purged",
		"subject_purge_rows_purged",
		"completed_subject_purges_purged",
	}
	maintenanceEventOrder = []string{
		"subject_purge_phases_advanced",
		"subject_purges_completed",
	}
	reconciliationResultOrder = []string{
		"candidates_claimed",
		"public_applied",
		"deny_applied",
		"metadata_only_applied",
		"no_change",
		"stale_ignored",
		"payloads_cleared",
		"source_advanced",
		"projection_advanced",
		"visibility_advanced",
		"not_found",
		"unsupported_type",
		"resolution_failures",
		"resolve_retries",
		"repository_retries",
	}
)

type metricsSnapshot struct {
	lifecycleOutcomes       map[lifecycleKey]uint64
	lifecycleActions        map[lifecycleKey]uint64
	lifecycleErrors         map[lifecycleKey]uint64
	lifecycleAttempts       map[lifecycleKey]histogram
	lifecycleCleanupDeleted uint64

	runtimeRuns                map[runtimeResultKey]uint64
	runtimeDurations           map[string]histogram
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
	httpDurations map[httpKey]histogram

	searchFirstPages map[string]uint64
}

type histogramSeries struct {
	labels []metricLabel
	value  histogram
}

type metricLabel struct {
	name  string
	value string
}

func (metrics *Metrics) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if request != nil && request.Method != http.MethodGet && request.Method != http.MethodHead {
		writer.Header().Set("Allow", "GET, HEAD")
		http.Error(writer, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	body := metrics.render()
	writer.Header().Set("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
	writer.Header().Set("Cache-Control", "no-store")
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	writer.Header().Set("Content-Length", strconv.Itoa(len(body)))
	writer.WriteHeader(http.StatusOK)
	if request == nil || request.Method != http.MethodHead {
		_, _ = writer.Write([]byte(body))
	}
}

func (metrics *Metrics) render() string {
	snapshot := metrics.snapshot()
	var builder strings.Builder
	builder.Grow(32 * 1024)

	writeLifecycleMetrics(&builder, snapshot)
	writeRuntimeMetrics(&builder, snapshot)
	writeOutboxMetrics(&builder, snapshot)
	writeMaintenanceMetrics(&builder, snapshot)
	writeReconciliationMetrics(&builder, snapshot)
	writeSearchMetrics(&builder, snapshot)
	writeHTTPMetrics(&builder, snapshot)
	return builder.String()
}

func (metrics *Metrics) snapshot() metricsSnapshot {
	if metrics == nil {
		return metricsSnapshot{}
	}
	metrics.mu.RLock()
	defer metrics.mu.RUnlock()
	return metricsSnapshot{
		lifecycleOutcomes:          cloneMap(metrics.lifecycleOutcomes),
		lifecycleActions:           cloneMap(metrics.lifecycleActions),
		lifecycleErrors:            cloneMap(metrics.lifecycleErrors),
		lifecycleAttempts:          cloneHistogramMap(metrics.lifecycleAttempts),
		lifecycleCleanupDeleted:    metrics.lifecycleCleanupDeleted,
		runtimeRuns:                cloneMap(metrics.runtimeRuns),
		runtimeDurations:           cloneHistogramMap(metrics.runtimeDurations),
		runtimeConsecutiveFailures: cloneMap(metrics.runtimeConsecutiveFailures),
		runtimeNextDelaySeconds:    cloneMap(metrics.runtimeNextDelaySeconds),
		runtimeLastRunSuccess:      cloneMap(metrics.runtimeLastRunSuccess),
		runtimeLastSuccess:         cloneMap(metrics.runtimeLastSuccess),
		runtimeLastError:           cloneMap(metrics.runtimeLastError),
		outboxEvents:               cloneMap(metrics.outboxEvents),
		outboxRecovery:             cloneMap(metrics.outboxRecovery),
		outboxCleanupDeleted:       metrics.outboxCleanupDeleted,
		outboxLikelyMore:           metrics.outboxLikelyMore,
		outboxDispatchDuration:     metrics.outboxDispatchDuration.clone(),
		maintenanceRows:            cloneMap(metrics.maintenanceRows),
		maintenanceEvents:          cloneMap(metrics.maintenanceEvents),
		maintenanceTicks:           metrics.maintenanceTicks,
		maintenanceBacklog:         cloneMap(metrics.maintenanceBacklog),
		maintenanceDuration:        metrics.maintenanceDuration.clone(),
		reconciliationTotals:       cloneMap(metrics.reconciliationTotals),
		reconciliationBacklog:      cloneMap(metrics.reconciliationBacklog),
		reconciliationDuration:     metrics.reconciliationDuration.clone(),
		httpRequests:               cloneMap(metrics.httpRequests),
		httpErrors:                 cloneMap(metrics.httpErrors),
		httpDurations:              cloneHistogramMap(metrics.httpDurations),
		searchFirstPages:           cloneMap(metrics.searchFirstPages),
	}
}

func writeLifecycleMetrics(builder *strings.Builder, snapshot metricsSnapshot) {
	writeHeader(builder, "saved_lifecycle_outcomes_total", "Saved lifecycle messages by bounded source and persistence outcome.", "counter")
	for _, key := range sortedLifecycleKeys(snapshot.lifecycleOutcomes) {
		writeSample(builder, "saved_lifecycle_outcomes_total", []metricLabel{
			{name: "source", value: key.Source},
			{name: "outcome", value: key.Value},
		}, snapshot.lifecycleOutcomes[key])
	}

	writeHeader(builder, "saved_lifecycle_actions_total", "Saved lifecycle consumer actions by bounded source.", "counter")
	for _, key := range sortedLifecycleKeys(snapshot.lifecycleActions) {
		writeSample(builder, "saved_lifecycle_actions_total", []metricLabel{
			{name: "source", value: key.Source},
			{name: "action", value: key.Value},
		}, snapshot.lifecycleActions[key])
	}

	writeHeader(builder, "saved_lifecycle_errors_total", "Saved lifecycle observations by bounded source and error code.", "counter")
	for _, key := range sortedLifecycleKeys(snapshot.lifecycleErrors) {
		writeSample(builder, "saved_lifecycle_errors_total", []metricLabel{
			{name: "source", value: key.Source},
			{name: "error_code", value: key.Value},
		}, snapshot.lifecycleErrors[key])
	}

	attemptKeys := sortedLifecycleHistogramKeys(snapshot.lifecycleAttempts)
	attemptSeries := make([]histogramSeries, 0, len(attemptKeys))
	for _, key := range attemptKeys {
		attemptSeries = append(attemptSeries, histogramSeries{
			labels: []metricLabel{
				{name: "source", value: key.Source},
				{name: "action", value: key.Value},
			},
			value: snapshot.lifecycleAttempts[key],
		})
	}
	writeHistogram(
		builder,
		"saved_lifecycle_delivery_attempts",
		"JetStream delivery attempt observed for Saved lifecycle actions.",
		lifecycleDeliveryAttemptBucket,
		attemptSeries,
	)

	writeHeader(builder, "saved_lifecycle_inbox_cleanup_deleted_total", "Expired Saved lifecycle inbox deduplication rows deleted.", "counter")
	writeSample(builder, "saved_lifecycle_inbox_cleanup_deleted_total", nil, snapshot.lifecycleCleanupDeleted)
}

func writeRuntimeMetrics(builder *strings.Builder, snapshot metricsSnapshot) {
	tasks := observedRuntimeTasks(snapshot)
	writeHeader(builder, "saved_runtime_runs_total", "Saved background task runs by bounded task and result.", "counter")
	for _, task := range tasks {
		for _, result := range []string{"success", "error"} {
			writeSample(builder, "saved_runtime_runs_total", []metricLabel{
				{name: "task", value: task},
				{name: "result", value: result},
			}, snapshot.runtimeRuns[runtimeResultKey{Task: task, Result: result}])
		}
	}

	runtimeSeries := make([]histogramSeries, 0, len(tasks))
	for _, task := range tasks {
		runtimeSeries = append(runtimeSeries, histogramSeries{
			labels: []metricLabel{{name: "task", value: task}},
			value:  histogramOrZero(snapshot.runtimeDurations[task], runtimeDurationBuckets),
		})
	}
	writeHistogram(builder, "saved_runtime_run_duration_seconds", "Saved background task run duration in seconds.", runtimeDurationBuckets, runtimeSeries)

	writeRuntimeGauge(builder, "saved_runtime_consecutive_failures", "Current consecutive failures for each Saved background task.", tasks, func(task string) float64 {
		return float64(snapshot.runtimeConsecutiveFailures[task])
	})
	writeRuntimeGauge(builder, "saved_runtime_next_delay_seconds", "Delay scheduled before the next Saved background task run.", tasks, func(task string) float64 {
		return snapshot.runtimeNextDelaySeconds[task]
	})
	writeRuntimeGauge(builder, "saved_runtime_last_run_success", "Whether the last Saved background task run succeeded.", tasks, func(task string) float64 {
		return snapshot.runtimeLastRunSuccess[task]
	})
	writeRuntimeGauge(builder, "saved_runtime_last_success_timestamp_seconds", "Unix timestamp of the last successful Saved background task run.", tasks, func(task string) float64 {
		return snapshot.runtimeLastSuccess[task]
	})
	writeRuntimeGauge(builder, "saved_runtime_last_error_timestamp_seconds", "Unix timestamp of the last failed Saved background task run.", tasks, func(task string) float64 {
		return snapshot.runtimeLastError[task]
	})
}

func writeOutboxMetrics(builder *strings.Builder, snapshot metricsSnapshot) {
	writeHeader(builder, "saved_outbox_events_total", "Saved domain outbox events observed during dispatch by result.", "counter")
	for _, result := range outboxEventOrder {
		writeSample(builder, "saved_outbox_events_total", []metricLabel{{name: "result", value: result}}, snapshot.outboxEvents[result])
	}
	writeHeader(builder, "saved_outbox_recovery_total", "Expired Saved domain outbox leases recovered by result.", "counter")
	for _, result := range outboxRecoveryOrder {
		writeSample(builder, "saved_outbox_recovery_total", []metricLabel{{name: "result", value: result}}, snapshot.outboxRecovery[result])
	}
	writeHeader(builder, "saved_outbox_cleanup_deleted_total", "Terminal Saved domain outbox rows deleted after retention.", "counter")
	writeSample(builder, "saved_outbox_cleanup_deleted_total", nil, snapshot.outboxCleanupDeleted)
	writeHeader(builder, "saved_outbox_likely_more", "Whether the last Saved outbox dispatch indicated immediately available backlog.", "gauge")
	writeSample(builder, "saved_outbox_likely_more", nil, snapshot.outboxLikelyMore)
	writeHistogram(builder, "saved_outbox_dispatch_duration_seconds", "Saved domain outbox dispatch batch duration in seconds.", outboxDispatchDurationBuckets, []histogramSeries{{
		value: histogramOrZero(snapshot.outboxDispatchDuration, outboxDispatchDurationBuckets),
	}})
}

func writeMaintenanceMetrics(builder *strings.Builder, snapshot metricsSnapshot) {
	writeHeader(builder, "saved_maintenance_rows_total", "Rows affected by bounded Saved maintenance, retention, purge, and projection GC actions.", "counter")
	for _, action := range maintenanceRowOrder {
		writeSample(builder, "saved_maintenance_rows_total", []metricLabel{{name: "action", value: action}}, snapshot.maintenanceRows[action])
	}
	writeHeader(builder, "saved_maintenance_events_total", "Bounded Saved maintenance state transitions.", "counter")
	for _, action := range maintenanceEventOrder {
		writeSample(builder, "saved_maintenance_events_total", []metricLabel{{name: "action", value: action}}, snapshot.maintenanceEvents[action])
	}
	writeHeader(builder, "saved_maintenance_ticks_total", "Bounded Saved maintenance transactions executed.", "counter")
	writeSample(builder, "saved_maintenance_ticks_total", nil, snapshot.maintenanceTicks)
	writeHeader(builder, "saved_maintenance_backlog", "Whether the last Saved maintenance run was capped or reported more work.", "gauge")
	for _, state := range []string{"capped", "has_more"} {
		writeSample(builder, "saved_maintenance_backlog", []metricLabel{{name: "state", value: state}}, snapshot.maintenanceBacklog[state])
	}
	writeHistogram(builder, "saved_maintenance_run_duration_seconds", "Saved maintenance run duration in seconds.", maintenanceDurationBuckets, []histogramSeries{{
		value: histogramOrZero(snapshot.maintenanceDuration, maintenanceDurationBuckets),
	}})
}

func writeReconciliationMetrics(builder *strings.Builder, snapshot metricsSnapshot) {
	writeHeader(builder, "saved_reconciliation_total", "Bounded Saved projection reconciliation outcomes and retries.", "counter")
	for _, result := range reconciliationResultOrder {
		writeSample(builder, "saved_reconciliation_total", []metricLabel{{name: "result", value: result}}, snapshot.reconciliationTotals[result])
	}
	writeHeader(builder, "saved_reconciliation_backlog", "Whether the last Saved projection reconciliation run was capped or reported more work.", "gauge")
	for _, state := range []string{"capped", "has_more"} {
		writeSample(builder, "saved_reconciliation_backlog", []metricLabel{{name: "state", value: state}}, snapshot.reconciliationBacklog[state])
	}
	writeHistogram(builder, "saved_reconciliation_run_duration_seconds", "Saved projection reconciliation run duration in seconds.", reconciliationDurationBuckets, []histogramSeries{{
		value: histogramOrZero(snapshot.reconciliationDuration, reconciliationDurationBuckets),
	}})
}

func writeHTTPMetrics(builder *strings.Builder, snapshot metricsSnapshot) {
	keys := sortedHTTPKeys(snapshot.httpRequests)
	writeHeader(builder, "saved_http_requests_total", "Saved HTTP requests by allowlisted route pattern, method, and status class.", "counter")
	for _, key := range keys {
		writeSample(builder, "saved_http_requests_total", httpLabels(key), snapshot.httpRequests[key])
	}

	errorKeys := sortedHTTPKeys(snapshot.httpErrors)
	writeHeader(builder, "saved_http_errors_total", "Saved HTTP responses in the 4xx or 5xx status classes.", "counter")
	for _, key := range errorKeys {
		writeSample(builder, "saved_http_errors_total", httpLabels(key), snapshot.httpErrors[key])
	}

	durationKeys := sortedHTTPHistogramKeys(snapshot.httpDurations)
	durationSeries := make([]histogramSeries, 0, len(durationKeys))
	for _, key := range durationKeys {
		durationSeries = append(durationSeries, histogramSeries{
			labels: httpLabels(key),
			value:  snapshot.httpDurations[key],
		})
	}
	writeHistogram(builder, "saved_http_request_duration_seconds", "Saved HTTP request duration in seconds.", httpDurationBuckets, durationSeries)
}

func writeSearchMetrics(builder *strings.Builder, snapshot metricsSnapshot) {
	writeHeader(builder, "saved_search_first_pages_total", "Successful first-page Saved searches by bounded result outcome.", "counter")
	for _, result := range []string{"matches", "zero_results"} {
		writeSample(
			builder,
			"saved_search_first_pages_total",
			[]metricLabel{{name: "result", value: result}},
			snapshot.searchFirstPages[result],
		)
	}
}

func writeRuntimeGauge(
	builder *strings.Builder,
	name string,
	help string,
	tasks []string,
	value func(string) float64,
) {
	writeHeader(builder, name, help, "gauge")
	for _, task := range tasks {
		writeSample(builder, name, []metricLabel{{name: "task", value: task}}, value(task))
	}
}

func writeHistogram(
	builder *strings.Builder,
	name string,
	help string,
	bounds []float64,
	series []histogramSeries,
) {
	writeHeader(builder, name, help, "histogram")
	for _, item := range series {
		for index, upperBound := range bounds {
			labels := appendClonedLabel(item.labels, metricLabel{name: "le", value: formatFloat(upperBound)})
			writeSample(builder, name+"_bucket", labels, histogramBucket(item.value, index))
		}
		labels := appendClonedLabel(item.labels, metricLabel{name: "le", value: "+Inf"})
		writeSample(builder, name+"_bucket", labels, histogramBucket(item.value, len(bounds)))
		writeSample(builder, name+"_sum", item.labels, item.value.Sum)
		writeSample(builder, name+"_count", item.labels, item.value.Count)
	}
}

func writeHeader(builder *strings.Builder, name, help, metricType string) {
	fmt.Fprintf(builder, "# HELP %s %s\n", name, help)
	fmt.Fprintf(builder, "# TYPE %s %s\n", name, metricType)
}

func writeSample(builder *strings.Builder, name string, labels []metricLabel, value any) {
	builder.WriteString(name)
	if len(labels) > 0 {
		builder.WriteByte('{')
		for index, label := range labels {
			if index > 0 {
				builder.WriteByte(',')
			}
			builder.WriteString(label.name)
			builder.WriteByte('=')
			builder.WriteString(strconv.Quote(label.value))
		}
		builder.WriteByte('}')
	}
	builder.WriteByte(' ')
	switch typed := value.(type) {
	case uint64:
		builder.WriteString(strconv.FormatUint(typed, 10))
	case float64:
		builder.WriteString(formatFloat(typed))
	default:
		builder.WriteByte('0')
	}
	builder.WriteByte('\n')
}

func formatFloat(value float64) string {
	if math.IsNaN(value) {
		return "0"
	}
	return strconv.FormatFloat(value, 'g', -1, 64)
}

func histogramBucket(value histogram, index int) uint64 {
	if index < 0 || index >= len(value.Buckets) {
		return 0
	}
	return value.Buckets[index]
}

func histogramOrZero(value histogram, bounds []float64) histogram {
	if len(value.Buckets) != len(bounds)+1 {
		value.Buckets = make([]uint64, len(bounds)+1)
	}
	return value
}

func appendClonedLabel(labels []metricLabel, extra metricLabel) []metricLabel {
	result := make([]metricLabel, len(labels)+1)
	copy(result, labels)
	result[len(labels)] = extra
	return result
}

func httpLabels(key httpKey) []metricLabel {
	return []metricLabel{
		{name: "route", value: key.Route},
		{name: "method", value: key.Method},
		{name: "status_class", value: key.StatusClass},
	}
}

func observedRuntimeTasks(snapshot metricsSnapshot) []string {
	tasks := append([]string(nil), runtimeTaskOrder...)
	if _, ok := snapshot.runtimeConsecutiveFailures[unknownLabel]; ok ||
		hasUnknownRuntimeRun(snapshot.runtimeRuns) ||
		snapshot.runtimeDurations[unknownLabel].Count > 0 {
		tasks = append(tasks, unknownLabel)
	}
	return tasks
}

func hasUnknownRuntimeRun(values map[runtimeResultKey]uint64) bool {
	return values[runtimeResultKey{Task: unknownLabel, Result: "success"}] > 0 ||
		values[runtimeResultKey{Task: unknownLabel, Result: "error"}] > 0
}

func sortedLifecycleKeys(values map[lifecycleKey]uint64) []lifecycleKey {
	keys := make([]lifecycleKey, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(left, right int) bool {
		if keys[left].Source == keys[right].Source {
			return keys[left].Value < keys[right].Value
		}
		return keys[left].Source < keys[right].Source
	})
	return keys
}

func sortedLifecycleHistogramKeys(values map[lifecycleKey]histogram) []lifecycleKey {
	keys := make([]lifecycleKey, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(left, right int) bool {
		if keys[left].Source == keys[right].Source {
			return keys[left].Value < keys[right].Value
		}
		return keys[left].Source < keys[right].Source
	})
	return keys
}

func sortedHTTPKeys(values map[httpKey]uint64) []httpKey {
	keys := make([]httpKey, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sortHTTPKeys(keys)
	return keys
}

func sortedHTTPHistogramKeys(values map[httpKey]histogram) []httpKey {
	keys := make([]httpKey, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sortHTTPKeys(keys)
	return keys
}

func sortHTTPKeys(keys []httpKey) {
	sort.Slice(keys, func(left, right int) bool {
		if keys[left].Route != keys[right].Route {
			return keys[left].Route < keys[right].Route
		}
		if keys[left].Method != keys[right].Method {
			return keys[left].Method < keys[right].Method
		}
		return keys[left].StatusClass < keys[right].StatusClass
	})
}

func cloneMap[Key comparable, Value any](source map[Key]Value) map[Key]Value {
	result := make(map[Key]Value, len(source))
	for key, value := range source {
		result[key] = value
	}
	return result
}

func cloneHistogramMap[Key comparable](source map[Key]*histogram) map[Key]histogram {
	result := make(map[Key]histogram, len(source))
	for key, value := range source {
		if value != nil {
			result[key] = value.clone()
		}
	}
	return result
}
