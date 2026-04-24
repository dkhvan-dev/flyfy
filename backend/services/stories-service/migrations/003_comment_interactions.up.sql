ALTER TABLE story_comments
    ADD COLUMN IF NOT EXISTS like_count INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS story_comment_likes (
    comment_id UUID NOT NULL REFERENCES story_comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (comment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_story_comment_likes_user_comment
    ON story_comment_likes(user_id, comment_id);

CREATE INDEX IF NOT EXISTS idx_story_comments_author_story_created
    ON story_comments(author_user_id, story_id, created_at DESC)
    WHERE deleted_at IS NULL;
