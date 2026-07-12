package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

type ActivityTranslationWorkerConfig struct {
	Enabled        bool
	WorkerID       string
	BatchSize      int
	PollInterval   time.Duration
	RequestTimeout time.Duration
	RetryBaseDelay time.Duration
	LockTimeout    time.Duration
}

type ActivityTranslationWorkerMetrics interface {
	SetQueueStats(stats model.ActivityTranslationQueueStats)
	RecordCompleted()
	RecordFailed()
	RecordStale()
	ObserveDuration(duration time.Duration)
}

type noopActivityTranslationWorkerMetrics struct{}

func (noopActivityTranslationWorkerMetrics) SetQueueStats(model.ActivityTranslationQueueStats) {}
func (noopActivityTranslationWorkerMetrics) RecordCompleted()                                  {}
func (noopActivityTranslationWorkerMetrics) RecordFailed()                                     {}
func (noopActivityTranslationWorkerMetrics) RecordStale()                                      {}
func (noopActivityTranslationWorkerMetrics) ObserveDuration(time.Duration)                     {}

type ActivityTranslationWorker struct {
	cfg        ActivityTranslationWorkerConfig
	jobs       port.ActivityTranslationJobRepository
	translator port.ActivityTranslator
	metrics    ActivityTranslationWorkerMetrics
	onApplied  func(context.Context, uuid.UUID)
	now        func() time.Time
}

func (w *ActivityTranslationWorker) SetAppliedHook(hook func(context.Context, uuid.UUID)) {
	if w != nil {
		w.onApplied = hook
	}
}

func NewActivityTranslationWorker(
	cfg ActivityTranslationWorkerConfig,
	jobs port.ActivityTranslationJobRepository,
	translator port.ActivityTranslator,
	metrics ActivityTranslationWorkerMetrics,
) *ActivityTranslationWorker {
	if cfg.BatchSize <= 0 {
		cfg.BatchSize = 10
	}
	if cfg.PollInterval <= 0 {
		cfg.PollInterval = 2 * time.Second
	}
	if cfg.RequestTimeout <= 0 {
		cfg.RequestTimeout = 8 * time.Second
	}
	if cfg.RetryBaseDelay <= 0 {
		cfg.RetryBaseDelay = 30 * time.Second
	}
	if cfg.LockTimeout <= 0 {
		cfg.LockTimeout = 2 * time.Minute
	}
	minimumLockTimeout := time.Duration(cfg.BatchSize)*cfg.RequestTimeout + cfg.PollInterval
	if cfg.LockTimeout < minimumLockTimeout {
		cfg.LockTimeout = minimumLockTimeout
	}
	if strings.TrimSpace(cfg.WorkerID) == "" {
		cfg.WorkerID = "activity-translation-worker"
	}
	if metrics == nil {
		metrics = noopActivityTranslationWorkerMetrics{}
	}
	return &ActivityTranslationWorker{
		cfg:        cfg,
		jobs:       jobs,
		translator: translator,
		metrics:    metrics,
		now:        func() time.Time { return time.Now().UTC() },
	}
}

func (w *ActivityTranslationWorker) Run(ctx context.Context) error {
	if w == nil || !w.cfg.Enabled {
		return nil
	}
	if w.jobs == nil {
		return errors.New("activity translation job repository is required")
	}
	if w.translator == nil {
		return errors.New("activity translator is required")
	}

	ticker := time.NewTicker(w.cfg.PollInterval)
	defer ticker.Stop()
	for {
		if _, err := w.ProcessBatch(ctx); err != nil && !errors.Is(err, context.Canceled) {
			log.Error().Err(err).Msg("activity translation batch failed")
		}
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
		}
	}
}

func (w *ActivityTranslationWorker) ProcessBatch(ctx context.Context) (int, error) {
	jobs, err := w.jobs.ClaimActivityTranslationJobs(
		ctx,
		w.cfg.WorkerID,
		w.cfg.BatchSize,
		w.cfg.LockTimeout,
	)
	if err != nil {
		return 0, err
	}

	var batchErr error
	for index := range jobs {
		if err = w.processJob(ctx, jobs[index]); err != nil {
			if errors.Is(err, context.Canceled) {
				return index, err
			}
			batchErr = errors.Join(batchErr, err)
		}
	}
	if stats, statsErr := w.jobs.GetActivityTranslationQueueStats(ctx); statsErr != nil {
		batchErr = errors.Join(batchErr, statsErr)
	} else {
		w.metrics.SetQueueStats(stats)
	}
	return len(jobs), batchErr
}

func (w *ActivityTranslationWorker) processJob(
	ctx context.Context,
	job model.ActivityTranslationJob,
) error {
	startedAt := w.now()
	fields, texts := orderedActivityTranslationSourceFields(job.SourceFields)
	if len(fields) == 0 {
		return w.failJob(ctx, job, false, "invalid_source_fields", startedAt)
	}

	requestCtx, cancel := context.WithTimeout(ctx, w.cfg.RequestTimeout)
	result, err := w.translator.TranslateTexts(requestCtx, port.ActivityTranslationRequest{
		SourceLocale:    job.SourceLanguage,
		TargetLocales:   []string{job.TargetLanguage},
		Texts:           texts,
		AllowIncomplete: true,
	})
	cancel()
	if err != nil {
		if errors.Is(err, context.Canceled) && errors.Is(ctx.Err(), context.Canceled) {
			return context.Canceled
		}
		retryable, code := classifyActivityTranslationError(err)
		return w.failJob(ctx, job, retryable, code, startedAt)
	}

	items := result.Items[job.TargetLanguage]
	if len(items) != len(fields) {
		return w.failJob(ctx, job, false, "invalid_translation_response", startedAt)
	}
	translatedFields := make(map[string]string, len(fields))
	provider := strings.TrimSpace(result.Provider)
	for index, item := range items {
		if provider == "" {
			provider = strings.TrimSpace(item.Provider)
		}
		if !activityTranslationTextStatusSucceeded(item.Status) {
			return w.failJob(
				ctx,
				job,
				activityTranslationTextStatusRetryable(item.Status),
				activityTranslationStatusErrorCode(item.Status),
				startedAt,
			)
		}
		translated := strings.TrimSpace(item.Text)
		if translated == "" {
			return w.failJob(ctx, job, false, "empty_translation", startedAt)
		}
		translatedFields[fields[index]] = translated
	}

	applyResult, err := w.jobs.ApplyActivityTranslationJob(ctx, job.ID, translatedFields, provider)
	if err != nil {
		return fmt.Errorf("apply activity translation job %s: %w", job.ID, err)
	}
	duration := w.now().Sub(startedAt)
	w.metrics.ObserveDuration(duration)
	switch applyResult {
	case model.ActivityTranslationApplied:
		w.metrics.RecordCompleted()
		if w.onApplied != nil {
			w.onApplied(ctx, job.ActivityID)
		}
		log.Info().
			Str("job_id", job.ID.String()).
			Str("activity_id", job.ActivityID.String()).
			Str("source_language", job.SourceLanguage).
			Str("target_language", job.TargetLanguage).
			Str("source_hash", job.SourceHash).
			Int("attempt", job.Attempts+1).
			Str("status", string(model.ActivityTranslationJobCompleted)).
			Str("provider", provider).
			Int64("duration_ms", duration.Milliseconds()).
			Msg("activity translation job completed")
	case model.ActivityTranslationStale:
		w.metrics.RecordStale()
		log.Info().
			Str("job_id", job.ID.String()).
			Str("activity_id", job.ActivityID.String()).
			Str("source_language", job.SourceLanguage).
			Str("target_language", job.TargetLanguage).
			Str("source_hash", job.SourceHash).
			Int("attempt", job.Attempts+1).
			Str("status", string(model.ActivityTranslationJobStale)).
			Str("provider", provider).
			Int64("duration_ms", duration.Milliseconds()).
			Msg("activity translation job became stale")
	}
	return nil
}

func (w *ActivityTranslationWorker) failJob(
	ctx context.Context,
	job model.ActivityTranslationJob,
	retryable bool,
	errorCode string,
	startedAt time.Time,
) error {
	now := w.now()
	nextRunAt := nextActivityTranslationRetry(w.cfg.RetryBaseDelay, job.Attempts, now)
	if err := w.jobs.FailActivityTranslationJob(
		ctx,
		job.ID,
		retryable,
		nextRunAt,
		errorCode,
	); err != nil {
		return fmt.Errorf("record activity translation job failure %s: %w", job.ID, err)
	}
	finalFailure := !retryable || job.Attempts+1 >= job.MaxAttempts
	status := model.ActivityTranslationJobPending
	if finalFailure {
		status = model.ActivityTranslationJobFailed
		w.metrics.RecordFailed()
	}
	duration := now.Sub(startedAt)
	w.metrics.ObserveDuration(duration)
	log.Warn().
		Str("job_id", job.ID.String()).
		Str("activity_id", job.ActivityID.String()).
		Str("source_language", job.SourceLanguage).
		Str("target_language", job.TargetLanguage).
		Str("source_hash", job.SourceHash).
		Int("attempt", job.Attempts+1).
		Str("status", string(status)).
		Int64("duration_ms", duration.Milliseconds()).
		Str("error_code", errorCode).
		Msg("activity translation job was not completed")
	return nil
}

func orderedActivityTranslationSourceFields(sourceFields map[string]string) ([]string, []string) {
	fields := make([]string, 0, 2)
	texts := make([]string, 0, 2)
	for _, field := range []string{"title", "description"} {
		value := strings.TrimSpace(sourceFields[field])
		if value == "" {
			continue
		}
		fields = append(fields, field)
		texts = append(texts, value)
	}
	return fields, texts
}

func classifyActivityTranslationError(err error) (bool, string) {
	type retryableError interface{ Retryable() bool }
	type codedError interface{ Code() string }

	code := "translation_service_error"
	var coded codedError
	if errors.As(err, &coded) && strings.TrimSpace(coded.Code()) != "" {
		code = coded.Code()
	}
	var retryable retryableError
	if errors.As(err, &retryable) {
		return retryable.Retryable(), code
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return true, "request_timeout"
	}
	return true, code
}

func activityTranslationTextStatusSucceeded(status port.ActivityTranslationTextStatus) bool {
	switch status {
	case port.ActivityTranslationTextTranslated,
		port.ActivityTranslationTextCached,
		port.ActivityTranslationTextSameLanguage:
		return true
	default:
		return false
	}
}

func activityTranslationTextStatusRetryable(status port.ActivityTranslationTextStatus) bool {
	switch status {
	case port.ActivityTranslationTextQuotaExhausted,
		port.ActivityTranslationTextDisabled,
		port.ActivityTranslationTextProviderUnavailable:
		return true
	default:
		return false
	}
}

func activityTranslationStatusErrorCode(status port.ActivityTranslationTextStatus) string {
	code := strings.TrimSpace(string(status))
	if code == "" {
		return "invalid_translation_status"
	}
	return code
}

func nextActivityTranslationRetry(base time.Duration, attempts int, now time.Time) time.Time {
	if base <= 0 {
		base = 30 * time.Second
	}
	if attempts < 0 {
		attempts = 0
	}
	if attempts > 6 {
		attempts = 6
	}
	return now.Add(time.Duration(1<<attempts) * base)
}
