CREATE TABLE IF NOT EXISTS user_social_outbox (
    id uuid PRIMARY KEY,
    event_type text NOT NULL,
    viewer_user_id uuid NOT NULL,
    target_user_id uuid NOT NULL,
    edge_type text NOT NULL,
    active boolean NOT NULL,
    source_key text NOT NULL,
    source_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    last_error text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    delivered_at timestamp with time zone,
    CONSTRAINT user_social_outbox_edge_type_check CHECK ((edge_type = ANY (ARRAY['friend'::text, 'following'::text]))),
    CONSTRAINT user_social_outbox_event_type_check CHECK ((event_type = ANY (ARRAY[
        'user.follow.created'::text,
        'user.follow.deleted'::text,
        'user.friendship.created'::text,
        'user.friendship.deleted'::text
    ]))),
    CONSTRAINT user_social_outbox_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'DELIVERED'::text, 'DEAD'::text]))),
    CONSTRAINT user_social_outbox_self_check CHECK ((viewer_user_id <> target_user_id)),
    CONSTRAINT user_social_outbox_attempt_count_check CHECK ((attempt_count >= 0)),
    CONSTRAINT user_social_outbox_source_key_key UNIQUE (source_key)
);

CREATE INDEX IF NOT EXISTS idx_user_social_outbox_due
    ON user_social_outbox (next_attempt_at, created_at, id)
    WHERE status = 'PENDING';

CREATE INDEX IF NOT EXISTS idx_user_social_outbox_viewer_target
    ON user_social_outbox (viewer_user_id, target_user_id, edge_type, created_at DESC);
