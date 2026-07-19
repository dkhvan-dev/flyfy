package repository

import (
	"context"
	"errors"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const savedCollectionReadSelectSQL = `
SELECT collection.id::text,
       collection.owner_user_id::text,
       collection.title,
       collection.lifecycle_state,
       collection.metadata_version,
       collection.lifecycle_version,
       collection.active_item_count,
       collection.organized_at,
       collection.created_at,
       collection.updated_at,
       cover.saved_at_snapshot,
       cover.saved_at,
       cover.entity_type,
       cover.entity_id,
       cover.visibility_status,
       cover.source_revision,
       cover.projection_revision,
       cover.visibility_revision,
       cover.visibility_validated_at,
       cover.source_default_locale,
       cover.title_en,
       cover.title_ru,
       cover.title_kk,
       cover.media_reference,
       cover.media_reference_revision,
       cover.media_valid_until
FROM saved_collections AS collection
LEFT JOIN LATERAL (
    SELECT membership.saved_at_snapshot,
           saved.saved_at,
           saved.entity_type,
           saved.entity_id,
           CASE
               WHEN projection.reconciliation_fail_closed_at IS NULL
               THEN projection.visibility_status
               ELSE 'UNAVAILABLE'
           END AS visibility_status,
           projection.source_revision,
           projection.projection_revision,
           projection.visibility_revision,
           projection.visibility_validated_at,
           CASE WHEN projection.reconciliation_fail_closed_at IS NULL THEN projection.source_default_locale END AS source_default_locale,
           CASE WHEN projection.reconciliation_fail_closed_at IS NULL THEN projection.title_en END AS title_en,
           CASE WHEN projection.reconciliation_fail_closed_at IS NULL THEN projection.title_ru END AS title_ru,
           CASE WHEN projection.reconciliation_fail_closed_at IS NULL THEN projection.title_kk END AS title_kk,
           CASE WHEN projection.reconciliation_fail_closed_at IS NULL THEN projection.media_reference END AS media_reference,
           CASE WHEN projection.reconciliation_fail_closed_at IS NULL THEN projection.media_reference_revision END AS media_reference_revision,
           CASE WHEN projection.reconciliation_fail_closed_at IS NULL THEN projection.media_valid_until END AS media_valid_until
    FROM saved_collection_items AS membership
    JOIN saved_items AS saved
      ON saved.owner_user_id = membership.owner_user_id
     AND saved.id = membership.saved_item_id
     AND saved.relationship_state = 'ACTIVE'
    JOIN saved_content_projections AS projection
      ON projection.entity_type = saved.entity_type
     AND projection.entity_id = saved.entity_id
    WHERE membership.owner_user_id = collection.owner_user_id
      AND membership.collection_id = collection.id
      AND membership.membership_state = 'ACTIVE'
    ORDER BY membership.saved_at_snapshot DESC, membership.saved_item_id DESC
    LIMIT 1
) AS cover ON TRUE
WHERE collection.owner_user_id = $1
  AND collection.lifecycle_state = 'ACTIVE'`

const listSavedCollectionsOrderSQL = `
ORDER BY collection.organized_at DESC, collection.id DESC
LIMIT 201`

const getSavedCollectionFilterSQL = `
  AND collection.id = $2`

const listSavedCollectionOptionsSQL = `
SELECT id::text, title, metadata_version, lifecycle_version
FROM saved_collections
WHERE owner_user_id = $1
  AND lifecycle_state = 'ACTIVE'
ORDER BY organized_at DESC, id DESC
LIMIT 201`

func (repository *PGSavedCollectionRepository) ListCollectionRecords(
	ctx context.Context,
	query savedcollectionapp.ListQuery,
) ([]savedcollectionapp.CollectionRecord, error) {
	if repository == nil || repository.pool == nil {
		return nil, savedcollectionapp.ErrRepositoryUnavailable
	}
	if err := validateSavedCollectionContext(ctx); err != nil {
		return nil, err
	}
	if err := query.Validate(); err != nil {
		return nil, err
	}
	rows, err := repository.pool.Query(
		ctx,
		savedCollectionReadSelectSQL+listSavedCollectionsOrderSQL,
		query.OwnerUserID.String(),
	)
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	defer rows.Close()
	records := make([]savedcollectionapp.CollectionRecord, 0)
	for rows.Next() {
		record, err := scanSavedCollectionRecord(
			rows, query.OwnerUserID, query.Locale, repository.limits,
		)
		if err != nil {
			return nil, err
		}
		records = append(records, record)
	}
	if err := rows.Err(); err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	if len(records) > int(repository.limits.MaxActiveCollections) {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	return records, nil
}

func (repository *PGSavedCollectionRepository) GetCollectionRecord(
	ctx context.Context,
	query savedcollectionapp.GetQuery,
) (savedcollectionapp.CollectionRecord, error) {
	if repository == nil || repository.pool == nil {
		return savedcollectionapp.CollectionRecord{}, savedcollectionapp.ErrRepositoryUnavailable
	}
	if err := validateSavedCollectionContext(ctx); err != nil {
		return savedcollectionapp.CollectionRecord{}, err
	}
	if err := query.Validate(); err != nil {
		return savedcollectionapp.CollectionRecord{}, err
	}
	record, err := scanSavedCollectionRecord(
		repository.pool.QueryRow(
			ctx,
			savedCollectionReadSelectSQL+getSavedCollectionFilterSQL,
			query.OwnerUserID.String(),
			query.CollectionID.String(),
		),
		query.OwnerUserID,
		query.Locale,
		repository.limits,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedcollectionapp.CollectionRecord{}, domain.ErrCollectionNotFound
	}
	if err != nil {
		return savedcollectionapp.CollectionRecord{}, err
	}
	return record, nil
}

func (repository *PGSavedCollectionRepository) GetTargetCollections(
	ctx context.Context,
	query savedcollectionapp.TargetSnapshotQuery,
) (savedcollectionapp.TargetCollectionsSnapshot, error) {
	if repository == nil || repository.pool == nil {
		return savedcollectionapp.TargetCollectionsSnapshot{}, savedcollectionapp.ErrRepositoryUnavailable
	}
	if err := validateSavedCollectionContext(ctx); err != nil {
		return savedcollectionapp.TargetCollectionsSnapshot{}, err
	}
	if err := query.Validate(); err != nil {
		return savedcollectionapp.TargetCollectionsSnapshot{}, err
	}
	tx, err := repository.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.RepeatableRead,
		AccessMode: pgx.ReadOnly,
	})
	if err != nil {
		return savedcollectionapp.TargetCollectionsSnapshot{}, mapSavedCollectionPGError(err)
	}
	defer rollbackCollectionTx(tx)
	relationship, found, err := scanSavedRelationship(tx.QueryRow(
		ctx,
		selectSavedRelationshipForCollectionAnalysisSQL,
		query.OwnerUserID.String(),
		string(query.Target.EntityType()),
		query.Target.EntityID(),
	))
	if err != nil {
		return savedcollectionapp.TargetCollectionsSnapshot{}, mapSavedCollectionPGError(err)
	}
	effectiveIDs := []uuid.UUID{}
	dependentVersion := uint64(0)
	if found {
		effectiveIDs, err = effectiveTargetCollectionIDs(ctx, tx, query.OwnerUserID, relationship)
		if err != nil {
			return savedcollectionapp.TargetCollectionsSnapshot{}, err
		}
		dependentVersion = relationship.dependentMembershipVersion
	}
	rows, err := tx.Query(ctx, listSavedCollectionOptionsSQL, query.OwnerUserID.String())
	if err != nil {
		return savedcollectionapp.TargetCollectionsSnapshot{}, mapSavedCollectionPGError(err)
	}
	options := make([]savedcollectionapp.CollectionOption, 0)
	for rows.Next() {
		var idText string
		var title string
		var metadataVersion int64
		var lifecycleVersion int64
		if err := rows.Scan(&idText, &title, &metadataVersion, &lifecycleVersion); err != nil {
			rows.Close()
			return savedcollectionapp.TargetCollectionsSnapshot{}, mapSavedCollectionPGError(err)
		}
		id, err := uuid.Parse(idText)
		if err != nil || id == uuid.Nil || metadataVersion <= 0 || lifecycleVersion <= 0 {
			rows.Close()
			return savedcollectionapp.TargetCollectionsSnapshot{}, savedcollectionapp.ErrDataInvariant
		}
		if _, err := savedcollectionapp.NormalizeStoredTitle(title); err != nil {
			rows.Close()
			return savedcollectionapp.TargetCollectionsSnapshot{}, savedcollectionapp.ErrDataInvariant
		}
		options = append(options, savedcollectionapp.CollectionOption{
			ID:               id,
			Title:            title,
			MetadataVersion:  uint64(metadataVersion),
			LifecycleVersion: uint64(lifecycleVersion),
		})
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return savedcollectionapp.TargetCollectionsSnapshot{}, mapSavedCollectionPGError(err)
	}
	rows.Close()
	if len(options) > int(repository.limits.MaxActiveCollections) ||
		len(effectiveIDs) > repository.limits.MaxDesiredCollectionIDs {
		return savedcollectionapp.TargetCollectionsSnapshot{}, savedcollectionapp.ErrDataInvariant
	}
	snapshot := savedcollectionapp.TargetCollectionsSnapshot{
		Target:                     query.Target,
		Relationship:               relationshipSnapshot(relationship, found),
		DependentMembershipVersion: dependentVersion,
		EffectiveCollectionIDs:     append([]uuid.UUID(nil), effectiveIDs...),
		CollectionOptions:          options,
		RecordedAt:                 query.ReadAt.UTC(),
	}
	if err := tx.Commit(ctx); err != nil {
		return savedcollectionapp.TargetCollectionsSnapshot{}, mapSavedCollectionPGError(err)
	}
	return snapshot, nil
}

type savedCollectionReadRow struct {
	id                     string
	ownerUserID            string
	title                  string
	lifecycle              string
	metadataVersion        int64
	lifecycleVersion       int64
	activeItemCount        int64
	organizedAt            time.Time
	createdAt              time.Time
	updatedAt              time.Time
	savedAtSnapshot        pgtype.Timestamptz
	savedAt                pgtype.Timestamptz
	entityType             pgtype.Text
	entityID               pgtype.Text
	visibilityStatus       pgtype.Text
	sourceRevision         pgtype.Int8
	projectionRevision     pgtype.Int8
	visibilityRevision     pgtype.Int8
	visibilityValidatedAt  pgtype.Timestamptz
	sourceDefaultLocale    pgtype.Text
	titleEN                pgtype.Text
	titleRU                pgtype.Text
	titleKK                pgtype.Text
	mediaReference         pgtype.Text
	mediaReferenceRevision pgtype.Int8
	mediaValidUntil        pgtype.Timestamptz
}

func scanSavedCollectionRecord(
	scanner rowScanner,
	expectedOwnerUserID uuid.UUID,
	locale savedcollectionapp.Locale,
	limits savedcollectionapp.Limits,
) (savedcollectionapp.CollectionRecord, error) {
	var row savedCollectionReadRow
	if err := scanner.Scan(
		&row.id,
		&row.ownerUserID,
		&row.title,
		&row.lifecycle,
		&row.metadataVersion,
		&row.lifecycleVersion,
		&row.activeItemCount,
		&row.organizedAt,
		&row.createdAt,
		&row.updatedAt,
		&row.savedAtSnapshot,
		&row.savedAt,
		&row.entityType,
		&row.entityID,
		&row.visibilityStatus,
		&row.sourceRevision,
		&row.projectionRevision,
		&row.visibilityRevision,
		&row.visibilityValidatedAt,
		&row.sourceDefaultLocale,
		&row.titleEN,
		&row.titleRU,
		&row.titleKK,
		&row.mediaReference,
		&row.mediaReferenceRevision,
		&row.mediaValidUntil,
	); err != nil {
		return savedcollectionapp.CollectionRecord{}, err
	}
	id, err := uuid.Parse(row.id)
	if err != nil || id == uuid.Nil {
		return savedcollectionapp.CollectionRecord{}, savedcollectionapp.ErrDataInvariant
	}
	ownerUserID, err := uuid.Parse(row.ownerUserID)
	if err != nil || ownerUserID == uuid.Nil || ownerUserID != expectedOwnerUserID ||
		row.lifecycle != string(savedcollectionapp.CollectionLifecycleActive) ||
		row.metadataVersion <= 0 || row.lifecycleVersion <= 0 || row.activeItemCount < 0 ||
		uint64(row.activeItemCount) > limits.MaxMembershipsPerCollection ||
		row.organizedAt.IsZero() || row.createdAt.IsZero() || row.updatedAt.IsZero() ||
		row.organizedAt.Before(row.createdAt) || row.updatedAt.Before(row.organizedAt) {
		return savedcollectionapp.CollectionRecord{}, savedcollectionapp.ErrDataInvariant
	}
	normalized, err := savedcollectionapp.NormalizeStoredTitle(row.title)
	if err != nil || normalized.Display != row.title {
		return savedcollectionapp.CollectionRecord{}, savedcollectionapp.ErrDataInvariant
	}
	record := savedcollectionapp.CollectionRecord{
		OwnerUserID: ownerUserID,
		Collection: savedcollectionapp.Collection{
			ID:               id,
			Title:            row.title,
			LifecycleState:   savedcollectionapp.CollectionLifecycleActive,
			MetadataVersion:  uint64(row.metadataVersion),
			LifecycleVersion: uint64(row.lifecycleVersion),
			ActiveItemCount:  uint64(row.activeItemCount),
			Cover:            savedcollectionapp.GenericCover(),
			OrganizedAt:      row.organizedAt.UTC(),
			CreatedAt:        row.createdAt.UTC(),
			UpdatedAt:        row.updatedAt.UTC(),
		},
	}
	candidate, err := row.coverCandidate(id, locale)
	if err != nil {
		return savedcollectionapp.CollectionRecord{}, err
	}
	record.CoverCandidate = candidate
	return record, nil
}

func (row savedCollectionReadRow) coverCandidate(
	collectionID uuid.UUID,
	requestedLocale savedcollectionapp.Locale,
) (*savedcollectionapp.CoverCandidate, error) {
	if !row.savedAtSnapshot.Valid {
		if row.anyCoverColumnPresent() {
			return nil, savedcollectionapp.ErrDataInvariant
		}
		return nil, nil
	}
	if !row.savedAt.Valid || !row.savedAtSnapshot.Time.Equal(row.savedAt.Time) ||
		!row.entityType.Valid || !row.entityID.Valid || !row.visibilityStatus.Valid {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	target, err := domain.NewSavedTarget(domain.EntityType(row.entityType.String), row.entityID.String)
	if err != nil {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	visibility := domain.VisibilityStatus(row.visibilityStatus.String)
	if !visibility.IsValid() ||
		(visibility == domain.VisibilityPrivate && target.EntityType() != domain.EntityTypeActivity) {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	if visibility != domain.VisibilityPublic {
		if row.anySelectedProjectionPayloadPresent() {
			return nil, savedcollectionapp.ErrDataInvariant
		}
		return nil, nil
	}
	if !row.sourceRevision.Valid || row.sourceRevision.Int64 <= 0 ||
		!row.projectionRevision.Valid || row.projectionRevision.Int64 <= 0 ||
		!row.visibilityRevision.Valid || row.visibilityRevision.Int64 <= 0 ||
		!row.visibilityValidatedAt.Valid || row.visibilityValidatedAt.Time.IsZero() ||
		!row.sourceDefaultLocale.Valid {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	defaultLocale := savedcollectionapp.Locale(row.sourceDefaultLocale.String)
	if !defaultLocale.IsValid() {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	title, ok := selectSavedCollectionTitle(
		requestedLocale,
		defaultLocale,
		savedCollectionLocalizedText{EN: row.titleEN, RU: row.titleRU, KK: row.titleKK},
	)
	if !ok {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	mediaColumnsPresent := 0
	for _, present := range []bool{
		row.mediaReference.Valid,
		row.mediaReferenceRevision.Valid,
		row.mediaValidUntil.Valid,
	} {
		if present {
			mediaColumnsPresent++
		}
	}
	if mediaColumnsPresent == 0 {
		return nil, nil
	}
	if mediaColumnsPresent != 3 || row.mediaReferenceRevision.Int64 <= 0 ||
		row.mediaValidUntil.Time.IsZero() ||
		!row.mediaValidUntil.Time.After(row.visibilityValidatedAt.Time) ||
		row.mediaValidUntil.Time.After(row.visibilityValidatedAt.Time.Add(15*time.Minute)) ||
		!validOpaqueMediaReference(row.mediaReference.String) {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	return &savedcollectionapp.CoverCandidate{
		CollectionID:          collectionID,
		Target:                target,
		Title:                 title,
		OpaqueReference:       row.mediaReference.String,
		ReferenceRevision:     uint64(row.mediaReferenceRevision.Int64),
		VisibilityValidatedAt: row.visibilityValidatedAt.Time.UTC(),
		ValidUntil:            row.mediaValidUntil.Time.UTC(),
	}, nil
}

func (row savedCollectionReadRow) anySelectedProjectionPayloadPresent() bool {
	return row.sourceDefaultLocale.Valid || row.titleEN.Valid || row.titleRU.Valid ||
		row.titleKK.Valid || row.mediaReference.Valid || row.mediaReferenceRevision.Valid ||
		row.mediaValidUntil.Valid
}

func (row savedCollectionReadRow) anyCoverColumnPresent() bool {
	return row.savedAt.Valid || row.entityType.Valid || row.entityID.Valid ||
		row.visibilityStatus.Valid || row.sourceRevision.Valid || row.projectionRevision.Valid ||
		row.visibilityRevision.Valid || row.visibilityValidatedAt.Valid ||
		row.sourceDefaultLocale.Valid || row.titleEN.Valid || row.titleRU.Valid ||
		row.titleKK.Valid || row.mediaReference.Valid || row.mediaReferenceRevision.Valid ||
		row.mediaValidUntil.Valid
}

type savedCollectionLocalizedText struct {
	EN pgtype.Text
	RU pgtype.Text
	KK pgtype.Text
}

func (text savedCollectionLocalizedText) forLocale(locale savedcollectionapp.Locale) pgtype.Text {
	switch locale {
	case savedcollectionapp.LocaleEN:
		return text.EN
	case savedcollectionapp.LocaleRU:
		return text.RU
	case savedcollectionapp.LocaleKK:
		return text.KK
	default:
		return pgtype.Text{}
	}
}

func selectSavedCollectionTitle(
	requested savedcollectionapp.Locale,
	defaultLocale savedcollectionapp.Locale,
	titles savedCollectionLocalizedText,
) (string, bool) {
	order := []savedcollectionapp.Locale{
		requested,
		defaultLocale,
		savedcollectionapp.LocaleEN,
		savedcollectionapp.LocaleRU,
		savedcollectionapp.LocaleKK,
	}
	seen := make(map[savedcollectionapp.Locale]struct{}, len(order))
	for _, locale := range order {
		if _, duplicate := seen[locale]; duplicate {
			continue
		}
		seen[locale] = struct{}{}
		value := titles.forLocale(locale)
		if !value.Valid {
			continue
		}
		if title, valid := boundedSavedDisplayText(value.String, 300); valid {
			return title, true
		}
	}
	return "", false
}

func validOpaqueMediaReference(value string) bool {
	return value != "" && len(value) <= 2048 && utf8.ValidString(value) &&
		value == strings.TrimSpace(value) && strings.IndexFunc(value, unicode.IsControl) < 0
}
