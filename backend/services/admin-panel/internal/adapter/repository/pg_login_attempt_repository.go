package repository

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type PGLoginAttemptRepository struct {
	pool *pgxpool.Pool
}

func NewPGLoginAttemptRepository(pool *pgxpool.Pool) *PGLoginAttemptRepository {
	return &PGLoginAttemptRepository{pool: pool}
}

func (r *PGLoginAttemptRepository) Append(ctx context.Context, attempt *model.StaffLoginAttempt) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO staff_login_attempts (
			id, email_hash, ip_address_hash, success, failure_reason, created_at
		)
		VALUES ($1, $2, $3, $4, $5, $6)
	`, attempt.ID, attempt.EmailHash, attempt.IPAddressHash, attempt.Success,
		attempt.FailureReason, attempt.CreatedAt)
	return err
}

func (r *PGLoginAttemptRepository) CountFailuresSince(ctx context.Context, emailHash string, ipAddressHash string, since time.Time) (int, error) {
	var count int
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM staff_login_attempts
		WHERE success = FALSE
		  AND created_at >= $1
		  AND (
		      ($2 <> '' AND email_hash = $2)
		      OR ($3 <> '' AND ip_address_hash = $3)
		  )
	`, since, emailHash, ipAddressHash).Scan(&count)
	return count, err
}
