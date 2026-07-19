BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '5min';

ALTER TABLE guide_profiles
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE TABLE guide_saved_lifecycle_state (
    guide_profile_id UUID PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE,

    source_revision BIGINT NOT NULL CHECK (source_revision > 0),
    projection_revision BIGINT NOT NULL CHECK (projection_revision > 0),
    visibility_revision BIGINT NOT NULL CHECK (visibility_revision > 0),
    current_visibility TEXT NOT NULL CHECK (
        current_visibility IN ('PUBLIC', 'UNAVAILABLE', 'DELETED')
    ),

    local_source_changed_at TIMESTAMPTZ NOT NULL,
    local_projection_changed_at TIMESTAMPTZ NOT NULL,
    local_visibility_changed_at TIMESTAMPTZ NOT NULL,
    source_deleted BOOLEAN NOT NULL DEFAULT FALSE,

    external_known BOOLEAN NOT NULL DEFAULT FALSE,
    external_account_status TEXT,
    external_is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    external_account_updated_at TIMESTAMPTZ,
    external_profile_updated_at TIMESTAMPTZ,
    external_projection_fingerprint BYTEA,
    external_avatar_file_id UUID,

    media_reference_revision BIGINT NOT NULL DEFAULT 1 CHECK (media_reference_revision > 0),
    media_reference_active BOOLEAN NOT NULL DEFAULT FALSE,

    last_reconciled_at TIMESTAMPTZ,
    next_reconcile_at TIMESTAMPTZ NOT NULL,
    reconcile_failure_count INTEGER NOT NULL DEFAULT 0 CHECK (reconcile_failure_count >= 0),
    reconcile_lease_token UUID,
    reconcile_leased_until TIMESTAMPTZ,
    semantic_occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT guide_saved_external_fingerprint_length_check CHECK (
        external_projection_fingerprint IS NULL
        OR octet_length(external_projection_fingerprint) = 32
    ),
    CONSTRAINT guide_saved_external_state_check CHECK (
        (NOT external_known AND external_account_status IS NULL
            AND external_account_updated_at IS NULL
            AND external_profile_updated_at IS NULL
            AND external_projection_fingerprint IS NULL
            AND external_avatar_file_id IS NULL
            AND NOT external_is_deleted)
        OR
        (external_known AND external_account_status IN ('ACTIVE', 'BLOCKED', 'DELETED')
            AND external_account_updated_at IS NOT NULL)
    ),
    CONSTRAINT guide_saved_reconcile_lease_check CHECK (
        (reconcile_lease_token IS NULL AND reconcile_leased_until IS NULL)
        OR
        (reconcile_lease_token IS NOT NULL AND reconcile_leased_until IS NOT NULL)
    ),
    CONSTRAINT guide_saved_media_state_check CHECK (
        NOT media_reference_active
        OR (current_visibility = 'PUBLIC' AND external_avatar_file_id IS NOT NULL)
    ),
    CONSTRAINT guide_saved_state_timestamps_check CHECK (
        local_source_changed_at <= semantic_occurred_at
        AND local_projection_changed_at <= semantic_occurred_at
        AND local_visibility_changed_at <= semantic_occurred_at
        AND created_at <= updated_at
    )
);

CREATE TABLE guide_saved_lifecycle_outbox (
    event_id UUID PRIMARY KEY,
    event_kind TEXT NOT NULL CHECK (
        event_kind IN ('PUBLISHED', 'UPDATED', 'UNAVAILABLE', 'DELETED', 'VISIBILITY_CHANGED')
    ),
    target_user_id UUID NOT NULL,
    source_revision BIGINT NOT NULL CHECK (source_revision > 0),
    projection_revision BIGINT NOT NULL CHECK (projection_revision > 0),
    visibility_revision BIGINT NOT NULL CHECK (visibility_revision > 0),
    occurred_at TIMESTAMPTZ NOT NULL,
    visibility TEXT NOT NULL CHECK (visibility IN ('PUBLIC', 'UNAVAILABLE', 'DELETED')),
    public_projection BYTEA,

    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'PROCESSING', 'DELIVERED', 'DEAD')
    ),
    attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    max_attempts INTEGER NOT NULL DEFAULT 20 CHECK (max_attempts BETWEEN 1 AND 100),
    next_attempt_at TIMESTAMPTZ,
    lease_token UUID,
    leased_until TIMESTAMPTZ,
    last_error_code TEXT,
    delivered_at TIMESTAMPTZ,
    dead_at TIMESTAMPTZ,
    retention_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT guide_saved_outbox_deny_payload_check CHECK (
        visibility = 'PUBLIC' OR public_projection IS NULL
    ),
    CONSTRAINT guide_saved_outbox_kind_visibility_check CHECK (
        (event_kind IN ('PUBLISHED', 'UPDATED') AND visibility = 'PUBLIC')
        OR (event_kind = 'UNAVAILABLE' AND visibility = 'UNAVAILABLE')
        OR (event_kind = 'DELETED' AND visibility = 'DELETED')
        OR event_kind = 'VISIBILITY_CHANGED'
    ),
    CONSTRAINT guide_saved_outbox_attempt_budget_check CHECK (
        attempt_count <= max_attempts
    ),
    CONSTRAINT guide_saved_outbox_error_code_check CHECK (
        last_error_code IS NULL
        OR (char_length(last_error_code) BETWEEN 1 AND 64
            AND last_error_code = upper(last_error_code))
    ),
    CONSTRAINT guide_saved_outbox_lifecycle_check CHECK (
        (status = 'PENDING' AND next_attempt_at IS NOT NULL
            AND lease_token IS NULL AND leased_until IS NULL
            AND delivered_at IS NULL AND dead_at IS NULL
            AND retention_expires_at IS NULL)
        OR
        (status = 'PROCESSING' AND next_attempt_at IS NULL
            AND lease_token IS NOT NULL AND leased_until IS NOT NULL
            AND delivered_at IS NULL AND dead_at IS NULL
            AND retention_expires_at IS NULL)
        OR
        (status = 'DELIVERED' AND next_attempt_at IS NULL
            AND lease_token IS NULL AND leased_until IS NULL
            AND delivered_at IS NOT NULL AND dead_at IS NULL
            AND retention_expires_at IS NOT NULL)
        OR
        (status = 'DEAD' AND next_attempt_at IS NULL
            AND lease_token IS NULL AND leased_until IS NULL
            AND delivered_at IS NULL AND dead_at IS NOT NULL
            AND retention_expires_at IS NOT NULL)
    ),
    CONSTRAINT guide_saved_outbox_timestamps_check CHECK (
        occurred_at <= created_at
        AND created_at <= updated_at
        AND (next_attempt_at IS NULL OR next_attempt_at >= created_at)
        AND (leased_until IS NULL OR leased_until >= created_at)
        AND (delivered_at IS NULL OR delivered_at >= created_at)
        AND (dead_at IS NULL OR dead_at >= created_at)
        AND (retention_expires_at IS NULL OR retention_expires_at >= created_at)
    )
);

CREATE INDEX idx_guide_saved_outbox_pending_due
    ON guide_saved_lifecycle_outbox (next_attempt_at, created_at, event_id)
    WHERE status = 'PENDING';

CREATE INDEX idx_guide_saved_outbox_lease_recovery
    ON guide_saved_lifecycle_outbox (leased_until, created_at, event_id)
    WHERE status = 'PROCESSING';

CREATE INDEX idx_guide_saved_outbox_terminal_retention
    ON guide_saved_lifecycle_outbox (retention_expires_at, event_id)
    WHERE status IN ('DELIVERED', 'DEAD');

CREATE INDEX idx_guide_saved_state_reconcile_due
    ON guide_saved_lifecycle_state (next_reconcile_at, guide_profile_id)
    WHERE source_deleted = FALSE;

CREATE INDEX idx_guide_saved_state_reconcile_lease
    ON guide_saved_lifecycle_state (reconcile_leased_until, guide_profile_id)
    WHERE reconcile_lease_token IS NOT NULL;

CREATE OR REPLACE FUNCTION guide_saved_revision_floor(value TIMESTAMPTZ)
RETURNS BIGINT
LANGUAGE SQL
IMMUTABLE
STRICT
AS $$
    SELECT GREATEST(1::BIGINT, FLOOR(EXTRACT(EPOCH FROM value) * 1000000)::BIGINT)
$$;

CREATE OR REPLACE FUNCTION guide_saved_effective_visibility(
    profile_id UUID,
    external_known_value BOOLEAN,
    external_account_status_value TEXT,
    external_is_deleted_value BOOLEAN,
    source_deleted_value BOOLEAN
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    profile_status TEXT;
    profile_deleted_at TIMESTAMPTZ;
    verification_status TEXT;
BEGIN
    IF source_deleted_value THEN
        RETURN 'DELETED';
    END IF;

    SELECT gp.status, gp.deleted_at
    INTO profile_status, profile_deleted_at
    FROM guide_profiles gp
    WHERE gp.id = profile_id;

    IF NOT FOUND OR profile_deleted_at IS NOT NULL THEN
        RETURN 'DELETED';
    END IF;

    SELECT vr.status
    INTO verification_status
    FROM guide_verification_requests vr
    WHERE vr.guide_profile_id = profile_id
    ORDER BY vr.created_at DESC, vr.id DESC
    LIMIT 1;

    IF profile_status = 'ACTIVE'
        AND verification_status = 'APPROVED'
        AND external_known_value
        AND external_account_status_value = 'ACTIVE'
        AND NOT external_is_deleted_value THEN
        RETURN 'PUBLIC';
    END IF;

    RETURN 'UNAVAILABLE';
END;
$$;

CREATE OR REPLACE FUNCTION guide_saved_prepare_state()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    semantic_changed BOOLEAN;
    projection_changed BOOLEAN;
    visibility_input_changed BOOLEAN;
    next_visibility TEXT;
    revision_time BIGINT;
    source_floor BIGINT;
    projection_floor BIGINT;
    visibility_floor BIGINT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.semantic_occurred_at := GREATEST(
            NEW.semantic_occurred_at,
            NEW.local_source_changed_at,
            NEW.local_projection_changed_at,
            NEW.local_visibility_changed_at
        );
        NEW.current_visibility := guide_saved_effective_visibility(
            NEW.guide_profile_id,
            NEW.external_known,
            NEW.external_account_status,
            NEW.external_is_deleted,
            NEW.source_deleted
        );
        NEW.source_revision := GREATEST(1, NEW.source_revision);
        NEW.projection_revision := GREATEST(1, NEW.projection_revision);
        NEW.visibility_revision := GREATEST(1, NEW.visibility_revision);
        NEW.media_reference_revision := GREATEST(1, NEW.media_reference_revision);
        NEW.media_reference_active := NEW.current_visibility = 'PUBLIC'
            AND NEW.external_avatar_file_id IS NOT NULL;
        NEW.updated_at := GREATEST(NEW.updated_at, NEW.created_at, NEW.semantic_occurred_at);
        RETURN NEW;
    END IF;

    IF NEW.guide_profile_id IS DISTINCT FROM OLD.guide_profile_id
        OR NEW.user_id IS DISTINCT FROM OLD.user_id THEN
        RAISE EXCEPTION 'Saved guide canonical identity is immutable' USING ERRCODE = '23514';
    END IF;

    projection_changed :=
        NEW.local_projection_changed_at IS DISTINCT FROM OLD.local_projection_changed_at
        OR NEW.external_projection_fingerprint IS DISTINCT FROM OLD.external_projection_fingerprint
        OR NEW.external_avatar_file_id IS DISTINCT FROM OLD.external_avatar_file_id;

    visibility_input_changed :=
        NEW.local_visibility_changed_at IS DISTINCT FROM OLD.local_visibility_changed_at
        OR NEW.source_deleted IS DISTINCT FROM OLD.source_deleted
        OR NEW.external_known IS DISTINCT FROM OLD.external_known
        OR NEW.external_account_status IS DISTINCT FROM OLD.external_account_status
        OR NEW.external_is_deleted IS DISTINCT FROM OLD.external_is_deleted;

    semantic_changed :=
        NEW.local_source_changed_at IS DISTINCT FROM OLD.local_source_changed_at
        OR projection_changed
        OR visibility_input_changed;

    IF NOT semantic_changed THEN
        NEW.source_revision := OLD.source_revision;
        NEW.projection_revision := OLD.projection_revision;
        NEW.visibility_revision := OLD.visibility_revision;
        NEW.current_visibility := OLD.current_visibility;
        NEW.media_reference_revision := OLD.media_reference_revision;
        NEW.media_reference_active := OLD.media_reference_active;
        NEW.semantic_occurred_at := OLD.semantic_occurred_at;
        NEW.updated_at := GREATEST(NEW.updated_at, OLD.updated_at);
        RETURN NEW;
    END IF;

    NEW.semantic_occurred_at := GREATEST(
        NEW.semantic_occurred_at,
        NEW.local_source_changed_at,
        NEW.local_projection_changed_at,
        NEW.local_visibility_changed_at
    );

    next_visibility := guide_saved_effective_visibility(
        NEW.guide_profile_id,
        NEW.external_known,
        NEW.external_account_status,
        NEW.external_is_deleted,
        NEW.source_deleted
    );
    revision_time := guide_saved_revision_floor(NEW.semantic_occurred_at);
    source_floor := GREATEST(
        revision_time,
        guide_saved_revision_floor(NEW.local_source_changed_at),
        COALESCE(guide_saved_revision_floor(NEW.external_account_updated_at), 1),
        COALESCE(guide_saved_revision_floor(NEW.external_profile_updated_at), 1)
    );
    projection_floor := GREATEST(
        revision_time,
        guide_saved_revision_floor(NEW.local_projection_changed_at),
        COALESCE(guide_saved_revision_floor(NEW.external_profile_updated_at), 1)
    );
    visibility_floor := GREATEST(
        revision_time,
        guide_saved_revision_floor(NEW.local_visibility_changed_at),
        COALESCE(guide_saved_revision_floor(NEW.external_account_updated_at), 1)
    );

    NEW.source_revision := GREATEST(OLD.source_revision + 1, source_floor);
    IF projection_changed THEN
        NEW.projection_revision := GREATEST(OLD.projection_revision + 1, projection_floor);
    ELSE
        NEW.projection_revision := OLD.projection_revision;
    END IF;
    IF visibility_input_changed OR next_visibility IS DISTINCT FROM OLD.current_visibility THEN
        NEW.visibility_revision := GREATEST(OLD.visibility_revision + 1, visibility_floor);
    ELSE
        NEW.visibility_revision := OLD.visibility_revision;
    END IF;

    NEW.current_visibility := next_visibility;
    IF next_visibility <> 'PUBLIC' OR NEW.external_avatar_file_id IS NULL THEN
        IF OLD.media_reference_active THEN
            NEW.media_reference_revision := GREATEST(
                OLD.media_reference_revision + 1,
                NEW.source_revision,
                NEW.visibility_revision
            );
        ELSE
            NEW.media_reference_revision := OLD.media_reference_revision;
        END IF;
        NEW.media_reference_active := FALSE;
    ELSE
        IF NOT OLD.media_reference_active
            OR NEW.external_avatar_file_id IS DISTINCT FROM OLD.external_avatar_file_id
            OR projection_changed THEN
            NEW.media_reference_revision := GREATEST(
                OLD.media_reference_revision + 1,
                NEW.projection_revision
            );
        ELSE
            NEW.media_reference_revision := OLD.media_reference_revision;
        END IF;
        NEW.media_reference_active := TRUE;
    END IF;
    NEW.updated_at := GREATEST(clock_timestamp(), OLD.updated_at, NEW.semantic_occurred_at);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_guide_saved_prepare_state
BEFORE INSERT OR UPDATE ON guide_saved_lifecycle_state
FOR EACH ROW
EXECUTE FUNCTION guide_saved_prepare_state();

INSERT INTO guide_saved_lifecycle_state (
    guide_profile_id,
    user_id,
    source_revision,
    projection_revision,
    visibility_revision,
    current_visibility,
    local_source_changed_at,
    local_projection_changed_at,
    local_visibility_changed_at,
    next_reconcile_at,
    semantic_occurred_at,
    created_at,
    updated_at
)
SELECT
    gp.id,
    gp.user_id,
    GREATEST(
        guide_saved_revision_floor(gp.updated_at),
        COALESCE(guide_saved_revision_floor(latest_verification.updated_at), 1)
    ),
    guide_saved_revision_floor(gp.updated_at),
    GREATEST(
        guide_saved_revision_floor(gp.updated_at),
        COALESCE(guide_saved_revision_floor(latest_verification.updated_at), 1)
    ),
    CASE WHEN gp.deleted_at IS NOT NULL THEN 'DELETED' ELSE 'UNAVAILABLE' END,
    GREATEST(gp.updated_at, COALESCE(latest_verification.updated_at, gp.updated_at)),
    gp.updated_at,
    GREATEST(gp.updated_at, COALESCE(latest_verification.updated_at, gp.updated_at)),
    clock_timestamp() + make_interval(
        secs => MOD((hashtextextended(gp.user_id::TEXT, 0) & 2147483647::BIGINT), 300)::INTEGER
    ),
    GREATEST(gp.updated_at, COALESCE(latest_verification.updated_at, gp.updated_at)),
    gp.created_at,
    GREATEST(gp.updated_at, gp.created_at)
FROM guide_profiles gp
LEFT JOIN LATERAL (
    SELECT vr.updated_at
    FROM guide_verification_requests vr
    WHERE vr.guide_profile_id = gp.id
    ORDER BY vr.created_at DESC, vr.id DESC
    LIMIT 1
) latest_verification ON TRUE
ON CONFLICT (guide_profile_id) DO NOTHING;

CREATE OR REPLACE FUNCTION guide_saved_emit_state_event()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    kind_value TEXT;
    event_created_at TIMESTAMPTZ;
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.source_revision = OLD.source_revision THEN
        RETURN NEW;
    END IF;

    kind_value := CASE
        WHEN NEW.current_visibility = 'DELETED' THEN 'DELETED'
        WHEN NEW.current_visibility = 'UNAVAILABLE' THEN 'UNAVAILABLE'
        WHEN TG_OP = 'INSERT' OR OLD.current_visibility <> 'PUBLIC' THEN 'PUBLISHED'
        ELSE 'UPDATED'
    END;
    event_created_at := GREATEST(clock_timestamp(), NEW.semantic_occurred_at);

    INSERT INTO guide_saved_lifecycle_outbox (
        event_id,
        event_kind,
        target_user_id,
        source_revision,
        projection_revision,
        visibility_revision,
        occurred_at,
        visibility,
        public_projection,
        status,
        attempt_count,
        max_attempts,
        next_attempt_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        kind_value,
        NEW.user_id,
        NEW.source_revision,
        NEW.projection_revision,
        NEW.visibility_revision,
        NEW.semantic_occurred_at,
        NEW.current_visibility,
        NULL,
        'PENDING',
        0,
        20,
        event_created_at,
        event_created_at,
        event_created_at
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_guide_saved_emit_state_event
AFTER INSERT OR UPDATE ON guide_saved_lifecycle_state
FOR EACH ROW
EXECUTE FUNCTION guide_saved_emit_state_event();

CREATE OR REPLACE FUNCTION guide_saved_profile_lifecycle_changed()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    change_time TIMESTAMPTZ;
    projection_time TIMESTAMPTZ;
    visibility_time TIMESTAMPTZ;
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.user_id IS DISTINCT FROM OLD.user_id THEN
        RAISE EXCEPTION 'Guide user_id is an immutable Saved canonical identity' USING ERRCODE = '23514';
    END IF;

    IF TG_OP = 'INSERT' THEN
        INSERT INTO guide_saved_lifecycle_state (
            guide_profile_id,
            user_id,
            source_revision,
            projection_revision,
            visibility_revision,
            current_visibility,
            local_source_changed_at,
            local_projection_changed_at,
            local_visibility_changed_at,
            next_reconcile_at,
            semantic_occurred_at,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            NEW.user_id,
            guide_saved_revision_floor(NEW.updated_at),
            guide_saved_revision_floor(NEW.updated_at),
            guide_saved_revision_floor(NEW.updated_at),
            'UNAVAILABLE',
            NEW.updated_at,
            NEW.updated_at,
            NEW.updated_at,
            clock_timestamp() + make_interval(
                secs => MOD((hashtextextended(NEW.user_id::TEXT, 0) & 2147483647::BIGINT), 300)::INTEGER
            ),
            NEW.updated_at,
            NEW.created_at,
            GREATEST(NEW.updated_at, NEW.created_at)
        );
        RETURN NEW;
    END IF;

    change_time := GREATEST(NEW.updated_at, clock_timestamp());
    projection_time := CASE
        WHEN NEW.headline IS DISTINCT FROM OLD.headline
            OR NEW.rating_avg IS DISTINCT FROM OLD.rating_avg
            OR NEW.reviews_count IS DISTINCT FROM OLD.reviews_count
        THEN change_time
        ELSE NULL
    END;
    visibility_time := CASE
        WHEN NEW.status IS DISTINCT FROM OLD.status
            OR NEW.deleted_at IS DISTINCT FROM OLD.deleted_at
        THEN change_time
        ELSE NULL
    END;

    IF projection_time IS NULL AND visibility_time IS NULL THEN
        RETURN NEW;
    END IF;

    UPDATE guide_saved_lifecycle_state
    SET local_source_changed_at = change_time,
        local_projection_changed_at = COALESCE(projection_time, local_projection_changed_at),
        local_visibility_changed_at = COALESCE(visibility_time, local_visibility_changed_at),
        source_deleted = NEW.deleted_at IS NOT NULL,
        next_reconcile_at = CASE
            WHEN visibility_time IS NOT NULL THEN LEAST(next_reconcile_at, change_time)
            ELSE next_reconcile_at
        END,
        semantic_occurred_at = change_time
    WHERE guide_profile_id = NEW.id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_guide_saved_profile_inserted
AFTER INSERT ON guide_profiles
FOR EACH ROW
EXECUTE FUNCTION guide_saved_profile_lifecycle_changed();

CREATE TRIGGER trg_guide_saved_profile_updated
AFTER UPDATE OF user_id, status, headline, rating_avg, reviews_count, deleted_at ON guide_profiles
FOR EACH ROW
EXECUTE FUNCTION guide_saved_profile_lifecycle_changed();

CREATE OR REPLACE FUNCTION guide_saved_profile_deleting()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    change_time TIMESTAMPTZ := clock_timestamp();
BEGIN
    UPDATE guide_saved_lifecycle_state
    SET source_deleted = TRUE,
        local_source_changed_at = change_time,
        local_visibility_changed_at = change_time,
        semantic_occurred_at = change_time
    WHERE guide_profile_id = OLD.id;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_guide_saved_profile_deleting
BEFORE DELETE ON guide_profiles
FOR EACH ROW
EXECUTE FUNCTION guide_saved_profile_deleting();

CREATE OR REPLACE FUNCTION guide_saved_verification_lifecycle_changed()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    profile_id UUID;
    request_id UUID;
    latest_id UUID;
    change_time TIMESTAMPTZ := clock_timestamp();
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.id IS DISTINCT FROM OLD.id
            OR NEW.guide_profile_id IS DISTINCT FROM OLD.guide_profile_id
            OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
            RAISE EXCEPTION 'Verification identity and ordering are immutable' USING ERRCODE = '23514';
        END IF;
        IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
            RETURN NEW;
        END IF;
    END IF;

    profile_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.guide_profile_id ELSE NEW.guide_profile_id END;
    request_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END;

    SELECT vr.id
    INTO latest_id
    FROM guide_verification_requests vr
    WHERE vr.guide_profile_id = profile_id
    ORDER BY vr.created_at DESC, vr.id DESC
    LIMIT 1;

    IF TG_OP <> 'DELETE' AND latest_id IS DISTINCT FROM request_id THEN
        RETURN NEW;
    END IF;
    IF TG_OP = 'DELETE' AND EXISTS (
        SELECT 1
        FROM guide_verification_requests vr
        WHERE vr.guide_profile_id = profile_id
          AND (vr.created_at, vr.id) > (OLD.created_at, OLD.id)
    ) THEN
        RETURN OLD;
    END IF;

    UPDATE guide_saved_lifecycle_state
    SET local_source_changed_at = change_time,
        local_visibility_changed_at = change_time,
        next_reconcile_at = LEAST(next_reconcile_at, change_time),
        semantic_occurred_at = change_time
    WHERE guide_profile_id = profile_id;
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER trg_guide_saved_verification_inserted
AFTER INSERT ON guide_verification_requests
FOR EACH ROW
EXECUTE FUNCTION guide_saved_verification_lifecycle_changed();

CREATE TRIGGER trg_guide_saved_verification_updated
AFTER UPDATE OF id, guide_profile_id, status, created_at ON guide_verification_requests
FOR EACH ROW
EXECUTE FUNCTION guide_saved_verification_lifecycle_changed();

CREATE TRIGGER trg_guide_saved_verification_deleted
AFTER DELETE ON guide_verification_requests
FOR EACH ROW
EXECUTE FUNCTION guide_saved_verification_lifecycle_changed();

CREATE OR REPLACE FUNCTION guide_saved_outbox_semantics_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.event_id IS DISTINCT FROM OLD.event_id
        OR NEW.event_kind IS DISTINCT FROM OLD.event_kind
        OR NEW.target_user_id IS DISTINCT FROM OLD.target_user_id
        OR NEW.source_revision IS DISTINCT FROM OLD.source_revision
        OR NEW.projection_revision IS DISTINCT FROM OLD.projection_revision
        OR NEW.visibility_revision IS DISTINCT FROM OLD.visibility_revision
        OR NEW.occurred_at IS DISTINCT FROM OLD.occurred_at
        OR NEW.visibility IS DISTINCT FROM OLD.visibility
        OR NEW.public_projection IS DISTINCT FROM OLD.public_projection
        OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'Saved lifecycle event semantics are immutable' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_guide_saved_outbox_semantics_immutable
BEFORE UPDATE ON guide_saved_lifecycle_outbox
FOR EACH ROW
EXECUTE FUNCTION guide_saved_outbox_semantics_immutable();

CREATE OR REPLACE FUNCTION guide_saved_outbox_no_delete_before_terminal()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status NOT IN ('DELIVERED', 'DEAD')
        OR OLD.retention_expires_at IS NULL
        OR OLD.retention_expires_at > clock_timestamp() THEN
        RAISE EXCEPTION 'Saved lifecycle event is not retention-eligible' USING ERRCODE = '55000';
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_guide_saved_outbox_no_delete_before_terminal
BEFORE DELETE ON guide_saved_lifecycle_outbox
FOR EACH ROW
EXECUTE FUNCTION guide_saved_outbox_no_delete_before_terminal();

COMMIT;
