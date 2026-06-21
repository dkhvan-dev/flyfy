CREATE TABLE personal_checklist_templates (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    note TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT 'custom',
    priority TEXT NOT NULL DEFAULT 'recommended',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT personal_checklist_templates_id_not_blank CHECK (length(trim(id)) > 0),
    CONSTRAINT personal_checklist_templates_user_id_not_blank CHECK (length(trim(user_id)) > 0),
    CONSTRAINT personal_checklist_templates_title_length_check CHECK (
        length(trim(title)) BETWEEN 1 AND 120
    ),
    CONSTRAINT personal_checklist_templates_note_length_check CHECK (length(note) <= 500),
    CONSTRAINT personal_checklist_templates_category_check CHECK (
        category IN ('documents', 'baggage', 'weather', 'activity', 'health', 'safety', 'money', 'custom')
    ),
    CONSTRAINT personal_checklist_templates_priority_check CHECK (
        priority IN ('critical', 'essential', 'important', 'recommended', 'optional')
    )
);

CREATE TABLE custom_checklist_items (
    id TEXT PRIMARY KEY,
    checklist_instance_id TEXT NOT NULL REFERENCES checklist_instances(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    trip_id TEXT NOT NULL,
    title TEXT NOT NULL,
    note TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT 'custom',
    priority TEXT NOT NULL DEFAULT 'recommended',
    status TEXT NOT NULL DEFAULT 'open',
    assigned_user_id TEXT,
    reuse_in_future BOOLEAN NOT NULL DEFAULT false,
    personal_template_id TEXT REFERENCES personal_checklist_templates(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT custom_checklist_items_id_not_blank CHECK (length(trim(id)) > 0),
    CONSTRAINT custom_checklist_items_user_id_not_blank CHECK (length(trim(user_id)) > 0),
    CONSTRAINT custom_checklist_items_trip_id_not_blank CHECK (length(trim(trip_id)) > 0),
    CONSTRAINT custom_checklist_items_title_length_check CHECK (
        length(trim(title)) BETWEEN 1 AND 120
    ),
    CONSTRAINT custom_checklist_items_note_length_check CHECK (length(note) <= 500),
    CONSTRAINT custom_checklist_items_assignee_not_blank CHECK (
        assigned_user_id IS NULL OR length(trim(assigned_user_id)) > 0
    ),
    CONSTRAINT custom_checklist_items_category_check CHECK (
        category IN ('documents', 'baggage', 'weather', 'activity', 'health', 'safety', 'money', 'custom')
    ),
    CONSTRAINT custom_checklist_items_priority_check CHECK (
        priority IN ('critical', 'essential', 'important', 'recommended', 'optional')
    ),
    CONSTRAINT custom_checklist_items_status_check CHECK (
        status IN ('open', 'done', 'skipped')
    )
);

CREATE INDEX custom_checklist_items_user_trip_active
    ON custom_checklist_items (user_id, trip_id, updated_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX custom_checklist_items_instance_active
    ON custom_checklist_items (checklist_instance_id, status, priority)
    WHERE deleted_at IS NULL;

CREATE INDEX personal_checklist_templates_user_active
    ON personal_checklist_templates (user_id, updated_at DESC)
    WHERE is_active = true;
