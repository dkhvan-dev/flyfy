CREATE TABLE IF NOT EXISTS stories (
    id UUID PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    author_user_id UUID NOT NULL,
    title TEXT NOT NULL,
    excerpt TEXT NOT NULL,
    content TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL,
    status TEXT NOT NULL,
    cover_file_id UUID NULL,
    place_name TEXT NULL,
    place_country_code TEXT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}',
    search_vector TSVECTOR NULL,
    view_count INTEGER NOT NULL DEFAULT 0,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    share_count INTEGER NOT NULL DEFAULT 0,
    published_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL,
    CONSTRAINT chk_stories_category CHECK (category IN ('JOURNAL', 'GUIDE', 'PHOTO_ESSAY', 'CULINARY')),
    CONSTRAINT chk_stories_status CHECK (status IN ('DRAFT', 'PUBLISHED'))
);

CREATE TABLE IF NOT EXISTS story_view_sketches (
    story_id UUID PRIMARY KEY REFERENCES stories(id) ON DELETE CASCADE,
    registers BYTEA NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS story_likes (
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (story_id, user_id)
);

CREATE TABLE IF NOT EXISTS story_comments (
    id UUID PRIMARY KEY,
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    author_user_id UUID NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_stories_author_status
    ON stories(author_user_id, status, updated_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_stories_category_published
    ON stories(category, published_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_stories_published_latest
    ON stories(status, published_at DESC, created_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_stories_popular
    ON stories(status, view_count DESC, published_at DESC)
    WHERE deleted_at IS NULL;

CREATE OR REPLACE FUNCTION stories_search_vector_refresh() RETURNS trigger AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('simple', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(NEW.excerpt, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(NEW.content, '')), 'C') ||
        setweight(to_tsvector('simple', coalesce(NEW.place_name, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(array_to_string(NEW.tags, ' '), '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_stories_search_vector_refresh ON stories;

CREATE TRIGGER trg_stories_search_vector_refresh
    BEFORE INSERT OR UPDATE OF title, excerpt, content, place_name, tags
    ON stories
    FOR EACH ROW
    EXECUTE FUNCTION stories_search_vector_refresh();

CREATE INDEX IF NOT EXISTS idx_stories_search_vector
    ON stories USING GIN(search_vector);

CREATE INDEX IF NOT EXISTS idx_stories_tags
    ON stories USING GIN(tags);

CREATE INDEX IF NOT EXISTS idx_story_comments_story_created
    ON story_comments(story_id, created_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_story_likes_user_story
    ON story_likes(user_id, story_id);
