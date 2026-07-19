-- Temporary operational index: it contains only projections whose nine search
-- fields still require backfill and becomes empty as batches commit.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_saved_content_projections_search_backfill_v1
    ON saved_content_projections (entity_type, entity_id)
    WHERE search_title_en_v1 IS DISTINCT FROM saved_search_normalize_v1(title_en)
       OR search_title_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(title_ru)
       OR search_title_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(title_kk)
       OR search_city_en_v1 IS DISTINCT FROM saved_search_normalize_v1(city_en)
       OR search_city_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(city_ru)
       OR search_city_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(city_kk)
       OR search_country_en_v1 IS DISTINCT FROM saved_search_normalize_v1(country_en)
       OR search_country_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(country_ru)
       OR search_country_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(country_kk);
