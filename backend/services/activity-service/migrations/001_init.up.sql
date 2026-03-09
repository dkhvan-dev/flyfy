CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID NOT NULL,
    source_activity_id UUID NULL REFERENCES activities(id),

    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,

    format VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL,
    visibility VARCHAR(20) NOT NULL,
    join_mode VARCHAR(20) NOT NULL,
    moderation_status VARCHAR(30) NOT NULL,

    category_slug VARCHAR(100) NOT NULL,

    language_code VARCHAR(10) NOT NULL,
    timezone VARCHAR(100) NOT NULL,

    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    registration_deadline TIMESTAMPTZ NOT NULL,

    capacity_type VARCHAR(20) NOT NULL,
    min_participants INT NULL,
    max_participants INT NULL,

    price_type VARCHAR(20) NOT NULL,
    price_amount NUMERIC(12,2) NULL,
    currency VARCHAR(10) NULL,
    price_locked_at TIMESTAMPTZ NULL,

    requires_profile_completion BOOLEAN NOT NULL DEFAULT TRUE,
    requires_attendance_confirmation BOOLEAN NOT NULL DEFAULT FALSE,
    confirmation_deadline TIMESTAMPTZ NULL,

    country_code VARCHAR(10) NULL,
    city_name VARCHAR(150) NULL,
    address_text VARCHAR(300) NULL,
    latitude NUMERIC(10,7) NULL,
    longitude NUMERIC(10,7) NULL,
    map_url TEXT NULL,
    meeting_url TEXT NULL,

    cancellation_reason TEXT NULL,
    cancelled_at TIMESTAMPTZ NULL,
    started_at TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    published_at TIMESTAMPTZ NULL,

    revision INT NOT NULL DEFAULT 1,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_activities_format
        CHECK (format IN ('OFFLINE', 'ONLINE', 'HYBRID')),

    CONSTRAINT chk_activities_status
        CHECK (status IN ('DRAFT', 'REVIEW_REQUIRED', 'PUBLISHED', 'ENROLLMENT_OPEN', 'FULL', 'STARTED', 'COMPLETED', 'CANCELLED', 'ARCHIVED')),

    CONSTRAINT chk_activities_visibility
        CHECK (visibility IN ('PUBLIC', 'PRIVATE', 'UNLISTED')),

    CONSTRAINT chk_activities_join_mode
        CHECK (join_mode IN ('AUTO_APPROVE', 'MANUAL_APPROVE')),

    CONSTRAINT chk_activities_moderation_status
        CHECK (moderation_status IN ('NOT_REQUIRED', 'PENDING_REVIEW', 'APPROVED', 'REJECTED')),

    CONSTRAINT chk_activities_capacity_type
        CHECK (capacity_type IN ('LIMITED', 'UNLIMITED')),

    CONSTRAINT chk_activities_price_type
        CHECK (price_type IN ('FREE', 'PAID', 'DEPOSIT')),

    CONSTRAINT chk_activities_time_order
        CHECK (end_at > start_at),

    CONSTRAINT chk_activities_capacity_limited
        CHECK (
            (capacity_type = 'UNLIMITED' AND max_participants IS NULL)
            OR
            (capacity_type = 'LIMITED' AND max_participants IS NOT NULL AND max_participants > 0)
        ),

    CONSTRAINT chk_activities_min_max
        CHECK (
            min_participants IS NULL
            OR max_participants IS NULL
            OR min_participants <= max_participants
        ),

    CONSTRAINT chk_activities_pricing
        CHECK (
            (price_type = 'FREE' AND price_amount IS NULL AND currency IS NULL)
            OR
            (price_type IN ('PAID', 'DEPOSIT') AND price_amount IS NOT NULL AND price_amount >= 0 AND currency IS NOT NULL)
        ),

    CONSTRAINT chk_activities_location_mode
        CHECK (
            (format = 'ONLINE' AND meeting_url IS NOT NULL)
            OR
            (format = 'OFFLINE' AND (country_code IS NOT NULL OR city_name IS NOT NULL OR address_text IS NOT NULL OR map_url IS NOT NULL))
            OR
            (format = 'HYBRID')
        )
);

CREATE INDEX idx_activities_host_user_id ON activities(host_user_id);
CREATE INDEX idx_activities_status ON activities(status);
CREATE INDEX idx_activities_start_at ON activities(start_at);
CREATE INDEX idx_activities_category_slug ON activities(category_slug);
CREATE INDEX idx_activities_country_city ON activities(country_code, city_name);
CREATE INDEX idx_activities_moderation_status ON activities(moderation_status);

CREATE TABLE activity_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    tag_slug VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_activity_tags UNIQUE (activity_id, tag_slug)
);

CREATE INDEX idx_activity_tags_tag_slug ON activity_tags(tag_slug);

CREATE TABLE activity_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    file_id UUID NOT NULL,
    media_type VARCHAR(20) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_cover BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_activity_media_type
        CHECK (media_type IN ('IMAGE', 'VIDEO')),

    CONSTRAINT uq_activity_media_file UNIQUE (activity_id, file_id)
);

CREATE INDEX idx_activity_media_activity_id ON activity_media(activity_id);

CREATE TABLE activity_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,

    status VARCHAR(30) NOT NULL,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMPTZ NULL,
    waitlisted_at TIMESTAMPTZ NULL,
    payment_due_at TIMESTAMPTZ NULL,
    paid_at TIMESTAMPTZ NULL,
    attendance_confirmed_at TIMESTAMPTZ NULL,
    checked_in_at TIMESTAMPTZ NULL,
    attended_at TIMESTAMPTZ NULL,
    cancelled_at TIMESTAMPTZ NULL,
    cancelled_by_user_id UUID NULL,
    cancel_reason TEXT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_activity_participants_status
        CHECK (status IN (
            'REQUESTED',
            'APPROVED',
            'WAITLISTED',
            'PENDING_PAYMENT',
            'CONFIRMED',
            'DECLINED',
            'CANCELLED',
            'EXPIRED',
            'CHECKED_IN',
            'ATTENDED',
            'NO_SHOW'
        ))
);

CREATE INDEX idx_activity_participants_activity_id ON activity_participants(activity_id);
CREATE INDEX idx_activity_participants_user_id ON activity_participants(user_id);
CREATE INDEX idx_activity_participants_status ON activity_participants(status);

CREATE UNIQUE INDEX uq_activity_participants_active_user
    ON activity_participants(activity_id, user_id)
    WHERE status IN ('REQUESTED', 'APPROVED', 'WAITLISTED', 'PENDING_PAYMENT', 'CONFIRMED', 'CHECKED_IN');

CREATE TABLE activity_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    actor_user_id UUID NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activity_events_activity_id ON activity_events(activity_id);
CREATE INDEX idx_activity_events_event_type ON activity_events(event_type);

CREATE TABLE activity_participant_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES activity_participants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    actor_user_id UUID NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activity_participant_events_activity_id ON activity_participant_events(activity_id);
CREATE INDEX idx_activity_participant_events_participant_id ON activity_participant_events(participant_id);
CREATE INDEX idx_activity_participant_events_user_id ON activity_participant_events(user_id);

CREATE TABLE blocked_url_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_type VARCHAR(20) NOT NULL,
    pattern_value TEXT NOT NULL,
    action VARCHAR(20) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    comment TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_blocked_url_patterns_type
        CHECK (pattern_type IN ('STARTS_WITH', 'CONTAINS', 'REGEX', 'DOMAIN')),

    CONSTRAINT chk_blocked_url_patterns_action
        CHECK (action IN ('BLOCK', 'REVIEW'))
);

CREATE INDEX idx_blocked_url_patterns_active ON blocked_url_patterns(is_active);