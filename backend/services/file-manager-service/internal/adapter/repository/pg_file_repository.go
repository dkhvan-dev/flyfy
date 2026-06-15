package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

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
			width,
			height,
			duration_ms,
			thumbnail_file_id,
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
			$12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22,
			$23, $24, $25, $26, $27, $28, $29
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
		file.Width,
		file.Height,
		file.DurationMS,
		file.ThumbnailFileID,
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
			width,
			height,
			duration_ms,
			thumbnail_file_id,
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
			width,
			height,
			duration_ms,
			thumbnail_file_id,
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
			width = $12,
			height = $13,
			duration_ms = $14,
			thumbnail_file_id = $15,
			visibility = $16,
			purpose = $17,
			status = $18,
			owner_type = $19,
			owner_id = $20,
			uploaded_by_user_id = $21,
			upload_expires_at = $22,
			policy_status = $23,
			policy_reason_code = $24,
			policy_decision_id = $25,
			is_deleted = $26,
			deleted_at = $27,
			updated_at = $28
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
		file.Width,
		file.Height,
		file.DurationMS,
		file.ThumbnailFileID,
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

func (r *PGFileRepository) SoftDeleteUnbound(ctx context.Context, id uuid.UUID) (bool, error) {
	const query = `
		UPDATE files
		SET
			is_deleted = TRUE,
			status = $2,
			deleted_at = NOW(),
			updated_at = NOW()
		WHERE id = $1
		  AND is_deleted = FALSE
		  AND NOT EXISTS (
		  	SELECT 1
		  	FROM file_bindings b
		  	WHERE b.file_id = files.id
		  	  AND b.is_deleted = FALSE
		  )
	`

	tag, err := r.pool.Exec(ctx, query, id, string(enum.FileStatusDeleted))
	if err != nil {
		return false, fmt.Errorf("soft delete unbound file: %w", err)
	}

	return tag.RowsAffected() > 0, nil
}

func (r *PGFileRepository) HasActiveBinding(ctx context.Context, id uuid.UUID) (bool, error) {
	const query = `
		SELECT EXISTS (
			SELECT 1
			FROM file_bindings
			WHERE file_id = $1
			  AND is_deleted = FALSE
		)
	`

	var exists bool
	if err := r.pool.QueryRow(ctx, query, id).Scan(&exists); err != nil {
		return false, fmt.Errorf("check active file binding: %w", err)
	}

	return exists, nil
}

func (r *PGFileRepository) ListExpiredUnboundUploads(
	ctx context.Context,
	purpose enum.FilePurpose,
	expiredBefore time.Time,
	limit int,
) ([]*model.File, error) {
	if limit <= 0 {
		limit = 100
	}

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
			width,
			height,
			duration_ms,
			thumbnail_file_id,
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
		FROM files f
		WHERE f.purpose = $1
		  AND f.upload_expires_at IS NOT NULL
		  AND f.upload_expires_at < $2
		  AND f.is_deleted = FALSE
		  AND NOT EXISTS (
		  	SELECT 1
		  	FROM file_bindings b
		  	WHERE b.file_id = f.id
		  	  AND b.is_deleted = FALSE
		)
		ORDER BY f.upload_expires_at ASC
		LIMIT $3
	`

	rows, err := r.pool.Query(ctx, query, string(purpose), expiredBefore, limit)
	if err != nil {
		return nil, fmt.Errorf("query expired unbound uploads: %w", err)
	}
	defer rows.Close()

	files := make([]*model.File, 0)
	for rows.Next() {
		file, err := scanFile(rows)
		if err != nil {
			return nil, fmt.Errorf("scan expired unbound upload: %w", err)
		}
		files = append(files, file)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate expired unbound uploads: %w", err)
	}

	return files, nil
}
