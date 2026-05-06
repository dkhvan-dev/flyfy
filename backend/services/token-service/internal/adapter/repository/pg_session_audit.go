package repository

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
)

// PgSessionAuditLogger persists session-lifecycle events to user_session_audit
// AND mirrors them to zerolog for live observability.
//
// Failures to write to Postgres are logged at WARN and never propagated — auditing
// is best-effort and must not block auth flows.
type PgSessionAuditLogger struct {
	pool   *pgxpool.Pool
	logger zerolog.Logger
}

func NewPgSessionAuditLogger(pool *pgxpool.Pool, logger zerolog.Logger) *PgSessionAuditLogger {
	return &PgSessionAuditLogger{
		pool:   pool,
		logger: logger.With().Str("component", "session_audit").Logger(),
	}
}

func (a *PgSessionAuditLogger) LogSessionEvent(
	ctx context.Context,
	userID uuid.UUID,
	sessionID *uuid.UUID,
	event string,
	ipAddress, userAgent string,
	metadata map[string]string,
) {
	// Live log
	logEvent := a.logger.Info().
		Str("user_id", userID.String()).
		Str("event", event)
	if sessionID != nil {
		logEvent = logEvent.Str("session_id", sessionID.String())
	}
	if ipAddress != "" {
		logEvent = logEvent.Str("ip", ipAddress)
	}
	if userAgent != "" {
		logEvent = logEvent.Str("user_agent", userAgent)
	}
	for k, v := range metadata {
		logEvent = logEvent.Str(k, v)
	}
	logEvent.Msg("session event")

	// Persist (best-effort)
	metaJSON, err := json.Marshal(metadata)
	if err != nil || metadata == nil {
		metaJSON = []byte(`{}`)
	}

	const q = `
		INSERT INTO user_session_audit (user_id, session_id, event, ip_address, user_agent, metadata)
		VALUES ($1, $2, $3, NULLIF($4,'')::inet, NULLIF($5,''), $6::jsonb)
	`

	var sid any
	if sessionID != nil {
		sid = *sessionID
	}

	if _, err := a.pool.Exec(ctx, q, userID, sid, event, normalizeIP(ipAddress), userAgent, string(metaJSON)); err != nil {
		a.logger.Warn().Err(err).Str("event", event).Msg("failed to persist session audit event")
	}
}
