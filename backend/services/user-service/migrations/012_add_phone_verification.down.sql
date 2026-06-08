BEGIN;

DROP TRIGGER IF EXISTS trg_phone_verification_set_updated_at
    ON user_phone_verification_challenges;

DROP TABLE IF EXISTS user_phone_verification_challenges;

DROP INDEX IF EXISTS uq_users_verified_primary_phone;

ALTER TABLE users
    DROP COLUMN IF EXISTS pending_phone_started_at,
    DROP COLUMN IF EXISTS pending_phone,
    DROP COLUMN IF EXISTS primary_phone_verified_at;

COMMIT;
