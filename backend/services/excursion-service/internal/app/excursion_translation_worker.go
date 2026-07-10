package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

type ExcursionTranslationWorkerConfig struct {
	Enabled        bool
	WorkerID       string
	BatchSize      int
	PollInterval   time.Duration
	RequestTimeout time.Duration
	RetryBaseDelay time.Duration
	LockTimeout    time.Duration
}

type ExcursionTranslationWorkerMetrics interface {
	SetQueueStats(stats model.ExcursionTranslationQueueStats)
	RecordCompleted()
	RecordFailed()
	RecordStale()
	ObserveDuration(duration time.Duration)
}

type noopExcursionTranslationWorkerMetrics struct{}

func (noopExcursionTranslationWorkerMetrics) SetQueueStats(model.ExcursionTranslationQueueStats) {}
func (noopExcursionTranslationWorkerMetrics) RecordCompleted()                                   {}
func (noopExcursionTranslationWorkerMetrics) RecordFailed()                                      {}
func (noopExcursionTranslationWorkerMetrics) RecordStale()                                       {}
func (noopExcursionTranslationWorkerMetrics) ObserveDuration(time.Duration)                      {}

type ExcursionTranslationWorker struct {
	cfg        ExcursionTranslationWorkerConfig
	jobs       port.ExcursionTranslationJobRepository
	translator port.ExcursionTranslator
	metrics    ExcursionTranslationWorkerMetrics
	now        func() time.Time
}

func NewExcursionTranslationWorker(
	cfg ExcursionTranslationWorkerConfig,
	jobs port.ExcursionTranslationJobRepository,
	translator port.ExcursionTranslator,
	metrics ExcursionTranslationWorkerMetrics,
) *ExcursionTranslationWorker {
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
		cfg.WorkerID = "excursion-translation-worker"
	}
	if metrics == nil {
		metrics = noopExcursionTranslationWorkerMetrics{}
	}
	return &ExcursionTranslationWorker{
		cfg:        cfg,
		jobs:       jobs,
		translator: translator,
		metrics:    metrics,
		now:        func() time.Time { return time.Now().UTC() },
	}
}

func (w *ExcursionTranslationWorker) Run(ctx context.Context) error {
	if w == nil || !w.cfg.Enabled {
		return nil
	}
	if w.jobs == nil {
		return errors.New("excursion translation job repository is required")
	}
	if w.translator == nil {
		return errors.New("excursion translator is required")
	}

	ticker := time.NewTicker(w.cfg.PollInterval)
	defer ticker.Stop()
	for {
		if _, err := w.ProcessBatch(ctx); err != nil && !errors.Is(err, context.Canceled) {
			log.Error().Err(err).Msg("excursion translation batch failed")
		}
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
		}
	}
}

func (w *ExcursionTranslationWorker) ProcessBatch(ctx context.Context) (int, error) {
	jobs, err := w.jobs.ClaimExcursionTranslationJobs(
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
	if stats, statsErr := w.jobs.GetExcursionTranslationQueueStats(ctx); statsErr != nil {
		batchErr = errors.Join(batchErr, statsErr)
	} else {
		w.metrics.SetQueueStats(stats)
	}
	return len(jobs), batchErr
}

func (w *ExcursionTranslationWorker) processJob(ctx context.Context, job model.ExcursionTranslationJob) error {
	startedAt := w.now()
	fields, texts := orderedTranslationSourceFields(job.SourceFields)
	if len(fields) == 0 {
		return w.failJob(ctx, job, false, "invalid_source_fields", startedAt)
	}

	requestCtx, cancel := context.WithTimeout(ctx, w.cfg.RequestTimeout)
	result, err := w.translator.TranslateTexts(requestCtx, port.TranslationRequest{
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
		retryable, code := classifyTranslationError(err)
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
		if !translationTextStatusSucceeded(item.Status) {
			return w.failJob(
				ctx,
				job,
				translationTextStatusRetryable(item.Status),
				translationStatusErrorCode(item.Status),
				startedAt,
			)
		}
		translated := strings.TrimSpace(item.Text)
		if translated == "" {
			return w.failJob(ctx, job, false, "empty_translation", startedAt)
		}
		translatedFields[fields[index]] = translated
	}

	applyResult, err := w.jobs.ApplyExcursionTranslationJob(ctx, job.ID, translatedFields, provider)
	if err != nil {
		return fmt.Errorf("apply excursion translation job %s: %w", job.ID, err)
	}
	duration := w.now().Sub(startedAt)
	w.metrics.ObserveDuration(duration)
	switch applyResult {
	case model.ExcursionTranslationApplied:
		w.metrics.RecordCompleted()
		log.Info().
			Str("job_id", job.ID.String()).
			Str("excursion_id", job.ExcursionID.String()).
			Str("entity_type", string(job.EntityType)).
			Str("entity_id", job.EntityID.String()).
			Str("source_language", job.SourceLanguage).
			Str("target_language", job.TargetLanguage).
			Str("source_hash", job.SourceHash).
			Int("attempt", job.Attempts+1).
			Str("status", string(model.ExcursionTranslationJobCompleted)).
			Str("provider", provider).
			Int64("duration_ms", duration.Milliseconds()).
			Msg("excursion translation job completed")
	case model.ExcursionTranslationStale:
		w.metrics.RecordStale()
		log.Info().
			Str("job_id", job.ID.String()).
			Str("excursion_id", job.ExcursionID.String()).
			Str("entity_type", string(job.EntityType)).
			Str("entity_id", job.EntityID.String()).
			Str("source_language", job.SourceLanguage).
			Str("target_language", job.TargetLanguage).
			Str("source_hash", job.SourceHash).
			Int("attempt", job.Attempts+1).
			Str("status", string(model.ExcursionTranslationJobStale)).
			Str("provider", provider).
			Int64("duration_ms", duration.Milliseconds()).
			Msg("excursion translation job became stale")
	}
	return nil
}

func (w *ExcursionTranslationWorker) failJob(
	ctx context.Context,
	job model.ExcursionTranslationJob,
	retryable bool,
	errorCode string,
	startedAt time.Time,
) error {
	now := w.now()
	nextRunAt := nextTranslationRetry(w.cfg.RetryBaseDelay, job.Attempts, now)
	if err := w.jobs.FailExcursionTranslationJob(ctx, job.ID, retryable, nextRunAt, errorCode); err != nil {
		return fmt.Errorf("record excursion translation job failure %s: %w", job.ID, err)
	}
	finalFailure := !retryable || job.Attempts+1 >= job.MaxAttempts
	status := model.ExcursionTranslationJobPending
	if finalFailure {
		status = model.ExcursionTranslationJobFailed
		w.metrics.RecordFailed()
	}
	duration := now.Sub(startedAt)
	w.metrics.ObserveDuration(duration)
	log.Warn().
		Str("job_id", job.ID.String()).
		Str("excursion_id", job.ExcursionID.String()).
		Str("entity_type", string(job.EntityType)).
		Str("entity_id", job.EntityID.String()).
		Str("source_language", job.SourceLanguage).
		Str("target_language", job.TargetLanguage).
		Str("source_hash", job.SourceHash).
		Int("attempt", job.Attempts+1).
		Str("status", string(status)).
		Int64("duration_ms", duration.Milliseconds()).
		Str("error_code", errorCode).
		Msg("excursion translation job was not completed")
	return nil
}

func orderedTranslationSourceFields(sourceFields map[string]string) ([]string, []string) {
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

func classifyTranslationError(err error) (bool, string) {
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

func translationTextStatusSucceeded(status port.TranslationTextStatus) bool {
	switch status {
	case port.TranslationTextTranslated, port.TranslationTextCached, port.TranslationTextSameLanguage:
		return true
	default:
		return false
	}
}

func translationTextStatusRetryable(status port.TranslationTextStatus) bool {
	switch status {
	case port.TranslationTextQuotaExhausted,
		port.TranslationTextDisabled,
		port.TranslationTextProviderUnavailable:
		return true
	default:
		return false
	}
}

func translationStatusErrorCode(status port.TranslationTextStatus) string {
	code := strings.TrimSpace(string(status))
	if code == "" {
		return "invalid_translation_status"
	}
	return code
}

func nextTranslationRetry(base time.Duration, attempts int, now time.Time) time.Time {
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
