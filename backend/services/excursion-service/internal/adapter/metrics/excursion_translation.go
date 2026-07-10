package metrics

import (
	"fmt"
	"math"
	"net/http"
	"strconv"
	"sync/atomic"
	"time"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
)

var translationDurationBuckets = [...]float64{0.1, 0.25, 0.5, 1, 2, 5, 10}

type ExcursionTranslation struct {
	pending              atomic.Int64
	processing           atomic.Int64
	completed            atomic.Uint64
	failed               atomic.Uint64
	stale                atomic.Uint64
	oldestPendingAgeBits atomic.Uint64
	durationCount        atomic.Uint64
	durationSumBits      atomic.Uint64
	durationBucketCounts [len(translationDurationBuckets) + 1]atomic.Uint64
}

func NewExcursionTranslation() *ExcursionTranslation {
	return &ExcursionTranslation{}
}

func (m *ExcursionTranslation) SetQueueStats(stats model.ExcursionTranslationQueueStats) {
	if m == nil {
		return
	}
	m.pending.Store(stats.PendingCount)
	m.processing.Store(stats.ProcessingCount)
	m.oldestPendingAgeBits.Store(math.Float64bits(max(stats.OldestPendingAgeSeconds, 0)))
}

func (m *ExcursionTranslation) RecordCompleted() {
	if m != nil {
		m.completed.Add(1)
	}
}

func (m *ExcursionTranslation) RecordFailed() {
	if m != nil {
		m.failed.Add(1)
	}
}

func (m *ExcursionTranslation) RecordStale() {
	if m != nil {
		m.stale.Add(1)
	}
}

func (m *ExcursionTranslation) ObserveDuration(duration time.Duration) {
	if m == nil {
		return
	}
	seconds := max(duration.Seconds(), 0)
	m.durationCount.Add(1)
	atomicAddFloat64(&m.durationSumBits, seconds)
	for index, upperBound := range translationDurationBuckets {
		if seconds <= upperBound {
			m.durationBucketCounts[index].Add(1)
		}
	}
	m.durationBucketCounts[len(translationDurationBuckets)].Add(1)
}

func (m *ExcursionTranslation) ServeHTTP(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; version=0.0.4; charset=utf-8")

	writeMetricHeader(w, "excursion_translation_jobs_pending", "Current pending excursion translation jobs.", "gauge")
	_, _ = fmt.Fprintf(w, "excursion_translation_jobs_pending %d\n", m.pending.Load())
	writeMetricHeader(w, "excursion_translation_jobs_processing", "Current processing excursion translation jobs.", "gauge")
	_, _ = fmt.Fprintf(w, "excursion_translation_jobs_processing %d\n", m.processing.Load())
	writeMetricHeader(w, "excursion_translation_jobs_completed_total", "Completed excursion translation jobs.", "counter")
	_, _ = fmt.Fprintf(w, "excursion_translation_jobs_completed_total %d\n", m.completed.Load())
	writeMetricHeader(w, "excursion_translation_jobs_failed_total", "Permanently failed excursion translation jobs.", "counter")
	_, _ = fmt.Fprintf(w, "excursion_translation_jobs_failed_total %d\n", m.failed.Load())
	writeMetricHeader(w, "excursion_translation_jobs_stale_total", "Stale excursion translation jobs.", "counter")
	_, _ = fmt.Fprintf(w, "excursion_translation_jobs_stale_total %d\n", m.stale.Load())
	writeMetricHeader(w, "excursion_translation_oldest_pending_age_seconds", "Age of the oldest pending excursion translation job.", "gauge")
	_, _ = fmt.Fprintf(
		w,
		"excursion_translation_oldest_pending_age_seconds %s\n",
		formatMetricFloat(math.Float64frombits(m.oldestPendingAgeBits.Load())),
	)

	writeMetricHeader(w, "excursion_translation_duration_seconds", "Excursion translation job processing duration.", "histogram")
	for index, upperBound := range translationDurationBuckets {
		_, _ = fmt.Fprintf(
			w,
			"excursion_translation_duration_seconds_bucket{le=%q} %d\n",
			formatMetricFloat(upperBound),
			m.durationBucketCounts[index].Load(),
		)
	}
	_, _ = fmt.Fprintf(
		w,
		"excursion_translation_duration_seconds_bucket{le=\"+Inf\"} %d\n",
		m.durationBucketCounts[len(translationDurationBuckets)].Load(),
	)
	_, _ = fmt.Fprintf(
		w,
		"excursion_translation_duration_seconds_sum %s\n",
		formatMetricFloat(math.Float64frombits(m.durationSumBits.Load())),
	)
	_, _ = fmt.Fprintf(w, "excursion_translation_duration_seconds_count %d\n", m.durationCount.Load())
}

func writeMetricHeader(w http.ResponseWriter, name string, help string, metricType string) {
	_, _ = fmt.Fprintf(w, "# HELP %s %s\n", name, help)
	_, _ = fmt.Fprintf(w, "# TYPE %s %s\n", name, metricType)
}

func formatMetricFloat(value float64) string {
	return strconv.FormatFloat(value, 'g', -1, 64)
}

func atomicAddFloat64(target *atomic.Uint64, delta float64) {
	for {
		currentBits := target.Load()
		current := math.Float64frombits(currentBits)
		if target.CompareAndSwap(currentBits, math.Float64bits(current+delta)) {
			return
		}
	}
}
