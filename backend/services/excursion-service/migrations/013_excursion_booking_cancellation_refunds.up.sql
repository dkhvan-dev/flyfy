ALTER TABLE excursion_bookings
    ADD COLUMN cancelled_by VARCHAR(20) NULL,
    ADD COLUMN refund_percent INT NOT NULL DEFAULT 0,
    ADD COLUMN refund_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN refund_currency VARCHAR(10) NULL,
    ADD COLUMN refund_policy_code VARCHAR(60) NULL,
    ADD COLUMN refund_status VARCHAR(40) NULL;

ALTER TABLE excursion_bookings
    DROP CONSTRAINT IF EXISTS chk_excursion_bookings_price;

ALTER TABLE excursion_bookings
    ADD CONSTRAINT chk_excursion_bookings_price
        CHECK (
            unit_price_amount >= 0
            AND service_fee_amount >= 0
            AND total_price_amount >= 0
            AND refund_percent >= 0
            AND refund_percent <= 100
            AND refund_amount >= 0
        );

ALTER TABLE excursion_bookings
    ADD CONSTRAINT chk_excursion_bookings_cancelled_by
        CHECK (cancelled_by IS NULL OR cancelled_by IN ('TOURIST', 'GUIDE', 'SYSTEM'));

ALTER TABLE excursion_bookings
    ADD CONSTRAINT chk_excursion_bookings_refund_status
        CHECK (refund_status IS NULL OR refund_status IN ('PENDING_PAYMENT_INTEGRATION', 'NOT_REFUNDABLE'));
