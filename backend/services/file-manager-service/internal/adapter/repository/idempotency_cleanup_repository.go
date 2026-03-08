package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type IdempotencyCleanupRepository struct {
	pool *pgxpool.Pool
}

func NewIdempotencyCleanupRepository(pool *pgxpool.Pool) *IdempotencyCleanupRepository {
	return &IdempotencyCleanupRepository{pool: pool}
}

func (r *IdempotencyCleanupRepository) DeleteExpired(ctx context.Context, limit int) (int64, error) {
	if limit <= 0 {
		limit = 1000
	}

	const query = `
		DELETE FROM file_idempotency_keys
		WHERE id IN (
			SELECT id
			FROM file_idempotency_keys
			WHERE expires_at < NOW()
			ORDER BY expires_at ASC
			LIMIT $1
		)
	`

	tag, err := r.pool.Exec(ctx, query, limit)
	if err != nil {
		return 0, fmt.Errorf("delete expired idempotency keys: %w", err)
	}

	return tag.RowsAffected(), nil
}
