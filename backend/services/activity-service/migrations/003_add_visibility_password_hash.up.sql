ALTER TABLE activities
ADD COLUMN IF NOT EXISTS visibility_password_hash VARCHAR(255) NULL;
