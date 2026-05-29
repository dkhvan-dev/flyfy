INSERT INTO staff_permissions(code, domain, action, description) VALUES
    ('fraud.review', 'fraud', 'review', 'Review anti-fraud blocks and record false-positive, escalation, or confirmed-fraud outcomes')
ON CONFLICT (code) DO UPDATE
SET domain = EXCLUDED.domain,
    action = EXCLUDED.action,
    description = EXCLUDED.description;

INSERT INTO staff_role_permissions(role_code, permission_code) VALUES
    ('SUPER_ADMIN', 'fraud.review'),
    ('MODERATION_LEAD', 'fraud.review')
ON CONFLICT DO NOTHING;
