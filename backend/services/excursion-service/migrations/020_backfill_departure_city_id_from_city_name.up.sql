WITH normalized_excursions AS (
    SELECT
        id,
        CASE lower(trim(city_name))
            WHEN 'алматы' THEN 'almaty'
            ELSE NULLIF(
                trim(both '-' from regexp_replace(lower(trim(city_name)), '[^[:alnum:]]+', '-', 'g')),
                ''
            )
        END AS city_slug
    FROM excursions
    WHERE departure_city_id IS NULL
      AND city_name IS NOT NULL
      AND trim(city_name) <> ''
),
valid_excursions AS (
    SELECT id, city_slug
    FROM normalized_excursions
    WHERE city_slug ~ '^[a-z0-9][a-z0-9-]{0,63}$'
)
UPDATE excursions e
SET departure_city_id = v.city_slug
FROM valid_excursions v
WHERE e.id = v.id
  AND e.departure_city_id IS NULL;

WITH normalized_products AS (
    SELECT
        id,
        CASE lower(trim(city_name))
            WHEN 'алматы' THEN 'almaty'
            ELSE NULLIF(
                trim(both '-' from regexp_replace(lower(trim(city_name)), '[^[:alnum:]]+', '-', 'g')),
                ''
            )
        END AS city_slug
    FROM excursion_products
    WHERE departure_city_id IS NULL
      AND city_name IS NOT NULL
      AND trim(city_name) <> ''
),
valid_products AS (
    SELECT id, city_slug
    FROM normalized_products
    WHERE city_slug ~ '^[a-z0-9][a-z0-9-]{0,63}$'
)
UPDATE excursion_products p
SET departure_city_id = v.city_slug
FROM valid_products v
WHERE p.id = v.id
  AND p.departure_city_id IS NULL;
