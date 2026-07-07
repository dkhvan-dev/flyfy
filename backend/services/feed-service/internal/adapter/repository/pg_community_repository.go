package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

const maxCommunityPlatformPaginationLimit = 500

func (r *PGPostRepository) ListCommunities(ctx context.Context, filter model.CommunityListFilter) ([]*model.Community, error) {
	args := make([]any, 0, 8)
	clauses := make([]string, 0, 8)

	if !filter.IncludeDeleted {
		clauses = append(clauses, "deleted_at IS NULL")
	}
	if filter.PublicOnly {
		clauses = append(clauses, "status = 'ACTIVE'", "visibility = 'PUBLIC'")
	}
	if topic := strings.ToUpper(strings.TrimSpace(filter.Topic)); topic != "" {
		args = append(args, topic)
		clauses = append(clauses, fmt.Sprintf("topic = $%d", len(args)))
	}
	if countryCode := strings.ToUpper(strings.TrimSpace(filter.CountryCode)); countryCode != "" {
		args = append(args, countryCode)
		clauses = append(clauses, fmt.Sprintf("country_code = $%d", len(args)))
	}
	if cityID := strings.TrimSpace(filter.CityID); cityID != "" {
		args = append(args, cityID)
		clauses = append(clauses, fmt.Sprintf("city_id = $%d", len(args)))
	}
	if search := strings.ToLower(strings.TrimSpace(filter.Search)); search != "" {
		args = append(args, "%"+search+"%")
		pos := len(args)
		clauses = append(clauses, fmt.Sprintf(`(
			LOWER(title) LIKE $%d OR
			LOWER(description) LIKE $%d OR
			LOWER(slug) LIKE $%d OR
			LOWER(topic) LIKE $%d
		)`, pos, pos, pos, pos))
	}
	if filter.OnlyFollowedByUserID != nil && *filter.OnlyFollowedByUserID != uuid.Nil {
		args = append(args, *filter.OnlyFollowedByUserID)
		clauses = append(clauses, fmt.Sprintf(`EXISTS (
			SELECT 1
			FROM community_memberships scm
			WHERE scm.community_id = communities.id
			  AND scm.user_id = $%d
			  AND scm.status = 'ACTIVE'
		)`, len(args)))
	} else if filter.ExcludeFollowedByUserID != nil && *filter.ExcludeFollowedByUserID != uuid.Nil {
		args = append(args, *filter.ExcludeFollowedByUserID)
		clauses = append(clauses, fmt.Sprintf(`NOT EXISTS (
			SELECT 1
			FROM community_memberships scm
			WHERE scm.community_id = communities.id
			  AND scm.user_id = $%d
			  AND scm.status = 'ACTIVE'
		)`, len(args)))
	}
	if filter.Limit <= 0 || filter.Limit > 50 {
		filter.Limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	args = append(args, filter.Limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT
			communities.id, slug, title, description, topic, city_id, country_code, language_code,
			avatar_file_id, cover_file_id, visibility, posting_policy, status,
			COALESCE(blueprint_config.default_post_profile_key, 'article_v1') AS default_post_profile_key,
			COALESCE(
				blueprint_config.allowed_post_profile_keys,
				ARRAY[COALESCE(blueprint_config.default_post_profile_key, 'article_v1')]::text[]
			) AS allowed_post_profile_keys,
			COALESCE(blueprint_config.enabled_tabs, ARRAY['posts']::text[]) AS enabled_tabs,
			follower_count, post_count, rules, title_i18n, description_i18n, rules_i18n,
			created_by_admin_id, created_at, updated_at, deleted_at
		FROM communities
		LEFT JOIN LATERAL (
			SELECT cb.default_post_profile_key, cb.allowed_post_profile_keys, cb.enabled_tabs
			FROM community_instances ci
			JOIN community_blueprints cb ON cb.id = ci.blueprint_id
			WHERE ci.community_id = communities.id
			  AND ci.status = 'ACTIVE'
			ORDER BY ci.updated_at DESC, ci.created_at DESC
			LIMIT 1
		) AS blueprint_config ON true
		WHERE %s
		ORDER BY follower_count DESC, title ASC
		LIMIT $%d OFFSET $%d
	`, communityWhereClause(clauses), limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query communities: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Community, 0)
	for rows.Next() {
		item, scanErr := scanCommunity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan community list: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func communityWhereClause(clauses []string) string {
	if len(clauses) == 0 {
		return "TRUE"
	}
	return strings.Join(clauses, " AND ")
}

func (r *PGPostRepository) CreateCommunity(ctx context.Context, community *model.Community) error {
	if community == nil || community.ID == uuid.Nil || strings.TrimSpace(community.Slug) == "" {
		return nil
	}
	titleI18n, err := json.Marshal(community.TitleI18n)
	if err != nil {
		return fmt.Errorf("marshal community title i18n: %w", err)
	}
	descriptionI18n, err := json.Marshal(community.DescriptionI18n)
	if err != nil {
		return fmt.Errorf("marshal community description i18n: %w", err)
	}
	rulesI18n, err := json.Marshal(community.RulesI18n)
	if err != nil {
		return fmt.Errorf("marshal community rules i18n: %w", err)
	}

	_, err = r.pool.Exec(
		ctx,
		`INSERT INTO communities (
			id, slug, title, title_i18n, description, description_i18n, topic,
			rules, rules_i18n, city_id, country_code, language_code,
			avatar_file_id, cover_file_id, visibility, posting_policy, status,
			follower_count, post_count, created_by_admin_id, created_at, updated_at
		)
		VALUES (
			$1, $2, $3, $4::jsonb, $5, $6::jsonb, $7,
			$8, $9::jsonb, $10, $11, $12,
			$13, $14, $15, $16, $17,
			$18, $19, $20, $21, $22
		)`,
		community.ID,
		strings.TrimSpace(community.Slug),
		strings.TrimSpace(community.Title),
		titleI18n,
		strings.TrimSpace(community.Description),
		descriptionI18n,
		strings.ToUpper(strings.TrimSpace(community.Topic)),
		normalizeCommunityRules(community.Rules),
		rulesI18n,
		community.CityID,
		community.CountryCode,
		community.LanguageCode,
		community.AvatarFileID,
		community.CoverFileID,
		string(community.Visibility),
		string(community.PostingPolicy),
		string(community.Status),
		community.FollowerCount,
		community.PostCount,
		community.CreatedByAdminID,
		community.CreatedAt,
		community.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert community: %w", err)
	}
	return nil
}

func (r *PGPostRepository) UpdateCommunity(ctx context.Context, community *model.Community) error {
	if community == nil || community.ID == uuid.Nil || strings.TrimSpace(community.Slug) == "" {
		return nil
	}
	titleI18n, err := json.Marshal(community.TitleI18n)
	if err != nil {
		return fmt.Errorf("marshal community title i18n: %w", err)
	}
	descriptionI18n, err := json.Marshal(community.DescriptionI18n)
	if err != nil {
		return fmt.Errorf("marshal community description i18n: %w", err)
	}
	rulesI18n, err := json.Marshal(community.RulesI18n)
	if err != nil {
		return fmt.Errorf("marshal community rules i18n: %w", err)
	}

	tag, err := r.pool.Exec(
		ctx,
		`UPDATE communities
		SET slug = $2,
		    title = $3,
		    title_i18n = $4::jsonb,
		    description = $5,
		    description_i18n = $6::jsonb,
		    topic = $7,
		    rules = $8,
		    rules_i18n = $9::jsonb,
		    city_id = $10,
		    country_code = $11,
		    language_code = $12,
		    avatar_file_id = $13,
		    cover_file_id = $14,
		    visibility = $15,
		    posting_policy = $16,
		    status = $17,
		    updated_at = $18
		WHERE id = $1 AND deleted_at IS NULL`,
		community.ID,
		strings.TrimSpace(community.Slug),
		strings.TrimSpace(community.Title),
		titleI18n,
		strings.TrimSpace(community.Description),
		descriptionI18n,
		strings.ToUpper(strings.TrimSpace(community.Topic)),
		normalizeCommunityRules(community.Rules),
		rulesI18n,
		community.CityID,
		community.CountryCode,
		community.LanguageCode,
		community.AvatarFileID,
		community.CoverFileID,
		string(community.Visibility),
		string(community.PostingPolicy),
		string(community.Status),
		community.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update community: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *PGPostRepository) GetCommunityByID(ctx context.Context, communityID uuid.UUID) (*model.Community, error) {
	const query = `
		SELECT
			communities.id, slug, title, description, topic, city_id, country_code, language_code,
			avatar_file_id, cover_file_id, visibility, posting_policy, status,
			COALESCE(blueprint_config.default_post_profile_key, 'article_v1') AS default_post_profile_key,
			COALESCE(
				blueprint_config.allowed_post_profile_keys,
				ARRAY[COALESCE(blueprint_config.default_post_profile_key, 'article_v1')]::text[]
			) AS allowed_post_profile_keys,
			COALESCE(blueprint_config.enabled_tabs, ARRAY['posts']::text[]) AS enabled_tabs,
			follower_count, post_count, rules, title_i18n, description_i18n, rules_i18n,
			created_by_admin_id, created_at, updated_at, deleted_at
		FROM communities
		LEFT JOIN LATERAL (
			SELECT cb.default_post_profile_key, cb.allowed_post_profile_keys, cb.enabled_tabs
			FROM community_instances ci
			JOIN community_blueprints cb ON cb.id = ci.blueprint_id
			WHERE ci.community_id = communities.id
			  AND ci.status = 'ACTIVE'
			ORDER BY ci.updated_at DESC, ci.created_at DESC
			LIMIT 1
		) AS blueprint_config ON true
		WHERE id = $1
		LIMIT 1
	`

	item, err := scanCommunity(r.pool.QueryRow(ctx, query, communityID))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select community by id: %w", err)
	}
	return item, nil
}

func (r *PGPostRepository) GetCommunityBySlug(ctx context.Context, slug string) (*model.Community, error) {
	const query = `
		SELECT
			communities.id, slug, title, description, topic, city_id, country_code, language_code,
			avatar_file_id, cover_file_id, visibility, posting_policy, status,
			COALESCE(blueprint_config.default_post_profile_key, 'article_v1') AS default_post_profile_key,
			COALESCE(
				blueprint_config.allowed_post_profile_keys,
				ARRAY[COALESCE(blueprint_config.default_post_profile_key, 'article_v1')]::text[]
			) AS allowed_post_profile_keys,
			COALESCE(blueprint_config.enabled_tabs, ARRAY['posts']::text[]) AS enabled_tabs,
			follower_count, post_count, rules, title_i18n, description_i18n, rules_i18n,
			created_by_admin_id, created_at, updated_at, deleted_at
		FROM communities
		LEFT JOIN LATERAL (
			SELECT cb.default_post_profile_key, cb.allowed_post_profile_keys, cb.enabled_tabs
			FROM community_instances ci
			JOIN community_blueprints cb ON cb.id = ci.blueprint_id
			WHERE ci.community_id = communities.id
			  AND ci.status = 'ACTIVE'
			ORDER BY ci.updated_at DESC, ci.created_at DESC
			LIMIT 1
		) AS blueprint_config ON true
		WHERE slug = $1 AND deleted_at IS NULL
		LIMIT 1
	`

	item, err := scanCommunity(r.pool.QueryRow(ctx, query, strings.TrimSpace(slug)))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select community by slug: %w", err)
	}
	return item, nil
}

func (r *PGPostRepository) ListCommunityPostProfiles(ctx context.Context, filter model.CommunityPostProfileListFilter) ([]*model.CommunityPostProfile, error) {
	args := make([]any, 0, 4)
	clauses := []string{"1=1"}
	if postKind := strings.ToUpper(strings.TrimSpace(filter.PostKind)); postKind != "" {
		args = append(args, postKind)
		clauses = append(clauses, fmt.Sprintf("post_kind = $%d", len(args)))
	}
	filter.Limit, filter.Offset = normalizeCommunityPlatformPagination(filter.Limit, filter.Offset)
	args = append(args, filter.Limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT key, version, post_kind, composer_preset, render_preset, schema_json,
		       validation_json, moderation_mode, activity_creation_mode, created_at, updated_at
		FROM community_post_profiles
		WHERE %s
		ORDER BY key ASC
		LIMIT $%d OFFSET $%d
	`, strings.Join(clauses, " AND "), limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query community post profiles: %w", err)
	}
	defer rows.Close()

	items := make([]*model.CommunityPostProfile, 0)
	for rows.Next() {
		item, scanErr := scanCommunityPostProfile(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan community post profile: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) ListCommunityBlueprints(ctx context.Context, filter model.CommunityBlueprintListFilter) ([]*model.CommunityBlueprint, error) {
	args := make([]any, 0, 8)
	clauses := []string{"1=1"}
	if category := strings.TrimSpace(filter.Category); category != "" {
		args = append(args, category)
		clauses = append(clauses, fmt.Sprintf("category = $%d", len(args)))
	}
	if postProfile := strings.TrimSpace(filter.PostProfile); postProfile != "" {
		args = append(args, postProfile)
		clauses = append(clauses, fmt.Sprintf("default_post_profile_key = $%d", len(args)))
	}
	if rolloutPolicy := strings.ToUpper(strings.TrimSpace(filter.RolloutPolicy)); rolloutPolicy != "" {
		args = append(args, rolloutPolicy)
		clauses = append(clauses, fmt.Sprintf("rollout_policy = $%d", len(args)))
	}
	if filter.Status != nil && filter.Status.IsValid() {
		args = append(args, string(*filter.Status))
		clauses = append(clauses, fmt.Sprintf("status = $%d", len(args)))
	}
	if search := strings.ToLower(strings.TrimSpace(filter.Search)); search != "" {
		args = append(args, "%"+search+"%")
		pos := len(args)
		clauses = append(clauses, fmt.Sprintf(`(
			LOWER(key) LIKE $%d OR
			LOWER(category) LIKE $%d OR
			LOWER(title_i18n::text) LIKE $%d
		)`, pos, pos, pos))
	}
	filter.Limit, filter.Offset = normalizeCommunityPlatformPagination(filter.Limit, filter.Offset)
	args = append(args, filter.Limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT id, key, category, default_post_profile_key, title_i18n, description_i18n,
		       rules_i18n, icon_key, rollout_policy, allowed_scope_types,
		       allowed_post_profile_keys, enabled_tabs, subcategory_keys, promotion_segment_keys,
		       default_moderation_mode, status, created_at, updated_at
		FROM community_blueprints
		WHERE %s
		ORDER BY category ASC, key ASC
		LIMIT $%d OFFSET $%d
	`, strings.Join(clauses, " AND "), limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query community blueprints: %w", err)
	}
	defer rows.Close()

	items := make([]*model.CommunityBlueprint, 0)
	for rows.Next() {
		item, scanErr := scanCommunityBlueprint(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan community blueprint: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) ListCommunityGeoHubs(ctx context.Context, filter model.CommunityGeoHubListFilter) ([]*model.CommunityGeoHub, error) {
	args := make([]any, 0, 8)
	clauses := []string{"1=1"}
	if countryCode := strings.ToUpper(strings.TrimSpace(filter.CountryCode)); countryCode != "" {
		args = append(args, countryCode)
		clauses = append(clauses, fmt.Sprintf("country_code = $%d", len(args)))
	}
	if cityID := strings.TrimSpace(filter.CityID); cityID != "" {
		args = append(args, cityID)
		clauses = append(clauses, fmt.Sprintf("city_id = $%d", len(args)))
	}
	if hubTier := strings.ToUpper(strings.TrimSpace(filter.HubTier)); hubTier != "" {
		args = append(args, hubTier)
		clauses = append(clauses, fmt.Sprintf("hub_tier = $%d", len(args)))
	}
	if filter.CommunityEnabled != nil {
		args = append(args, *filter.CommunityEnabled)
		clauses = append(clauses, fmt.Sprintf("community_enabled = $%d", len(args)))
	}
	if !filter.IncludeAliasOnly {
		clauses = append(clauses, "hub_tier <> 'ALIAS_ONLY'")
	}
	filter.Limit, filter.Offset = normalizeCommunityPlatformPagination(filter.Limit, filter.Offset)
	args = append(args, filter.Limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT country_code, city_id, hub_tier, community_enabled, parent_country_code,
		       parent_city_id, reason, priority, created_by, updated_at
		FROM community_geo_hubs
		WHERE %s
		ORDER BY priority DESC, country_code ASC, city_id ASC
		LIMIT $%d OFFSET $%d
	`, strings.Join(clauses, " AND "), limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query community geo hubs: %w", err)
	}
	defer rows.Close()

	items := make([]*model.CommunityGeoHub, 0)
	for rows.Next() {
		item, scanErr := scanCommunityGeoHub(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan community geo hub: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) ListCommunityInstances(ctx context.Context, filter model.CommunityInstanceListFilter) ([]*model.CommunityInstance, error) {
	args := make([]any, 0, 8)
	clauses := []string{"1=1"}
	if filter.BlueprintID != uuid.Nil {
		args = append(args, filter.BlueprintID)
		clauses = append(clauses, fmt.Sprintf("blueprint_id = $%d", len(args)))
	}
	if countryCode := strings.ToUpper(strings.TrimSpace(filter.CountryCode)); countryCode != "" {
		args = append(args, countryCode)
		clauses = append(clauses, fmt.Sprintf("country_code = $%d", len(args)))
	}
	if cityID := strings.TrimSpace(filter.CityID); cityID != "" {
		args = append(args, cityID)
		clauses = append(clauses, fmt.Sprintf("city_id = $%d", len(args)))
	}
	if scopeType := strings.ToUpper(strings.TrimSpace(filter.ScopeType)); scopeType != "" {
		args = append(args, scopeType)
		clauses = append(clauses, fmt.Sprintf("scope_type = $%d", len(args)))
	}
	if filter.Status != nil && filter.Status.IsValid() {
		args = append(args, string(*filter.Status))
		clauses = append(clauses, fmt.Sprintf("status = $%d", len(args)))
	}
	if search := strings.ToLower(strings.TrimSpace(filter.Search)); search != "" {
		args = append(args, "%"+search+"%")
		pos := len(args)
		clauses = append(clauses, fmt.Sprintf(`(
			LOWER(slug) LIKE $%d OR
			LOWER(title_i18n::text) LIKE $%d
		)`, pos, pos))
	}
	filter.Limit, filter.Offset = normalizeCommunityPlatformPagination(filter.Limit, filter.Offset)
	args = append(args, filter.Limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT id, community_id, blueprint_id, slug, country_code, city_id, scope_type,
		       title_i18n, description_i18n, rules_i18n, status, member_count,
		       post_count, created_at, updated_at
		FROM community_instances
		WHERE %s
		ORDER BY member_count DESC, slug ASC
		LIMIT $%d OFFSET $%d
	`, strings.Join(clauses, " AND "), limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query community instances: %w", err)
	}
	defer rows.Close()

	items := make([]*model.CommunityInstance, 0)
	for rows.Next() {
		item, scanErr := scanCommunityInstance(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan community instance: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) MaterializeCommunityInstances(ctx context.Context, filter model.CommunityInstanceMaterializationFilter) (*model.CommunityInstanceMaterializationResult, error) {
	var blueprintID any
	if filter.BlueprintID != uuid.Nil {
		blueprintID = filter.BlueprintID
	}
	countryCode := strings.ToUpper(strings.TrimSpace(filter.CountryCode))
	cityID := strings.TrimSpace(filter.CityID)
	scopeType := strings.ToUpper(strings.TrimSpace(filter.ScopeType))
	limit := normalizeCommunityMaterializationLimit(filter.Limit)

	const query = `
WITH selected_coverage AS (
    SELECT
        cov.id AS coverage_id,
        cov.blueprint_id,
        cov.country_code,
        cov.city_id,
        cov.scope_type,
        cov.priority,
        cb.key AS blueprint_key,
        cb.category,
        cb.title_i18n,
        cb.description_i18n,
        cb.rules_i18n,
        cb.default_moderation_mode,
        md5('community:' || cov.id::text) AS community_hash,
        md5('community-instance:' || cov.id::text) AS instance_hash
    FROM community_blueprint_geo_coverage cov
    JOIN community_blueprints cb ON cb.id = cov.blueprint_id
    WHERE cov.status = 'ACTIVE'
      AND cb.status = 'ACTIVE'
      AND ($1::uuid IS NULL OR cov.blueprint_id = $1::uuid)
      AND ($2::text = '' OR cov.country_code = $2::text)
      AND ($3::text = '' OR cov.city_id = $3::text)
      AND ($4::text = '' OR cov.scope_type = $4::text)
    ORDER BY cov.priority ASC, cb.key ASC, cov.country_code ASC, cov.city_id ASC NULLS FIRST
    LIMIT $5
),
candidates AS (
    SELECT
        (
            substr(community_hash, 1, 8) || '-' ||
            substr(community_hash, 9, 4) || '-4' ||
            substr(community_hash, 14, 3) || '-8' ||
            substr(community_hash, 18, 3) || '-' ||
            substr(community_hash, 21, 12)
        )::uuid AS community_id,
        (
            substr(instance_hash, 1, 8) || '-' ||
            substr(instance_hash, 9, 4) || '-4' ||
            substr(instance_hash, 14, 3) || '-8' ||
            substr(instance_hash, 18, 3) || '-' ||
            substr(instance_hash, 21, 12)
        )::uuid AS instance_id,
        blueprint_id,
        replace(lower(blueprint_key), '_', '-') || '-' || lower(country_code) ||
            CASE WHEN city_id IS NULL THEN '' ELSE '-' || lower(city_id) END AS slug,
        title_i18n AS title_i18n,
        description_i18n,
        rules_i18n,
        upper(category) AS topic,
        country_code,
        city_id,
        scope_type,
        CASE
            WHEN default_moderation_mode = 'PREMODERATION' THEN 'MEMBERS_AFTER_MODERATION'
            WHEN default_moderation_mode = 'TRUSTED_PUBLISH_ELSE_REVIEW' THEN 'MEMBERS_AFTER_MODERATION'
            ELSE 'OPEN_MEMBERS'
        END AS posting_policy
    FROM selected_coverage
),
upserted_communities AS (
    INSERT INTO communities (
        id,
        slug,
        title,
        title_i18n,
        description,
        description_i18n,
        topic,
        rules,
        rules_i18n,
        city_id,
        country_code,
        language_code,
        visibility,
        posting_policy,
        status,
        follower_count,
        post_count,
        created_at,
        updated_at
    )
    SELECT
        community_id,
        slug,
        COALESCE(NULLIF(title_i18n->>'ru', ''), slug),
        title_i18n,
        COALESCE(NULLIF(description_i18n->>'ru', ''), ''),
        description_i18n,
        topic,
        COALESCE(ARRAY(SELECT jsonb_array_elements_text(rules_i18n->'ru')), ARRAY[]::text[]),
        rules_i18n,
        city_id,
        country_code,
        'ru',
        'PUBLIC',
        posting_policy,
        'ACTIVE',
        0,
        0,
        now(),
        now()
    FROM candidates
    ON CONFLICT (slug) DO UPDATE SET
        title = EXCLUDED.title,
        title_i18n = EXCLUDED.title_i18n,
        description = EXCLUDED.description,
        description_i18n = EXCLUDED.description_i18n,
        topic = EXCLUDED.topic,
        rules = EXCLUDED.rules,
        rules_i18n = EXCLUDED.rules_i18n,
        city_id = EXCLUDED.city_id,
        country_code = EXCLUDED.country_code,
        posting_policy = EXCLUDED.posting_policy,
        status = EXCLUDED.status,
        updated_at = now()
    RETURNING id, slug
),
resolved_communities AS (
    SELECT candidates.*, upserted_communities.id AS resolved_community_id
    FROM candidates
    JOIN upserted_communities ON upserted_communities.slug = candidates.slug
),
upserted_instances AS (
    INSERT INTO community_instances (
        id,
        community_id,
        blueprint_id,
        slug,
        country_code,
        city_id,
        scope_type,
        title_i18n,
        description_i18n,
        rules_i18n,
        status,
        member_count,
        post_count,
        created_at,
        updated_at
    )
    SELECT
        instance_id,
        resolved_community_id,
        blueprint_id,
        slug,
        country_code,
        city_id,
        scope_type,
        title_i18n,
        description_i18n,
        rules_i18n,
        'ACTIVE',
        0,
        0,
        now(),
        now()
    FROM resolved_communities
    ON CONFLICT (id) DO UPDATE SET
        community_id = EXCLUDED.community_id,
        slug = EXCLUDED.slug,
        title_i18n = EXCLUDED.title_i18n,
        description_i18n = EXCLUDED.description_i18n,
        rules_i18n = EXCLUDED.rules_i18n,
        status = EXCLUDED.status,
        updated_at = now()
    RETURNING id
)
SELECT COUNT(*) FROM upserted_instances`

	var materializedCount int
	if err := r.pool.QueryRow(ctx, query, blueprintID, countryCode, cityID, scopeType, limit).Scan(&materializedCount); err != nil {
		return nil, fmt.Errorf("materialize community instances: %w", err)
	}
	return &model.CommunityInstanceMaterializationResult{
		MaterializedCount: materializedCount,
	}, nil
}

func (r *PGPostRepository) CreateCommunityReport(ctx context.Context, report *model.CommunityReport) (*model.CommunityReportSubmissionResult, error) {
	if report == nil || report.CommunityID == uuid.Nil || report.ReporterUserID == uuid.Nil || !report.Reason.IsValid() {
		return nil, nil
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin create community report tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = lockVisibleCommunityFollowerCount(ctx, tx, report.CommunityID); err != nil {
		return nil, err
	}

	stored, err := scanCommunityReport(tx.QueryRow(
		ctx,
		`INSERT INTO community_reports (
			id,
			community_id,
			reporter_user_id,
			reason,
			details,
			status,
			created_at,
			updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (community_id, reporter_user_id) WHERE status = 'OPEN'
		DO UPDATE SET
			reason = EXCLUDED.reason,
			details = EXCLUDED.details,
			updated_at = NOW()
		RETURNING id, community_id, reporter_user_id, reason, details, status, created_at, updated_at`,
		report.ID,
		report.CommunityID,
		report.ReporterUserID,
		string(report.Reason),
		report.Details,
		string(enum.PostReportStatusOpen),
		report.CreatedAt,
		report.UpdatedAt,
	))
	if err != nil {
		return nil, fmt.Errorf("upsert community report: %w", err)
	}

	openReportsCount, err := countOpenCommunityReports(ctx, tx, report.CommunityID)
	if err != nil {
		return nil, err
	}
	if err = tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit create community report tx: %w", err)
	}
	return &model.CommunityReportSubmissionResult{
		Report:           stored,
		OpenReportsCount: openReportsCount,
	}, nil
}

func (r *PGPostRepository) SetCommunityMuted(ctx context.Context, communityID uuid.UUID, userID uuid.UUID, muted bool) (*model.CommunityMembership, error) {
	if communityID == uuid.Nil || userID == uuid.Nil {
		return nil, nil
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin set community muted tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = lockVisibleCommunityFollowerCount(ctx, tx, communityID); err != nil {
		return nil, err
	}

	current, err := scanCommunityMembership(tx.QueryRow(
		ctx,
		`SELECT community_id, user_id, role, status, created_at, updated_at
		 FROM community_memberships
		 WHERE community_id = $1 AND user_id = $2
		 FOR UPDATE`,
		communityID,
		userID,
	))
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return nil, fmt.Errorf("lock community membership for mute: %w", err)
	}

	nextStatus := enum.CommunityMembershipStatusLeft
	if muted {
		nextStatus = enum.CommunityMembershipStatusMuted
	}
	if current != nil && current.Status == enum.CommunityMembershipStatusBanned {
		nextStatus = enum.CommunityMembershipStatusBanned
	}

	var updated *model.CommunityMembership
	if errors.Is(err, pgx.ErrNoRows) {
		if !muted {
			if err = tx.Commit(ctx); err != nil {
				return nil, fmt.Errorf("commit no-op unmute community tx: %w", err)
			}
			return nil, nil
		}
		updated, err = scanCommunityMembership(tx.QueryRow(
			ctx,
			`INSERT INTO community_memberships (community_id, user_id, role, status, created_at, updated_at)
			 VALUES ($1, $2, 'MEMBER', $3, NOW(), NOW())
			 RETURNING community_id, user_id, role, status, created_at, updated_at`,
			communityID,
			userID,
			string(nextStatus),
		))
	} else if current.Status == nextStatus {
		updated = current
	} else {
		updated, err = scanCommunityMembership(tx.QueryRow(
			ctx,
			`UPDATE community_memberships
			 SET status = $3, updated_at = NOW()
			 WHERE community_id = $1 AND user_id = $2
			 RETURNING community_id, user_id, role, status, created_at, updated_at`,
			communityID,
			userID,
			string(nextStatus),
		))
	}
	if err != nil {
		return nil, fmt.Errorf("upsert community mute status: %w", err)
	}

	if current != nil && updated != nil && current.Status != updated.Status {
		if delta := membershipStatusFollowerDelta(current.Status, updated.Status); delta != 0 {
			if _, err = incrementCommunityFollowerCount(ctx, tx, communityID, delta); err != nil {
				return nil, err
			}
		}
		if _, err = tx.Exec(
			ctx,
			`INSERT INTO community_member_status_changes (
				id,
				community_id,
				target_user_id,
				actor_user_id,
				previous_status,
				next_status,
				created_at
			)
			VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
			uuid.New(),
			communityID,
			userID,
			userID,
			string(current.Status),
			string(updated.Status),
		); err != nil {
			return nil, fmt.Errorf("insert community mute status audit: %w", err)
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit set community muted tx: %w", err)
	}
	return updated, nil
}

func (r *PGPostRepository) FollowCommunity(ctx context.Context, communityID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin follow community tx: %w", err)
	}
	defer tx.Rollback(ctx)

	count, err := lockVisibleCommunityFollowerCount(ctx, tx, communityID)
	if err != nil {
		return false, 0, err
	}

	var existingStatus sql.NullString
	err = tx.QueryRow(
		ctx,
		`SELECT status FROM community_memberships WHERE community_id = $1 AND user_id = $2 FOR UPDATE`,
		communityID,
		userID,
	).Scan(&existingStatus)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return false, 0, fmt.Errorf("select community membership: %w", err)
	}
	if existingStatus.Valid {
		switch enum.CommunityMembershipStatus(existingStatus.String) {
		case enum.CommunityMembershipStatusMuted, enum.CommunityMembershipStatusBanned:
			if err = tx.Commit(ctx); err != nil {
				return false, 0, fmt.Errorf("commit restricted follow community tx: %w", err)
			}
			return false, count, nil
		case enum.CommunityMembershipStatusActive:
			if err = tx.Commit(ctx); err != nil {
				return false, 0, fmt.Errorf("commit unchanged follow community tx: %w", err)
			}
			return false, count, nil
		}
	}

	if existingStatus.Valid {
		_, err = tx.Exec(
			ctx,
			`UPDATE community_memberships SET status = 'ACTIVE', updated_at = NOW() WHERE community_id = $1 AND user_id = $2`,
			communityID,
			userID,
		)
	} else {
		_, err = tx.Exec(
			ctx,
			`INSERT INTO community_memberships (community_id, user_id, role, status, created_at, updated_at)
			 VALUES ($1, $2, 'MEMBER', 'ACTIVE', NOW(), NOW())`,
			communityID,
			userID,
		)
	}
	if err != nil {
		return false, 0, fmt.Errorf("upsert community membership: %w", err)
	}

	count, err = incrementCommunityFollowerCount(ctx, tx, communityID, 1)
	if err != nil {
		return false, 0, err
	}
	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit follow community tx: %w", err)
	}
	return true, count, nil
}

func (r *PGPostRepository) UnfollowCommunity(ctx context.Context, communityID uuid.UUID, userID uuid.UUID) (bool, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return false, 0, fmt.Errorf("begin unfollow community tx: %w", err)
	}
	defer tx.Rollback(ctx)

	count, err := lockVisibleCommunityFollowerCount(ctx, tx, communityID)
	if err != nil {
		return false, 0, err
	}

	var existingStatus sql.NullString
	err = tx.QueryRow(
		ctx,
		`SELECT status FROM community_memberships WHERE community_id = $1 AND user_id = $2 FOR UPDATE`,
		communityID,
		userID,
	).Scan(&existingStatus)
	if errors.Is(err, pgx.ErrNoRows) {
		if err = tx.Commit(ctx); err != nil {
			return false, 0, fmt.Errorf("commit missing unfollow community tx: %w", err)
		}
		return false, count, nil
	}
	if err != nil {
		return false, 0, fmt.Errorf("select community membership: %w", err)
	}
	if enum.CommunityMembershipStatus(existingStatus.String) != enum.CommunityMembershipStatusActive {
		if err = tx.Commit(ctx); err != nil {
			return false, 0, fmt.Errorf("commit unchanged unfollow community tx: %w", err)
		}
		return false, count, nil
	}

	if _, err = tx.Exec(
		ctx,
		`UPDATE community_memberships SET status = 'LEFT', updated_at = NOW() WHERE community_id = $1 AND user_id = $2`,
		communityID,
		userID,
	); err != nil {
		return false, 0, fmt.Errorf("update community membership left: %w", err)
	}

	count, err = incrementCommunityFollowerCount(ctx, tx, communityID, -1)
	if err != nil {
		return false, 0, err
	}
	if err = tx.Commit(ctx); err != nil {
		return false, 0, fmt.Errorf("commit unfollow community tx: %w", err)
	}
	return true, count, nil
}

func (r *PGPostRepository) ListFollowedCommunityIDs(ctx context.Context, userID uuid.UUID, communityIDs []uuid.UUID) (map[uuid.UUID]bool, error) {
	result := make(map[uuid.UUID]bool, len(communityIDs))
	if userID == uuid.Nil || len(communityIDs) == 0 {
		return result, nil
	}

	rows, err := r.pool.Query(
		ctx,
		`SELECT community_id
		 FROM community_memberships
		 WHERE user_id = $1 AND status = 'ACTIVE' AND community_id = ANY($2)`,
		userID,
		communityIDs,
	)
	if err != nil {
		return nil, fmt.Errorf("query followed community ids: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var communityID uuid.UUID
		if err = rows.Scan(&communityID); err != nil {
			return nil, fmt.Errorf("scan followed community id: %w", err)
		}
		result[communityID] = true
	}
	return result, rows.Err()
}

func (r *PGPostRepository) ListUserCommunityIDs(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]uuid.UUID, error) {
	if userID == uuid.Nil {
		return []uuid.UUID{}, nil
	}
	if limit <= 0 || limit > 500 {
		limit = 200
	}
	if offset < 0 {
		offset = 0
	}

	rows, err := r.pool.Query(
		ctx,
		`SELECT m.community_id
		 FROM community_memberships m
		 JOIN communities c ON c.id = m.community_id
		 WHERE m.user_id = $1
		   AND m.status = 'ACTIVE'
		   AND c.deleted_at IS NULL
		   AND c.status = 'ACTIVE'
		   AND c.visibility = 'PUBLIC'
		 ORDER BY m.updated_at DESC, m.community_id DESC
		 LIMIT $2 OFFSET $3`,
		userID,
		limit,
		offset,
	)
	if err != nil {
		return nil, fmt.Errorf("query user community ids: %w", err)
	}
	defer rows.Close()

	result := make([]uuid.UUID, 0, limit)
	for rows.Next() {
		var communityID uuid.UUID
		if err = rows.Scan(&communityID); err != nil {
			return nil, fmt.Errorf("scan user community id: %w", err)
		}
		result = append(result, communityID)
	}
	return result, rows.Err()
}

func (r *PGPostRepository) GetCommunityMembership(ctx context.Context, communityID uuid.UUID, userID uuid.UUID) (*model.CommunityMembership, error) {
	if communityID == uuid.Nil || userID == uuid.Nil {
		return nil, nil
	}

	var (
		item      model.CommunityMembership
		roleRaw   string
		statusRaw string
	)
	err := r.pool.QueryRow(
		ctx,
		`SELECT community_id, user_id, role, status, created_at, updated_at
		 FROM community_memberships
		 WHERE community_id = $1 AND user_id = $2
		 LIMIT 1`,
		communityID,
		userID,
	).Scan(
		&item.CommunityID,
		&item.UserID,
		&roleRaw,
		&statusRaw,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("select community membership: %w", err)
	}

	item.Role = enum.CommunityMembershipRole(strings.ToUpper(strings.TrimSpace(roleRaw)))
	item.Status = enum.CommunityMembershipStatus(strings.ToUpper(strings.TrimSpace(statusRaw)))
	return &item, nil
}

func (r *PGPostRepository) ListCommunityMemberships(ctx context.Context, filter model.CommunityMemberListFilter) ([]*model.CommunityMembership, error) {
	if filter.CommunityID == uuid.Nil {
		return []*model.CommunityMembership{}, nil
	}

	args := []any{filter.CommunityID}
	clauses := []string{"community_id = $1"}
	if filter.Role != nil {
		args = append(args, string(*filter.Role))
		clauses = append(clauses, fmt.Sprintf("role = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, string(*filter.Status))
		clauses = append(clauses, fmt.Sprintf("status = $%d", len(args)))
	}
	if filter.Limit <= 0 || filter.Limit > 50 {
		filter.Limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	args = append(args, filter.Limit, filter.Offset)
	limitPos := len(args) - 1
	offsetPos := len(args)

	query := fmt.Sprintf(`
		SELECT community_id, user_id, role, status, created_at, updated_at
		FROM community_memberships
		WHERE %s
		ORDER BY
			CASE role
				WHEN 'ADMIN' THEN 0
				WHEN 'MODERATOR' THEN 1
				WHEN 'TRUSTED_MEMBER' THEN 2
				ELSE 3
			END,
			created_at DESC,
			user_id ASC
		LIMIT $%d OFFSET $%d
	`, strings.Join(clauses, " AND "), limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query community memberships: %w", err)
	}
	defer rows.Close()

	items := make([]*model.CommunityMembership, 0)
	for rows.Next() {
		item, scanErr := scanCommunityMembership(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan community membership: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) ListCommunityMemberRoleChanges(
	ctx context.Context,
	filter model.CommunityMemberRoleChangeListFilter,
) ([]*model.CommunityMemberRoleChange, error) {
	if filter.CommunityID == uuid.Nil || filter.TargetUserID == uuid.Nil {
		return []*model.CommunityMemberRoleChange{}, nil
	}
	if filter.Limit <= 0 || filter.Limit > 50 {
		filter.Limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	rows, err := r.pool.Query(
		ctx,
		`SELECT
			id,
			community_id,
			target_user_id,
			actor_user_id,
			previous_role,
			next_role,
			created_at
		 FROM community_member_role_changes
		 WHERE community_id = $1 AND target_user_id = $2
		 ORDER BY created_at DESC
		 LIMIT $3 OFFSET $4`,
		filter.CommunityID,
		filter.TargetUserID,
		filter.Limit,
		filter.Offset,
	)
	if err != nil {
		return nil, fmt.Errorf("query community member role changes: %w", err)
	}
	defer rows.Close()

	items := make([]*model.CommunityMemberRoleChange, 0)
	for rows.Next() {
		item, scanErr := scanCommunityMemberRoleChange(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan community member role change: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) UpdateCommunityMembershipRole(
	ctx context.Context,
	communityID uuid.UUID,
	userID uuid.UUID,
	actorUserID uuid.UUID,
	role enum.CommunityMembershipRole,
) (*model.CommunityMembership, error) {
	if communityID == uuid.Nil || userID == uuid.Nil || actorUserID == uuid.Nil || !role.IsValid() {
		return nil, nil
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin update community membership role tx: %w", err)
	}
	defer tx.Rollback(ctx)

	current, err := scanCommunityMembership(tx.QueryRow(
		ctx,
		`SELECT community_id, user_id, role, status, created_at, updated_at
		 FROM community_memberships
		 WHERE community_id = $1 AND user_id = $2 AND status = 'ACTIVE'
		 FOR UPDATE`,
		communityID,
		userID,
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("lock active community membership: %w", err)
	}

	if current.Role == role {
		if err = tx.Commit(ctx); err != nil {
			return nil, fmt.Errorf("commit update community membership role tx: %w", err)
		}
		return current, nil
	}

	updated, err := scanCommunityMembership(tx.QueryRow(
		ctx,
		`UPDATE community_memberships
		 SET role = $3, updated_at = NOW()
		 WHERE community_id = $1 AND user_id = $2 AND status = 'ACTIVE'
		 RETURNING community_id, user_id, role, status, created_at, updated_at`,
		communityID,
		userID,
		string(role),
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("update community membership role: %w", err)
	}

	if _, err = tx.Exec(
		ctx,
		`INSERT INTO community_member_role_changes (
			id,
			community_id,
			target_user_id,
			actor_user_id,
			previous_role,
			next_role,
			created_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
		uuid.New(),
		communityID,
		userID,
		actorUserID,
		string(current.Role),
		string(updated.Role),
	); err != nil {
		return nil, fmt.Errorf("insert community member role change audit: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit update community membership role tx: %w", err)
	}
	return updated, nil
}

func (r *PGPostRepository) UpdateCommunityMembershipStatus(
	ctx context.Context,
	communityID uuid.UUID,
	userID uuid.UUID,
	actorUserID uuid.UUID,
	status enum.CommunityMembershipStatus,
) (*model.CommunityMembership, error) {
	if communityID == uuid.Nil || userID == uuid.Nil || actorUserID == uuid.Nil || !status.IsValid() {
		return nil, nil
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin update community membership status tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = lockActiveCommunityFollowerCount(ctx, tx, communityID); err != nil {
		return nil, err
	}

	current, err := scanCommunityMembership(tx.QueryRow(
		ctx,
		`SELECT community_id, user_id, role, status, created_at, updated_at
		 FROM community_memberships
		 WHERE community_id = $1 AND user_id = $2
		 FOR UPDATE`,
		communityID,
		userID,
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("lock community membership for status update: %w", err)
	}

	if current.Status == status {
		if err = tx.Commit(ctx); err != nil {
			return nil, fmt.Errorf("commit update community membership status tx: %w", err)
		}
		return current, nil
	}

	updated, err := scanCommunityMembership(tx.QueryRow(
		ctx,
		`UPDATE community_memberships
		 SET status = $3, updated_at = NOW()
		 WHERE community_id = $1 AND user_id = $2
		 RETURNING community_id, user_id, role, status, created_at, updated_at`,
		communityID,
		userID,
		string(status),
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("update community membership status: %w", err)
	}

	if delta := membershipStatusFollowerDelta(current.Status, status); delta != 0 {
		if _, err = incrementCommunityFollowerCount(ctx, tx, communityID, delta); err != nil {
			return nil, err
		}
	}

	if _, err = tx.Exec(
		ctx,
		`INSERT INTO community_member_status_changes (
			id,
			community_id,
			target_user_id,
			actor_user_id,
			previous_status,
			next_status,
			created_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
		uuid.New(),
		communityID,
		userID,
		actorUserID,
		string(current.Status),
		string(updated.Status),
	); err != nil {
		return nil, fmt.Errorf("insert community member status change audit: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit update community membership status tx: %w", err)
	}
	return updated, nil
}

func scanCommunityMembership(scanner interface{ Scan(dest ...any) error }) (*model.CommunityMembership, error) {
	var (
		item      model.CommunityMembership
		roleRaw   string
		statusRaw string
	)
	if err := scanner.Scan(
		&item.CommunityID,
		&item.UserID,
		&roleRaw,
		&statusRaw,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}

	item.Role = enum.CommunityMembershipRole(strings.ToUpper(strings.TrimSpace(roleRaw)))
	item.Status = enum.CommunityMembershipStatus(strings.ToUpper(strings.TrimSpace(statusRaw)))
	return &item, nil
}

func scanCommunityMemberRoleChange(scanner interface{ Scan(dest ...any) error }) (*model.CommunityMemberRoleChange, error) {
	var (
		item            model.CommunityMemberRoleChange
		previousRoleRaw string
		nextRoleRaw     string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.CommunityID,
		&item.TargetUserID,
		&item.ActorUserID,
		&previousRoleRaw,
		&nextRoleRaw,
		&item.CreatedAt,
	); err != nil {
		return nil, err
	}

	item.PreviousRole = enum.CommunityMembershipRole(strings.ToUpper(strings.TrimSpace(previousRoleRaw)))
	item.NextRole = enum.CommunityMembershipRole(strings.ToUpper(strings.TrimSpace(nextRoleRaw)))
	return &item, nil
}

type communityTx interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

func lockVisibleCommunityFollowerCount(ctx context.Context, tx communityTx, communityID uuid.UUID) (int, error) {
	var count int
	err := tx.QueryRow(
		ctx,
		`SELECT follower_count
		 FROM communities
		 WHERE id = $1
		   AND deleted_at IS NULL
		   AND status = 'ACTIVE'
		   AND visibility = 'PUBLIC'
		 FOR UPDATE`,
		communityID,
	).Scan(&count)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, ErrNotFound
	}
	if err != nil {
		return 0, fmt.Errorf("lock visible community: %w", err)
	}
	return count, nil
}

func lockActiveCommunityFollowerCount(ctx context.Context, tx communityTx, communityID uuid.UUID) (int, error) {
	var count int
	err := tx.QueryRow(
		ctx,
		`SELECT follower_count
		 FROM communities
		 WHERE id = $1
		   AND deleted_at IS NULL
		   AND status = 'ACTIVE'
		 FOR UPDATE`,
		communityID,
	).Scan(&count)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, ErrNotFound
	}
	if err != nil {
		return 0, fmt.Errorf("lock active community: %w", err)
	}
	return count, nil
}

func incrementCommunityFollowerCount(ctx context.Context, tx communityTx, communityID uuid.UUID, delta int) (int, error) {
	var count int
	if err := tx.QueryRow(
		ctx,
		`UPDATE communities
		 SET follower_count = GREATEST(follower_count + $2, 0), updated_at = NOW()
		 WHERE id = $1
		 RETURNING follower_count`,
		communityID,
		delta,
	).Scan(&count); err != nil {
		return 0, fmt.Errorf("update community follower count: %w", err)
	}
	return count, nil
}

func countOpenCommunityReports(ctx context.Context, tx communityTx, communityID uuid.UUID) (int, error) {
	var count int
	if err := tx.QueryRow(
		ctx,
		`SELECT COUNT(*)
		 FROM community_reports
		 WHERE community_id = $1 AND status = $2`,
		communityID,
		string(enum.PostReportStatusOpen),
	).Scan(&count); err != nil {
		return 0, fmt.Errorf("count open community reports: %w", err)
	}
	return count, nil
}

func membershipStatusFollowerDelta(previous enum.CommunityMembershipStatus, next enum.CommunityMembershipStatus) int {
	previousActive := previous == enum.CommunityMembershipStatusActive
	nextActive := next == enum.CommunityMembershipStatusActive
	switch {
	case previousActive && !nextActive:
		return -1
	case !previousActive && nextActive:
		return 1
	default:
		return 0
	}
}

func scanCommunityReport(scanner interface{ Scan(dest ...any) error }) (*model.CommunityReport, error) {
	var (
		item      model.CommunityReport
		reasonRaw string
		statusRaw string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.CommunityID,
		&item.ReporterUserID,
		&reasonRaw,
		&item.Details,
		&statusRaw,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.Reason = enum.NormalizePostReportReason(enum.PostReportReason(reasonRaw))
	item.Status = enum.NormalizePostReportStatus(enum.PostReportStatus(statusRaw))
	return &item, nil
}

func scanCommunityPostProfile(scanner interface{ Scan(dest ...any) error }) (*model.CommunityPostProfile, error) {
	var (
		item              model.CommunityPostProfile
		keyRaw            string
		postKindRaw       string
		schemaRaw         []byte
		validationRaw     []byte
		moderationModeRaw string
		activityModeRaw   string
	)
	if err := scanner.Scan(
		&keyRaw,
		&item.Version,
		&postKindRaw,
		&item.ComposerPreset,
		&item.RenderPreset,
		&schemaRaw,
		&validationRaw,
		&moderationModeRaw,
		&activityModeRaw,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.Key = enum.PostProfileKey(strings.TrimSpace(keyRaw))
	item.PostKind = enum.PostKind(strings.ToUpper(strings.TrimSpace(postKindRaw)))
	item.SchemaJSON = cloneRawJSON(schemaRaw)
	item.ValidationJSON = cloneRawJSON(validationRaw)
	item.ModerationMode = enum.ModerationMode(strings.ToUpper(strings.TrimSpace(moderationModeRaw)))
	item.ActivityCreationMode = enum.ActivityCreationMode(strings.ToUpper(strings.TrimSpace(activityModeRaw)))
	return &item, nil
}

func scanCommunityBlueprint(scanner interface{ Scan(dest ...any) error }) (*model.CommunityBlueprint, error) {
	var (
		item                      model.CommunityBlueprint
		defaultPostProfileKeyRaw  string
		titleI18nRaw              []byte
		descriptionI18nRaw        []byte
		rulesI18nRaw              []byte
		rolloutPolicyRaw          string
		allowedScopeTypesRaw      []string
		allowedPostProfileKeysRaw []string
		enabledTabsRaw            []string
		subcategoryKeysRaw        []string
		promotionSegmentKeysRaw   []string
		defaultModerationRaw      string
		statusRaw                 string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.Key,
		&item.Category,
		&defaultPostProfileKeyRaw,
		&titleI18nRaw,
		&descriptionI18nRaw,
		&rulesI18nRaw,
		&item.IconKey,
		&rolloutPolicyRaw,
		&allowedScopeTypesRaw,
		&allowedPostProfileKeysRaw,
		&enabledTabsRaw,
		&subcategoryKeysRaw,
		&promotionSegmentKeysRaw,
		&defaultModerationRaw,
		&statusRaw,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.DefaultPostProfileKey = enum.PostProfileKey(strings.TrimSpace(defaultPostProfileKeyRaw))
	item.TitleI18n = decodeCommunityStringMap(titleI18nRaw)
	item.DescriptionI18n = decodeCommunityStringMap(descriptionI18nRaw)
	item.RulesI18n = decodeCommunityStringSliceMap(rulesI18nRaw)
	item.RolloutPolicy = enum.CommunityRolloutPolicy(strings.ToUpper(strings.TrimSpace(rolloutPolicyRaw)))
	item.AllowedScopeTypes = normalizeCommunityScopeTypes(allowedScopeTypesRaw)
	item.AllowedPostProfileKeys = normalizeCommunityStringList(allowedPostProfileKeysRaw)
	item.EnabledTabs = normalizeCommunityStringList(enabledTabsRaw)
	item.SubcategoryKeys = normalizeCommunityStringList(subcategoryKeysRaw)
	item.PromotionSegmentKeys = normalizeCommunityStringList(promotionSegmentKeysRaw)
	item.DefaultModerationMode = enum.ModerationMode(strings.ToUpper(strings.TrimSpace(defaultModerationRaw)))
	item.Status = enum.NormalizeCommunityStatus(enum.CommunityStatus(statusRaw))
	return &item, nil
}

func scanCommunityGeoHub(scanner interface{ Scan(dest ...any) error }) (*model.CommunityGeoHub, error) {
	var (
		item       model.CommunityGeoHub
		hubTierRaw string
	)
	if err := scanner.Scan(
		&item.CountryCode,
		&item.CityID,
		&hubTierRaw,
		&item.CommunityEnabled,
		&item.ParentCountryCode,
		&item.ParentCityID,
		&item.Reason,
		&item.Priority,
		&item.CreatedBy,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.CountryCode = strings.ToUpper(strings.TrimSpace(item.CountryCode))
	item.CityID = strings.TrimSpace(item.CityID)
	item.HubTier = enum.CommunityGeoHubTier(strings.ToUpper(strings.TrimSpace(hubTierRaw)))
	return &item, nil
}

func scanCommunityInstance(scanner interface{ Scan(dest ...any) error }) (*model.CommunityInstance, error) {
	var (
		item               model.CommunityInstance
		scopeTypeRaw       string
		titleI18nRaw       []byte
		descriptionI18nRaw []byte
		rulesI18nRaw       []byte
		statusRaw          string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.CommunityID,
		&item.BlueprintID,
		&item.Slug,
		&item.CountryCode,
		&item.CityID,
		&scopeTypeRaw,
		&titleI18nRaw,
		&descriptionI18nRaw,
		&rulesI18nRaw,
		&statusRaw,
		&item.MemberCount,
		&item.PostCount,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.CountryCode = strings.ToUpper(strings.TrimSpace(item.CountryCode))
	item.ScopeType = enum.NormalizeCommunityScopeType(enum.CommunityScopeType(scopeTypeRaw))
	item.TitleI18n = decodeCommunityStringMap(titleI18nRaw)
	item.DescriptionI18n = decodeCommunityStringMap(descriptionI18nRaw)
	item.RulesI18n = decodeCommunityStringSliceMap(rulesI18nRaw)
	item.Status = enum.NormalizeCommunityStatus(enum.CommunityStatus(statusRaw))
	return &item, nil
}

func scanCommunity(scanner interface{ Scan(dest ...any) error }) (*model.Community, error) {
	var (
		item               model.Community
		cityID             *string
		countryCode        *string
		avatarFileID       *uuid.UUID
		coverFileID        *uuid.UUID
		visibilityRaw      string
		postingPolicyRaw   string
		statusRaw          string
		defaultProfileRaw  string
		allowedProfileKeys []string
		enabledTabs        []string
		rules              []string
		titleI18nRaw       []byte
		descriptionI18nRaw []byte
		rulesI18nRaw       []byte
		createdByAdminID   *uuid.UUID
		deletedAt          sql.NullTime
		deletedAtPtr       *sql.NullTime
	)

	deletedAtPtr = &deletedAt
	if err := scanner.Scan(
		&item.ID,
		&item.Slug,
		&item.Title,
		&item.Description,
		&item.Topic,
		&cityID,
		&countryCode,
		&item.LanguageCode,
		&avatarFileID,
		&coverFileID,
		&visibilityRaw,
		&postingPolicyRaw,
		&statusRaw,
		&defaultProfileRaw,
		&allowedProfileKeys,
		&enabledTabs,
		&item.FollowerCount,
		&item.PostCount,
		&rules,
		&titleI18nRaw,
		&descriptionI18nRaw,
		&rulesI18nRaw,
		&createdByAdminID,
		&item.CreatedAt,
		&item.UpdatedAt,
		deletedAtPtr,
	); err != nil {
		return nil, err
	}

	item.CityID = cityID
	item.CountryCode = countryCode
	item.AvatarFileID = avatarFileID
	item.CoverFileID = coverFileID
	item.Rules = normalizeCommunityRules(rules)
	item.TitleI18n = normalizeCommunityTextI18n(titleI18nRaw, item.Title)
	item.DescriptionI18n = normalizeCommunityTextI18n(descriptionI18nRaw, item.Description)
	item.RulesI18n = normalizeCommunityRulesI18n(rulesI18nRaw, item.Rules)
	item.CreatedByAdminID = createdByAdminID
	if deletedAt.Valid {
		item.DeletedAt = &deletedAt.Time
	}
	item.Visibility = enum.NormalizeCommunityVisibility(enum.CommunityVisibility(visibilityRaw))
	item.PostingPolicy = enum.NormalizeCommunityPostingPolicy(enum.CommunityPostingPolicy(postingPolicyRaw))
	item.Status = enum.NormalizeCommunityStatus(enum.CommunityStatus(statusRaw))
	item.DefaultPostProfileKey = enum.NormalizePostProfileKey(enum.PostProfileKey(defaultProfileRaw))
	if !item.DefaultPostProfileKey.IsValid() {
		item.DefaultPostProfileKey = enum.PostProfileArticleV1
	}
	item.AllowedPostProfileKeys = normalizeCommunityStringList(allowedProfileKeys)
	if len(item.AllowedPostProfileKeys) == 0 {
		item.AllowedPostProfileKeys = []string{string(item.DefaultPostProfileKey)}
	}
	item.EnabledTabs = normalizeCommunityStringList(enabledTabs)
	if len(item.EnabledTabs) == 0 {
		item.EnabledTabs = []string{"posts"}
	}

	return &item, nil
}

func normalizeCommunityTextI18n(raw []byte, fallback string) map[string]string {
	values := map[string]string{}
	if len(raw) > 0 {
		_ = json.Unmarshal(raw, &values)
	}
	if strings.TrimSpace(fallback) != "" {
		if strings.TrimSpace(values["ru"]) == "" {
			values["ru"] = strings.TrimSpace(fallback)
		}
	}
	for locale, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			values[locale] = trimmed
		} else {
			delete(values, locale)
		}
	}
	return values
}

func decodeCommunityStringMap(raw []byte) map[string]string {
	values := map[string]string{}
	if len(raw) > 0 {
		_ = json.Unmarshal(raw, &values)
	}
	for locale, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			delete(values, locale)
			continue
		}
		values[locale] = trimmed
	}
	return values
}

func decodeCommunityStringSliceMap(raw []byte) map[string][]string {
	values := map[string][]string{}
	if len(raw) > 0 {
		_ = json.Unmarshal(raw, &values)
	}
	for locale, rules := range values {
		normalized := normalizeCommunityRules(rules)
		if len(normalized) == 0 {
			delete(values, locale)
			continue
		}
		values[locale] = normalized
	}
	return values
}

func normalizeCommunityScopeTypes(raw []string) []enum.CommunityScopeType {
	if len(raw) == 0 {
		return nil
	}
	values := make([]enum.CommunityScopeType, 0, len(raw))
	for _, value := range raw {
		scopeType := enum.NormalizeCommunityScopeType(enum.CommunityScopeType(value))
		if scopeType.IsValid() {
			values = append(values, scopeType)
		}
	}
	return values
}

func normalizeCommunityStringList(raw []string) []string {
	if len(raw) == 0 {
		return nil
	}
	values := make([]string, 0, len(raw))
	seen := make(map[string]struct{}, len(raw))
	for _, value := range raw {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		if _, ok := seen[trimmed]; ok {
			continue
		}
		seen[trimmed] = struct{}{}
		values = append(values, trimmed)
	}
	if len(values) == 0 {
		return nil
	}
	return values
}

func cloneRawJSON(raw []byte) json.RawMessage {
	if len(raw) == 0 {
		return nil
	}
	return append(json.RawMessage(nil), raw...)
}

func normalizeCommunityPlatformPagination(limit int, offset int) (int, int) {
	if limit <= 0 {
		limit = 50
	}
	if limit > maxCommunityPlatformPaginationLimit {
		limit = maxCommunityPlatformPaginationLimit
	}
	if offset < 0 {
		offset = 0
	}
	return limit, offset
}

func normalizeCommunityMaterializationLimit(limit int) int {
	if limit <= 0 {
		return 500
	}
	if limit > 5000 {
		return 5000
	}
	return limit
}

func normalizeCommunityRulesI18n(raw []byte, fallback []string) map[string][]string {
	values := map[string][]string{}
	if len(raw) > 0 {
		_ = json.Unmarshal(raw, &values)
	}
	if len(values["ru"]) == 0 && len(fallback) > 0 {
		values["ru"] = normalizeCommunityRules(fallback)
	}
	for locale, rules := range values {
		normalized := normalizeCommunityRules(rules)
		if len(normalized) == 0 {
			delete(values, locale)
			continue
		}
		values[locale] = normalized
	}
	return values
}

func normalizeCommunityRules(raw []string) []string {
	if len(raw) == 0 {
		return nil
	}
	rules := make([]string, 0, len(raw))
	for _, rule := range raw {
		if trimmed := strings.TrimSpace(rule); trimmed != "" {
			rules = append(rules, trimmed)
		}
	}
	if len(rules) == 0 {
		return nil
	}
	return rules
}
