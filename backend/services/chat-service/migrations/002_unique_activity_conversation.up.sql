CREATE UNIQUE INDEX IF NOT EXISTS uq_conversations_activity_id
    ON conversations (activity_id)
    WHERE activity_id IS NOT NULL;
