CREATE INDEX IF NOT EXISTS idx_user_friendships_addressee_pending_requested_at
    ON user_friendships(addressee_user_id, requested_at DESC)
    WHERE status = 'PENDING';
