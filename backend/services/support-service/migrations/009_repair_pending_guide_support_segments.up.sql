WITH non_verified_guide_statuses(status) AS (
    VALUES
        ('draft'),
        ('pending_review'),
        ('submitted'),
        ('under_review'),
        ('suspended'),
        ('rejected'),
        ('revoked')
),
repaired_user_segments AS (
    SELECT
        user_id,
        CASE
            WHEN manual_segment IN ('guide', 'creator', 'vip', 'partner') THEN manual_segment
            WHEN is_partner THEN 'partner'
            WHEN is_public_figure OR followers_count >= 100000 THEN 'vip'
            WHEN followers_count >= 10000 THEN 'creator'
            ELSE 'standard'
        END AS repaired_segment,
        array_remove(array_remove(reason_codes, 'verified_guide'), 'guide_profile') AS repaired_reason_codes
    FROM support_user_segments
    WHERE upper(replace(trim(guide_status), '-', '_')) = ANY (
        SELECT upper(status) FROM non_verified_guide_statuses
    )
      AND (is_guide OR customer_segment = 'guide' OR 'verified_guide' = ANY(reason_codes))
)
UPDATE support_user_segments AS segment
SET
    is_guide = false,
    customer_segment = repaired.repaired_segment,
    reason_codes = CASE
        WHEN cardinality(repaired.repaired_reason_codes) = 0 THEN ARRAY['standard']::TEXT[]
        ELSE repaired.repaired_reason_codes
    END,
    updated_at = now()
FROM repaired_user_segments AS repaired
WHERE segment.user_id = repaired.user_id;

WITH non_verified_guide_statuses(status) AS (
    VALUES
        ('draft'),
        ('pending_review'),
        ('submitted'),
        ('under_review'),
        ('suspended'),
        ('rejected'),
        ('revoked')
),
repaired_tickets AS (
    SELECT
        id,
        CASE
            WHEN followers_count_snapshot >= 100000 THEN 'vip'
            WHEN followers_count_snapshot >= 10000 THEN 'creator'
            ELSE 'standard'
        END AS repaired_segment,
        array_remove(array_remove(customer_segment_reason_codes, 'verified_guide'), 'guide_profile') AS repaired_segment_reason_codes,
        array_remove(priority_reason_codes, 'segment_guide') AS repaired_priority_reason_codes
    FROM support_tickets
    WHERE upper(replace(trim(guide_status_snapshot), '-', '_')) = ANY (
        SELECT upper(status) FROM non_verified_guide_statuses
    )
      AND (customer_segment = 'guide'
        OR 'verified_guide' = ANY(customer_segment_reason_codes)
        OR 'segment_guide' = ANY(priority_reason_codes))
)
UPDATE support_tickets AS ticket
SET
    customer_segment = repaired.repaired_segment,
    customer_segment_reason_codes = CASE
        WHEN cardinality(repaired.repaired_segment_reason_codes) = 0 THEN ARRAY['standard']::TEXT[]
        ELSE repaired.repaired_segment_reason_codes
    END,
    priority_reason_codes = repaired.repaired_priority_reason_codes,
    priority = CASE
        WHEN ticket.priority = 'high' AND cardinality(repaired.repaired_priority_reason_codes) = 0 THEN 'normal'
        ELSE ticket.priority
    END,
    updated_at = now()
FROM repaired_tickets AS repaired
WHERE ticket.id = repaired.id;
