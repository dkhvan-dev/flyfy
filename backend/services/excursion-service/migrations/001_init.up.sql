CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE excursions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guide_profile_id UUID NOT NULL,
    guide_user_id UUID NOT NULL,

    landmark_id UUID NULL,
    landmark_name VARCHAR(180) NULL,

    title VARCHAR(160) NOT NULL,
    summary VARCHAR(240) NOT NULL,
    description TEXT NOT NULL,
    category_slug VARCHAR(100) NOT NULL,

    status VARCHAR(20) NOT NULL,
    visibility VARCHAR(20) NOT NULL,

    duration_minutes INT NOT NULL,
    max_group_size INT NOT NULL,

    country_code VARCHAR(10) NULL,
    city_name VARCHAR(150) NULL,
    meeting_point VARCHAR(300) NOT NULL,
    latitude NUMERIC(10,7) NULL,
    longitude NUMERIC(10,7) NULL,
    map_url TEXT NULL,

    price_amount NUMERIC(12,2) NOT NULL,
    currency VARCHAR(10) NOT NULL,

    published_at TIMESTAMPTZ NULL,
    deleted_at TIMESTAMPTZ NULL,
    revision INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_excursions_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT chk_excursions_visibility
        CHECK (visibility IN ('PUBLIC', 'UNLISTED', 'PRIVATE')),
    CONSTRAINT chk_excursions_duration
        CHECK (duration_minutes BETWEEN 15 AND 43200),
    CONSTRAINT chk_excursions_group_size
        CHECK (max_group_size BETWEEN 1 AND 100),
    CONSTRAINT chk_excursions_price
        CHECK (price_amount >= 0)
);

CREATE INDEX idx_excursions_guide_user_id ON excursions(guide_user_id);
CREATE INDEX idx_excursions_guide_profile_id ON excursions(guide_profile_id);
CREATE INDEX idx_excursions_status_visibility ON excursions(status, visibility) WHERE deleted_at IS NULL;
CREATE INDEX idx_excursions_category_slug ON excursions(category_slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_excursions_country_city ON excursions(country_code, city_name) WHERE deleted_at IS NULL;
CREATE INDEX idx_excursions_price_amount ON excursions(price_amount) WHERE deleted_at IS NULL;
CREATE INDEX idx_excursions_duration ON excursions(duration_minutes) WHERE deleted_at IS NULL;

CREATE TABLE excursion_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    excursion_id UUID NOT NULL REFERENCES excursions(id) ON DELETE CASCADE,
    tag_slug VARCHAR(100) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_excursion_tags UNIQUE (excursion_id, tag_slug)
);

CREATE INDEX idx_excursion_tags_tag_slug ON excursion_tags(tag_slug);

CREATE TABLE excursion_languages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    excursion_id UUID NOT NULL REFERENCES excursions(id) ON DELETE CASCADE,
    language_code VARCHAR(20) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_excursion_languages UNIQUE (excursion_id, language_code)
);

CREATE INDEX idx_excursion_languages_language_code ON excursion_languages(language_code);

CREATE TABLE excursion_included_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    excursion_id UUID NOT NULL REFERENCES excursions(id) ON DELETE CASCADE,
    item_text VARCHAR(180) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE excursion_itinerary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    excursion_id UUID NOT NULL REFERENCES excursions(id) ON DELETE CASCADE,
    sort_order INT NOT NULL DEFAULT 0,
    start_offset_minutes INT NOT NULL DEFAULT 0,
    duration_minutes INT NULL,
    title VARCHAR(160) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_excursion_itinerary_offset CHECK (sort_order >= 0 AND start_offset_minutes >= 0),
    CONSTRAINT chk_excursion_itinerary_duration CHECK (duration_minutes IS NULL OR duration_minutes > 0)
);

CREATE INDEX idx_excursion_itinerary_items_excursion_id ON excursion_itinerary_items(excursion_id, sort_order);

CREATE TABLE excursion_covers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    excursion_id UUID NOT NULL REFERENCES excursions(id) ON DELETE CASCADE,
    file_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_excursion_covers_excursion_id UNIQUE (excursion_id)
);

CREATE INDEX idx_excursion_covers_file_id ON excursion_covers(file_id);

CREATE TABLE excursion_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    excursion_id UUID NOT NULL REFERENCES excursions(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    actor_user_id UUID NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_excursion_events_excursion_id ON excursion_events(excursion_id);
CREATE INDEX idx_excursion_events_event_type ON excursion_events(event_type);