CREATE TABLE IF NOT EXISTS user_friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'PENDING',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_user_friendships_no_self CHECK (requester_user_id <> addressee_user_id),
    CONSTRAINT chk_user_friendships_status CHECK (status IN ('PENDING', 'ACCEPTED'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_user_friendships_pair
    ON user_friendships (
        LEAST(requester_user_id, addressee_user_id),
        GREATEST(requester_user_id, addressee_user_id)
    );

CREATE INDEX IF NOT EXISTS idx_user_friendships_requester_status
    ON user_friendships(requester_user_id, status, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_friendships_addressee_status
    ON user_friendships(addressee_user_id, status, updated_at DESC);
