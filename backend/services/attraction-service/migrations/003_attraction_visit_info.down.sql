DROP INDEX IF EXISTS idx_attractions_visit_info;

ALTER TABLE attractions
    DROP COLUMN IF EXISTS visit_info;
