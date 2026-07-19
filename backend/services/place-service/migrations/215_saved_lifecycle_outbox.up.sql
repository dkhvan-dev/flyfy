CREATE TABLE IF NOT EXISTS place_saved_lifecycle_outbox (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schema_version SMALLINT NOT NULL DEFAULT 1,
    event_type TEXT NOT NULL,
    entity_type TEXT NOT NULL DEFAULT 'ATTRACTION',
    entity_id UUID NOT NULL,
    source_revision BIGINT NOT NULL,
    projection_revision BIGINT NOT NULL,
    visibility_revision BIGINT NOT NULL,
    visibility TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,

    -- origin_txid is internal coalescing state. Multiple child-table writes in
    -- one source transaction produce one immutable lifecycle envelope.
    origin_txid XID8 NOT NULL,
    aggregate_was_absent BOOLEAN NOT NULL DEFAULT false,
    initial_visibility TEXT NOT NULL,

    status TEXT NOT NULL DEFAULT 'PENDING',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL,
    locked_at TIMESTAMPTZ,
    lease_id UUID,
    delivered_at TIMESTAMPTZ,
    dead_at TIMESTAMPTZ,
    last_error_code TEXT,
    retention_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT place_saved_lifecycle_outbox_origin_key
        UNIQUE (origin_txid, entity_id),
    CONSTRAINT place_saved_lifecycle_outbox_event_id_v4_check
        CHECK (
            substring(event_id::text FROM 15 FOR 1) = '4'
            AND substring(event_id::text FROM 20 FOR 1) IN ('8', '9', 'a', 'b')
        ),
    CONSTRAINT place_saved_lifecycle_outbox_schema_check
        CHECK (schema_version = 1),
    CONSTRAINT place_saved_lifecycle_outbox_event_type_check
        CHECK (
            event_type IN (
                'content.published',
                'content.updated',
                'content.unavailable',
                'content.deleted',
                'content.visibility_changed'
            )
        ),
    CONSTRAINT place_saved_lifecycle_outbox_entity_type_check
        CHECK (entity_type = 'ATTRACTION'),
    CONSTRAINT place_saved_lifecycle_outbox_revisions_check
        CHECK (
            source_revision > 0
            AND projection_revision > 0
            AND visibility_revision > 0
        ),
    CONSTRAINT place_saved_lifecycle_outbox_visibility_check
        CHECK (visibility IN ('PUBLIC', 'UNAVAILABLE', 'DELETED', 'RESTRICTED')),
    CONSTRAINT place_saved_lifecycle_outbox_event_visibility_check
        CHECK (
            (event_type IN ('content.published', 'content.updated') AND visibility = 'PUBLIC')
            OR (event_type = 'content.unavailable' AND visibility = 'UNAVAILABLE')
            OR (event_type = 'content.deleted' AND visibility = 'DELETED')
            OR (event_type = 'content.visibility_changed' AND visibility = 'RESTRICTED')
        ),
    CONSTRAINT place_saved_lifecycle_outbox_initial_visibility_check
        CHECK (initial_visibility IN ('ABSENT', 'PUBLIC', 'UNAVAILABLE', 'DELETED', 'RESTRICTED')),
    CONSTRAINT place_saved_lifecycle_outbox_status_check
        CHECK (status IN ('PENDING', 'DELIVERED', 'DEAD')),
    CONSTRAINT place_saved_lifecycle_outbox_attempts_check
        CHECK (attempt_count >= 0),
    CONSTRAINT place_saved_lifecycle_outbox_error_code_check
        CHECK (
            last_error_code IS NULL
            OR (
                octet_length(last_error_code) BETWEEN 1 AND 64
                AND last_error_code ~ '^[A-Z][A-Z0-9_]*$'
            )
        ),
    CONSTRAINT place_saved_lifecycle_outbox_lease_check
        CHECK ((locked_at IS NULL) = (lease_id IS NULL)),
    CONSTRAINT place_saved_lifecycle_outbox_lifecycle_check
        CHECK (
            (
                status = 'PENDING'
                AND delivered_at IS NULL
                AND dead_at IS NULL
                AND retention_expires_at IS NULL
            )
            OR (
                status = 'DELIVERED'
                AND delivered_at IS NOT NULL
                AND dead_at IS NULL
                AND locked_at IS NULL
                AND lease_id IS NULL
                AND retention_expires_at = delivered_at + INTERVAL '14 days'
            )
            OR (
                status = 'DEAD'
                AND delivered_at IS NULL
                AND dead_at IS NOT NULL
                AND locked_at IS NULL
                AND lease_id IS NULL
                AND retention_expires_at = dead_at + INTERVAL '14 days'
            )
        ),
    CONSTRAINT place_saved_lifecycle_outbox_timestamps_check
        CHECK (
            isfinite(occurred_at)
            AND isfinite(next_attempt_at)
            AND isfinite(created_at)
            AND isfinite(updated_at)
            AND occurred_at >= created_at
            AND next_attempt_at >= created_at
            AND updated_at >= created_at
            AND (locked_at IS NULL OR locked_at >= created_at)
            AND (delivered_at IS NULL OR delivered_at >= created_at)
            AND (dead_at IS NULL OR dead_at >= created_at)
        )
);

-- Reconcile a retry after a legacy runner committed DDL before writing its
-- migration marker. These named constraints also remove the retired DLQ draft.
ALTER TABLE place_saved_lifecycle_outbox
    DROP CONSTRAINT IF EXISTS place_saved_lifecycle_outbox_attempts_check,
    DROP CONSTRAINT IF EXISTS place_saved_lifecycle_outbox_status_check,
    DROP CONSTRAINT IF EXISTS place_saved_lifecycle_outbox_lifecycle_check;

ALTER TABLE place_saved_lifecycle_outbox
    DROP COLUMN IF EXISTS dlq_attempt_count;

ALTER TABLE place_saved_lifecycle_outbox
    ADD CONSTRAINT place_saved_lifecycle_outbox_status_check
        CHECK (status IN ('PENDING', 'DELIVERED', 'DEAD')),
    ADD CONSTRAINT place_saved_lifecycle_outbox_attempts_check
        CHECK (attempt_count >= 0),
    ADD CONSTRAINT place_saved_lifecycle_outbox_lifecycle_check
        CHECK (
            (
                status = 'PENDING'
                AND delivered_at IS NULL
                AND dead_at IS NULL
                AND retention_expires_at IS NULL
            )
            OR (
                status = 'DELIVERED'
                AND delivered_at IS NOT NULL
                AND dead_at IS NULL
                AND locked_at IS NULL
                AND lease_id IS NULL
                AND retention_expires_at = delivered_at + INTERVAL '14 days'
            )
            OR (
                status = 'DEAD'
                AND delivered_at IS NULL
                AND dead_at IS NOT NULL
                AND locked_at IS NULL
                AND lease_id IS NULL
                AND retention_expires_at = dead_at + INTERVAL '14 days'
            )
        );

CREATE INDEX IF NOT EXISTS idx_place_saved_lifecycle_outbox_due
    ON place_saved_lifecycle_outbox (next_attempt_at, created_at, event_id)
    WHERE status = 'PENDING';

CREATE INDEX IF NOT EXISTS idx_place_saved_lifecycle_outbox_lease_recovery
    ON place_saved_lifecycle_outbox (locked_at, event_id)
    WHERE status = 'PENDING' AND locked_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_place_saved_lifecycle_outbox_retention
    ON place_saved_lifecycle_outbox (retention_expires_at, event_id)
    WHERE status IN ('DELIVERED', 'DEAD');

CREATE OR REPLACE FUNCTION protect_place_saved_lifecycle_outbox()
RETURNS trigger AS $$
DECLARE
    envelope_changed boolean;
BEGIN
    IF NEW.event_id IS DISTINCT FROM OLD.event_id
       OR NEW.entity_type IS DISTINCT FROM OLD.entity_type
       OR NEW.entity_id IS DISTINCT FROM OLD.entity_id
       OR NEW.origin_txid IS DISTINCT FROM OLD.origin_txid
       OR NEW.aggregate_was_absent IS DISTINCT FROM OLD.aggregate_was_absent
       OR NEW.initial_visibility IS DISTINCT FROM OLD.initial_visibility
       OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
        RAISE EXCEPTION 'Saved lifecycle outbox identity is immutable'
            USING ERRCODE = '55000';
    END IF;

    envelope_changed := NEW.schema_version IS DISTINCT FROM OLD.schema_version
        OR NEW.event_type IS DISTINCT FROM OLD.event_type
        OR NEW.source_revision IS DISTINCT FROM OLD.source_revision
        OR NEW.projection_revision IS DISTINCT FROM OLD.projection_revision
        OR NEW.visibility_revision IS DISTINCT FROM OLD.visibility_revision
        OR NEW.visibility IS DISTINCT FROM OLD.visibility
        OR NEW.occurred_at IS DISTINCT FROM OLD.occurred_at;
    IF envelope_changed AND OLD.origin_txid IS DISTINCT FROM pg_current_xact_id() THEN
        RAISE EXCEPTION 'Saved lifecycle envelope is immutable after source commit'
            USING ERRCODE = '55000';
    END IF;

    IF NOT (
        (OLD.status = 'PENDING' AND NEW.status IN ('PENDING', 'DELIVERED', 'DEAD'))
        OR (OLD.status = 'DELIVERED' AND NEW.status = 'DELIVERED')
        OR (OLD.status = 'DEAD' AND NEW.status = 'DEAD')
    ) THEN
        RAISE EXCEPTION 'invalid Saved lifecycle outbox state transition'
            USING ERRCODE = '55000';
    END IF;
    IF NEW.attempt_count < OLD.attempt_count THEN
        RAISE EXCEPTION 'Saved lifecycle attempt counters are monotonic'
            USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_place_saved_lifecycle_outbox
    ON place_saved_lifecycle_outbox;
CREATE TRIGGER trg_protect_place_saved_lifecycle_outbox
    BEFORE UPDATE ON place_saved_lifecycle_outbox
    FOR EACH ROW
    EXECUTE FUNCTION protect_place_saved_lifecycle_outbox();

-- Keep source, projection, and visibility revisions independent. Projection
-- revision also rotates on every visibility transition so a previously issued
-- opaque media reference can no longer match current source state.
CREATE OR REPLACE FUNCTION bump_place_saved_source_revisions()
RETURNS trigger AS $$
DECLARE
    old_source jsonb;
    new_source jsonb;
    source_changed boolean;
    projection_changed boolean;
    visibility_changed boolean;
BEGIN
    old_source := to_jsonb(OLD)
        - 'updated_at'
        - 'saved_source_revision'
        - 'saved_projection_revision'
        - 'saved_visibility_revision';
    new_source := to_jsonb(NEW)
        - 'updated_at'
        - 'saved_source_revision'
        - 'saved_projection_revision'
        - 'saved_visibility_revision';

    source_changed := new_source IS DISTINCT FROM old_source;
    visibility_changed := NEW.status IS DISTINCT FROM OLD.status
        OR NEW.deleted_at IS DISTINCT FROM OLD.deleted_at
        OR NEW.default_locale IS DISTINCT FROM OLD.default_locale;
    projection_changed := visibility_changed
        OR NEW.default_locale IS DISTINCT FROM OLD.default_locale
        OR NEW.country_code IS DISTINCT FROM OLD.country_code
        OR NEW.city_id IS DISTINCT FROM OLD.city_id
        OR NEW.rating IS DISTINCT FROM OLD.rating
        OR NEW.review_count IS DISTINCT FROM OLD.review_count;

    IF source_changed THEN
        NEW.saved_source_revision := nextval('place_saved_source_revision_seq');
    END IF;
    IF projection_changed THEN
        NEW.saved_projection_revision := nextval('place_saved_source_revision_seq');
    END IF;
    IF visibility_changed THEN
        NEW.saved_visibility_revision := nextval('place_saved_source_revision_seq');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Child-table technical timestamps and search vectors do not rotate a Saved
-- projection. Card-visible translation/media changes do.
CREATE OR REPLACE FUNCTION bump_place_saved_projection_from_child()
RETURNS trigger AS $$
DECLARE
    old_place_id uuid;
    new_place_id uuid;
    old_projection jsonb;
    new_projection jsonb;
BEGIN
    IF TG_OP <> 'INSERT' THEN
        old_place_id := OLD.place_id;
    END IF;
    IF TG_OP <> 'DELETE' THEN
        new_place_id := NEW.place_id;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF TG_TABLE_NAME = 'place_translations' THEN
            old_projection := to_jsonb(OLD) - 'created_at' - 'updated_at' - 'search_vector';
            new_projection := to_jsonb(NEW) - 'created_at' - 'updated_at' - 'search_vector';
        ELSE
            old_projection := to_jsonb(OLD) - 'created_at' - 'source_url' - 'credit' - 'license';
            new_projection := to_jsonb(NEW) - 'created_at' - 'source_url' - 'credit' - 'license';
        END IF;
        IF old_projection IS NOT DISTINCT FROM new_projection THEN
            RETURN NEW;
        END IF;
    END IF;

    IF old_place_id IS NOT NULL THEN
        IF TG_TABLE_NAME = 'place_translations' THEN
            UPDATE places
            SET
                saved_source_revision = nextval('place_saved_source_revision_seq'),
                saved_projection_revision = nextval('place_saved_source_revision_seq'),
                saved_visibility_revision = nextval('place_saved_source_revision_seq')
            WHERE id = old_place_id;
        ELSE
            UPDATE places
            SET
                saved_source_revision = nextval('place_saved_source_revision_seq'),
                saved_projection_revision = nextval('place_saved_source_revision_seq')
            WHERE id = old_place_id;
        END IF;
    END IF;

    IF new_place_id IS NOT NULL AND new_place_id IS DISTINCT FROM old_place_id THEN
        IF TG_TABLE_NAME = 'place_translations' THEN
            UPDATE places
            SET
                saved_source_revision = nextval('place_saved_source_revision_seq'),
                saved_projection_revision = nextval('place_saved_source_revision_seq'),
                saved_visibility_revision = nextval('place_saved_source_revision_seq')
            WHERE id = new_place_id;
        ELSE
            UPDATE places
            SET
                saved_source_revision = nextval('place_saved_source_revision_seq'),
                saved_projection_revision = nextval('place_saved_source_revision_seq')
            WHERE id = new_place_id;
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION current_place_saved_visibility(
    target_id uuid,
    target_status varchar,
    target_deleted_at timestamptz,
    target_default_locale varchar
)
RETURNS text AS $$
BEGIN
    IF target_deleted_at IS NOT NULL THEN
        RETURN 'DELETED';
    END IF;
    IF target_status <> 'PUBLISHED' THEN
        RETURN 'RESTRICTED';
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM place_translations translation
        WHERE translation.place_id = target_id
          AND translation.locale = target_default_locale
          AND btrim(translation.title) <> ''
    ) THEN
        RETURN 'UNAVAILABLE';
    END IF;
    RETURN 'PUBLIC';
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION enqueue_place_saved_lifecycle_event()
RETURNS trigger AS $$
DECLARE
    transaction_id xid8 := pg_current_xact_id();
    current_visibility text;
    first_visibility text;
    was_absent boolean;
    lifecycle_event_type text;
    existing_row boolean := false;
    event_time timestamptz := clock_timestamp();
BEGIN
    IF TG_OP = 'UPDATE'
       AND NEW.saved_projection_revision = OLD.saved_projection_revision
       AND NEW.saved_visibility_revision = OLD.saved_visibility_revision THEN
        RETURN NEW;
    END IF;

    current_visibility := current_place_saved_visibility(
        NEW.id,
        NEW.status,
        NEW.deleted_at,
        NEW.default_locale
    );

    SELECT outbox.aggregate_was_absent, outbox.initial_visibility
    INTO was_absent, first_visibility
    FROM place_saved_lifecycle_outbox outbox
    WHERE outbox.origin_txid = transaction_id
      AND outbox.entity_id = NEW.id;
    existing_row := FOUND;

    IF NOT existing_row THEN
        was_absent := TG_OP = 'INSERT';
        IF was_absent THEN
            first_visibility := 'ABSENT';
        ELSE
            first_visibility := current_place_saved_visibility(
                OLD.id,
                OLD.status,
                OLD.deleted_at,
                OLD.default_locale
            );
        END IF;
    END IF;

    IF was_absent AND current_visibility = 'RESTRICTED' THEN
        DELETE FROM place_saved_lifecycle_outbox
        WHERE origin_txid = transaction_id
          AND entity_id = NEW.id;
        RETURN NEW;
    END IF;
    IF NOT existing_row
       AND current_visibility = 'RESTRICTED'
       AND first_visibility = 'RESTRICTED' THEN
        RETURN NEW;
    END IF;

    lifecycle_event_type := CASE current_visibility
        WHEN 'DELETED' THEN 'content.deleted'
        WHEN 'UNAVAILABLE' THEN 'content.unavailable'
        WHEN 'RESTRICTED' THEN 'content.visibility_changed'
        WHEN 'PUBLIC' THEN
            CASE
                WHEN was_absent OR first_visibility <> 'PUBLIC' THEN 'content.published'
                ELSE 'content.updated'
            END
        ELSE NULL
    END;

    IF lifecycle_event_type IS NULL THEN
        RETURN NEW;
    END IF;

    INSERT INTO place_saved_lifecycle_outbox (
        event_id,
        schema_version,
        event_type,
        entity_type,
        entity_id,
        source_revision,
        projection_revision,
        visibility_revision,
        visibility,
        occurred_at,
        origin_txid,
        aggregate_was_absent,
        initial_visibility,
        status,
        attempt_count,
        next_attempt_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        1,
        lifecycle_event_type,
        'ATTRACTION',
        NEW.id,
        NEW.saved_source_revision,
        NEW.saved_projection_revision,
        NEW.saved_visibility_revision,
        current_visibility,
        event_time,
        transaction_id,
        was_absent,
        first_visibility,
        'PENDING',
        0,
        event_time,
        event_time,
        event_time
    )
    ON CONFLICT (origin_txid, entity_id) DO UPDATE
    SET
        event_type = EXCLUDED.event_type,
        source_revision = EXCLUDED.source_revision,
        projection_revision = EXCLUDED.projection_revision,
        visibility_revision = EXCLUDED.visibility_revision,
        visibility = EXCLUDED.visibility,
        occurred_at = EXCLUDED.occurred_at,
        next_attempt_at = EXCLUDED.next_attempt_at,
        updated_at = EXCLUDED.updated_at;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_places_saved_lifecycle_outbox ON places;
CREATE TRIGGER trg_places_saved_lifecycle_outbox
    AFTER INSERT OR UPDATE ON places
    FOR EACH ROW
    EXECUTE FUNCTION enqueue_place_saved_lifecycle_event();
