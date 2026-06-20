package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func (r *PGPostRepository) ListFeedPosts(ctx context.Context, filter model.PostListFilter) ([]*model.Post, error) {
	limit := filter.Limit
	if limit <= 0 {
		limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	args := make([]any, 0, 10)
	clauses := []string{"fi.is_visible = TRUE", "(s.expires_at IS NULL OR s.expires_at > NOW())"}
	if filter.OnlyExpiring {
		clauses = append(clauses, "s.expires_at IS NOT NULL")
	}
	if filter.ExcludeExpiring {
		clauses = append(clauses, "s.expires_at IS NULL")
	}
	policy := feedRankingPolicyWithOverride(r.feedRankingPolicy, filter.FeedRankingPolicyOverride)
	viewerUserIDPos := 0
	effectiveCommunityIDExpression := "COALESCE(fi.community_id, s.community_id, ci.community_id)"
	if len(filter.CommunityIDs) > 0 {
		args = append(args, filter.CommunityIDs)
		clauses = append(clauses, fmt.Sprintf("%s = ANY($%d)", effectiveCommunityIDExpression, len(args)))
	}
	feedRankJoins := ""
	if filter.ViewerUserID != nil && *filter.ViewerUserID != uuid.Nil {
		args = append(args, *filter.ViewerUserID)
		viewerUserIDPos = len(args)
		clauses = append(clauses, fmt.Sprintf(`
			NOT EXISTS (
				SELECT 1
				FROM post_feed_events hidden
				WHERE hidden.viewer_user_id = $%d
				  AND hidden.post_id = fi.post_id
				  AND hidden.event_type IN ('hide', 'report')
			)
			AND NOT EXISTS (
				SELECT 1
				FROM community_memberships muted_community
				WHERE muted_community.community_id = %s
				  AND muted_community.user_id = $%d
				  AND muted_community.status = 'MUTED'
			)
		`, viewerUserIDPos, effectiveCommunityIDExpression, viewerUserIDPos))
		feedRankJoins = policy.feedRankJoinsExpression(viewerUserIDPos)
	}
	currentCityIDPos := 0
	if currentCityID := strings.TrimSpace(filter.CurrentCityID); currentCityID != "" {
		args = append(args, currentCityID)
		currentCityIDPos = len(args)
	}
	currentCountryCodePos := 0
	if currentCountryCode := strings.ToUpper(strings.TrimSpace(filter.CurrentCountryCode)); currentCountryCode != "" {
		args = append(args, currentCountryCode)
		currentCountryCodePos = len(args)
	}
	feedRankedAtExpression := "fi.rank_published_at"
	if viewerUserIDPos > 0 || currentCityIDPos > 0 || currentCountryCodePos > 0 {
		feedRankedAtExpression = policy.viewerRankedAtExpression(viewerUserIDPos, currentCityIDPos, currentCountryCodePos)
	}
	if filter.FollowedByUserID != nil && *filter.FollowedByUserID != uuid.Nil {
		args = append(args, *filter.FollowedByUserID)
		userIDPos := len(args)
		clauses = append(clauses, fmt.Sprintf(`
			EXISTS (
				SELECT 1
				FROM community_memberships m
				WHERE m.community_id = %s
				  AND m.user_id = $%d
				  AND m.status = 'ACTIVE'
			)
		`, effectiveCommunityIDExpression, userIDPos))
	}
	if filter.ExcludeFollowedByUserID != nil && *filter.ExcludeFollowedByUserID != uuid.Nil {
		args = append(args, *filter.ExcludeFollowedByUserID)
		userIDPos := len(args)
		clauses = append(clauses, fmt.Sprintf(`
			NOT EXISTS (
				SELECT 1
				FROM community_memberships m
				WHERE m.community_id = %s
				  AND m.user_id = $%d
				  AND m.status = 'ACTIVE'
			)
		`, effectiveCommunityIDExpression, userIDPos))
	}
	switch strings.TrimSpace(filter.CandidateSource) {
	case model.PostCandidateSourceSocial:
		if viewerUserIDPos == 0 {
			clauses = append(clauses, "FALSE")
			break
		}
		clauses = append(clauses, fmt.Sprintf(`
			EXISTS (
				SELECT 1
				FROM post_feed_social_edges source_social
				WHERE source_social.viewer_user_id = $%d
				  AND source_social.target_user_id = s.author_user_id
				  AND source_social.edge_type IN ('friend', 'following')
				  AND source_social.active = true
			)
		`, viewerUserIDPos))
	case model.PostCandidateSourceSystem:
		clauses = append(clauses, `
			s.post_profile_key = 'article_v1'
			AND EXISTS (
				SELECT 1
				FROM unnest(COALESCE(s.tags, ARRAY[]::text[])) AS system_tag(tag)
				WHERE lower(system_tag.tag) = ANY(ARRAY['official_updates', 'travel_alerts', 'local_news'])
			)
		`)
	case model.PostCandidateSourceGeo:
		geoClauses := make([]string, 0, 2)
		if currentCityIDPos > 0 {
			geoClauses = append(geoClauses, fmt.Sprintf("LOWER(COALESCE(s.place_city_id, ci.city_id, '')) = LOWER($%d)", currentCityIDPos))
		}
		if currentCountryCodePos > 0 {
			geoClauses = append(geoClauses, fmt.Sprintf("UPPER(COALESCE(s.place_country_code, ci.country_code, '')) = UPPER($%d)", currentCountryCodePos))
		}
		if len(geoClauses) == 0 {
			clauses = append(clauses, "FALSE")
		} else {
			clauses = append(clauses, "("+strings.Join(geoClauses, " OR ")+")")
		}
	case model.PostCandidateSourceInterest:
		if viewerUserIDPos == 0 {
			clauses = append(clauses, "FALSE")
			break
		}
		clauses = append(clauses, fmt.Sprintf(`
			EXISTS (
				SELECT 1
				FROM post_feed_user_interests source_interest
				WHERE source_interest.viewer_user_id = $%d
				  AND source_interest.score > 0
				  AND source_interest.updated_at < NOW() - %s
				  AND (
					(source_interest.entity_type = 'post' AND source_interest.entity_id = fi.post_id::text)
					OR (source_interest.entity_type = 'community' AND source_interest.entity_id = %s::text)
					OR (source_interest.entity_type = 'post_profile' AND source_interest.entity_id = lower(s.post_profile_key))
					OR (source_interest.entity_type = 'author' AND source_interest.entity_id = s.author_user_id::text)
					OR (source_interest.entity_type = 'city' AND source_interest.entity_id = lower(COALESCE(s.place_city_id, ci.city_id, '')))
					OR (source_interest.entity_type = 'country' AND source_interest.entity_id = lower(COALESCE(s.place_country_code, ci.country_code, '')))
					OR (source_interest.entity_type = 'category' AND source_interest.entity_id = lower(s.category))
					OR (
						source_interest.entity_type = 'tag'
						AND source_interest.entity_id IN (
							SELECT lower(post_tag.tag)
							FROM unnest(COALESCE(s.tags, ARRAY[]::text[])) AS post_tag(tag)
						)
					)
				  )
			)
			AND NOT EXISTS (
				SELECT 1
				FROM post_feed_user_interests negative_source_interest
				WHERE negative_source_interest.viewer_user_id = $%d
				  AND negative_source_interest.score < 0
				  AND negative_source_interest.last_event_at >= NOW() - %s
				  AND (
					(negative_source_interest.entity_type = 'post' AND negative_source_interest.entity_id = fi.post_id::text)
					OR (negative_source_interest.entity_type = 'community' AND negative_source_interest.entity_id = %s::text)
					OR (negative_source_interest.entity_type = 'post_profile' AND negative_source_interest.entity_id = lower(s.post_profile_key))
					OR (negative_source_interest.entity_type = 'author' AND negative_source_interest.entity_id = s.author_user_id::text)
					OR (negative_source_interest.entity_type = 'city' AND negative_source_interest.entity_id = lower(COALESCE(s.place_city_id, ci.city_id, '')))
					OR (negative_source_interest.entity_type = 'country' AND negative_source_interest.entity_id = lower(COALESCE(s.place_country_code, ci.country_code, '')))
					OR (negative_source_interest.entity_type = 'category' AND negative_source_interest.entity_id = lower(s.category))
					OR (
						negative_source_interest.entity_type = 'tag'
						AND negative_source_interest.entity_id IN (
							SELECT lower(post_tag.tag)
							FROM unnest(COALESCE(s.tags, ARRAY[]::text[])) AS post_tag(tag)
						)
					)
				  )
			)
		`, viewerUserIDPos, policy.durationSQL(policy.InterestFreshnessDelay), effectiveCommunityIDExpression, viewerUserIDPos, policy.durationSQL(policy.DirectNegativeFeedbackDecayWindow), effectiveCommunityIDExpression))
	case model.PostCandidateSourceColdStart:
		geoClauses := make([]string, 0, 2)
		if currentCityIDPos > 0 {
			geoClauses = append(geoClauses, fmt.Sprintf("LOWER(COALESCE(s.place_city_id, ci.city_id, '')) = LOWER($%d)", currentCityIDPos))
		}
		if currentCountryCodePos > 0 {
			geoClauses = append(geoClauses, fmt.Sprintf("UPPER(COALESCE(s.place_country_code, ci.country_code, '')) = UPPER($%d)", currentCountryCodePos))
		}
		if viewerUserIDPos > 0 {
			clauses = append(clauses, fmt.Sprintf(`
				NOT EXISTS (
					SELECT 1
					FROM post_feed_user_interests cold_start_source_interest
					WHERE cold_start_source_interest.viewer_user_id = $%d
					  AND cold_start_source_interest.score > 0
					  AND cold_start_source_interest.updated_at < NOW() - %s
				)
			`, viewerUserIDPos, policy.durationSQL(policy.InterestFreshnessDelay)))
		}
		if len(geoClauses) > 0 {
			clauses = append(clauses, "("+strings.Join(geoClauses, " OR ")+")")
		}
	}
	if filter.FeedCursorPublishedAt != nil && filter.FeedCursorPostID != nil {
		args = append(args, filter.FeedCursorPublishedAt.UTC(), *filter.FeedCursorPostID)
		publishedAtPos := len(args) - 1
		postIDPos := len(args)
		clauses = append(clauses, fmt.Sprintf(`
			(
				%s < $%d
				OR (%s = $%d AND fi.post_id < $%d)
			)
		`, feedRankedAtExpression, publishedAtPos, feedRankedAtExpression, publishedAtPos, postIDPos))
	}

	args = append(args, limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		WITH ranked_feed_candidates AS (
			SELECT
				s.id, s.slug, s.author_user_id, s.title, s.excerpt, s.content, s.category, s.status,
				%s AS community_id, s.community_instance_id, s.post_kind, s.post_profile_key, s.post_profile_version,
				s.structured_data, s.moderation_mode, s.source_activity_id, s.activity_creation_status, s.activity_creation_error,
				s.cover_file_id, s.place_name, s.place_country_code, s.place_city_id, s.tags,
				s.view_count, s.like_count, s.comment_count, s.share_count, s.published_at, s.expires_at,
				s.created_at, s.updated_at, s.deleted_at,
				s.format, s.content_schema_version, s.content_blocks, s.content_plain_text,
				s.revision, s.last_autosaved_at, s.archived_at, s.moderation_status, s.media_status,
				%s AS feed_ranked_at,
				ROW_NUMBER() OVER (PARTITION BY %s ORDER BY %s DESC, fi.post_id DESC) AS community_row_number,
				ROW_NUMBER() OVER (PARTITION BY s.category ORDER BY %s DESC, fi.post_id DESC) AS category_row_number,
				ROW_NUMBER() OVER (PARTITION BY s.author_user_id ORDER BY %s DESC, fi.post_id DESC) AS author_row_number,
				ROW_NUMBER() OVER (PARTITION BY s.post_profile_key ORDER BY %s DESC, fi.post_id DESC) AS profile_row_number
			FROM post_feed_items fi
			JOIN posts s ON s.id = fi.post_id
			LEFT JOIN community_instances ci ON ci.id = s.community_instance_id
			%s
			WHERE %s
		)
			SELECT
				id, slug, author_user_id, title, excerpt, content, category, status,
				community_id, community_instance_id, post_kind, post_profile_key, post_profile_version,
				structured_data, moderation_mode, source_activity_id, activity_creation_status, activity_creation_error,
				cover_file_id, place_name, place_country_code, place_city_id, tags,
				view_count, like_count, comment_count, share_count, published_at, expires_at,
			created_at, updated_at, deleted_at,
			format, content_schema_version, content_blocks, content_plain_text,
			revision, last_autosaved_at, archived_at, moderation_status, media_status,
			feed_ranked_at
		FROM ranked_feed_candidates
		WHERE (community_id IS NULL OR community_row_number <= %d)
		  AND category_row_number <= %d
		  AND author_row_number <= %d
		  AND profile_row_number <= %d
		ORDER BY feed_ranked_at DESC, id DESC
		LIMIT $%d OFFSET $%d
	`, effectiveCommunityIDExpression, feedRankedAtExpression, effectiveCommunityIDExpression, feedRankedAtExpression, feedRankedAtExpression, feedRankedAtExpression, feedRankedAtExpression, feedRankJoins, strings.Join(clauses, " AND "), policy.MaxPostsPerCommunityPerPage, policy.MaxPostsPerCategoryPerPage, policy.MaxPostsPerAuthorPerPage, policy.MaxPostsPerProfilePerPage, limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query feed posts: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Post, 0)
	for rows.Next() {
		var feedRankedAt time.Time
		item, scanErr := scanPost(feedPostScanner{
			scanner:      rows,
			feedRankedAt: &feedRankedAt,
		})
		if scanErr != nil {
			return nil, fmt.Errorf("scan feed post: %w", scanErr)
		}
		if !feedRankedAt.IsZero() {
			item.FeedRankedAt = &feedRankedAt
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

type feedPostScanner struct {
	scanner      interface{ Scan(dest ...any) error }
	feedRankedAt *time.Time
}

func (s feedPostScanner) Scan(dest ...any) error {
	return s.scanner.Scan(append(dest, s.feedRankedAt)...)
}

func (r *PGPostRepository) CreateFeedEvents(ctx context.Context, events []model.FeedEvent) error {
	if len(events) == 0 {
		return nil
	}

	const query = `
		WITH inserted_feed_event AS (
			INSERT INTO post_feed_events (
				id, event_id, viewer_user_id, event_type, surface, tab,
				block_id, block_type, post_id, community_id, rank,
				occurred_at, received_at, request_id, metadata
			) VALUES (
				$1, $2, $3, $4, $5, $6,
				$7, $8, $9, $10, $11,
				$12, $13, $14, $15
			)
			ON CONFLICT (event_id) DO NOTHING
			RETURNING viewer_user_id, event_type, post_id, occurred_at, received_at, metadata
		),
		interest_signal AS (
			SELECT
				viewer_user_id,
				event_type,
				post_id,
				COALESCE(
					NULLIF(metadata->>'entityType', ''),
					CASE WHEN post_id IS NOT NULL THEN 'post' ELSE NULL END
				) AS entity_type,
				COALESCE(NULLIF(metadata->>'entityId', ''), post_id::text) AS entity_id,
				COALESCE(NULLIF(metadata->>'entityId', ''), post_id::text, '') AS representative_id,
				CASE
					WHEN event_type = 'impression' THEN 0.0500
					WHEN event_type = 'click' AND metadata->>'action' = 'conversion' THEN 3.0000
					WHEN event_type = 'click' THEN 1.0000
					WHEN event_type = 'dwell' THEN 0.7000
					WHEN event_type = 'like' THEN 1.6000
					WHEN event_type = 'comment' THEN 2.2000
					WHEN event_type = 'share' THEN 2.0000
					WHEN event_type = 'subscribe' THEN 3.0000
					WHEN event_type = 'hide' THEN -4.0000
					WHEN event_type = 'not_interested' THEN -3.0000
					WHEN event_type = 'report' THEN -6.0000
					ELSE 0.0000
				END AS score,
				CASE WHEN event_type = 'impression' THEN 1 ELSE 0 END AS impression_count,
				CASE WHEN event_type = 'click' THEN 1 ELSE 0 END AS click_count,
				CASE WHEN event_type = 'click' AND metadata->>'action' = 'conversion' THEN 1 WHEN event_type = 'subscribe' THEN 1 ELSE 0 END AS conversion_count,
				CASE WHEN event_type IN ('hide', 'report') THEN 1 ELSE 0 END AS hide_count,
				CASE WHEN event_type = 'not_interested' THEN 1 ELSE 0 END AS not_interested_count,
				COALESCE(NULLIF(metadata->>'source', ''), '') AS source,
				COALESCE(occurred_at, received_at) AS last_event_at,
				metadata
			FROM inserted_feed_event
			WHERE viewer_user_id IS NOT NULL
		),
		derived_interest_signal AS (
			SELECT
				viewer_user_id,
				event_type,
				'city' AS entity_type,
				lower(NULLIF(metadata->>'cityId', '')) AS entity_id,
				representative_id,
				score * 0.45 AS score,
				impression_count,
				click_count,
				conversion_count,
				hide_count,
				not_interested_count,
				source,
				last_event_at,
				entity_type AS parent_entity_type,
				entity_id AS parent_entity_id
			FROM interest_signal
			WHERE NULLIF(metadata->>'cityId', '') IS NOT NULL

			UNION ALL

			SELECT
				viewer_user_id,
				event_type,
				'country' AS entity_type,
				lower(NULLIF(metadata->>'countryCode', '')) AS entity_id,
				representative_id,
				score * 0.25 AS score,
				impression_count,
				click_count,
				conversion_count,
				hide_count,
				not_interested_count,
				source,
				last_event_at,
				entity_type AS parent_entity_type,
				entity_id AS parent_entity_id
			FROM interest_signal
			WHERE NULLIF(metadata->>'countryCode', '') IS NOT NULL

			UNION ALL

			SELECT
				viewer_user_id,
				event_type,
				'community' AS entity_type,
				NULLIF(metadata->>'communityId', '') AS entity_id,
				representative_id,
				score * 0.60 AS score,
				impression_count,
				click_count,
				conversion_count,
				hide_count,
				not_interested_count,
				source,
				last_event_at,
				entity_type AS parent_entity_type,
				entity_id AS parent_entity_id
			FROM interest_signal
			WHERE NULLIF(metadata->>'communityId', '') IS NOT NULL

			UNION ALL

			SELECT
				viewer_user_id,
				event_type,
				'category' AS entity_type,
				lower(COALESCE(NULLIF(metadata->>'categorySlug', ''), NULLIF(metadata->>'category', ''))) AS entity_id,
				representative_id,
				score * 0.35 AS score,
				impression_count,
				click_count,
				conversion_count,
				hide_count,
				not_interested_count,
				source,
				last_event_at,
				entity_type AS parent_entity_type,
				entity_id AS parent_entity_id
			FROM interest_signal
			WHERE COALESCE(NULLIF(metadata->>'categorySlug', ''), NULLIF(metadata->>'category', '')) IS NOT NULL

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'post_profile' AS entity_type,
				lower(COALESCE(NULLIF(signal.metadata->>'postProfileKey', ''), NULLIF(profile_post.post_profile_key, ''))) AS entity_id,
				signal.representative_id,
				signal.score * 0.30 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			JOIN posts profile_post ON profile_post.id = signal.post_id
			WHERE COALESCE(NULLIF(signal.metadata->>'postProfileKey', ''), NULLIF(profile_post.post_profile_key, '')) IS NOT NULL

			UNION ALL

			SELECT
				viewer_user_id,
				event_type,
				'profile' AS entity_type,
				lower(COALESCE(NULLIF(metadata->>'profileUserId', ''), NULLIF(metadata->>'profileId', ''))) AS entity_id,
				representative_id,
				score * 0.65 AS score,
				impression_count,
				click_count,
				conversion_count,
				hide_count,
				not_interested_count,
				source,
				last_event_at,
				entity_type AS parent_entity_type,
				entity_id AS parent_entity_id
			FROM interest_signal
			WHERE COALESCE(NULLIF(metadata->>'profileUserId', ''), NULLIF(metadata->>'profileId', '')) IS NOT NULL

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'author' AS entity_type,
				event_post.author_user_id::text AS entity_id,
				signal.representative_id,
				signal.score * 0.55 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			JOIN posts event_post ON event_post.id = signal.post_id
			WHERE signal.post_id IS NOT NULL
			  AND event_post.author_user_id <> signal.viewer_user_id

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'tag' AS entity_type,
				lower(tag.value) AS entity_id,
				signal.representative_id,
				signal.score * 0.20 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			CROSS JOIN LATERAL jsonb_array_elements_text(signal.metadata->'tags') AS tag(value)
			WHERE jsonb_typeof(signal.metadata->'tags') = 'array'
			  AND trim(tag.value) <> ''

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'tag' AS entity_type,
				lower(tag.value) AS entity_id,
				signal.representative_id,
				signal.score * 0.20 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			CROSS JOIN LATERAL jsonb_array_elements_text(signal.metadata->'semanticTags') AS tag(value)
			WHERE jsonb_typeof(signal.metadata->'semanticTags') = 'array'
			  AND trim(tag.value) <> ''

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'tag' AS entity_type,
				lower(tag.value) AS entity_id,
				signal.representative_id,
				signal.score * 0.20 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			CROSS JOIN LATERAL jsonb_array_elements_text(signal.metadata->'interestTags') AS tag(value)
			WHERE jsonb_typeof(signal.metadata->'interestTags') = 'array'
			  AND trim(tag.value) <> ''

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'tag' AS entity_type,
				lower(tag.value) AS entity_id,
				signal.representative_id,
				signal.score * 0.20 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			CROSS JOIN LATERAL jsonb_array_elements_text(signal.metadata->'guideSpecialties') AS tag(value)
			WHERE jsonb_typeof(signal.metadata->'guideSpecialties') = 'array'
			  AND trim(tag.value) <> ''

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'tag' AS entity_type,
				lower(tag.value) AS entity_id,
				signal.representative_id,
				signal.score * 0.20 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			CROSS JOIN LATERAL jsonb_array_elements_text(signal.metadata->'postTags') AS tag(value)
			WHERE jsonb_typeof(signal.metadata->'postTags') = 'array'
			  AND trim(tag.value) <> ''

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'tag' AS entity_type,
				lower(tag.value) AS entity_id,
				signal.representative_id,
				signal.score * 0.20 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			CROSS JOIN LATERAL jsonb_array_elements_text(signal.metadata->'placeTags') AS tag(value)
			WHERE jsonb_typeof(signal.metadata->'placeTags') = 'array'
			  AND trim(tag.value) <> ''

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'tag' AS entity_type,
				lower(tag.value) AS entity_id,
				signal.representative_id,
				signal.score * 0.20 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			CROSS JOIN LATERAL jsonb_array_elements_text(signal.metadata->'seasonalTags') AS tag(value)
			WHERE jsonb_typeof(signal.metadata->'seasonalTags') = 'array'
			  AND trim(tag.value) <> ''

			UNION ALL

			SELECT
				signal.viewer_user_id,
				signal.event_type,
				'tag' AS entity_type,
				lower(tag.value) AS entity_id,
				signal.representative_id,
				signal.score * 0.20 AS score,
				signal.impression_count,
				signal.click_count,
				signal.conversion_count,
				signal.hide_count,
				signal.not_interested_count,
				signal.source,
				signal.last_event_at,
				signal.entity_type AS parent_entity_type,
				signal.entity_id AS parent_entity_id
			FROM interest_signal signal
			CROSS JOIN LATERAL jsonb_array_elements_text(signal.metadata->'localIntentTags') AS tag(value)
			WHERE jsonb_typeof(signal.metadata->'localIntentTags') = 'array'
			  AND trim(tag.value) <> ''
		),
		valid_interest_signal AS (
			SELECT
				viewer_user_id, event_type, entity_type, entity_id, representative_id, score,
				impression_count, click_count, conversion_count, hide_count,
				not_interested_count, source, last_event_at,
				'' AS parent_entity_type,
				'' AS parent_entity_id
			FROM interest_signal
			WHERE entity_type IN ('post', 'post_profile', 'community', 'activity', 'place', 'tour', 'guide', 'profile')
			  AND entity_id IS NOT NULL
			  AND entity_id <> ''

			UNION ALL

			SELECT
				viewer_user_id, event_type, entity_type, entity_id, representative_id, score,
				impression_count, click_count, conversion_count, hide_count,
				not_interested_count, source, last_event_at,
				parent_entity_type, parent_entity_id
			FROM derived_interest_signal
			WHERE entity_type IN ('city', 'country', 'community', 'category', 'tag', 'post_profile', 'profile', 'author')
			  AND entity_id IS NOT NULL
			  AND entity_id <> ''
		)
		INSERT INTO post_feed_user_interests (
			viewer_user_id, entity_type, entity_id, representative_id, score,
			impression_count, click_count, conversion_count, hide_count,
			not_interested_count, last_event_at, updated_at, metadata
		)
		SELECT
			viewer_user_id,
			entity_type,
			entity_id,
			representative_id,
			LEAST(100, GREATEST(-100, score)),
			impression_count,
			click_count,
			conversion_count,
			hide_count,
			not_interested_count,
			last_event_at,
			NOW(),
			jsonb_strip_nulls(jsonb_build_object(
				'source', NULLIF(source, ''),
				'lastEventType', NULLIF(event_type, ''),
				'parentEntityType', NULLIF(parent_entity_type, ''),
				'parentEntityId', NULLIF(parent_entity_id, ''),
				'rankingExperiment', NULLIF($16::text, '')
			))
		FROM valid_interest_signal
		ON CONFLICT (viewer_user_id, entity_type, entity_id) DO UPDATE
		SET representative_id = CASE
				WHEN EXCLUDED.representative_id <> '' THEN EXCLUDED.representative_id
				ELSE post_feed_user_interests.representative_id
			END,
		    score = LEAST(100, GREATEST(-100, post_feed_user_interests.score + EXCLUDED.score)),
		    impression_count = post_feed_user_interests.impression_count + EXCLUDED.impression_count,
		    click_count = post_feed_user_interests.click_count + EXCLUDED.click_count,
		    conversion_count = post_feed_user_interests.conversion_count + EXCLUDED.conversion_count,
		    hide_count = post_feed_user_interests.hide_count + EXCLUDED.hide_count,
		    not_interested_count = post_feed_user_interests.not_interested_count + EXCLUDED.not_interested_count,
		    last_event_at = GREATEST(post_feed_user_interests.last_event_at, EXCLUDED.last_event_at),
		    updated_at = NOW(),
		    metadata = post_feed_user_interests.metadata || EXCLUDED.metadata
	`

	var batch pgx.Batch
	rankingExperiment := r.feedRankingPolicy.normalized().ExperimentKey
	for _, event := range events {
		metadata, err := json.Marshal(feedEventMetadataWithRankingExperiment(event.Metadata, rankingExperiment))
		if err != nil {
			return fmt.Errorf("marshal feed event metadata: %w", err)
		}
		id := event.ID
		if id == uuid.Nil {
			id = uuid.New()
		}
		batch.Queue(
			query,
			id,
			event.EventID,
			event.ViewerUserID,
			event.EventType,
			event.Surface,
			event.Tab,
			event.BlockID,
			event.BlockType,
			event.PostID,
			event.CommunityID,
			event.Rank,
			event.OccurredAt,
			event.ReceivedAt,
			event.RequestID,
			metadata,
			rankingExperiment,
		)
	}

	results := r.pool.SendBatch(ctx, &batch)
	defer results.Close()

	for range events {
		if _, err := results.Exec(); err != nil {
			return fmt.Errorf("send feed event batch: %w", err)
		}
	}
	return nil
}

func feedEventMetadataWithRankingExperiment(metadata map[string]any, experimentKey string) map[string]any {
	experimentKey = strings.TrimSpace(experimentKey)
	if experimentKey == "" {
		experimentKey = DefaultFeedRankingPolicy().ExperimentKey
	}
	enriched := make(map[string]any, len(metadata)+1)
	for key, value := range metadata {
		enriched[key] = value
	}
	if feedEventMetadataString(enriched["rankingExperiment"]) == "" {
		enriched["rankingExperiment"] = experimentKey
	}
	return enriched
}

func feedEventMetadataString(value any) string {
	text, ok := value.(string)
	if !ok {
		return ""
	}
	return strings.TrimSpace(text)
}

func (r *PGPostRepository) ListFeedUserInterests(ctx context.Context, filter model.FeedUserInterestListFilter) ([]model.FeedUserInterest, error) {
	if filter.ViewerUserID == uuid.Nil {
		return []model.FeedUserInterest{}, nil
	}

	limit := filter.Limit
	if limit <= 0 || limit > 200 {
		limit = 50
	}

	args := []any{filter.ViewerUserID}
	clauses := []string{"viewer_user_id = $1"}
	if len(filter.EntityTypes) > 0 {
		args = append(args, filter.EntityTypes)
		clauses = append(clauses, fmt.Sprintf("entity_type = ANY($%d)", len(args)))
	}

	args = append(args, limit)
	limitPos := len(args)
	query := fmt.Sprintf(`
		SELECT
			viewer_user_id, entity_type, entity_id, representative_id, score,
			impression_count, click_count, conversion_count, hide_count,
			not_interested_count, last_event_at, updated_at, metadata
		FROM post_feed_user_interests
		WHERE %s
		ORDER BY score DESC, last_event_at DESC
		LIMIT $%d
	`, strings.Join(clauses, " AND "), limitPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query feed user interests: %w", err)
	}
	defer rows.Close()

	interests := make([]model.FeedUserInterest, 0)
	for rows.Next() {
		interest, scanErr := scanFeedUserInterest(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan feed user interest: %w", scanErr)
		}
		interests = append(interests, interest)
	}
	return interests, rows.Err()
}

func (r *PGPostRepository) ListFeedQualityMetrics(ctx context.Context, filter model.FeedQualityMetricsFilter) ([]model.FeedQualityMetric, error) {
	limit := filter.Limit
	if limit <= 0 || limit > 200 {
		limit = 50
	}

	args := []any{filter.Since.UTC(), filter.Until.UTC()}
	clauses := []string{"post_feed_events.received_at >= $1", "post_feed_events.received_at < $2"}
	if strings.TrimSpace(filter.Surface) != "" {
		args = append(args, strings.TrimSpace(filter.Surface))
		clauses = append(clauses, fmt.Sprintf("post_feed_events.surface = $%d", len(args)))
	}
	args = append(args, limit)
	limitPos := len(args)

	query := fmt.Sprintf(`
		WITH grouped_events AS (
			SELECT
				post_feed_events.surface,
				post_feed_events.tab,
				post_feed_events.block_type,
				COALESCE(NULLIF(post_feed_events.metadata->>'rankingExperiment', ''), 'control') AS ranking_experiment,
				COALESCE(NULLIF(post_feed_events.metadata->>'candidateSource', ''), '') AS candidate_source,
				COALESCE(NULLIF(post_feed_events.metadata->>'postProfileKey', ''), NULLIF(quality_post.post_profile_key, ''), '') AS post_profile,
				COALESCE(COALESCE(post_feed_events.community_id, quality_post.community_id)::text, '') AS community_id,
				COALESCE(NULLIF(post_feed_events.metadata->>'action', ''), post_feed_events.event_type) AS action,
				COUNT(*) AS event_count,
				COUNT(DISTINCT post_feed_events.viewer_user_id) FILTER (WHERE post_feed_events.viewer_user_id IS NOT NULL) AS unique_viewers,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'impression') AS impression_count,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'click') AS click_count,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'dwell') AS dwell_count,
				COALESCE(ROUND(AVG(
					CASE
						WHEN post_feed_events.event_type = 'dwell'
						 AND post_feed_events.metadata->>'dwellMs' ~ '^[0-9]+$'
						THEN (post_feed_events.metadata->>'dwellMs')::numeric
						ELSE NULL
					END
				))::bigint, 0) AS avg_dwell_ms,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'like') AS like_count,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'comment') AS comment_count,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'share') AS share_count,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'subscribe') AS subscribe_count,
				COUNT(*) FILTER (WHERE (post_feed_events.event_type = 'click' AND post_feed_events.metadata->>'action' = 'conversion') OR post_feed_events.event_type = 'subscribe') AS conversion_count,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'hide') AS hide_count,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'not_interested') AS not_interested_count,
				COUNT(*) FILTER (WHERE post_feed_events.event_type = 'report') AS feed_report_count
			FROM post_feed_events
			LEFT JOIN posts quality_post ON quality_post.id = post_feed_events.post_id
			WHERE %s
			GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
		),
		report_metrics AS (
			SELECT
				post_feed_events.surface,
				post_feed_events.tab,
				post_feed_events.block_type,
				COALESCE(NULLIF(post_feed_events.metadata->>'rankingExperiment', ''), 'control') AS ranking_experiment,
				COALESCE(NULLIF(post_feed_events.metadata->>'candidateSource', ''), '') AS candidate_source,
				COALESCE(NULLIF(post_feed_events.metadata->>'postProfileKey', ''), NULLIF(quality_post.post_profile_key, ''), '') AS post_profile,
				COALESCE(COALESCE(post_feed_events.community_id, quality_post.community_id)::text, '') AS community_id,
				COALESCE(NULLIF(post_feed_events.metadata->>'action', ''), post_feed_events.event_type) AS action,
				COUNT(DISTINCT quality_report.id) AS report_count
			FROM post_feed_events
			LEFT JOIN posts quality_post ON quality_post.id = post_feed_events.post_id
			JOIN post_reports quality_report
			  ON quality_report.post_id = post_feed_events.post_id
			 AND quality_report.created_at >= $1
			 AND quality_report.created_at < $2
			WHERE %s
			  AND post_feed_events.event_type = 'impression'
			GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
		)
		SELECT
			grouped_events.surface,
			grouped_events.tab,
			grouped_events.block_type,
			grouped_events.ranking_experiment,
			grouped_events.candidate_source,
			grouped_events.post_profile,
			grouped_events.community_id,
			grouped_events.action,
			grouped_events.event_count,
			grouped_events.unique_viewers,
			grouped_events.impression_count,
			grouped_events.click_count,
			grouped_events.dwell_count,
			grouped_events.avg_dwell_ms,
			grouped_events.like_count,
			grouped_events.comment_count,
			grouped_events.share_count,
			grouped_events.subscribe_count,
			grouped_events.conversion_count,
			grouped_events.hide_count,
			grouped_events.not_interested_count,
			grouped_events.feed_report_count + COALESCE(report_metrics.report_count, 0) AS report_count
		FROM grouped_events
		LEFT JOIN report_metrics
		  ON report_metrics.surface = grouped_events.surface
		 AND report_metrics.tab = grouped_events.tab
		 AND report_metrics.block_type = grouped_events.block_type
		 AND report_metrics.ranking_experiment = grouped_events.ranking_experiment
		 AND report_metrics.candidate_source = grouped_events.candidate_source
		 AND COALESCE(report_metrics.post_profile, '') = COALESCE(grouped_events.post_profile, '')
		 AND report_metrics.community_id = grouped_events.community_id
		 AND report_metrics.action = grouped_events.action
		ORDER BY event_count DESC, conversion_count DESC, hide_count DESC, not_interested_count DESC, report_count DESC
		LIMIT $%d
	`, strings.Join(clauses, " AND "), strings.Join(clauses, " AND "), limitPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query feed quality metrics: %w", err)
	}
	defer rows.Close()

	metrics := make([]model.FeedQualityMetric, 0)
	for rows.Next() {
		var metric model.FeedQualityMetric
		if err := rows.Scan(
			&metric.Surface,
			&metric.Tab,
			&metric.BlockType,
			&metric.RankingExperiment,
			&metric.CandidateSource,
			&metric.PostProfile,
			&metric.CommunityID,
			&metric.Action,
			&metric.EventCount,
			&metric.UniqueViewers,
			&metric.ImpressionCount,
			&metric.ClickCount,
			&metric.DwellCount,
			&metric.AvgDwellMs,
			&metric.LikeCount,
			&metric.CommentCount,
			&metric.ShareCount,
			&metric.SubscribeCount,
			&metric.ConversionCount,
			&metric.HideCount,
			&metric.NotInterestedCount,
			&metric.ReportCount,
		); err != nil {
			return nil, fmt.Errorf("scan feed quality metric: %w", err)
		}
		metrics = append(metrics, metric)
	}
	return metrics, rows.Err()
}

func scanFeedUserInterest(scanner interface{ Scan(dest ...any) error }) (model.FeedUserInterest, error) {
	var interest model.FeedUserInterest
	var metadataBytes []byte
	if err := scanner.Scan(
		&interest.ViewerUserID,
		&interest.EntityType,
		&interest.EntityID,
		&interest.RepresentativeID,
		&interest.Score,
		&interest.ImpressionCount,
		&interest.ClickCount,
		&interest.ConversionCount,
		&interest.HideCount,
		&interest.NotInterestedCount,
		&interest.LastEventAt,
		&interest.UpdatedAt,
		&metadataBytes,
	); err != nil {
		return model.FeedUserInterest{}, err
	}
	if len(metadataBytes) > 0 {
		if err := json.Unmarshal(metadataBytes, &interest.Metadata); err != nil {
			return model.FeedUserInterest{}, fmt.Errorf("unmarshal feed user interest metadata: %w", err)
		}
	}
	if interest.Metadata == nil {
		interest.Metadata = map[string]any{}
	}
	return interest, nil
}

func syncPostFeedItemTx(ctx context.Context, tx pgx.Tx, post *model.Post) error {
	if post == nil || post.ID == uuid.Nil {
		return nil
	}
	if !post.IsPubliclyVisible() {
		return deletePostFeedItemTx(ctx, tx, post.ID)
	}
	return upsertPostFeedItemTx(ctx, tx, post)
}

func upsertPostFeedItemTx(ctx context.Context, tx pgx.Tx, post *model.Post) error {
	publishedAt := post.CreatedAt
	if post.PublishedAt != nil {
		publishedAt = post.PublishedAt.UTC()
	}
	if publishedAt.IsZero() {
		publishedAt = post.UpdatedAt.UTC()
	}
	if publishedAt.IsZero() {
		publishedAt = post.CreatedAt.UTC()
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO post_feed_items (
			post_id, author_user_id, community_id, is_visible,
			published_at, rank_published_at, post_revision, created_at, updated_at
		) VALUES (
			$1, $2, $3, TRUE,
			$4, $4, $5, $6, NOW()
		)
		ON CONFLICT (post_id) DO UPDATE
		SET author_user_id = EXCLUDED.author_user_id,
		    community_id = EXCLUDED.community_id,
		    is_visible = TRUE,
		    published_at = EXCLUDED.published_at,
		    rank_published_at = EXCLUDED.rank_published_at,
		    post_revision = EXCLUDED.post_revision,
		    updated_at = NOW()
	`, post.ID, post.AuthorUserID, post.CommunityID, publishedAt, post.Revision, post.CreatedAt); err != nil {
		return fmt.Errorf("upsert post feed item: %w", err)
	}
	return nil
}

func deletePostFeedItemTx(ctx context.Context, tx pgx.Tx, postID uuid.UUID) error {
	if postID == uuid.Nil {
		return nil
	}
	if _, err := tx.Exec(ctx, `DELETE FROM post_feed_items WHERE post_id = $1`, postID); err != nil {
		return fmt.Errorf("delete post feed item: %w", err)
	}
	return nil
}

func enqueuePostFeedProjectionForPostTx(ctx context.Context, tx pgx.Tx, post *model.Post) error {
	if post == nil || post.ID == uuid.Nil {
		return nil
	}
	if !post.IsPubliclyVisible() {
		return enqueuePostFeedProjectionDeleteTx(ctx, tx, post.ID, post.Revision, post.UpdatedAt)
	}

	return enqueuePostFeedProjectionTx(ctx, tx, model.PostFeedProjectionOutboxEvent{
		EventType:    model.PostFeedProjectionEventUpsert,
		PostID:       post.ID,
		PostRevision: post.Revision,
		Payload:      postFeedProjectionPayload(post, model.PostFeedProjectionEventUpsert),
		CreatedAt:    post.UpdatedAt,
	})
}

func enqueuePostFeedProjectionDeleteTx(ctx context.Context, tx pgx.Tx, postID uuid.UUID, postRevision int64, createdAt time.Time) error {
	if postID == uuid.Nil {
		return nil
	}
	return enqueuePostFeedProjectionTx(ctx, tx, model.PostFeedProjectionOutboxEvent{
		EventType:    model.PostFeedProjectionEventDelete,
		PostID:       postID,
		PostRevision: postRevision,
		CreatedAt:    createdAt,
	})
}

func postFeedProjectionPayload(post *model.Post, eventType string) []byte {
	if post == nil || post.ID == uuid.Nil {
		return nil
	}
	payload := map[string]any{
		"postId":       post.ID,
		"postRevision": post.Revision,
		"eventType":    eventType,
		"authorUserId": post.AuthorUserID,
		"category":     string(post.Category),
	}
	if post.CommunityID != nil && *post.CommunityID != uuid.Nil {
		payload["communityId"] = *post.CommunityID
	}
	encoded, err := json.Marshal(payload)
	if err != nil {
		return nil
	}
	return encoded
}

func enqueuePostFeedProjectionTx(ctx context.Context, tx pgx.Tx, event model.PostFeedProjectionOutboxEvent) error {
	if event.EventType == "" || event.PostID == uuid.Nil {
		return fmt.Errorf("post feed projection event is invalid")
	}
	if event.PostRevision <= 0 {
		event.PostRevision = 1
	}
	createdAt := event.CreatedAt
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}
	payload := event.Payload
	if len(payload) == 0 {
		encoded, err := json.Marshal(map[string]any{
			"postId":       event.PostID,
			"postRevision": event.PostRevision,
			"eventType":    event.EventType,
		})
		if err != nil {
			return fmt.Errorf("marshal post feed projection payload: %w", err)
		}
		payload = encoded
	}

	const query = `
		INSERT INTO post_feed_projection_outbox (
			id, event_type, post_id, post_revision, payload, status, next_attempt_at, created_at
		) VALUES (
			$1, $2, $3, $4, $5, 'PENDING', $6, $6
		)
		ON CONFLICT (post_id, post_revision, event_type) DO NOTHING
	`
	if _, err := tx.Exec(ctx, query, uuid.New(), event.EventType, event.PostID, event.PostRevision, payload, createdAt); err != nil {
		return fmt.Errorf("insert post feed projection outbox event: %w", err)
	}
	return nil
}

func (r *PGPostRepository) ListDuePostFeedProjectionEvents(
	ctx context.Context,
	limit int,
	now time.Time,
) ([]model.PostFeedProjectionOutboxEvent, error) {
	if limit <= 0 {
		limit = 50
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	rows, err := r.pool.Query(ctx, `
		WITH due AS (
			SELECT id
			FROM post_feed_projection_outbox
			WHERE status = 'PENDING'
			  AND next_attempt_at <= $1
			ORDER BY created_at ASC, id ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		UPDATE post_feed_projection_outbox AS outbox
		SET next_attempt_at = $1 + INTERVAL '30 seconds'
		FROM due
		WHERE outbox.id = due.id
		RETURNING outbox.id, outbox.event_type, outbox.post_id, outbox.post_revision,
		          outbox.payload, outbox.status, outbox.attempt_count, outbox.next_attempt_at,
		          outbox.last_error, outbox.created_at, outbox.delivered_at
	`, now, limit)
	if err != nil {
		return nil, fmt.Errorf("list due post feed projection outbox events: %w", err)
	}
	defer rows.Close()

	items := make([]model.PostFeedProjectionOutboxEvent, 0)
	for rows.Next() {
		item, scanErr := scanPostFeedProjectionOutboxEvent(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan post feed projection outbox event: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) ProjectPostFeedItem(ctx context.Context, event model.PostFeedProjectionOutboxEvent) (bool, error) {
	if event.PostID == uuid.Nil {
		return false, fmt.Errorf("post feed projection post id is required")
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, fmt.Errorf("begin post feed projection tx: %w", err)
	}
	defer tx.Rollback(ctx)

	switch event.EventType {
	case model.PostFeedProjectionEventDelete:
		if err = deletePostFeedItemTx(ctx, tx, event.PostID); err != nil {
			return false, err
		}
	case model.PostFeedProjectionEventUpsert:
		post, selectErr := selectPostForFeedProjectionTx(ctx, tx, event.PostID)
		if selectErr != nil {
			return false, selectErr
		}
		if post == nil {
			if err = deletePostFeedItemTx(ctx, tx, event.PostID); err != nil {
				return false, err
			}
			break
		}
		if err = syncPostFeedItemTx(ctx, tx, post); err != nil {
			return false, err
		}
	default:
		return false, fmt.Errorf("unsupported post feed projection event type: %s", event.EventType)
	}

	if err = tx.Commit(ctx); err != nil {
		return false, fmt.Errorf("commit post feed projection tx: %w", err)
	}
	return true, nil
}

func (r *PGPostRepository) MarkPostFeedProjectionOutboxDelivered(ctx context.Context, eventID uuid.UUID, deliveredAt time.Time) error {
	if deliveredAt.IsZero() {
		deliveredAt = time.Now().UTC()
	}
	if _, err := r.pool.Exec(ctx, `
		UPDATE post_feed_projection_outbox
		SET status = 'DELIVERED',
		    delivered_at = $2,
		    last_error = ''
		WHERE id = $1
		  AND status <> 'DELIVERED'
	`, eventID, deliveredAt); err != nil {
		return fmt.Errorf("mark post feed projection outbox delivered: %w", err)
	}
	return nil
}

func (r *PGPostRepository) MarkPostFeedProjectionOutboxFailed(ctx context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error {
	if nextAttemptAt.IsZero() {
		nextAttemptAt = time.Now().UTC().Add(time.Second)
	}
	if _, err := r.pool.Exec(ctx, `
		UPDATE post_feed_projection_outbox
		SET attempt_count = attempt_count + 1,
		    status = CASE WHEN attempt_count + 1 >= 20 THEN 'DEAD' ELSE 'PENDING' END,
		    last_error = $2,
		    next_attempt_at = $3
		WHERE id = $1
		  AND status = 'PENDING'
	`, eventID, strings.TrimSpace(reason), nextAttemptAt); err != nil {
		return fmt.Errorf("mark post feed projection outbox failed: %w", err)
	}
	return nil
}

func selectPostForFeedProjectionTx(ctx context.Context, tx pgx.Tx, postID uuid.UUID) (*model.Post, error) {
	row := tx.QueryRow(ctx, `
		SELECT
			id, slug, author_user_id, title, excerpt, content, category, status,
			community_id, community_instance_id, post_kind, post_profile_key, post_profile_version,
			structured_data, moderation_mode, source_activity_id, activity_creation_status, activity_creation_error,
			cover_file_id, place_name, place_country_code, place_city_id, tags, view_count,
			like_count, comment_count, share_count, published_at, expires_at, created_at, updated_at, deleted_at,
			format, content_schema_version, content_blocks, content_plain_text, revision,
			last_autosaved_at, archived_at, moderation_status, media_status
		FROM posts
		WHERE id = $1
		LIMIT 1
	`, postID)
	item, err := scanPost(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select post for feed projection: %w", err)
	}
	return item, nil
}

func scanPostFeedProjectionOutboxEvent(scanner interface{ Scan(dest ...any) error }) (model.PostFeedProjectionOutboxEvent, error) {
	var (
		item      model.PostFeedProjectionOutboxEvent
		statusRaw string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.EventType,
		&item.PostID,
		&item.PostRevision,
		&item.Payload,
		&statusRaw,
		&item.AttemptCount,
		&item.NextAttemptAt,
		&item.LastError,
		&item.CreatedAt,
		&item.DeliveredAt,
	); err != nil {
		return model.PostFeedProjectionOutboxEvent{}, err
	}
	item.Status = model.PostFeedProjectionOutboxStatus(statusRaw)
	return item, nil
}
