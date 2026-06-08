BEGIN;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS primary_phone_verified_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS pending_phone VARCHAR(32),
    ADD COLUMN IF NOT EXISTS pending_phone_started_at TIMESTAMPTZ;

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_verified_primary_phone
    ON users (primary_phone)
    WHERE primary_phone IS NOT NULL
      AND BTRIM(primary_phone) <> ''
      AND primary_phone_verified_at IS NOT NULL
      AND is_deleted = FALSE;

CREATE TABLE IF NOT EXISTS user_phone_verification_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone_e164 VARCHAR(32) NOT NULL,
    code_hash TEXT NOT NULL,
    status VARCHAR(32) NOT NULL,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    resend_count INTEGER NOT NULL DEFAULT 0,
    last_sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_phone_verification_user_status
    ON user_phone_verification_challenges (user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_phone_verification_expires_at
    ON user_phone_verification_challenges (expires_at)
    WHERE status = 'PENDING';

DROP TRIGGER IF EXISTS trg_phone_verification_set_updated_at
    ON user_phone_verification_challenges;
CREATE TRIGGER trg_phone_verification_set_updated_at
BEFORE UPDATE ON user_phone_verification_challenges
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

COMMIT;
