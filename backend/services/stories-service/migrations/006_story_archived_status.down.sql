-- Downgrade cannot keep ARCHIVED rows under the legacy check. Convert only
-- affected rows first, then validate the legacy constraint before the final
-- short lock window that swaps constraint names.
UPDATE stories
SET status = 'PUBLISHED'
WHERE status = 'ARCHIVED';

ALTER TABLE stories
    ADD CONSTRAINT chk_stories_status_legacy
    CHECK (status IN ('DRAFT', 'PUBLISHED')) NOT VALID;

ALTER TABLE stories
    VALIDATE CONSTRAINT chk_stories_status_legacy;

ALTER TABLE stories
    DROP CONSTRAINT IF EXISTS chk_stories_status;

ALTER TABLE stories
    RENAME CONSTRAINT chk_stories_status_legacy TO chk_stories_status;
