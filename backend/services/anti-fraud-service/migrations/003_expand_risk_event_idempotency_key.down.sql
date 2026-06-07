ALTER TABLE risk_events
    ALTER COLUMN idempotency_key TYPE varchar(160)
    USING left(idempotency_key, 160);
