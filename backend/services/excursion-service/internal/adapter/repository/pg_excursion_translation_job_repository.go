package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
)

const maxExcursionTranslationJobErrorLength = 512

const enqueueExcursionTranslationJobQuery = `
	INSERT INTO excursion_translation_jobs (
		id, excursion_id, entity_type, entity_id,
		source_language, target_language, source_fields, source_hash,
		status, attempts, max_attempts, next_run_at, created_at, updated_at
	) VALUES (
		$1, $2, $3, $4,
		$5, $6, $7::jsonb, $8,
		$9, $10, $11, $12, $13, $14
	)
	ON CONFLICT (entity_type, entity_id, target_language, source_hash) DO UPDATE
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
	WHERE excursion_translation_jobs.status = 'FAILED'
`

const claimExcursionTranslationJobsQuery = `
	WITH picked AS (
		SELECT id
		FROM excursion_translation_jobs
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
	UPDATE excursion_translation_jobs AS job
	SET status = 'PROCESSING',
	    locked_at = NOW(),
	    locked_by = $2,
	    updated_at = NOW()
	FROM picked
	WHERE job.id = picked.id
	RETURNING
		job.id, job.excursion_id, job.entity_type, job.entity_id,
		job.source_language, job.target_language, job.source_fields, job.source_hash,
		job.status, job.attempts, job.max_attempts, job.next_run_at,
		job.locked_at, job.locked_by, job.last_error, job.provider,
		job.created_at, job.updated_at, job.completed_at
`

const failExcursionTranslationJobQuery = `
	UPDATE excursion_translation_jobs
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
	RETURNING excursion_id
`

func (r *PGExcursionRepository) EnqueueExcursionTranslationJobs(
	ctx context.Context,
	jobs []model.ExcursionTranslationJob,
) error {
	if len(jobs) == 0 {
		return nil
	}
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin enqueue excursion translation jobs tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err = enqueueExcursionTranslationJobs(ctx, tx, jobs); err != nil {
		return err
	}
	for _, excursionID := range uniqueTranslationJobExcursionIDs(jobs) {
		if err = refreshExcursionTranslationStatus(ctx, tx, excursionID); err != nil {
			return err
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit enqueue excursion translation jobs tx: %w", err)
	}
	return nil
}

func enqueueExcursionTranslationJobs(
	ctx context.Context,
	exec dbExecutor,
	jobs []model.ExcursionTranslationJob,
) error {
	for _, job := range jobs {
		sourceFields, err := json.Marshal(job.SourceFields)
		if err != nil {
			return fmt.Errorf("encode excursion translation job source fields: %w", err)
		}
		if _, err = exec.Exec(
			ctx,
			enqueueExcursionTranslationJobQuery,
			job.ID,
			job.ExcursionID,
			string(job.EntityType),
			job.EntityID,
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
			return fmt.Errorf("enqueue excursion translation job: %w", err)
		}
	}
	return nil
}

func (r *PGExcursionRepository) MarkExcursionTranslationJobsStale(
	ctx context.Context,
	excursionID uuid.UUID,
	entityIDs []uuid.UUID,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin stale excursion translation jobs tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if err = markExcursionTranslationJobsStale(ctx, tx, excursionID, entityIDs); err != nil {
		return err
	}
	if err = refreshExcursionTranslationStatus(ctx, tx, excursionID); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit stale excursion translation jobs tx: %w", err)
	}
	return nil
}

func markExcursionTranslationJobsStale(
	ctx context.Context,
	exec dbExecutor,
	excursionID uuid.UUID,
	entityIDs []uuid.UUID,
) error {
	query := `
		UPDATE excursion_translation_jobs
		SET status = 'STALE',
		    locked_at = NULL,
		    locked_by = NULL,
		    updated_at = NOW()
		WHERE excursion_id = $1
		  AND status IN ('PENDING', 'PROCESSING')
	`
	args := []any{excursionID}
	if len(entityIDs) > 0 {
		query += " AND entity_id = ANY($2::uuid[])"
		args = append(args, entityIDs)
	}
	if _, err := exec.Exec(ctx, query, args...); err != nil {
		return fmt.Errorf("mark excursion translation jobs stale: %w", err)
	}
	return nil
}

func (r *PGExcursionRepository) ClaimExcursionTranslationJobs(
	ctx context.Context,
	workerID string,
	limit int,
	lockTimeout time.Duration,
) ([]model.ExcursionTranslationJob, error) {
	if limit <= 0 {
		limit = 10
	}
	if lockTimeout <= 0 {
		lockTimeout = 2 * time.Minute
	}
	rows, err := r.pool.Query(ctx, claimExcursionTranslationJobsQuery, limit, strings.TrimSpace(workerID), lockTimeout.String())
	if err != nil {
		return nil, fmt.Errorf("claim excursion translation jobs: %w", err)
	}
	defer rows.Close()

	jobs := make([]model.ExcursionTranslationJob, 0, limit)
	for rows.Next() {
		job, scanErr := scanExcursionTranslationJob(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan claimed excursion translation job: %w", scanErr)
		}
		jobs = append(jobs, job)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate claimed excursion translation jobs: %w", err)
	}
	return jobs, nil
}

func (r *PGExcursionRepository) ApplyExcursionTranslationJob(
	ctx context.Context,
	jobID uuid.UUID,
	translatedFields map[string]string,
	provider string,
) (model.ExcursionTranslationApplyResult, error) {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return model.ExcursionTranslationNoop, fmt.Errorf("begin apply excursion translation job tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	job, err := scanExcursionTranslationJob(tx.QueryRow(ctx, `
		SELECT id, excursion_id, entity_type, entity_id,
		       source_language, target_language, source_fields, source_hash,
		       status, attempts, max_attempts, next_run_at,
		       locked_at, locked_by, last_error, provider,
		       created_at, updated_at, completed_at
		FROM excursion_translation_jobs
		WHERE id = $1 AND status = 'PROCESSING'
		FOR UPDATE
	`, jobID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return model.ExcursionTranslationNoop, nil
		}
		return model.ExcursionTranslationNoop, fmt.Errorf("load excursion translation job for apply: %w", err)
	}

	if job.EntityType != model.ExcursionTranslationEntityItineraryItem {
		return model.ExcursionTranslationNoop, fmt.Errorf("unsupported excursion translation entity type %q", job.EntityType)
	}

	var (
		baseTitle       string
		baseDescription string
		translationsRaw []byte
	)
	err = tx.QueryRow(ctx, `
		SELECT title, description, translations
		FROM excursion_itinerary_items
		WHERE id = $1 AND excursion_id = $2
		FOR UPDATE
	`, job.EntityID, job.ExcursionID).Scan(&baseTitle, &baseDescription, &translationsRaw)
	if err != nil {
		if err == pgx.ErrNoRows {
			if err = markExcursionTranslationJobStale(ctx, tx, job.ID); err != nil {
				return model.ExcursionTranslationNoop, err
			}
			if err = refreshExcursionTranslationStatus(ctx, tx, job.ExcursionID); err != nil {
				return model.ExcursionTranslationNoop, err
			}
			if err = tx.Commit(ctx); err != nil {
				return model.ExcursionTranslationNoop, fmt.Errorf("commit missing-entity stale translation job: %w", err)
			}
			return model.ExcursionTranslationStale, nil
		}
		return model.ExcursionTranslationNoop, fmt.Errorf("load itinerary item for translation: %w", err)
	}

	translations := scanExcursionItineraryTranslations(translationsRaw)
	currentItem := &model.ExcursionItineraryItem{
		Title:        baseTitle,
		Description:  baseDescription,
		Translations: translations,
	}
	sourceCopy := currentItem.SourceCopyForLanguage(job.SourceLanguage)
	currentHash := model.HashExcursionTranslationSource(job.SourceLanguage, map[string]string{
		"title":       sourceCopy.Title,
		"description": sourceCopy.Description,
	})
	if currentHash != job.SourceHash {
		if err = markExcursionTranslationJobStale(ctx, tx, job.ID); err != nil {
			return model.ExcursionTranslationNoop, err
		}
		if err = refreshExcursionTranslationStatus(ctx, tx, job.ExcursionID); err != nil {
			return model.ExcursionTranslationNoop, err
		}
		if err = tx.Commit(ctx); err != nil {
			return model.ExcursionTranslationNoop, fmt.Errorf("commit source-hash stale translation job: %w", err)
		}
		return model.ExcursionTranslationStale, nil
	}

	if translations == nil {
		translations = make(model.ExcursionItineraryTranslations)
	}
	targetCopy := translations[job.TargetLanguage]
	if strings.TrimSpace(targetCopy.Title) == "" {
		targetCopy.Title = strings.TrimSpace(translatedFields["title"])
	}
	if strings.TrimSpace(targetCopy.Description) == "" {
		targetCopy.Description = strings.TrimSpace(translatedFields["description"])
	}
	translations[job.TargetLanguage] = targetCopy
	translations = model.NormalizeExcursionItineraryTranslations(translations)
	encodedTranslations, err := json.Marshal(translations)
	if err != nil {
		return model.ExcursionTranslationNoop, fmt.Errorf("encode itinerary translations: %w", err)
	}
	if _, err = tx.Exec(ctx, `
		UPDATE excursion_itinerary_items
		SET translations = $2::jsonb, updated_at = NOW()
		WHERE id = $1
	`, job.EntityID, encodedTranslations); err != nil {
		return model.ExcursionTranslationNoop, fmt.Errorf("apply itinerary translation: %w", err)
	}

	if err = completeExcursionTranslationJob(ctx, tx, job.ID, provider); err != nil {
		return model.ExcursionTranslationNoop, err
	}
	if err = refreshExcursionTranslationStatus(ctx, tx, job.ExcursionID); err != nil {
		return model.ExcursionTranslationNoop, err
	}
	if err = tx.Commit(ctx); err != nil {
		return model.ExcursionTranslationNoop, fmt.Errorf("commit apply excursion translation job: %w", err)
	}
	return model.ExcursionTranslationApplied, nil
}

func (r *PGExcursionRepository) CompleteExcursionTranslationJob(
	ctx context.Context,
	jobID uuid.UUID,
	provider string,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin complete excursion translation job tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	var excursionID uuid.UUID
	err = tx.QueryRow(ctx, `
		UPDATE excursion_translation_jobs
		SET status = 'COMPLETED', provider = $2, completed_at = NOW(),
		    locked_at = NULL, locked_by = NULL, updated_at = NOW()
		WHERE id = $1 AND status = 'PROCESSING'
		RETURNING excursion_id
	`, jobID, strings.TrimSpace(provider)).Scan(&excursionID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil
		}
		return fmt.Errorf("complete excursion translation job: %w", err)
	}
	if err = refreshExcursionTranslationStatus(ctx, tx, excursionID); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit complete excursion translation job tx: %w", err)
	}
	return nil
}

func completeExcursionTranslationJob(ctx context.Context, exec dbExecutor, jobID uuid.UUID, provider string) error {
	tag, err := exec.Exec(ctx, `
		UPDATE excursion_translation_jobs
		SET status = 'COMPLETED', provider = $2, completed_at = NOW(),
		    locked_at = NULL, locked_by = NULL, updated_at = NOW()
		WHERE id = $1 AND status = 'PROCESSING'
	`, jobID, strings.TrimSpace(provider))
	if err != nil {
		return fmt.Errorf("complete excursion translation job: %w", err)
	}
	if tag.RowsAffected() != 1 {
		return fmt.Errorf("complete excursion translation job: processing job not found")
	}
	return nil
}

func (r *PGExcursionRepository) FailExcursionTranslationJob(
	ctx context.Context,
	jobID uuid.UUID,
	retryable bool,
	nextRunAt time.Time,
	lastError string,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin fail excursion translation job tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	lastError = truncateTranslationJobError(lastError)
	var excursionID uuid.UUID
	err = tx.QueryRow(
		ctx,
		failExcursionTranslationJobQuery,
		jobID,
		retryable,
		nextRunAt.UTC(),
		lastError,
	).Scan(&excursionID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil
		}
		return fmt.Errorf("fail excursion translation job: %w", err)
	}
	if err = refreshExcursionTranslationStatus(ctx, tx, excursionID); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit fail excursion translation job tx: %w", err)
	}
	return nil
}

func (r *PGExcursionRepository) MarkExcursionTranslationJobStale(ctx context.Context, jobID uuid.UUID) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin stale excursion translation job tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	var excursionID uuid.UUID
	err = tx.QueryRow(ctx, `
		UPDATE excursion_translation_jobs
		SET status = 'STALE', locked_at = NULL, locked_by = NULL, updated_at = NOW()
		WHERE id = $1 AND status IN ('PENDING', 'PROCESSING')
		RETURNING excursion_id
	`, jobID).Scan(&excursionID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil
		}
		return fmt.Errorf("mark excursion translation job stale: %w", err)
	}
	if err = refreshExcursionTranslationStatus(ctx, tx, excursionID); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit stale excursion translation job tx: %w", err)
	}
	return nil
}

func markExcursionTranslationJobStale(ctx context.Context, exec dbExecutor, jobID uuid.UUID) error {
	if _, err := exec.Exec(ctx, `
		UPDATE excursion_translation_jobs
		SET status = 'STALE', locked_at = NULL, locked_by = NULL, updated_at = NOW()
		WHERE id = $1 AND status IN ('PENDING', 'PROCESSING')
	`, jobID); err != nil {
		return fmt.Errorf("mark excursion translation job stale: %w", err)
	}
	return nil
}

func (r *PGExcursionRepository) GetExcursionTranslationQueueStats(
	ctx context.Context,
) (model.ExcursionTranslationQueueStats, error) {
	var stats model.ExcursionTranslationQueueStats
	err := r.pool.QueryRow(ctx, `
		SELECT
			COUNT(*) FILTER (WHERE status = 'PENDING')::bigint,
			COUNT(*) FILTER (WHERE status = 'PROCESSING')::bigint,
			COALESCE(EXTRACT(EPOCH FROM (NOW() - MIN(created_at) FILTER (WHERE status = 'PENDING'))), 0)::float8
		FROM excursion_translation_jobs
	`).Scan(&stats.PendingCount, &stats.ProcessingCount, &stats.OldestPendingAgeSeconds)
	if err != nil {
		return model.ExcursionTranslationQueueStats{}, fmt.Errorf("get excursion translation queue stats: %w", err)
	}
	return stats, nil
}

func (r *PGExcursionRepository) ListExcursionTranslationBackfillCandidates(
	ctx context.Context,
	afterID uuid.UUID,
	limit int,
) ([]model.ExcursionTranslationBackfillCandidate, error) {
	if limit <= 0 {
		limit = 100
	}
	rows, err := r.pool.Query(ctx, `
		WITH candidates AS (
			SELECT excursion.id, excursion.source_language
			FROM excursions AS excursion
			WHERE excursion.deleted_at IS NULL
			  AND ($1::uuid = '00000000-0000-0000-0000-000000000000'::uuid OR excursion.id > $1)
			  AND EXISTS (
				SELECT 1
				FROM excursion_itinerary_items AS candidate_item
				WHERE candidate_item.excursion_id = excursion.id
			  )
			ORDER BY excursion.id ASC
			LIMIT $2
		)
		SELECT candidate.id, candidate.source_language,
		       item.id, item.excursion_id, item.sort_order, item.start_offset_minutes, item.duration_minutes,
		       item.place_id, item.place_name, item.latitude, item.longitude, item.travel_from_previous_minutes,
		       item.title, item.description, item.translations, item.created_at, item.updated_at
		FROM candidates AS candidate
		JOIN excursion_itinerary_items AS item ON item.excursion_id = candidate.id
		ORDER BY candidate.id ASC, item.sort_order ASC, item.start_offset_minutes ASC
	`, afterID, limit)
	if err != nil {
		return nil, fmt.Errorf("list excursion translation backfill candidates: %w", err)
	}
	defer rows.Close()

	candidates := make([]model.ExcursionTranslationBackfillCandidate, 0, limit)
	indexes := make(map[uuid.UUID]int, limit)
	for rows.Next() {
		var (
			excursionID     uuid.UUID
			sourceLanguage  string
			item            model.ExcursionItineraryItem
			translationsRaw []byte
		)
		if err = rows.Scan(
			&excursionID,
			&sourceLanguage,
			&item.ID,
			&item.ExcursionID,
			&item.SortOrder,
			&item.StartOffsetMinutes,
			&item.DurationMinutes,
			&item.PlaceID,
			&item.PlaceName,
			&item.Latitude,
			&item.Longitude,
			&item.TravelFromPreviousMinutes,
			&item.Title,
			&item.Description,
			&translationsRaw,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan excursion translation backfill candidate: %w", err)
		}
		item.Translations = scanExcursionItineraryTranslations(translationsRaw)
		candidateIndex, exists := indexes[excursionID]
		if !exists {
			candidateIndex = len(candidates)
			indexes[excursionID] = candidateIndex
			candidates = append(candidates, model.ExcursionTranslationBackfillCandidate{
				ExcursionID:    excursionID,
				SourceLanguage: sourceLanguage,
				Itinerary:      make([]*model.ExcursionItineraryItem, 0, 4),
			})
		}
		itemCopy := item
		candidates[candidateIndex].Itinerary = append(candidates[candidateIndex].Itinerary, &itemCopy)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate excursion translation backfill candidates: %w", err)
	}
	return candidates, nil
}

func listCurrentExcursionTranslationJobs(
	ctx context.Context,
	queryer dbQueryExecutor,
	excursionID uuid.UUID,
) ([]model.ExcursionTranslationJob, error) {
	rows, err := queryer.Query(ctx, `
		SELECT job.id, job.excursion_id, job.entity_type, job.entity_id,
		       job.source_language, job.target_language, job.source_fields, job.source_hash,
		       job.status, job.attempts, job.max_attempts, job.next_run_at,
		       job.locked_at, job.locked_by, job.last_error, job.provider,
		       job.created_at, job.updated_at, job.completed_at
		FROM excursion_translation_jobs AS job
		JOIN excursion_itinerary_items AS item
		  ON item.id = job.entity_id
		 AND item.excursion_id = job.excursion_id
		WHERE job.excursion_id = $1
		  AND job.entity_type = 'itinerary_item'
		ORDER BY job.created_at ASC, job.id ASC
	`, excursionID)
	if err != nil {
		return nil, fmt.Errorf("list current excursion translation jobs: %w", err)
	}
	defer rows.Close()

	jobs := make([]model.ExcursionTranslationJob, 0)
	for rows.Next() {
		job, scanErr := scanExcursionTranslationJob(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan current excursion translation job: %w", scanErr)
		}
		jobs = append(jobs, job)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate current excursion translation jobs: %w", err)
	}
	return jobs, nil
}

func refreshExcursionTranslationStatus(ctx context.Context, exec dbExecutor, excursionID uuid.UUID) error {
	if _, err := exec.Exec(ctx, `
		WITH current_jobs AS (
			SELECT job.status
			FROM excursion_translation_jobs AS job
			JOIN excursion_itinerary_items AS item
			  ON item.id = job.entity_id
			 AND item.excursion_id = job.excursion_id
			WHERE job.excursion_id = $1
			  AND job.entity_type = 'itinerary_item'
		), job_counts AS (
			SELECT
				COUNT(*)::int AS total,
				COUNT(*) FILTER (WHERE status IN ('PENDING', 'PROCESSING'))::int AS active,
				COUNT(*) FILTER (WHERE status = 'COMPLETED')::int AS completed,
				COUNT(*) FILTER (WHERE status = 'FAILED')::int AS failed
			FROM current_jobs
		)
		UPDATE excursions
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
		WHERE excursions.id = $1
	`, excursionID); err != nil {
		return fmt.Errorf("refresh excursion translation status: %w", err)
	}
	return nil
}

func scanExcursionTranslationJob(row excursionScanner) (model.ExcursionTranslationJob, error) {
	var (
		job             model.ExcursionTranslationJob
		entityTypeRaw   string
		statusRaw       string
		sourceFieldsRaw []byte
	)
	err := row.Scan(
		&job.ID,
		&job.ExcursionID,
		&entityTypeRaw,
		&job.EntityID,
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
		return model.ExcursionTranslationJob{}, err
	}
	if err = json.Unmarshal(sourceFieldsRaw, &job.SourceFields); err != nil {
		return model.ExcursionTranslationJob{}, fmt.Errorf("decode source fields: %w", err)
	}
	job.EntityType = model.ExcursionTranslationEntityType(entityTypeRaw)
	job.Status = model.ExcursionTranslationJobStatus(statusRaw)
	return job, nil
}

func uniqueTranslationJobExcursionIDs(jobs []model.ExcursionTranslationJob) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(jobs))
	result := make([]uuid.UUID, 0, len(jobs))
	for _, job := range jobs {
		if job.ExcursionID == uuid.Nil {
			continue
		}
		if _, exists := seen[job.ExcursionID]; exists {
			continue
		}
		seen[job.ExcursionID] = struct{}{}
		result = append(result, job.ExcursionID)
	}
	return result
}

func truncateTranslationJobError(value string) string {
	value = strings.TrimSpace(value)
	if len(value) <= maxExcursionTranslationJobErrorLength {
		return value
	}
	return value[:maxExcursionTranslationJobErrorLength]
}
