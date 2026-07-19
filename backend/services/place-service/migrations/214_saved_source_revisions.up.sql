CREATE SEQUENCE IF NOT EXISTS place_saved_source_revision_seq AS BIGINT MINVALUE 1;

ALTER TABLE places
    ADD COLUMN IF NOT EXISTS saved_source_revision BIGINT,
    ADD COLUMN IF NOT EXISTS saved_projection_revision BIGINT,
    ADD COLUMN IF NOT EXISTS saved_visibility_revision BIGINT;

UPDATE places
SET
    saved_source_revision = nextval('place_saved_source_revision_seq'),
    saved_projection_revision = nextval('place_saved_source_revision_seq'),
    saved_visibility_revision = nextval('place_saved_source_revision_seq')
WHERE saved_source_revision IS NULL
   OR saved_projection_revision IS NULL
   OR saved_visibility_revision IS NULL;

ALTER TABLE places
    ALTER COLUMN saved_source_revision SET DEFAULT nextval('place_saved_source_revision_seq'),
    ALTER COLUMN saved_projection_revision SET DEFAULT nextval('place_saved_source_revision_seq'),
    ALTER COLUMN saved_visibility_revision SET DEFAULT nextval('place_saved_source_revision_seq'),
    ALTER COLUMN saved_source_revision SET NOT NULL,
    ALTER COLUMN saved_projection_revision SET NOT NULL,
    ALTER COLUMN saved_visibility_revision SET NOT NULL;

ALTER TABLE places
    DROP CONSTRAINT IF EXISTS chk_places_saved_source_revision_positive,
    DROP CONSTRAINT IF EXISTS chk_places_saved_projection_revision_positive,
    DROP CONSTRAINT IF EXISTS chk_places_saved_visibility_revision_positive;

ALTER TABLE places
    ADD CONSTRAINT chk_places_saved_source_revision_positive
        CHECK (saved_source_revision > 0),
    ADD CONSTRAINT chk_places_saved_projection_revision_positive
        CHECK (saved_projection_revision > 0),
    ADD CONSTRAINT chk_places_saved_visibility_revision_positive
        CHECK (saved_visibility_revision > 0);

CREATE OR REPLACE FUNCTION bump_place_saved_source_revisions()
RETURNS trigger AS $$
DECLARE
    old_source jsonb;
    new_source jsonb;
BEGIN
    old_source := to_jsonb(OLD)
        - 'saved_source_revision'
        - 'saved_projection_revision'
        - 'saved_visibility_revision';
    new_source := to_jsonb(NEW)
        - 'saved_source_revision'
        - 'saved_projection_revision'
        - 'saved_visibility_revision';

    IF new_source IS DISTINCT FROM old_source THEN
        NEW.saved_source_revision := nextval('place_saved_source_revision_seq');
        NEW.saved_projection_revision := nextval('place_saved_source_revision_seq');
    END IF;

    IF NEW.status IS DISTINCT FROM OLD.status
       OR NEW.deleted_at IS DISTINCT FROM OLD.deleted_at THEN
        NEW.saved_visibility_revision := nextval('place_saved_source_revision_seq');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_places_saved_source_revisions ON places;
CREATE TRIGGER trg_places_saved_source_revisions
    BEFORE UPDATE ON places
    FOR EACH ROW
    EXECUTE FUNCTION bump_place_saved_source_revisions();

CREATE OR REPLACE FUNCTION bump_place_saved_projection_from_child()
RETURNS trigger AS $$
DECLARE
    old_place_id uuid;
    new_place_id uuid;
BEGIN
    IF TG_OP <> 'INSERT' THEN
        old_place_id := OLD.place_id;
    END IF;
    IF TG_OP <> 'DELETE' THEN
        new_place_id := NEW.place_id;
    END IF;

    IF old_place_id IS NOT NULL THEN
        UPDATE places
        SET
            saved_source_revision = nextval('place_saved_source_revision_seq'),
            saved_projection_revision = nextval('place_saved_source_revision_seq')
        WHERE id = old_place_id;
    END IF;

    IF new_place_id IS NOT NULL AND new_place_id IS DISTINCT FROM old_place_id THEN
        UPDATE places
        SET
            saved_source_revision = nextval('place_saved_source_revision_seq'),
            saved_projection_revision = nextval('place_saved_source_revision_seq')
        WHERE id = new_place_id;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_place_translations_saved_source_revisions ON place_translations;
CREATE TRIGGER trg_place_translations_saved_source_revisions
    AFTER INSERT OR UPDATE OR DELETE ON place_translations
    FOR EACH ROW
    EXECUTE FUNCTION bump_place_saved_projection_from_child();

DROP TRIGGER IF EXISTS trg_place_media_saved_source_revisions ON place_media;
CREATE TRIGGER trg_place_media_saved_source_revisions
    AFTER INSERT OR UPDATE OR DELETE ON place_media
    FOR EACH ROW
    EXECUTE FUNCTION bump_place_saved_projection_from_child();
