CREATE TABLE activity_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    participant_id UUID NOT NULL REFERENCES activity_participants(id) ON DELETE CASCADE,
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    host_user_id UUID NOT NULL,
    author_user_id UUID NOT NULL,

    rating NUMERIC(2,1) NOT NULL,
    comment TEXT NOT NULL DEFAULT '',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL,

    CONSTRAINT chk_activity_reviews_rating
        CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT chk_activity_reviews_comment
        CHECK (length(comment) <= 2000)
);

CREATE UNIQUE INDEX idx_activity_reviews_participant
    ON activity_reviews(participant_id)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_reviews_activity_created
    ON activity_reviews(activity_id, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_reviews_activity_rating_created
    ON activity_reviews(activity_id, rating DESC, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_reviews_host_created
    ON activity_reviews(host_user_id, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_reviews_host_rating_created
    ON activity_reviews(host_user_id, rating DESC, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_reviews_author_created
    ON activity_reviews(author_user_id, created_at DESC)
    WHERE deleted_at IS NULL;

CREATE TABLE activity_organizer_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    participant_id UUID NOT NULL REFERENCES activity_participants(id) ON DELETE CASCADE,
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    host_user_id UUID NOT NULL,
    author_user_id UUID NOT NULL,

    rating NUMERIC(2,1) NOT NULL,
    comment TEXT NOT NULL DEFAULT '',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL,

    CONSTRAINT chk_activity_organizer_reviews_rating
        CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT chk_activity_organizer_reviews_comment
        CHECK (length(comment) <= 2000),
    CONSTRAINT chk_activity_organizer_reviews_not_self
        CHECK (author_user_id <> host_user_id)
);

CREATE UNIQUE INDEX idx_activity_organizer_reviews_participant
    ON activity_organizer_reviews(participant_id)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_organizer_reviews_activity_created
    ON activity_organizer_reviews(activity_id, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_organizer_reviews_activity_rating_created
    ON activity_organizer_reviews(activity_id, rating DESC, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_organizer_reviews_host_created
    ON activity_organizer_reviews(host_user_id, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_organizer_reviews_host_rating_created
    ON activity_organizer_reviews(host_user_id, rating DESC, created_at DESC, id ASC)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_activity_organizer_reviews_author_created
    ON activity_organizer_reviews(author_user_id, created_at DESC)
    WHERE deleted_at IS NULL;
