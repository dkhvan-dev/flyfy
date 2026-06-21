CREATE TABLE checklist_item_feedback (
    id TEXT PRIMARY KEY,
    checklist_instance_id TEXT NOT NULL REFERENCES checklist_instances(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    trip_id TEXT NOT NULL,
    item_id TEXT NOT NULL,
    feedback_type TEXT NOT NULL,
    comment TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT checklist_item_feedback_id_not_blank CHECK (length(trim(id)) > 0),
    CONSTRAINT checklist_item_feedback_instance_id_not_blank CHECK (length(trim(checklist_instance_id)) > 0),
    CONSTRAINT checklist_item_feedback_user_id_not_blank CHECK (length(trim(user_id)) > 0),
    CONSTRAINT checklist_item_feedback_trip_id_not_blank CHECK (length(trim(trip_id)) > 0),
    CONSTRAINT checklist_item_feedback_item_id_not_blank CHECK (length(trim(item_id)) > 0),
    CONSTRAINT checklist_item_feedback_type_check CHECK (
        feedback_type IN ('helpful', 'not_helpful', 'add_next_time')
    ),
    CONSTRAINT checklist_item_feedback_comment_length_check CHECK (length(comment) <= 500)
);

CREATE INDEX idx_checklist_item_feedback_trip_item
    ON checklist_item_feedback (user_id, trip_id, item_id, created_at DESC);

CREATE INDEX idx_checklist_item_feedback_type_created
    ON checklist_item_feedback (feedback_type, created_at DESC);
