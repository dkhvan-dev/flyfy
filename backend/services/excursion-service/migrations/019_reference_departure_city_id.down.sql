-- 019 only normalizes legacy UUID departure_city_id columns to reference city
-- slugs. The canonical schema from 018 already uses VARCHAR(64), so rolling
-- this compatibility migration back must not convert the column to UUID again.
SELECT 1;
