package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
)

type PGIdempotencyRepository struct {
	pool *pgxpool.Pool
}

func NewPGIdempotencyRepository(pool *pgxpool.Pool) *PGIdempotencyRepository {
	return &PGIdempotencyRepository{pool: pool}
}

func (r *PGIdempotencyRepository) GetByOperationAndKey(
	ctx context.Context,
	operation string,
	key string,
) (*model.IdempotencyRecord, error) {
	const query = `
		SELECT
			id, operation, idempotency_key, request_fingerprint,
			response_status_code, response_body, resource_type, resource_id,
			created_by_user_id, expires_at, created_at, updated_at
		FROM file_idempotency_keys
		WHERE operation = $1
		  AND idempotency_key = $2
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, operation, key)

	var (
		record          model.IdempotencyRecord
		responseBody    []byte
		resourceType    *string
		resourceID      *uuid.UUID
		createdByUserID *uuid.UUID
	)

	err := row.Scan(
		&record.ID,
		&record.Operation,
		&record.IdempotencyKey,
		&record.RequestFingerprint,
		&record.ResponseStatusCode,
		&responseBody,
		&resourceType,
		&resourceID,
		&createdByUserID,
		&record.ExpiresAt,
		&record.CreatedAt,
		&record.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select idempotency record: %w", err)
	}

	record.ResponseBody = responseBody
	record.ResourceType = resourceType
	record.ResourceID = resourceID
	record.CreatedByUserID = createdByUserID

	return &record, nil
}

func (r *PGIdempotencyRepository) Create(ctx context.Context, record *model.IdempotencyRecord) error {
	const query = `
		INSERT INTO file_idempotency_keys (
			id, operation, idempotency_key, request_fingerprint,
			response_status_code, response_body, resource_type, resource_id,
			created_by_user_id, expires_at, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4,
			$5, $6, $7, $8,
			$9, $10, $11, $12
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		record.ID,
		record.Operation,
		record.IdempotencyKey,
		record.RequestFingerprint,
		record.ResponseStatusCode,
		record.ResponseBody,
		record.ResourceType,
		record.ResourceID,
		record.CreatedByUserID,
		record.ExpiresAt,
		record.CreatedAt,
		record.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert idempotency record: %w", err)
	}

	return nil
}

func (r *PGIdempotencyRepository) UpdateResponse(
	ctx context.Context,
	operation string,
	key string,
	requestFingerprint string,
	statusCode int,
	responseBody []byte,
	resourceType *string,
	resourceID *string,
) error {
	var resourceUUID *uuid.UUID
	if resourceID != nil && *resourceID != "" {
		parsed, err := uuid.Parse(*resourceID)
		if err != nil {
			return fmt.Errorf("parse resource id: %w", err)
		}
		resourceUUID = &parsed
	}

	const query = `
		UPDATE file_idempotency_keys
		SET response_status_code = $4,
			response_body = $5,
			resource_type = $6,
			resource_id = $7,
			updated_at = NOW()
		WHERE operation = $1
		  AND idempotency_key = $2
		  AND request_fingerprint = $3
	`

	tag, err := r.pool.Exec(
		ctx,
		query,
		operation,
		key,
		requestFingerprint,
		statusCode,
		responseBody,
		resourceType,
		resourceUUID,
	)
	if err != nil {
		return fmt.Errorf("update idempotency response: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}
