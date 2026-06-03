WITH ranked_offer_locations AS (
    SELECT
        o.product_id,
        NULLIF(BTRIM(e.country_code), '') AS country_code,
        NULLIF(BTRIM(e.city_name), '') AS city_name,
        NULLIF(BTRIM(e.departure_city_id), '') AS departure_city_id,
        ROW_NUMBER() OVER (
            PARTITION BY o.product_id
            ORDER BY
                CASE WHEN NULLIF(BTRIM(e.departure_city_id), '') IS NOT NULL THEN 0 ELSE 1 END,
                CASE WHEN NULLIF(BTRIM(e.city_name), '') IS NOT NULL THEN 0 ELSE 1 END,
                CASE WHEN e.status = 'PUBLISHED' AND e.visibility = 'PUBLIC' THEN 0 ELSE 1 END,
                e.updated_at DESC,
                e.created_at DESC
        ) AS row_num
    FROM excursion_offers o
    JOIN excursions e ON e.id = o.legacy_excursion_id
    WHERE o.deleted_at IS NULL
      AND e.deleted_at IS NULL
      AND (
          NULLIF(BTRIM(e.country_code), '') IS NOT NULL
          OR NULLIF(BTRIM(e.city_name), '') IS NOT NULL
          OR NULLIF(BTRIM(e.departure_city_id), '') IS NOT NULL
      )
),
product_offer_locations AS (
    SELECT
        product_id,
        country_code,
        city_name,
        departure_city_id
    FROM ranked_offer_locations
    WHERE row_num = 1
)
UPDATE excursion_products p
SET
    country_code = COALESCE(NULLIF(BTRIM(p.country_code), ''), l.country_code),
    city_name = COALESCE(NULLIF(BTRIM(p.city_name), ''), l.city_name),
    departure_city_id = COALESCE(NULLIF(BTRIM(p.departure_city_id), ''), l.departure_city_id),
    updated_at = NOW()
FROM product_offer_locations l
WHERE p.id = l.product_id
  AND (
      (NULLIF(BTRIM(p.country_code), '') IS NULL AND l.country_code IS NOT NULL)
      OR (NULLIF(BTRIM(p.city_name), '') IS NULL AND l.city_name IS NOT NULL)
      OR (NULLIF(BTRIM(p.departure_city_id), '') IS NULL AND l.departure_city_id IS NOT NULL)
  );
