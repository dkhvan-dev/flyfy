ALTER TABLE excursion_bookings
    DROP CONSTRAINT IF EXISTS chk_excursion_bookings_refund_status;

ALTER TABLE excursion_bookings
    DROP CONSTRAINT IF EXISTS chk_excursion_bookings_cancelled_by;

ALTER TABLE excursion_bookings
    DROP CONSTRAINT IF EXISTS chk_excursion_bookings_price;

ALTER TABLE excursion_bookings
    ADD CONSTRAINT chk_excursion_bookings_price
        CHECK (unit_price_amount >= 0 AND service_fee_amount >= 0 AND total_price_amount >= 0);

ALTER TABLE excursion_bookings
    DROP COLUMN IF EXISTS refund_status,
    DROP COLUMN IF EXISTS refund_policy_code,
    DROP COLUMN IF EXISTS refund_currency,
    DROP COLUMN IF EXISTS refund_amount,
    DROP COLUMN IF EXISTS refund_percent,
    DROP COLUMN IF EXISTS cancelled_by;
