DROP TRIGGER IF EXISTS trg_sticker_recent_usage_set_updated_at ON sticker_recent_usage;
DROP INDEX IF EXISTS idx_sticker_recent_usage_user_last_used;
DROP TABLE IF EXISTS sticker_recent_usage;
