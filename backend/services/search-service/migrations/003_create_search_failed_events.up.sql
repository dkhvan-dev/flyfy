CREATE TABLE IF NOT EXISTS search_failed_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_event_id UUID NOT NULL REFERENCES search_document_events(id) ON DELETE CASCADE,
    source_service TEXT NOT NULL,
    source_event_id TEXT NOT NULL,
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    attempt_count INT NOT NULL,
    last_error TEXT,
    failed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_search_failed_events_document_event
    ON search_failed_events (document_event_id);

CREATE INDEX IF NOT EXISTS idx_search_failed_events_failed_at
    ON search_failed_events (failed_at DESC);

CREATE INDEX IF NOT EXISTS idx_search_failed_events_source
    ON search_failed_events (source_service, source_event_id);
