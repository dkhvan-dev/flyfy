UPDATE activities
SET join_mode = 'AUTO_APPROVE',
    updated_at = NOW()
WHERE join_mode <> 'AUTO_APPROVE';

ALTER TABLE activities
    DROP CONSTRAINT chk_activities_join_mode;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_join_mode
        CHECK (join_mode = 'AUTO_APPROVE');
