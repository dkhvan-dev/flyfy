CREATE INDEX IF NOT EXISTS idx_files_expired_upload_cleanup
    ON files(purpose, upload_expires_at)
    WHERE is_deleted = FALSE
      AND upload_expires_at IS NOT NULL;
