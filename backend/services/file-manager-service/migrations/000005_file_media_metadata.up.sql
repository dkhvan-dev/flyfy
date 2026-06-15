ALTER TABLE files
    ADD COLUMN width INTEGER,
    ADD COLUMN height INTEGER,
    ADD COLUMN duration_ms INTEGER,
    ADD COLUMN thumbnail_file_id UUID;

ALTER TABLE files
    ADD CONSTRAINT files_width_positive
        CHECK (width IS NULL OR width > 0) NOT VALID,
    ADD CONSTRAINT files_height_positive
        CHECK (height IS NULL OR height > 0) NOT VALID,
    ADD CONSTRAINT files_duration_ms_positive
        CHECK (duration_ms IS NULL OR duration_ms > 0) NOT VALID,
    ADD CONSTRAINT files_thumbnail_file_id_fk
        FOREIGN KEY (thumbnail_file_id) REFERENCES files(id) ON DELETE SET NULL NOT VALID;

ALTER TABLE files VALIDATE CONSTRAINT files_width_positive;
ALTER TABLE files VALIDATE CONSTRAINT files_height_positive;
ALTER TABLE files VALIDATE CONSTRAINT files_duration_ms_positive;
ALTER TABLE files VALIDATE CONSTRAINT files_thumbnail_file_id_fk;
