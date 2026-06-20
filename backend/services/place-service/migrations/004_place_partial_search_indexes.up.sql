CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_place_translations_title_trgm
    ON place_translations USING GIN (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_place_translations_description_trgm
    ON place_translations USING GIN (description gin_trgm_ops);
