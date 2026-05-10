CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE tours (
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

    CONSTRAINT chk_tours_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT chk_tours_visibility
        CHECK (visibility IN ('PUBLIC', 'UNLISTED', 'PRIVATE')),
    CONSTRAINT chk_tours_duration
        CHECK (duration_minutes BETWEEN 15 AND 43200),
    CONSTRAINT chk_tours_group_size
        CHECK (max_group_size BETWEEN 1 AND 100),
    CONSTRAINT chk_tours_price
        CHECK (price_amount >= 0)
);

CREATE INDEX idx_tours_guide_user_id ON tours(guide_user_id);
CREATE INDEX idx_tours_guide_profile_id ON tours(guide_profile_id);
CREATE INDEX idx_tours_status_visibility ON tours(status, visibility) WHERE deleted_at IS NULL;
CREATE INDEX idx_tours_category_slug ON tours(category_slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_tours_country_city ON tours(country_code, city_name) WHERE deleted_at IS NULL;
CREATE INDEX idx_tours_price_amount ON tours(price_amount) WHERE deleted_at IS NULL;
CREATE INDEX idx_tours_duration ON tours(duration_minutes) WHERE deleted_at IS NULL;

CREATE TABLE tour_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
    tag_slug VARCHAR(100) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tour_tags UNIQUE (tour_id, tag_slug)
);

CREATE INDEX idx_tour_tags_tag_slug ON tour_tags(tag_slug);

CREATE TABLE tour_languages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
    language_code VARCHAR(20) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tour_languages UNIQUE (tour_id, language_code)
);

CREATE INDEX idx_tour_languages_language_code ON tour_languages(language_code);

CREATE TABLE tour_included_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
    item_text VARCHAR(180) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tour_itinerary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
    sort_order INT NOT NULL DEFAULT 0,
    start_offset_minutes INT NOT NULL DEFAULT 0,
    duration_minutes INT NULL,
    title VARCHAR(160) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_tour_itinerary_offset CHECK (sort_order >= 0 AND start_offset_minutes >= 0),
    CONSTRAINT chk_tour_itinerary_duration CHECK (duration_minutes IS NULL OR duration_minutes > 0)
);

CREATE INDEX idx_tour_itinerary_items_tour_id ON tour_itinerary_items(tour_id, sort_order);

CREATE TABLE tour_covers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
    file_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tour_covers_tour_id UNIQUE (tour_id)
);

CREATE INDEX idx_tour_covers_file_id ON tour_covers(file_id);

CREATE TABLE tour_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tour_id UUID NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    actor_user_id UUID NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tour_events_tour_id ON tour_events(tour_id);
CREATE INDEX idx_tour_events_event_type ON tour_events(event_type);