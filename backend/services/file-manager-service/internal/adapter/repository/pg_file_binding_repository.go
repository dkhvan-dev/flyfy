package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/model"
)

type PGFileBindingRepository struct {
	pool *pgxpool.Pool
}

func NewPGFileBindingRepository(pool *pgxpool.Pool) *PGFileBindingRepository {
	return &PGFileBindingRepository{pool: pool}
}

func (r *PGFileBindingRepository) Create(ctx context.Context, binding *model.FileBinding) error {
	const query = `
		INSERT INTO file_bindings (
			id, file_id, owner_type, owner_id, purpose, is_primary,
			is_deleted, deleted_at, created_by_user_id, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		binding.ID,
		binding.FileID,
		string(binding.OwnerType),
		binding.OwnerID,
		string(binding.Purpose),
		binding.IsPrimary,
		binding.IsDeleted,
		binding.DeletedAt,
		binding.CreatedByUserID,
		binding.CreatedAt,
		binding.UpdatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert file binding: %w", err)
	}

	return nil
}

func (r *PGFileBindingRepository) CreateWithPrimarySwitchTx(
	ctx context.Context,
	binding *model.FileBinding,
) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if binding.IsPrimary {
		const softDeletePrimaryQuery = `
			UPDATE file_bindings
			SET is_deleted = TRUE,
				deleted_at = NOW(),
				updated_at = NOW()
			WHERE owner_type = $1
			  AND owner_id = $2
			  AND purpose = $3
			  AND is_primary = TRUE
			  AND is_deleted = FALSE
		`

		if _, err = tx.Exec(
			ctx,
			softDeletePrimaryQuery,
			string(binding.OwnerType),
			binding.OwnerID,
			string(binding.Purpose),
		); err != nil {
			return fmt.Errorf("soft delete existing primary binding: %w", err)
		}
	}

	const insertQuery = `
		INSERT INTO file_bindings (
			id, file_id, owner_type, owner_id, purpose, is_primary,
			is_deleted, deleted_at, created_by_user_id, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11
		)
	`

	if _, err = tx.Exec(
		ctx,
		insertQuery,
		binding.ID,
		binding.FileID,
		string(binding.OwnerType),
		binding.OwnerID,
		string(binding.Purpose),
		binding.IsPrimary,
		binding.IsDeleted,
		binding.DeletedAt,
		binding.CreatedByUserID,
		binding.CreatedAt,
		binding.UpdatedAt,
	); err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert binding in tx: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}

	return nil
}

func (r *PGFileBindingRepository) GetPrimaryByOwnerAndPurpose(
	ctx context.Context,
	ownerType enum.OwnerType,
	ownerID uuid.UUID,
	purpose enum.FilePurpose,
) (*model.FileBinding, error) {
	const query = `
		SELECT
			id, file_id, owner_type, owner_id, purpose, is_primary,
			is_deleted, deleted_at, created_by_user_id, created_at, updated_at
		FROM file_bindings
		WHERE owner_type = $1
		  AND owner_id = $2
		  AND purpose = $3
		  AND is_primary = TRUE
		  AND is_deleted = FALSE
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, string(ownerType), ownerID, string(purpose))

	var (
		binding         model.FileBinding
		ownerTypeRaw    string
		purposeRaw      string
		createdByUserID *uuid.UUID
	)

	err := row.Scan(
		&binding.ID,
		&binding.FileID,
		&ownerTypeRaw,
		&binding.OwnerID,
		&purposeRaw,
		&binding.IsPrimary,
		&binding.IsDeleted,
		&binding.DeletedAt,
		&createdByUserID,
		&binding.CreatedAt,
		&binding.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select primary binding: %w", err)
	}

	binding.OwnerType = enum.OwnerType(ownerTypeRaw)
	binding.Purpose = enum.FilePurpose(purposeRaw)
	binding.CreatedByUserID = createdByUserID

	return &binding, nil
}

func (r *PGFileBindingRepository) SoftDeletePrimaryByOwnerAndPurpose(
	ctx context.Context,
	ownerType enum.OwnerType,
	ownerID uuid.UUID,
	purpose enum.FilePurpose,
) error {
	const query = `
		UPDATE file_bindings
		SET is_deleted = TRUE,
			deleted_at = NOW(),
			updated_at = NOW()
		WHERE owner_type = $1
		  AND owner_id = $2
		  AND purpose = $3
		  AND is_primary = TRUE
		  AND is_deleted = FALSE
	`

	_, err := r.pool.Exec(ctx, query, string(ownerType), ownerID, string(purpose))
	if err != nil {
		return fmt.Errorf("soft delete primary binding: %w", err)
	}

	return nil
}

func (r *PGFileBindingRepository) ListByFileID(ctx context.Context, fileID uuid.UUID) ([]*model.FileBinding, error) {
	const query = `
		SELECT
			id, file_id, owner_type, owner_id, purpose, is_primary,
			is_deleted, deleted_at, created_by_user_id, created_at, updated_at
		FROM file_bindings
		WHERE file_id = $1
		ORDER BY created_at ASC
	`

	rows, err := r.pool.Query(ctx, query, fileID)
	if err != nil {
		return nil, fmt.Errorf("query file bindings: %w", err)
	}
	defer rows.Close()

	var result []*model.FileBinding
	for rows.Next() {
		var (
			binding         model.FileBinding
			ownerTypeRaw    string
			purposeRaw      string
			createdByUserID *uuid.UUID
		)

		if err = rows.Scan(
			&binding.ID,
			&binding.FileID,
			&ownerTypeRaw,
			&binding.OwnerID,
			&purposeRaw,
			&binding.IsPrimary,
			&binding.IsDeleted,
			&binding.DeletedAt,
			&createdByUserID,
			&binding.CreatedAt,
			&binding.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan file binding: %w", err)
		}

		binding.OwnerType = enum.OwnerType(ownerTypeRaw)
		binding.Purpose = enum.FilePurpose(purposeRaw)
		binding.CreatedByUserID = createdByUserID

		result = append(result, &binding)
	}

	return result, rows.Err()
}

func (r *PGFileBindingRepository) ListByOwnerAndPurpose(
	ctx context.Context,
	ownerType enum.OwnerType,
	ownerID uuid.UUID,
	purpose enum.FilePurpose,
	limit int,
) ([]*model.FileBinding, error) {
	if limit <= 0 {
		limit = 100
	}

	const query = `
		SELECT
			id, file_id, owner_type, owner_id, purpose, is_primary,
			is_deleted, deleted_at, created_by_user_id, created_at, updated_at
		FROM file_bindings
		WHERE owner_type = $1
		  AND owner_id = $2
		  AND purpose = $3
		  AND is_deleted = FALSE
		ORDER BY created_at DESC
		LIMIT $4
	`

	rows, err := r.pool.Query(ctx, query, string(ownerType), ownerID, string(purpose), limit)
	if err != nil {
		return nil, fmt.Errorf("query file bindings by owner: %w", err)
	}
	defer rows.Close()

	var result []*model.FileBinding
	for rows.Next() {
		var (
			binding         model.FileBinding
			ownerTypeRaw    string
			purposeRaw      string
			createdByUserID *uuid.UUID
		)

		if err = rows.Scan(
			&binding.ID,
			&binding.FileID,
			&ownerTypeRaw,
			&binding.OwnerID,
			&purposeRaw,
			&binding.IsPrimary,
			&binding.IsDeleted,
			&binding.DeletedAt,
			&createdByUserID,
			&binding.CreatedAt,
			&binding.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan file binding by owner: %w", err)
		}

		binding.OwnerType = enum.OwnerType(ownerTypeRaw)
		binding.Purpose = enum.FilePurpose(purposeRaw)
		binding.CreatedByUserID = createdByUserID

		result = append(result, &binding)
	}

	return result, rows.Err()
}
