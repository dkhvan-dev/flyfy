package repository

import (
	"context"
	"errors"
	"math"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const selectEffectiveTargetCollectionIDsSQL = `
SELECT membership.collection_id::text
FROM saved_collection_items AS membership
JOIN saved_collections AS collection
  ON collection.owner_user_id = membership.owner_user_id
 AND collection.id = membership.collection_id
 AND collection.lifecycle_state = 'ACTIVE'
WHERE membership.owner_user_id = $1
  AND membership.saved_item_id = $2
  AND membership.membership_state = 'ACTIVE'
ORDER BY membership.collection_id
LIMIT 201`

const lockSavedCollectionsByIDsSQL = `
SELECT id::text,
       client_creation_id::text,
       title,
       normalized_title_key,
       lifecycle_state,
       lifecycle_version,
       metadata_version,
       items_version,
       active_item_count,
       created_at,
       organized_at,
       updated_at,
       deleted_at
FROM saved_collections
WHERE owner_user_id = $1
  AND id::text = ANY($2::text[])
ORDER BY id
FOR UPDATE`

const lockSavedMembershipsForTargetSQL = `
SELECT id::text,
       collection_id::text,
       membership_state,
       membership_version,
       saved_at_snapshot,
       added_at,
       updated_at,
       removed_at
FROM saved_collection_items
WHERE owner_user_id = $1
  AND saved_item_id = $2
  AND collection_id::text = ANY($3::text[])
ORDER BY collection_id, id
FOR UPDATE`

const insertSavedCollectionMembershipSQL = `
INSERT INTO saved_collection_items (
    id,
    owner_user_id,
    collection_id,
    saved_item_id,
    membership_state,
    membership_version,
    saved_at_snapshot,
    added_at,
    updated_at
) VALUES ($1, $2, $3, $4, 'ACTIVE', 1, $5, $6, $6)`

const reactivateSavedCollectionMembershipSQL = `
UPDATE saved_collection_items
SET membership_state = 'ACTIVE',
    membership_version = membership_version + 1,
    saved_at_snapshot = $5,
    removal_reason = NULL,
    added_at = $6,
    updated_at = $6,
    removed_at = NULL,
    purge_eligible_at = NULL
WHERE owner_user_id = $1
  AND collection_id = $2
  AND saved_item_id = $3
  AND id = $4
  AND membership_state = 'REMOVED'
  AND membership_version = $7`

const removeSavedCollectionMembershipSQL = `
UPDATE saved_collection_items
SET membership_state = 'REMOVED',
    membership_version = membership_version + 1,
    removal_reason = 'DESIRED_SET_REMOVAL',
    updated_at = $5,
    removed_at = $5,
    purge_eligible_at = $5::timestamptz + INTERVAL '14 days'
WHERE owner_user_id = $1
  AND collection_id = $2
  AND saved_item_id = $3
  AND id = $4
  AND membership_state = 'ACTIVE'
  AND membership_version = $6`

const updateSavedCollectionMembershipCountSQL = `
UPDATE saved_collections
SET active_item_count = $3,
    items_version = items_version + 1,
    organized_at = $4,
    updated_at = $4
WHERE owner_user_id = $1
  AND id = $2
  AND lifecycle_state = 'ACTIVE'
  AND active_item_count = $5
  AND items_version = $6
RETURNING active_item_count, items_version, organized_at, updated_at`

const incrementSavedRelationshipMembershipVersionSQL = `
UPDATE saved_items
SET dependent_membership_version = dependent_membership_version + 1,
    updated_at = $4
WHERE owner_user_id = $1
  AND id = $2
  AND relationship_state = 'ACTIVE'
  AND relationship_version = $3
  AND dependent_membership_version = $5
RETURNING id::text,
          relationship_state,
          state_generation::text,
          relationship_attribution_id::text,
          relationship_version,
          dependent_membership_version,
          saved_at,
          updated_at`

type savedMembershipState struct {
	id              uuid.UUID
	collectionID    uuid.UUID
	state           string
	version         uint64
	savedAtSnapshot time.Time
	addedAt         time.Time
	updatedAt       time.Time
	removedAt       *time.Time
}

func effectiveTargetCollectionIDs(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	relationship savedRelationshipState,
) ([]uuid.UUID, error) {
	rows, err := tx.Query(
		ctx,
		selectEffectiveTargetCollectionIDsSQL,
		ownerUserID.String(),
		relationship.id.String(),
	)
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	defer rows.Close()
	result := make([]uuid.UUID, 0)
	for rows.Next() {
		var text string
		if err := rows.Scan(&text); err != nil {
			return nil, mapSavedCollectionPGError(err)
		}
		parsed, err := uuid.Parse(text)
		if err != nil || parsed == uuid.Nil {
			return nil, savedcollectionapp.ErrDataInvariant
		}
		result = append(result, parsed)
	}
	if err := rows.Err(); err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	if len(result) > savedcollectionapp.DefaultMaxDesiredCollectionIDs {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	if relationship.state != domain.RelationshipStateActive && len(result) != 0 {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	return result, nil
}

func lockSavedCollectionsByIDs(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	collectionIDs []uuid.UUID,
) (map[uuid.UUID]savedCollectionState, error) {
	if len(collectionIDs) == 0 {
		return map[uuid.UUID]savedCollectionState{}, nil
	}
	texts := uuidTexts(collectionIDs)
	rows, err := tx.Query(ctx, lockSavedCollectionsByIDsSQL, ownerUserID.String(), texts)
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	defer rows.Close()
	states := make(map[uuid.UUID]savedCollectionState, len(collectionIDs))
	for rows.Next() {
		state, found, err := scanSavedCollectionState(rows)
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, savedcollectionapp.ErrDataInvariant
		}
		states[state.id] = state
	}
	if err := rows.Err(); err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	return states, nil
}

func lockSavedMembershipsForTarget(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	savedItemID uuid.UUID,
	collectionIDs []uuid.UUID,
) (map[uuid.UUID]savedMembershipState, error) {
	if savedItemID == uuid.Nil || len(collectionIDs) == 0 {
		return map[uuid.UUID]savedMembershipState{}, nil
	}
	rows, err := tx.Query(
		ctx,
		lockSavedMembershipsForTargetSQL,
		ownerUserID.String(),
		savedItemID.String(),
		uuidTexts(collectionIDs),
	)
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	defer rows.Close()
	states := make(map[uuid.UUID]savedMembershipState, len(collectionIDs))
	for rows.Next() {
		state, err := scanSavedMembership(rows)
		if err != nil {
			return nil, err
		}
		if _, duplicate := states[state.collectionID]; duplicate {
			return nil, savedcollectionapp.ErrDataInvariant
		}
		states[state.collectionID] = state
	}
	if err := rows.Err(); err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	return states, nil
}

func scanSavedMembership(scanner rowScanner) (savedMembershipState, error) {
	var idText string
	var collectionIDText string
	var state string
	var version int64
	var savedAtSnapshot time.Time
	var addedAt time.Time
	var updatedAt time.Time
	var removedAt pgtype.Timestamptz
	if err := scanner.Scan(
		&idText,
		&collectionIDText,
		&state,
		&version,
		&savedAtSnapshot,
		&addedAt,
		&updatedAt,
		&removedAt,
	); err != nil {
		return savedMembershipState{}, mapSavedCollectionPGError(err)
	}
	id, err := uuid.Parse(idText)
	if err != nil || id == uuid.Nil {
		return savedMembershipState{}, savedcollectionapp.ErrDataInvariant
	}
	collectionID, err := uuid.Parse(collectionIDText)
	if err != nil || collectionID == uuid.Nil || version <= 0 || savedAtSnapshot.IsZero() ||
		addedAt.IsZero() || updatedAt.IsZero() {
		return savedMembershipState{}, savedcollectionapp.ErrDataInvariant
	}
	result := savedMembershipState{
		id:              id,
		collectionID:    collectionID,
		state:           state,
		version:         uint64(version),
		savedAtSnapshot: savedAtSnapshot.UTC(),
		addedAt:         addedAt.UTC(),
		updatedAt:       updatedAt.UTC(),
	}
	if removedAt.Valid {
		value := removedAt.Time.UTC()
		result.removedAt = &value
	}
	if (state == "ACTIVE" && result.removedAt != nil) ||
		(state == "REMOVED" && result.removedAt == nil) ||
		(state != "ACTIVE" && state != "REMOVED") {
		return savedMembershipState{}, savedcollectionapp.ErrDataInvariant
	}
	return result, nil
}

func addSavedCollectionMembership(
	ctx context.Context,
	tx pgx.Tx,
	ids savedCollectionIDGenerator,
	ownerUserID uuid.UUID,
	collectionID uuid.UUID,
	relationship savedRelationshipState,
	existing *savedMembershipState,
	serverNow time.Time,
) error {
	if existing == nil {
		membershipID, err := newSavedCollectionUUID(ids)
		if err != nil {
			return err
		}
		tag, err := tx.Exec(
			ctx,
			insertSavedCollectionMembershipSQL,
			membershipID.String(),
			ownerUserID.String(),
			collectionID.String(),
			relationship.id.String(),
			relationship.savedAt.UTC(),
			serverNow.UTC(),
		)
		if err != nil {
			return mapSavedCollectionPGError(err)
		}
		if tag.RowsAffected() != 1 {
			return savedcollectionapp.ErrDataInvariant
		}
		return nil
	}
	if existing.state != "REMOVED" || existing.version >= math.MaxInt64 ||
		serverNow.Before(existing.updatedAt) {
		return savedcollectionapp.ErrDataInvariant
	}
	tag, err := tx.Exec(
		ctx,
		reactivateSavedCollectionMembershipSQL,
		ownerUserID.String(),
		collectionID.String(),
		relationship.id.String(),
		existing.id.String(),
		relationship.savedAt.UTC(),
		serverNow.UTC(),
		int64(existing.version),
	)
	if err != nil {
		return mapSavedCollectionPGError(err)
	}
	if tag.RowsAffected() != 1 {
		return domain.ErrMutationStale
	}
	return nil
}

func removeSavedCollectionMembership(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	collectionID uuid.UUID,
	relationship savedRelationshipState,
	existing savedMembershipState,
	serverNow time.Time,
) error {
	if existing.state != "ACTIVE" || existing.version >= math.MaxInt64 ||
		serverNow.Before(existing.updatedAt) {
		return savedcollectionapp.ErrDataInvariant
	}
	tag, err := tx.Exec(
		ctx,
		removeSavedCollectionMembershipSQL,
		ownerUserID.String(),
		collectionID.String(),
		relationship.id.String(),
		existing.id.String(),
		serverNow.UTC(),
		int64(existing.version),
	)
	if err != nil {
		return mapSavedCollectionPGError(err)
	}
	if tag.RowsAffected() != 1 {
		return domain.ErrMutationStale
	}
	return nil
}

func changeSavedCollectionItemCount(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	state savedCollectionState,
	delta int64,
	serverNow time.Time,
) (savedCollectionState, error) {
	newCount, ok := addUnsignedDelta(state.activeItemCount, delta)
	if !ok || state.itemsVersion >= math.MaxInt64 || serverNow.Before(state.updatedAt) ||
		serverNow.Before(state.organizedAt) {
		return savedCollectionState{}, savedcollectionapp.ErrDataInvariant
	}
	var activeItemCount int64
	var itemsVersion int64
	var organizedAt time.Time
	var updatedAt time.Time
	err := tx.QueryRow(
		ctx,
		updateSavedCollectionMembershipCountSQL,
		ownerUserID.String(),
		state.id.String(),
		int64(newCount),
		serverNow.UTC(),
		int64(state.activeItemCount),
		int64(state.itemsVersion),
	).Scan(&activeItemCount, &itemsVersion, &organizedAt, &updatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedCollectionState{}, domain.ErrMutationStale
	}
	if err != nil {
		return savedCollectionState{}, mapSavedCollectionPGError(err)
	}
	if activeItemCount != int64(newCount) || itemsVersion != int64(state.itemsVersion)+1 ||
		!organizedAt.Equal(serverNow) || !updatedAt.Equal(serverNow) {
		return savedCollectionState{}, savedcollectionapp.ErrDataInvariant
	}
	state.activeItemCount = newCount
	state.itemsVersion = uint64(itemsVersion)
	state.organizedAt = organizedAt.UTC()
	state.updatedAt = updatedAt.UTC()
	return state, nil
}

func incrementSavedRelationshipMembershipVersion(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	relationship savedRelationshipState,
	serverNow time.Time,
) (savedRelationshipState, error) {
	if relationship.relationshipVersion > math.MaxInt64 ||
		relationship.dependentMembershipVersion >= math.MaxInt64 ||
		serverNow.Before(relationship.updatedAt) {
		return savedRelationshipState{}, savedcollectionapp.ErrDataInvariant
	}
	state, found, err := scanSavedRelationship(tx.QueryRow(
		ctx,
		incrementSavedRelationshipMembershipVersionSQL,
		ownerUserID.String(),
		relationship.id.String(),
		int64(relationship.relationshipVersion),
		serverNow.UTC(),
		int64(relationship.dependentMembershipVersion),
	))
	if err != nil {
		return savedRelationshipState{}, mapSavedCollectionPGError(err)
	}
	if !found {
		return savedRelationshipState{}, domain.ErrMutationStale
	}
	if state.dependentMembershipVersion != relationship.dependentMembershipVersion+1 {
		return savedRelationshipState{}, savedcollectionapp.ErrDataInvariant
	}
	return state, nil
}

func unionSortedUUIDs(groups ...[]uuid.UUID) []uuid.UUID {
	set := make(map[uuid.UUID]struct{})
	for _, group := range groups {
		for _, value := range group {
			set[value] = struct{}{}
		}
	}
	values := make([]uuid.UUID, 0, len(set))
	for value := range set {
		values = append(values, value)
	}
	sort.Slice(values, func(left, right int) bool {
		return values[left].String() < values[right].String()
	})
	return values
}

func uuidTexts(values []uuid.UUID) []string {
	result := make([]string, len(values))
	for index, value := range values {
		result[index] = value.String()
	}
	return result
}
