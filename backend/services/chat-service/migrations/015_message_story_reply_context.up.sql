ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS story_reply JSONB;

CREATE INDEX IF NOT EXISTS idx_messages_story_reply_story_id
    ON messages ((story_reply ->> 'storyId'))
    WHERE story_reply IS NOT NULL;
