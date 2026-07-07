CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS search_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    entity_version BIGINT NOT NULL DEFAULT 1,
    locale TEXT NOT NULL DEFAULT 'en',
    title JSONB NOT NULL DEFAULT '{}'::jsonb,
    subtitle JSONB NOT NULL DEFAULT '{}'::jsonb,
    description JSONB NOT NULL DEFAULT '{}'::jsonb,
    tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    category_codes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    city_id TEXT,
    country_code TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    geo_point GEOGRAPHY(Point, 4326),
    price_min NUMERIC(12, 2),
    price_max NUMERIC(12, 2),
    currency TEXT,
    rating NUMERIC(3, 2),
    review_count INT NOT NULL DEFAULT 0,
    popularity_score DOUBLE PRECISION NOT NULL DEFAULT 0,
    freshness_score DOUBLE PRECISION NOT NULL DEFAULT 0,
    trust_score DOUBLE PRECISION NOT NULL DEFAULT 0,
    availability_status TEXT,
    available_from TIMESTAMPTZ,
    available_to TIMESTAMPTZ,
    visibility TEXT NOT NULL DEFAULT 'public',
    moderation_status TEXT NOT NULL DEFAULT 'approved',
    owner_user_id UUID,
    preview_image_file_id UUID,
    deep_link TEXT NOT NULL,
    search_text TEXT NOT NULL DEFAULT '',
    search_text_normalized TEXT NOT NULL DEFAULT '',
    search_variants TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    search_vector TSVECTOR NOT NULL DEFAULT ''::tsvector,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    indexed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT search_documents_domain_check CHECK (
        domain IN ('activity', 'excursion', 'place', 'guide', 'community', 'user')
    ),
    CONSTRAINT search_documents_excludes_private_domains CHECK (
        domain NOT IN ('route', 'routes', 'checklist', 'checklists', 'chat', 'chats')
    ),
    CONSTRAINT search_documents_visibility_check CHECK (
        visibility IN ('public', 'authenticated', 'hidden')
    ),
    CONSTRAINT search_documents_moderation_status_check CHECK (
        moderation_status IN ('approved', 'pending', 'rejected', 'blocked')
    ),
    CONSTRAINT search_documents_latitude_check CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT search_documents_longitude_check CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
);

CREATE OR REPLACE FUNCTION refresh_search_document_derived_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.geo_point := CASE
        WHEN NEW.latitude IS NULL OR NEW.longitude IS NULL THEN NULL
        ELSE ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::GEOGRAPHY
    END;

    NEW.search_vector :=
        setweight(to_tsvector('simple', coalesce(NEW.search_text_normalized, '')), 'A') ||
        setweight(to_tsvector('simple', array_to_string(NEW.search_variants, ' ')), 'B') ||
        setweight(to_tsvector('simple', array_to_string(NEW.tags, ' ')), 'C');

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_search_documents_refresh_derived_fields ON search_documents;
CREATE TRIGGER trg_search_documents_refresh_derived_fields
BEFORE INSERT OR UPDATE OF latitude, longitude, search_text_normalized, search_variants, tags
ON search_documents
FOR EACH ROW
EXECUTE FUNCTION refresh_search_document_derived_fields();

UPDATE search_documents
SET search_text_normalized = search_text_normalized;

CREATE UNIQUE INDEX IF NOT EXISTS idx_search_documents_entity_unique
    ON search_documents (domain, entity_id, locale);

CREATE INDEX IF NOT EXISTS idx_search_documents_vector
    ON search_documents USING GIN (search_vector);

CREATE INDEX IF NOT EXISTS idx_search_documents_trgm
    ON search_documents USING GIN (search_text_normalized gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_search_documents_geo
    ON search_documents USING GIST (geo_point);

CREATE INDEX IF NOT EXISTS idx_search_documents_domain_visibility_moderation
    ON search_documents (domain, visibility, moderation_status)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_search_documents_country_city
    ON search_documents (country_code, city_id)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_search_documents_updated_at
    ON search_documents (updated_at DESC);

CREATE TABLE IF NOT EXISTS search_document_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_service TEXT NOT NULL,
    source_event_id TEXT NOT NULL,
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    attempt_count INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivered_at TIMESTAMPTZ,
    dead_at TIMESTAMPTZ,
    CONSTRAINT search_document_events_status_check CHECK (
        status IN ('pending', 'processing', 'retry', 'delivered', 'dead')
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_search_document_events_source_unique
    ON search_document_events (source_service, source_event_id);

CREATE INDEX IF NOT EXISTS idx_search_document_events_due
    ON search_document_events (next_attempt_at, created_at)
    WHERE status IN ('pending', 'retry');
