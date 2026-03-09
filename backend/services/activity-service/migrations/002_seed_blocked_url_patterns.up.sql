INSERT INTO blocked_url_patterns (
    id,
    pattern_type,
    pattern_value,
    action,
    is_active,
    comment,
    created_at
)
VALUES
    (
        gen_random_uuid(),
        'CONTAINS',
        't.me/',
        'REVIEW',
        TRUE,
        'Telegram links should be reviewed',
        NOW()
    ),
    (
        gen_random_uuid(),
        'DOMAIN',
        'example-bad-site.com',
        'BLOCK',
        TRUE,
        'Blocked suspicious domain',
        NOW()
    ),
    (
        gen_random_uuid(),
        'STARTS_WITH',
        'javascript:',
        'BLOCK',
        TRUE,
        'Blocked unsafe javascript pseudo-protocol',
        NOW()
    );