CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    provider VARCHAR(50) NOT NULL,
    bucket VARCHAR(255) NOT NULL,
    object_key VARCHAR(1024) NOT NULL UNIQUE,

    original_name VARCHAR(512) NOT NULL,
    stored_name VARCHAR(255) NOT NULL,
    extension VARCHAR(50),

    content_type VARCHAR(255) NOT NULL,
    detected_content_type VARCHAR(255),

    size_bytes BIGINT NOT NULL CHECK (size_bytes >= 0),
    checksum_sha256 VARCHAR(128),

    visibility VARCHAR(32) NOT NULL,
    purpose VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL,

    owner_type VARCHAR(64),
    owner_id UUID,

    uploaded_by_user_id UUID,
    upload_expires_at TIMESTAMPTZ,

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_files_owner
    ON files(owner_type, owner_id);

CREATE INDEX IF NOT EXISTS idx_files_uploaded_by_user_id
    ON files(uploaded_by_user_id);

CREATE INDEX IF NOT EXISTS idx_files_purpose
    ON files(purpose);

CREATE INDEX IF NOT EXISTS idx_files_status
    ON files(status);

CREATE INDEX IF NOT EXISTS idx_files_created_at
    ON files(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_files_is_deleted
    ON files(is_deleted);

CREATE INDEX IF NOT EXISTS idx_files_bucket_object_key
    ON files(bucket, object_key);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_files_set_updated_at ON files;

CREATE TRIGGER trg_files_set_updated_at
BEFORE UPDATE ON files
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();