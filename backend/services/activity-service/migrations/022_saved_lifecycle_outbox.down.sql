DO $$
BEGIN
    IF to_regclass('activity_saved_lifecycle_outbox') IS NOT NULL
       AND EXISTS (SELECT 1 FROM activity_saved_lifecycle_outbox LIMIT 1) THEN
        RAISE EXCEPTION 'refusing to drop non-empty activity Saved lifecycle outbox'
            USING ERRCODE = '55000';
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_activities_saved_deleted_outbox ON activities;
DROP FUNCTION IF EXISTS enqueue_activity_saved_deleted_event();

DROP TRIGGER IF EXISTS trg_activity_saved_lifecycle_outbox_immutable
    ON activity_saved_lifecycle_outbox;
DROP FUNCTION IF EXISTS protect_activity_saved_lifecycle_outbox_semantics();
DROP TABLE IF EXISTS activity_saved_lifecycle_outbox;

DROP TRIGGER IF EXISTS trg_activities_saved_source_revisions ON activities;
DROP FUNCTION IF EXISTS bump_activity_saved_source_revisions();
DROP FUNCTION IF EXISTS activity_saved_effective_visibility(TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ);

ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_saved_visibility_revision_positive,
    DROP CONSTRAINT IF EXISTS chk_activities_saved_projection_revision_positive,
    DROP CONSTRAINT IF EXISTS chk_activities_saved_source_revision_positive,
    DROP COLUMN IF EXISTS saved_visibility_revision,
    DROP COLUMN IF EXISTS saved_projection_revision,
    DROP COLUMN IF EXISTS saved_source_revision;

DROP SEQUENCE IF EXISTS activity_saved_source_revision_seq;
