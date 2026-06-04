WITH custom_packs AS (
    SELECT id
    FROM sticker_packs
    WHERE type = 'USER_CUSTOM'
)
UPDATE sticker_packs
SET cover_sticker_id = NULL
WHERE id IN (SELECT id FROM custom_packs);

WITH custom_stickers AS (
    SELECT s.id
    FROM stickers s
    JOIN sticker_packs p ON p.id = s.pack_id
    WHERE p.type = 'USER_CUSTOM'
)
UPDATE sticker_packs
SET cover_sticker_id = NULL
WHERE cover_sticker_id IN (SELECT id FROM custom_stickers);

WITH custom_packs AS (
    SELECT id
    FROM sticker_packs
    WHERE type = 'USER_CUSTOM'
)
DELETE FROM sticker_upload_sessions
WHERE pack_id IN (SELECT id FROM custom_packs);

WITH custom_packs AS (
    SELECT id
    FROM sticker_packs
    WHERE type = 'USER_CUSTOM'
)
DELETE FROM user_sticker_packs
WHERE pack_id IN (SELECT id FROM custom_packs);

WITH custom_stickers AS (
    SELECT s.id
    FROM stickers s
    JOIN sticker_packs p ON p.id = s.pack_id
    WHERE p.type = 'USER_CUSTOM'
)
DELETE FROM sticker_recent_usage
WHERE sticker_id IN (SELECT id FROM custom_stickers);

WITH custom_packs AS (
    SELECT id
    FROM sticker_packs
    WHERE type = 'USER_CUSTOM'
)
DELETE FROM stickers
WHERE pack_id IN (SELECT id FROM custom_packs);

DELETE FROM sticker_packs
WHERE type = 'USER_CUSTOM';
