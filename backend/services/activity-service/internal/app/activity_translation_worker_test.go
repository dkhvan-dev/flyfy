package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

type activityTranslationJobRepoStub struct {
	jobs            []model.ActivityTranslationJob
	appliedJobID    uuid.UUID
	appliedFields   map[string]string
	appliedProvider string
	failedJobID     uuid.UUID
	failedRetryable bool
	failedNextRunAt time.Time
	failedErrorCode string
	applyResult     model.ActivityTranslationApplyResult
}

func (s *activityTranslationJobRepoStub) EnqueueActivityTranslationJobs(
	context.Context,
	[]model.ActivityTranslationJob,
) error {
	return nil
}

func (s *activityTranslationJobRepoStub) ClaimActivityTranslationJobs(
	context.Context,
	string,
	int,
	time.Duration,
) ([]model.ActivityTranslationJob, error) {
	jobs := s.jobs
	s.jobs = nil
	return jobs, nil
}

func (s *activityTranslationJobRepoStub) ApplyActivityTranslationJob(
	_ context.Context,
	jobID uuid.UUID,
	translatedFields map[string]string,
	provider string,
) (model.ActivityTranslationApplyResult, error) {
	s.appliedJobID = jobID
	s.appliedFields = translatedFields
	s.appliedProvider = provider
	return s.applyResult, nil
}

func (s *activityTranslationJobRepoStub) FailActivityTranslationJob(
	_ context.Context,
	jobID uuid.UUID,
	retryable bool,
	nextRunAt time.Time,
	lastError string,
) error {
	s.failedJobID = jobID
	s.failedRetryable = retryable
	s.failedNextRunAt = nextRunAt
	s.failedErrorCode = lastError
	return nil
}

func (s *activityTranslationJobRepoStub) GetActivityTranslationQueueStats(
	context.Context,
) (model.ActivityTranslationQueueStats, error) {
	return model.ActivityTranslationQueueStats{}, nil
}

type activityTranslatorStub struct {
	request port.ActivityTranslationRequest
	result  port.ActivityTranslationResult
	err     error
}

func (s *activityTranslatorStub) TranslateTexts(
	_ context.Context,
	input port.ActivityTranslationRequest,
) (port.ActivityTranslationResult, error) {
	s.request = input
	return s.result, s.err
}

type retryableActivityTranslationError struct{}

func (retryableActivityTranslationError) Error() string   { return "quota exhausted" }
func (retryableActivityTranslationError) Retryable() bool { return true }
func (retryableActivityTranslationError) Code() string    { return "quota_exhausted" }

func TestActivityTranslationWorkerAppliesOrderedFieldsAndRunsHook(t *testing.T) {
	job := activityTranslationTestJob()
	repo := &activityTranslationJobRepoStub{
		jobs:        []model.ActivityTranslationJob{job},
		applyResult: model.ActivityTranslationApplied,
	}
	translator := &activityTranslatorStub{result: port.ActivityTranslationResult{
		Provider: "azure_translator",
		Items: map[string][]port.ActivityTranslationTextResult{
			"en": {
				{Text: "Mountain hike", Status: port.ActivityTranslationTextTranslated},
				{Text: "Detailed mountain hike description.", Status: port.ActivityTranslationTextCached},
			},
		},
	}}
	worker := NewActivityTranslationWorker(
		ActivityTranslationWorkerConfig{Enabled: true},
		repo,
		translator,
		nil,
	)
	hookedActivityID := uuid.Nil
	worker.SetAppliedHook(func(_ context.Context, activityID uuid.UUID) {
		hookedActivityID = activityID
	})

	processed, err := worker.ProcessBatch(context.Background())
	if err != nil {
		t.Fatalf("ProcessBatch() error = %v", err)
	}
	if processed != 1 {
		t.Fatalf("processed = %d, want 1", processed)
	}
	if len(translator.request.Texts) != 2 ||
		translator.request.Texts[0] != job.SourceFields["title"] ||
		translator.request.Texts[1] != job.SourceFields["description"] {
		t.Fatalf("translation request texts = %#v, want title then description", translator.request.Texts)
	}
	if repo.appliedFields["title"] != "Mountain hike" ||
		repo.appliedFields["description"] != "Detailed mountain hike description." {
		t.Fatalf("applied fields = %#v", repo.appliedFields)
	}
	if repo.appliedProvider != "azure_translator" || hookedActivityID != job.ActivityID {
		t.Fatalf("provider/hook = %q/%s", repo.appliedProvider, hookedActivityID)
	}
}

func TestActivityTranslationWorkerRetriesProviderFailure(t *testing.T) {
	job := activityTranslationTestJob()
	repo := &activityTranslationJobRepoStub{jobs: []model.ActivityTranslationJob{job}}
	translator := &activityTranslatorStub{err: retryableActivityTranslationError{}}
	worker := NewActivityTranslationWorker(
		ActivityTranslationWorkerConfig{
			Enabled:        true,
			RetryBaseDelay: time.Minute,
		},
		repo,
		translator,
		nil,
	)
	now := time.Date(2026, 7, 11, 10, 0, 0, 0, time.UTC)
	worker.now = func() time.Time { return now }

	processed, err := worker.ProcessBatch(context.Background())
	if err != nil && !errors.Is(err, context.Canceled) {
		t.Fatalf("ProcessBatch() error = %v", err)
	}
	if processed != 1 || repo.failedJobID != job.ID {
		t.Fatalf("processed/failed job = %d/%s", processed, repo.failedJobID)
	}
	if !repo.failedRetryable || repo.failedErrorCode != "quota_exhausted" {
		t.Fatalf("failure = retryable:%v code:%q", repo.failedRetryable, repo.failedErrorCode)
	}
	if want := now.Add(time.Minute); !repo.failedNextRunAt.Equal(want) {
		t.Fatalf("next run = %s, want %s", repo.failedNextRunAt, want)
	}
}

func activityTranslationTestJob() model.ActivityTranslationJob {
	return model.ActivityTranslationJob{
		ID:             uuid.New(),
		ActivityID:     uuid.New(),
		SourceLanguage: "ru",
		TargetLanguage: "en",
		SourceFields: map[string]string{
			"title":       "Поход в горы",
			"description": "Подробное описание похода в горы.",
		},
		SourceHash:  "source-hash",
		Status:      model.ActivityTranslationJobProcessing,
		MaxAttempts: 5,
	}
}
