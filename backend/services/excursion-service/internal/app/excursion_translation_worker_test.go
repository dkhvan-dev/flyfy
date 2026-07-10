package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

func TestExcursionTranslationWorkerCompletesJobWhenSourceHashMatches(t *testing.T) {
	job := validWorkerTranslationJob()
	repo := &translationWorkerRepositoryStub{
		claimed:     []model.ExcursionTranslationJob{job},
		applyResult: model.ExcursionTranslationApplied,
	}
	metrics := &translationWorkerMetricsStub{}
	worker := newTranslationWorkerForTest(repo, successfulWorkerTranslator(), metrics)

	processed, err := worker.ProcessBatch(context.Background())

	if err != nil {
		t.Fatalf("ProcessBatch() error = %v", err)
	}
	if processed != 1 || repo.appliedJobID != job.ID {
		t.Fatalf("processed = %d applied job = %s", processed, repo.appliedJobID)
	}
	if repo.appliedFields["title"] != "Hotel departure" || repo.appliedFields["description"] == "" {
		t.Fatalf("applied fields = %#v", repo.appliedFields)
	}
	if metrics.completed != 1 {
		t.Fatalf("completed metric = %d, want 1", metrics.completed)
	}
}

func TestExcursionTranslationWorkerMarksJobStaleWhenSourceHashChanged(t *testing.T) {
	repo := &translationWorkerRepositoryStub{
		claimed:     []model.ExcursionTranslationJob{validWorkerTranslationJob()},
		applyResult: model.ExcursionTranslationStale,
	}
	metrics := &translationWorkerMetricsStub{}
	worker := newTranslationWorkerForTest(repo, successfulWorkerTranslator(), metrics)

	_, err := worker.ProcessBatch(context.Background())

	if err != nil {
		t.Fatalf("ProcessBatch() error = %v", err)
	}
	if metrics.stale != 1 || metrics.completed != 0 {
		t.Fatalf("metrics stale=%d completed=%d", metrics.stale, metrics.completed)
	}
}

func TestExcursionTranslationWorkerRetriesProviderError(t *testing.T) {
	job := validWorkerTranslationJob()
	repo := &translationWorkerRepositoryStub{claimed: []model.ExcursionTranslationJob{job}}
	translator := &translationWorkerTranslatorStub{
		err: workerTranslationError{retryable: true, code: "provider_unavailable"},
	}
	worker := newTranslationWorkerForTest(repo, translator, &translationWorkerMetricsStub{})

	_, err := worker.ProcessBatch(context.Background())

	if err != nil {
		t.Fatalf("ProcessBatch() error = %v", err)
	}
	if repo.failure == nil || !repo.failure.retryable || repo.failure.lastError != "provider_unavailable" {
		t.Fatalf("failure = %#v, want retryable provider error", repo.failure)
	}
	if !repo.failure.nextRunAt.Equal(worker.now().Add(30 * time.Second)) {
		t.Fatalf("next run = %s, want base backoff", repo.failure.nextRunAt)
	}
}

func TestExcursionTranslationWorkerFailsInvalidRequestWithoutRetry(t *testing.T) {
	repo := &translationWorkerRepositoryStub{claimed: []model.ExcursionTranslationJob{validWorkerTranslationJob()}}
	translator := &translationWorkerTranslatorStub{
		err: workerTranslationError{retryable: false, code: "invalid_request"},
	}
	metrics := &translationWorkerMetricsStub{}
	worker := newTranslationWorkerForTest(repo, translator, metrics)

	_, err := worker.ProcessBatch(context.Background())

	if err != nil {
		t.Fatalf("ProcessBatch() error = %v", err)
	}
	if repo.failure == nil || repo.failure.retryable || repo.failure.lastError != "invalid_request" {
		t.Fatalf("failure = %#v, want non-retryable invalid request", repo.failure)
	}
	if metrics.failed != 1 {
		t.Fatalf("failed metric = %d, want 1", metrics.failed)
	}
}

func TestExcursionTranslationWorkerHandlesQuotaExhaustedAsRetryable(t *testing.T) {
	job := validWorkerTranslationJob()
	repo := &translationWorkerRepositoryStub{claimed: []model.ExcursionTranslationJob{job}}
	translator := &translationWorkerTranslatorStub{result: port.TranslationResult{
		Items: map[string][]port.TranslationTextResult{
			"en": {
				{Text: job.SourceFields["title"], Status: port.TranslationTextQuotaExhausted},
				{Text: job.SourceFields["description"], Status: port.TranslationTextQuotaExhausted},
			},
		},
	}}
	worker := newTranslationWorkerForTest(repo, translator, &translationWorkerMetricsStub{})

	_, err := worker.ProcessBatch(context.Background())

	if err != nil {
		t.Fatalf("ProcessBatch() error = %v", err)
	}
	if repo.failure == nil || !repo.failure.retryable || repo.failure.lastError != "quota_exhausted" {
		t.Fatalf("failure = %#v, want retryable quota error", repo.failure)
	}
}

func TestExcursionTranslationWorkerLockCoversSequentialBatch(t *testing.T) {
	worker := NewExcursionTranslationWorker(ExcursionTranslationWorkerConfig{
		Enabled:        true,
		BatchSize:      25,
		PollInterval:   2 * time.Second,
		RequestTimeout: 8 * time.Second,
		LockTimeout:    2 * time.Minute,
	}, &translationWorkerRepositoryStub{}, successfulWorkerTranslator(), nil)

	want := 25*8*time.Second + 2*time.Second
	if worker.cfg.LockTimeout != want {
		t.Fatalf("lock timeout = %s, want %s", worker.cfg.LockTimeout, want)
	}
}

func newTranslationWorkerForTest(
	repo *translationWorkerRepositoryStub,
	translator port.ExcursionTranslator,
	metrics *translationWorkerMetricsStub,
) *ExcursionTranslationWorker {
	fixedNow := time.Date(2026, time.July, 10, 3, 0, 0, 0, time.UTC)
	worker := NewExcursionTranslationWorker(ExcursionTranslationWorkerConfig{
		Enabled:        true,
		WorkerID:       "worker-test",
		BatchSize:      10,
		PollInterval:   time.Second,
		RequestTimeout: time.Second,
		RetryBaseDelay: 30 * time.Second,
		LockTimeout:    time.Minute,
	}, repo, translator, metrics)
	worker.now = func() time.Time { return fixedNow }
	return worker
}

func validWorkerTranslationJob() model.ExcursionTranslationJob {
	fields := map[string]string{
		"title":       "Выезд из отеля",
		"description": "Встречаемся с гидом и начинаем маршрут.",
	}
	return model.ExcursionTranslationJob{
		ID:             uuid.New(),
		ExcursionID:    uuid.New(),
		EntityType:     model.ExcursionTranslationEntityItineraryItem,
		EntityID:       uuid.New(),
		SourceLanguage: "ru",
		TargetLanguage: "en",
		SourceFields:   fields,
		SourceHash:     model.HashExcursionTranslationSource("ru", fields),
		Status:         model.ExcursionTranslationJobProcessing,
		MaxAttempts:    5,
	}
}

func successfulWorkerTranslator() port.ExcursionTranslator {
	return &translationWorkerTranslatorStub{result: port.TranslationResult{
		Provider: "azure",
		Items: map[string][]port.TranslationTextResult{
			"en": {
				{Text: "Hotel departure", Status: port.TranslationTextTranslated, Provider: "azure"},
				{Text: "Meet your guide and start the route.", Status: port.TranslationTextCached, Provider: "azure", CacheHit: true},
			},
		},
	}}
}

type translationWorkerTranslatorStub struct {
	result port.TranslationResult
	err    error
	calls  []port.TranslationRequest
}

func (s *translationWorkerTranslatorStub) TranslateTexts(
	_ context.Context,
	input port.TranslationRequest,
) (port.TranslationResult, error) {
	s.calls = append(s.calls, input)
	return s.result, s.err
}

type translationWorkerFailure struct {
	retryable bool
	nextRunAt time.Time
	lastError string
}

type translationWorkerRepositoryStub struct {
	claimed       []model.ExcursionTranslationJob
	claimErr      error
	applyResult   model.ExcursionTranslationApplyResult
	applyErr      error
	appliedJobID  uuid.UUID
	appliedFields map[string]string
	failure       *translationWorkerFailure
	stats         model.ExcursionTranslationQueueStats
}

func (s *translationWorkerRepositoryStub) EnqueueExcursionTranslationJobs(context.Context, []model.ExcursionTranslationJob) error {
	return nil
}

func (s *translationWorkerRepositoryStub) MarkExcursionTranslationJobsStale(context.Context, uuid.UUID, []uuid.UUID) error {
	return nil
}

func (s *translationWorkerRepositoryStub) ClaimExcursionTranslationJobs(
	context.Context,
	string,
	int,
	time.Duration,
) ([]model.ExcursionTranslationJob, error) {
	return s.claimed, s.claimErr
}

func (s *translationWorkerRepositoryStub) ApplyExcursionTranslationJob(
	_ context.Context,
	jobID uuid.UUID,
	translatedFields map[string]string,
	_ string,
) (model.ExcursionTranslationApplyResult, error) {
	s.appliedJobID = jobID
	s.appliedFields = translatedFields
	return s.applyResult, s.applyErr
}

func (s *translationWorkerRepositoryStub) CompleteExcursionTranslationJob(context.Context, uuid.UUID, string) error {
	return nil
}

func (s *translationWorkerRepositoryStub) FailExcursionTranslationJob(
	_ context.Context,
	_ uuid.UUID,
	retryable bool,
	nextRunAt time.Time,
	lastError string,
) error {
	s.failure = &translationWorkerFailure{
		retryable: retryable,
		nextRunAt: nextRunAt,
		lastError: lastError,
	}
	return nil
}

func (s *translationWorkerRepositoryStub) MarkExcursionTranslationJobStale(context.Context, uuid.UUID) error {
	return nil
}

func (s *translationWorkerRepositoryStub) GetExcursionTranslationQueueStats(context.Context) (model.ExcursionTranslationQueueStats, error) {
	return s.stats, nil
}

type translationWorkerMetricsStub struct {
	completed int
	failed    int
	stale     int
	stats     model.ExcursionTranslationQueueStats
}

func (s *translationWorkerMetricsStub) SetQueueStats(stats model.ExcursionTranslationQueueStats) {
	s.stats = stats
}

func (s *translationWorkerMetricsStub) RecordCompleted()              { s.completed++ }
func (s *translationWorkerMetricsStub) RecordFailed()                 { s.failed++ }
func (s *translationWorkerMetricsStub) RecordStale()                  { s.stale++ }
func (s *translationWorkerMetricsStub) ObserveDuration(time.Duration) {}

type workerTranslationError struct {
	retryable bool
	code      string
}

func (e workerTranslationError) Error() string   { return e.code }
func (e workerTranslationError) Retryable() bool { return e.retryable }
func (e workerTranslationError) Code() string    { return e.code }

var _ error = workerTranslationError{}
