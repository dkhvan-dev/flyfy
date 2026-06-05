BEGIN;

DROP INDEX IF EXISTS idx_auth_users_email;
DROP INDEX IF EXISTS uq_auth_users_email_ci;

ALTER TABLE auth_users
    DROP COLUMN IF EXISTS email_verified,
    DROP COLUMN IF EXISTS password_hash,
    DROP COLUMN IF EXISTS email;

COMMIT;
