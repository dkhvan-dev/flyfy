ALTER TABLE moderation_cases
    DROP CONSTRAINT IF EXISTS chk_moderation_cases_target_type;

ALTER TABLE moderation_cases
    ADD CONSTRAINT chk_moderation_cases_target_type
    CHECK (target_type IN ('EXCURSION', 'ACTIVITY', 'GUIDE_APPLICATION', 'CHAT_MESSAGE', 'STORY'));

INSERT INTO staff_roles(code, name, description, is_system) VALUES
    ('GUIDE_MODERATOR', 'Guide moderator', 'Can review guide status applications', TRUE)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_system = EXCLUDED.is_system;

INSERT INTO staff_permissions(code, domain, action, description) VALUES
    ('guide.moderate', 'guide', 'moderate', 'Approve or reject guide status applications')
ON CONFLICT (code) DO UPDATE
SET domain = EXCLUDED.domain,
    action = EXCLUDED.action,
    description = EXCLUDED.description;

INSERT INTO staff_role_permissions(role_code, permission_code) VALUES
    ('SUPER_ADMIN', 'guide.moderate'),
    ('MODERATION_LEAD', 'guide.moderate'),
    ('GUIDE_MODERATOR', 'dashboard.read'),
    ('GUIDE_MODERATOR', 'moderation.read'),
    ('GUIDE_MODERATOR', 'guide.moderate')
ON CONFLICT DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_moderation_cases_guide_application_search_trgm
    ON moderation_cases
    USING GIN (
        (LOWER(
            COALESCE(snapshot->>'GuideDisplayName', '') || ' ' ||
            COALESCE(snapshot->>'FirstName', '') || ' ' ||
            COALESCE(snapshot->>'LastName', '') || ' ' ||
            COALESCE(snapshot->>'Headline', '') || ' ' ||
            COALESCE(snapshot->>'About', '') || ' ' ||
            COALESCE(snapshot->>'Languages', '') || ' ' ||
            COALESCE(snapshot->>'Specializations', '')
        )) gin_trgm_ops
    )
    WHERE target_type = 'GUIDE_APPLICATION';

CREATE INDEX IF NOT EXISTS idx_moderation_cases_guide_application_city
    ON moderation_cases (
        LOWER(COALESCE(snapshot->>'BaseCityID', '')),
        LOWER(COALESCE(snapshot->>'BaseCityName', ''))
    )
    WHERE target_type = 'GUIDE_APPLICATION';
