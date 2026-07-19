package repository

import (
	"context"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const savedItemsListSelectSQL = `
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
       CASE
           WHEN projections.reconciliation_fail_closed_at IS NULL
           THEN projections.visibility_status
           ELSE 'UNAVAILABLE'
       END,
       projections.visibility_validated_at,
       projections.updated_at,
       CASE WHEN projections.visibility_status = 'PUBLIC' AND projections.reconciliation_fail_closed_at IS NULL THEN projections.source_default_locale END,
       CASE WHEN projections.visibility_status = 'PUBLIC' AND projections.reconciliation_fail_closed_at IS NULL THEN projections.title_en END,
       CASE WHEN projections.visibility_status = 'PUBLIC' AND projections.reconciliation_fail_closed_at IS NULL THEN projections.title_ru END,
       CASE WHEN projections.visibility_status = 'PUBLIC' AND projections.reconciliation_fail_closed_at IS NULL THEN projections.title_kk END,
       CASE WHEN projections.visibility_status = 'PUBLIC' AND projections.reconciliation_fail_closed_at IS NULL THEN projections.subtitle_en END,
       CASE WHEN projections.visibility_status = 'PUBLIC' AND projections.reconciliation_fail_closed_at IS NULL THEN projections.subtitle_ru END,
       CASE WHEN projections.visibility_status = 'PUBLIC' AND projections.reconciliation_fail_closed_at IS NULL THEN projections.subtitle_kk END,
       CASE
           WHEN projections.visibility_status = 'PUBLIC'
            AND projections.reconciliation_fail_closed_at IS NULL THEN projections.media_reference
       END,
       CASE
           WHEN projections.visibility_status = 'PUBLIC'
            AND projections.reconciliation_fail_closed_at IS NULL THEN projections.media_reference_revision
       END,
       CASE
           WHEN projections.visibility_status = 'PUBLIC'
            AND projections.reconciliation_fail_closed_at IS NULL THEN projections.media_valid_until
       END,
       CASE
           WHEN projections.visibility_status = 'PUBLIC'
            AND projections.reconciliation_fail_closed_at IS NULL
            AND projections.media_valid_until IS NOT NULL
           THEN projections.media_valid_until > $6::timestamptz
       END,
       CASE WHEN projections.visibility_status = 'PUBLIC' AND projections.reconciliation_fail_closed_at IS NULL THEN projections.canonical_detail_route END
FROM saved_items
JOIN saved_content_projections AS projections
  ON projections.entity_type = saved_items.entity_type
 AND projections.entity_id = saved_items.entity_id
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
WHERE saved_items.owner_user_id = $1::uuid
  AND saved_items.relationship_state = 'ACTIVE'
  AND ($2::text IS NULL OR saved_items.entity_type = $2::text)
  AND (
      $3::timestamptz IS NULL
      OR (saved_items.saved_at, saved_items.id) < ($3::timestamptz, $4::uuid)
  )`

const savedItemsCollectionFilterSQL = `
  AND EXISTS (
      SELECT 1
      FROM saved_collection_items AS filter_membership
      WHERE filter_membership.owner_user_id = saved_items.owner_user_id
        AND filter_membership.saved_item_id = saved_items.id
        AND filter_membership.collection_id = $7::uuid
        AND filter_membership.membership_state = 'ACTIVE'
  )`

const savedItemsUncollectedFilterSQL = `
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

const savedItemsListOrderSQL = `
ORDER BY saved_items.saved_at DESC, saved_items.id DESC
LIMIT $5`

const activeOwnerCollectionSQL = `
SELECT 1
FROM saved_collections
WHERE owner_user_id = $1::uuid
  AND id = $2::uuid
  AND lifecycle_state = 'ACTIVE'`

func (r *PGSavedQueryRepository) ListItems(
	ctx context.Context,
	query savedqueryapp.ListQuery,
) (savedqueryapp.Page, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return savedqueryapp.Page{}, savedqueryapp.ErrRepositoryUnavailable
	}
	if err := query.Validate(); err != nil {
		return savedqueryapp.Page{}, err
	}
	if query.Collection == nil {
		return r.listItems(ctx, r.pool, query)
	}

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.RepeatableRead,
		AccessMode: pgx.ReadOnly,
	})
	if err != nil {
		return savedqueryapp.Page{}, mapSavedQueryPGError(err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()

	var sentinel int
	err = tx.QueryRow(ctx, activeOwnerCollectionSQL, query.OwnerUserID.String(), query.Collection.String()).Scan(&sentinel)
	if isSavedQueryNotFound(err) {
		return savedqueryapp.Page{}, savedqueryapp.ErrCollectionNotFound
	}
	if err != nil {
		return savedqueryapp.Page{}, mapSavedQueryPGError(err)
	}
	if sentinel != 1 {
		return savedqueryapp.Page{}, savedqueryapp.ErrDataInvariant
	}

	page, err := r.listItems(ctx, tx, query)
	if err != nil {
		return savedqueryapp.Page{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return savedqueryapp.Page{}, mapSavedQueryPGError(err)
	}
	return page, nil
}

func (r *PGSavedQueryRepository) listItems(
	ctx context.Context,
	executor savedQueryExecutor,
	query savedqueryapp.ListQuery,
) (savedqueryapp.Page, error) {
	entityType, afterSavedAt, afterItemID, collectionID := savedListArguments(query)
	arguments := []any{
		query.OwnerUserID.String(),
		entityType,
		afterSavedAt,
		afterItemID,
		query.Limit + 1,
		query.ReadAt.UTC(),
	}
	if query.Collection != nil {
		arguments = append(arguments, collectionID)
	}
	rows, err := executor.Query(ctx, savedItemsListSQL(query), arguments...)
	if err != nil {
		return savedqueryapp.Page{}, mapSavedQueryPGError(err)
	}
	defer rows.Close()

	items := make([]savedqueryapp.Item, 0, query.Limit+1)
	for rows.Next() {
		item, err := scanSavedListItem(rows, query.Locale, query.ReadAt)
		if err != nil {
			return savedqueryapp.Page{}, err
		}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return savedqueryapp.Page{}, mapSavedQueryPGError(err)
	}

	page := savedqueryapp.Page{}
	if len(items) > query.Limit {
		page.HasMore = true
		items = items[:query.Limit]
	}
	page.Items = items
	if page.HasMore {
		last := items[len(items)-1]
		page.Next = &savedqueryapp.Keyset{
			SavedAt: last.Relationship.SavedAt,
			ItemID:  last.ItemID,
		}
	}
	return page, nil
}

func savedItemsListSQL(query savedqueryapp.ListQuery) string {
	filter := ""
	if query.Collection != nil {
		filter = savedItemsCollectionFilterSQL
	} else if query.Uncollected {
		filter = savedItemsUncollectedFilterSQL
	}
	return savedItemsListSelectSQL + filter + savedItemsListOrderSQL
}

func savedListArguments(query savedqueryapp.ListQuery) (any, any, any, any) {
	var entityType any
	if query.EntityType != nil {
		entityType = string(*query.EntityType)
	}
	var afterSavedAt any
	var afterItemID any
	if query.After != nil {
		afterSavedAt = query.After.SavedAt.UTC()
		afterItemID = query.After.ItemID.String()
	}
	var collectionID any
	if query.Collection != nil {
		collectionID = query.Collection.String()
	}
	return entityType, afterSavedAt, afterItemID, collectionID
}

type savedListRow struct {
	itemIDText                 string
	entityType                 string
	entityID                   string
	generationText             string
	attributionText            string
	relationshipVersion        int64
	dependentMembershipVersion int64
	savedAt                    time.Time
	effectiveCollectionCount   int64
	sourceRevision             int64
	projectionRevision         int64
	visibilityRevision         int64
	visibilityStatus           string
	visibilityValidatedAt      pgtype.Timestamptz
	projectionUpdatedAt        time.Time
	sourceDefaultLocale        pgtype.Text
	titleEN                    pgtype.Text
	titleRU                    pgtype.Text
	titleKK                    pgtype.Text
	subtitleEN                 pgtype.Text
	subtitleRU                 pgtype.Text
	subtitleKK                 pgtype.Text
	mediaReference             pgtype.Text
	mediaReferenceRevision     pgtype.Int8
	mediaValidUntil            pgtype.Timestamptz
	mediaLeaseCurrent          pgtype.Bool
	canonicalDetailRoute       pgtype.Text
}

func scanSavedListItem(
	scanner savedQueryScanner,
	locale savedqueryapp.Locale,
	readAt time.Time,
) (savedqueryapp.Item, error) {
	var row savedListRow
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
	); err != nil {
		return savedqueryapp.Item{}, mapSavedQueryPGError(err)
	}
	return row.toItem(locale, readAt)
}

func (row savedListRow) toItem(locale savedqueryapp.Locale, readAt time.Time) (savedqueryapp.Item, error) {
	itemID, itemIDValid := parseNonNilUUID(row.itemIDText)
	generation, generationValid := parseNonNilUUID(row.generationText)
	attribution, attributionValid := parseNonNilUUID(row.attributionText)
	target, targetErr := domain.NewSavedTarget(domain.EntityType(row.entityType), row.entityID)
	if !itemIDValid || !generationValid || !attributionValid || targetErr != nil ||
		row.relationshipVersion <= 0 || row.dependentMembershipVersion < 0 ||
		row.effectiveCollectionCount < 0 ||
		row.effectiveCollectionCount > savedqueryapp.MaxEffectiveCollectionCount ||
		!validSavedQueryTime(row.savedAt) ||
		row.sourceRevision < 0 || row.projectionRevision < 0 || row.visibilityRevision < 0 {
		return savedqueryapp.Item{}, savedqueryapp.ErrDataInvariant
	}
	visibility := domain.VisibilityStatus(row.visibilityStatus)
	if !visibility.IsValid() ||
		(visibility == domain.VisibilityPrivate && target.EntityType() != domain.EntityTypeActivity) {
		return savedqueryapp.Item{}, savedqueryapp.ErrDataInvariant
	}

	projection := savedqueryapp.CardProjection{
		ContentState: savedqueryapp.ContentStateUnavailable,
		Revisions: savedqueryapp.SourceRevisions{
			Source:     uint64(row.sourceRevision),
			Projection: uint64(row.projectionRevision),
			Visibility: uint64(row.visibilityRevision),
		},
	}
	if visibility == domain.VisibilityPublic {
		projection.Public = row.publicProjection(locale, readAt)
		if projection.Public != nil {
			projection.ContentState = savedqueryapp.ContentStateAvailable
		}
	}

	return savedqueryapp.Item{
		ItemID: itemID,
		Target: target,
		Relationship: savedqueryapp.ActiveRelationship{
			Generation:                 generation,
			Version:                    uint64(row.relationshipVersion),
			DependentMembershipVersion: uint64(row.dependentMembershipVersion),
			SavedAt:                    row.savedAt.UTC(),
			AttributionID:              attribution,
		},
		EffectiveCollectionCount: uint32(row.effectiveCollectionCount),
		Projection:               projection,
	}, nil
}

func (row savedListRow) publicProjection(
	requested savedqueryapp.Locale,
	readAt time.Time,
) *savedqueryapp.PublicCardProjection {
	if row.sourceRevision <= 0 || row.projectionRevision <= 0 || row.visibilityRevision <= 0 ||
		!row.sourceDefaultLocale.Valid || !row.visibilityValidatedAt.Valid ||
		!validSavedQueryTime(row.visibilityValidatedAt.Time) || !validSavedQueryTime(row.projectionUpdatedAt) {
		return nil
	}
	defaultLocale := savedqueryapp.Locale(row.sourceDefaultLocale.String)
	if !defaultLocale.IsValid() {
		return nil
	}
	titles := localizedPGText{EN: row.titleEN, RU: row.titleRU, KK: row.titleKK}
	subtitles := localizedPGText{EN: row.subtitleEN, RU: row.subtitleRU, KK: row.subtitleKK}
	if !titles.allValid(300, true) || !subtitles.allValid(500, false) || !row.mediaIsCoherent(readAt) {
		return nil
	}
	if !titles.forLocale(defaultLocale).Valid {
		return nil
	}
	displayLocale, title, ok := selectLocalizedTitle(requested, defaultLocale, titles)
	if !ok {
		return nil
	}
	if !row.canonicalDetailRoute.Valid {
		return nil
	}
	route := row.canonicalDetailRoute.String
	if !validStoredCanonicalRoute(route) {
		return nil
	}

	projection := &savedqueryapp.PublicCardProjection{
		DisplayLocale:        displayLocale,
		Title:                title,
		CanonicalDetailRoute: route,
		SourceUpdatedAt:      row.projectionUpdatedAt.UTC(),
	}
	if row.mediaReference.Valid {
		projection.MediaReference = &savedqueryapp.MediaReference{
			OpaqueReference:   row.mediaReference.String,
			ReferenceRevision: uint64(row.mediaReferenceRevision.Int64),
			ValidUntil:        row.mediaValidUntil.Time.UTC(),
		}
	}
	if subtitleValue := subtitles.forLocale(displayLocale); subtitleValue.Valid {
		if subtitle, valid := boundedSavedDisplayText(subtitleValue.String, 500); valid {
			projection.Subtitle = &subtitle
		}
	}
	return projection
}

func (row savedListRow) mediaIsCoherent(readAt time.Time) bool {
	if !row.mediaReference.Valid && !row.mediaReferenceRevision.Valid && !row.mediaValidUntil.Valid {
		return !row.mediaLeaseCurrent.Valid
	}
	if !row.mediaReference.Valid || !row.mediaReferenceRevision.Valid || !row.mediaValidUntil.Valid ||
		!row.mediaLeaseCurrent.Valid || row.mediaReferenceRevision.Int64 <= 0 ||
		!validSavedQueryTime(row.mediaValidUntil.Time) ||
		!row.mediaValidUntil.Time.After(row.visibilityValidatedAt.Time) ||
		row.mediaValidUntil.Time.After(row.visibilityValidatedAt.Time.Add(15*time.Minute)) ||
		row.mediaLeaseCurrent.Bool != row.mediaValidUntil.Time.After(readAt) {
		return false
	}
	_, valid := boundedSavedDisplayText(row.mediaReference.String, 2048)
	return valid
}

type localizedPGText struct {
	EN pgtype.Text
	RU pgtype.Text
	KK pgtype.Text
}

func (value localizedPGText) forLocale(locale savedqueryapp.Locale) pgtype.Text {
	switch locale {
	case savedqueryapp.LocaleEN:
		return value.EN
	case savedqueryapp.LocaleRU:
		return value.RU
	case savedqueryapp.LocaleKK:
		return value.KK
	default:
		return pgtype.Text{}
	}
}

func (value localizedPGText) allValid(maxRunes int, requireOne bool) bool {
	values := []pgtype.Text{value.EN, value.RU, value.KK}
	present := false
	for _, candidate := range values {
		if !candidate.Valid {
			continue
		}
		present = true
		if utf8.RuneCountInString(candidate.String) > maxRunes {
			return false
		}
		if _, valid := boundedSavedDisplayText(candidate.String, maxRunes); !valid {
			return false
		}
	}
	return present || !requireOne
}

func selectLocalizedTitle(
	requested savedqueryapp.Locale,
	defaultLocale savedqueryapp.Locale,
	titles localizedPGText,
) (savedqueryapp.Locale, string, bool) {
	order := []savedqueryapp.Locale{
		requested,
		defaultLocale,
		savedqueryapp.LocaleEN,
		savedqueryapp.LocaleRU,
		savedqueryapp.LocaleKK,
	}
	seen := make(map[savedqueryapp.Locale]struct{}, len(order))
	for _, locale := range order {
		if _, exists := seen[locale]; exists {
			continue
		}
		seen[locale] = struct{}{}
		candidate := titles.forLocale(locale)
		if !candidate.Valid {
			continue
		}
		if title, valid := boundedSavedDisplayText(candidate.String, 300); valid {
			return locale, title, true
		}
	}
	return "", "", false
}

func boundedSavedDisplayText(value string, maxRunes int) (string, bool) {
	if value == "" || maxRunes < 1 || !utf8.ValidString(value) || value != strings.TrimSpace(value) ||
		strings.IndexFunc(value, unicode.IsControl) >= 0 {
		return "", false
	}
	runes := []rune(value)
	if len(runes) > maxRunes {
		value = strings.TrimSpace(string(runes[:maxRunes]))
	}
	return value, value != ""
}

func validStoredCanonicalRoute(value string) bool {
	return strings.HasPrefix(value, "/") && len(value) <= 2048 &&
		!strings.ContainsAny(value, "?#%\\") &&
		value == strings.TrimSpace(value) && utf8.ValidString(value) &&
		strings.IndexFunc(value, unicode.IsControl) < 0
}

func parseNonNilUUID(value string) (uuid.UUID, bool) {
	parsed, err := uuid.Parse(value)
	return parsed, err == nil && parsed != uuid.Nil
}

func validSavedQueryTime(value time.Time) bool {
	return !value.IsZero() && value.UnixMicro() > 0
}
