CREATE TABLE help_article_events (
    id BIGSERIAL PRIMARY KEY,
    article_id TEXT NOT NULL REFERENCES help_articles(id) ON DELETE CASCADE,
    actor_id TEXT NOT NULL DEFAULT '',
    actor_type TEXT NOT NULL DEFAULT 'support_admin'
        CHECK (actor_type IN ('system', 'user', 'support_agent', 'support_admin')),
    event_type TEXT NOT NULL CHECK (length(event_type) BETWEEN 2 AND 120),
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_help_article_events_article_created
    ON help_article_events(article_id, created_at DESC);
