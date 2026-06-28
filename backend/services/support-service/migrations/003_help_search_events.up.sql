CREATE TABLE help_search_events (
    id BIGSERIAL PRIMARY KEY,
    query TEXT NOT NULL CHECK (length(query) BETWEEN 1 AND 300),
    locale TEXT NOT NULL CHECK (locale IN ('en', 'ru', 'kk')),
    surface TEXT NOT NULL CHECK (
        surface IN (
            'help_center',
            'places',
            'activity_details',
            'excursion_details',
            'place_details',
            'currency_converter'
        )
    ),
    result_count INTEGER NOT NULL CHECK (result_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_help_search_events_created
    ON help_search_events(created_at DESC);
CREATE INDEX idx_help_search_events_no_results_created
    ON help_search_events(created_at DESC)
    WHERE result_count = 0;
CREATE INDEX idx_help_search_events_query_created
    ON help_search_events(query, created_at DESC);
