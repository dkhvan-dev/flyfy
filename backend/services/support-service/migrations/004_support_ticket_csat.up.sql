CREATE TABLE support_ticket_csat (
    ticket_id TEXT PRIMARY KEY REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT NOT NULL DEFAULT '' CHECK (length(comment) <= 1200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_ticket_csat_created
    ON support_ticket_csat(created_at DESC);
CREATE INDEX idx_support_ticket_csat_user_created
    ON support_ticket_csat(user_id, created_at DESC);
