package repository

import (
	"context"
	"errors"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const insertSavedCollectionUsageSQL = `
INSERT INTO saved_collection_usage (
    owner_user_id,
    active_collections_count,
    active_memberships_count,
    usage_version,
    created_at,
    updated_at
) VALUES ($1, 0, 0, 0, $2, $2)
ON CONFLICT (owner_user_id) DO NOTHING`

const lockSavedCollectionUsageForMutationSQL = `
SELECT active_collections_count, active_memberships_count, usage_version, updated_at
FROM saved_collection_usage
WHERE owner_user_id = $1
FOR UPDATE`

const updateSavedCollectionUsageForMutationSQL = `
UPDATE saved_collection_usage
SET active_collections_count = $2,
    active_memberships_count = $3,
    usage_version = usage_version + 1,
    updated_at = $4
WHERE owner_user_id = $1
  AND active_collections_count = $5
  AND active_memberships_count = $6
  AND usage_version = $7
RETURNING active_collections_count, active_memberships_count, usage_version, updated_at`

const lockSavedCollectionByIDSQL = `
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
  AND id = $2
FOR UPDATE`

const lockSavedCollectionByClientCreationIDSQL = `
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
  AND client_creation_id = $2
FOR UPDATE`

const findActiveSavedCollectionTitleConflictSQL = `
SELECT id::text
FROM saved_collections
WHERE owner_user_id = $1
  AND normalized_title_key = $2 COLLATE "C"
  AND lifecycle_state = 'ACTIVE'
  AND ($3::uuid IS NULL OR id <> $3::uuid)
LIMIT 1`

type savedCollectionState struct {
	id               uuid.UUID
	clientCreationID uuid.UUID
	title            *string
	normalizedTitle  *string
	lifecycle        savedcollectionapp.CollectionLifecycleState
	lifecycleVersion uint64
	metadataVersion  uint64
	itemsVersion     uint64
	activeItemCount  uint64
	createdAt        time.Time
	organizedAt      time.Time
	updatedAt        time.Time
	deletedAt        *time.Time
}

type savedCollectionUsageMutationState struct {
	activeCollections uint64
	activeMemberships uint64
	version           uint64
	updatedAt         time.Time
}

func ensureAndLockSavedCollectionUsage(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	serverNow time.Time,
) (savedCollectionUsageMutationState, error) {
	tag, err := tx.Exec(ctx, insertSavedCollectionUsageSQL, ownerUserID.String(), serverNow.UTC())
	if err != nil {
		return savedCollectionUsageMutationState{}, mapSavedCollectionPGError(err)
	}
	inserted := tag.RowsAffected() == 1

	state, found, err := lockExistingSavedCollectionUsage(ctx, tx, ownerUserID)
	if err != nil {
		return savedCollectionUsageMutationState{}, err
	}
	if !found {
		return savedCollectionUsageMutationState{}, savedcollectionapp.ErrDataInvariant
	}
	if inserted {
		var domainRowsExist bool
		if err := tx.QueryRow(ctx, `
SELECT EXISTS (
    SELECT 1 FROM saved_collections WHERE owner_user_id = $1
) OR EXISTS (
    SELECT 1 FROM saved_collection_items WHERE owner_user_id = $1
)`, ownerUserID.String()).Scan(&domainRowsExist); err != nil {
			return savedCollectionUsageMutationState{}, mapSavedCollectionPGError(err)
		}
		if domainRowsExist {
			return savedCollectionUsageMutationState{}, savedcollectionapp.ErrDataInvariant
		}
	}
	return state, nil
}

func lockExistingSavedCollectionUsage(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
) (savedCollectionUsageMutationState, bool, error) {
	var activeCollections int64
	var activeMemberships int64
	var version int64
	var updatedAt time.Time
	err := tx.QueryRow(
		ctx,
		lockSavedCollectionUsageForMutationSQL,
		ownerUserID.String(),
	).Scan(&activeCollections, &activeMemberships, &version, &updatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedCollectionUsageMutationState{}, false, nil
	}
	if err != nil {
		return savedCollectionUsageMutationState{}, false, mapSavedCollectionPGError(err)
	}
	if activeCollections < 0 || activeMemberships < 0 || version < 0 || updatedAt.IsZero() {
		return savedCollectionUsageMutationState{}, false, savedcollectionapp.ErrDataInvariant
	}
	return savedCollectionUsageMutationState{
		activeCollections: uint64(activeCollections),
		activeMemberships: uint64(activeMemberships),
		version:           uint64(version),
		updatedAt:         updatedAt.UTC(),
	}, true, nil
}

func changeSavedCollectionUsage(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	state savedCollectionUsageMutationState,
	collectionDelta int64,
	membershipDelta int64,
	serverNow time.Time,
) (savedCollectionUsageMutationState, error) {
	if state.version >= math.MaxInt64 || serverNow.Before(state.updatedAt) {
		return savedCollectionUsageMutationState{}, savedcollectionapp.ErrDataInvariant
	}
	collections, ok := addUnsignedDelta(state.activeCollections, collectionDelta)
	if !ok || collections > math.MaxInt64 {
		return savedCollectionUsageMutationState{}, savedcollectionapp.ErrDataInvariant
	}
	memberships, ok := addUnsignedDelta(state.activeMemberships, membershipDelta)
	if !ok || memberships > math.MaxInt64 {
		return savedCollectionUsageMutationState{}, savedcollectionapp.ErrDataInvariant
	}
	var updatedCollections int64
	var updatedMemberships int64
	var updatedVersion int64
	var updatedAt time.Time
	err := tx.QueryRow(
		ctx,
		updateSavedCollectionUsageForMutationSQL,
		ownerUserID.String(),
		int64(collections),
		int64(memberships),
		serverNow.UTC(),
		int64(state.activeCollections),
		int64(state.activeMemberships),
		int64(state.version),
	).Scan(&updatedCollections, &updatedMemberships, &updatedVersion, &updatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedCollectionUsageMutationState{}, domain.ErrMutationStale
	}
	if err != nil {
		return savedCollectionUsageMutationState{}, mapSavedCollectionPGError(err)
	}
	if updatedCollections != int64(collections) || updatedMemberships != int64(memberships) ||
		updatedVersion != int64(state.version)+1 || updatedAt.IsZero() {
		return savedCollectionUsageMutationState{}, savedcollectionapp.ErrDataInvariant
	}
	return savedCollectionUsageMutationState{
		activeCollections: collections,
		activeMemberships: memberships,
		version:           uint64(updatedVersion),
		updatedAt:         updatedAt.UTC(),
	}, nil
}

func addUnsignedDelta(value uint64, delta int64) (uint64, bool) {
	if delta >= 0 {
		addition := uint64(delta)
		if value > math.MaxUint64-addition {
			return 0, false
		}
		return value + addition, true
	}
	if delta == math.MinInt64 {
		return 0, false
	}
	subtraction := uint64(-delta)
	if subtraction > value {
		return 0, false
	}
	return value - subtraction, true
}

func lockSavedCollectionByID(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	collectionID uuid.UUID,
) (savedCollectionState, bool, error) {
	return scanSavedCollectionState(tx.QueryRow(
		ctx,
		lockSavedCollectionByIDSQL,
		ownerUserID.String(),
		collectionID.String(),
	))
}

func lockSavedCollectionByClientCreationID(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	clientCreationID uuid.UUID,
) (savedCollectionState, bool, error) {
	return scanSavedCollectionState(tx.QueryRow(
		ctx,
		lockSavedCollectionByClientCreationIDSQL,
		ownerUserID.String(),
		clientCreationID.String(),
	))
}

func scanSavedCollectionState(row rowScanner) (savedCollectionState, bool, error) {
	var idText string
	var clientCreationIDText string
	var title pgtype.Text
	var normalizedTitle pgtype.Text
	var lifecycle string
	var lifecycleVersion int64
	var metadataVersion int64
	var itemsVersion int64
	var activeItemCount int64
	var createdAt time.Time
	var organizedAt time.Time
	var updatedAt time.Time
	var deletedAt pgtype.Timestamptz
	if err := row.Scan(
		&idText,
		&clientCreationIDText,
		&title,
		&normalizedTitle,
		&lifecycle,
		&lifecycleVersion,
		&metadataVersion,
		&itemsVersion,
		&activeItemCount,
		&createdAt,
		&organizedAt,
		&updatedAt,
		&deletedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return savedCollectionState{}, false, nil
		}
		return savedCollectionState{}, false, mapSavedCollectionPGError(err)
	}
	id, err := uuid.Parse(idText)
	if err != nil || id == uuid.Nil {
		return savedCollectionState{}, false, savedcollectionapp.ErrDataInvariant
	}
	clientCreationID, err := uuid.Parse(clientCreationIDText)
	if err != nil || clientCreationID == uuid.Nil || lifecycleVersion <= 0 ||
		metadataVersion <= 0 || itemsVersion < 0 || activeItemCount < 0 ||
		activeItemCount > itemsVersion || createdAt.IsZero() || organizedAt.IsZero() ||
		updatedAt.IsZero() {
		return savedCollectionState{}, false, savedcollectionapp.ErrDataInvariant
	}
	state := savedCollectionState{
		id:               id,
		clientCreationID: clientCreationID,
		lifecycle:        savedcollectionapp.CollectionLifecycleState(lifecycle),
		lifecycleVersion: uint64(lifecycleVersion),
		metadataVersion:  uint64(metadataVersion),
		itemsVersion:     uint64(itemsVersion),
		activeItemCount:  uint64(activeItemCount),
		createdAt:        createdAt.UTC(),
		organizedAt:      organizedAt.UTC(),
		updatedAt:        updatedAt.UTC(),
	}
	if title.Valid {
		value := title.String
		state.title = &value
	}
	if normalizedTitle.Valid {
		value := normalizedTitle.String
		state.normalizedTitle = &value
	}
	if deletedAt.Valid {
		value := deletedAt.Time.UTC()
		state.deletedAt = &value
	}
	if !state.valid() {
		return savedCollectionState{}, false, savedcollectionapp.ErrDataInvariant
	}
	return state, true, nil
}

func (state savedCollectionState) valid() bool {
	switch state.lifecycle {
	case savedcollectionapp.CollectionLifecycleActive:
		return state.title != nil && state.normalizedTitle != nil && state.deletedAt == nil
	case savedcollectionapp.CollectionLifecycleDeleted:
		return state.title == nil && state.normalizedTitle == nil && state.deletedAt != nil &&
			state.activeItemCount == 0 && state.lifecycleVersion > 1
	default:
		return false
	}
}

func activeSavedCollectionTitleConflict(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	normalizedTitle string,
	excludedID *uuid.UUID,
) (bool, error) {
	var excluded any
	if excludedID != nil {
		excluded = excludedID.String()
	}
	var conflictingID string
	err := tx.QueryRow(
		ctx,
		findActiveSavedCollectionTitleConflictSQL,
		ownerUserID.String(),
		normalizedTitle,
		excluded,
	).Scan(&conflictingID)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, mapSavedCollectionPGError(err)
	}
	parsed, err := uuid.Parse(conflictingID)
	if err != nil || parsed == uuid.Nil {
		return false, savedcollectionapp.ErrDataInvariant
	}
	return true, nil
}

func newSavedCollectionUUID(ids savedCollectionIDGenerator) (uuid.UUID, error) {
	value := ids.NewV4()
	if value == uuid.Nil || value.Version() != 4 || value.Variant() != uuid.RFC4122 {
		return uuid.Nil, savedcollectionapp.ErrDataInvariant
	}
	return value, nil
}
