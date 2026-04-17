CREATE TABLE IF NOT EXISTS user_follows (
    follower_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followed_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_user_id, followed_user_id),
    CONSTRAINT chk_user_follows_no_self_follow CHECK (follower_user_id <> followed_user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_follows_followed_user_id
    ON user_follows(followed_user_id, created_at DESC);
