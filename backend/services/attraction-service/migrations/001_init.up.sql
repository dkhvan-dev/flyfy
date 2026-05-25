CREATE TABLE IF NOT EXISTS attractions (
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

    CONSTRAINT chk_attractions_category CHECK (category IN (
        'NATURE', 'ARCHITECTURE', 'MUSEUM', 'BEACH', 'PARK',
        'TEMPLE', 'ENTERTAINMENT', 'FOOD', 'MARKET', 'SHOPPING', 'OTHER'
    )),
    CONSTRAINT chk_attractions_source CHECK (source IN ('USER', 'AI_AGENT', 'IMPORT')),
    CONSTRAINT chk_attractions_status CHECK (status IN ('DRAFT', 'PUBLISHED')),
    CONSTRAINT chk_attractions_default_locale CHECK (default_locale IN ('en', 'ru', 'kk')),
    CONSTRAINT chk_attractions_country_code CHECK (country_code = '' OR country_code ~ '^[A-Z]{2}$'),
    CONSTRAINT chk_attractions_city_id CHECK (city_id = '' OR city_id ~ '^[a-z0-9][a-z0-9-]{0,63}$'),
    CONSTRAINT chk_attractions_duration_unit CHECK (duration_unit IS NULL OR duration_unit IN ('HOURS', 'DAYS')),
    CONSTRAINT chk_attractions_rating CHECK (rating >= 0.0 AND rating <= 5.0)
);

CREATE INDEX idx_attractions_status ON attractions (status) WHERE deleted_at IS NULL;
CREATE INDEX idx_attractions_country ON attractions (country_code) WHERE deleted_at IS NULL;
CREATE INDEX idx_attractions_city ON attractions (city_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_attractions_category ON attractions (category) WHERE deleted_at IS NULL;
CREATE INDEX idx_attractions_author ON attractions (author_user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_attractions_rating ON attractions (rating DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_attractions_price ON attractions (price_amount) WHERE deleted_at IS NULL AND price_amount IS NOT NULL;
CREATE INDEX idx_attractions_tags ON attractions USING GIN (tags) WHERE deleted_at IS NULL;
CREATE INDEX idx_attractions_visit_info ON attractions USING GIN (visit_info) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS attraction_translations (
    attraction_id   UUID NOT NULL REFERENCES attractions(id) ON DELETE CASCADE,
    locale          VARCHAR(5) NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL DEFAULT '',
    search_vector   TSVECTOR NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (attraction_id, locale),
    CONSTRAINT chk_attraction_translations_locale CHECK (locale IN ('en', 'ru', 'kk')),
    CONSTRAINT chk_attraction_translations_title CHECK (char_length(title) BETWEEN 1 AND 200),
    CONSTRAINT chk_attraction_translations_description CHECK (char_length(description) <= 5000)
);

CREATE INDEX idx_attraction_translations_locale ON attraction_translations (locale);
CREATE INDEX idx_attraction_translations_search ON attraction_translations USING GIN (search_vector);
CREATE INDEX idx_attraction_translations_title ON attraction_translations (locale, lower(title));

CREATE OR REPLACE FUNCTION attraction_translations_search_vector_update() RETURNS trigger AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('simple', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.description, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_attraction_translations_search_vector
    BEFORE INSERT OR UPDATE OF title, description
    ON attraction_translations
    FOR EACH ROW
    EXECUTE FUNCTION attraction_translations_search_vector_update();

-- Attraction media (carousel photos/videos)
CREATE TABLE IF NOT EXISTS attraction_media (
    id              UUID PRIMARY KEY,
    attraction_id   UUID NOT NULL REFERENCES attractions(id) ON DELETE CASCADE,
    file_id         UUID NOT NULL,
    external_url    TEXT NOT NULL DEFAULT '',
    source_url      TEXT NOT NULL DEFAULT '',
    credit          TEXT NOT NULL DEFAULT '',
    license         TEXT NOT NULL DEFAULT '',
    media_type      VARCHAR(8) NOT NULL DEFAULT 'PHOTO',
    position        INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_attraction_media_type CHECK (media_type IN ('PHOTO', 'VIDEO')),
    CONSTRAINT chk_attraction_media_external_url CHECK (
        external_url = '' OR external_url ~ '^https://'
    ),
    CONSTRAINT chk_attraction_media_source_url CHECK (
        source_url = '' OR source_url ~ '^https://'
    )
);

CREATE INDEX idx_attraction_media_attraction ON attraction_media (attraction_id, position);

-- Reviews
CREATE TABLE IF NOT EXISTS attraction_reviews (
    id              UUID PRIMARY KEY,
    attraction_id   UUID NOT NULL REFERENCES attractions(id) ON DELETE CASCADE,
    author_user_id  UUID NOT NULL,
    rating          NUMERIC(3, 1) NOT NULL,
    comment         TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ NULL,

    CONSTRAINT chk_reviews_rating CHECK (rating >= 1.0 AND rating <= 5.0)
);

CREATE INDEX idx_reviews_attraction ON attraction_reviews (attraction_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_reviews_author ON attraction_reviews (author_user_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_reviews_unique_author ON attraction_reviews (attraction_id, author_user_id) WHERE deleted_at IS NULL;

-- Review media (photos/videos attached to reviews)
CREATE TABLE IF NOT EXISTS review_media (
    id          UUID PRIMARY KEY,
    review_id   UUID NOT NULL REFERENCES attraction_reviews(id) ON DELETE CASCADE,
    file_id     UUID NOT NULL,
    media_type  VARCHAR(8) NOT NULL DEFAULT 'PHOTO',
    position    INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_review_media_type CHECK (media_type IN ('PHOTO', 'VIDEO'))
);

CREATE INDEX idx_review_media_review ON review_media (review_id, position);
