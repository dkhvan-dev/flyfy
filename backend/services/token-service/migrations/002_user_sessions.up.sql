-- 002_user_sessions.up.sql
-- Token Service: per-user session tracking and refresh-token rotation history.
-- Enforces single active session per user via a partial unique index.

BEGIN;

-- =============================================================
-- user_sessions: one logical session per (user_id) at a time.
-- =============================================================
CREATE TABLE IF NOT EXISTS user_sessions (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL,

    -- Refresh token currently bound to this session.
    refresh_jti        TEXT NOT NULL,
    refresh_token_hash TEXT NOT NULL,         -- sha256 hex of the refresh JWT
    refresh_issued_at  TIMESTAMPTZ NOT NULL,
    refresh_expires_at TIMESTAMPTZ NOT NULL,

    -- Device metadata
    device_id          TEXT,
    platform           TEXT,
    os_version         TEXT,
    app_version        TEXT,
    model              TEXT,
    user_agent         TEXT,
    ip_address         INET,

    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_refreshed_at  TIMESTAMPTZ,

    revoked_at         TIMESTAMPTZ,
    revoke_reason      TEXT
);

-- Single-session invariant: at most one non-revoked session per user.
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_sessions_active_user
    ON user_sessions(user_id)
    WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_created
    ON user_sessions(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_sessions_refresh_jti_active
    ON user_sessions(refresh_jti)
    WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_user_sessions_last_used_active
    ON user_sessions(last_used_at)
    WHERE revoked_at IS NULL;

-- =============================================================
-- refresh_token_history: previous refresh JTIs for reuse detection.
-- A reused (already-rotated) refresh token MUST trigger a session revoke.
-- =============================================================
CREATE TABLE IF NOT EXISTS refresh_token_history (
    id                 BIGSERIAL PRIMARY KEY,
    session_id         UUID NOT NULL REFERENCES user_sessions(id) ON DELETE CASCADE,
    refresh_jti        TEXT NOT NULL,
    refresh_token_hash TEXT NOT NULL,
    issued_at          TIMESTAMPTZ NOT NULL,
    rotated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_refresh_history_jti
    ON refresh_token_history(refresh_jti);

CREATE INDEX IF NOT EXISTS idx_refresh_history_session
    ON refresh_token_history(session_id, rotated_at DESC);

-- =============================================================
-- user_session_audit: append-only audit of session lifecycle events.
-- =============================================================
CREATE TABLE IF NOT EXISTS user_session_audit (
    id          BIGSERIAL PRIMARY KEY,
    user_id     UUID NOT NULL,
    session_id  UUID,
    event       TEXT NOT NULL,
    -- 'created' | 'replaced' | 'refreshed' | 'logout' |
    -- 'token_reuse_detected' | 'admin_revoke' | 'inactivity_expired'
    ip_address  INET,
    user_agent  TEXT,
    metadata    JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_session_audit_user_created
    ON user_session_audit(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_session_audit_event_created
    ON user_session_audit(event, created_at DESC);

COMMIT;
