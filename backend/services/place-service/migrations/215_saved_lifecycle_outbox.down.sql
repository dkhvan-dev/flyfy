DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM place_saved_lifecycle_outbox LIMIT 1) THEN
        RAISE EXCEPTION 'cannot remove Saved lifecycle outbox while retained events exist'
            USING ERRCODE = '55000';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_places_saved_lifecycle_outbox ON places;
DROP FUNCTION IF EXISTS enqueue_place_saved_lifecycle_event();
DROP FUNCTION IF EXISTS current_place_saved_visibility(uuid, varchar, timestamptz, varchar);

DROP TRIGGER IF EXISTS trg_protect_place_saved_lifecycle_outbox ON place_saved_lifecycle_outbox;
DROP FUNCTION IF EXISTS protect_place_saved_lifecycle_outbox();

DROP TABLE place_saved_lifecycle_outbox;

-- Restore the revision behavior installed by migration 214.
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
