CREATE TABLE IF NOT EXISTS places (
    id              UUID PRIMARY KEY,
    author_user_id  UUID NOT NULL,
    default_locale  VARCHAR(5) NOT NULL DEFAULT 'en',
    country_code    VARCHAR(2) NOT NULL DEFAULT '',
    city_id         VARCHAR(64) NOT NULL DEFAULT '',
    category        VARCHAR(32) NOT NULL DEFAULT 'OTHER',
    price_amount    NUMERIC(12, 2) NULL,
    price_currency  VARCHAR(3) NULL,
    duration_value  INT NULL,
    duration_unit   VARCHAR(8) NULL,
    rating          NUMERIC(3, 1) NOT NULL DEFAULT 0.0,
    review_count    INT NOT NULL DEFAULT 0,
    spots           INT NULL,
    source          VARCHAR(16) NOT NULL DEFAULT 'USER',
    status          VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    tags            TEXT[] NOT NULL DEFAULT '{}',
    visit_info      JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ NULL,

    CONSTRAINT chk_places_category CHECK (category IN (
        'NATURE', 'ARCHITECTURE', 'MUSEUM', 'BEACH', 'PARK',
        'TEMPLE', 'ENTERTAINMENT', 'FOOD', 'MARKET', 'SHOPPING', 'OTHER'
    )),
    CONSTRAINT chk_places_source CHECK (source IN ('USER', 'AI_AGENT', 'IMPORT')),
    CONSTRAINT chk_places_status CHECK (status IN ('DRAFT', 'PUBLISHED')),
    CONSTRAINT chk_places_default_locale CHECK (default_locale IN ('en', 'ru', 'kk')),
    CONSTRAINT chk_places_country_code CHECK (country_code = '' OR country_code ~ '^[A-Z]{2}$'),
    CONSTRAINT chk_places_city_id CHECK (city_id = '' OR city_id ~ '^[a-z0-9][a-z0-9-]{0,63}$'),
    CONSTRAINT chk_places_duration_unit CHECK (duration_unit IS NULL OR duration_unit IN ('HOURS', 'DAYS')),
    CONSTRAINT chk_places_rating CHECK (rating >= 0.0 AND rating <= 5.0)
);

CREATE INDEX idx_places_status ON places (status) WHERE deleted_at IS NULL;
CREATE INDEX idx_places_country ON places (country_code) WHERE deleted_at IS NULL;
CREATE INDEX idx_places_city ON places (city_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_places_category ON places (category) WHERE deleted_at IS NULL;
CREATE INDEX idx_places_author ON places (author_user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_places_rating ON places (rating DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_places_price ON places (price_amount) WHERE deleted_at IS NULL AND price_amount IS NOT NULL;
CREATE INDEX idx_places_tags ON places USING GIN (tags) WHERE deleted_at IS NULL;
CREATE INDEX idx_places_visit_info ON places USING GIN (visit_info) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS place_translations (
    place_id   UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    locale          VARCHAR(5) NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL DEFAULT '',
    search_vector   TSVECTOR NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (place_id, locale),
    CONSTRAINT chk_place_translations_locale CHECK (locale IN ('en', 'ru', 'kk')),
    CONSTRAINT chk_place_translations_title CHECK (char_length(title) BETWEEN 1 AND 200),
    CONSTRAINT chk_place_translations_description CHECK (char_length(description) <= 5000)
);

CREATE INDEX idx_place_translations_locale ON place_translations (locale);
CREATE INDEX idx_place_translations_search ON place_translations USING GIN (search_vector);
CREATE INDEX idx_place_translations_title ON place_translations (locale, lower(title));

CREATE OR REPLACE FUNCTION place_translations_search_vector_update() RETURNS trigger AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('simple', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.description, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_place_translations_search_vector
    BEFORE INSERT OR UPDATE OF title, description
    ON place_translations
    FOR EACH ROW
    EXECUTE FUNCTION place_translations_search_vector_update();

-- Place media (carousel photos/videos)
CREATE TABLE IF NOT EXISTS place_media (
    id              UUID PRIMARY KEY,
    place_id   UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    file_id         UUID NOT NULL,
    external_url    TEXT NOT NULL DEFAULT '',
    source_url      TEXT NOT NULL DEFAULT '',
    credit          TEXT NOT NULL DEFAULT '',
    license         TEXT NOT NULL DEFAULT '',
    media_type      VARCHAR(8) NOT NULL DEFAULT 'PHOTO',
    position        INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_place_media_type CHECK (media_type IN ('PHOTO', 'VIDEO')),
    CONSTRAINT chk_place_media_external_url CHECK (
        external_url = '' OR external_url ~ '^https://'
    ),
    CONSTRAINT chk_place_media_source_url CHECK (
        source_url = '' OR source_url ~ '^https://'
    )
);

CREATE INDEX idx_place_media_place ON place_media (place_id, position);

-- Reviews
CREATE TABLE IF NOT EXISTS place_reviews (
    id              UUID PRIMARY KEY,
    place_id   UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    author_user_id  UUID NOT NULL,
    rating          NUMERIC(3, 1) NOT NULL,
    comment         TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ NULL,

    CONSTRAINT chk_reviews_rating CHECK (rating >= 1.0 AND rating <= 5.0)
);

CREATE INDEX idx_reviews_place ON place_reviews (place_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_reviews_author ON place_reviews (author_user_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_reviews_unique_author ON place_reviews (place_id, author_user_id) WHERE deleted_at IS NULL;

-- Review media (photos/videos attached to reviews)
CREATE TABLE IF NOT EXISTS review_media (
    id          UUID PRIMARY KEY,
    review_id   UUID NOT NULL REFERENCES place_reviews(id) ON DELETE CASCADE,
    file_id     UUID NOT NULL,
    media_type  VARCHAR(8) NOT NULL DEFAULT 'PHOTO',
    position    INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_review_media_type CHECK (media_type IN ('PHOTO', 'VIDEO'))
);

CREATE INDEX idx_review_media_review ON review_media (review_id, position);
