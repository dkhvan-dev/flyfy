package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/activity-service/internal/adapter/savedcontract"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

const activitySavedLifecycleOutboxMaxBatch = 100

func enqueueActivitySavedLifecycleTransition(
	ctx context.Context,
	exec activityDBExecutor,
	before *model.Activity,
	after *model.Activity,
	beforeMedia []*model.ActivityMedia,
	afterMedia []*model.ActivityMedia,
	occurredAt time.Time,
) error {
	event, err := savedcontract.BuildActivityLifecycleEvent(
		before,
		after,
		beforeMedia,
		afterMedia,
		occurredAt,
	)
	if err != nil {
		return fmt.Errorf("build activity Saved lifecycle event: %w", err)
	}
	if event == nil {
		return nil
	}

	const query = `
		INSERT INTO activity_saved_lifecycle_outbox (
			id,
			activity_id,
			subject,
			schema_version,
			event_kind,
			visibility,
			source_revision,
			projection_revision,
			visibility_revision,
			has_public_projection,
			payload,
			next_attempt_at,
			occurred_at,
			created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11::jsonb, $12, $13, $12
		)
		ON CONFLICT ON CONSTRAINT uq_activity_saved_lifecycle_semantic_event DO NOTHING
	`
	now := time.Now().UTC()
	if now.Before(event.OccurredAt) {
		now = event.OccurredAt
	}
	if _, err = exec.Exec(
		ctx,
		query,
		event.ID,
		event.ActivityID,
		event.Subject,
		event.SchemaVersion,
		string(event.Kind),
		event.Visibility,
		event.SourceRevision,
		event.ProjectionRevision,
		event.VisibilityRevision,
		event.HasPublicProjection,
		event.Payload,
		now,
		event.OccurredAt,
	); err != nil {
		return fmt.Errorf("insert activity Saved lifecycle outbox event: %w", err)
	}
	return nil
}

func getActivityForUpdate(
	ctx context.Context,
	exec activityDBExecutor,
	activityID uuid.UUID,
) (*model.Activity, error) {
	query := `
		SELECT
	` + activitySelectColumns + `
		FROM activities
		WHERE id = $1
		FOR UPDATE
	`
	item, err := scanActivity(exec.QueryRow(ctx, query, activityID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get activity for Saved lifecycle update: %w", err)
	}
	return item, nil
}

func (r *PGActivityRepository) ClaimActivitySavedLifecycleEvents(
	ctx context.Context,
	workerID string,
	limit int,
	now time.Time,
	leaseDuration time.Duration,
) ([]model.ActivitySavedLifecycleOutboxEvent, error) {
	workerID = strings.TrimSpace(workerID)
	if workerID == "" || len(workerID) > 200 {
		return nil, fmt.Errorf("invalid activity Saved lifecycle worker id")
	}
	if limit <= 0 || limit > activitySavedLifecycleOutboxMaxBatch {
		limit = 50
	}
	if now.IsZero() {
		now = time.Now().UTC()
	} else {
		now = now.UTC()
	}
	if leaseDuration <= 0 || leaseDuration > 10*time.Minute {
		leaseDuration = 30 * time.Second
	}
	leaseUntil := now.Add(leaseDuration)

	rows, err := r.pool.Query(ctx, `
		WITH candidates AS (
			SELECT id, status = 'PROCESSING' AS recovered_lease
			FROM activity_saved_lifecycle_outbox
			WHERE status IN ('PENDING', 'PROCESSING')
			  AND next_attempt_at <= $1
			ORDER BY COALESCE(next_attempt_at, locked_at) ASC, created_at ASC, id ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		UPDATE activity_saved_lifecycle_outbox AS outbox
		SET status = 'PROCESSING',
		    next_attempt_at = $3,
		    locked_at = $1,
		    locked_by = $4
		FROM candidates
		WHERE outbox.id = candidates.id
		RETURNING
			outbox.id,
			outbox.activity_id,
			outbox.subject,
			outbox.schema_version,
			outbox.event_kind,
			outbox.visibility,
			outbox.source_revision,
			outbox.projection_revision,
			outbox.visibility_revision,
			outbox.has_public_projection,
			outbox.payload,
			outbox.status,
			outbox.attempt_count,
			outbox.max_attempts,
			outbox.next_attempt_at,
			outbox.locked_at,
			outbox.locked_by,
			outbox.last_error_code,
			outbox.occurred_at,
			outbox.created_at,
			outbox.published_at,
			outbox.dead_at,
			outbox.retention_expires_at,
			candidates.recovered_lease
	`, now, limit, leaseUntil, workerID)
	if err != nil {
		return nil, fmt.Errorf("claim activity Saved lifecycle outbox: %w", err)
	}
	defer rows.Close()

	items := make([]model.ActivitySavedLifecycleOutboxEvent, 0, limit)
	for rows.Next() {
		item, scanErr := scanActivitySavedLifecycleOutboxEvent(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan activity Saved lifecycle outbox: %w", scanErr)
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate activity Saved lifecycle outbox: %w", err)
	}
	return items, nil
}

func (r *PGActivityRepository) MarkActivitySavedLifecyclePublished(
	ctx context.Context,
	eventID uuid.UUID,
	workerID string,
	publishedAt time.Time,
) (bool, error) {
	if eventID == uuid.Nil || strings.TrimSpace(workerID) == "" {
		return false, nil
	}
	if publishedAt.IsZero() {
		publishedAt = time.Now().UTC()
	} else {
		publishedAt = publishedAt.UTC()
	}
	tag, err := r.pool.Exec(ctx, `
		UPDATE activity_saved_lifecycle_outbox
		SET status = 'PUBLISHED',
		    next_attempt_at = NULL,
		    locked_at = NULL,
		    locked_by = NULL,
		    last_error_code = NULL,
		    published_at = $3,
		    retention_expires_at = $3 + INTERVAL '14 days'
		WHERE id = $1
		  AND status = 'PROCESSING'
		  AND locked_by = $2
	`, eventID, strings.TrimSpace(workerID), publishedAt)
	if err != nil {
		return false, fmt.Errorf("mark activity Saved lifecycle published: %w", err)
	}
	return tag.RowsAffected() == 1, nil
}

func (r *PGActivityRepository) MarkActivitySavedLifecycleFailed(
	ctx context.Context,
	eventID uuid.UUID,
	workerID string,
	errorCode string,
	nextAttemptAt time.Time,
) (dead bool, updated bool, err error) {
	if eventID == uuid.Nil || strings.TrimSpace(workerID) == "" {
		return false, false, nil
	}
	errorCode = model.NormalizeActivitySavedLifecycleErrorCode(errorCode)
	if nextAttemptAt.IsZero() {
		nextAttemptAt = time.Now().UTC().Add(time.Second)
	} else {
		nextAttemptAt = nextAttemptAt.UTC()
	}
	var status string
	err = r.pool.QueryRow(ctx, `
		UPDATE activity_saved_lifecycle_outbox
		SET attempt_count = attempt_count + 1,
		    status = CASE
		        WHEN attempt_count + 1 >= max_attempts THEN 'DEAD'
		        ELSE 'PENDING'
		    END,
		    next_attempt_at = CASE
		        WHEN attempt_count + 1 >= max_attempts THEN NULL::TIMESTAMPTZ
		        ELSE $4::TIMESTAMPTZ
		    END,
		    locked_at = NULL,
		    locked_by = NULL,
		    last_error_code = $3,
		    dead_at = CASE
		        WHEN attempt_count + 1 >= max_attempts THEN NOW()
		        ELSE NULL
		    END,
		    retention_expires_at = CASE
		        WHEN attempt_count + 1 >= max_attempts THEN NOW() + INTERVAL '14 days'
		        ELSE NULL
		    END
		WHERE id = $1
		  AND status = 'PROCESSING'
		  AND locked_by = $2
		RETURNING status
	`, eventID, strings.TrimSpace(workerID), errorCode, nextAttemptAt).Scan(&status)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, false, nil
	}
	if err != nil {
		return false, false, fmt.Errorf("mark activity Saved lifecycle failed: %w", err)
	}
	return status == string(model.ActivitySavedLifecycleDead), true, nil
}

func (r *PGActivityRepository) DeleteTerminalActivitySavedLifecycleEvents(
	ctx context.Context,
	before time.Time,
	limit int,
) (int64, error) {
	if before.IsZero() {
		before = time.Now().UTC()
	} else {
		before = before.UTC()
	}
	if limit <= 0 || limit > 1000 {
		limit = 100
	}
	tag, err := r.pool.Exec(ctx, `
		WITH expired AS (
			SELECT id
			FROM activity_saved_lifecycle_outbox
			WHERE status IN ('PUBLISHED', 'DEAD')
			  AND retention_expires_at <= $1
			ORDER BY retention_expires_at ASC, id ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		DELETE FROM activity_saved_lifecycle_outbox AS outbox
		USING expired
		WHERE outbox.id = expired.id
	`, before, limit)
	if err != nil {
		return 0, fmt.Errorf("delete terminal activity Saved lifecycle outbox: %w", err)
	}
	return tag.RowsAffected(), nil
}

func (r *PGActivityRepository) GetActivitySavedLifecycleQueueStats(
	ctx context.Context,
	now time.Time,
) (model.ActivitySavedLifecycleQueueStats, error) {
	if now.IsZero() {
		now = time.Now().UTC()
	} else {
		now = now.UTC()
	}
	var stats model.ActivitySavedLifecycleQueueStats
	err := r.pool.QueryRow(ctx, `
		SELECT
			(SELECT COUNT(*)::BIGINT
			 FROM activity_saved_lifecycle_outbox
			 WHERE status = 'PENDING'),
			(SELECT COUNT(*)::BIGINT
			 FROM activity_saved_lifecycle_outbox
			 WHERE status = 'PROCESSING'),
			(SELECT COUNT(*)::BIGINT
			 FROM activity_saved_lifecycle_outbox
			 WHERE status = 'DEAD'),
			COALESCE(
				(SELECT GREATEST(EXTRACT(EPOCH FROM ($1 - MIN(created_at))), 0)
				 FROM activity_saved_lifecycle_outbox
				 WHERE status = 'PENDING'),
				0
			)::FLOAT8
	`, now).Scan(
		&stats.PendingCount,
		&stats.ProcessingCount,
		&stats.DeadCount,
		&stats.OldestPendingAgeSeconds,
	)
	if err != nil {
		return model.ActivitySavedLifecycleQueueStats{}, fmt.Errorf("get activity Saved lifecycle queue stats: %w", err)
	}
	return stats, nil
}

func scanActivitySavedLifecycleOutboxEvent(row activityScanner) (model.ActivitySavedLifecycleOutboxEvent, error) {
	var event model.ActivitySavedLifecycleOutboxEvent
	var kind string
	var status string
	err := row.Scan(
		&event.ID,
		&event.ActivityID,
		&event.Subject,
		&event.SchemaVersion,
		&kind,
		&event.Visibility,
		&event.SourceRevision,
		&event.ProjectionRevision,
		&event.VisibilityRevision,
		&event.HasPublicProjection,
		&event.Payload,
		&status,
		&event.AttemptCount,
		&event.MaxAttempts,
		&event.NextAttemptAt,
		&event.LockedAt,
		&event.LockedBy,
		&event.LastErrorCode,
		&event.OccurredAt,
		&event.CreatedAt,
		&event.PublishedAt,
		&event.DeadAt,
		&event.RetentionExpiresAt,
		&event.RecoveredLease,
	)
	event.Kind = model.ActivitySavedLifecycleEventKind(kind)
	event.Status = model.ActivitySavedLifecycleOutboxStatus(status)
	return event, err
}
