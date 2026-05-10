CREATE TABLE IF NOT EXISTS sticker_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(128) NOT NULL UNIQUE,
    title JSONB NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_sticker_groups_status
        CHECK (status IN ('DRAFT', 'ACTIVE', 'IN_REVIEW', 'REJECTED', 'BLOCKED', 'DELETED'))
);

ALTER TABLE sticker_packs
    ADD COLUMN IF NOT EXISTS group_id UUID,
    ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS thumbnail_file_id UUID,
    ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;

ALTER TABLE stickers
    ADD COLUMN IF NOT EXISTS slug VARCHAR(128),
    ADD COLUMN IF NOT EXISTS fallback_file_id UUID,
    ADD COLUMN IF NOT EXISTS preview_file_id UUID,
    ADD COLUMN IF NOT EXISTS content_type VARCHAR(128),
    ADD COLUMN IF NOT EXISTS width INTEGER,
    ADD COLUMN IF NOT EXISTS height INTEGER,
    ADD COLUMN IF NOT EXISTS duration_ms INTEGER,
    ADD COLUMN IF NOT EXISTS size_bytes BIGINT,
    ADD COLUMN IF NOT EXISTS checksum TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_sticker_packs_group'
    ) THEN
        ALTER TABLE sticker_packs
            ADD CONSTRAINT fk_sticker_packs_group
            FOREIGN KEY (group_id) REFERENCES sticker_groups(id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_sticker_packs_version_positive'
    ) THEN
        ALTER TABLE sticker_packs
            ADD CONSTRAINT chk_sticker_packs_version_positive
            CHECK (version > 0);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_stickers_catalog_dimensions'
    ) THEN
        ALTER TABLE stickers
            ADD CONSTRAINT chk_stickers_catalog_dimensions
            CHECK (
                (width IS NULL AND height IS NULL)
                OR (width > 0 AND height > 0)
            );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_stickers_catalog_duration'
    ) THEN
        ALTER TABLE stickers
            ADD CONSTRAINT chk_stickers_catalog_duration
            CHECK (duration_ms IS NULL OR (duration_ms > 0 AND duration_ms <= 3000));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_stickers_catalog_size'
    ) THEN
        ALTER TABLE stickers
            ADD CONSTRAINT chk_stickers_catalog_size
            CHECK (size_bytes IS NULL OR size_bytes > 0);
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_stickers_pack_slug_live
    ON stickers(pack_id, slug)
    WHERE slug IS NOT NULL AND status <> 'DELETED';

CREATE INDEX IF NOT EXISTS idx_sticker_groups_status_order
    ON sticker_groups(status, display_order, created_at);

CREATE INDEX IF NOT EXISTS idx_sticker_packs_group_status_order
    ON sticker_packs(group_id, status, sort_order)
    WHERE group_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sticker_packs_official_public
    ON sticker_packs(is_official, visibility, status, sort_order);

CREATE INDEX IF NOT EXISTS idx_stickers_keywords_gin
    ON stickers USING GIN(keywords);

DROP TRIGGER IF EXISTS trg_sticker_groups_set_updated_at ON sticker_groups;
CREATE TRIGGER trg_sticker_groups_set_updated_at
BEFORE UPDATE ON sticker_groups
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
