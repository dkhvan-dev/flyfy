-- Data backfill is intentionally irreversible: clearing departure_city_id on
-- rollback would hide existing excursions from city filters again.
SELECT 1;
