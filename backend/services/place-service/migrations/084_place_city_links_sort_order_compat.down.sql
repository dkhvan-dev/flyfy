DROP INDEX IF EXISTS idx_place_city_links_place_kind_sort_order;
DROP TRIGGER IF EXISTS trg_place_city_links_sort_order_sync ON place_city_links;
DROP FUNCTION IF EXISTS sync_place_city_links_sort_order();

ALTER TABLE place_city_links
    DROP COLUMN IF EXISTS sort_order;
