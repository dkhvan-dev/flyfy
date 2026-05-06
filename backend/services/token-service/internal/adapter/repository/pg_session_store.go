package repository

import (
	"context"
	"errors"
	"fmt"
	"net"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/port"
)

// pgUniqueViolation is the SQLSTATE for "unique_violation" — used to detect
// the partial-unique-index conflict on user_sessions(user_id) WHERE revoked_at IS NULL.
const pgUniqueViolation = "23505"

// PgSessionStore implements port.SessionStore on top of PostgreSQL via pgx.
type PgSessionStore struct {
	pool *pgxpool.Pool
}

func NewPgSessionStore(pool *pgxpool.Pool) *PgSessionStore {
	return &PgSessionStore{pool: pool}
}

// CreateActive atomically revokes any active session for the user and inserts the new one.
// Returns the previously active session (if there was one).
func (s *PgSessionStore) CreateActive(
	ctx context.Context,
	sess *model.UserSession,
	replaceReason string,
) (*model.UserSession, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	// 1. Revoke any currently active session for this user. The partial unique
	//    index guarantees there can only be one such row.
	const revokeQ = `
		UPDATE user_sessions
		   SET revoked_at = now(),
		       revoke_reason = $2
		 WHERE user_id = $1
		   AND revoked_at IS NULL
		 RETURNING id, user_id, refresh_jti, refresh_token_hash,
		           refresh_issued_at, refresh_expires_at,
		           device_id, platform, os_version, app_version, model, user_agent,
		           host(ip_address)::text AS ip_address,
		           created_at, last_used_at, last_refreshed_at, revoked_at, revoke_reason
	`
	var replaced *model.UserSession
	row := tx.QueryRow(ctx, revokeQ, sess.UserID, replaceReason)
	rep, err := scanSessionRow(row)
	switch {
	case err == nil:
		replaced = rep
	case errors.Is(err, pgx.ErrNoRows):
		replaced = nil
	default:
		return nil, fmt.Errorf("revoking previous session: %w", err)
	}

	// 2. Insert the new session.
	const insertQ = `
		INSERT INTO user_sessions
		    (id, user_id, refresh_jti, refresh_token_hash, refresh_issued_at, refresh_expires_at,
		     device_id, platform, os_version, app_version, model, user_agent, ip_address,
		     created_at, last_used_at)
		VALUES
		    ($1, $2, $3, $4, $5, $6,
		     NULLIF($7,''), NULLIF($8,''), NULLIF($9,''), NULLIF($10,''), NULLIF($11,''), NULLIF($12,''),
		     NULLIF($13,'')::inet,
		     $14, $14)
	`
	_, err = tx.Exec(ctx, insertQ,
		sess.ID, sess.UserID,
		sess.RefreshJTI, sess.RefreshTokenHash,
		sess.RefreshIssuedAt, sess.RefreshExpiresAt,
		sess.Device.DeviceID, sess.Device.Platform, sess.Device.OSVersion, sess.Device.AppVersion,
		sess.Device.Model, sess.Device.UserAgent, normalizeIP(sess.Device.IPAddress),
		sess.CreatedAt,
	)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgUniqueViolation {
			return nil, model.ErrSessionConflict
		}
		return nil, fmt.Errorf("insert session: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return replaced, nil
}

func (s *PgSessionStore) GetByID(ctx context.Context, sessionID uuid.UUID) (*model.UserSession, error) {
	const q = `
		SELECT id, user_id, refresh_jti, refresh_token_hash,
		       refresh_issued_at, refresh_expires_at,
		       device_id, platform, os_version, app_version, model, user_agent,
		       host(ip_address)::text AS ip_address,
		       created_at, last_used_at, last_refreshed_at, revoked_at, revoke_reason
		  FROM user_sessions
		 WHERE id = $1
	`
	row := s.pool.QueryRow(ctx, q, sessionID)
	sess, err := scanSessionRow(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, model.ErrSessionNotFound
	}
	return sess, err
}

func (s *PgSessionStore) GetActiveByUserID(ctx context.Context, userID uuid.UUID) (*model.UserSession, error) {
	const q = `
		SELECT id, user_id, refresh_jti, refresh_token_hash,
		       refresh_issued_at, refresh_expires_at,
		       device_id, platform, os_version, app_version, model, user_agent,
		       host(ip_address)::text AS ip_address,
		       created_at, last_used_at, last_refreshed_at, revoked_at, revoke_reason
		  FROM user_sessions
		 WHERE user_id = $1 AND revoked_at IS NULL
	`
	row := s.pool.QueryRow(ctx, q, userID)
	sess, err := scanSessionRow(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, model.ErrSessionNotFound
	}
	return sess, err
}

func (s *PgSessionStore) GetActiveByRefreshJTI(ctx context.Context, refreshJTI string) (*model.UserSession, error) {
	const q = `
		SELECT id, user_id, refresh_jti, refresh_token_hash,
		       refresh_issued_at, refresh_expires_at,
		       device_id, platform, os_version, app_version, model, user_agent,
		       host(ip_address)::text AS ip_address,
		       created_at, last_used_at, last_refreshed_at, revoked_at, revoke_reason
		  FROM user_sessions
		 WHERE refresh_jti = $1 AND revoked_at IS NULL
	`
	row := s.pool.QueryRow(ctx, q, refreshJTI)
	sess, err := scanSessionRow(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, model.ErrSessionNotFound
	}
	return sess, err
}

// RotateRefresh atomically:
//   - inserts the previous refresh JTI/hash into refresh_token_history,
//   - updates the session row with the new refresh JTI/hash/expiry, last_refreshed_at, last_used_at,
//     and (when supplied) device metadata.
func (s *PgSessionStore) RotateRefresh(
	ctx context.Context,
	sessionID uuid.UUID,
	prev port.RotatePrev,
	next port.RotateNext,
) error {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	const histQ = `
		INSERT INTO refresh_token_history (session_id, refresh_jti, refresh_token_hash, issued_at, rotated_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	if _, err := tx.Exec(ctx, histQ,
		sessionID, prev.RefreshJTI, prev.RefreshTokenHash, prev.IssuedAt, next.RotatedAt,
	); err != nil {
		return fmt.Errorf("insert refresh history: %w", err)
	}

	// Conditional UPDATE: only rotate if the session still holds prev.RefreshJTI
	// AND is not revoked. Defends against concurrent rotation/revoke.
	const updQ = `
		UPDATE user_sessions
		   SET refresh_jti        = $2,
		       refresh_token_hash = $3,
		       refresh_issued_at  = $4,
		       refresh_expires_at = $5,
		       last_refreshed_at  = $6,
		       last_used_at       = $6,
		       device_id   = COALESCE(NULLIF($7,''),  device_id),
		       platform    = COALESCE(NULLIF($8,''),  platform),
		       os_version  = COALESCE(NULLIF($9,''),  os_version),
		       app_version = COALESCE(NULLIF($10,''), app_version),
		       model       = COALESCE(NULLIF($11,''), model),
		       user_agent  = COALESCE(NULLIF($12,''), user_agent),
		       ip_address  = COALESCE(NULLIF($13,'')::inet, ip_address)
		 WHERE id = $1
		   AND refresh_jti = $14
		   AND revoked_at IS NULL
	`
	cmd, err := tx.Exec(ctx, updQ,
		sessionID, next.RefreshJTI, next.RefreshTokenHash, next.IssuedAt, next.ExpiresAt, next.RotatedAt,
		next.Device.DeviceID, next.Device.Platform, next.Device.OSVersion, next.Device.AppVersion,
		next.Device.Model, next.Device.UserAgent, normalizeIP(next.Device.IPAddress),
		prev.RefreshJTI,
	)
	if err != nil {
		return fmt.Errorf("update session refresh: %w", err)
	}
	if cmd.RowsAffected() == 0 {
		return model.ErrSessionNotFound
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}
	return nil
}

func (s *PgSessionStore) Revoke(ctx context.Context, sessionID uuid.UUID, reason string) error {
	const q = `
		UPDATE user_sessions
		   SET revoked_at = now(),
		       revoke_reason = $2
		 WHERE id = $1 AND revoked_at IS NULL
	`
	cmd, err := s.pool.Exec(ctx, q, sessionID, reason)
	if err != nil {
		return fmt.Errorf("revoke session: %w", err)
	}
	if cmd.RowsAffected() == 0 {
		// Already revoked or doesn't exist — idempotent success.
		return nil
	}
	return nil
}

func (s *PgSessionStore) RevokeAllForUser(ctx context.Context, userID uuid.UUID, reason string) (int, error) {
	const q = `
		UPDATE user_sessions
		   SET revoked_at = now(),
		       revoke_reason = $2
		 WHERE user_id = $1 AND revoked_at IS NULL
	`
	cmd, err := s.pool.Exec(ctx, q, userID, reason)
	if err != nil {
		return 0, fmt.Errorf("revoke all sessions for user: %w", err)
	}
	return int(cmd.RowsAffected()), nil
}

func (s *PgSessionStore) TouchLastUsed(ctx context.Context, sessionID uuid.UUID, at time.Time) error {
	const q = `UPDATE user_sessions SET last_used_at = $2 WHERE id = $1 AND revoked_at IS NULL`
	_, err := s.pool.Exec(ctx, q, sessionID, at)
	if err != nil {
		return fmt.Errorf("touch last_used_at: %w", err)
	}
	return nil
}

func (s *PgSessionStore) FindHistoricalRefreshJTI(ctx context.Context, refreshJTI string) (uuid.UUID, bool, error) {
	const q = `SELECT session_id FROM refresh_token_history WHERE refresh_jti = $1 LIMIT 1`
	var sessionID uuid.UUID
	err := s.pool.QueryRow(ctx, q, refreshJTI).Scan(&sessionID)
	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, false, nil
	}
	if err != nil {
		return uuid.Nil, false, fmt.Errorf("query refresh history: %w", err)
	}
	return sessionID, true, nil
}

func (s *PgSessionStore) ListByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]*model.UserSession, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	const q = `
		SELECT id, user_id, refresh_jti, refresh_token_hash,
		       refresh_issued_at, refresh_expires_at,
		       device_id, platform, os_version, app_version, model, user_agent,
		       host(ip_address)::text AS ip_address,
		       created_at, last_used_at, last_refreshed_at, revoked_at, revoke_reason
		  FROM user_sessions
		 WHERE user_id = $1
		 ORDER BY (revoked_at IS NULL) DESC, created_at DESC
		 LIMIT $2
	`
	rows, err := s.pool.Query(ctx, q, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("list user sessions: %w", err)
	}
	defer rows.Close()

	var out []*model.UserSession
	for rows.Next() {
		sess, err := scanSessionRow(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, sess)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return out, nil
}

// --- scanning helpers ---

// rowScanner is implemented by both pgx.Row (single-row QueryRow) and pgx.Rows.
type rowScanner interface {
	Scan(dest ...any) error
}

func scanSessionRow(r rowScanner) (*model.UserSession, error) {
	var (
		s          model.UserSession
		deviceID   *string
		platform   *string
		osVersion  *string
		appVersion *string
		modelStr   *string
		userAgent  *string
		ipAddr     *string // SELECT casts host(ip_address)::text
		lastRef    *time.Time
		revokedAt  *time.Time
		revokeRsn  *string
	)

	if err := r.Scan(
		&s.ID, &s.UserID, &s.RefreshJTI, &s.RefreshTokenHash,
		&s.RefreshIssuedAt, &s.RefreshExpiresAt,
		&deviceID, &platform, &osVersion, &appVersion, &modelStr, &userAgent, &ipAddr,
		&s.CreatedAt, &s.LastUsedAt, &lastRef, &revokedAt, &revokeRsn,
	); err != nil {
		return nil, err
	}

	s.Device = model.DeviceInfo{
		DeviceID:   deref(deviceID),
		Platform:   deref(platform),
		OSVersion:  deref(osVersion),
		AppVersion: deref(appVersion),
		Model:      deref(modelStr),
		UserAgent:  deref(userAgent),
		IPAddress:  deref(ipAddr),
	}
	s.LastRefreshedAt = lastRef
	s.RevokedAt = revokedAt
	s.RevokeReason = deref(revokeRsn)

	return &s, nil
}

func deref(p *string) string {
	if p == nil {
		return ""
	}
	return *p
}

// normalizeIP returns "" for empty/invalid input, otherwise the canonical IP string.
// SQL casts NULLIF($,”)::inet, so an empty string is stored as NULL.
func normalizeIP(s string) string {
	if s == "" {
		return ""
	}
	if ip := net.ParseIP(s); ip != nil {
		return ip.String()
	}
	return ""
}
