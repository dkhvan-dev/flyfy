-- The retired official sticker catalog is replaced by the generated .tgs
-- catalog. Re-activating legacy stickers on rollback would expose outdated
-- assets and can conflict with the current catalog, so this migration is
-- intentionally irreversible.
SELECT 1;
