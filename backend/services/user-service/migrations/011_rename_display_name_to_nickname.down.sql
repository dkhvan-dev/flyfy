DROP TRIGGER IF EXISTS trg_user_profiles_nickname_immutable ON user_profiles;
DROP FUNCTION IF EXISTS prevent_user_profile_nickname_change();

ALTER TABLE user_profiles
    DROP CONSTRAINT IF EXISTS user_profiles_nickname_not_blank;

DROP INDEX IF EXISTS uq_user_profiles_nickname_ci;
DROP INDEX IF EXISTS idx_user_profiles_nickname;

ALTER TABLE user_profiles
    RENAME COLUMN nickname TO display_name;

CREATE INDEX IF NOT EXISTS idx_user_profiles_display_name
    ON user_profiles(display_name);

CREATE UNIQUE INDEX IF NOT EXISTS uq_user_profiles_display_name_ci
    ON user_profiles (LOWER(BTRIM(display_name)))
    WHERE display_name IS NOT NULL AND BTRIM(display_name) <> '';

ALTER TABLE user_profiles
    ADD CONSTRAINT user_profiles_display_name_not_blank
    CHECK (display_name IS NULL OR BTRIM(display_name) <> '');

CREATE OR REPLACE FUNCTION prevent_user_profile_display_name_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.display_name IS NOT NULL
        AND BTRIM(OLD.display_name) <> ''
        AND (
            NEW.display_name IS NULL
            OR BTRIM(NEW.display_name) IS DISTINCT FROM BTRIM(OLD.display_name)
        )
    THEN
        RAISE EXCEPTION 'nickname cannot be changed'
            USING ERRCODE = '23514',
                  CONSTRAINT = 'user_profiles_display_name_immutable';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_profiles_display_name_immutable
BEFORE UPDATE OF display_name ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION prevent_user_profile_display_name_change();
