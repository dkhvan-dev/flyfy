DROP INDEX IF EXISTS idx_guide_profiles_revoked_status;

ALTER TABLE guide_profiles
    DROP COLUMN IF EXISTS status_changed_by,
    DROP COLUMN IF EXISTS status_changed_at,
    DROP COLUMN IF EXISTS status_reason;
