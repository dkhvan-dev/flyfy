CREATE TABLE IF NOT EXISTS conversation_pins (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id   UUID        NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    message_id        UUID        NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
    pinned_by_user_id UUID        NOT NULL,
    pinned_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_conversation_pins_message
    ON conversation_pins (conversation_id, message_id);

CREATE INDEX IF NOT EXISTS idx_conversation_pins_order
    ON conversation_pins (conversation_id, pinned_at DESC, id DESC);

INSERT INTO conversation_pins (id, conversation_id, message_id, pinned_by_user_id, pinned_at)
SELECT
    gen_random_uuid(),
    c.id,
    c.pinned_message_id,
    CASE
        WHEN m.sender_user_id = '00000000-0000-0000-0000-000000000000'
            THEN COALESCE(cp.user_id, '00000000-0000-0000-0000-000000000000'::uuid)
        ELSE m.sender_user_id
    END,
    COALESCE(m.sent_at, c.last_activity_at, c.created_at)
FROM conversations c
JOIN messages m
  ON m.id = c.pinned_message_id
LEFT JOIN LATERAL (
    SELECT p.user_id
    FROM conversation_participants p
    WHERE p.conversation_id = c.id
      AND p.left_at IS NULL
    ORDER BY CASE WHEN p.role = 'admin' THEN 0 ELSE 1 END, p.joined_at, p.id
    LIMIT 1
) cp ON true
WHERE c.pinned_message_id IS NOT NULL
ON CONFLICT (conversation_id, message_id) DO NOTHING;
