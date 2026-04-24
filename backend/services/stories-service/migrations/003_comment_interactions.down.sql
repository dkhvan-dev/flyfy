DROP INDEX IF EXISTS idx_story_comments_author_story_created;

DROP INDEX IF EXISTS idx_story_comment_likes_user_comment;

DROP TABLE IF EXISTS story_comment_likes;

ALTER TABLE story_comments
    DROP COLUMN IF EXISTS like_count;
