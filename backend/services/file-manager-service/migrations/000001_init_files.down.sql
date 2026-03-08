DROP TRIGGER IF EXISTS trg_files_set_updated_at ON files;

DROP INDEX IF EXISTS idx_files_bucket_object_key;
DROP INDEX IF EXISTS idx_files_is_deleted;
DROP INDEX IF EXISTS idx_files_created_at;
DROP INDEX IF EXISTS idx_files_status;
DROP INDEX IF EXISTS idx_files_purpose;
DROP INDEX IF EXISTS idx_files_uploaded_by_user_id;
DROP INDEX IF EXISTS idx_files_owner;

DROP TABLE IF EXISTS files;