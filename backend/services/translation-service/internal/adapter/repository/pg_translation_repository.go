package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/translation-service/internal/domain/model"
)

type PGTranslationRepository struct {
	pool *pgxpool.Pool
}

func NewPGTranslationRepository(pool *pgxpool.Pool) *PGTranslationRepository {
	return &PGTranslationRepository{pool: pool}
}

func (r *PGTranslationRepository) GetCachedTranslation(ctx context.Context, key model.CacheKey) (model.CachedTranslation, bool, error) {
	const query = `
SELECT
    normalized_source_text,
    translated_text,
    provider,
    provider_model_label,
    quality_status,
    created_at,
    updated_at
FROM translation_cache
WHERE provider = $1
  AND source_language = $2
  AND target_language = $3
  AND glossary_version = $4
  AND source_hash = $5
LIMIT 1
`
	var entry model.CachedTranslation
	entry.Key = key
	var qualityStatus string
	if err := r.pool.QueryRow(
		ctx,
		query,
		key.Provider,
		string(key.SourceLanguage),
		string(key.TargetLanguage),
		key.GlossaryVersion,
		key.SourceHash,
	).Scan(
		&entry.NormalizedSourceText,
		&entry.TranslatedText,
		&entry.Provider,
		&entry.ProviderModelLabel,
		&qualityStatus,
		&entry.CreatedAt,
		&entry.UpdatedAt,
	); err != nil {
		if err == pgx.ErrNoRows {
			return model.CachedTranslation{}, false, nil
		}
		return model.CachedTranslation{}, false, fmt.Errorf("get cached translation: %w", err)
	}
	entry.QualityStatus = model.QualityStatus(qualityStatus)
	return entry, true, nil
}

func (r *PGTranslationRepository) UpsertCachedTranslation(ctx context.Context, entry model.CachedTranslation) error {
	const query = `
INSERT INTO translation_cache (
    provider,
    source_language,
    target_language,
    glossary_version,
    source_hash,
    normalized_source_text,
    translated_text,
    provider_model_label,
    quality_status,
    created_at,
    updated_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
ON CONFLICT (provider, source_language, target_language, glossary_version, source_hash)
DO UPDATE SET
    normalized_source_text = EXCLUDED.normalized_source_text,
    translated_text = EXCLUDED.translated_text,
    provider_model_label = EXCLUDED.provider_model_label,
    quality_status = EXCLUDED.quality_status,
    updated_at = EXCLUDED.updated_at
`
	_, err := r.pool.Exec(
		ctx,
		query,
		entry.Key.Provider,
		string(entry.Key.SourceLanguage),
		string(entry.Key.TargetLanguage),
		entry.Key.GlossaryVersion,
		entry.Key.SourceHash,
		entry.NormalizedSourceText,
		entry.TranslatedText,
		entry.ProviderModelLabel,
		string(entry.QualityStatus),
		entry.CreatedAt,
		entry.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("upsert cached translation: %w", err)
	}
	return nil
}

func (r *PGTranslationRepository) ReserveMonthlyUsage(ctx context.Context, reservation model.UsageReservation) (model.UsageReservationResult, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return model.UsageReservationResult{}, fmt.Errorf("begin monthly translation usage reservation: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()
	warningLimit := quotaThresholdCharacters(reservation.MonthlyLimit, reservation.QuotaWarningThreshold)
	criticalLimit := quotaThresholdCharacters(reservation.MonthlyLimit, reservation.QuotaCriticalThreshold)

	const upsertQuery = `
INSERT INTO translation_usage_monthly (
    provider,
    environment,
    year_month,
    source_language,
    target_language,
    content_type,
    billing_mode,
    monthly_limit,
    warning_threshold,
    critical_threshold,
    updated_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
ON CONFLICT (provider, environment, year_month, source_language, target_language, content_type)
DO UPDATE SET
    billing_mode = EXCLUDED.billing_mode,
    monthly_limit = EXCLUDED.monthly_limit,
    warning_threshold = EXCLUDED.warning_threshold,
    critical_threshold = EXCLUDED.critical_threshold,
    warning_reached = CASE
        WHEN EXCLUDED.monthly_limit > 0 THEN translation_usage_monthly.reserved_characters >= CEIL(EXCLUDED.monthly_limit * EXCLUDED.warning_threshold)
        ELSE false
    END,
    critical_reached = CASE
        WHEN EXCLUDED.monthly_limit > 0 THEN translation_usage_monthly.reserved_characters >= CEIL(EXCLUDED.monthly_limit * EXCLUDED.critical_threshold)
        ELSE false
    END,
    updated_at = EXCLUDED.updated_at
`
	_, err = tx.Exec(
		ctx,
		upsertQuery,
		reservation.Provider,
		reservation.Environment,
		reservation.YearMonth,
		string(reservation.SourceLanguage),
		string(reservation.TargetLanguage),
		string(reservation.ContentType),
		string(reservation.BillingMode),
		reservation.MonthlyLimit,
		reservation.QuotaWarningThreshold,
		reservation.QuotaCriticalThreshold,
		reservation.ReservedAt,
	)
	if err != nil {
		return model.UsageReservationResult{}, fmt.Errorf("upsert monthly translation usage row: %w", err)
	}

	const reserveQuery = `
UPDATE translation_usage_monthly
SET
    reserved_characters = reserved_characters + $7,
    warning_reached = CASE
        WHEN $9 > 0 THEN (reserved_characters + $7) >= $9
        ELSE false
    END,
    critical_reached = CASE
        WHEN $10 > 0 THEN (reserved_characters + $7) >= $10
        ELSE false
    END,
    updated_at = $11
WHERE provider = $1
  AND environment = $2
  AND year_month = $3
  AND source_language = $4
  AND target_language = $5
  AND content_type = $6
  AND ($8 <= 0 OR reserved_characters + $7 <= $8)
RETURNING reserved_characters, monthly_limit, warning_reached, critical_reached
`
	var result model.UsageReservationResult
	err = tx.QueryRow(
		ctx,
		reserveQuery,
		reservation.Provider,
		reservation.Environment,
		reservation.YearMonth,
		string(reservation.SourceLanguage),
		string(reservation.TargetLanguage),
		string(reservation.ContentType),
		reservation.Characters,
		reservation.MonthlyLimit,
		warningLimit,
		criticalLimit,
		reservation.ReservedAt,
	).Scan(
		&result.UsedCharacters,
		&result.LimitCharacters,
		&result.WarningReached,
		&result.CriticalReached,
	)
	switch {
	case err == nil:
		result.Allowed = true
		result.ReservedCharacters = reservation.Characters
	case errors.Is(err, pgx.ErrNoRows):
		const currentQuery = `
SELECT reserved_characters, monthly_limit, warning_reached, critical_reached
FROM translation_usage_monthly
WHERE provider = $1
  AND environment = $2
  AND year_month = $3
  AND source_language = $4
  AND target_language = $5
  AND content_type = $6
`
		if scanErr := tx.QueryRow(
			ctx,
			currentQuery,
			reservation.Provider,
			reservation.Environment,
			reservation.YearMonth,
			string(reservation.SourceLanguage),
			string(reservation.TargetLanguage),
			string(reservation.ContentType),
		).Scan(
			&result.UsedCharacters,
			&result.LimitCharacters,
			&result.WarningReached,
			&result.CriticalReached,
		); scanErr != nil {
			return model.UsageReservationResult{}, fmt.Errorf("get current monthly translation usage: %w", scanErr)
		}
	default:
		return model.UsageReservationResult{}, fmt.Errorf("reserve monthly translation usage: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return model.UsageReservationResult{}, fmt.Errorf("commit monthly translation usage reservation: %w", err)
	}
	return result, nil
}

func quotaThresholdCharacters(monthlyLimit int, threshold float64) int {
	if monthlyLimit <= 0 || threshold <= 0 {
		return 0
	}
	return int(math.Ceil(float64(monthlyLimit) * threshold))
}

func (r *PGTranslationRepository) CommitMonthlyUsage(ctx context.Context, commit model.UsageCommit) error {
	const query = `
UPDATE translation_usage_monthly
SET
    billed_characters = billed_characters + $7,
    request_count = request_count + $8,
    updated_at = $9
WHERE provider = $1
  AND environment = $2
  AND year_month = $3
  AND source_language = $4
  AND target_language = $5
  AND content_type = $6
`
	_, err := r.pool.Exec(
		ctx,
		query,
		commit.Provider,
		commit.Environment,
		commit.YearMonth,
		string(commit.SourceLanguage),
		string(commit.TargetLanguage),
		string(commit.ContentType),
		commit.BilledCharacters,
		commit.RequestCount,
		commit.CommittedAt,
	)
	if err != nil {
		return fmt.Errorf("commit monthly translation usage: %w", err)
	}
	return nil
}

func (r *PGTranslationRepository) ReleaseMonthlyUsage(ctx context.Context, release model.UsageRelease) error {
	const query = `
UPDATE translation_usage_monthly
SET
    reserved_characters = GREATEST(reserved_characters - $7, 0),
    warning_reached = CASE
        WHEN monthly_limit > 0 THEN GREATEST(reserved_characters - $7, 0) >= CEIL(monthly_limit * warning_threshold)
        ELSE false
    END,
    critical_reached = CASE
        WHEN monthly_limit > 0 THEN GREATEST(reserved_characters - $7, 0) >= CEIL(monthly_limit * critical_threshold)
        ELSE false
    END,
    updated_at = $8
WHERE provider = $1
  AND environment = $2
  AND year_month = $3
  AND source_language = $4
  AND target_language = $5
  AND content_type = $6
`
	_, err := r.pool.Exec(
		ctx,
		query,
		release.Provider,
		release.Environment,
		release.YearMonth,
		string(release.SourceLanguage),
		string(release.TargetLanguage),
		string(release.ContentType),
		release.Characters,
		release.ReleasedAt,
	)
	if err != nil {
		return fmt.Errorf("release monthly translation usage: %w", err)
	}
	return nil
}

func (r *PGTranslationRepository) CreateTranslationJob(ctx context.Context, job model.TranslationJob) (model.TranslationJob, bool, error) {
	textsJSON, err := json.Marshal(job.Texts)
	if err != nil {
		return model.TranslationJob{}, false, fmt.Errorf("marshal translation job texts: %w", err)
	}
	resultJSON, err := json.Marshal(job.Result)
	if err != nil {
		return model.TranslationJob{}, false, fmt.Errorf("marshal translation job result: %w", err)
	}
	const query = `
INSERT INTO translation_jobs (
    id,
    idempotency_key,
    source_language,
    target_languages,
    content_type,
    texts,
    status,
    result,
    attempt_count,
    next_attempt_at,
    created_at,
    updated_at
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 1, $9, $9, $9)
ON CONFLICT (idempotency_key) DO NOTHING
RETURNING
    id,
    idempotency_key,
    source_language,
    target_languages,
    content_type,
    texts,
    status,
    result,
    COALESCE(error_code, ''),
    COALESCE(error_message, ''),
    attempt_count,
    created_at,
    updated_at,
    completed_at
`
	created, err := scanTranslationJob(r.pool.QueryRow(
		ctx,
		query,
		job.ID,
		job.IdempotencyKey,
		string(job.SourceLanguage),
		languagesToStrings(job.TargetLanguages),
		string(job.ContentType),
		textsJSON,
		string(job.Status),
		resultJSON,
		job.CreatedAt,
	))
	if err == nil {
		return created, true, nil
	}
	if err != pgx.ErrNoRows {
		return model.TranslationJob{}, false, fmt.Errorf("insert translation job: %w", err)
	}

	existing, ok, err := r.getTranslationJobByIdempotencyKey(ctx, job.IdempotencyKey)
	if err != nil {
		return model.TranslationJob{}, false, err
	}
	if !ok {
		return model.TranslationJob{}, false, fmt.Errorf("translation job idempotency conflict disappeared")
	}
	return existing, false, nil
}

func (r *PGTranslationRepository) CompleteTranslationJob(ctx context.Context, completion model.TranslationJobCompletion) (model.TranslationJob, error) {
	resultJSON, err := json.Marshal(completion.Result)
	if err != nil {
		return model.TranslationJob{}, fmt.Errorf("marshal translation job result: %w", err)
	}
	const query = `
UPDATE translation_jobs
SET
    status = 'completed',
    result = $2,
    error_code = NULL,
    error_message = NULL,
    completed_at = $3,
    updated_at = $3
WHERE id = $1
RETURNING
    id,
    idempotency_key,
    source_language,
    target_languages,
    content_type,
    texts,
    status,
    result,
    COALESCE(error_code, ''),
    COALESCE(error_message, ''),
    attempt_count,
    created_at,
    updated_at,
    completed_at
`
	job, err := scanTranslationJob(r.pool.QueryRow(ctx, query, completion.ID, resultJSON, completion.CompletedAt))
	if err != nil {
		return model.TranslationJob{}, fmt.Errorf("complete translation job: %w", err)
	}
	return job, nil
}

func (r *PGTranslationRepository) FailTranslationJob(ctx context.Context, failure model.TranslationJobFailure) (model.TranslationJob, error) {
	const query = `
UPDATE translation_jobs
SET
    status = 'failed',
    error_code = $2,
    error_message = $3,
    updated_at = $4
WHERE id = $1
RETURNING
    id,
    idempotency_key,
    source_language,
    target_languages,
    content_type,
    texts,
    status,
    result,
    COALESCE(error_code, ''),
    COALESCE(error_message, ''),
    attempt_count,
    created_at,
    updated_at,
    completed_at
`
	job, err := scanTranslationJob(r.pool.QueryRow(ctx, query, failure.ID, failure.ErrorCode, failure.ErrorMessage, failure.FailedAt))
	if err != nil {
		return model.TranslationJob{}, fmt.Errorf("fail translation job: %w", err)
	}
	return job, nil
}

func (r *PGTranslationRepository) GetTranslationJob(ctx context.Context, id string) (model.TranslationJob, bool, error) {
	const query = `
SELECT
    id,
    idempotency_key,
    source_language,
    target_languages,
    content_type,
    texts,
    status,
    result,
    COALESCE(error_code, ''),
    COALESCE(error_message, ''),
    attempt_count,
    created_at,
    updated_at,
    completed_at
FROM translation_jobs
WHERE id = $1
LIMIT 1
`
	job, err := scanTranslationJob(r.pool.QueryRow(ctx, query, id))
	if err != nil {
		if err == pgx.ErrNoRows {
			return model.TranslationJob{}, false, nil
		}
		return model.TranslationJob{}, false, fmt.Errorf("get translation job: %w", err)
	}
	return job, true, nil
}

func (r *PGTranslationRepository) GetMonthlyUsage(ctx context.Context, provider string, environment string, yearMonth string) ([]model.MonthlyUsageRow, error) {
	const query = `
SELECT
    provider,
    environment,
    year_month,
    source_language,
    target_language,
    content_type,
    billing_mode,
    reserved_characters,
    billed_characters,
    request_count,
    monthly_limit,
    warning_reached,
    critical_reached
FROM translation_usage_monthly
WHERE provider = $1
  AND environment = $2
  AND year_month = $3
ORDER BY source_language, target_language, content_type
`
	rows, err := r.pool.Query(ctx, query, provider, environment, yearMonth)
	if err != nil {
		return nil, fmt.Errorf("query monthly translation usage: %w", err)
	}
	defer rows.Close()

	result := make([]model.MonthlyUsageRow, 0)
	for rows.Next() {
		var row model.MonthlyUsageRow
		var sourceLanguage, targetLanguage, contentType, billingMode string
		if err := rows.Scan(
			&row.Provider,
			&row.Environment,
			&row.YearMonth,
			&sourceLanguage,
			&targetLanguage,
			&contentType,
			&billingMode,
			&row.ReservedCharacters,
			&row.BilledCharacters,
			&row.RequestCount,
			&row.MonthlyLimit,
			&row.WarningReached,
			&row.CriticalReached,
		); err != nil {
			return nil, fmt.Errorf("scan monthly translation usage: %w", err)
		}
		row.SourceLanguage = model.Language(sourceLanguage)
		row.TargetLanguage = model.Language(targetLanguage)
		row.ContentType = model.ContentType(contentType)
		row.BillingMode = model.BillingMode(billingMode)
		result = append(result, row)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate monthly translation usage: %w", err)
	}
	return result, nil
}

func (r *PGTranslationRepository) getTranslationJobByIdempotencyKey(ctx context.Context, idempotencyKey string) (model.TranslationJob, bool, error) {
	const query = `
SELECT
    id,
    idempotency_key,
    source_language,
    target_languages,
    content_type,
    texts,
    status,
    result,
    COALESCE(error_code, ''),
    COALESCE(error_message, ''),
    attempt_count,
    created_at,
    updated_at,
    completed_at
FROM translation_jobs
WHERE idempotency_key = $1
LIMIT 1
`
	job, err := scanTranslationJob(r.pool.QueryRow(ctx, query, idempotencyKey))
	if err != nil {
		if err == pgx.ErrNoRows {
			return model.TranslationJob{}, false, nil
		}
		return model.TranslationJob{}, false, fmt.Errorf("get translation job by idempotency key: %w", err)
	}
	return job, true, nil
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanTranslationJob(row rowScanner) (model.TranslationJob, error) {
	var job model.TranslationJob
	var sourceLanguage, contentType, status string
	var targetLanguages []string
	var textsJSON []byte
	var resultJSON []byte
	var completedAt pgtype.Timestamptz
	if err := row.Scan(
		&job.ID,
		&job.IdempotencyKey,
		&sourceLanguage,
		&targetLanguages,
		&contentType,
		&textsJSON,
		&status,
		&resultJSON,
		&job.ErrorCode,
		&job.ErrorMessage,
		&job.AttemptCount,
		&job.CreatedAt,
		&job.UpdatedAt,
		&completedAt,
	); err != nil {
		return model.TranslationJob{}, err
	}
	if len(textsJSON) > 0 {
		if err := json.Unmarshal(textsJSON, &job.Texts); err != nil {
			return model.TranslationJob{}, fmt.Errorf("unmarshal translation job texts: %w", err)
		}
	}
	job.Result = map[model.Language][]model.TranslatedText{}
	if len(resultJSON) > 0 {
		if err := json.Unmarshal(resultJSON, &job.Result); err != nil {
			return model.TranslationJob{}, fmt.Errorf("unmarshal translation job result: %w", err)
		}
	}
	job.SourceLanguage = model.Language(sourceLanguage)
	job.TargetLanguages = stringsToLanguages(targetLanguages)
	job.ContentType = model.ContentType(contentType)
	job.Status = model.TranslationJobStatus(status)
	if completedAt.Valid {
		value := completedAt.Time
		job.CompletedAt = &value
	}
	return job, nil
}

func languagesToStrings(values []model.Language) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		result = append(result, string(value))
	}
	return result
}

func stringsToLanguages(values []string) []model.Language {
	result := make([]model.Language, 0, len(values))
	for _, value := range values {
		result = append(result, model.Language(value))
	}
	return result
}
