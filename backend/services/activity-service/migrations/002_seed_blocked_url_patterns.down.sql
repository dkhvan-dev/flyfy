DELETE FROM blocked_url_patterns
WHERE
    (pattern_type = 'CONTAINS' AND pattern_value = 't.me/' AND action = 'REVIEW')
    OR
    (pattern_type = 'DOMAIN' AND pattern_value = 'example-bad-site.com' AND action = 'BLOCK')
    OR
    (pattern_type = 'STARTS_WITH' AND pattern_value = 'javascript:' AND action = 'BLOCK');