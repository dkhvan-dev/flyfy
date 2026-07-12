package metrics

import (
	"fmt"
	"math"
	"net/http"
	"strconv"
	"sync/atomic"
	"time"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

var activityTranslationDurationBuckets = [...]float64{0.1, 0.25, 0.5, 1, 2, 5, 10}

type ActivityTranslation struct {
	pending              atomic.Int64
	processing           atomic.Int64
	completed            atomic.Uint64
	failed               atomic.Uint64
	stale                atomic.Uint64
	oldestPendingAgeBits atomic.Uint64
	durationCount        atomic.Uint64
	durationSumBits      atomic.Uint64
	durationBucketCounts [len(activityTranslationDurationBuckets) + 1]atomic.Uint64
}

func NewActivityTranslation() *ActivityTranslation {
	return &ActivityTranslation{}
}

func (m *ActivityTranslation) SetQueueStats(stats model.ActivityTranslationQueueStats) {
	if m == nil {
		return
	}
	m.pending.Store(stats.PendingCount)
	m.processing.Store(stats.ProcessingCount)
	m.oldestPendingAgeBits.Store(math.Float64bits(max(stats.OldestPendingAgeSeconds, 0)))
}

func (m *ActivityTranslation) RecordCompleted() {
	if m != nil {
		m.completed.Add(1)
	}
}

func (m *ActivityTranslation) RecordFailed() {
	if m != nil {
		m.failed.Add(1)
	}
}

func (m *ActivityTranslation) RecordStale() {
	if m != nil {
		m.stale.Add(1)
	}
}

func (m *ActivityTranslation) ObserveDuration(duration time.Duration) {
	if m == nil {
		return
	}
	seconds := max(duration.Seconds(), 0)
	m.durationCount.Add(1)
	activityAtomicAddFloat64(&m.durationSumBits, seconds)
	for index, upperBound := range activityTranslationDurationBuckets {
		if seconds <= upperBound {
			m.durationBucketCounts[index].Add(1)
		}
	}
	m.durationBucketCounts[len(activityTranslationDurationBuckets)].Add(1)
}

func (m *ActivityTranslation) ServeHTTP(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; version=0.0.4; charset=utf-8")

	activityWriteMetricHeader(w, "activity_translation_jobs_pending", "Current pending activity translation jobs.", "gauge")
	_, _ = fmt.Fprintf(w, "activity_translation_jobs_pending %d\n", m.pending.Load())
	activityWriteMetricHeader(w, "activity_translation_jobs_processing", "Current processing activity translation jobs.", "gauge")
	_, _ = fmt.Fprintf(w, "activity_translation_jobs_processing %d\n", m.processing.Load())
	activityWriteMetricHeader(w, "activity_translation_jobs_completed_total", "Completed activity translation jobs.", "counter")
	_, _ = fmt.Fprintf(w, "activity_translation_jobs_completed_total %d\n", m.completed.Load())
	activityWriteMetricHeader(w, "activity_translation_jobs_failed_total", "Permanently failed activity translation jobs.", "counter")
	_, _ = fmt.Fprintf(w, "activity_translation_jobs_failed_total %d\n", m.failed.Load())
	activityWriteMetricHeader(w, "activity_translation_jobs_stale_total", "Stale activity translation jobs.", "counter")
	_, _ = fmt.Fprintf(w, "activity_translation_jobs_stale_total %d\n", m.stale.Load())
	activityWriteMetricHeader(w, "activity_translation_oldest_pending_age_seconds", "Age of the oldest pending activity translation job.", "gauge")
	_, _ = fmt.Fprintf(
		w,
		"activity_translation_oldest_pending_age_seconds %s\n",
		activityFormatMetricFloat(math.Float64frombits(m.oldestPendingAgeBits.Load())),
	)

	activityWriteMetricHeader(w, "activity_translation_duration_seconds", "Activity translation job processing duration.", "histogram")
	for index, upperBound := range activityTranslationDurationBuckets {
		_, _ = fmt.Fprintf(
			w,
			"activity_translation_duration_seconds_bucket{le=%q} %d\n",
			activityFormatMetricFloat(upperBound),
			m.durationBucketCounts[index].Load(),
		)
	}
	_, _ = fmt.Fprintf(
		w,
		"activity_translation_duration_seconds_bucket{le=\"+Inf\"} %d\n",
		m.durationBucketCounts[len(activityTranslationDurationBuckets)].Load(),
	)
	_, _ = fmt.Fprintf(
		w,
		"activity_translation_duration_seconds_sum %s\n",
		activityFormatMetricFloat(math.Float64frombits(m.durationSumBits.Load())),
	)
	_, _ = fmt.Fprintf(w, "activity_translation_duration_seconds_count %d\n", m.durationCount.Load())
}

func activityWriteMetricHeader(w http.ResponseWriter, name string, help string, metricType string) {
	_, _ = fmt.Fprintf(w, "# HELP %s %s\n", name, help)
	_, _ = fmt.Fprintf(w, "# TYPE %s %s\n", name, metricType)
}

func activityFormatMetricFloat(value float64) string {
	return strconv.FormatFloat(value, 'g', -1, 64)
}

func activityAtomicAddFloat64(target *atomic.Uint64, delta float64) {
	for {
		currentBits := target.Load()
		current := math.Float64frombits(currentBits)
		if target.CompareAndSwap(currentBits, math.Float64bits(current+delta)) {
			return
		}
	}
}
