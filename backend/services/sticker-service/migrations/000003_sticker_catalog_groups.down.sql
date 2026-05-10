DROP TRIGGER IF EXISTS trg_sticker_groups_set_updated_at ON sticker_groups;

DROP INDEX IF EXISTS idx_stickers_keywords_gin;
DROP INDEX IF EXISTS idx_sticker_packs_official_public;
DROP INDEX IF EXISTS idx_sticker_packs_group_status_order;
DROP INDEX IF EXISTS idx_sticker_groups_status_order;
DROP INDEX IF EXISTS uq_stickers_pack_slug_live;

ALTER TABLE stickers
    DROP CONSTRAINT IF EXISTS chk_stickers_catalog_size,
    DROP CONSTRAINT IF EXISTS chk_stickers_catalog_duration,
    DROP CONSTRAINT IF EXISTS chk_stickers_catalog_dimensions;

ALTER TABLE sticker_packs
    DROP CONSTRAINT IF EXISTS chk_sticker_packs_version_positive,
    DROP CONSTRAINT IF EXISTS fk_sticker_packs_group;

ALTER TABLE stickers
    DROP COLUMN IF EXISTS checksum,
    DROP COLUMN IF EXISTS size_bytes,
    DROP COLUMN IF EXISTS duration_ms,
    DROP COLUMN IF EXISTS height,
    DROP COLUMN IF EXISTS width,
    DROP COLUMN IF EXISTS content_type,
    DROP COLUMN IF EXISTS preview_file_id,
    DROP COLUMN IF EXISTS fallback_file_id,
    DROP COLUMN IF EXISTS slug;

ALTER TABLE sticker_packs
    DROP COLUMN IF EXISTS published_at,
    DROP COLUMN IF EXISTS thumbnail_file_id,
    DROP COLUMN IF EXISTS version,
    DROP COLUMN IF EXISTS is_official,
    DROP COLUMN IF EXISTS group_id;

DROP TABLE IF EXISTS sticker_groups;
