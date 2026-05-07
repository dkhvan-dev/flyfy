ALTER TABLE activity_participants
    ADD COLUMN IF NOT EXISTS payment_transaction_id UUID NULL;

CREATE INDEX IF NOT EXISTS idx_activity_participants_payment_transaction_id
    ON activity_participants(payment_transaction_id)
    WHERE payment_transaction_id IS NOT NULL;
