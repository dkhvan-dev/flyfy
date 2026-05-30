package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
)

type PGFileRepository struct {
	pool *pgxpool.Pool
}

func NewPGFileRepository(pool *pgxpool.Pool) *PGFileRepository {
	return &PGFileRepository{pool: pool}
}

func (r *PGFileRepository) Create(ctx context.Context, file *model.File) error {
	const query = `
		INSERT INTO files (
			id,
			provider,
			bucket,
			object_key,
			original_name,
			stored_name,
			extension,
			content_type,
			detected_content_type,
			size_bytes,
			checksum_sha256,
			visibility,
			purpose,
			status,
			owner_type,
			owner_id,
			uploaded_by_user_id,
			upload_expires_at,
			policy_status,
			policy_reason_code,
			policy_decision_id,
			is_deleted,
			deleted_at,
			created_at,
			updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
			$12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		file.ID,
		file.Provider,
		file.Bucket,
		file.ObjectKey,
		file.OriginalName,
		file.StoredName,
		file.Extension,
		file.ContentType,
		file.DetectedContentType,
		file.SizeBytes,
		file.ChecksumSHA256,
		string(file.Visibility),
		string(file.Purpose),
		string(file.Status),
		ownerTypeToDB(file.OwnerType),
		file.OwnerID,
		file.UploadedByUserID,
		file.UploadExpiresAt,
		string(file.PolicyStatus),
		file.PolicyReasonCode,
		file.PolicyDecisionID,
		file.IsDeleted,
		file.DeletedAt,
		file.CreatedAt,
		file.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert file: %w", err)
	}

	return nil
}

func (r *PGFileRepository) GetByID(ctx context.Context, id uuid.UUID) (*model.File, error) {
	const query = `
		SELECT
			id,
			provider,
			bucket,
			object_key,
			original_name,
			stored_name,
			extension,
			content_type,
			detected_content_type,
			size_bytes,
			checksum_sha256,
			visibility,
			purpose,
			status,
			owner_type,
			owner_id,
			uploaded_by_user_id,
			upload_expires_at,
			policy_status,
			policy_reason_code,
			policy_decision_id,
			is_deleted,
			deleted_at,
			created_at,
			updated_at
		FROM files
		WHERE id = $1
		LIMIT 1
	`

	file, err := scanFile(r.pool.QueryRow(ctx, query, id))
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, nil
		}
		return nil, fmt.Errorf("select file by id: %w", err)
	}

	return file, nil
}

func (r *PGFileRepository) GetByObjectKey(ctx context.Context, objectKey string) (*model.File, error) {
	const query = `
		SELECT
			id,
			provider,
			bucket,
			object_key,
			original_name,
			stored_name,
			extension,
			content_type,
			detected_content_type,
			size_bytes,
			checksum_sha256,
			visibility,
			purpose,
			status,
			owner_type,
			owner_id,
			uploaded_by_user_id,
			upload_expires_at,
			policy_status,
			policy_reason_code,
			policy_decision_id,
			is_deleted,
			deleted_at,
			created_at,
			updated_at
		FROM files
		WHERE object_key = $1
		LIMIT 1
	`

	file, err := scanFile(r.pool.QueryRow(ctx, query, objectKey))
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, nil
		}
		return nil, fmt.Errorf("select file by object key: %w", err)
	}

	return file, nil
}

func (r *PGFileRepository) Update(ctx context.Context, file *model.File) error {
	const query = `
		UPDATE files
		SET
			provider = $2,
			bucket = $3,
			object_key = $4,
			original_name = $5,
			stored_name = $6,
			extension = $7,
			content_type = $8,
			detected_content_type = $9,
			size_bytes = $10,
			checksum_sha256 = $11,
			visibility = $12,
			purpose = $13,
			status = $14,
			owner_type = $15,
			owner_id = $16,
			uploaded_by_user_id = $17,
			upload_expires_at = $18,
			policy_status = $19,
			policy_reason_code = $20,
			policy_decision_id = $21,
			is_deleted = $22,
			deleted_at = $23,
			updated_at = $24
		WHERE id = $1
	`

	tag, err := r.pool.Exec(
		ctx,
		query,
		file.ID,
		file.Provider,
		file.Bucket,
		file.ObjectKey,
		file.OriginalName,
		file.StoredName,
		file.Extension,
		file.ContentType,
		file.DetectedContentType,
		file.SizeBytes,
		file.ChecksumSHA256,
		string(file.Visibility),
		string(file.Purpose),
		string(file.Status),
		ownerTypeToDB(file.OwnerType),
		file.OwnerID,
		file.UploadedByUserID,
		file.UploadExpiresAt,
		string(file.PolicyStatus),
		file.PolicyReasonCode,
		file.PolicyDecisionID,
		file.IsDeleted,
		file.DeletedAt,
		file.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update file: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func (r *PGFileRepository) SoftDelete(ctx context.Context, id uuid.UUID) error {
	const query = `
		UPDATE files
		SET
			is_deleted = TRUE,
			status = $2,
			deleted_at = NOW(),
			updated_at = NOW()
		WHERE id = $1
		  AND is_deleted = FALSE
	`

	tag, err := r.pool.Exec(ctx, query, id, string(enum.FileStatusDeleted))
	if err != nil {
		return fmt.Errorf("soft delete file: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}
