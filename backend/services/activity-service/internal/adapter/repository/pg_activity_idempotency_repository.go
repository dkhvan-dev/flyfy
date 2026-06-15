package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

const activityIdempotencyKeySelectColumns = `
	key, source_service, source_resource_type, source_resource_id,
	host_user_id, request_hash, activity_id, status, last_error,
	created_at, updated_at, completed_at
`

func (r *PGActivityRepository) AcquireActivityIdempotencyKey(
	ctx context.Context,
	item *model.ActivityIdempotencyKey,
) (*model.ActivityIdempotencyKey, bool, error) {
	if item == nil {
		return nil, false, model.ErrInvalidActivityIdempotencyKey
	}
	if err := item.Validate(); err != nil {
		return nil, false, err
	}

	inserted, err := r.insertActivityIdempotencyKey(ctx, item)
	if err == nil {
		return inserted, true, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return nil, false, err
	}

	reacquired, err := r.reacquireFailedActivityIdempotencyKey(ctx, item)
	if err == nil {
		return reacquired, true, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return nil, false, err
	}

	existing, err := r.getActivityIdempotencyKey(ctx, item.Key)
	if err != nil {
		return nil, false, err
	}
	return existing, false, nil
}

func (r *PGActivityRepository) insertActivityIdempotencyKey(
	ctx context.Context,
	item *model.ActivityIdempotencyKey,
) (*model.ActivityIdempotencyKey, error) {
	const query = `
		INSERT INTO activity_idempotency_keys (
			key, source_service, source_resource_type, source_resource_id,
			host_user_id, request_hash, status, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4,
			$5, $6, $7, $8, $9
		)
		ON CONFLICT (key) DO NOTHING
		RETURNING
	` + activityIdempotencyKeySelectColumns

	return scanActivityIdempotencyKey(r.pool.QueryRow(
		ctx,
		query,
		item.Key,
		item.SourceService,
		item.SourceResourceType,
		item.SourceResourceID,
		item.HostUserID,
		item.RequestHash,
		string(item.Status),
		item.CreatedAt,
		item.UpdatedAt,
	))
}

func (r *PGActivityRepository) reacquireFailedActivityIdempotencyKey(
	ctx context.Context,
	item *model.ActivityIdempotencyKey,
) (*model.ActivityIdempotencyKey, error) {
	const query = `
		UPDATE activity_idempotency_keys
		SET
			status = $6,
			last_error = NULL,
			activity_id = NULL,
			updated_at = now(),
			completed_at = NULL
		WHERE key = $1
		  AND source_service = $2
		  AND source_resource_type = $3
		  AND source_resource_id = $4
		  AND request_hash = $5
		  AND status = $7
		RETURNING
	` + activityIdempotencyKeySelectColumns

	return scanActivityIdempotencyKey(r.pool.QueryRow(
		ctx,
		query,
		item.Key,
		item.SourceService,
		item.SourceResourceType,
		item.SourceResourceID,
		item.RequestHash,
		string(model.ActivityIdempotencyStatusInProgress),
		string(model.ActivityIdempotencyStatusFailed),
	))
}

func (r *PGActivityRepository) getActivityIdempotencyKey(
	ctx context.Context,
	key string,
) (*model.ActivityIdempotencyKey, error) {
	const query = `
		SELECT
	` + activityIdempotencyKeySelectColumns + `
		FROM activity_idempotency_keys
		WHERE key = $1
		LIMIT 1
	`

	item, err := scanActivityIdempotencyKey(r.pool.QueryRow(ctx, query, strings.TrimSpace(key)))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get activity idempotency key: %w", err)
	}
	return item, nil
}

func (r *PGActivityRepository) CompleteActivityIdempotencyKey(
	ctx context.Context,
	key string,
	activityID uuid.UUID,
) error {
	key = strings.TrimSpace(key)
	if key == "" || activityID == uuid.Nil {
		return model.ErrInvalidActivityIdempotencyKey
	}

	const query = `
		UPDATE activity_idempotency_keys
		SET
			status = $3,
			activity_id = $2,
			last_error = NULL,
			completed_at = now(),
			updated_at = now()
		WHERE key = $1
	`

	if _, err := r.pool.Exec(ctx, query, key, activityID, string(model.ActivityIdempotencyStatusCompleted)); err != nil {
		return fmt.Errorf("complete activity idempotency key: %w", err)
	}
	return nil
}

func (r *PGActivityRepository) FailActivityIdempotencyKey(
	ctx context.Context,
	key string,
	reason string,
) error {
	key = strings.TrimSpace(key)
	if key == "" {
		return model.ErrInvalidActivityIdempotencyKey
	}

	const query = `
		UPDATE activity_idempotency_keys
		SET
			status = $3,
			last_error = $2,
			updated_at = now()
		WHERE key = $1
		  AND status = $4
	`

	if _, err := r.pool.Exec(
		ctx,
		query,
		key,
		truncateActivityIdempotencyError(reason),
		string(model.ActivityIdempotencyStatusFailed),
		string(model.ActivityIdempotencyStatusInProgress),
	); err != nil {
		return fmt.Errorf("fail activity idempotency key: %w", err)
	}
	return nil
}

func scanActivityIdempotencyKey(row activityScanner) (*model.ActivityIdempotencyKey, error) {
	var (
		item      model.ActivityIdempotencyKey
		statusRaw string
	)

	if err := row.Scan(
		&item.Key,
		&item.SourceService,
		&item.SourceResourceType,
		&item.SourceResourceID,
		&item.HostUserID,
		&item.RequestHash,
		&item.ActivityID,
		&statusRaw,
		&item.LastError,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.CompletedAt,
	); err != nil {
		return nil, err
	}

	item.Status = model.ActivityIdempotencyStatus(statusRaw)
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return &item, nil
}

func truncateActivityIdempotencyError(reason string) *string {
	value := strings.TrimSpace(reason)
	if value == "" {
		return nil
	}
	if len(value) > 512 {
		value = value[:512]
	}
	return &value
}
