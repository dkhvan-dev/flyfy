CREATE TABLE IF NOT EXISTS user_routes (
    id TEXT PRIMARY KEY,
    owner_user_id TEXT NOT NULL,
    source_route_id TEXT REFERENCES user_routes(id) ON DELETE SET NULL,
    title TEXT NOT NULL CHECK (char_length(btrim(title)) >= 3 AND char_length(title) <= 120),
    description TEXT NOT NULL DEFAULT '',
    visibility TEXT NOT NULL CHECK (visibility IN ('private', 'unlisted', 'public')),
    profile TEXT NOT NULL,
    city_code TEXT NOT NULL DEFAULT '',
    tags TEXT[] NOT NULL DEFAULT '{}',
    points JSONB NOT NULL,
    snapshot JSONB NOT NULL,
    copies_count INTEGER NOT NULL DEFAULT 0 CHECK (copies_count >= 0),
    views_count INTEGER NOT NULL DEFAULT 0 CHECK (views_count >= 0),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS user_route_saves (
    user_id TEXT NOT NULL,
    route_id TEXT NOT NULL REFERENCES user_routes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (user_id, route_id)
);

CREATE INDEX IF NOT EXISTS idx_user_routes_owner_updated
    ON user_routes (owner_user_id, updated_at DESC, id);

CREATE INDEX IF NOT EXISTS idx_user_routes_public_city_updated
    ON user_routes (city_code, updated_at DESC, id)
    WHERE visibility = 'public';

CREATE INDEX IF NOT EXISTS idx_user_routes_source_route
    ON user_routes (source_route_id)
    WHERE source_route_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_route_saves_user_created
    ON user_route_saves (user_id, created_at DESC, route_id);

CREATE INDEX IF NOT EXISTS idx_user_route_saves_route
    ON user_route_saves (route_id);
