CREATE TABLE IF NOT EXISTS search_query_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    search_session_id TEXT,
    query_hash TEXT,
    query_length INT NOT NULL DEFAULT 0,
    user_id_hash TEXT,
    anonymous_id_hash TEXT,
    scope TEXT,
    domain TEXT,
    entity_id TEXT,
    result_position INT,
    locale TEXT NOT NULL DEFAULT 'en',
    request_id TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT search_query_events_type_check CHECK (
        event_type IN (
            'search_started',
            'suggestion_clicked',
            'search_submitted',
            'result_clicked',
            'filter_changed',
            'zero_results',
            'search_failed'
        )
    ),
    CONSTRAINT search_query_events_scope_check CHECK (
        scope IS NULL OR scope IN ('global', 'activity', 'excursion', 'place', 'guide', 'community', 'user')
    ),
    CONSTRAINT search_query_events_domain_check CHECK (
        domain IS NULL OR domain IN ('activity', 'excursion', 'place', 'guide', 'community', 'user')
    ),
    CONSTRAINT search_query_events_position_check CHECK (
        result_position IS NULL OR result_position >= 0
    ),
    CONSTRAINT search_query_events_query_length_check CHECK (
        query_length >= 0
    )
);

CREATE INDEX IF NOT EXISTS idx_search_query_events_type_created
    ON search_query_events (event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_search_query_events_session
    ON search_query_events (search_session_id, created_at DESC)
    WHERE search_session_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_search_query_events_domain_created
    ON search_query_events (domain, created_at DESC)
    WHERE domain IS NOT NULL;
