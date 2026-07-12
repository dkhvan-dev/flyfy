CREATE TABLE IF NOT EXISTS post_feed_user_community_affinities (
    viewer_user_id uuid NOT NULL,
    community_id uuid NOT NULL,
    meaningful_visit_count integer DEFAULT 0 NOT NULL,
    distinct_visit_day_count integer DEFAULT 0 NOT NULL,
    first_visit_at timestamp with time zone NOT NULL,
    last_visit_at timestamp with time zone NOT NULL,
    last_visit_day date NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT post_feed_user_community_affinities_pkey
        PRIMARY KEY (viewer_user_id, community_id),
    CONSTRAINT post_feed_user_community_affinities_community_id_fkey
        FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE,
    CONSTRAINT post_feed_user_community_affinities_visit_count_check
        CHECK (meaningful_visit_count >= 0),
    CONSTRAINT post_feed_user_community_affinities_visit_day_count_check
        CHECK (distinct_visit_day_count >= 0),
    CONSTRAINT post_feed_user_community_affinities_visit_order_check
        CHECK (first_visit_at <= last_visit_at)
);

CREATE INDEX IF NOT EXISTS idx_post_feed_user_community_affinities_recent
    ON post_feed_user_community_affinities (viewer_user_id, last_visit_at DESC);

ALTER TABLE post_feed_events
    DROP CONSTRAINT IF EXISTS post_feed_events_block_type_check;

ALTER TABLE post_feed_events
    ADD CONSTRAINT post_feed_events_block_type_check
    CHECK ((block_type = ANY (ARRAY[
        'stories_tray'::text,
        'suggested_communities'::text,
        'my_subscriptions'::text,
        'community_card'::text,
        'post_card'::text,
        'activity_card'::text,
        'place_card'::text,
        'attraction_card'::text,
        'tour_card'::text,
        'guide_card'::text,
        'profile_card'::text,
        'official_news_card'::text
    ]))) NOT VALID;

ALTER TABLE post_feed_events
    VALIDATE CONSTRAINT post_feed_events_block_type_check;
