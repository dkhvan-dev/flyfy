DROP TRIGGER IF EXISTS trg_stickers_set_updated_at ON stickers;
DROP TRIGGER IF EXISTS trg_sticker_packs_set_updated_at ON sticker_packs;

DROP INDEX IF EXISTS uq_sticker_upload_sessions_user_idempotency;
DROP INDEX IF EXISTS idx_sticker_upload_sessions_user_status_expires;
DROP INDEX IF EXISTS idx_user_sticker_packs_user_removed;
DROP INDEX IF EXISTS idx_stickers_created_by_status;
DROP INDEX IF EXISTS uq_stickers_pack_file_live;
DROP INDEX IF EXISTS idx_stickers_pack_status_sort;
DROP INDEX IF EXISTS idx_sticker_packs_owner_status;
DROP INDEX IF EXISTS idx_sticker_packs_status_visibility_sort;

DROP TABLE IF EXISTS sticker_upload_sessions;
DROP TABLE IF EXISTS user_sticker_packs;

ALTER TABLE sticker_packs
    DROP CONSTRAINT IF EXISTS fk_sticker_packs_cover_sticker;

DROP TABLE IF EXISTS stickers;
DROP TABLE IF EXISTS sticker_packs;
DROP FUNCTION IF EXISTS set_updated_at();
