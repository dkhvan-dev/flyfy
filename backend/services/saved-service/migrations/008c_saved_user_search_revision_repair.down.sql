DO $saved_user_search_revision_repair_irreversible$
BEGIN
    RAISE EXCEPTION USING
        ERRCODE = '55000',
        MESSAGE = 'migration 008c is an irreversible cleanup of cross-source search revisions';
END
$saved_user_search_revision_repair_irreversible$;
