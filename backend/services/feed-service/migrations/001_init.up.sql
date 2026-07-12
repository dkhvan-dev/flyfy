--
-- PostgreSQL database dump
--


-- Dumped from database version 17.9
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', 'public', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: posts_search_vector_refresh(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION posts_search_vector_refresh() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('simple', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(NEW.excerpt, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(NEW.content, '')), 'C') ||
        setweight(to_tsvector('simple', coalesce(NEW.place_name, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(array_to_string(NEW.tags, ' '), '')), 'C');
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS posts (
    id uuid NOT NULL,
    slug text NOT NULL,
    author_user_id uuid NOT NULL,
    title text NOT NULL,
    excerpt text NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    category text NOT NULL,
    status text NOT NULL,
    cover_file_id uuid,
    place_name text,
    place_country_code text,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    view_count integer DEFAULT 0 NOT NULL,
    like_count integer DEFAULT 0 NOT NULL,
    comment_count integer DEFAULT 0 NOT NULL,
    share_count integer DEFAULT 0 NOT NULL,
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    search_vector tsvector,
    place_city_id text,
    format text DEFAULT 'POST'::text NOT NULL,
    content_schema_version integer DEFAULT 1 NOT NULL,
    content_blocks jsonb,
    content_plain_text text DEFAULT ''::text NOT NULL,
    revision bigint DEFAULT 1 NOT NULL,
    last_autosaved_at timestamp with time zone,
    archived_at timestamp with time zone,
    moderation_status text DEFAULT 'NOT_REQUIRED'::text NOT NULL,
    community_id uuid,
    community_instance_id uuid,
    post_kind text DEFAULT 'ARTICLE'::text NOT NULL,
    post_profile_key text DEFAULT 'article_v1'::text NOT NULL,
    post_profile_version integer DEFAULT 1 NOT NULL,
    structured_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    moderation_mode text DEFAULT 'PREMODERATION'::text NOT NULL,
    source_activity_id uuid,
    activity_creation_status text,
    activity_creation_error text,
    media_status text DEFAULT 'READY'::text NOT NULL,
    expires_at timestamp with time zone,
    CONSTRAINT chk_posts_activity_creation_status CHECK (((activity_creation_status IS NULL) OR (activity_creation_status = ANY (ARRAY['PENDING'::text, 'CREATED'::text, 'FAILED'::text])))),
    CONSTRAINT chk_posts_category CHECK ((category = ANY (ARRAY['JOURNAL'::text, 'GUIDE'::text, 'PHOTO_ESSAY'::text, 'CULINARY'::text]))),
    CONSTRAINT chk_posts_media_status CHECK ((media_status = ANY (ARRAY['READY'::text, 'PENDING_BIND'::text, 'FAILED'::text]))),
    CONSTRAINT chk_posts_moderation_mode CHECK ((moderation_mode = ANY (ARRAY['PREMODERATION'::text, 'PUBLISH_FIRST'::text, 'PUBLISH_FIRST_WITH_RISK_HOLD'::text, 'TRUSTED_PUBLISH_ELSE_REVIEW'::text]))),
    CONSTRAINT chk_posts_post_kind CHECK ((post_kind = ANY (ARRAY['ARTICLE'::text, 'QUICK_POST'::text, 'LISTING'::text, 'EVENT_ANNOUNCEMENT'::text, 'QUESTION_ANSWER'::text, 'TRIP_PLAN'::text]))),
    CONSTRAINT chk_posts_post_profile_version CHECK ((post_profile_version > 0)),
    CONSTRAINT chk_posts_status CHECK ((status = ANY (ARRAY['DRAFT'::text, 'PUBLISHED'::text, 'ARCHIVED'::text])))
);


--
-- Name: post_publish_cooldowns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_publish_cooldowns (
    author_user_id uuid PRIMARY KEY,
    last_post_id uuid NOT NULL,
    last_published_at timestamp with time zone NOT NULL,
    next_available_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_post_publish_cooldowns_window CHECK ((next_available_at >= last_published_at))
);


--
-- Name: story_seen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS story_seen (
    story_id uuid NOT NULL,
    viewer_user_id uuid NOT NULL,
    seen_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: story_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS story_likes (
    story_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: stories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS stories (
    id uuid NOT NULL,
    author_user_id uuid NOT NULL,
    caption text DEFAULT ''::text NOT NULL,
    media_file_id uuid NOT NULL,
    cover_file_id uuid NOT NULL,
    media_type text NOT NULL,
    view_count integer DEFAULT 0 NOT NULL,
    like_count integer DEFAULT 0 NOT NULL,
    reply_count integer DEFAULT 0 NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT chk_stories_expiry CHECK ((expires_at > created_at)),
    CONSTRAINT chk_stories_media_type CHECK ((media_type = ANY (ARRAY['IMAGE'::text, 'VIDEO'::text])))
);


--
-- Name: post_comment_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_comment_likes (
    comment_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: post_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_comments (
    id uuid NOT NULL,
    post_id uuid NOT NULL,
    author_user_id uuid NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    like_count integer DEFAULT 0 NOT NULL
);


--
-- Name: communities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS communities (
    id uuid NOT NULL,
    slug text NOT NULL,
    title text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    topic text DEFAULT 'GENERAL'::text NOT NULL,
    city_id text,
    country_code text,
    language_code text DEFAULT 'ru'::text NOT NULL,
    avatar_file_id uuid,
    cover_file_id uuid,
    visibility text DEFAULT 'PUBLIC'::text NOT NULL,
    posting_policy text DEFAULT 'MEMBERS_AFTER_MODERATION'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    follower_count integer DEFAULT 0 NOT NULL,
    post_count integer DEFAULT 0 NOT NULL,
    created_by_admin_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    rules text[] DEFAULT '{}'::text[] NOT NULL,
    title_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    description_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    rules_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT chk_communities_posting_policy CHECK ((posting_policy = ANY (ARRAY['ADMINS_ONLY'::text, 'MEMBERS_AFTER_MODERATION'::text, 'TRUSTED_MEMBERS'::text, 'OPEN_MEMBERS'::text]))),
    CONSTRAINT chk_communities_status CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'ARCHIVED'::text, 'HIDDEN'::text]))),
    CONSTRAINT chk_communities_visibility CHECK ((visibility = ANY (ARRAY['PUBLIC'::text, 'HIDDEN'::text, 'INVITE_ONLY'::text])))
);


--
-- Name: community_post_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_post_profiles (
    key text NOT NULL PRIMARY KEY,
    version integer DEFAULT 1 NOT NULL,
    post_kind text NOT NULL,
    composer_preset text NOT NULL,
    render_preset text NOT NULL,
    schema_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    validation_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    moderation_mode text NOT NULL,
    activity_creation_mode text DEFAULT 'DISABLED'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_post_profiles_activity_mode CHECK ((activity_creation_mode = ANY (ARRAY['DISABLED'::text, 'OPTIONAL'::text, 'REQUIRED'::text]))),
    CONSTRAINT chk_community_post_profiles_moderation_mode CHECK ((moderation_mode = ANY (ARRAY['PREMODERATION'::text, 'PUBLISH_FIRST'::text, 'PUBLISH_FIRST_WITH_RISK_HOLD'::text, 'TRUSTED_PUBLISH_ELSE_REVIEW'::text]))),
    CONSTRAINT chk_community_post_profiles_post_kind CHECK ((post_kind = ANY (ARRAY['ARTICLE'::text, 'QUICK_POST'::text, 'LISTING'::text, 'EVENT_ANNOUNCEMENT'::text, 'QUESTION_ANSWER'::text, 'TRIP_PLAN'::text]))),
    CONSTRAINT chk_community_post_profiles_version CHECK ((version > 0))
);


--
-- Name: community_blueprints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_blueprints (
    id uuid NOT NULL PRIMARY KEY,
    key text NOT NULL UNIQUE,
    category text NOT NULL,
    default_post_profile_key text NOT NULL REFERENCES community_post_profiles(key),
    allowed_post_profile_keys text[] DEFAULT ARRAY['article_v1']::text[] NOT NULL,
    enabled_tabs text[] DEFAULT ARRAY['posts']::text[] NOT NULL,
    subcategory_keys text[] DEFAULT ARRAY[]::text[] NOT NULL,
    promotion_segment_keys text[] DEFAULT ARRAY[]::text[] NOT NULL,
    title_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    description_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    rules_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    icon_key text DEFAULT ''::text NOT NULL,
    rollout_policy text NOT NULL,
    allowed_scope_types text[] DEFAULT ARRAY['CITY']::text[] NOT NULL,
    default_moderation_mode text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_blueprints_default_moderation CHECK ((default_moderation_mode = ANY (ARRAY['PREMODERATION'::text, 'PUBLISH_FIRST'::text, 'PUBLISH_FIRST_WITH_RISK_HOLD'::text, 'TRUSTED_PUBLISH_ELSE_REVIEW'::text]))),
    CONSTRAINT chk_community_blueprints_rollout CHECK ((rollout_policy = ANY (ARRAY['ELIGIBLE_HUBS'::text, 'PRIORITY_HUBS'::text, 'ON_DEMAND'::text]))),
    CONSTRAINT chk_community_blueprints_status CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'ARCHIVED'::text, 'HIDDEN'::text])))
);


--
-- Name: community_geo_hubs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_geo_hubs (
    country_code text NOT NULL,
    city_id text NOT NULL,
    hub_tier text NOT NULL,
    community_enabled boolean DEFAULT false NOT NULL,
    parent_country_code text,
    parent_city_id text,
    reason text NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    created_by text DEFAULT 'seed'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    PRIMARY KEY (country_code, city_id),
    CONSTRAINT chk_community_geo_hubs_hub_tier CHECK ((hub_tier = ANY (ARRAY['GLOBAL'::text, 'NATIONAL'::text, 'REGIONAL'::text, 'TOURIST'::text, 'ALIAS_ONLY'::text]))),
    CONSTRAINT chk_community_geo_hubs_parent_pair CHECK ((((parent_country_code IS NULL) AND (parent_city_id IS NULL)) OR ((parent_country_code IS NOT NULL) AND (parent_city_id IS NOT NULL)))),
    CONSTRAINT chk_community_geo_hubs_priority CHECK ((priority >= 0))
);


--
-- Name: community_geo_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_geo_aliases (
    country_code text NOT NULL,
    city_id text NOT NULL,
    parent_country_code text NOT NULL,
    parent_city_id text NOT NULL,
    reason text NOT NULL,
    created_by text DEFAULT 'seed'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    PRIMARY KEY (country_code, city_id),
    CONSTRAINT chk_community_geo_aliases_no_self_alias CHECK (((country_code <> parent_country_code) OR (city_id <> parent_city_id)))
);


--
-- Name: community_blueprint_geo_coverage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_blueprint_geo_coverage (
    id uuid NOT NULL PRIMARY KEY,
    blueprint_id uuid NOT NULL REFERENCES community_blueprints(id) ON DELETE CASCADE,
    country_code text NOT NULL,
    city_id text,
    scope_type text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_blueprint_geo_coverage_scope CHECK ((scope_type = ANY (ARRAY['CITY'::text, 'GLOBAL'::text]))),
    CONSTRAINT chk_community_blueprint_geo_coverage_status CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'ARCHIVED'::text, 'HIDDEN'::text]))),
    CONSTRAINT chk_community_blueprint_geo_coverage_priority CHECK ((priority >= 0))
);


--
-- Name: community_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_instances (
    id uuid NOT NULL PRIMARY KEY,
    community_id uuid UNIQUE,
    blueprint_id uuid NOT NULL REFERENCES community_blueprints(id) ON DELETE CASCADE,
    slug text NOT NULL UNIQUE,
    country_code text NOT NULL,
    city_id text,
    scope_type text NOT NULL,
    title_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    description_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    rules_i18n jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    member_count integer DEFAULT 0 NOT NULL,
    post_count integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_instances_counts CHECK (((member_count >= 0) AND (post_count >= 0))),
    CONSTRAINT chk_community_instances_scope CHECK ((scope_type = ANY (ARRAY['CITY'::text, 'GLOBAL'::text]))),
    CONSTRAINT chk_community_instances_status CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'ARCHIVED'::text, 'HIDDEN'::text]))),
    CONSTRAINT uq_community_instances_blueprint_geo UNIQUE (blueprint_id, country_code, city_id, scope_type)
);


--
-- Name: community_instance_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_instance_stats (
    community_instance_id uuid NOT NULL PRIMARY KEY REFERENCES community_instances(id) ON DELETE CASCADE,
    member_count integer DEFAULT 0 NOT NULL,
    post_count integer DEFAULT 0 NOT NULL,
    active_post_count integer DEFAULT 0 NOT NULL,
    last_post_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_instance_stats_counts CHECK (((member_count >= 0) AND (post_count >= 0) AND (active_post_count >= 0)))
);


--
-- Name: community_instance_materialization_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_instance_materialization_events (
    id uuid NOT NULL PRIMARY KEY,
    blueprint_id uuid NOT NULL REFERENCES community_blueprints(id) ON DELETE CASCADE,
    country_code text NOT NULL,
    city_id text,
    scope_type text NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_instance_materialization_scope CHECK ((scope_type = ANY (ARRAY['CITY'::text, 'GLOBAL'::text]))),
    CONSTRAINT chk_community_instance_materialization_status CHECK ((status = ANY (ARRAY['PENDING'::text, 'DONE'::text, 'FAILED'::text])))
);


--
-- Name: post_profile_schema_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_profile_schema_versions (
    post_profile_key text NOT NULL REFERENCES community_post_profiles(key) ON DELETE CASCADE,
    version integer NOT NULL,
    schema_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    validation_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    PRIMARY KEY (post_profile_key, version),
    CONSTRAINT chk_post_profile_schema_versions_version CHECK ((version > 0))
);


--
-- Seed community post profiles.
--

INSERT INTO community_post_profiles (
    key,
    version,
    post_kind,
    composer_preset,
    render_preset,
    schema_json,
    validation_json,
    moderation_mode,
    activity_creation_mode
) VALUES
    ('article_v1', 1, 'ARTICLE', 'rich_article', 'article_card', '{"kind":"article","version":1,"fields":{"title":{"type":"string"},"excerpt":{"type":"string"},"content_blocks":{"type":"content_blocks"},"cover_file_id":{"type":"uuid"},"tags":{"type":"string_array"}}}'::jsonb, '{"required":["title","excerpt","content_blocks"],"maxLength":{"title":140,"excerpt":280},"minItems":{"content_blocks":1},"maxItems":{"tags":12}}'::jsonb, 'PREMODERATION', 'DISABLED'),
    ('quick_post_v1', 1, 'QUICK_POST', 'quick_post', 'quick_post_card', '{"kind":"quick_post","version":1,"fields":{"body":{"type":"string"},"media_file_ids":{"type":"uuid_array"},"tags":{"type":"string_array"}}}'::jsonb, '{"required":["body"],"maxLength":{"body":1000},"maxItems":{"media_file_ids":8,"tags":12}}'::jsonb, 'PUBLISH_FIRST', 'DISABLED'),
    ('listing_v1', 1, 'LISTING', 'listing_form', 'listing_card', '{"kind":"listing","version":1,"fields":{"title":{"type":"string"},"body":{"type":"string"},"price":{"type":"decimal"},"currency":{"type":"currency"},"location":{"type":"geo_text"},"media_file_ids":{"type":"uuid_array"},"contact_preference":{"type":"string"}}}'::jsonb, '{"required":["title","body","location"],"maxLength":{"title":120,"body":2000},"maxItems":{"media_file_ids":12}}'::jsonb, 'PUBLISH_FIRST_WITH_RISK_HOLD', 'DISABLED'),
    ('event_announcement_v1', 1, 'EVENT_ANNOUNCEMENT', 'event_announcement_form', 'event_card', '{"kind":"event_announcement","version":1,"fields":{"title":{"type":"string"},"description":{"type":"string"},"starts_at":{"type":"datetime"},"ends_at":{"type":"datetime"},"location":{"type":"geo_text"},"capacity":{"type":"integer"},"price":{"type":"money"},"media_file_ids":{"type":"uuid_array"}},"activityMapping":{"titleField":"title","descriptionField":"description","startAtField":"starts_at","endAtField":"ends_at","locationField":"location","capacityField":"capacity","priceField":"price"}}'::jsonb, '{"required":["title","description","starts_at","location"],"maxLength":{"title":120,"description":3000},"maxItems":{"media_file_ids":12}}'::jsonb, 'TRUSTED_PUBLISH_ELSE_REVIEW', 'REQUIRED'),
    ('question_answer_v1', 1, 'QUESTION_ANSWER', 'question_form', 'question_card', '{"kind":"question_answer","version":1,"fields":{"question":{"type":"string"},"details":{"type":"string"},"tags":{"type":"string_array"},"location":{"type":"geo_text"}}}'::jsonb, '{"required":["question"],"maxLength":{"question":240,"details":2000},"maxItems":{"tags":8}}'::jsonb, 'PUBLISH_FIRST', 'DISABLED'),
    ('trip_plan_v1', 1, 'TRIP_PLAN', 'trip_plan_form', 'trip_plan_card', '{"kind":"trip_plan","version":1,"fields":{"title":{"type":"string"},"route":{"type":"route"},"starts_at":{"type":"datetime"},"meeting_point":{"type":"geo_text"},"participant_limit":{"type":"integer"},"transport_mode":{"type":"string"},"cost_share":{"type":"money"},"media_file_ids":{"type":"uuid_array"}},"activityMapping":{"titleField":"title","descriptionField":"route","startAtField":"starts_at","locationField":"meeting_point","capacityField":"participant_limit","priceField":"cost_share"}}'::jsonb, '{"required":["title","route","starts_at","meeting_point"],"maxLength":{"title":120},"maxItems":{"media_file_ids":8}}'::jsonb, 'PUBLISH_FIRST_WITH_RISK_HOLD', 'OPTIONAL')
ON CONFLICT (key) DO UPDATE SET
    version = EXCLUDED.version,
    post_kind = EXCLUDED.post_kind,
    composer_preset = EXCLUDED.composer_preset,
    render_preset = EXCLUDED.render_preset,
    schema_json = EXCLUDED.schema_json,
    validation_json = EXCLUDED.validation_json,
    moderation_mode = EXCLUDED.moderation_mode,
    activity_creation_mode = EXCLUDED.activity_creation_mode,
    updated_at = now();

INSERT INTO post_profile_schema_versions (post_profile_key, version, schema_json, validation_json)
SELECT key, version, schema_json, validation_json
FROM community_post_profiles
ON CONFLICT (post_profile_key, version) DO UPDATE SET
    schema_json = EXCLUDED.schema_json,
    validation_json = EXCLUDED.validation_json;


--
-- Seed community blueprints.
--

INSERT INTO community_blueprints (
    id,
    key,
    category,
    default_post_profile_key,
    allowed_post_profile_keys,
    enabled_tabs,
    subcategory_keys,
    promotion_segment_keys,
    title_i18n,
    description_i18n,
    rules_i18n,
    icon_key,
    rollout_policy,
    allowed_scope_types,
    default_moderation_mode
) VALUES
    ('10000000-0000-4000-8000-000000000001', 'languages', 'languages', 'quick_post_v1', ARRAY['quick_post_v1','listing_v1','event_announcement_v1']::text[], ARRAY['discussions','announcements']::text[], ARRAY['english','french','spanish','chinese','other_languages']::text[], ARRAY['languages','english','french','spanish','chinese','other_languages']::text[], '{"ru":"Языки","en":"Languages","kk":"Тілдер"}'::jsonb, '{"ru":"Языковая практика, вопросы, встречи и объявления по языкам.","en":"Language practice, questions, meetups, and language-specific announcements.","kk":"Тіл тәжірибесі, сұрақтар, кездесулер және тілдер бойынша хабарландырулар."}'::jsonb, '{}'::jsonb, 'language', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST'),
    ('10000000-0000-4000-8000-000000000002', 'housing', 'housing', 'listing_v1', ARRAY['listing_v1','quick_post_v1']::text[], ARRAY['listings','discussions']::text[], ARRAY['long_term_rent','short_term_rent','roommates','real_estate']::text[], ARRAY['housing','long_term_rent','short_term_rent','roommates','real_estate']::text[], '{"ru":"Жилье","en":"Housing","kk":"Тұрғын үй"}'::jsonb, '{"ru":"Аренда, посуточное жилье, комнаты, соседи и недвижимость.","en":"Rentals, short stays, rooms, roommates, and real estate.","kk":"Жалдау, қысқа мерзімді баспана, бөлмелер, көршілер және жылжымайтын мүлік."}'::jsonb, '{}'::jsonb, 'home', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST_WITH_RISK_HOLD'),
    ('10000000-0000-4000-8000-000000000003', 'transport', 'transport', 'listing_v1', ARRAY['listing_v1','quick_post_v1']::text[], ARRAY['listings','discussions']::text[], ARRAY['car','bike_scooter','public_transport','driver','repair']::text[], ARRAY['transport','car','bike_scooter','public_transport']::text[], '{"ru":"Транспорт","en":"Transport","kk":"Көлік"}'::jsonb, '{"ru":"Аренда авто, байков, самокатов, общественный транспорт и локальные советы.","en":"Car, bike and scooter rentals, public transport, and local mobility tips.","kk":"Көлік, байк және самокат жалдау, қоғамдық көлік және жергілікті кеңестер."}'::jsonb, '{}'::jsonb, 'bus', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST_WITH_RISK_HOLD'),
    ('10000000-0000-4000-8000-000000000004', 'work_services', 'work', 'listing_v1', ARRAY['listing_v1','quick_post_v1']::text[], ARRAY['listings','discussions']::text[], ARRAY['jobs','gigs','local_services','freelance','documents']::text[], ARRAY['work_services','jobs','services','freelance']::text[], '{"ru":"Работа и услуги","en":"Work and services","kk":"Жұмыс және қызметтер"}'::jsonb, '{"ru":"Вакансии, подработки, услуги, фриланс и помощь в городе.","en":"Jobs, gigs, services, freelance work, and local help.","kk":"Вакансиялар, қосымша жұмыс, қызметтер, фриланс және қаладағы көмек."}'::jsonb, '{}'::jsonb, 'briefcase-business', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST_WITH_RISK_HOLD'),
    ('10000000-0000-4000-8000-000000000005', 'marketplace', 'marketplace', 'listing_v1', ARRAY['listing_v1']::text[], ARRAY['listings']::text[], ARRAY['buy_sell','free','exchange','electronics','home_items','kids']::text[], ARRAY['marketplace','buy_sell','exchange']::text[], '{"ru":"Барахолка","en":"Marketplace","kk":"Базар"}'::jsonb, '{"ru":"Покупка, продажа и обмен вещей в городе.","en":"Buy, sell, and exchange items in the city.","kk":"Қалада заттарды сатып алу, сату және айырбастау."}'::jsonb, '{}'::jsonb, 'shopping-bag', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST_WITH_RISK_HOLD'),
    ('10000000-0000-4000-8000-000000000006', 'sports_training', 'sports', 'event_announcement_v1', ARRAY['quick_post_v1','event_announcement_v1']::text[], ARRAY['activities','discussions']::text[], ARRAY['football','running','fitness','cycling','water_sports','gyms']::text[], ARRAY['sports','football','running','fitness','cycling']::text[], '{"ru":"Спорт и тренировки","en":"Sports and workouts","kk":"Спорт және жаттығулар"}'::jsonb, '{"ru":"Игры, тренировки, маршруты, секции и спортивные встречи.","en":"Games, workouts, routes, classes, and sport meetups.","kk":"Ойындар, жаттығулар, маршруттар, секциялар және спорт кездесулері."}'::jsonb, '{}'::jsonb, 'dumbbell', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'TRUSTED_PUBLISH_ELSE_REVIEW'),
    ('10000000-0000-4000-8000-000000000007', 'hobbies_workshops', 'hobbies', 'quick_post_v1', ARRAY['quick_post_v1','listing_v1','event_announcement_v1']::text[], ARRAY['discussions','activities']::text[], ARRAY['yoga','pottery','art','photography','music','dance','board_games','workshops']::text[], ARRAY['hobbies','yoga','pottery','art','photography','music','dance','workshops']::text[], '{"ru":"Хобби и мастер-классы","en":"Hobbies and workshops","kk":"Хобби және шеберлік сабақтары"}'::jsonb, '{"ru":"Йога, творчество, мастер-классы, фото, музыка, танцы и настольные игры.","en":"Yoga, creative workshops, photo, music, dance, and board games.","kk":"Йога, шығармашылық сабақтар, фото, музыка, би және үстел ойындары."}'::jsonb, '{}'::jsonb, 'sparkles', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'TRUSTED_PUBLISH_ELSE_REVIEW'),
    ('10000000-0000-4000-8000-000000000008', 'trips_companions', 'outdoor', 'trip_plan_v1', ARRAY['trip_plan_v1','quick_post_v1']::text[], ARRAY['trip_plans','discussions']::text[], ARRAY['rideshare','mountain_hiking','trekking','weekend_trips','travel_buddies','routes']::text[], ARRAY['trips','rideshare','hiking','trekking','weekend_trips']::text[], '{"ru":"Поездки и попутчики","en":"Trips and companions","kk":"Сапарлар және жолсеріктер"}'::jsonb, '{"ru":"Попутчики, походы, трекинг, маршруты и короткие поездки.","en":"Rideshares, hikes, trekking, routes, and short trips.","kk":"Жолсеріктер, жорықтар, трекинг, маршруттар және қысқа сапарлар."}'::jsonb, '{}'::jsonb, 'route', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST_WITH_RISK_HOLD'),
    ('10000000-0000-4000-8000-000000000009', 'pets', 'pets', 'quick_post_v1', ARRAY['quick_post_v1','listing_v1']::text[], ARRAY['discussions','listings']::text[], ARRAY['pet_owners','pet_friendly','vets','grooming','boarding','pet_transport']::text[], ARRAY['pets','pet_friendly','vets','pet_services']::text[], '{"ru":"Питомцы","en":"Pets","kk":"Үй жануарлары"}'::jsonb, '{"ru":"Опыт жизни с питомцами, pet-friendly места, ветеринары и услуги.","en":"Living with pets, pet-friendly places, vets, and services.","kk":"Үй жануарларымен өмір, pet-friendly орындар, ветеринарлар және қызметтер."}'::jsonb, '{}'::jsonb, 'paw-print', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST'),
    ('10000000-0000-4000-8000-000000000010', 'city_life', 'city_life', 'quick_post_v1', ARRAY['quick_post_v1']::text[], ARRAY['discussions']::text[], ARRAY['food','cafes','markets','delivery','families','daily_tips','volunteering']::text[], ARRAY['city_life','food','cafes','families','daily_tips']::text[], '{"ru":"Городская жизнь","en":"City life","kk":"Қала өмірі"}'::jsonb, '{"ru":"Еда, кафе, рынки, доставка, семьи, бытовые советы и жизнь в городе.","en":"Food, cafes, markets, delivery, families, everyday tips, and city life.","kk":"Тамақ, кафелер, базарлар, жеткізу, отбасылар, күнделікті кеңестер және қала өмірі."}'::jsonb, '{}'::jsonb, 'utensils', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST'),
    ('10000000-0000-4000-8000-000000000011', 'health_safety', 'health', 'question_answer_v1', ARRAY['question_answer_v1','quick_post_v1']::text[], ARRAY['questions','discussions']::text[], ARRAY['clinics','insurance','pharmacies','emergency','safety','documents']::text[], ARRAY['health_safety','clinics','insurance','pharmacies','emergency']::text[], '{"ru":"Здоровье и безопасность","en":"Health and safety","kk":"Денсаулық және қауіпсіздік"}'::jsonb, '{"ru":"Клиники, аптеки, страховка, безопасность и экстренные вопросы.","en":"Clinics, pharmacies, insurance, safety, and urgent questions.","kk":"Клиникалар, дәріханалар, сақтандыру, қауіпсіздік және шұғыл сұрақтар."}'::jsonb, '{}'::jsonb, 'heart-pulse', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST'),
    ('10000000-0000-4000-8000-000000000012', 'event_board', 'events', 'event_announcement_v1', ARRAY['event_announcement_v1']::text[], ARRAY['activities']::text[], ARRAY['meetups','concerts','workshops','volunteering','family_events','free_events']::text[], ARRAY['events','meetups','workshops','concerts']::text[], '{"ru":"Афиша","en":"Events","kk":"Афиша"}'::jsonb, '{"ru":"События, встречи и локальные мероприятия.","en":"Events, meetups, and local happenings.","kk":"Іс-шаралар, кездесулер және жергілікті оқиғалар."}'::jsonb, '{}'::jsonb, 'calendar', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'TRUSTED_PUBLISH_ELSE_REVIEW'),
    ('10000000-0000-4000-8000-000000000013', 'local_news', 'content', 'article_v1', ARRAY['article_v1']::text[], ARRAY['articles']::text[], ARRAY['official_updates','local_news','travel_alerts','guides']::text[], ARRAY['news','official_updates','travel_alerts']::text[], '{"ru":"Новости","en":"News","kk":"Жаңалықтар"}'::jsonb, '{"ru":"Локальные новости, официальные обновления и важные заметки для путешественников.","en":"Local news, official updates, and important traveler notes.","kk":"Жергілікті жаңалықтар, ресми жаңартулар және саяхатшыларға маңызды ескертпелер."}'::jsonb, '{}'::jsonb, 'newspaper', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PREMODERATION'),
    ('10000000-0000-4000-8000-000000000014', 'questions_answers', 'qa', 'question_answer_v1', ARRAY['question_answer_v1']::text[], ARRAY['questions']::text[], ARRAY['city_questions','country_questions','documents','transport','housing','safety']::text[], ARRAY['questions_answers','city_questions','documents','safety']::text[], '{"ru":"Вопросы и ответы","en":"Questions and answers","kk":"Сұрақтар мен жауаптар"}'::jsonb, '{"ru":"Практические вопросы по городу, стране, документам, транспорту и быту.","en":"Practical questions about the city, country, documents, transport, and everyday life.","kk":"Қала, ел, құжаттар, көлік және күнделікті өмір туралы практикалық сұрақтар."}'::jsonb, '{}'::jsonb, 'circle-help', 'ELIGIBLE_HUBS', ARRAY['CITY'], 'PUBLISH_FIRST')
ON CONFLICT (key) DO UPDATE SET
    category = EXCLUDED.category,
    default_post_profile_key = EXCLUDED.default_post_profile_key,
    allowed_post_profile_keys = EXCLUDED.allowed_post_profile_keys,
    enabled_tabs = EXCLUDED.enabled_tabs,
    subcategory_keys = EXCLUDED.subcategory_keys,
    promotion_segment_keys = EXCLUDED.promotion_segment_keys,
    title_i18n = EXCLUDED.title_i18n,
    description_i18n = EXCLUDED.description_i18n,
    rules_i18n = EXCLUDED.rules_i18n,
    icon_key = EXCLUDED.icon_key,
    rollout_policy = EXCLUDED.rollout_policy,
    allowed_scope_types = EXCLUDED.allowed_scope_types,
    default_moderation_mode = EXCLUDED.default_moderation_mode,
    status = EXCLUDED.status,
    updated_at = now();


--
-- Seed initial community geo hubs and aliases. The full production coverage is managed by the geo hub admin/generator; these rows protect the baseline contract and local development.
--

INSERT INTO community_geo_hubs (
    country_code,
    city_id,
    hub_tier,
    community_enabled,
    parent_country_code,
    parent_city_id,
    reason,
    priority
) VALUES
    ('KZ', 'almaty', 'NATIONAL', true, NULL, NULL, 'major_city', 10),
    ('KZ', 'astana', 'NATIONAL', true, NULL, NULL, 'capital_city', 20),
    ('KZ', 'taldykorgan', 'ALIAS_ONLY', false, 'KZ', 'almaty', 'nearby_alias', 900),
    ('KZ', 'kapchagay', 'ALIAS_ONLY', false, 'KZ', 'almaty', 'nearby_alias', 900),
    ('KZ', 'konaev', 'ALIAS_ONLY', false, 'KZ', 'almaty', 'nearby_alias', 900),
    ('KZ', 'balkhash', 'ALIAS_ONLY', false, 'KZ', 'almaty', 'nearby_alias', 900),
    ('KZ', 'kokshetau', 'ALIAS_ONLY', false, 'KZ', 'astana', 'nearby_alias', 900),
    ('RU', 'novosibirsk', 'REGIONAL', true, NULL, NULL, 'regional_transport_hub', 40),
    ('RU', 'omsk', 'ALIAS_ONLY', false, 'RU', 'novosibirsk', 'nearby_alias', 900),
    ('VN', 'ho-chi-minh-city', 'GLOBAL', true, NULL, NULL, 'major_city', 10),
    ('VN', 'hanoi', 'GLOBAL', true, NULL, NULL, 'capital_city', 20),
    ('VN', 'da-nang', 'REGIONAL', true, NULL, NULL, 'tourist_demand', 30),
    ('VN', 'nha-trang', 'TOURIST', true, NULL, NULL, 'tourist_demand', 40),
    ('VN', 'ha-long', 'TOURIST', true, NULL, NULL, 'tourist_demand', 50),
    ('VN', 'cat-ba', 'ALIAS_ONLY', false, 'VN', 'ha-long', 'nearby_alias', 900),
    ('VN', 'phan-thiet', 'ALIAS_ONLY', false, 'VN', 'nha-trang', 'nearby_alias', 900),
    ('GE', 'tbilisi', 'NATIONAL', true, NULL, NULL, 'capital_city', 10),
    ('GE', 'batumi', 'TOURIST', true, NULL, NULL, 'tourist_demand', 30),
    ('RU', 'moscow', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 110),
    ('UZ', 'tashkent', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 120),
    ('KG', 'bishkek', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 130),
    ('TJ', 'dushanbe', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 140),
    ('TM', 'ashgabat', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 150),
    ('AZ', 'baku', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 170),
    ('AM', 'yerevan', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 180),
    ('BY', 'minsk', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 190),
    ('RS', 'belgrade', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 200),
    ('GR', 'athens', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 210),
    ('UA', 'kyiv', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 220),
    ('MD', 'chisinau', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 230),
    ('TR', 'istanbul', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 240),
    ('AE', 'dubai', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 250),
    ('TH', 'bangkok', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 260),
    ('PH', 'manila', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 270),
    ('EG', 'cairo', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 290),
    ('CN', 'beijing', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 300),
    ('KR', 'seoul', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 310),
    ('JP', 'tokyo', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 320),
    ('IN', 'new-delhi', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 330),
    ('US', 'new-york', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 340),
    ('CA', 'toronto', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 350),
    ('SG', 'singapore', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 360),
    ('GB', 'london', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 370),
    ('DE', 'berlin', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 380),
    ('AT', 'vienna', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 390),
    ('AU', 'sydney', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 400),
    ('NZ', 'auckland', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 410),
    ('TZ', 'dar-es-salaam', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 420),
    ('KE', 'nairobi', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 430),
    ('FR', 'paris', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 440),
    ('IT', 'rome', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 450),
    ('ES', 'madrid', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 460),
    ('MN', 'ulaanbaatar', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 470),
    ('MY', 'kuala-lumpur', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 480),
    ('ID', 'jakarta', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 490),
    ('MV', 'male', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 500),
    ('SC', 'victoria', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 510),
    ('PL', 'warsaw', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 520),
    ('MX', 'mexico-city', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 530),
    ('BR', 'rio-de-janeiro', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 540),
    ('AR', 'buenos-aires', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 550),
    ('AB', 'sukhum', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 560),
    ('CU', 'havana', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 570),
    ('MA', 'casablanca', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 580),
    ('PT', 'lisbon', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 590),
    ('LU', 'luxembourg-city', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 600),
    ('LK', 'colombo', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 610),
    ('ME', 'podgorica', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 620),
    ('MT', 'valletta', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 630),
    ('CY', 'nicosia', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 640),
    ('CH', 'zurich', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 650),
    ('IS', 'reykjavik', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 660),
    ('IE', 'dublin', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 670),
    ('NL', 'amsterdam', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 680),
    ('DK', 'copenhagen', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 690),
    ('FI', 'helsinki', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 700),
    ('EE', 'tallinn', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 710),
    ('SE', 'stockholm', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 720),
    ('CZ', 'prague', 'NATIONAL', true, NULL, NULL, 'primary_catalog_city', 730),
    ('KZ', 'shymkent', 'REGIONAL', true, NULL, NULL, 'major_city', 800),
    ('KZ', 'aktau', 'TOURIST', true, NULL, NULL, 'tourist_demand', 805),
    ('KZ', 'turkestan', 'TOURIST', true, NULL, NULL, 'tourist_demand', 810),
    ('RU', 'spb', 'REGIONAL', true, NULL, NULL, 'major_city', 815),
    ('RU', 'yekaterinburg', 'REGIONAL', true, NULL, NULL, 'major_city', 820),
    ('RU', 'kazan', 'REGIONAL', true, NULL, NULL, 'major_city', 825),
    ('RU', 'sochi', 'TOURIST', true, NULL, NULL, 'tourist_demand', 830),
    ('UZ', 'samarkand', 'REGIONAL', true, NULL, NULL, 'major_city', 835),
    ('UZ', 'bukhara', 'TOURIST', true, NULL, NULL, 'tourist_demand', 840),
    ('UZ', 'khiva', 'TOURIST', true, NULL, NULL, 'tourist_demand', 845),
    ('UZ', 'fergana', 'TOURIST', true, NULL, NULL, 'tourist_demand', 850),
    ('KG', 'osh', 'TOURIST', true, NULL, NULL, 'tourist_demand', 855),
    ('KG', 'karakol', 'TOURIST', true, NULL, NULL, 'tourist_demand', 860),
    ('KG', 'cholpon-ata', 'TOURIST', true, NULL, NULL, 'tourist_demand', 865),
    ('TJ', 'khujand', 'TOURIST', true, NULL, NULL, 'tourist_demand', 870),
    ('TJ', 'panjakent', 'TOURIST', true, NULL, NULL, 'tourist_demand', 875),
    ('TJ', 'khorog', 'TOURIST', true, NULL, NULL, 'tourist_demand', 880),
    ('GE', 'kutaisi', 'TOURIST', true, NULL, NULL, 'tourist_demand', 885),
    ('GE', 'stepantsminda', 'TOURIST', true, NULL, NULL, 'tourist_demand', 890),
    ('GE', 'gudauri', 'TOURIST', true, NULL, NULL, 'tourist_demand', 895),
    ('GE', 'telavi', 'TOURIST', true, NULL, NULL, 'tourist_demand', 900),
    ('GE', 'borjomi', 'TOURIST', true, NULL, NULL, 'tourist_demand', 905),
    ('GE', 'kobuleti', 'TOURIST', true, NULL, NULL, 'tourist_demand', 910),
    ('AZ', 'ganja', 'TOURIST', true, NULL, NULL, 'tourist_demand', 915),
    ('AZ', 'sheki', 'TOURIST', true, NULL, NULL, 'tourist_demand', 920),
    ('AZ', 'gabala', 'TOURIST', true, NULL, NULL, 'tourist_demand', 925),
    ('AM', 'gyumri', 'TOURIST', true, NULL, NULL, 'tourist_demand', 930),
    ('AM', 'dilijan', 'TOURIST', true, NULL, NULL, 'tourist_demand', 935),
    ('AM', 'tsaghkadzor', 'TOURIST', true, NULL, NULL, 'tourist_demand', 940),
    ('RS', 'novi-sad', 'TOURIST', true, NULL, NULL, 'tourist_demand', 945),
    ('RS', 'nis', 'TOURIST', true, NULL, NULL, 'tourist_demand', 950),
    ('GR', 'thessaloniki', 'TOURIST', true, NULL, NULL, 'tourist_demand', 955),
    ('GR', 'rhodes', 'TOURIST', true, NULL, NULL, 'tourist_demand', 960),
    ('TH', 'phuket', 'TOURIST', true, NULL, NULL, 'tourist_demand', 965),
    ('TH', 'pattaya', 'TOURIST', true, NULL, NULL, 'tourist_demand', 970),
    ('TH', 'chiang-mai', 'TOURIST', true, NULL, NULL, 'tourist_demand', 975),
    ('TH', 'krabi', 'TOURIST', true, NULL, NULL, 'tourist_demand', 980),
    ('PH', 'cebu-city', 'REGIONAL', true, NULL, NULL, 'major_city', 985),
    ('PH', 'boracay', 'TOURIST', true, NULL, NULL, 'tourist_demand', 990),
    ('VN', 'ninh-binh', 'TOURIST', true, NULL, NULL, 'tourist_demand', 995),
    ('VN', 'hue', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1000),
    ('VN', 'hoi-an', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1005),
    ('VN', 'da-lat', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1010),
    ('VN', 'sa-pa', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1015),
    ('EG', 'luxor', 'REGIONAL', true, NULL, NULL, 'major_city', 1020),
    ('EG', 'hurghada', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1025),
    ('EG', 'sharm-el-sheikh', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1030),
    ('CN', 'shanghai', 'REGIONAL', true, NULL, NULL, 'major_city', 1035),
    ('CN', 'xian', 'REGIONAL', true, NULL, NULL, 'major_city', 1040),
    ('CN', 'chengdu', 'REGIONAL', true, NULL, NULL, 'major_city', 1045),
    ('CN', 'guilin', 'REGIONAL', true, NULL, NULL, 'major_city', 1050),
    ('KR', 'busan', 'REGIONAL', true, NULL, NULL, 'major_city', 1055),
    ('KR', 'jeju', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1060),
    ('JP', 'osaka', 'REGIONAL', true, NULL, NULL, 'major_city', 1065),
    ('JP', 'kyoto', 'REGIONAL', true, NULL, NULL, 'major_city', 1070),
    ('JP', 'nara', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1075),
    ('IN', 'jaipur', 'REGIONAL', true, NULL, NULL, 'major_city', 1080),
    ('IN', 'varanasi', 'REGIONAL', true, NULL, NULL, 'major_city', 1085),
    ('IN', 'goa', 'REGIONAL', true, NULL, NULL, 'major_city', 1090),
    ('US', 'los-angeles', 'REGIONAL', true, NULL, NULL, 'major_city', 1095),
    ('US', 'miami', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1100),
    ('US', 'san-francisco', 'REGIONAL', true, NULL, NULL, 'major_city', 1105),
    ('US', 'las-vegas', 'REGIONAL', true, NULL, NULL, 'major_city', 1110),
    ('CA', 'vancouver', 'REGIONAL', true, NULL, NULL, 'major_city', 1115),
    ('CA', 'whistler', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1120),
    ('GB', 'edinburgh', 'REGIONAL', true, NULL, NULL, 'major_city', 1125),
    ('GB', 'oxford', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1130),
    ('GB', 'cambridge', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1135),
    ('DE', 'munich', 'REGIONAL', true, NULL, NULL, 'major_city', 1140),
    ('DE', 'hamburg', 'REGIONAL', true, NULL, NULL, 'major_city', 1145),
    ('AT', 'salzburg', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1150),
    ('AT', 'innsbruck', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1155),
    ('AU', 'melbourne', 'REGIONAL', true, NULL, NULL, 'major_city', 1160),
    ('AU', 'gold-coast', 'REGIONAL', true, NULL, NULL, 'major_city', 1165),
    ('NZ', 'rotorua', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1170),
    ('NZ', 'queenstown', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1175),
    ('TZ', 'zanzibar-city', 'REGIONAL', true, NULL, NULL, 'major_city', 1180),
    ('TZ', 'arusha', 'REGIONAL', true, NULL, NULL, 'major_city', 1185),
    ('KE', 'mombasa', 'REGIONAL', true, NULL, NULL, 'major_city', 1190),
    ('FR', 'nice', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1195),
    ('FR', 'lyon', 'REGIONAL', true, NULL, NULL, 'major_city', 1200),
    ('FR', 'marseille', 'REGIONAL', true, NULL, NULL, 'major_city', 1205),
    ('IT', 'milan', 'REGIONAL', true, NULL, NULL, 'major_city', 1210),
    ('IT', 'venice', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1215),
    ('IT', 'florence', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1220),
    ('ES', 'barcelona', 'REGIONAL', true, NULL, NULL, 'major_city', 1225),
    ('ES', 'valencia', 'REGIONAL', true, NULL, NULL, 'major_city', 1230),
    ('ES', 'seville', 'REGIONAL', true, NULL, NULL, 'major_city', 1235),
    ('MY', 'george-town', 'REGIONAL', true, NULL, NULL, 'major_city', 1240),
    ('MY', 'langkawi', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1245),
    ('ID', 'bali', 'REGIONAL', true, NULL, NULL, 'major_city', 1250),
    ('ID', 'denpasar', 'REGIONAL', true, NULL, NULL, 'major_city', 1255),
    ('PL', 'krakow', 'REGIONAL', true, NULL, NULL, 'major_city', 1260),
    ('PL', 'gdansk', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1265),
    ('MX', 'cancun', 'REGIONAL', true, NULL, NULL, 'major_city', 1270),
    ('MX', 'playa-del-carmen', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1275),
    ('BR', 'sao-paulo', 'REGIONAL', true, NULL, NULL, 'major_city', 1280),
    ('CU', 'varadero', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1285),
    ('MA', 'tangier', 'REGIONAL', true, NULL, NULL, 'major_city', 1290),
    ('MA', 'marrakech', 'REGIONAL', true, NULL, NULL, 'major_city', 1295),
    ('PT', 'porto', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1300),
    ('LK', 'kandy', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1305),
    ('ME', 'kotor', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1310),
    ('ME', 'budva', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1315),
    ('CY', 'limassol', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1320),
    ('CY', 'paphos', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1325),
    ('CH', 'geneva', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1330),
    ('IE', 'galway', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1335),
    ('NL', 'rotterdam', 'REGIONAL', true, NULL, NULL, 'major_city', 1340),
    ('SE', 'gothenburg', 'REGIONAL', true, NULL, NULL, 'major_city', 1345),
    ('CZ', 'cesky-krumlov', 'TOURIST', true, NULL, NULL, 'tourist_demand', 1350)
ON CONFLICT (country_code, city_id) DO UPDATE SET
    hub_tier = EXCLUDED.hub_tier,
    community_enabled = EXCLUDED.community_enabled,
    parent_country_code = EXCLUDED.parent_country_code,
    parent_city_id = EXCLUDED.parent_city_id,
    reason = EXCLUDED.reason,
    priority = EXCLUDED.priority,
    updated_at = now();

INSERT INTO community_geo_aliases (
    country_code,
    city_id,
    parent_country_code,
    parent_city_id,
    reason
) VALUES
    ('KZ', 'taldykorgan', 'KZ', 'almaty', 'nearby_alias'),
    ('KZ', 'kapchagay', 'KZ', 'almaty', 'nearby_alias'),
    ('KZ', 'konaev', 'KZ', 'almaty', 'nearby_alias'),
    ('KZ', 'balkhash', 'KZ', 'almaty', 'nearby_alias'),
    ('KZ', 'kokshetau', 'KZ', 'astana', 'nearby_alias'),
    ('RU', 'omsk', 'RU', 'novosibirsk', 'nearby_alias'),
    ('VN', 'cat-ba', 'VN', 'ha-long', 'nearby_alias'),
    ('VN', 'phan-thiet', 'VN', 'nha-trang', 'nearby_alias')
ON CONFLICT (country_code, city_id) DO UPDATE SET
    parent_country_code = EXCLUDED.parent_country_code,
    parent_city_id = EXCLUDED.parent_city_id,
    reason = EXCLUDED.reason,
    updated_at = now();

WITH city_coverage AS (
    SELECT
        cb.id AS blueprint_id,
        gh.country_code,
        gh.city_id,
        'CITY'::text AS scope_type,
        gh.priority,
        md5(cb.key || ':city:' || gh.country_code || ':' || gh.city_id) AS hash
    FROM community_blueprints cb
    JOIN community_geo_hubs gh ON gh.community_enabled = true
    WHERE cb.allowed_scope_types @> ARRAY['CITY']::text[]
      AND gh.hub_tier <> 'ALIAS_ONLY'
      AND cb.rollout_policy IN ('ELIGIBLE_HUBS', 'PRIORITY_HUBS', 'ON_DEMAND')
),
coverage AS (
    SELECT * FROM city_coverage
)
INSERT INTO community_blueprint_geo_coverage (
    id,
    blueprint_id,
    country_code,
    city_id,
    scope_type,
    status,
    priority
)
SELECT
    (
        substr(hash, 1, 8) || '-' ||
        substr(hash, 9, 4) || '-4' ||
        substr(hash, 14, 3) || '-8' ||
        substr(hash, 18, 3) || '-' ||
        substr(hash, 21, 12)
    )::uuid,
    blueprint_id,
    country_code,
    city_id,
    scope_type,
    'ACTIVE',
    priority
FROM coverage
ON CONFLICT DO NOTHING;


--
-- Name: community_member_role_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_member_role_changes (
    id uuid NOT NULL,
    community_id uuid NOT NULL,
    target_user_id uuid NOT NULL,
    actor_user_id uuid NOT NULL,
    previous_role text NOT NULL,
    next_role text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_member_role_changes_next_role CHECK ((next_role = ANY (ARRAY['MEMBER'::text, 'TRUSTED_MEMBER'::text, 'MODERATOR'::text, 'ADMIN'::text]))),
    CONSTRAINT chk_community_member_role_changes_previous_role CHECK ((previous_role = ANY (ARRAY['MEMBER'::text, 'TRUSTED_MEMBER'::text, 'MODERATOR'::text, 'ADMIN'::text])))
);


--
-- Name: community_member_status_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_member_status_changes (
    id uuid NOT NULL,
    community_id uuid NOT NULL,
    target_user_id uuid NOT NULL,
    actor_user_id uuid NOT NULL,
    previous_status text NOT NULL,
    next_status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_member_status_changes_next_status CHECK ((next_status = ANY (ARRAY['ACTIVE'::text, 'MUTED'::text, 'BANNED'::text, 'LEFT'::text]))),
    CONSTRAINT chk_community_member_status_changes_previous_status CHECK ((previous_status = ANY (ARRAY['ACTIVE'::text, 'MUTED'::text, 'BANNED'::text, 'LEFT'::text])))
);


--
-- Name: community_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_memberships (
    community_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text DEFAULT 'MEMBER'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_memberships_role CHECK ((role = ANY (ARRAY['MEMBER'::text, 'TRUSTED_MEMBER'::text, 'MODERATOR'::text, 'ADMIN'::text]))),
    CONSTRAINT chk_community_memberships_status CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'MUTED'::text, 'BANNED'::text, 'LEFT'::text])))
);


--
-- Name: post_community_moderation_decisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_community_moderation_decisions (
    id uuid NOT NULL,
    post_id uuid NOT NULL,
    community_id uuid NOT NULL,
    moderator_user_id uuid NOT NULL,
    decision text NOT NULL,
    previous_status text NOT NULL,
    next_status text NOT NULL,
    post_revision bigint NOT NULL,
    reason text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_post_community_moderation_decisions_decision CHECK ((decision = ANY (ARRAY['APPROVE'::text, 'REJECT'::text]))),
    CONSTRAINT chk_post_community_moderation_decisions_next_status CHECK ((next_status = ANY (ARRAY['APPROVED'::text, 'REJECTED'::text]))),
    CONSTRAINT chk_post_community_moderation_decisions_previous_status CHECK ((previous_status = ANY (ARRAY['NOT_REQUIRED'::text, 'PENDING'::text, 'APPROVED'::text, 'REJECTED'::text, 'HIDDEN'::text])))
);


--
-- Name: community_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS community_reports (
    id uuid NOT NULL,
    community_id uuid NOT NULL,
    reporter_user_id uuid NOT NULL,
    reason text NOT NULL,
    details text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'OPEN'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_community_reports_reason CHECK ((reason = ANY (ARRAY['SPAM'::text, 'HARASSMENT'::text, 'HATE'::text, 'SEXUAL_CONTENT'::text, 'VIOLENCE'::text, 'MISINFORMATION'::text, 'ILLEGAL'::text, 'OTHER'::text]))),
    CONSTRAINT chk_community_reports_status CHECK ((status = ANY (ARRAY['OPEN'::text, 'REVIEWED'::text, 'DISMISSED'::text])))
);


--
-- Name: post_feed_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_feed_events (
    id uuid NOT NULL,
    event_id uuid NOT NULL,
    viewer_user_id uuid,
    event_type text NOT NULL,
    surface text NOT NULL,
    tab text NOT NULL,
    block_id text NOT NULL,
    block_type text NOT NULL,
    post_id uuid,
    community_id uuid,
    rank integer DEFAULT 0 NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    request_id text DEFAULT ''::text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT post_feed_events_block_type_check CHECK ((block_type = ANY (ARRAY['stories_tray'::text, 'suggested_communities'::text, 'my_subscriptions'::text, 'post_card'::text, 'activity_card'::text, 'place_card'::text, 'tour_card'::text, 'guide_card'::text, 'profile_card'::text, 'official_news_card'::text]))),
    CONSTRAINT post_feed_events_event_type_check CHECK ((event_type = ANY (ARRAY['impression'::text, 'click'::text, 'dwell'::text, 'like'::text, 'comment'::text, 'share'::text, 'subscribe'::text, 'hide'::text, 'not_interested'::text, 'report'::text]))),
    CONSTRAINT post_feed_events_rank_check CHECK ((rank >= 0)),
    CONSTRAINT post_feed_events_surface_check CHECK ((surface = ANY (ARRAY['home'::text, 'content'::text]))),
    CONSTRAINT post_feed_events_tab_check CHECK ((tab = ANY (ARRAY['for_you'::text, 'following'::text])))
);


--
-- Name: post_feed_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_feed_items (
    post_id uuid NOT NULL,
    author_user_id uuid NOT NULL,
    community_id uuid,
    is_visible boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone NOT NULL,
    rank_published_at timestamp with time zone NOT NULL,
    post_revision bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: post_feed_projection_outbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_feed_projection_outbox (
    id uuid NOT NULL,
    event_type text NOT NULL,
    post_id uuid NOT NULL,
    post_revision bigint NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    last_error text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    delivered_at timestamp with time zone,
    CONSTRAINT post_feed_projection_outbox_attempt_count_check CHECK ((attempt_count >= 0)),
    CONSTRAINT post_feed_projection_outbox_event_type_check CHECK ((event_type = ANY (ARRAY['post_feed.upsert'::text, 'post_feed.delete'::text]))),
    CONSTRAINT post_feed_projection_outbox_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'DELIVERED'::text, 'DEAD'::text])))
);


--
-- Name: post_activity_intents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_activity_intents (
    id uuid NOT NULL,
    event_type text NOT NULL,
    idempotency_key text NOT NULL,
    post_id uuid NOT NULL,
    author_user_id uuid NOT NULL,
    community_id uuid,
    community_instance_id uuid,
    post_profile_key text NOT NULL,
    post_profile_version integer NOT NULL,
    structured_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    last_error text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    delivered_at timestamp with time zone,
    CONSTRAINT post_activity_intents_attempt_count_check CHECK ((attempt_count >= 0)),
    CONSTRAINT post_activity_intents_event_type_check CHECK ((event_type = 'activity_creation_requested'::text)),
    CONSTRAINT post_activity_intents_profile_version_check CHECK ((post_profile_version > 0)),
    CONSTRAINT post_activity_intents_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'DELIVERED'::text, 'DEAD'::text])))
);


--
-- Name: post_feed_user_interests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_feed_user_interests (
    viewer_user_id uuid NOT NULL,
    entity_type text NOT NULL,
    entity_id text NOT NULL,
    representative_id text DEFAULT ''::text NOT NULL,
    score numeric(10,4) DEFAULT 0 NOT NULL,
    impression_count bigint DEFAULT 0 NOT NULL,
    click_count bigint DEFAULT 0 NOT NULL,
    conversion_count bigint DEFAULT 0 NOT NULL,
    hide_count bigint DEFAULT 0 NOT NULL,
    not_interested_count bigint DEFAULT 0 NOT NULL,
    last_event_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT post_feed_user_interests_entity_type_check CHECK ((entity_type = ANY (ARRAY['post'::text, 'post_profile'::text, 'community'::text, 'activity'::text, 'place'::text, 'tour'::text, 'guide'::text, 'profile'::text, 'author'::text, 'city'::text, 'country'::text, 'category'::text, 'tag'::text]))),
    CONSTRAINT post_feed_user_interests_score_check CHECK (((score >= ('-100'::integer)::numeric) AND (score <= (100)::numeric)))
);


--
-- Name: post_feed_social_edges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_feed_social_edges (
    viewer_user_id uuid NOT NULL,
    target_user_id uuid NOT NULL,
    edge_type text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    source_event_id uuid,
    source_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT post_feed_social_edges_edge_type_check CHECK ((edge_type = ANY (ARRAY['friend'::text, 'following'::text]))),
    CONSTRAINT post_feed_social_edges_self_check CHECK ((viewer_user_id <> target_user_id))
);


--
-- Name: post_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_likes (
    post_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: post_media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_media (
    post_id uuid NOT NULL,
    file_id uuid NOT NULL,
    media_type text NOT NULL,
    "position" integer NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    caption text DEFAULT ''::text NOT NULL,
    alt_text text DEFAULT ''::text NOT NULL,
    width integer,
    height integer,
    duration_ms integer,
    thumbnail_file_id uuid,
    processing_status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_post_media_position_non_negative CHECK (("position" >= 0)),
    CONSTRAINT chk_post_media_processing_status CHECK ((processing_status = ANY (ARRAY['PENDING_BIND'::text, 'BOUND'::text, 'BIND_FAILED'::text]))),
    CONSTRAINT chk_post_media_type CHECK ((media_type = ANY (ARRAY['IMAGE'::text, 'VIDEO'::text, 'AUDIO'::text, 'DOCUMENT'::text])))
);


--
-- Name: post_moderation_outbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_moderation_outbox (
    id uuid NOT NULL,
    event_type text NOT NULL,
    aggregate_type text NOT NULL,
    aggregate_id uuid NOT NULL,
    community_id uuid,
    post_id uuid,
    actor_user_id uuid NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    last_error text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    delivered_at timestamp with time zone,
    CONSTRAINT post_moderation_outbox_aggregate_type_check CHECK ((aggregate_type = ANY (ARRAY['POST'::text, 'POST_REPORT'::text]))),
    CONSTRAINT post_moderation_outbox_attempt_count_check CHECK ((attempt_count >= 0)),
    CONSTRAINT post_moderation_outbox_event_type_check CHECK ((event_type = ANY (ARRAY['post_moderation.reviewed'::text, 'post_report.created'::text, 'post_report.auto_hidden'::text, 'post_report.resolved'::text]))),
    CONSTRAINT post_moderation_outbox_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'DELIVERED'::text, 'DEAD'::text])))
);


--
-- Name: post_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_reports (
    id uuid NOT NULL,
    post_id uuid NOT NULL,
    community_id uuid,
    reporter_user_id uuid NOT NULL,
    author_user_id uuid NOT NULL,
    reason text NOT NULL,
    details text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'OPEN'::text NOT NULL,
    resolved_by_user_id uuid,
    resolution_note text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    CONSTRAINT chk_post_reports_not_own CHECK ((reporter_user_id <> author_user_id)),
    CONSTRAINT chk_post_reports_reason CHECK ((reason = ANY (ARRAY['SPAM'::text, 'HARASSMENT'::text, 'HATE'::text, 'SEXUAL_CONTENT'::text, 'VIOLENCE'::text, 'MISINFORMATION'::text, 'ILLEGAL'::text, 'OTHER'::text]))),
    CONSTRAINT chk_post_reports_status CHECK ((status = ANY (ARRAY['OPEN'::text, 'REVIEWED'::text, 'DISMISSED'::text])))
);


--
-- Name: post_seen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_seen (
    post_id uuid NOT NULL,
    viewer_user_id uuid NOT NULL,
    seen_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: post_view_sketches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS post_view_sketches (
    post_id uuid NOT NULL,
    registers bytea NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: posts chk_posts_format; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE posts
    ADD CONSTRAINT chk_posts_format CHECK ((format = ANY (ARRAY['POST'::text, 'GUIDE'::text, 'PHOTO_ESSAY'::text, 'ARTICLE'::text, 'CULINARY'::text]))) NOT VALID;


--
-- Name: posts chk_posts_moderation_status; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE posts
    ADD CONSTRAINT chk_posts_moderation_status CHECK ((moderation_status = ANY (ARRAY['NOT_REQUIRED'::text, 'PENDING'::text, 'APPROVED'::text, 'REJECTED'::text, 'HIDDEN'::text]))) NOT VALID;


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: posts posts_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_slug_key UNIQUE (slug);


--
-- Name: story_seen story_seen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_seen
    ADD CONSTRAINT story_seen_pkey PRIMARY KEY (story_id, viewer_user_id);


--
-- Name: story_likes story_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_likes
    ADD CONSTRAINT story_likes_pkey PRIMARY KEY (story_id, user_id);


--
-- Name: stories stories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stories
    ADD CONSTRAINT stories_pkey PRIMARY KEY (id);


--
-- Name: post_comment_likes post_comment_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_comment_likes
    ADD CONSTRAINT post_comment_likes_pkey PRIMARY KEY (comment_id, user_id);


--
-- Name: post_comments post_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_comments
    ADD CONSTRAINT post_comments_pkey PRIMARY KEY (id);


--
-- Name: communities communities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY communities
    ADD CONSTRAINT communities_pkey PRIMARY KEY (id);


--
-- Name: communities communities_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY communities
    ADD CONSTRAINT communities_slug_key UNIQUE (slug);


--
-- Name: community_member_role_changes community_member_role_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_member_role_changes
    ADD CONSTRAINT community_member_role_changes_pkey PRIMARY KEY (id);


--
-- Name: community_member_status_changes community_member_status_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_member_status_changes
    ADD CONSTRAINT community_member_status_changes_pkey PRIMARY KEY (id);


--
-- Name: community_memberships community_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_memberships
    ADD CONSTRAINT community_memberships_pkey PRIMARY KEY (community_id, user_id);


--
-- Name: post_community_moderation_decisions post_community_moderation_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_community_moderation_decisions
    ADD CONSTRAINT post_community_moderation_decisions_pkey PRIMARY KEY (id);


--
-- Name: community_reports community_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_reports
    ADD CONSTRAINT community_reports_pkey PRIMARY KEY (id);


--
-- Name: post_feed_events post_feed_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_events
    ADD CONSTRAINT post_feed_events_pkey PRIMARY KEY (id);


--
-- Name: post_feed_items post_feed_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_items
    ADD CONSTRAINT post_feed_items_pkey PRIMARY KEY (post_id);


--
-- Name: post_feed_projection_outbox post_feed_projection_outbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_projection_outbox
    ADD CONSTRAINT post_feed_projection_outbox_pkey PRIMARY KEY (id);


--
-- Name: post_feed_projection_outbox post_feed_projection_outbox_unique_event; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_projection_outbox
    ADD CONSTRAINT post_feed_projection_outbox_unique_event UNIQUE (post_id, post_revision, event_type);


--
-- Name: post_activity_intents post_activity_intents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_activity_intents
    ADD CONSTRAINT post_activity_intents_pkey PRIMARY KEY (id);


--
-- Name: post_activity_intents post_activity_intents_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_activity_intents
    ADD CONSTRAINT post_activity_intents_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: post_feed_user_interests post_feed_user_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_user_interests
    ADD CONSTRAINT post_feed_user_interests_pkey PRIMARY KEY (viewer_user_id, entity_type, entity_id);


--
-- Name: post_feed_social_edges post_feed_social_edges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_social_edges
    ADD CONSTRAINT post_feed_social_edges_pkey PRIMARY KEY (viewer_user_id, target_user_id, edge_type);


--
-- Name: post_likes post_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_likes
    ADD CONSTRAINT post_likes_pkey PRIMARY KEY (post_id, user_id);


--
-- Name: post_media post_media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_media
    ADD CONSTRAINT post_media_pkey PRIMARY KEY (post_id, file_id);


--
-- Name: post_moderation_outbox post_moderation_outbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_moderation_outbox
    ADD CONSTRAINT post_moderation_outbox_pkey PRIMARY KEY (id);


--
-- Name: post_reports post_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_reports
    ADD CONSTRAINT post_reports_pkey PRIMARY KEY (id);


--
-- Name: post_seen post_seen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_seen
    ADD CONSTRAINT post_seen_pkey PRIMARY KEY (post_id, viewer_user_id);


--
-- Name: post_view_sketches post_view_sketches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_view_sketches
    ADD CONSTRAINT post_view_sketches_pkey PRIMARY KEY (post_id);


--
-- Name: idx_posts_author_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_author_status ON posts USING btree (author_user_id, status, updated_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_posts_author_published_rate_limit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_author_published_rate_limit ON posts USING btree (author_user_id, published_at DESC) WHERE (published_at IS NOT NULL);


--
-- Name: idx_posts_category_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_category_published ON posts USING btree (category, published_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_posts_community_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_community_published ON posts USING btree (community_id, published_at DESC, created_at DESC) WHERE ((deleted_at IS NULL) AND (community_id IS NOT NULL));


--
-- Name: idx_posts_content_plain_text_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_content_plain_text_search ON posts USING gin (to_tsvector('simple'::regconfig, content_plain_text)) WHERE ((deleted_at IS NULL) AND (archived_at IS NULL) AND (status = 'PUBLISHED'::text) AND (moderation_status = ANY (ARRAY['NOT_REQUIRED'::text, 'APPROVED'::text])));


--
-- Name: idx_posts_feed_community_latest_keyset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_feed_community_latest_keyset ON posts USING btree (community_id, status, COALESCE(moderation_status, 'NOT_REQUIRED'::text), COALESCE(published_at, created_at) DESC, id DESC) WHERE ((deleted_at IS NULL) AND (archived_at IS NULL) AND (community_id IS NOT NULL));


--
-- Name: idx_posts_feed_community_latest_ready_keyset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_feed_community_latest_ready_keyset ON posts USING btree (community_id, status, COALESCE(moderation_status, 'NOT_REQUIRED'::text), media_status, COALESCE(published_at, created_at) DESC, id DESC) WHERE ((deleted_at IS NULL) AND (archived_at IS NULL) AND (media_status = 'READY'::text) AND (community_id IS NOT NULL));


--
-- Name: idx_posts_feed_latest_keyset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_feed_latest_keyset ON posts USING btree (status, COALESCE(moderation_status, 'NOT_REQUIRED'::text), COALESCE(published_at, created_at) DESC, id DESC) WHERE ((deleted_at IS NULL) AND (archived_at IS NULL));


--
-- Name: idx_posts_feed_latest_ready_keyset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_feed_latest_ready_keyset ON posts USING btree (status, COALESCE(moderation_status, 'NOT_REQUIRED'::text), media_status, COALESCE(published_at, created_at) DESC, id DESC) WHERE ((deleted_at IS NULL) AND (archived_at IS NULL) AND (media_status = 'READY'::text));


--
-- Name: idx_posts_owner_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_owner_workspace ON posts USING btree (author_user_id, status, updated_at DESC, id DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_posts_place_city_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_place_city_published ON posts USING btree (place_country_code, place_city_id, published_at DESC, created_at DESC) WHERE ((deleted_at IS NULL) AND (status = 'PUBLISHED'::text));


--
-- Name: idx_posts_popular; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_popular ON posts USING btree (status, view_count DESC, published_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_posts_public_expiry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_public_expiry ON posts USING btree (expires_at) WHERE ((deleted_at IS NULL) AND (archived_at IS NULL) AND (status = 'PUBLISHED'::text));


--
-- Name: idx_posts_public_feed_content_engine; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_public_feed_content_engine ON posts USING btree (format, category, place_country_code, place_city_id, published_at DESC, created_at DESC, id DESC) WHERE ((deleted_at IS NULL) AND (archived_at IS NULL) AND (status = 'PUBLISHED'::text) AND (moderation_status = ANY (ARRAY['NOT_REQUIRED'::text, 'APPROVED'::text])));


--
-- Name: idx_posts_published_latest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_published_latest ON posts USING btree (status, published_at DESC, created_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_posts_search_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_search_vector ON posts USING gin (search_vector);


--
-- Name: idx_story_seen_viewer_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_story_seen_viewer_seen_at ON story_seen USING btree (viewer_user_id, seen_at DESC);


--
-- Name: idx_story_likes_user_story; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_story_likes_user_story ON story_likes USING btree (user_id, story_id);


--
-- Name: idx_stories_active_latest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stories_active_latest ON stories USING btree (created_at DESC, id DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_stories_author_active_latest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stories_author_active_latest ON stories USING btree (author_user_id, created_at DESC, id DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_post_comment_likes_user_comment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_comment_likes_user_comment ON post_comment_likes USING btree (user_id, comment_id);


--
-- Name: idx_post_comments_author_post_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_comments_author_post_created ON post_comments USING btree (author_user_id, post_id, created_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_communities_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_communities_city ON communities USING btree (country_code, city_id, follower_count DESC) WHERE ((deleted_at IS NULL) AND (status = 'ACTIVE'::text));


--
-- Name: idx_communities_status_topic; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_communities_status_topic ON communities USING btree (status, topic, follower_count DESC, title) WHERE (deleted_at IS NULL);


--
-- Name: idx_community_blueprints_category_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_blueprints_category_status ON community_blueprints USING btree (category, status, key);


--
-- Name: idx_community_blueprint_geo_coverage_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_blueprint_geo_coverage_lookup ON community_blueprint_geo_coverage USING btree (country_code, city_id, scope_type, status, priority);


--
-- Name: uq_community_blueprint_geo_coverage_effective; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_community_blueprint_geo_coverage_effective ON community_blueprint_geo_coverage USING btree (blueprint_id, country_code, COALESCE(city_id, ''::text), scope_type);


--
-- Name: idx_community_geo_aliases_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_geo_aliases_parent ON community_geo_aliases USING btree (parent_country_code, parent_city_id);


--
-- Name: idx_community_geo_hubs_enabled_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_geo_hubs_enabled_priority ON community_geo_hubs USING btree (country_code, community_enabled, priority, city_id);


--
-- Name: idx_community_instances_geo_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_instances_geo_status ON community_instances USING btree (country_code, city_id, scope_type, status, member_count DESC);


--
-- Name: idx_community_instances_blueprint_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_instances_blueprint_status ON community_instances USING btree (blueprint_id, status, member_count DESC);


--
-- Name: idx_posts_community_instance_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_community_instance_published ON posts USING btree (community_instance_id, published_at DESC, created_at DESC) WHERE ((deleted_at IS NULL) AND (community_instance_id IS NOT NULL));


--
-- Name: idx_posts_profile_kind_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_profile_kind_status ON posts USING btree (post_profile_key, post_kind, status, updated_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_community_member_role_changes_actor_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_member_role_changes_actor_created ON community_member_role_changes USING btree (community_id, actor_user_id, created_at DESC);


--
-- Name: idx_community_member_role_changes_community_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_member_role_changes_community_created ON community_member_role_changes USING btree (community_id, created_at DESC);


--
-- Name: idx_community_member_role_changes_target_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_member_role_changes_target_created ON community_member_role_changes USING btree (community_id, target_user_id, created_at DESC);


--
-- Name: idx_community_member_status_changes_actor_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_member_status_changes_actor_created ON community_member_status_changes USING btree (community_id, actor_user_id, created_at DESC);


--
-- Name: idx_community_member_status_changes_community_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_member_status_changes_community_created ON community_member_status_changes USING btree (community_id, created_at DESC);


--
-- Name: idx_community_member_status_changes_target_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_member_status_changes_target_created ON community_member_status_changes USING btree (community_id, target_user_id, created_at DESC);


--
-- Name: idx_community_memberships_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_memberships_user_status ON community_memberships USING btree (user_id, status, updated_at DESC);


--
-- Name: idx_community_memberships_user_status_community; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_memberships_user_status_community ON community_memberships USING btree (user_id, status, community_id);


--
-- Name: idx_post_community_moderation_decisions_community_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_community_moderation_decisions_community_created ON post_community_moderation_decisions USING btree (community_id, created_at DESC);


--
-- Name: idx_post_community_moderation_decisions_moderator_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_community_moderation_decisions_moderator_created ON post_community_moderation_decisions USING btree (moderator_user_id, created_at DESC);


--
-- Name: idx_post_community_moderation_decisions_post_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_community_moderation_decisions_post_created ON post_community_moderation_decisions USING btree (post_id, created_at DESC);


--
-- Name: idx_community_reports_community_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_reports_community_status_created ON community_reports USING btree (community_id, status, created_at DESC);


--
-- Name: idx_community_reports_reporter_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_community_reports_reporter_created ON community_reports USING btree (reporter_user_id, created_at DESC);


--
-- Name: idx_post_feed_events_post_type_received; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_events_post_type_received ON post_feed_events USING btree (post_id, event_type, received_at DESC) WHERE (post_id IS NOT NULL);


--
-- Name: idx_post_feed_events_surface_type_received; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_events_surface_type_received ON post_feed_events USING btree (surface, event_type, received_at DESC);


--
-- Name: idx_post_feed_events_viewer_received; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_events_viewer_received ON post_feed_events USING btree (viewer_user_id, received_at DESC) WHERE (viewer_user_id IS NOT NULL);


--
-- Name: idx_post_feed_events_viewer_post_hide; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_events_viewer_post_hide ON post_feed_events USING btree (viewer_user_id, post_id) WHERE ((event_type = ANY (ARRAY['hide'::text, 'report'::text])) AND (viewer_user_id IS NOT NULL) AND (post_id IS NOT NULL));


--
-- Name: idx_post_feed_events_viewer_post_negative; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_events_viewer_post_negative ON post_feed_events USING btree (viewer_user_id, post_id, received_at DESC) WHERE ((event_type = ANY (ARRAY['not_interested'::text, 'report'::text])) AND (viewer_user_id IS NOT NULL) AND (post_id IS NOT NULL));


--
-- Name: idx_post_feed_items_author_latest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_items_author_latest ON post_feed_items USING btree (author_user_id, rank_published_at DESC) WHERE (is_visible = true);


--
-- Name: idx_post_feed_items_community_latest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_items_community_latest ON post_feed_items USING btree (community_id, rank_published_at DESC, post_id DESC) WHERE ((is_visible = true) AND (community_id IS NOT NULL));


--
-- Name: idx_post_feed_items_latest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_items_latest ON post_feed_items USING btree (rank_published_at DESC, post_id DESC) WHERE (is_visible = true);


--
-- Name: idx_post_feed_projection_outbox_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_projection_outbox_due ON post_feed_projection_outbox USING btree (status, next_attempt_at, created_at) WHERE (status = 'PENDING'::text);


--
-- Name: idx_post_feed_projection_outbox_post_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_projection_outbox_post_created ON post_feed_projection_outbox USING btree (post_id, created_at DESC);


--
-- Name: idx_post_activity_intents_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_activity_intents_due ON post_activity_intents USING btree (status, next_attempt_at, created_at) WHERE (status = 'PENDING'::text);


--
-- Name: idx_post_activity_intents_post_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_activity_intents_post_created ON post_activity_intents USING btree (post_id, created_at DESC);


--
-- Name: idx_post_feed_user_interests_entity_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_user_interests_entity_score ON post_feed_user_interests USING btree (entity_type, score DESC, last_event_at DESC);


--
-- Name: idx_post_feed_user_interests_viewer_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_user_interests_viewer_score ON post_feed_user_interests USING btree (viewer_user_id, score DESC, last_event_at DESC);


--
-- Name: idx_post_feed_social_edges_viewer_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_social_edges_viewer_type ON post_feed_social_edges USING btree (viewer_user_id, edge_type, active, target_user_id);


--
-- Name: idx_post_feed_social_edges_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_feed_social_edges_target ON post_feed_social_edges USING btree (target_user_id, edge_type, active, viewer_user_id);


--
-- Name: idx_post_media_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_media_file_id ON post_media USING btree (file_id);


--
-- Name: idx_post_media_processing_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_media_processing_status ON post_media USING btree (processing_status, updated_at DESC);


--
-- Name: idx_post_media_post_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_post_media_post_position ON post_media USING btree (post_id, "position");


--
-- Name: idx_post_moderation_outbox_actor_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_moderation_outbox_actor_created ON post_moderation_outbox USING btree (actor_user_id, created_at DESC);


--
-- Name: idx_post_moderation_outbox_aggregate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_moderation_outbox_aggregate ON post_moderation_outbox USING btree (aggregate_type, aggregate_id, created_at DESC);


--
-- Name: idx_post_moderation_outbox_community_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_moderation_outbox_community_created ON post_moderation_outbox USING btree (community_id, created_at DESC) WHERE (community_id IS NOT NULL);


--
-- Name: idx_post_moderation_outbox_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_moderation_outbox_due ON post_moderation_outbox USING btree (status, next_attempt_at, created_at) WHERE (status = 'PENDING'::text);


--
-- Name: idx_post_reports_community_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reports_community_status_created ON post_reports USING btree (community_id, status, created_at DESC) WHERE (community_id IS NOT NULL);


--
-- Name: idx_post_reports_reporter_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reports_reporter_created ON post_reports USING btree (reporter_user_id, created_at DESC);


--
-- Name: idx_post_reports_post_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reports_post_status ON post_reports USING btree (post_id, status);


--
-- Name: idx_post_reports_post_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_reports_post_created ON post_reports USING btree (post_id, created_at DESC);


--
-- Name: idx_post_seen_post_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_seen_post_seen_at ON post_seen USING btree (post_id, seen_at DESC);


--
-- Name: idx_post_seen_viewer_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_post_seen_viewer_seen_at ON post_seen USING btree (viewer_user_id, seen_at DESC);


--
-- Name: community_reports_open_report_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX community_reports_open_report_unique ON community_reports USING btree (community_id, reporter_user_id) WHERE (status = 'OPEN'::text);


--
-- Name: post_feed_events_event_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_feed_events_event_id_unique ON post_feed_events USING btree (event_id);


--
-- Name: post_reports_open_report_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_reports_open_report_unique ON post_reports USING btree (post_id, reporter_user_id) WHERE (status = 'OPEN'::text);


--
-- Name: posts trg_posts_search_vector_refresh; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_posts_search_vector_refresh BEFORE INSERT OR UPDATE OF title, excerpt, content, place_name, tags ON posts FOR EACH ROW EXECUTE FUNCTION posts_search_vector_refresh();


--
-- Name: posts posts_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE SET NULL;


--
-- Name: community_instances community_instances_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_instances
    ADD CONSTRAINT community_instances_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE SET NULL;


--
-- Name: posts posts_community_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_community_instance_id_fkey FOREIGN KEY (community_instance_id) REFERENCES community_instances(id) ON DELETE SET NULL;


--
-- Name: posts posts_post_profile_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_post_profile_key_fkey FOREIGN KEY (post_profile_key) REFERENCES community_post_profiles(key);


--
-- Name: community_geo_aliases community_geo_aliases_city_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_geo_aliases
    ADD CONSTRAINT community_geo_aliases_city_fkey FOREIGN KEY (country_code, city_id) REFERENCES community_geo_hubs(country_code, city_id) ON DELETE CASCADE;


--
-- Name: community_geo_aliases community_geo_aliases_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_geo_aliases
    ADD CONSTRAINT community_geo_aliases_parent_fkey FOREIGN KEY (parent_country_code, parent_city_id) REFERENCES community_geo_hubs(country_code, city_id) ON DELETE CASCADE;


--
-- Name: community_geo_hubs community_geo_hubs_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_geo_hubs
    ADD CONSTRAINT community_geo_hubs_parent_fkey FOREIGN KEY (parent_country_code, parent_city_id) REFERENCES community_geo_hubs(country_code, city_id) ON DELETE SET NULL;


--
-- Name: story_seen story_seen_story_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_seen
    ADD CONSTRAINT story_seen_story_id_fkey FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE;


--
-- Name: story_likes story_likes_story_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_likes
    ADD CONSTRAINT story_likes_story_id_fkey FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE;


--
-- Name: post_comment_likes post_comment_likes_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_comment_likes
    ADD CONSTRAINT post_comment_likes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES post_comments(id) ON DELETE CASCADE;


--
-- Name: post_comments post_comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_comments
    ADD CONSTRAINT post_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: community_member_role_changes community_member_role_changes_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_member_role_changes
    ADD CONSTRAINT community_member_role_changes_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;


--
-- Name: community_member_status_changes community_member_status_changes_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_member_status_changes
    ADD CONSTRAINT community_member_status_changes_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;


--
-- Name: community_memberships community_memberships_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_memberships
    ADD CONSTRAINT community_memberships_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;


--
-- Name: post_community_moderation_decisions post_community_moderation_decisions_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_community_moderation_decisions
    ADD CONSTRAINT post_community_moderation_decisions_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;


--
-- Name: post_community_moderation_decisions post_community_moderation_decisions_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_community_moderation_decisions
    ADD CONSTRAINT post_community_moderation_decisions_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: community_reports community_reports_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY community_reports
    ADD CONSTRAINT community_reports_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;


--
-- Name: post_feed_events post_feed_events_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_events
    ADD CONSTRAINT post_feed_events_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE SET NULL;


--
-- Name: post_feed_events post_feed_events_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_events
    ADD CONSTRAINT post_feed_events_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE SET NULL;


--
-- Name: post_feed_items post_feed_items_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_items
    ADD CONSTRAINT post_feed_items_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE SET NULL;


--
-- Name: post_feed_items post_feed_items_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_items
    ADD CONSTRAINT post_feed_items_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: post_feed_projection_outbox post_feed_projection_outbox_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_feed_projection_outbox
    ADD CONSTRAINT post_feed_projection_outbox_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: post_activity_intents post_activity_intents_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_activity_intents
    ADD CONSTRAINT post_activity_intents_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE SET NULL;


--
-- Name: post_activity_intents post_activity_intents_community_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_activity_intents
    ADD CONSTRAINT post_activity_intents_community_instance_id_fkey FOREIGN KEY (community_instance_id) REFERENCES community_instances(id) ON DELETE SET NULL;


--
-- Name: post_activity_intents post_activity_intents_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_activity_intents
    ADD CONSTRAINT post_activity_intents_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: post_likes post_likes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_likes
    ADD CONSTRAINT post_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: post_media post_media_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_media
    ADD CONSTRAINT post_media_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: post_moderation_outbox post_moderation_outbox_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_moderation_outbox
    ADD CONSTRAINT post_moderation_outbox_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE SET NULL;


--
-- Name: post_moderation_outbox post_moderation_outbox_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_moderation_outbox
    ADD CONSTRAINT post_moderation_outbox_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE SET NULL;


--
-- Name: post_reports post_reports_community_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_reports
    ADD CONSTRAINT post_reports_community_id_fkey FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE SET NULL;


--
-- Name: post_reports post_reports_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_reports
    ADD CONSTRAINT post_reports_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: post_seen post_seen_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_seen
    ADD CONSTRAINT post_seen_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- Name: post_view_sketches post_view_sketches_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_view_sketches
    ADD CONSTRAINT post_view_sketches_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--
