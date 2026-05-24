ALTER TABLE guide_profiles
    ADD COLUMN IF NOT EXISTS status_reason TEXT,
    ADD COLUMN IF NOT EXISTS status_changed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS status_changed_by UUID;

CREATE INDEX IF NOT EXISTS idx_guide_profiles_revoked_status
    ON guide_profiles(status, status_changed_at DESC)
    WHERE status = 'REVOKED';
