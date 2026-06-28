ALTER TABLE support_tickets
    ADD COLUMN IF NOT EXISTS priority_reason_codes TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    ADD COLUMN IF NOT EXISTS customer_segment TEXT NOT NULL DEFAULT 'standard'
        CHECK (customer_segment IN ('standard', 'guide', 'creator', 'vip', 'partner')),
    ADD COLUMN IF NOT EXISTS customer_segment_reason_codes TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    ADD COLUMN IF NOT EXISTS segment_refresh_status TEXT NOT NULL DEFAULT 'stale'
        CHECK (segment_refresh_status IN ('fresh', 'stale')),
    ADD COLUMN IF NOT EXISTS user_nickname_snapshot TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS followers_count_snapshot INTEGER NOT NULL DEFAULT 0 CHECK (followers_count_snapshot >= 0),
    ADD COLUMN IF NOT EXISTS guide_status_snapshot TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS subscription_tier_snapshot TEXT,
    ADD COLUMN IF NOT EXISTS assignment_status TEXT NOT NULL DEFAULT 'needs_assignment'
        CHECK (assignment_status IN ('needs_assignment', 'assigned', 'manual')),
    ADD COLUMN IF NOT EXISTS assignment_reason TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS assignment_reason_codes TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ;

CREATE TABLE support_user_segments (
    user_id TEXT PRIMARY KEY,
    nickname TEXT NOT NULL DEFAULT '',
    customer_segment TEXT NOT NULL DEFAULT 'standard'
        CHECK (customer_segment IN ('standard', 'guide', 'creator', 'vip', 'partner')),
    followers_count INTEGER NOT NULL DEFAULT 0 CHECK (followers_count >= 0),
    is_guide BOOLEAN NOT NULL DEFAULT false,
    guide_status TEXT NOT NULL DEFAULT '',
    is_public_figure BOOLEAN NOT NULL DEFAULT false,
    is_partner BOOLEAN NOT NULL DEFAULT false,
    manual_segment TEXT NOT NULL DEFAULT ''
        CHECK (manual_segment IN ('', 'standard', 'guide', 'creator', 'vip', 'partner')),
    manual_reason TEXT NOT NULL DEFAULT '' CHECK (length(manual_reason) <= 300),
    subscription_tier TEXT,
    reason_codes TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    refresh_status TEXT NOT NULL DEFAULT 'fresh'
        CHECK (refresh_status IN ('fresh', 'stale')),
    source_version TEXT NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE support_agents (
    staff_id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'paused', 'offline', 'on_leave')),
    languages TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    skills TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    level TEXT NOT NULL DEFAULT 'agent'
        CHECK (level IN ('agent', 'senior', 'lead')),
    max_active_load NUMERIC(8, 2) NOT NULL DEFAULT 8 CHECK (max_active_load >= 0),
    timezone TEXT NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_tickets_customer_segment
    ON support_tickets(customer_segment, priority, updated_at DESC);
CREATE INDEX idx_support_tickets_assignment_status
    ON support_tickets(assignment_status, priority, updated_at DESC);
CREATE INDEX idx_support_user_segments_segment
    ON support_user_segments(customer_segment, updated_at DESC);
CREATE INDEX idx_support_agents_status
    ON support_agents(status, level, updated_at DESC);
