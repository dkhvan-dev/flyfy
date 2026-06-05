BEGIN;

ALTER TABLE auth_users
    ADD COLUMN IF NOT EXISTS email VARCHAR(320),
    ADD COLUMN IF NOT EXISTS password_hash TEXT,
    ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS uq_auth_users_email_ci
    ON auth_users (LOWER(BTRIM(email)))
    WHERE email IS NOT NULL AND BTRIM(email) <> '';

CREATE INDEX IF NOT EXISTS idx_auth_users_email
    ON auth_users(email)
    WHERE email IS NOT NULL;

COMMIT;
