CREATE TABLE IF NOT EXISTS place_visit_info (
    place_id                     UUID PRIMARY KEY REFERENCES places(id) ON DELETE CASCADE,
    best_season_months           SMALLINT[] NOT NULL DEFAULT '{}',
    opening_hours                JSONB NOT NULL DEFAULT '{}'::jsonb,
    time_on_site_min_minutes     INT NULL,
    time_on_site_max_minutes     INT NULL,
    car_travel_time_min_minutes  INT NULL,
    car_travel_time_max_minutes  INT NULL,
    car_route_hint               JSONB NOT NULL DEFAULT '{}'::jsonb,
    road_condition               VARCHAR(32) NOT NULL DEFAULT '',
    price_note                   JSONB NOT NULL DEFAULT '{}'::jsonb,
    planning_note                JSONB NOT NULL DEFAULT '{}'::jsonb,
    last_verified_at             DATE NULL,
    created_at                   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_place_visit_info_time_on_site CHECK (
        time_on_site_min_minutes IS NULL OR time_on_site_min_minutes >= 0
    ),
    CONSTRAINT chk_place_visit_info_time_on_site_range CHECK (
        time_on_site_min_minutes IS NULL OR
        time_on_site_max_minutes IS NULL OR
        time_on_site_max_minutes >= time_on_site_min_minutes
    ),
    CONSTRAINT chk_place_visit_info_car_time CHECK (
        car_travel_time_min_minutes IS NULL OR car_travel_time_min_minutes >= 0
    ),
    CONSTRAINT chk_place_visit_info_car_time_range CHECK (
        car_travel_time_min_minutes IS NULL OR
        car_travel_time_max_minutes IS NULL OR
        car_travel_time_max_minutes >= car_travel_time_min_minutes
    )
);

CREATE TABLE IF NOT EXISTS place_fee_items (
    place_id       UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    fee_type       VARCHAR(32) NOT NULL,
    title          JSONB NOT NULL DEFAULT '{}'::jsonb,
    description    JSONB NOT NULL DEFAULT '{}'::jsonb,
    amount_min     NUMERIC(12, 2) NULL,
    amount_max     NUMERIC(12, 2) NULL,
    currency       VARCHAR(3) NOT NULL DEFAULT '',
    unit           VARCHAR(32) NOT NULL DEFAULT '',
    is_required    BOOLEAN NOT NULL DEFAULT FALSE,
    is_approximate BOOLEAN NOT NULL DEFAULT FALSE,
    note           JSONB NOT NULL DEFAULT '{}'::jsonb,
    sort_order     INT NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (place_id, fee_type, sort_order),
    CONSTRAINT chk_place_fee_items_fee_type CHECK (fee_type IN (
        'entrance', 'transport', 'parking', 'eco_fee', 'permit', 'guide', 'other'
    )),
    CONSTRAINT chk_place_fee_items_amount_min CHECK (amount_min IS NULL OR amount_min >= 0),
    CONSTRAINT chk_place_fee_items_amount_max CHECK (amount_max IS NULL OR amount_max >= 0),
    CONSTRAINT chk_place_fee_items_amount_range CHECK (
        amount_min IS NULL OR amount_max IS NULL OR amount_max >= amount_min
    ),
    CONSTRAINT chk_place_fee_items_currency CHECK (
        currency = '' OR currency ~ '^[A-Z]{3}$'
    )
);

CREATE TABLE IF NOT EXISTS place_access_options (
    place_id              UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    transport_type        VARCHAR(32) NOT NULL,
    duration_min_minutes  INT NULL,
    duration_max_minutes  INT NULL,
    distance_km           NUMERIC(8, 2) NULL,
    route_hint            JSONB NOT NULL DEFAULT '{}'::jsonb,
    road_condition        VARCHAR(32) NOT NULL DEFAULT '',
    requires_4x4          BOOLEAN NOT NULL DEFAULT FALSE,
    parking_note          JSONB NOT NULL DEFAULT '{}'::jsonb,
    last_segment_note     JSONB NOT NULL DEFAULT '{}'::jsonb,
    note                  JSONB NOT NULL DEFAULT '{}'::jsonb,
    sort_order            INT NOT NULL DEFAULT 0,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (place_id, transport_type, sort_order),
    CONSTRAINT chk_place_access_options_duration_min CHECK (
        duration_min_minutes IS NULL OR duration_min_minutes >= 0
    ),
    CONSTRAINT chk_place_access_options_duration_max CHECK (
        duration_max_minutes IS NULL OR duration_max_minutes >= 0
    ),
    CONSTRAINT chk_place_access_options_duration_range CHECK (
        duration_min_minutes IS NULL OR
        duration_max_minutes IS NULL OR
        duration_max_minutes >= duration_min_minutes
    ),
    CONSTRAINT chk_place_access_options_distance CHECK (
        distance_km IS NULL OR distance_km >= 0
    )
);

CREATE TABLE IF NOT EXISTS place_practical_notes (
    place_id    UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    note_type   VARCHAR(32) NOT NULL,
    title       JSONB NOT NULL DEFAULT '{}'::jsonb,
    body        JSONB NOT NULL DEFAULT '{}'::jsonb,
    priority    VARCHAR(16) NOT NULL DEFAULT '',
    sort_order  INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (place_id, note_type, sort_order)
);

CREATE TABLE IF NOT EXISTS place_recommended_items (
    place_id    UUID NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    item_type   VARCHAR(32) NOT NULL,
    title       JSONB NOT NULL DEFAULT '{}'::jsonb,
    importance  VARCHAR(16) NOT NULL DEFAULT 'recommended',
    season      VARCHAR(32) NOT NULL DEFAULT '',
    note        JSONB NOT NULL DEFAULT '{}'::jsonb,
    sort_order  INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (place_id, item_type, sort_order),
    CONSTRAINT chk_place_recommended_items_importance CHECK (
        importance IN ('required', 'recommended')
    )
);

CREATE INDEX IF NOT EXISTS idx_place_fee_items_place_sort
    ON place_fee_items (place_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_place_access_options_place_sort
    ON place_access_options (place_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_place_practical_notes_place_sort
    ON place_practical_notes (place_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_place_recommended_items_place_sort
    ON place_recommended_items (place_id, sort_order);
