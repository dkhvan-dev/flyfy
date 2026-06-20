DROP INDEX IF EXISTS idx_places_visit_info;

ALTER TABLE places
    DROP COLUMN IF EXISTS visit_info;
