CREATE TABLE excursion_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    canonical_key TEXT NOT NULL,

    landmark_id UUID NULL,
    landmark_name VARCHAR(180) NULL,

    title VARCHAR(160) NOT NULL,
    summary VARCHAR(240) NOT NULL,
    description TEXT NOT NULL,
    category_slug VARCHAR(100) NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC',

    duration_minutes INT NOT NULL,
    country_code VARCHAR(10) NULL,
    city_name VARCHAR(150) NULL,
    latitude NUMERIC(10,7) NULL,
    longitude NUMERIC(10,7) NULL,
    map_url TEXT NULL,
    cover_file_id UUID NULL,

    min_price_amount NUMERIC(12,2) NULL,
    currency VARCHAR(10) NULL,
    offers_count INT NOT NULL DEFAULT 0,
    published_offers_count INT NOT NULL DEFAULT 0,
    next_available_at TIMESTAMPTZ NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_excursion_products_canonical_key UNIQUE (canonical_key),
    CONSTRAINT chk_excursion_products_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT chk_excursion_products_visibility
        CHECK (visibility IN ('PUBLIC', 'UNLISTED', 'PRIVATE')),
    CONSTRAINT chk_excursion_products_duration
        CHECK (duration_minutes BETWEEN 15 AND 43200),
    CONSTRAINT chk_excursion_products_offer_counts
        CHECK (offers_count >= 0 AND published_offers_count >= 0 AND published_offers_count <= offers_count)
);

CREATE INDEX idx_excursion_products_public_listing
    ON excursion_products(status, visibility, updated_at DESC)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC';
CREATE INDEX idx_excursion_products_category
    ON excursion_products(category_slug)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC';
CREATE INDEX idx_excursion_products_country_city
    ON excursion_products(country_code, city_name)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC';
CREATE INDEX idx_excursion_products_min_price
    ON excursion_products(min_price_amount)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC';
CREATE INDEX idx_excursion_products_landmark_id
    ON excursion_products(landmark_id)
    WHERE landmark_id IS NOT NULL;

CREATE TABLE excursion_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES excursion_products(id) ON DELETE CASCADE,
    legacy_excursion_id UUID NULL REFERENCES excursions(id) ON DELETE SET NULL,

    guide_profile_id UUID NOT NULL,
    guide_user_id UUID NOT NULL,

    title VARCHAR(160) NOT NULL DEFAULT '',
    summary VARCHAR(240) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',

    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC',

    duration_minutes INT NOT NULL,
    max_group_size INT NOT NULL,
    meeting_point VARCHAR(300) NOT NULL,
    latitude NUMERIC(10,7) NULL,
    longitude NUMERIC(10,7) NULL,
    map_url TEXT NULL,

    price_amount NUMERIC(12,2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    cover_file_id UUID NULL,

    published_at TIMESTAMPTZ NULL,
    deleted_at TIMESTAMPTZ NULL,
    revision INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_excursion_offers_legacy_excursion_id UNIQUE (legacy_excursion_id),
    CONSTRAINT chk_excursion_offers_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT chk_excursion_offers_visibility
        CHECK (visibility IN ('PUBLIC', 'UNLISTED', 'PRIVATE')),
    CONSTRAINT chk_excursion_offers_duration
        CHECK (duration_minutes BETWEEN 15 AND 43200),
    CONSTRAINT chk_excursion_offers_group_size
        CHECK (max_group_size BETWEEN 1 AND 100),
    CONSTRAINT chk_excursion_offers_price
        CHECK (price_amount >= 0)
);

CREATE INDEX idx_excursion_offers_product_public
    ON excursion_offers(product_id, price_amount, updated_at DESC)
    WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC' AND deleted_at IS NULL;
CREATE INDEX idx_excursion_offers_guide_user_id
    ON excursion_offers(guide_user_id, updated_at DESC)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_excursion_offers_guide_profile_id
    ON excursion_offers(guide_profile_id, updated_at DESC)
    WHERE deleted_at IS NULL;

CREATE TABLE excursion_offer_languages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID NOT NULL REFERENCES excursion_offers(id) ON DELETE CASCADE,
    language_code VARCHAR(20) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_excursion_offer_languages UNIQUE (offer_id, language_code)
);

CREATE INDEX idx_excursion_offer_languages_language_code
    ON excursion_offer_languages(language_code);

CREATE TABLE excursion_offer_included_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID NOT NULL REFERENCES excursion_offers(id) ON DELETE CASCADE,
    item_text VARCHAR(180) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE excursion_departures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID NOT NULL REFERENCES excursion_offers(id) ON DELETE CASCADE,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    capacity INT NOT NULL,
    reserved_seats INT NOT NULL DEFAULT 0,
    confirmed_seats INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_excursion_departures_time CHECK (ends_at > starts_at),
    CONSTRAINT chk_excursion_departures_capacity CHECK (capacity > 0),
    CONSTRAINT chk_excursion_departures_seats
        CHECK (reserved_seats >= 0 AND confirmed_seats >= 0 AND reserved_seats + confirmed_seats <= capacity),
    CONSTRAINT chk_excursion_departures_status
        CHECK (status IN ('SCHEDULED', 'CANCELLED', 'COMPLETED'))
);

CREATE INDEX idx_excursion_departures_offer_start
    ON excursion_departures(offer_id, starts_at)
    WHERE status = 'SCHEDULED';
CREATE INDEX idx_excursion_departures_start
    ON excursion_departures(starts_at)
    WHERE status = 'SCHEDULED';

WITH source_excursions AS (
    SELECT
        t.*,
        tc.file_id AS cover_file_id,
        CASE
            WHEN t.landmark_id IS NOT NULL THEN 'landmark:' || t.landmark_id::text
            ELSE 'custom:'
                || COALESCE(NULLIF(lower(trim(t.country_code)), ''), 'unknown-country')
                || ':'
                || COALESCE(NULLIF(trim(both '-' from regexp_replace(lower(trim(t.city_name)), '[^[:alnum:]]+', '-', 'g')), ''), 'unknown-city')
                || ':'
                || COALESCE(NULLIF(trim(both '-' from regexp_replace(lower(trim(t.category_slug)), '[^[:alnum:]]+', '-', 'g')), ''), 'uncategorized')
                || ':'
                || COALESCE(NULLIF(trim(both '-' from regexp_replace(lower(trim(t.title)), '[^[:alnum:]]+', '-', 'g')), ''), t.id::text)
        END AS canonical_key
    FROM excursions t
    LEFT JOIN excursion_covers tc ON tc.excursion_id = t.id
    WHERE t.deleted_at IS NULL
),
product_source AS (
    SELECT DISTINCT ON (canonical_key)
        canonical_key,
        landmark_id,
        landmark_name,
        CASE
            WHEN landmark_name IS NOT NULL AND trim(landmark_name) <> '' THEN trim(landmark_name)
            ELSE title
        END AS title,
        CASE
            WHEN landmark_name IS NOT NULL AND trim(landmark_name) <> '' THEN 'Compare guide offers for ' || trim(landmark_name) || '.'
            ELSE summary
        END AS summary,
        CASE
            WHEN landmark_name IS NOT NULL AND trim(landmark_name) <> ''
                THEN 'Choose a guide, language, price, meeting point, and included options before booking.'
            ELSE description
        END AS description,
        category_slug,
        CASE
            WHEN status = 'PUBLISHED' AND visibility = 'PUBLIC' THEN 'PUBLISHED'
            ELSE 'DRAFT'
        END AS status,
        visibility,
        duration_minutes,
        country_code,
        city_name,
        latitude,
        longitude,
        map_url,
        CASE
            WHEN landmark_id IS NOT NULL THEN NULL
            ELSE cover_file_id
        END AS cover_file_id,
        created_at,
        updated_at
    FROM source_excursions
    ORDER BY canonical_key, CASE WHEN status = 'PUBLISHED' AND visibility = 'PUBLIC' THEN 0 ELSE 1 END, created_at ASC
)
INSERT INTO excursion_products (
    canonical_key,
    landmark_id,
    landmark_name,
    title,
    summary,
    description,
    category_slug,
    status,
    visibility,
    duration_minutes,
    country_code,
    city_name,
    latitude,
    longitude,
    map_url,
    cover_file_id,
    created_at,
    updated_at
)
SELECT
    canonical_key,
    landmark_id,
    landmark_name,
    title,
    summary,
    description,
    category_slug,
    status,
    visibility,
    duration_minutes,
    country_code,
    city_name,
    latitude,
    longitude,
    map_url,
    cover_file_id,
    created_at,
    updated_at
FROM product_source
ON CONFLICT (canonical_key) DO NOTHING;

WITH source_excursions AS (
    SELECT
        t.*,
        tc.file_id AS cover_file_id,
        CASE
            WHEN t.landmark_id IS NOT NULL THEN 'landmark:' || t.landmark_id::text
            ELSE 'custom:'
                || COALESCE(NULLIF(lower(trim(t.country_code)), ''), 'unknown-country')
                || ':'
                || COALESCE(NULLIF(trim(both '-' from regexp_replace(lower(trim(t.city_name)), '[^[:alnum:]]+', '-', 'g')), ''), 'unknown-city')
                || ':'
                || COALESCE(NULLIF(trim(both '-' from regexp_replace(lower(trim(t.category_slug)), '[^[:alnum:]]+', '-', 'g')), ''), 'uncategorized')
                || ':'
                || COALESCE(NULLIF(trim(both '-' from regexp_replace(lower(trim(t.title)), '[^[:alnum:]]+', '-', 'g')), ''), t.id::text)
        END AS canonical_key
    FROM excursions t
    LEFT JOIN excursion_covers tc ON tc.excursion_id = t.id
)
INSERT INTO excursion_offers (
    product_id,
    legacy_excursion_id,
    guide_profile_id,
    guide_user_id,
    title,
    summary,
    description,
    status,
    visibility,
    duration_minutes,
    max_group_size,
    meeting_point,
    latitude,
    longitude,
    map_url,
    price_amount,
    currency,
    cover_file_id,
    published_at,
    deleted_at,
    revision,
    created_at,
    updated_at
)
SELECT
    p.id,
    s.id,
    s.guide_profile_id,
    s.guide_user_id,
    s.title,
    s.summary,
    s.description,
    s.status,
    s.visibility,
    s.duration_minutes,
    s.max_group_size,
    s.meeting_point,
    s.latitude,
    s.longitude,
    s.map_url,
    s.price_amount,
    s.currency,
    s.cover_file_id,
    s.published_at,
    s.deleted_at,
    s.revision,
    s.created_at,
    s.updated_at
FROM source_excursions s
JOIN excursion_products p ON p.canonical_key = s.canonical_key
ON CONFLICT (legacy_excursion_id) DO NOTHING;

INSERT INTO excursion_offer_languages (offer_id, language_code, sort_order, created_at)
SELECT o.id, tl.language_code, tl.sort_order, tl.created_at
FROM excursion_offers o
JOIN excursion_languages tl ON tl.excursion_id = o.legacy_excursion_id
ON CONFLICT (offer_id, language_code) DO NOTHING;

INSERT INTO excursion_offer_included_items (offer_id, item_text, sort_order, created_at)
SELECT o.id, ti.item_text, ti.sort_order, ti.created_at
FROM excursion_offers o
JOIN excursion_included_items ti ON ti.excursion_id = o.legacy_excursion_id;

WITH product_ids AS (
    SELECT DISTINCT product_id FROM excursion_offers
),
stats AS (
    SELECT
        p.product_id AS product_id,
        COUNT(o.id) FILTER (WHERE o.deleted_at IS NULL AND o.status <> 'ARCHIVED') AS offers_count,
        COUNT(o.id) FILTER (WHERE o.deleted_at IS NULL AND o.status = 'PUBLISHED' AND o.visibility = 'PUBLIC') AS published_offers_count,
        MIN(o.price_amount) FILTER (WHERE o.deleted_at IS NULL AND o.status = 'PUBLISHED' AND o.visibility = 'PUBLIC') AS min_price_amount
    FROM product_ids p
    LEFT JOIN excursion_offers o ON o.product_id = p.product_id
    GROUP BY p.product_id
),
cheapest AS (
    SELECT DISTINCT ON (product_id)
        product_id,
        currency
    FROM excursion_offers
    WHERE deleted_at IS NULL AND status = 'PUBLISHED' AND visibility = 'PUBLIC'
    ORDER BY product_id, price_amount ASC, updated_at DESC
)
UPDATE excursion_products p
SET
    offers_count = stats.offers_count,
    published_offers_count = stats.published_offers_count,
    min_price_amount = stats.min_price_amount,
    currency = cheapest.currency,
    status = CASE WHEN stats.published_offers_count > 0 THEN 'PUBLISHED' ELSE 'DRAFT' END,
    updated_at = NOW()
FROM stats
LEFT JOIN cheapest ON cheapest.product_id = stats.product_id
WHERE p.id = stats.product_id;
