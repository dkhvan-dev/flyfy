CREATE TABLE IF NOT EXISTS post_publish_cooldowns (
    author_user_id UUID PRIMARY KEY,
    last_post_id UUID NOT NULL,
    last_published_at TIMESTAMPTZ NOT NULL,
    next_available_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_post_publish_cooldowns_window
        CHECK (next_available_at >= last_published_at)
);

INSERT INTO post_publish_cooldowns (
    author_user_id,
    last_post_id,
    last_published_at,
    next_available_at,
    updated_at
)
SELECT DISTINCT ON (author_user_id)
    author_user_id,
    id,
    published_at,
    published_at + INTERVAL '5 minutes',
    NOW()
FROM posts
WHERE published_at IS NOT NULL
  AND published_at > NOW() - INTERVAL '5 minutes'
ORDER BY author_user_id, published_at DESC, id DESC
ON CONFLICT (author_user_id) DO NOTHING;
