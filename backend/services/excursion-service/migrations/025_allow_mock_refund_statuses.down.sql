ALTER TABLE excursion_bookings
    DROP CONSTRAINT IF EXISTS chk_excursion_bookings_refund_status;

ALTER TABLE excursion_bookings
    ADD CONSTRAINT chk_excursion_bookings_refund_status
        CHECK (refund_status IS NULL OR refund_status IN ('PENDING_PAYMENT_INTEGRATION', 'NOT_REFUNDABLE'));
