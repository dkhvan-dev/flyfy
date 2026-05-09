ALTER TABLE activities
    DROP CONSTRAINT chk_activities_join_mode;

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_join_mode
        CHECK (join_mode IN ('AUTO_APPROVE', 'MANUAL_APPROVE'));
