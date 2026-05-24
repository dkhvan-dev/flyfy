DROP INDEX IF EXISTS idx_moderation_cases_guide_application_city;
DROP INDEX IF EXISTS idx_moderation_cases_guide_application_search_trgm;

DELETE FROM staff_role_permissions
WHERE role_code = 'GUIDE_MODERATOR'
   OR permission_code = 'guide.moderate';

DELETE FROM staff_permissions
WHERE code = 'guide.moderate';

DELETE FROM staff_roles
WHERE code = 'GUIDE_MODERATOR';

ALTER TABLE moderation_cases
    DROP CONSTRAINT IF EXISTS chk_moderation_cases_target_type;

ALTER TABLE moderation_cases
    ADD CONSTRAINT chk_moderation_cases_target_type
    CHECK (target_type IN ('EXCURSION', 'ACTIVITY', 'CHAT_MESSAGE', 'STORY'));
