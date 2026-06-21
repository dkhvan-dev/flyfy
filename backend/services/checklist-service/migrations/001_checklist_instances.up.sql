CREATE TABLE checklist_instances (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    trip_id TEXT NOT NULL,
    readiness JSONB NOT NULL DEFAULT '{}'::jsonb,
    seasonal_profile JSONB,
    trust_notice JSONB NOT NULL DEFAULT '{}'::jsonb,
    generated_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT checklist_instances_user_trip_unique UNIQUE (user_id, trip_id),
    CONSTRAINT checklist_instances_id_not_blank CHECK (length(trim(id)) > 0),
    CONSTRAINT checklist_instances_user_id_not_blank CHECK (length(trim(user_id)) > 0),
    CONSTRAINT checklist_instances_trip_id_not_blank CHECK (length(trim(trip_id)) > 0)
);

CREATE TABLE checklist_instance_items (
    instance_id TEXT NOT NULL REFERENCES checklist_instances(id) ON DELETE CASCADE,
    item_id TEXT NOT NULL,
    category TEXT NOT NULL,
    priority TEXT NOT NULL,
    status TEXT NOT NULL,
    title JSONB NOT NULL DEFAULT '{}'::jsonb,
    reason JSONB NOT NULL DEFAULT '{}'::jsonb,
    trust_level TEXT NOT NULL,
    source JSONB NOT NULL DEFAULT '{}'::jsonb,
    requires_user_confirmation BOOLEAN NOT NULL DEFAULT false,
    deadline_at TIMESTAMPTZ,
    position INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (instance_id, item_id),
    CONSTRAINT checklist_instance_items_item_id_not_blank CHECK (length(trim(item_id)) > 0),
    CONSTRAINT checklist_instance_items_category_check CHECK (
        category IN ('documents', 'baggage', 'weather', 'activity', 'health', 'safety', 'money', 'custom')
    ),
    CONSTRAINT checklist_instance_items_priority_check CHECK (
        priority IN ('critical', 'essential', 'important', 'recommended', 'optional')
    ),
    CONSTRAINT checklist_instance_items_status_check CHECK (
        status IN ('open', 'done', 'skipped')
    ),
    CONSTRAINT checklist_instance_items_trust_level_check CHECK (
        trust_level IN ('verified_curated', 'official_link_required', 'general_advisory')
    )
);

CREATE INDEX idx_checklist_instances_user_updated
    ON checklist_instances (user_id, updated_at DESC);

CREATE INDEX idx_checklist_instance_items_status
    ON checklist_instance_items (instance_id, status, priority);
