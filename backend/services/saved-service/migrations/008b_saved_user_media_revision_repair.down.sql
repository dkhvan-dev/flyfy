DO $saved_user_media_revision_repair_irreversible$
BEGIN
    RAISE EXCEPTION USING
        ERRCODE = '55000',
        MESSAGE = 'migration 008b is an irreversible cleanup of cross-source media revisions';
END
$saved_user_media_revision_repair_irreversible$;
