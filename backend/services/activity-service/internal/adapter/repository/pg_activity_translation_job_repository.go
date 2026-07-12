package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

const maxActivityTranslationJobErrorLength = 512

const enqueueActivityTranslationJobQuery = `
	INSERT INTO activity_translation_jobs (
		id, activity_id, source_language, target_language,
		source_fields, source_hash, status, attempts, max_attempts,
		next_run_at, created_at, updated_at
	) VALUES (
		$1, $2, $3, $4,
		$5::jsonb, $6, $7, $8, $9,
		$10, $11, $12
	)
	ON CONFLICT (activity_id, target_language, source_hash) DO UPDATE
	SET status = 'PENDING',
	    source_language = EXCLUDED.source_language,
	    source_fields = EXCLUDED.source_fields,
	    attempts = 0,
	    max_attempts = EXCLUDED.max_attempts,
	    next_run_at = EXCLUDED.next_run_at,
	    locked_at = NULL,
	    locked_by = NULL,
	    last_error = NULL,
	    provider = NULL,
	    completed_at = NULL,
	    updated_at = NOW()
	WHERE activity_translation_jobs.status IN ('FAILED', 'STALE', 'CANCELLED')
`

const claimActivityTranslationJobsQuery = `
	WITH picked AS (
		SELECT id
		FROM activity_translation_jobs
		WHERE (
			status = 'PENDING'
			AND next_run_at <= NOW()
		) OR (
			status = 'PROCESSING'
			AND locked_at <= NOW() - $3::interval
		)
		ORDER BY next_run_at ASC, created_at ASC
		LIMIT $1
		FOR UPDATE SKIP LOCKED
	)
	UPDATE activity_translation_jobs AS job
	SET status = 'PROCESSING',
	    locked_at = NOW(),
	    locked_by = $2,
	    updated_at = NOW()
	FROM picked
	WHERE job.id = picked.id
	RETURNING
		job.id, job.activity_id, job.source_language, job.target_language,
		job.source_fields, job.source_hash, job.status,
		job.attempts, job.max_attempts, job.next_run_at,
		job.locked_at, job.locked_by, job.last_error, job.provider,
		job.created_at, job.updated_at, job.completed_at
`

func (r *PGActivityRepository) CreateActivityWithTranslationJobs(
	ctx context.Context,
	activity *model.Activity,
	jobs []model.ActivityTranslationJob,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin create activity with translation jobs tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err = insertActivity(ctx, tx, activity); err != nil {
		return err
	}
	if err = enqueueActivityTranslationJobs(ctx, tx, jobs); err != nil {
		return err
	}
	if len(jobs) > 0 {
		if err = refreshActivityTranslationStatus(ctx, tx, activity.ID); err != nil {
			return err
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit create activity with translation jobs tx: %w", err)
	}
	return nil
}

func (r *PGActivityRepository) UpdateActivityWithTranslationJobs(
	ctx context.Context,
	activity *model.Activity,
	jobs []model.ActivityTranslationJob,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin update activity with translation jobs tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err = updateActivity(ctx, tx, activity); err != nil {
		return err
	}
	currentHash := model.HashActivityTranslationSource(activity.SourceLanguage, map[string]string{
		"title":       activity.Title,
		"description": activity.Description,
	})
	if _, err = tx.Exec(ctx, `
		UPDATE activity_translation_jobs
		SET status = 'STALE', locked_at = NULL, locked_by = NULL, updated_at = NOW()
		WHERE activity_id = $1
		  AND source_hash <> $2
		  AND status NOT IN ('STALE', 'CANCELLED')
	`, activity.ID, currentHash); err != nil {
		return fmt.Errorf("mark previous activity translation jobs stale: %w", err)
	}
	translations, err := json.Marshal(model.NormalizeActivityTranslations(activity.Translations))
	if err != nil {
		return fmt.Errorf("encode reset activity translations: %w", err)
	}
	if _, err = tx.Exec(ctx, `
		UPDATE activities
		SET source_language = $2,
		    translation_status = $3,
		    translations = $4::jsonb
		WHERE id = $1
	`, activity.ID, activity.SourceLanguage, string(activity.TranslationStatus), translations); err != nil {
		return fmt.Errorf("reset activity translations: %w", err)
	}
	if err = enqueueActivityTranslationJobs(ctx, tx, jobs); err != nil {
		return err
	}
	if len(jobs) > 0 {
		if err = refreshActivityTranslationStatus(ctx, tx, activity.ID); err != nil {
			return err
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit update activity with translation jobs tx: %w", err)
	}
	return nil
}

func (r *PGActivityRepository) EnqueueActivityTranslationJobs(
	ctx context.Context,
	jobs []model.ActivityTranslationJob,
) error {
	if len(jobs) == 0 {
		return nil
	}
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin enqueue activity translation jobs tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err = enqueueActivityTranslationJobs(ctx, tx, jobs); err != nil {
		return err
	}
	for _, activityID := range uniqueTranslationJobActivityIDs(jobs) {
		if err = refreshActivityTranslationStatus(ctx, tx, activityID); err != nil {
			return err
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit enqueue activity translation jobs tx: %w", err)
	}
	return nil
}

func enqueueActivityTranslationJobs(
	ctx context.Context,
	exec activityDBExecutor,
	jobs []model.ActivityTranslationJob,
) error {
	for _, job := range jobs {
		sourceFields, err := json.Marshal(job.SourceFields)
		if err != nil {
			return fmt.Errorf("encode activity translation job source fields: %w", err)
		}
		if _, err = exec.Exec(
			ctx,
			enqueueActivityTranslationJobQuery,
			job.ID,
			job.ActivityID,
			job.SourceLanguage,
			job.TargetLanguage,
			sourceFields,
			job.SourceHash,
			string(job.Status),
			job.Attempts,
			job.MaxAttempts,
			job.NextRunAt,
			job.CreatedAt,
			job.UpdatedAt,
		); err != nil {
			return fmt.Errorf("enqueue activity translation job: %w", err)
		}
	}
	return nil
}

func (r *PGActivityRepository) ClaimActivityTranslationJobs(
	ctx context.Context,
	workerID string,
	limit int,
	lockTimeout time.Duration,
) ([]model.ActivityTranslationJob, error) {
	if limit <= 0 {
		limit = 10
	}
	if lockTimeout <= 0 {
		lockTimeout = 2 * time.Minute
	}
	rows, err := r.pool.Query(
		ctx,
		claimActivityTranslationJobsQuery,
		limit,
		strings.TrimSpace(workerID),
		lockTimeout.String(),
	)
	if err != nil {
		return nil, fmt.Errorf("claim activity translation jobs: %w", err)
	}
	defer rows.Close()

	jobs := make([]model.ActivityTranslationJob, 0, limit)
	for rows.Next() {
		job, scanErr := scanActivityTranslationJob(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan claimed activity translation job: %w", scanErr)
		}
		jobs = append(jobs, job)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate claimed activity translation jobs: %w", err)
	}
	return jobs, nil
}

func (r *PGActivityRepository) ApplyActivityTranslationJob(
	ctx context.Context,
	jobID uuid.UUID,
	translatedFields map[string]string,
	provider string,
) (model.ActivityTranslationApplyResult, error) {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return model.ActivityTranslationNoop, fmt.Errorf("begin apply activity translation job tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	job, err := scanActivityTranslationJob(tx.QueryRow(ctx, `
		SELECT id, activity_id, source_language, target_language,
		       source_fields, source_hash, status,
		       attempts, max_attempts, next_run_at,
		       locked_at, locked_by, last_error, provider,
		       created_at, updated_at, completed_at
		FROM activity_translation_jobs
		WHERE id = $1 AND status = 'PROCESSING'
		FOR UPDATE
	`, jobID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return model.ActivityTranslationNoop, nil
		}
		return model.ActivityTranslationNoop, fmt.Errorf("load activity translation job for apply: %w", err)
	}

	var (
		title           string
		description     string
		sourceLanguage  string
		translationsRaw []byte
	)
	err = tx.QueryRow(ctx, `
		SELECT title, description, source_language, translations
		FROM activities
		WHERE id = $1
		FOR UPDATE
	`, job.ActivityID).Scan(&title, &description, &sourceLanguage, &translationsRaw)
	if err != nil {
		if err == pgx.ErrNoRows {
			if err = markActivityTranslationJobStale(ctx, tx, job.ID); err != nil {
				return model.ActivityTranslationNoop, err
			}
			if err = tx.Commit(ctx); err != nil {
				return model.ActivityTranslationNoop, fmt.Errorf("commit missing activity stale translation job: %w", err)
			}
			return model.ActivityTranslationStale, nil
		}
		return model.ActivityTranslationNoop, fmt.Errorf("load activity for translation apply: %w", err)
	}
	currentHash := model.HashActivityTranslationSource(sourceLanguage, map[string]string{
		"title":       title,
		"description": description,
	})
	if currentHash != job.SourceHash {
		if err = markActivityTranslationJobStale(ctx, tx, job.ID); err != nil {
			return model.ActivityTranslationNoop, err
		}
		if err = refreshActivityTranslationStatus(ctx, tx, job.ActivityID); err != nil {
			return model.ActivityTranslationNoop, err
		}
		if err = tx.Commit(ctx); err != nil {
			return model.ActivityTranslationNoop, fmt.Errorf("commit source-hash stale activity translation job: %w", err)
		}
		return model.ActivityTranslationStale, nil
	}

	translations := make(model.ActivityTranslations)
	if len(translationsRaw) > 0 {
		if err = json.Unmarshal(translationsRaw, &translations); err != nil {
			return model.ActivityTranslationNoop, fmt.Errorf("decode activity translations: %w", err)
		}
	}
	targetCopy := translations[job.TargetLanguage]
	if strings.TrimSpace(targetCopy.Title) == "" {
		targetCopy.Title = strings.TrimSpace(translatedFields["title"])
	}
	if strings.TrimSpace(targetCopy.Description) == "" {
		targetCopy.Description = strings.TrimSpace(translatedFields["description"])
	}
	translations[job.TargetLanguage] = targetCopy
	translations = model.NormalizeActivityTranslations(translations)
	encodedTranslations, err := json.Marshal(translations)
	if err != nil {
		return model.ActivityTranslationNoop, fmt.Errorf("encode activity translations: %w", err)
	}
	if _, err = tx.Exec(ctx, `
		UPDATE activities
		SET translations = $2::jsonb,
		    revision = revision + 1,
		    updated_at = NOW()
		WHERE id = $1
	`, job.ActivityID, encodedTranslations); err != nil {
		return model.ActivityTranslationNoop, fmt.Errorf("apply activity translation: %w", err)
	}
	if _, err = tx.Exec(ctx, `
		UPDATE activity_translation_jobs
		SET status = 'COMPLETED', provider = $2, completed_at = NOW(),
		    locked_at = NULL, locked_by = NULL, updated_at = NOW()
		WHERE id = $1 AND status = 'PROCESSING'
	`, job.ID, strings.TrimSpace(provider)); err != nil {
		return model.ActivityTranslationNoop, fmt.Errorf("complete activity translation job: %w", err)
	}
	if err = refreshActivityTranslationStatus(ctx, tx, job.ActivityID); err != nil {
		return model.ActivityTranslationNoop, err
	}
	if err = tx.Commit(ctx); err != nil {
		return model.ActivityTranslationNoop, fmt.Errorf("commit apply activity translation job: %w", err)
	}
	return model.ActivityTranslationApplied, nil
}

func (r *PGActivityRepository) FailActivityTranslationJob(
	ctx context.Context,
	jobID uuid.UUID,
	retryable bool,
	nextRunAt time.Time,
	lastError string,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin fail activity translation job tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	lastError = truncateActivityTranslationJobError(lastError)
	var activityID uuid.UUID
	err = tx.QueryRow(ctx, `
		UPDATE activity_translation_jobs
		SET status = CASE
		        WHEN attempts + 1 >= max_attempts OR $2 = FALSE THEN 'FAILED'
		        ELSE 'PENDING'
		    END,
		    attempts = attempts + 1,
		    next_run_at = $3,
		    last_error = $4,
		    locked_at = NULL,
		    locked_by = NULL,
		    updated_at = NOW()
		WHERE id = $1 AND status = 'PROCESSING'
		RETURNING activity_id
	`, jobID, retryable, nextRunAt.UTC(), lastError).Scan(&activityID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil
		}
		return fmt.Errorf("fail activity translation job: %w", err)
	}
	if err = refreshActivityTranslationStatus(ctx, tx, activityID); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit fail activity translation job tx: %w", err)
	}
	return nil
}

func (r *PGActivityRepository) GetActivityTranslationQueueStats(
	ctx context.Context,
) (model.ActivityTranslationQueueStats, error) {
	var stats model.ActivityTranslationQueueStats
	err := r.pool.QueryRow(ctx, `
		SELECT
			COUNT(*) FILTER (WHERE status = 'PENDING')::bigint,
			COUNT(*) FILTER (WHERE status = 'PROCESSING')::bigint,
			COALESCE(EXTRACT(EPOCH FROM (NOW() - MIN(created_at) FILTER (WHERE status = 'PENDING'))), 0)::float8
		FROM activity_translation_jobs
	`).Scan(&stats.PendingCount, &stats.ProcessingCount, &stats.OldestPendingAgeSeconds)
	if err != nil {
		return model.ActivityTranslationQueueStats{}, fmt.Errorf("get activity translation queue stats: %w", err)
	}
	return stats, nil
}

func (r *PGActivityRepository) ListActivityTranslationBackfillCandidates(
	ctx context.Context,
	afterID uuid.UUID,
	limit int,
) ([]model.ActivityTranslationBackfillCandidate, error) {
	if limit <= 0 {
		limit = 100
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, source_language, title, description, translations
		FROM activities
		WHERE ($1::uuid = '00000000-0000-0000-0000-000000000000'::uuid OR id > $1)
		  AND EXISTS (
			SELECT 1
			FROM unnest(ARRAY['ru', 'kk', 'en']) AS locale
			WHERE locale <> source_language
			  AND (
				NULLIF(BTRIM(translations -> locale ->> 'title'), '') IS NULL
				OR NULLIF(BTRIM(translations -> locale ->> 'description'), '') IS NULL
			  )
		  )
		ORDER BY id ASC
		LIMIT $2
	`, afterID, limit)
	if err != nil {
		return nil, fmt.Errorf("list activity translation backfill candidates: %w", err)
	}
	defer rows.Close()

	candidates := make([]model.ActivityTranslationBackfillCandidate, 0, limit)
	for rows.Next() {
		var candidate model.ActivityTranslationBackfillCandidate
		var translationsRaw []byte
		if err = rows.Scan(
			&candidate.ActivityID,
			&candidate.SourceLanguage,
			&candidate.Title,
			&candidate.Description,
			&translationsRaw,
		); err != nil {
			return nil, fmt.Errorf("scan activity translation backfill candidate: %w", err)
		}
		if err = json.Unmarshal(translationsRaw, &candidate.Translations); err != nil {
			return nil, fmt.Errorf("decode activity translation backfill candidate: %w", err)
		}
		candidate.Translations = model.NormalizeActivityTranslations(candidate.Translations)
		candidates = append(candidates, candidate)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate activity translation backfill candidates: %w", err)
	}
	return candidates, nil
}

func refreshActivityTranslationStatus(ctx context.Context, exec activityDBExecutor, activityID uuid.UUID) error {
	if _, err := exec.Exec(ctx, `
		WITH current_jobs AS (
			SELECT job.status
			FROM activity_translation_jobs AS job
			JOIN activities AS activity ON activity.id = job.activity_id
			WHERE job.activity_id = $1
			  AND job.source_language = activity.source_language
			  AND BTRIM(job.source_fields ->> 'title') = BTRIM(activity.title)
			  AND BTRIM(job.source_fields ->> 'description') = BTRIM(activity.description)
		), job_counts AS (
			SELECT
				COUNT(*)::int AS total,
				COUNT(*) FILTER (WHERE status IN ('PENDING', 'PROCESSING'))::int AS active,
				COUNT(*) FILTER (WHERE status = 'COMPLETED')::int AS completed,
				COUNT(*) FILTER (WHERE status = 'FAILED')::int AS failed
			FROM current_jobs
		)
		UPDATE activities
		SET translation_status = CASE
				WHEN job_counts.total = 0 THEN 'NONE'
				WHEN job_counts.active > 0 AND job_counts.completed > 0 THEN 'PARTIAL'
				WHEN job_counts.active > 0 THEN 'PENDING'
				WHEN job_counts.failed > 0 THEN 'FAILED'
				WHEN job_counts.completed = job_counts.total THEN 'COMPLETED'
				ELSE 'NONE'
			END,
			updated_at = NOW()
		FROM job_counts
		WHERE activities.id = $1
	`, activityID); err != nil {
		return fmt.Errorf("refresh activity translation status: %w", err)
	}
	return nil
}

func markActivityTranslationJobStale(
	ctx context.Context,
	exec activityDBExecutor,
	jobID uuid.UUID,
) error {
	if _, err := exec.Exec(ctx, `
		UPDATE activity_translation_jobs
		SET status = 'STALE', locked_at = NULL, locked_by = NULL, updated_at = NOW()
		WHERE id = $1 AND status IN ('PENDING', 'PROCESSING')
	`, jobID); err != nil {
		return fmt.Errorf("mark activity translation job stale: %w", err)
	}
	return nil
}

func scanActivityTranslationJob(row activityScanner) (model.ActivityTranslationJob, error) {
	var (
		job             model.ActivityTranslationJob
		statusRaw       string
		sourceFieldsRaw []byte
	)
	err := row.Scan(
		&job.ID,
		&job.ActivityID,
		&job.SourceLanguage,
		&job.TargetLanguage,
		&sourceFieldsRaw,
		&job.SourceHash,
		&statusRaw,
		&job.Attempts,
		&job.MaxAttempts,
		&job.NextRunAt,
		&job.LockedAt,
		&job.LockedBy,
		&job.LastError,
		&job.Provider,
		&job.CreatedAt,
		&job.UpdatedAt,
		&job.CompletedAt,
	)
	if err != nil {
		return model.ActivityTranslationJob{}, err
	}
	if err = json.Unmarshal(sourceFieldsRaw, &job.SourceFields); err != nil {
		return model.ActivityTranslationJob{}, fmt.Errorf("decode activity translation source fields: %w", err)
	}
	job.Status = model.ActivityTranslationJobStatus(statusRaw)
	return job, nil
}

func uniqueTranslationJobActivityIDs(jobs []model.ActivityTranslationJob) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(jobs))
	result := make([]uuid.UUID, 0, len(jobs))
	for _, job := range jobs {
		if job.ActivityID == uuid.Nil {
			continue
		}
		if _, exists := seen[job.ActivityID]; exists {
			continue
		}
		seen[job.ActivityID] = struct{}{}
		result = append(result, job.ActivityID)
	}
	return result
}

func truncateActivityTranslationJobError(value string) string {
	value = strings.TrimSpace(value)
	if len(value) <= maxActivityTranslationJobErrorLength {
		return value
	}
	return value[:maxActivityTranslationJobErrorLength]
}
