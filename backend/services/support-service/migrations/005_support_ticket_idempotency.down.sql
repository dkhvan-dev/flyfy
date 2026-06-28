DROP INDEX IF EXISTS idx_support_tickets_user_idempotency_key;

ALTER TABLE support_tickets
    DROP CONSTRAINT IF EXISTS support_tickets_idempotency_key_length,
    DROP COLUMN IF EXISTS idempotency_key;
