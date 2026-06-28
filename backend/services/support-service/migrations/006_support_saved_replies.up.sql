CREATE TABLE support_saved_replies (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'published'
        CHECK (status IN ('draft', 'review', 'published', 'archived')),
    tags TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    translations JSONB NOT NULL DEFAULT '{}'::JSONB,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_saved_replies_status_category
    ON support_saved_replies(status, category, sort_order, id);
