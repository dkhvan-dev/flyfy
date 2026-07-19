package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	savedsearchapp "kz/inflap/backend/services/saved-service/internal/app/savedsearch"
)

const savedSearchSelectSQL = `
WITH owner_items AS MATERIALIZED (
    SELECT id,
           owner_user_id,
           entity_type,
           entity_id,
           state_generation,
           relationship_attribution_id,
           relationship_version,
           dependent_membership_version,
           saved_at
    FROM saved_items
    WHERE owner_user_id = $1::uuid
      AND relationship_state = 'ACTIVE'
      AND ($2::text IS NULL OR entity_type = $2::text)
)
SELECT saved_items.id::text,
       saved_items.entity_type,
       saved_items.entity_id,
       saved_items.state_generation::text,
       saved_items.relationship_attribution_id::text,
       saved_items.relationship_version,
       saved_items.dependent_membership_version,
       saved_items.saved_at,
       effective_memberships.count::bigint,
       projections.source_revision,
       projections.projection_revision,
       projections.visibility_revision,
       projections.visibility_status,
       projections.visibility_validated_at,
       projections.updated_at,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.source_default_locale END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.title_en END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.title_ru END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.title_kk END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.subtitle_en END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.subtitle_ru END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.subtitle_kk END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.media_reference END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.media_reference_revision END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.media_valid_until END,
       CASE
           WHEN projections.visibility_status = 'PUBLIC'
            AND projections.media_valid_until IS NOT NULL
           THEN projections.media_valid_until > $9::timestamptz
       END,
       CASE WHEN projections.visibility_status = 'PUBLIC' THEN projections.canonical_detail_route END,
       winning_match.match_rank::smallint,
       winning_match.match_kind,
       winning_match.matched_field,
       winning_match.matched_locale,
       winning_match.matched_value
FROM owner_items AS saved_items
JOIN saved_content_projections AS projections
  ON projections.entity_type = saved_items.entity_type
 AND projections.entity_id = saved_items.entity_id
 AND projections.visibility_status = 'PUBLIC'
 AND projections.reconciliation_fail_closed_at IS NULL
 AND projections.search_document_version > 0
 AND projections.search_document_version = projections.projection_revision
CROSS JOIN LATERAL (
    SELECT evaluated.match_rank,
           evaluated.match_kind,
           fields.matched_field,
           fields.matched_locale,
           fields.matched_value
    FROM (
        VALUES
            ('TITLE'::text, 'EN'::text, 1, projections.search_title_en_v1, projections.title_en),
            ('TITLE'::text, 'RU'::text, 1, projections.search_title_ru_v1, projections.title_ru),
            ('TITLE'::text, 'KK'::text, 1, projections.search_title_kk_v1, projections.title_kk),
            ('CITY'::text, 'EN'::text, 2, projections.search_city_en_v1, projections.city_en),
            ('CITY'::text, 'RU'::text, 2, projections.search_city_ru_v1, projections.city_ru),
            ('CITY'::text, 'KK'::text, 2, projections.search_city_kk_v1, projections.city_kk),
            ('COUNTRY'::text, 'EN'::text, 3, projections.search_country_en_v1, projections.country_en),
            ('COUNTRY'::text, 'RU'::text, 3, projections.search_country_ru_v1, projections.country_ru),
            ('COUNTRY'::text, 'KK'::text, 3, projections.search_country_kk_v1, projections.country_kk)
    ) AS fields(matched_field, matched_locale, field_priority, normalized_value, matched_value)
    CROSS JOIN LATERAL (
        SELECT fields.normalized_value = $3::text AS full_field_exact,
               string_to_array(fields.normalized_value, ' ') @> $4::text[] AS all_tokens_exact,
               starts_with(fields.normalized_value, $3::text)
               OR NOT EXISTS (
                   SELECT 1
                   FROM unnest($4::text[]) AS query_token(value)
                   WHERE NOT EXISTS (
                       SELECT 1
                       FROM unnest(string_to_array(fields.normalized_value, ' ')) AS field_token(value)
                       WHERE starts_with(field_token.value, query_token.value)
                   )
               ) AS field_or_tokens_prefix
    ) AS characteristics
    CROSS JOIN LATERAL (
        SELECT CASE
                   WHEN fields.matched_field = 'TITLE' AND characteristics.full_field_exact THEN 1
                   WHEN fields.matched_field = 'TITLE' AND characteristics.all_tokens_exact THEN 2
                   WHEN fields.matched_field = 'TITLE' AND characteristics.field_or_tokens_prefix THEN 3
                   WHEN fields.matched_field <> 'TITLE'
                    AND (characteristics.full_field_exact OR characteristics.all_tokens_exact) THEN 4
                   WHEN fields.matched_field <> 'TITLE' AND characteristics.field_or_tokens_prefix THEN 5
               END AS match_rank,
               CASE
                   WHEN characteristics.full_field_exact THEN 'EXACT'
                   WHEN characteristics.all_tokens_exact THEN 'TOKEN'
                   ELSE 'PREFIX'
               END AS match_kind
    ) AS evaluated
    WHERE fields.normalized_value IS NOT NULL
      AND evaluated.match_rank IS NOT NULL
    ORDER BY evaluated.match_rank,
             fields.field_priority,
             CASE
                 WHEN fields.matched_locale = $10::text THEN 0
                 WHEN fields.matched_locale = projections.source_default_locale THEN 1
                 WHEN fields.matched_locale = 'EN' THEN 2
                 WHEN fields.matched_locale = 'RU' THEN 3
                 WHEN fields.matched_locale = 'KK' THEN 4
                 ELSE 5
             END
    LIMIT 1
) AS winning_match
LEFT JOIN LATERAL (
    SELECT count(*)::bigint AS count
    FROM saved_collection_items AS memberships
    JOIN saved_collections AS collections
      ON collections.owner_user_id = memberships.owner_user_id
     AND collections.id = memberships.collection_id
     AND collections.lifecycle_state = 'ACTIVE'
    WHERE memberships.owner_user_id = saved_items.owner_user_id
      AND memberships.saved_item_id = saved_items.id
      AND memberships.membership_state = 'ACTIVE'
) AS effective_memberships ON TRUE
WHERE (
    $5::smallint IS NULL
    OR winning_match.match_rank > $5::smallint
    OR (
        winning_match.match_rank = $5::smallint
        AND (saved_items.saved_at, saved_items.id) < ($6::timestamptz, $7::uuid)
    )
)`

const savedSearchCollectionFilterSQL = `
  AND EXISTS (
      SELECT 1
      FROM saved_collection_items AS filter_membership
      WHERE filter_membership.owner_user_id = saved_items.owner_user_id
        AND filter_membership.saved_item_id = saved_items.id
        AND filter_membership.collection_id = $11::uuid
        AND filter_membership.membership_state = 'ACTIVE'
  )`

const savedSearchUncollectedFilterSQL = `
  AND NOT EXISTS (
      SELECT 1
      FROM saved_collection_items AS filter_membership
      JOIN saved_collections AS filter_collection
        ON filter_collection.owner_user_id = filter_membership.owner_user_id
       AND filter_collection.id = filter_membership.collection_id
       AND filter_collection.lifecycle_state = 'ACTIVE'
      WHERE filter_membership.owner_user_id = saved_items.owner_user_id
        AND filter_membership.saved_item_id = saved_items.id
        AND filter_membership.membership_state = 'ACTIVE'
  )`

const savedSearchOrderSQL = `
ORDER BY winning_match.match_rank ASC, saved_items.saved_at DESC, saved_items.id DESC
LIMIT $8`

const activeOwnerSearchCollectionSQL = `
SELECT 1
FROM saved_collections
WHERE owner_user_id = $1::uuid
  AND id = $2::uuid
  AND lifecycle_state = 'ACTIVE'`

func (r *PGSavedSearchRepository) Search(
	ctx context.Context,
	query savedsearchapp.Query,
) (savedsearchapp.Page, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return savedsearchapp.Page{}, savedsearchapp.ErrRepositoryUnavailable
	}
	if err := query.Validate(); err != nil {
		return savedsearchapp.Page{}, err
	}
	if query.Collection == nil {
		return r.search(ctx, r.pool, query)
	}

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.RepeatableRead,
		AccessMode: pgx.ReadOnly,
	})
	if err != nil {
		return savedsearchapp.Page{}, mapSavedSearchPGError(err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()

	var sentinel int
	err = tx.QueryRow(
		ctx,
		activeOwnerSearchCollectionSQL,
		query.OwnerUserID.String(),
		query.Collection.String(),
	).Scan(&sentinel)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedsearchapp.Page{}, savedsearchapp.ErrCollectionNotFound
	}
	if err != nil {
		return savedsearchapp.Page{}, mapSavedSearchPGError(err)
	}
	if sentinel != 1 {
		return savedsearchapp.Page{}, savedsearchapp.ErrDataInvariant
	}

	page, err := r.search(ctx, tx, query)
	if err != nil {
		return savedsearchapp.Page{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return savedsearchapp.Page{}, mapSavedSearchPGError(err)
	}
	return page, nil
}

func (r *PGSavedSearchRepository) search(
	ctx context.Context,
	executor savedSearchExecutor,
	query savedsearchapp.Query,
) (savedsearchapp.Page, error) {
	arguments := savedSearchArguments(query)
	rows, err := executor.Query(ctx, savedSearchSQL(query), arguments...)
	if err != nil {
		return savedsearchapp.Page{}, mapSavedSearchPGError(err)
	}
	defer rows.Close()

	items := make([]savedsearchapp.Item, 0, query.Limit+1)
	for rows.Next() {
		item, err := scanSavedSearchItem(rows, query.Locale, query.ReadAt)
		if err != nil {
			return savedsearchapp.Page{}, err
		}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return savedsearchapp.Page{}, mapSavedSearchPGError(err)
	}

	page := savedsearchapp.Page{}
	if len(items) > query.Limit {
		page.HasMore = true
		items = items[:query.Limit]
	}
	page.Items = items
	if page.HasMore {
		last := items[len(items)-1]
		page.Next = &savedsearchapp.Keyset{
			MatchRank: last.Match.Rank,
			SavedAt:   last.Relationship.SavedAt,
			ItemID:    last.ItemID,
		}
	}
	return page, nil
}

func savedSearchSQL(query savedsearchapp.Query) string {
	filter := ""
	if query.Collection != nil {
		filter = savedSearchCollectionFilterSQL
	} else if query.Uncollected {
		filter = savedSearchUncollectedFilterSQL
	}
	return savedSearchSelectSQL + filter + savedSearchOrderSQL
}

func savedSearchArguments(query savedsearchapp.Query) []any {
	var entityType any
	if query.EntityType != nil {
		entityType = string(*query.EntityType)
	}
	var afterRank any
	var afterSavedAt any
	var afterItemID any
	if query.After != nil {
		afterRank = int16(query.After.MatchRank)
		afterSavedAt = query.After.SavedAt.UTC()
		afterItemID = query.After.ItemID.String()
	}
	arguments := []any{
		query.OwnerUserID.String(),
		entityType,
		query.Term.Normalized(),
		query.Term.Tokens(),
		afterRank,
		afterSavedAt,
		afterItemID,
		query.Limit + 1,
		query.ReadAt.UTC(),
		string(query.Locale),
	}
	if query.Collection != nil {
		arguments = append(arguments, query.Collection.String())
	}
	return arguments
}

func scanSavedSearchItem(
	scanner savedSearchScanner,
	locale savedqueryapp.Locale,
	readAt time.Time,
) (savedsearchapp.Item, error) {
	var row savedListRow
	var matchRank int16
	var matchKind string
	var matchedField string
	var matchedLocale string
	var matchedValue string
	if err := scanner.Scan(
		&row.itemIDText,
		&row.entityType,
		&row.entityID,
		&row.generationText,
		&row.attributionText,
		&row.relationshipVersion,
		&row.dependentMembershipVersion,
		&row.savedAt,
		&row.effectiveCollectionCount,
		&row.sourceRevision,
		&row.projectionRevision,
		&row.visibilityRevision,
		&row.visibilityStatus,
		&row.visibilityValidatedAt,
		&row.projectionUpdatedAt,
		&row.sourceDefaultLocale,
		&row.titleEN,
		&row.titleRU,
		&row.titleKK,
		&row.subtitleEN,
		&row.subtitleRU,
		&row.subtitleKK,
		&row.mediaReference,
		&row.mediaReferenceRevision,
		&row.mediaValidUntil,
		&row.mediaLeaseCurrent,
		&row.canonicalDetailRoute,
		&matchRank,
		&matchKind,
		&matchedField,
		&matchedLocale,
		&matchedValue,
	); err != nil {
		return savedsearchapp.Item{}, mapSavedSearchPGError(err)
	}

	baseItem, err := row.toItem(locale, readAt)
	if err != nil || baseItem.Projection.ContentState != savedqueryapp.ContentStateAvailable ||
		baseItem.Projection.Public == nil {
		return savedsearchapp.Item{}, savedsearchapp.ErrDataInvariant
	}
	match, err := savedSearchMatch(
		savedsearchapp.MatchRank(matchRank),
		savedsearchapp.MatchKind(matchKind),
		savedsearchapp.MatchedField(matchedField),
		savedqueryapp.Locale(matchedLocale),
		matchedValue,
		baseItem.Projection.Public,
	)
	if err != nil {
		return savedsearchapp.Item{}, err
	}
	return savedsearchapp.Item{Item: baseItem, Match: match}, nil
}

func savedSearchMatch(
	rank savedsearchapp.MatchRank,
	kind savedsearchapp.MatchKind,
	field savedsearchapp.MatchedField,
	locale savedqueryapp.Locale,
	matchedValue string,
	public *savedqueryapp.PublicCardProjection,
) (savedsearchapp.Match, error) {
	if public == nil || !rank.IsValid() || !kind.IsValid() || !field.IsValid() || !locale.IsValid() {
		return savedsearchapp.Match{}, savedsearchapp.ErrDataInvariant
	}
	value, valid := boundedSavedDisplayText(matchedValue, 300)
	if !valid || !validSearchMatchShape(rank, kind, field) {
		return savedsearchapp.Match{}, savedsearchapp.ErrDataInvariant
	}
	match := savedsearchapp.Match{Rank: rank, Kind: kind, Field: field, Locale: locale}
	if field == savedsearchapp.MatchedFieldTitle && locale == public.DisplayLocale {
		if value != public.Title {
			return savedsearchapp.Match{}, savedsearchapp.ErrDataInvariant
		}
		return match, nil
	}
	match.AlternatePublicDisplay = &value
	return match, nil
}

func validSearchMatchShape(
	rank savedsearchapp.MatchRank,
	kind savedsearchapp.MatchKind,
	field savedsearchapp.MatchedField,
) bool {
	switch rank {
	case savedsearchapp.MatchRankTitleExact:
		return field == savedsearchapp.MatchedFieldTitle && kind == savedsearchapp.MatchKindExact
	case savedsearchapp.MatchRankTitleToken:
		return field == savedsearchapp.MatchedFieldTitle && kind == savedsearchapp.MatchKindToken
	case savedsearchapp.MatchRankTitlePrefix:
		return field == savedsearchapp.MatchedFieldTitle && kind == savedsearchapp.MatchKindPrefix
	case savedsearchapp.MatchRankLocationExactOrToken:
		return field != savedsearchapp.MatchedFieldTitle &&
			(kind == savedsearchapp.MatchKindExact || kind == savedsearchapp.MatchKindToken)
	case savedsearchapp.MatchRankLocationPrefix:
		return field != savedsearchapp.MatchedFieldTitle && kind == savedsearchapp.MatchKindPrefix
	default:
		return false
	}
}
