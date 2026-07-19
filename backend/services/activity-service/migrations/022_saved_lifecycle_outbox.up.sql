CREATE SEQUENCE IF NOT EXISTS activity_saved_source_revision_seq AS BIGINT MINVALUE 1;

-- Existing rows stay nullable during rollout. Readers use the activity revision
-- as a compatibility baseline until the first Saved-relevant write initializes
-- the independent vector. This avoids a table rewrite and a revision rollback.
ALTER TABLE activities
    ADD COLUMN IF NOT EXISTS saved_source_revision BIGINT,
    ADD COLUMN IF NOT EXISTS saved_projection_revision BIGINT,
    ADD COLUMN IF NOT EXISTS saved_visibility_revision BIGINT;

ALTER TABLE activities
    ALTER COLUMN saved_source_revision SET DEFAULT nextval('activity_saved_source_revision_seq'),
    ALTER COLUMN saved_projection_revision SET DEFAULT nextval('activity_saved_source_revision_seq'),
    ALTER COLUMN saved_visibility_revision SET DEFAULT nextval('activity_saved_source_revision_seq');

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_saved_source_revision_positive
        CHECK (saved_source_revision IS NULL OR saved_source_revision > 0) NOT VALID,
    ADD CONSTRAINT chk_activities_saved_projection_revision_positive
        CHECK (saved_projection_revision IS NULL OR saved_projection_revision > 0) NOT VALID,
    ADD CONSTRAINT chk_activities_saved_visibility_revision_positive
        CHECK (saved_visibility_revision IS NULL OR saved_visibility_revision > 0) NOT VALID;

ALTER TABLE activities VALIDATE CONSTRAINT chk_activities_saved_source_revision_positive;
ALTER TABLE activities VALIDATE CONSTRAINT chk_activities_saved_projection_revision_positive;
ALTER TABLE activities VALIDATE CONSTRAINT chk_activities_saved_visibility_revision_positive;

CREATE OR REPLACE FUNCTION activity_saved_effective_visibility(
    activity_visibility TEXT,
    activity_status TEXT,
    activity_moderation_status TEXT,
    activity_published_at TIMESTAMPTZ,
    activity_cancelled_at TIMESTAMPTZ
)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN activity_visibility = 'PRIVATE' THEN 'PRIVATE'
        WHEN activity_visibility <> 'PUBLIC' THEN 'RESTRICTED'
        WHEN activity_status = 'ARCHIVED' THEN 'DELETED'
        WHEN activity_status = 'CANCELLED' OR activity_cancelled_at IS NOT NULL THEN 'UNAVAILABLE'
        WHEN activity_published_at IS NULL THEN 'RESTRICTED'
        WHEN activity_moderation_status = 'REJECTED' THEN 'RESTRICTED'
        ELSE 'PUBLIC'
    END;
$$;

CREATE OR REPLACE FUNCTION bump_activity_saved_source_revisions()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    old_source_revision BIGINT;
    old_projection_revision BIGINT;
    old_visibility_revision BIGINT;
    old_effective_visibility TEXT;
    new_effective_visibility TEXT;
    projection_changed BOOLEAN;
    visibility_changed BOOLEAN;
    public_projection_boundary_changed BOOLEAN;
BEGIN
    old_source_revision := COALESCE(OLD.saved_source_revision, GREATEST(OLD.revision, 1)::BIGINT);
    old_projection_revision := COALESCE(OLD.saved_projection_revision, GREATEST(OLD.revision, 1)::BIGINT);
    old_visibility_revision := COALESCE(OLD.saved_visibility_revision, GREATEST(OLD.revision, 1)::BIGINT);

    -- Preserve an explicit monotonic bump made by a child projection mutation,
    -- while lazily initializing rows created before this migration.
    NEW.saved_source_revision := GREATEST(COALESCE(NEW.saved_source_revision, 0), old_source_revision);
    NEW.saved_projection_revision := GREATEST(COALESCE(NEW.saved_projection_revision, 0), old_projection_revision);
    NEW.saved_visibility_revision := GREATEST(COALESCE(NEW.saved_visibility_revision, 0), old_visibility_revision);

    projection_changed :=
        NEW.title IS DISTINCT FROM OLD.title
        OR NEW.description IS DISTINCT FROM OLD.description
        OR NEW.translations IS DISTINCT FROM OLD.translations
        OR NEW.source_language IS DISTINCT FROM OLD.source_language
        OR NEW.country_code IS DISTINCT FROM OLD.country_code
        OR NEW.city_id IS DISTINCT FROM OLD.city_id
        OR NEW.city_name IS DISTINCT FROM OLD.city_name
        OR NEW.address_text IS DISTINCT FROM OLD.address_text;

    new_effective_visibility := activity_saved_effective_visibility(
        NEW.visibility,
        NEW.status,
        NEW.moderation_status,
        NEW.published_at,
        NEW.cancelled_at
    );
    old_effective_visibility := activity_saved_effective_visibility(
        OLD.visibility,
        OLD.status,
        OLD.moderation_status,
        OLD.published_at,
        OLD.cancelled_at
    );
    visibility_changed := new_effective_visibility IS DISTINCT FROM old_effective_visibility;
    public_projection_boundary_changed :=
        (new_effective_visibility = 'PUBLIC') IS DISTINCT FROM
        (old_effective_visibility = 'PUBLIC');

    IF projection_changed OR visibility_changed THEN
        NEW.saved_source_revision := GREATEST(
            old_source_revision + 1,
            nextval('activity_saved_source_revision_seq')
        );
    END IF;
    -- Crossing the PUBLIC boundary rotates the media reference revision. This
    -- prevents a reference revoked by a deny transition from becoming valid
    -- again if the same Activity is later restored to PUBLIC.
    IF projection_changed OR public_projection_boundary_changed THEN
        NEW.saved_projection_revision := GREATEST(
            old_projection_revision + 1,
            nextval('activity_saved_source_revision_seq')
        );
    END IF;
    IF visibility_changed THEN
        NEW.saved_visibility_revision := GREATEST(
            old_visibility_revision + 1,
            nextval('activity_saved_source_revision_seq')
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_activities_saved_source_revisions ON activities;
CREATE TRIGGER trg_activities_saved_source_revisions
    BEFORE UPDATE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION bump_activity_saved_source_revisions();

CREATE TABLE activity_saved_lifecycle_outbox (
    id UUID PRIMARY KEY,
    activity_id UUID NOT NULL,
    subject TEXT NOT NULL DEFAULT 'saved.source.activity.lifecycle.v1',
    schema_version SMALLINT NOT NULL DEFAULT 1,
    event_kind TEXT NOT NULL,
    visibility TEXT NOT NULL,
    source_revision BIGINT NOT NULL,
    projection_revision BIGINT NOT NULL,
    visibility_revision BIGINT NOT NULL,
    has_public_projection BOOLEAN NOT NULL DEFAULT FALSE,
    payload JSONB NOT NULL,

    status TEXT NOT NULL DEFAULT 'PENDING',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 12,
    next_attempt_at TIMESTAMPTZ,
    locked_at TIMESTAMPTZ,
    locked_by TEXT,
    last_error_code TEXT,

    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    dead_at TIMESTAMPTZ,
    retention_expires_at TIMESTAMPTZ,

    CONSTRAINT uq_activity_saved_lifecycle_semantic_event
        UNIQUE (
            activity_id,
            source_revision,
            projection_revision,
            visibility_revision,
            event_kind
        ),
    CONSTRAINT chk_activity_saved_lifecycle_subject
        CHECK (subject = 'saved.source.activity.lifecycle.v1'),
    CONSTRAINT chk_activity_saved_lifecycle_schema_version
        CHECK (schema_version = 1),
    CONSTRAINT chk_activity_saved_lifecycle_event_kind
        CHECK (event_kind IN ('PUBLISHED', 'UPDATED', 'UNAVAILABLE', 'DELETED', 'VISIBILITY_CHANGED')),
    CONSTRAINT chk_activity_saved_lifecycle_kind_visibility
        CHECK (
            (event_kind IN ('PUBLISHED', 'UPDATED') AND visibility = 'PUBLIC')
            OR (event_kind = 'UNAVAILABLE' AND visibility = 'UNAVAILABLE')
            OR (event_kind = 'DELETED' AND visibility = 'DELETED')
            OR (
                event_kind = 'VISIBILITY_CHANGED'
                AND visibility IN ('PUBLIC', 'PRIVATE', 'RESTRICTED')
            )
        ),
    CONSTRAINT chk_activity_saved_lifecycle_visibility
        CHECK (visibility IN ('PUBLIC', 'PRIVATE', 'UNAVAILABLE', 'DELETED', 'RESTRICTED')),
    CONSTRAINT chk_activity_saved_lifecycle_revisions
        CHECK (source_revision > 0 AND projection_revision > 0 AND visibility_revision > 0),
    CONSTRAINT chk_activity_saved_lifecycle_projection_privacy
        CHECK (visibility = 'PUBLIC' OR has_public_projection = FALSE),
    CONSTRAINT chk_activity_saved_lifecycle_payload_size
        CHECK (pg_column_size(payload) BETWEEN 2 AND 65536),
    CONSTRAINT chk_activity_saved_lifecycle_payload_identity
        CHECK (
            payload ->> 'event_id' = id::TEXT
            AND payload #>> '{target,entity_type}' = 'SAVED_ENTITY_TYPE_ACTIVITY'
            AND payload #>> '{target,entity_id}' = activity_id::TEXT
            AND (payload #>> '{revisions,source_revision}')::BIGINT = source_revision
            AND (payload #>> '{revisions,projection_revision}')::BIGINT = projection_revision
            AND (payload #>> '{revisions,visibility_revision}')::BIGINT = visibility_revision
        ),
    CONSTRAINT chk_activity_saved_lifecycle_payload_projection
        CHECK (
            (has_public_projection AND visibility = 'PUBLIC' AND payload ? 'public_projection')
            OR (NOT has_public_projection AND NOT (payload ? 'public_projection'))
        ),
    CONSTRAINT chk_activity_saved_lifecycle_status
        CHECK (status IN ('PENDING', 'PROCESSING', 'PUBLISHED', 'DEAD')),
    CONSTRAINT chk_activity_saved_lifecycle_attempts
        CHECK (attempt_count >= 0 AND max_attempts BETWEEN 1 AND 100 AND attempt_count <= max_attempts),
    CONSTRAINT chk_activity_saved_lifecycle_error_code
        CHECK (last_error_code IS NULL OR last_error_code ~ '^[A-Z][A-Z0-9_]{0,63}$'),
    CONSTRAINT chk_activity_saved_lifecycle_timestamps
        CHECK (
            occurred_at <= created_at + INTERVAL '5 minutes'
            AND (
                (status = 'PENDING'
                    AND next_attempt_at IS NOT NULL
                    AND locked_at IS NULL
                    AND locked_by IS NULL
                    AND published_at IS NULL
                    AND dead_at IS NULL
                    AND retention_expires_at IS NULL)
                OR
                (status = 'PROCESSING'
                    AND next_attempt_at IS NOT NULL
                    AND locked_at IS NOT NULL
                    AND locked_by IS NOT NULL
                    AND published_at IS NULL
                    AND dead_at IS NULL
                    AND retention_expires_at IS NULL)
                OR
                (status = 'PUBLISHED'
                    AND next_attempt_at IS NULL
                    AND locked_at IS NULL
                    AND locked_by IS NULL
                    AND published_at IS NOT NULL
                    AND dead_at IS NULL
                    AND retention_expires_at = published_at + INTERVAL '14 days')
                OR
                (status = 'DEAD'
                    AND attempt_count = max_attempts
                    AND next_attempt_at IS NULL
                    AND locked_at IS NULL
                    AND locked_by IS NULL
                    AND published_at IS NULL
                    AND dead_at IS NOT NULL
                    AND retention_expires_at = dead_at + INTERVAL '14 days')
            )
        )
);

CREATE INDEX idx_activity_saved_lifecycle_outbox_pending
    ON activity_saved_lifecycle_outbox (next_attempt_at, created_at, id)
    WHERE status = 'PENDING';

CREATE INDEX idx_activity_saved_lifecycle_outbox_processing_lease
    ON activity_saved_lifecycle_outbox (next_attempt_at, created_at, id)
    WHERE status = 'PROCESSING';

CREATE INDEX idx_activity_saved_lifecycle_outbox_retention
    ON activity_saved_lifecycle_outbox (retention_expires_at, id)
    WHERE status IN ('PUBLISHED', 'DEAD');

CREATE INDEX idx_activity_saved_lifecycle_outbox_dead
    ON activity_saved_lifecycle_outbox (created_at, id)
    WHERE status = 'DEAD';

CREATE INDEX idx_activity_saved_lifecycle_outbox_activity
    ON activity_saved_lifecycle_outbox (activity_id, occurred_at DESC, id DESC);

CREATE OR REPLACE FUNCTION protect_activity_saved_lifecycle_outbox_semantics()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF ROW(
        NEW.id,
        NEW.activity_id,
        NEW.subject,
        NEW.schema_version,
        NEW.event_kind,
        NEW.visibility,
        NEW.source_revision,
        NEW.projection_revision,
        NEW.visibility_revision,
        NEW.has_public_projection,
        NEW.payload,
        NEW.occurred_at,
        NEW.created_at,
        NEW.max_attempts
    ) IS DISTINCT FROM ROW(
        OLD.id,
        OLD.activity_id,
        OLD.subject,
        OLD.schema_version,
        OLD.event_kind,
        OLD.visibility,
        OLD.source_revision,
        OLD.projection_revision,
        OLD.visibility_revision,
        OLD.has_public_projection,
        OLD.payload,
        OLD.occurred_at,
        OLD.created_at,
        OLD.max_attempts
    ) THEN
        RAISE EXCEPTION 'activity Saved lifecycle event semantics are immutable'
            USING ERRCODE = '55000';
    END IF;

    IF OLD.status IN ('PUBLISHED', 'DEAD') THEN
        RAISE EXCEPTION 'terminal activity Saved lifecycle event cannot be updated'
            USING ERRCODE = '55000';
    END IF;
    IF OLD.status = 'PENDING' AND NEW.status <> 'PROCESSING' THEN
        RAISE EXCEPTION 'invalid activity Saved lifecycle transition from PENDING'
            USING ERRCODE = '55000';
    END IF;
    IF OLD.status = 'PROCESSING'
       AND NEW.status NOT IN ('PROCESSING', 'PENDING', 'PUBLISHED', 'DEAD') THEN
        RAISE EXCEPTION 'invalid activity Saved lifecycle transition from PROCESSING'
            USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_activity_saved_lifecycle_outbox_immutable
    BEFORE UPDATE ON activity_saved_lifecycle_outbox
    FOR EACH ROW
    EXECUTE FUNCTION protect_activity_saved_lifecycle_outbox_semantics();

CREATE OR REPLACE FUNCTION enqueue_activity_saved_deleted_event()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    lifecycle_event_id UUID := gen_random_uuid();
    lifecycle_occurred_at TIMESTAMPTZ := clock_timestamp();
    lifecycle_source_revision BIGINT;
    lifecycle_projection_revision BIGINT;
    lifecycle_visibility_revision BIGINT;
BEGIN
    lifecycle_source_revision := GREATEST(
        COALESCE(OLD.saved_source_revision, GREATEST(OLD.revision, 1)::BIGINT) + 1,
        nextval('activity_saved_source_revision_seq')
    );
    lifecycle_projection_revision := COALESCE(
        OLD.saved_projection_revision,
        GREATEST(OLD.revision, 1)::BIGINT
    );
    lifecycle_visibility_revision := GREATEST(
        COALESCE(OLD.saved_visibility_revision, GREATEST(OLD.revision, 1)::BIGINT) + 1,
        nextval('activity_saved_source_revision_seq')
    );

    INSERT INTO activity_saved_lifecycle_outbox (
        id,
        activity_id,
        event_kind,
        visibility,
        source_revision,
        projection_revision,
        visibility_revision,
        has_public_projection,
        payload,
        next_attempt_at,
        occurred_at,
        created_at
    ) VALUES (
        lifecycle_event_id,
        OLD.id,
        'DELETED',
        'DELETED',
        lifecycle_source_revision,
        lifecycle_projection_revision,
        lifecycle_visibility_revision,
        FALSE,
        jsonb_build_object(
            'event_id', lifecycle_event_id::TEXT,
            'kind', 'SAVED_LIFECYCLE_EVENT_KIND_DELETED',
            'target', jsonb_build_object(
                'entity_type', 'SAVED_ENTITY_TYPE_ACTIVITY',
                'entity_id', OLD.id::TEXT
            ),
            'revisions', jsonb_build_object(
                'source_revision', lifecycle_source_revision::TEXT,
                'projection_revision', lifecycle_projection_revision::TEXT,
                'visibility_revision', lifecycle_visibility_revision::TEXT
            ),
            'occurred_at', to_jsonb(lifecycle_occurred_at),
            'visibility', 'SAVED_TARGET_VISIBILITY_DELETED'
        ),
        lifecycle_occurred_at,
        lifecycle_occurred_at,
        lifecycle_occurred_at
    );

    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_activities_saved_deleted_outbox
    BEFORE DELETE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION enqueue_activity_saved_deleted_event();
