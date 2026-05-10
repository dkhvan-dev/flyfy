CREATE TABLE IF NOT EXISTS sticker_recent_usage (
    user_id UUID NOT NULL,
    sticker_id UUID NOT NULL REFERENCES stickers(id) ON DELETE CASCADE,
    use_count INTEGER NOT NULL DEFAULT 1,
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, sticker_id),

    CONSTRAINT chk_sticker_recent_usage_count_positive
        CHECK (use_count > 0)
);

CREATE INDEX IF NOT EXISTS idx_sticker_recent_usage_user_last_used
    ON sticker_recent_usage(user_id, last_used_at DESC);

DROP TRIGGER IF EXISTS trg_sticker_recent_usage_set_updated_at ON sticker_recent_usage;
CREATE TRIGGER trg_sticker_recent_usage_set_updated_at
BEFORE UPDATE ON sticker_recent_usage
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
