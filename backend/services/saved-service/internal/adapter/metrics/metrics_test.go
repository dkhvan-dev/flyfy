package metrics

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	natsadapter "kz/inflap/backend/services/saved-service/internal/adapter/nats"
	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
	savedoutbox "kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	savedreconciliation "kz/inflap/backend/services/saved-service/internal/app/savedreconciliation"
	savedruntime "kz/inflap/backend/services/saved-service/internal/runtime"
)

func TestLifecycleMetricsUseOnlyBoundedDimensions(t *testing.T) {
	registry := New()
	registry.ObserveSavedLifecycle(natsadapter.Observation{
		Subject:         savedlifecycle.ActivitySubjectV1,
		Outcome:         savedlifecycle.OutcomeApplied,
		Action:          natsadapter.ObservationAck,
		DeliveryAttempt: 2,
	})
	registry.ObserveSavedLifecycle(natsadapter.Observation{
		Subject:         savedlifecycle.ActivitySubjectV1,
		ErrorCode:       savedlifecycle.ErrorCodeRepositoryUnavailable,
		Action:          natsadapter.ObservationRetry,
		DeliveryAttempt: 3,
	})
	registry.ObserveSavedLifecycle(natsadapter.Observation{
		Action:      natsadapter.ObservationCleanup,
		DeletedRows: 7,
	})

	secret := "saved.source.user-123.private.lifecycle.v1"
	registry.ObserveSavedLifecycle(natsadapter.Observation{
		Subject:         secret,
		Outcome:         savedlifecycle.OutcomeCode("RAW_OUTCOME_123"),
		ErrorCode:       savedlifecycle.ErrorCode("RAW_ERROR_123"),
		Action:          natsadapter.ObservationAction("RAW_ACTION_123"),
		DeliveryAttempt: ^uint64(0),
		DeletedRows:     -10,
	})

	body := scrape(t, registry)
	assertContains(t, body,
		`saved_lifecycle_outcomes_total{source="ACTIVITY",outcome="APPLIED"} 1`,
		`saved_lifecycle_actions_total{source="ACTIVITY",action="ACK"} 1`,
		`saved_lifecycle_errors_total{source="ACTIVITY",error_code="REPOSITORY_UNAVAILABLE"} 1`,
		`saved_lifecycle_delivery_attempts_bucket{source="ACTIVITY",action="ACK",le="2"} 1`,
		`saved_lifecycle_inbox_cleanup_deleted_total 7`,
		`saved_lifecycle_outcomes_total{source="UNKNOWN",outcome="UNKNOWN"} 1`,
		`saved_lifecycle_actions_total{source="UNKNOWN",action="UNKNOWN"} 1`,
		`saved_lifecycle_errors_total{source="UNKNOWN",error_code="UNKNOWN"} 1`,
	)
	assertNotContains(t, body, secret, "RAW_OUTCOME_123", "RAW_ERROR_123", "RAW_ACTION_123")
}

func TestRuntimeMetricsCoverOutboxMaintenanceAndLastResults(t *testing.T) {
	registry := New()
	base := time.Unix(1000, 0).UTC()
	registry.ObserveSavedRuntime(savedruntime.Observation{
		Task:       savedruntime.TaskOutboxDispatch,
		StartedAt:  base,
		FinishedAt: base.Add(time.Second),
		OutboxBatch: savedoutbox.BatchStats{
			StartedAt:       base,
			FinishedAt:      base.Add(500 * time.Millisecond),
			LeasesRecovered: 2,
			RecoveryDead:    1,
			Claimed:         5,
			Delivered:       3,
			RetryScheduled:  1,
			Dead:            1,
			LikelyMore:      true,
		},
	})
	registry.ObserveSavedRuntime(savedruntime.Observation{
		Task:                savedruntime.TaskOutboxDispatch,
		StartedAt:           base.Add(2 * time.Second),
		FinishedAt:          base.Add(3 * time.Second),
		ConsecutiveFailures: 3,
		NextDelay:           4 * time.Second,
		Err:                 errors.New("database endpoint and owner must not become a label"),
	})
	registry.ObserveSavedRuntime(savedruntime.Observation{
		Task:          savedruntime.TaskOutboxCleanup,
		StartedAt:     base.Add(4 * time.Second),
		FinishedAt:    base.Add(5 * time.Second),
		OutboxDeleted: 11,
	})
	registry.ObserveSavedRuntime(savedruntime.Observation{
		Task:       savedruntime.TaskMaintenance,
		StartedAt:  base.Add(6 * time.Second),
		FinishedAt: base.Add(7 * time.Second),
		MaintenanceRun: savedmaintenance.Stats{
			StartedAt:                    base.Add(6 * time.Second),
			FinishedAt:                   base.Add(6500 * time.Millisecond),
			Ticks:                        2,
			Capped:                       true,
			HasMore:                      true,
			PendingOperationsExpired:     1,
			TerminalOperationsPurged:     2,
			TerminalOutboxPurged:         3,
			InboxDedupPurged:             4,
			DeletedCollectionChildren:    5,
			RemovedCollectionItemsPurged: 6,
			DeletedCollectionsPurged:     7,
			RemovedSavedItemsPurged:      8,
			ProjectionCandidatesMarked:   9,
			EphemeralProjectionsPurged:   10,
			StandardProjectionsPurged:    11,
			SubjectPurgeRowsPurged:       12,
			SubjectPurgePhasesAdvanced:   1,
			SubjectPurgesCompleted:       1,
			CompletedSubjectPurgesPurged: 13,
		},
	})
	registry.ObserveSavedRuntime(savedruntime.Observation{
		Task:       savedruntime.TaskReconciliation,
		StartedAt:  base.Add(7 * time.Second),
		FinishedAt: base.Add(8 * time.Second),
		ReconciliationRun: savedreconciliation.Stats{
			StartedAt:           base.Add(7 * time.Second),
			FinishedAt:          base.Add(7500 * time.Millisecond),
			CandidatesClaimed:   5,
			PublicApplied:       1,
			DenyApplied:         1,
			MetadataOnlyApplied: 1,
			NoChange:            1,
			StaleIgnored:        1,
			PayloadsCleared:     1,
			SourceAdvanced:      2,
			ProjectionAdvanced:  2,
			VisibilityAdvanced:  1,
			NotFound:            1,
			ResolutionFailures:  1,
			ResolveRetries:      2,
			RepositoryRetries:   1,
			Capped:              true,
			HasMore:             true,
		},
	})

	privateTask := savedruntime.Task("owner-123-maintenance")
	registry.ObserveSavedRuntime(savedruntime.Observation{
		Task:                privateTask,
		StartedAt:           base.Add(9 * time.Second),
		FinishedAt:          base.Add(8 * time.Second),
		ConsecutiveFailures: -10,
		NextDelay:           -time.Second,
	})

	body := scrape(t, registry)
	assertContains(t, body,
		`saved_runtime_runs_total{task="OUTBOX_DISPATCH",result="success"} 1`,
		`saved_runtime_runs_total{task="OUTBOX_DISPATCH",result="error"} 1`,
		`saved_runtime_consecutive_failures{task="OUTBOX_DISPATCH"} 3`,
		`saved_runtime_next_delay_seconds{task="OUTBOX_DISPATCH"} 4`,
		`saved_runtime_last_run_success{task="OUTBOX_DISPATCH"} 0`,
		`saved_runtime_last_success_timestamp_seconds{task="OUTBOX_DISPATCH"} 1001`,
		`saved_runtime_last_error_timestamp_seconds{task="OUTBOX_DISPATCH"} 1003`,
		`saved_outbox_events_total{result="claimed"} 5`,
		`saved_outbox_events_total{result="delivered"} 3`,
		`saved_outbox_events_total{result="retry_scheduled"} 1`,
		`saved_outbox_events_total{result="dead"} 1`,
		`saved_outbox_recovery_total{result="released"} 2`,
		`saved_outbox_recovery_total{result="dead"} 1`,
		`saved_outbox_cleanup_deleted_total 11`,
		`saved_outbox_dispatch_duration_seconds_count 2`,
		`saved_maintenance_rows_total{action="projection_candidates_marked"} 9`,
		`saved_maintenance_rows_total{action="ephemeral_projections_purged"} 10`,
		`saved_maintenance_rows_total{action="standard_projections_purged"} 11`,
		`saved_maintenance_rows_total{action="subject_purge_rows_purged"} 12`,
		`saved_maintenance_events_total{action="subject_purges_completed"} 1`,
		`saved_maintenance_ticks_total 2`,
		`saved_maintenance_backlog{state="capped"} 1`,
		`saved_maintenance_backlog{state="has_more"} 1`,
		`saved_runtime_runs_total{task="RECONCILIATION",result="success"} 1`,
		`saved_reconciliation_total{result="candidates_claimed"} 5`,
		`saved_reconciliation_total{result="deny_applied"} 1`,
		`saved_reconciliation_total{result="payloads_cleared"} 1`,
		`saved_reconciliation_total{result="resolve_retries"} 2`,
		`saved_reconciliation_backlog{state="capped"} 1`,
		`saved_reconciliation_backlog{state="has_more"} 1`,
		`saved_reconciliation_run_duration_seconds_count 1`,
		`saved_runtime_consecutive_failures{task="UNKNOWN"} 0`,
	)
	assertNotContains(t, body, string(privateTask), "database endpoint", "owner")
}

func TestPrometheusEndpointIsDeterministicAndWellFormed(t *testing.T) {
	registry := New()
	registry.ObserveSavedLifecycle(natsadapter.Observation{
		Subject: savedlifecycle.GuideSubjectV1,
		Outcome: savedlifecycle.OutcomeDuplicate,
		Action:  natsadapter.ObservationAck,
	})

	first := httptest.NewRecorder()
	registry.ServeHTTP(first, httptest.NewRequest(http.MethodGet, "/metrics", nil))
	second := httptest.NewRecorder()
	registry.ServeHTTP(second, httptest.NewRequest(http.MethodGet, "/metrics", nil))
	if first.Code != http.StatusOK || second.Code != http.StatusOK {
		t.Fatalf("GET status = %d/%d, want 200", first.Code, second.Code)
	}
	if first.Body.String() != second.Body.String() {
		t.Fatal("Prometheus output is not deterministic")
	}
	if got := first.Header().Get("Content-Type"); got != "text/plain; version=0.0.4; charset=utf-8" {
		t.Fatalf("Content-Type = %q", got)
	}
	assertContains(t, first.Body.String(),
		"# HELP saved_lifecycle_outcomes_total ",
		"# TYPE saved_lifecycle_outcomes_total counter",
		"# HELP saved_runtime_run_duration_seconds ",
		"# TYPE saved_runtime_run_duration_seconds histogram",
		"# HELP saved_http_request_duration_seconds ",
		"# TYPE saved_http_request_duration_seconds histogram",
	)

	head := httptest.NewRecorder()
	registry.ServeHTTP(head, httptest.NewRequest(http.MethodHead, "/metrics", nil))
	if head.Code != http.StatusOK || head.Body.Len() != 0 || head.Header().Get("Content-Length") == "0" {
		t.Fatalf("HEAD status=%d body=%d content-length=%q", head.Code, head.Body.Len(), head.Header().Get("Content-Length"))
	}

	post := httptest.NewRecorder()
	registry.ServeHTTP(post, httptest.NewRequest(http.MethodPost, "/metrics", nil))
	if post.Code != http.StatusMethodNotAllowed || post.Header().Get("Allow") != "GET, HEAD" {
		t.Fatalf("POST status=%d allow=%q", post.Code, post.Header().Get("Allow"))
	}
}

func TestSavedSearchMetricsExposePrivacySafeFirstPageOutcomes(t *testing.T) {
	t.Parallel()
	registry := New()
	registry.ObserveSavedSearch(false)
	registry.ObserveSavedSearch(true)
	registry.ObserveSavedSearch(true)

	body := scrape(t, registry)
	assertContains(t, body,
		`saved_search_first_pages_total{result="matches"} 1`,
		`saved_search_first_pages_total{result="zero_results"} 2`,
	)
}

func TestArbitraryObservationValuesCollapseToBoundedUnknownSeries(t *testing.T) {
	var registry Metrics
	for index := range 250 {
		suffix := formatUint(uint64(index))
		registry.ObserveSavedLifecycle(natsadapter.Observation{
			Subject:         "private-subject-" + suffix,
			Outcome:         savedlifecycle.OutcomeCode("private-outcome-" + suffix),
			ErrorCode:       savedlifecycle.ErrorCode("private-error-" + suffix),
			Action:          natsadapter.ObservationAction("private-action-" + suffix),
			DeliveryAttempt: uint64(index + 1),
		})
		registry.ObserveSavedRuntime(savedruntime.Observation{
			Task: savedruntime.Task("private-task-" + suffix),
		})
		registry.observeHTTP("private-pattern-"+suffix, "private-method-"+suffix, 999, time.Millisecond)
	}

	snapshot := registry.snapshot()
	if len(snapshot.lifecycleActions) != 1 || len(snapshot.lifecycleOutcomes) != 1 ||
		len(snapshot.lifecycleErrors) != 1 || len(snapshot.lifecycleAttempts) != 1 {
		t.Fatalf(
			"lifecycle series actions=%d outcomes=%d errors=%d attempts=%d, want one each",
			len(snapshot.lifecycleActions),
			len(snapshot.lifecycleOutcomes),
			len(snapshot.lifecycleErrors),
			len(snapshot.lifecycleAttempts),
		)
	}
	if len(snapshot.runtimeRuns) != 1 || len(snapshot.httpRequests) != 1 ||
		len(snapshot.httpDurations) != 1 {
		t.Fatalf(
			"runtime/http series runs=%d requests=%d durations=%d, want one each",
			len(snapshot.runtimeRuns),
			len(snapshot.httpRequests),
			len(snapshot.httpDurations),
		)
	}
	body := scrape(t, &registry)
	assertNotContains(t, body, "private-subject", "private-outcome", "private-error", "private-action", "private-task", "private-pattern", "private-method")
}

func TestMetricsAreSafeUnderConcurrentObserversAndScrapes(t *testing.T) {
	registry := New()
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	})
	handler := registry.Wrap(mux)
	const workers = 16
	const iterations = 50

	var waitGroup sync.WaitGroup
	waitGroup.Add(workers)
	for range workers {
		go func() {
			defer waitGroup.Done()
			for range iterations {
				registry.ObserveSavedLifecycle(natsadapter.Observation{
					Subject: savedlifecycle.AttractionSubjectV1,
					Outcome: savedlifecycle.OutcomeApplied,
					Action:  natsadapter.ObservationAck,
				})
				registry.ObserveSavedRuntime(savedruntime.Observation{
					Task: savedruntime.TaskOutboxDispatch,
					OutboxBatch: savedoutbox.BatchStats{
						Delivered: 1,
					},
				})
				recorder := httptest.NewRecorder()
				handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/health", nil))
				if recorder.Code != http.StatusNoContent {
					t.Errorf("status = %d, want 204", recorder.Code)
					return
				}
			}
		}()
	}
	var scrapeWaitGroup sync.WaitGroup
	scrapeWaitGroup.Add(8)
	for range 8 {
		go func() {
			defer scrapeWaitGroup.Done()
			for range 20 {
				_ = scrapeWithoutTest(registry)
			}
		}()
	}
	waitGroup.Wait()
	scrapeWaitGroup.Wait()

	want := uint64(workers * iterations)
	body := scrape(t, registry)
	assertContains(t, body,
		`saved_lifecycle_actions_total{source="ATTRACTION",action="ACK"} `+formatUint(want),
		`saved_outbox_events_total{result="delivered"} `+formatUint(want),
		`saved_http_requests_total{route="/health",method="GET",status_class="2xx"} `+formatUint(want),
	)
}

func scrape(t *testing.T, registry *Metrics) string {
	t.Helper()
	recorder := httptest.NewRecorder()
	registry.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/metrics", nil))
	if recorder.Code != http.StatusOK {
		t.Fatalf("scrape status = %d", recorder.Code)
	}
	return recorder.Body.String()
}

func scrapeWithoutTest(registry *Metrics) string {
	recorder := httptest.NewRecorder()
	registry.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/metrics", nil))
	return recorder.Body.String()
}

func assertContains(t *testing.T, value string, expected ...string) {
	t.Helper()
	for _, item := range expected {
		if !strings.Contains(value, item) {
			t.Errorf("output does not contain %q", item)
		}
	}
}

func assertNotContains(t *testing.T, value string, forbidden ...string) {
	t.Helper()
	for _, item := range forbidden {
		if strings.Contains(value, item) {
			t.Errorf("output contains forbidden value %q", item)
		}
	}
}

func formatUint(value uint64) string {
	const digits = "0123456789"
	if value == 0 {
		return "0"
	}
	var buffer [20]byte
	index := len(buffer)
	for value > 0 {
		index--
		buffer[index] = digits[value%10]
		value /= 10
	}
	return string(buffer[index:])
}
