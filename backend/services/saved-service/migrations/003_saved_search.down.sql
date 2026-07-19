-- Destructive rollback is maintenance-only. Disable Saved search and remove
-- the concurrent indexes before running this file.
SET lock_timeout = '5s';

ALTER TABLE saved_content_projections
    DROP CONSTRAINT IF EXISTS saved_content_projections_search_parity_v1_check;

DROP TRIGGER IF EXISTS trg_saved_search_sync_projection_v1
    ON saved_content_projections;
DROP FUNCTION IF EXISTS saved_search_sync_projection_v1();

ALTER TABLE saved_content_projections
    DROP COLUMN IF EXISTS search_country_kk_v1,
    DROP COLUMN IF EXISTS search_country_ru_v1,
    DROP COLUMN IF EXISTS search_country_en_v1,
    DROP COLUMN IF EXISTS search_city_kk_v1,
    DROP COLUMN IF EXISTS search_city_ru_v1,
    DROP COLUMN IF EXISTS search_city_en_v1,
    DROP COLUMN IF EXISTS search_title_kk_v1,
    DROP COLUMN IF EXISTS search_title_ru_v1,
    DROP COLUMN IF EXISTS search_title_en_v1;

DROP FUNCTION IF EXISTS saved_search_normalize_v1(TEXT);

RESET lock_timeout;
