UPDATE notification_deliveries
SET next_attempt_at = NOW()
WHERE next_attempt_at IS NULL;

ALTER TABLE notification_deliveries
  ALTER COLUMN next_attempt_at SET NOT NULL;
