DROP TRIGGER IF EXISTS trg_place_media_saved_source_revisions ON place_media;
DROP TRIGGER IF EXISTS trg_place_translations_saved_source_revisions ON place_translations;
DROP FUNCTION IF EXISTS bump_place_saved_projection_from_child();

DROP TRIGGER IF EXISTS trg_places_saved_source_revisions ON places;
DROP FUNCTION IF EXISTS bump_place_saved_source_revisions();

ALTER TABLE places
    DROP CONSTRAINT IF EXISTS chk_places_saved_visibility_revision_positive,
    DROP CONSTRAINT IF EXISTS chk_places_saved_projection_revision_positive,
    DROP CONSTRAINT IF EXISTS chk_places_saved_source_revision_positive,
    DROP COLUMN IF EXISTS saved_visibility_revision,
    DROP COLUMN IF EXISTS saved_projection_revision,
    DROP COLUMN IF EXISTS saved_source_revision;

DROP SEQUENCE IF EXISTS place_saved_source_revision_seq;
