package repository

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

type PGSessionRepository struct {
	pool *pgxpool.Pool
}

func NewPGSessionRepository(pool *pgxpool.Pool) *PGSessionRepository {
	return &PGSessionRepository{pool: pool}
}

func (r *PGSessionRepository) Create(ctx context.Context, session *model.StaffSession) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO staff_sessions (
			id, staff_user_id, session_hash, csrf_token_hash, ip_address_hash,
			user_agent_hash, created_at, last_seen_at, expires_at, absolute_expires_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`, session.ID, session.StaffUserID, session.SessionHash, session.CSRFTokenHash,
		session.IPAddressHash, session.UserAgentHash, session.CreatedAt, session.LastSeenAt,
		session.ExpiresAt, session.AbsoluteExpires)
	return err
}

func (r *PGSessionRepository) GetBySessionHash(ctx context.Context, sessionHash string) (*model.StaffSession, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, staff_user_id, session_hash, csrf_token_hash, ip_address_hash,
		       user_agent_hash, created_at, last_seen_at, expires_at, revoked_at,
		       absolute_expires_at
		FROM staff_sessions
		WHERE session_hash = $1
	`, sessionHash)
	var item model.StaffSession
	err := row.Scan(
		&item.ID,
		&item.StaffUserID,
		&item.SessionHash,
		&item.CSRFTokenHash,
		&item.IPAddressHash,
		&item.UserAgentHash,
		&item.CreatedAt,
		&item.LastSeenAt,
		&item.ExpiresAt,
		&item.RevokedAt,
		&item.AbsoluteExpires,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &item, nil
}

func (r *PGSessionRepository) Touch(ctx context.Context, id uuid.UUID, expiresAt time.Time, now time.Time) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE staff_sessions
		SET last_seen_at = $2,
		    expires_at = $3
		WHERE id = $1
		  AND revoked_at IS NULL
	`, id, now, expiresAt)
	return err
}

func (r *PGSessionRepository) Revoke(ctx context.Context, id uuid.UUID, now time.Time) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE staff_sessions
		SET revoked_at = COALESCE(revoked_at, $2)
		WHERE id = $1
	`, id, now)
	return err
}

func (r *PGSessionRepository) RevokeAllForStaff(ctx context.Context, staffID uuid.UUID, now time.Time) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE staff_sessions
		SET revoked_at = COALESCE(revoked_at, $2)
		WHERE staff_user_id = $1
		  AND revoked_at IS NULL
	`, staffID, now)
	return err
}
