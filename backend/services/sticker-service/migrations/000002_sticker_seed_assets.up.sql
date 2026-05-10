CREATE TABLE IF NOT EXISTS sticker_seed_assets (
    seed_key TEXT PRIMARY KEY,
    pack_id UUID NOT NULL REFERENCES sticker_packs(id) ON DELETE CASCADE,
    sticker_id UUID NOT NULL REFERENCES stickers(id) ON DELETE CASCADE,
    file_id UUID NOT NULL,
    checksum_sha256 CHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sticker_seed_assets_pack
    ON sticker_seed_assets(pack_id);
