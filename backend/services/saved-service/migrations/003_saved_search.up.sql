-- Saved search expand phase.
--
-- This migration is intentionally metadata-only. It must remain safe to apply
-- while saved_content_projections is large and receiving writes. Existing rows
-- are populated by the bounded saved-search-backfill command after deployment.
-- Keep SAVED_SEARCH_PRODUCT_ENABLED=false until the contract phase succeeds; see
-- SAVED_SEARCH_ROLLOUT.md.

-- SEARCH_NORMALIZATION_V1 is intentionally limited to Unicode NFKC,
-- locale-independent lower-casing, and Unicode alphanumeric token boundaries.
-- Changing it requires a new versioned expand/backfill/contract rollout.
CREATE OR REPLACE FUNCTION saved_search_normalize_v1(input_value TEXT)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
STRICT
PARALLEL SAFE
RETURN NULLIF(
    btrim(
        regexp_replace(
            lower(normalize(input_value, NFKC)),
            '[^[:alnum:]]+',
            ' ',
            'g'
        )
    ),
    ''
);

-- Adding nullable columns without a default is a catalog-only operation on
-- supported PostgreSQL versions. lock_timeout makes the deployment fail fast
-- instead of queueing an ACCESS EXCLUSIVE lock behind a long transaction.
SET lock_timeout = '5s';

ALTER TABLE saved_content_projections
    ADD COLUMN IF NOT EXISTS search_title_en_v1 TEXT,
    ADD COLUMN IF NOT EXISTS search_title_ru_v1 TEXT,
    ADD COLUMN IF NOT EXISTS search_title_kk_v1 TEXT,
    ADD COLUMN IF NOT EXISTS search_city_en_v1 TEXT,
    ADD COLUMN IF NOT EXISTS search_city_ru_v1 TEXT,
    ADD COLUMN IF NOT EXISTS search_city_kk_v1 TEXT,
    ADD COLUMN IF NOT EXISTS search_country_en_v1 TEXT,
    ADD COLUMN IF NOT EXISTS search_country_ru_v1 TEXT,
    ADD COLUMN IF NOT EXISTS search_country_kk_v1 TEXT;

CREATE OR REPLACE FUNCTION saved_search_sync_projection_v1()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.search_title_en_v1 := saved_search_normalize_v1(NEW.title_en);
    NEW.search_title_ru_v1 := saved_search_normalize_v1(NEW.title_ru);
    NEW.search_title_kk_v1 := saved_search_normalize_v1(NEW.title_kk);
    NEW.search_city_en_v1 := saved_search_normalize_v1(NEW.city_en);
    NEW.search_city_ru_v1 := saved_search_normalize_v1(NEW.city_ru);
    NEW.search_city_kk_v1 := saved_search_normalize_v1(NEW.city_kk);
    NEW.search_country_en_v1 := saved_search_normalize_v1(NEW.country_en);
    NEW.search_country_ru_v1 := saved_search_normalize_v1(NEW.country_ru);
    NEW.search_country_kk_v1 := saved_search_normalize_v1(NEW.country_kk);
    RETURN NEW;
END;
$function$;

DO $migration$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgrelid = 'saved_content_projections'::regclass
          AND tgname = 'trg_saved_search_sync_projection_v1'
          AND NOT tgisinternal
    ) THEN
        EXECUTE $ddl$
            CREATE TRIGGER trg_saved_search_sync_projection_v1
            BEFORE INSERT OR UPDATE OF
                title_en, title_ru, title_kk,
                city_en, city_ru, city_kk,
                country_en, country_ru, country_kk
            ON saved_content_projections
            FOR EACH ROW
            EXECUTE FUNCTION saved_search_sync_projection_v1()
        $ddl$;
    END IF;
END;
$migration$;

-- NOT VALID avoids a table scan during expand while immediately enforcing
-- parity for every new or updated row. The contract command validates existing
-- rows only after the resumable backfill reaches zero pending rows.
DO $migration$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'saved_content_projections'::regclass
          AND conname = 'saved_content_projections_search_parity_v1_check'
    ) THEN
        EXECUTE $ddl$
            ALTER TABLE saved_content_projections
            ADD CONSTRAINT saved_content_projections_search_parity_v1_check
            CHECK (
                search_title_en_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(title_en)
                AND search_title_ru_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(title_ru)
                AND search_title_kk_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(title_kk)
                AND search_city_en_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(city_en)
                AND search_city_ru_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(city_ru)
                AND search_city_kk_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(city_kk)
                AND search_country_en_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(country_en)
                AND search_country_ru_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(country_ru)
                AND search_country_kk_v1 IS NOT DISTINCT FROM saved_search_normalize_v1(country_kk)
            ) NOT VALID
        $ddl$;
    END IF;
END;
$migration$;

RESET lock_timeout;
