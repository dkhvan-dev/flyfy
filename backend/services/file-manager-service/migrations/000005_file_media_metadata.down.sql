ALTER TABLE files
    DROP CONSTRAINT IF EXISTS files_thumbnail_file_id_fk,
    DROP CONSTRAINT IF EXISTS files_duration_ms_positive,
    DROP CONSTRAINT IF EXISTS files_height_positive,
    DROP CONSTRAINT IF EXISTS files_width_positive;

ALTER TABLE files
    DROP COLUMN IF EXISTS thumbnail_file_id,
    DROP COLUMN IF EXISTS duration_ms,
    DROP COLUMN IF EXISTS height,
    DROP COLUMN IF EXISTS width;
