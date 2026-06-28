DROP INDEX IF EXISTS idx_support_agents_status;
DROP INDEX IF EXISTS idx_support_user_segments_segment;
DROP INDEX IF EXISTS idx_support_tickets_assignment_status;
DROP INDEX IF EXISTS idx_support_tickets_customer_segment;

DROP TABLE IF EXISTS support_agents;
DROP TABLE IF EXISTS support_user_segments;

ALTER TABLE support_tickets
    DROP COLUMN IF EXISTS assigned_at,
    DROP COLUMN IF EXISTS assignment_reason_codes,
    DROP COLUMN IF EXISTS assignment_reason,
    DROP COLUMN IF EXISTS assignment_status,
    DROP COLUMN IF EXISTS subscription_tier_snapshot,
    DROP COLUMN IF EXISTS guide_status_snapshot,
    DROP COLUMN IF EXISTS followers_count_snapshot,
    DROP COLUMN IF EXISTS user_nickname_snapshot,
    DROP COLUMN IF EXISTS segment_refresh_status,
    DROP COLUMN IF EXISTS customer_segment_reason_codes,
    DROP COLUMN IF EXISTS customer_segment,
    DROP COLUMN IF EXISTS priority_reason_codes;
