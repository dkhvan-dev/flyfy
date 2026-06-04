CREATE TABLE IF NOT EXISTS chat_user_blocks (
    blocker_user_id UUID        NOT NULL,
    blocked_user_id UUID        NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (blocker_user_id, blocked_user_id),
    CONSTRAINT chk_chat_user_blocks_not_self CHECK (blocker_user_id <> blocked_user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_user_blocks_blocked_user_id
    ON chat_user_blocks (blocked_user_id, blocker_user_id);
