WITH legacy_official_packs AS (
    SELECT id
    FROM sticker_packs
    WHERE type = 'SYSTEM'
      AND is_official = TRUE
      AND slug NOT LIKE 'inflap-tgs-%'
)
UPDATE sticker_packs
SET cover_sticker_id = NULL,
    updated_at = NOW()
WHERE id IN (SELECT id FROM legacy_official_packs);

WITH legacy_official_packs AS (
    SELECT id
    FROM sticker_packs
    WHERE type = 'SYSTEM'
      AND is_official = TRUE
      AND slug NOT LIKE 'inflap-tgs-%'
)
UPDATE stickers
SET status = 'DELETED',
    updated_at = NOW()
WHERE pack_id IN (SELECT id FROM legacy_official_packs)
  AND status <> 'DELETED';

UPDATE sticker_packs
SET status = 'DELETED',
    updated_at = NOW()
WHERE type = 'SYSTEM'
  AND is_official = TRUE
  AND slug NOT LIKE 'inflap-tgs-%'
  AND status <> 'DELETED';
