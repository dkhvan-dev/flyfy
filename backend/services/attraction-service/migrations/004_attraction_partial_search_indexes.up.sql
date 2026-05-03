CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_attraction_translations_title_trgm
    ON attraction_translations USING GIN (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_attraction_translations_description_trgm
    ON attraction_translations USING GIN (description gin_trgm_ops);
