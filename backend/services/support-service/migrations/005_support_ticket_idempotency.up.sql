ALTER TABLE support_tickets
    ADD COLUMN IF NOT EXISTS idempotency_key TEXT NOT NULL DEFAULT '';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'support_tickets_idempotency_key_length'
    ) THEN
        ALTER TABLE support_tickets
            ADD CONSTRAINT support_tickets_idempotency_key_length
                CHECK (length(idempotency_key) <= 180);
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_support_tickets_user_idempotency_key
    ON support_tickets(user_id, idempotency_key)
    WHERE idempotency_key <> '';
