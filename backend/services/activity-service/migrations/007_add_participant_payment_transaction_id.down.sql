DROP INDEX IF EXISTS idx_activity_participants_payment_transaction_id;

ALTER TABLE activity_participants
    DROP COLUMN IF EXISTS payment_transaction_id;
