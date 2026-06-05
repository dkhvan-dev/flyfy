DROP TRIGGER IF EXISTS trg_user_profiles_display_name_immutable ON user_profiles;
DROP FUNCTION IF EXISTS prevent_user_profile_display_name_change();

ALTER TABLE user_profiles
    DROP CONSTRAINT IF EXISTS user_profiles_display_name_not_blank;

DROP INDEX IF EXISTS uq_user_profiles_display_name_ci;
DROP INDEX IF EXISTS idx_user_profiles_display_name;

ALTER TABLE user_profiles
    RENAME COLUMN display_name TO nickname;

UPDATE user_profiles
SET nickname = NULL
WHERE nickname IS NOT NULL
  AND BTRIM(nickname) = '';

CREATE INDEX IF NOT EXISTS idx_user_profiles_nickname
    ON user_profiles(nickname);

CREATE UNIQUE INDEX IF NOT EXISTS uq_user_profiles_nickname_ci
    ON user_profiles (LOWER(BTRIM(nickname)))
    WHERE nickname IS NOT NULL AND BTRIM(nickname) <> '';

ALTER TABLE user_profiles
    ADD CONSTRAINT user_profiles_nickname_not_blank
    CHECK (nickname IS NULL OR BTRIM(nickname) <> '');

CREATE OR REPLACE FUNCTION prevent_user_profile_nickname_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.nickname IS NOT NULL
        AND BTRIM(OLD.nickname) <> ''
        AND (
            NEW.nickname IS NULL
            OR BTRIM(NEW.nickname) IS DISTINCT FROM BTRIM(OLD.nickname)
        )
    THEN
        RAISE EXCEPTION 'nickname cannot be changed'
            USING ERRCODE = '23514',
                  CONSTRAINT = 'user_profiles_nickname_immutable';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_profiles_nickname_immutable
BEFORE UPDATE OF nickname ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION prevent_user_profile_nickname_change();
