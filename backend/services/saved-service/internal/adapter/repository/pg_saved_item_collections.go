package repository

import (
	"context"
	"errors"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const maxCollectionsPerSavedItem = 200

const findEffectiveCollectionIDsSQL = `
SELECT item.collection_id::text
FROM saved_collection_items AS item
JOIN saved_collections AS collection
  ON collection.owner_user_id = item.owner_user_id
 AND collection.id = item.collection_id
WHERE item.owner_user_id = $1
  AND item.saved_item_id = $2
  AND item.membership_state = 'ACTIVE'
  AND collection.lifecycle_state = 'ACTIVE'
ORDER BY item.collection_id
LIMIT 201`

const lockEffectiveCollectionsSQL = `
SELECT id::text, active_item_count, items_version, organized_at
FROM saved_collections
WHERE owner_user_id = $1
  AND id::text = ANY($2::text[])
  AND lifecycle_state = 'ACTIVE'
ORDER BY id
FOR UPDATE`

const lockEffectiveMembershipsSQL = `
SELECT id::text, collection_id::text
FROM saved_collection_items
WHERE owner_user_id = $1
  AND saved_item_id = $2
  AND collection_id::text = ANY($3::text[])
  AND membership_state = 'ACTIVE'
ORDER BY collection_id, id
FOR UPDATE`

const removeEffectiveMembershipsSQL = `
UPDATE saved_collection_items
SET membership_state = 'REMOVED',
    membership_version = membership_version + 1,
    removal_reason = 'GLOBAL_UNSAVE',
    updated_at = $4,
    removed_at = $4,
    purge_eligible_at = $4::timestamptz + INTERVAL '14 days'
WHERE owner_user_id = $1
  AND saved_item_id = $2
  AND id::text = ANY($3::text[])
  AND membership_state = 'ACTIVE'`

const updateEffectiveCollectionsSQL = `
UPDATE saved_collections
SET active_item_count = active_item_count - 1,
    items_version = items_version + 1,
    organized_at = $3,
    updated_at = $3
WHERE owner_user_id = $1
  AND id::text = ANY($2::text[])
  AND lifecycle_state = 'ACTIVE'
  AND active_item_count > 0`

const lockSavedCollectionUsageSQL = `
SELECT active_memberships_count, usage_version
FROM saved_collection_usage
WHERE owner_user_id = $1
FOR UPDATE`

const decrementSavedCollectionUsageSQL = `
UPDATE saved_collection_usage
SET active_memberships_count = active_memberships_count - $2,
    usage_version = usage_version + 1,
    updated_at = $3
WHERE owner_user_id = $1
  AND active_memberships_count >= $2
  AND usage_version = $4
RETURNING active_memberships_count, usage_version`

type effectiveSavedMemberships struct {
	collectionIDs []string
	membershipIDs []string
}

type savedCollectionUsageState struct {
	activeMemberships int64
	version           uint64
}

func lockEffectiveSavedMemberships(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	savedItemID uuid.UUID,
	serverNow time.Time,
) (effectiveSavedMemberships, error) {
	candidates, err := queryUUIDStrings(
		ctx,
		tx,
		findEffectiveCollectionIDsSQL,
		ownerUserID.String(),
		savedItemID.String(),
	)
	if err != nil || len(candidates) == 0 {
		return effectiveSavedMemberships{}, err
	}
	if len(candidates) > maxCollectionsPerSavedItem {
		return effectiveSavedMemberships{}, saveditemapp.ErrDataInvariant
	}

	rows, err := tx.Query(ctx, lockEffectiveCollectionsSQL, ownerUserID.String(), candidates)
	if err != nil {
		return effectiveSavedMemberships{}, mapSavedItemPGError(err)
	}
	activeCollections := make([]string, 0, len(candidates))
	for rows.Next() {
		var collectionID string
		var activeItemCount int64
		var itemsVersion int64
		var organizedAt time.Time
		if err := rows.Scan(&collectionID, &activeItemCount, &itemsVersion, &organizedAt); err != nil {
			rows.Close()
			return effectiveSavedMemberships{}, mapSavedItemPGError(err)
		}
		if _, err := parseCanonicalUUID(collectionID); err != nil || activeItemCount <= 0 ||
			itemsVersion < activeItemCount || itemsVersion < 0 || serverNow.Before(organizedAt) {
			rows.Close()
			return effectiveSavedMemberships{}, saveditemapp.ErrDataInvariant
		}
		activeCollections = append(activeCollections, collectionID)
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return effectiveSavedMemberships{}, mapSavedItemPGError(err)
	}
	rows.Close()
	if len(activeCollections) == 0 {
		return effectiveSavedMemberships{}, nil
	}

	rows, err = tx.Query(
		ctx,
		lockEffectiveMembershipsSQL,
		ownerUserID.String(),
		savedItemID.String(),
		activeCollections,
	)
	if err != nil {
		return effectiveSavedMemberships{}, mapSavedItemPGError(err)
	}
	membershipIDs := make([]string, 0, len(activeCollections))
	lockedCollectionIDs := make([]string, 0, len(activeCollections))
	seenCollection := make(map[string]struct{}, len(activeCollections))
	for rows.Next() {
		var membershipID string
		var collectionID string
		if err := rows.Scan(&membershipID, &collectionID); err != nil {
			rows.Close()
			return effectiveSavedMemberships{}, mapSavedItemPGError(err)
		}
		if _, err := parseCanonicalUUID(membershipID); err != nil {
			rows.Close()
			return effectiveSavedMemberships{}, saveditemapp.ErrDataInvariant
		}
		if _, duplicate := seenCollection[collectionID]; duplicate {
			rows.Close()
			return effectiveSavedMemberships{}, saveditemapp.ErrDataInvariant
		}
		seenCollection[collectionID] = struct{}{}
		membershipIDs = append(membershipIDs, membershipID)
		lockedCollectionIDs = append(lockedCollectionIDs, collectionID)
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return effectiveSavedMemberships{}, mapSavedItemPGError(err)
	}
	rows.Close()
	return effectiveSavedMemberships{
		collectionIDs: lockedCollectionIDs,
		membershipIDs: membershipIDs,
	}, nil
}

func removeLockedEffectiveMemberships(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	savedItemID uuid.UUID,
	memberships effectiveSavedMemberships,
	serverNow time.Time,
) error {
	if len(memberships.membershipIDs) == 0 {
		return nil
	}
	tag, err := tx.Exec(
		ctx,
		removeEffectiveMembershipsSQL,
		ownerUserID.String(),
		savedItemID.String(),
		memberships.membershipIDs,
		serverNow.UTC(),
	)
	if err != nil {
		return mapSavedItemPGError(err)
	}
	if tag.RowsAffected() != int64(len(memberships.membershipIDs)) {
		return domain.ErrMutationStale
	}
	tag, err = tx.Exec(
		ctx,
		updateEffectiveCollectionsSQL,
		ownerUserID.String(),
		memberships.collectionIDs,
		serverNow.UTC(),
	)
	if err != nil {
		return mapSavedItemPGError(err)
	}
	if tag.RowsAffected() != int64(len(memberships.collectionIDs)) {
		return saveditemapp.ErrDataInvariant
	}
	return nil
}

func lockSavedCollectionUsage(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
) (savedCollectionUsageState, error) {
	var activeMemberships int64
	var version int64
	err := tx.QueryRow(ctx, lockSavedCollectionUsageSQL, ownerUserID.String()).Scan(
		&activeMemberships,
		&version,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedCollectionUsageState{}, saveditemapp.ErrDataInvariant
	}
	if err != nil {
		return savedCollectionUsageState{}, mapSavedItemPGError(err)
	}
	if activeMemberships < 0 || version < 0 {
		return savedCollectionUsageState{}, saveditemapp.ErrDataInvariant
	}
	return savedCollectionUsageState{activeMemberships: activeMemberships, version: uint64(version)}, nil
}

func decrementSavedCollectionUsage(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	usage savedCollectionUsageState,
	count int,
	serverNow time.Time,
) error {
	if count <= 0 || int64(count) > usage.activeMemberships ||
		usage.version >= math.MaxInt64 {
		return saveditemapp.ErrDataInvariant
	}
	var activeMemberships int64
	var version int64
	err := tx.QueryRow(
		ctx,
		decrementSavedCollectionUsageSQL,
		ownerUserID.String(),
		int64(count),
		serverNow.UTC(),
		int64(usage.version),
	).Scan(&activeMemberships, &version)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.ErrMutationStale
	}
	if err != nil {
		return mapSavedItemPGError(err)
	}
	if activeMemberships != usage.activeMemberships-int64(count) || version != int64(usage.version)+1 {
		return saveditemapp.ErrDataInvariant
	}
	return nil
}

func queryUUIDStrings(
	ctx context.Context,
	tx pgx.Tx,
	query string,
	arguments ...any,
) ([]string, error) {
	rows, err := tx.Query(ctx, query, arguments...)
	if err != nil {
		return nil, mapSavedItemPGError(err)
	}
	defer rows.Close()
	values := make([]string, 0)
	for rows.Next() {
		var value string
		if err := rows.Scan(&value); err != nil {
			return nil, mapSavedItemPGError(err)
		}
		if _, err := parseCanonicalUUID(value); err != nil {
			return nil, saveditemapp.ErrDataInvariant
		}
		values = append(values, value)
	}
	if err := rows.Err(); err != nil {
		return nil, mapSavedItemPGError(err)
	}
	return values, nil
}
