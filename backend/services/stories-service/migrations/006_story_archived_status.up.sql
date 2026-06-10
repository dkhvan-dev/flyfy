-- Expand the status check with the long table scan happening during VALIDATE
-- instead of under the final short ACCESS EXCLUSIVE lock window.
ALTER TABLE stories
    ADD CONSTRAINT chk_stories_status_expanded
    CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')) NOT VALID;

ALTER TABLE stories
    VALIDATE CONSTRAINT chk_stories_status_expanded;

ALTER TABLE stories
    DROP CONSTRAINT IF EXISTS chk_stories_status;

ALTER TABLE stories
    RENAME CONSTRAINT chk_stories_status_expanded TO chk_stories_status;
