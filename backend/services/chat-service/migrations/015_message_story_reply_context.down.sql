DROP INDEX IF EXISTS idx_messages_story_reply_story_id;

ALTER TABLE messages
    DROP COLUMN IF EXISTS story_reply;
