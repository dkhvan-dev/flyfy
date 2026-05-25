ALTER TABLE staff_users
    ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'Asia/Almaty';

ALTER TABLE staff_users
    DROP CONSTRAINT IF EXISTS chk_staff_users_timezone_not_blank;

ALTER TABLE staff_users
    ADD CONSTRAINT chk_staff_users_timezone_not_blank
        CHECK (btrim(timezone) <> '');
