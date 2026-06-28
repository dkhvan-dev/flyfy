-- Bridge legacy place_city_links.position with newer seed migrations that write sort_order.
-- This file intentionally sorts before 085_* seeds in the shell-based migrator.

ALTER TABLE place_city_links
    ADD COLUMN IF NOT EXISTS sort_order INT;

UPDATE place_city_links
SET sort_order = position
WHERE sort_order IS NULL;

CREATE OR REPLACE FUNCTION sync_place_city_links_sort_order()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.country_code IS NULL OR btrim(NEW.country_code) = '' THEN
        SELECT p.country_code
        INTO NEW.country_code
        FROM places p
        WHERE p.id = NEW.place_id;
    END IF;

    IF NEW.country_code IS NOT NULL THEN
        NEW.country_code := upper(btrim(NEW.country_code));
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.sort_order IS NULL THEN
            NEW.sort_order := COALESCE(NEW.position, 0);
        ELSIF NEW.position IS NULL OR NEW.position = 0 THEN
            NEW.position := NEW.sort_order;
        END IF;
    ELSE
        IF NEW.sort_order IS NULL THEN
            NEW.sort_order := COALESCE(NEW.position, 0);
        ELSIF NEW.position IS NULL THEN
            NEW.position := NEW.sort_order;
        ELSIF NEW.sort_order IS DISTINCT FROM OLD.sort_order
            AND NEW.position IS NOT DISTINCT FROM OLD.position THEN
            NEW.position := NEW.sort_order;
        ELSIF NEW.position IS DISTINCT FROM OLD.position
            AND NEW.sort_order IS NOT DISTINCT FROM OLD.sort_order THEN
            NEW.sort_order := NEW.position;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_place_city_links_sort_order_sync ON place_city_links;

CREATE TRIGGER trg_place_city_links_sort_order_sync
BEFORE INSERT OR UPDATE ON place_city_links
FOR EACH ROW
EXECUTE FUNCTION sync_place_city_links_sort_order();

ALTER TABLE place_city_links
    ALTER COLUMN sort_order SET DEFAULT 0;

UPDATE place_city_links
SET sort_order = 0
WHERE sort_order IS NULL;

ALTER TABLE place_city_links
    ALTER COLUMN sort_order SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_place_city_links_place_kind_sort_order
    ON place_city_links(place_id, kind, sort_order, city_id);
