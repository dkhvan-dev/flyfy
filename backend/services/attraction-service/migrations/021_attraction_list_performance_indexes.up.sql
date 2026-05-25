CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_latest
    ON attractions (country_code, city_id, created_at DESC, id)
    WHERE deleted_at IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_category_latest
    ON attractions (country_code, city_id, category, created_at DESC, id)
    WHERE deleted_at IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_category_latest
    ON attractions (country_code, category, created_at DESC, id)
    WHERE deleted_at IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_rating
    ON attractions (country_code, city_id, rating DESC, review_count DESC, created_at DESC, id)
    WHERE deleted_at IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_price
    ON attractions (country_code, city_id, price_amount, created_at DESC, id)
    WHERE deleted_at IS NULL
      AND price_amount IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_duration_hours
    ON attractions (
        country_code,
        city_id,
        (CASE WHEN duration_unit = 'DAYS' THEN duration_value * 24 ELSE duration_value END),
        created_at DESC,
        id
    )
    WHERE deleted_at IS NULL
      AND duration_value IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attraction_city_links_kind_city_attraction
    ON attraction_city_links (kind, city_id, attraction_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attraction_city_links_attraction_kind_position
    ON attraction_city_links (attraction_id, kind, position, city_id);
