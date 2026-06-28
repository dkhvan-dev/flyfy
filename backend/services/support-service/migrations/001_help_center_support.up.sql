CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE help_categories (
    id TEXT PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'published'
        CHECK (status IN ('draft', 'review', 'published', 'archived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE help_articles (
    id TEXT PRIMARY KEY,
    category_id TEXT REFERENCES help_categories(id) ON DELETE SET NULL,
    slug TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'review', 'published', 'archived')),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    owner_id TEXT NOT NULL DEFAULT '',
    reviewer_id TEXT NOT NULL DEFAULT '',
    visibility_rules JSONB NOT NULL DEFAULT '{}'::jsonb,
    published_at TIMESTAMPTZ,
    last_reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE help_article_translations (
    article_id TEXT NOT NULL REFERENCES help_articles(id) ON DELETE CASCADE,
    locale TEXT NOT NULL CHECK (locale IN ('en', 'ru', 'kk')),
    title TEXT NOT NULL CHECK (length(title) BETWEEN 3 AND 180),
    short_answer TEXT NOT NULL CHECK (length(short_answer) BETWEEN 3 AND 600),
    body TEXT NOT NULL CHECK (length(body) BETWEEN 3 AND 12000),
    search_vector TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(short_answer, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(body, '')), 'C')
    ) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (article_id, locale),
    UNIQUE (article_id, locale)
);

CREATE TABLE help_article_surfaces (
    article_id TEXT NOT NULL REFERENCES help_articles(id) ON DELETE CASCADE,
    surface TEXT NOT NULL CHECK (
        surface IN (
            'help_center',
            'places',
            'activity_details',
            'excursion_details',
            'place_details',
            'currency_converter'
        )
    ),
    PRIMARY KEY (article_id, surface)
);

CREATE TABLE help_article_tags (
    article_id TEXT NOT NULL REFERENCES help_articles(id) ON DELETE CASCADE,
    tag TEXT NOT NULL CHECK (length(tag) BETWEEN 2 AND 80),
    PRIMARY KEY (article_id, tag)
);

CREATE TABLE help_article_actions (
    id BIGSERIAL PRIMARY KEY,
    article_id TEXT NOT NULL REFERENCES help_articles(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL CHECK (
        action_type IN ('open_chat', 'contact_support', 'open_route')
    ),
    target TEXT NOT NULL CHECK (length(target) BETWEEN 1 AND 300),
    label_translations JSONB NOT NULL DEFAULT '{}'::jsonb,
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE help_article_related_articles (
    article_id TEXT NOT NULL REFERENCES help_articles(id) ON DELETE CASCADE,
    related_article_id TEXT NOT NULL REFERENCES help_articles(id) ON DELETE CASCADE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (article_id, related_article_id),
    CHECK (article_id <> related_article_id)
);

CREATE TABLE help_article_feedback (
    id BIGSERIAL PRIMARY KEY,
    article_id TEXT NOT NULL REFERENCES help_articles(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    locale TEXT NOT NULL CHECK (locale IN ('en', 'ru', 'kk')),
    helpful BOOLEAN NOT NULL,
    reason TEXT NOT NULL DEFAULT '' CHECK (length(reason) <= 600),
    escalated_to_support BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE support_tickets (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    conversation_id TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL CHECK (
        category IN (
            'account',
            'activities',
            'excursions',
            'places',
            'payments',
            'currency',
            'technical'
        )
    ),
    status TEXT NOT NULL DEFAULT 'new' CHECK (
        status IN (
            'new',
            'open',
            'assigned',
            'waiting_user',
            'waiting_support',
            'resolved',
            'closed',
            'reopened'
        )
    ),
    priority TEXT NOT NULL DEFAULT 'normal'
        CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    source TEXT NOT NULL CHECK (length(source) BETWEEN 1 AND 120),
    locale TEXT NOT NULL CHECK (locale IN ('en', 'ru', 'kk')),
    assignee_id TEXT NOT NULL DEFAULT '',
    context JSONB NOT NULL DEFAULT '{}'::jsonb,
    first_response_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE support_ticket_events (
    id BIGSERIAL PRIMARY KEY,
    ticket_id TEXT NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    actor_id TEXT NOT NULL DEFAULT '',
    actor_type TEXT NOT NULL DEFAULT 'system'
        CHECK (actor_type IN ('system', 'user', 'support_agent', 'support_admin')),
    event_type TEXT NOT NULL CHECK (length(event_type) BETWEEN 2 AND 120),
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_help_articles_status_updated
    ON help_articles(status, updated_at DESC);
CREATE INDEX idx_help_articles_category_status
    ON help_articles(category_id, status, updated_at DESC);
CREATE INDEX idx_help_article_translations_search
    ON help_article_translations USING GIN (search_vector);
CREATE INDEX idx_help_article_translations_title_trgm
    ON help_article_translations USING GIN (lower(title) gin_trgm_ops);
CREATE INDEX idx_help_article_translations_short_answer_trgm
    ON help_article_translations USING GIN (lower(short_answer) gin_trgm_ops);
CREATE INDEX idx_help_article_translations_body_trgm
    ON help_article_translations USING GIN (lower(body) gin_trgm_ops);
CREATE INDEX idx_help_article_surfaces_surface
    ON help_article_surfaces(surface, article_id);
CREATE INDEX idx_help_article_tags_tag
    ON help_article_tags(tag, article_id);
CREATE INDEX idx_help_article_feedback_article_created
    ON help_article_feedback(article_id, created_at DESC);
CREATE INDEX idx_help_article_feedback_user_created
    ON help_article_feedback(user_id, created_at DESC);
CREATE INDEX idx_support_tickets_status_priority
    ON support_tickets(status, priority, updated_at DESC);
CREATE INDEX idx_support_tickets_user_last_message
    ON support_tickets(user_id, last_message_at DESC);
CREATE INDEX idx_support_tickets_assignee_status
    ON support_tickets(assignee_id, status, priority, updated_at DESC);
CREATE INDEX idx_support_tickets_context
    ON support_tickets USING GIN (context);
CREATE INDEX idx_support_ticket_events_ticket_created
    ON support_ticket_events(ticket_id, created_at DESC);
