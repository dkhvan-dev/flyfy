ALTER TABLE staff_users
    DROP CONSTRAINT IF EXISTS chk_staff_users_timezone_not_blank;

ALTER TABLE staff_users
    DROP COLUMN IF EXISTS timezone;
