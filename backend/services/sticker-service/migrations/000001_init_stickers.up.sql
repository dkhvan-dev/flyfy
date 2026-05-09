CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS sticker_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(128) NOT NULL UNIQUE,
    type VARCHAR(32) NOT NULL,
    visibility VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    owner_user_id UUID,
    title JSONB NOT NULL,
    description JSONB,
    cover_sticker_id UUID,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_by_user_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_sticker_packs_type
        CHECK (type IN ('SYSTEM', 'USER_CUSTOM', 'CREATOR', 'PAID')),
    CONSTRAINT chk_sticker_packs_visibility
        CHECK (visibility IN ('PUBLIC', 'UNLISTED', 'PRIVATE')),
    CONSTRAINT chk_sticker_packs_status
        CHECK (status IN ('DRAFT', 'ACTIVE', 'IN_REVIEW', 'REJECTED', 'BLOCKED', 'DELETED')),
    CONSTRAINT chk_sticker_packs_user_custom_owner
        CHECK ((type = 'USER_CUSTOM' AND owner_user_id IS NOT NULL) OR (type <> 'USER_CUSTOM')),
    CONSTRAINT chk_sticker_packs_system_owner
        CHECK ((type = 'SYSTEM' AND owner_user_id IS NULL) OR (type <> 'SYSTEM'))
);

CREATE TABLE IF NOT EXISTS stickers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pack_id UUID NOT NULL REFERENCES sticker_packs(id),
    file_id UUID NOT NULL,
    emoji VARCHAR(64),
    keywords TEXT[] NOT NULL DEFAULT '{}',
    status VARCHAR(32) NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_by_user_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_stickers_status
        CHECK (status IN ('ACTIVE', 'IN_REVIEW', 'REJECTED', 'BLOCKED', 'DELETED'))
);

ALTER TABLE sticker_packs
    DROP CONSTRAINT IF EXISTS fk_sticker_packs_cover_sticker;

ALTER TABLE sticker_packs
    ADD CONSTRAINT fk_sticker_packs_cover_sticker
    FOREIGN KEY (cover_sticker_id) REFERENCES stickers(id);

CREATE TABLE IF NOT EXISTS user_sticker_packs (
    user_id UUID NOT NULL,
    pack_id UUID NOT NULL REFERENCES sticker_packs(id),
    source VARCHAR(32) NOT NULL,
    installed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    removed_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, pack_id),

    CONSTRAINT chk_user_sticker_packs_source
        CHECK (source IN ('DEFAULT', 'INSTALLED', 'CREATED', 'PURCHASED'))
);

CREATE TABLE IF NOT EXISTS sticker_upload_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    pack_id UUID NOT NULL REFERENCES sticker_packs(id),
    file_id UUID NOT NULL,
    status VARCHAR(32) NOT NULL,
    idempotency_key VARCHAR(255),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_sticker_upload_sessions_status
        CHECK (status IN ('PENDING_UPLOAD', 'READY', 'FAILED', 'EXPIRED'))
);

CREATE INDEX IF NOT EXISTS idx_sticker_packs_status_visibility_sort
    ON sticker_packs(status, visibility, sort_order);

CREATE INDEX IF NOT EXISTS idx_sticker_packs_owner_status
    ON sticker_packs(owner_user_id, status);

CREATE INDEX IF NOT EXISTS idx_stickers_pack_status_sort
    ON stickers(pack_id, status, sort_order);

CREATE UNIQUE INDEX IF NOT EXISTS uq_stickers_pack_file_live
    ON stickers(pack_id, file_id)
    WHERE status <> 'DELETED';

CREATE INDEX IF NOT EXISTS idx_stickers_created_by_status
    ON stickers(created_by_user_id, status);

CREATE INDEX IF NOT EXISTS idx_user_sticker_packs_user_removed
    ON user_sticker_packs(user_id, removed_at);

CREATE INDEX IF NOT EXISTS idx_sticker_upload_sessions_user_status_expires
    ON sticker_upload_sessions(user_id, status, expires_at);

CREATE UNIQUE INDEX IF NOT EXISTS uq_sticker_upload_sessions_user_idempotency
    ON sticker_upload_sessions(user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sticker_packs_set_updated_at ON sticker_packs;
CREATE TRIGGER trg_sticker_packs_set_updated_at
BEFORE UPDATE ON sticker_packs
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_stickers_set_updated_at ON stickers;
CREATE TRIGGER trg_stickers_set_updated_at
BEFORE UPDATE ON stickers
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
