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

const lockSavedRelationshipSQL = `
SELECT id::text,
       relationship_state,
       state_generation::text,
       relationship_attribution_id::text,
       relationship_version,
       dependent_membership_version,
       saved_at,
       updated_at
FROM saved_items
WHERE owner_user_id = $1
  AND entity_type = $2
  AND entity_id = $3
FOR UPDATE`

const insertSavedRelationshipSQL = `
INSERT INTO saved_items (
    id,
    owner_user_id,
    entity_type,
    entity_id,
    relationship_state,
    state_generation,
    relationship_attribution_id,
    relationship_version,
    dependent_membership_version,
    saved_at,
    removed_at,
    purge_eligible_at,
    created_at,
    updated_at
) VALUES (
    $1, $2, $3, $4, 'ACTIVE', $5, $6, 1, 0, $7, NULL, NULL, $7, $7
)
RETURNING id::text,
          relationship_state,
          state_generation::text,
          relationship_attribution_id::text,
          relationship_version,
          dependent_membership_version,
          saved_at,
          updated_at`

const reactivateSavedRelationshipSQL = `
UPDATE saved_items
SET relationship_state = 'ACTIVE',
    state_generation = $4,
    relationship_attribution_id = $5,
    relationship_version = relationship_version + 1,
    saved_at = $6,
    removed_at = NULL,
    purge_eligible_at = NULL,
    updated_at = $6
WHERE owner_user_id = $1
  AND entity_type = $2
  AND entity_id = $3
  AND relationship_state = 'REMOVED'
RETURNING id::text,
          relationship_state,
          state_generation::text,
          relationship_attribution_id::text,
          relationship_version,
          dependent_membership_version,
          saved_at,
          updated_at`

const insertSavedUserUsageSQL = `
INSERT INTO saved_user_usage (
    owner_user_id,
    active_saved_items_count,
    usage_version,
    created_at,
    updated_at
) VALUES ($1, 0, 0, $2, $2)
ON CONFLICT (owner_user_id) DO NOTHING`

const lockSavedUserUsageSQL = `
SELECT active_saved_items_count, usage_version
FROM saved_user_usage
WHERE owner_user_id = $1
FOR UPDATE`

const updateSavedUserUsageSQL = `
UPDATE saved_user_usage
SET active_saved_items_count = $2,
    usage_version = usage_version + 1,
    updated_at = $3
WHERE owner_user_id = $1
  AND active_saved_items_count = $4
  AND usage_version = $5
RETURNING active_saved_items_count, usage_version`

const insertSavedItemOutboxSQL = `
INSERT INTO saved_outbox (
    id,
    owner_user_id,
    saved_item_id,
    event_schema_version,
    event_type,
    entity_type,
    entity_id,
    relationship_state,
    state_generation,
    relationship_attribution_id,
    relationship_version,
    status,
    attempt_count,
    next_attempt_at,
    created_at,
    updated_at
) VALUES (
    $1, $2, $3, 1, $4, $5, $6, $7, $8, $9, $10,
    'PENDING', 0, $11, $11, $11
)`

type savedRelationshipState struct {
	id                         uuid.UUID
	state                      domain.RelationshipState
	stateGeneration            uuid.UUID
	relationshipAttributionID  uuid.UUID
	relationshipVersion        uint64
	dependentMembershipVersion uint64
	savedAt                    time.Time
	updatedAt                  time.Time
}

type savedUserUsageState struct {
	activeCount int64
	version     uint64
}

func lockSavedRelationship(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	target domain.SavedTarget,
) (savedRelationshipState, bool, error) {
	return scanSavedRelationship(tx.QueryRow(
		ctx,
		lockSavedRelationshipSQL,
		ownerUserID.String(),
		string(target.EntityType()),
		target.EntityID(),
	))
}

func insertSavedRelationship(
	ctx context.Context,
	tx pgx.Tx,
	command saveditemapp.SaveCommand,
) (savedRelationshipState, error) {
	state, found, err := scanSavedRelationship(tx.QueryRow(
		ctx,
		insertSavedRelationshipSQL,
		command.SavedItemID.String(),
		command.OwnerUserID.String(),
		string(command.Projection.Target.EntityType()),
		command.Projection.Target.EntityID(),
		command.StateGeneration.String(),
		command.RelationshipAttributionID.String(),
		command.ServerNow.UTC(),
	))
	if err != nil {
		return savedRelationshipState{}, err
	}
	if !found {
		return savedRelationshipState{}, saveditemapp.ErrDataInvariant
	}
	return state, nil
}

func reactivateSavedRelationship(
	ctx context.Context,
	tx pgx.Tx,
	command saveditemapp.SaveCommand,
) (savedRelationshipState, error) {
	state, found, err := scanSavedRelationship(tx.QueryRow(
		ctx,
		reactivateSavedRelationshipSQL,
		command.OwnerUserID.String(),
		string(command.Projection.Target.EntityType()),
		command.Projection.Target.EntityID(),
		command.StateGeneration.String(),
		command.RelationshipAttributionID.String(),
		command.ServerNow.UTC(),
	))
	if err != nil {
		return savedRelationshipState{}, err
	}
	if !found {
		return savedRelationshipState{}, domain.ErrMutationStale
	}
	return state, nil
}

func scanSavedRelationship(row rowScanner) (savedRelationshipState, bool, error) {
	var id string
	var state string
	var generation string
	var attributionID string
	var relationshipVersion int64
	var dependentMembershipVersion int64
	var savedAt time.Time
	var updatedAt time.Time
	if err := row.Scan(
		&id,
		&state,
		&generation,
		&attributionID,
		&relationshipVersion,
		&dependentMembershipVersion,
		&savedAt,
		&updatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return savedRelationshipState{}, false, nil
		}
		return savedRelationshipState{}, false, mapSavedItemPGError(err)
	}
	parsedID, err := parseCanonicalUUID(id)
	if err != nil {
		return savedRelationshipState{}, false, saveditemapp.ErrDataInvariant
	}
	parsedGeneration, err := parseCanonicalUUID(generation)
	if err != nil {
		return savedRelationshipState{}, false, saveditemapp.ErrDataInvariant
	}
	parsedAttributionID, err := parseCanonicalUUID(attributionID)
	if err != nil {
		return savedRelationshipState{}, false, saveditemapp.ErrDataInvariant
	}
	relationshipState := domain.RelationshipState(state)
	if !relationshipState.IsValid() || relationshipVersion <= 0 || dependentMembershipVersion < 0 ||
		savedAt.IsZero() || updatedAt.IsZero() {
		return savedRelationshipState{}, false, saveditemapp.ErrDataInvariant
	}
	return savedRelationshipState{
		id:                         parsedID,
		state:                      relationshipState,
		stateGeneration:            parsedGeneration,
		relationshipAttributionID:  parsedAttributionID,
		relationshipVersion:        uint64(relationshipVersion),
		dependentMembershipVersion: uint64(dependentMembershipVersion),
		savedAt:                    savedAt.UTC(),
		updatedAt:                  updatedAt.UTC(),
	}, true, nil
}

func ensureAndLockSavedUserUsage(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	serverNow time.Time,
) (savedUserUsageState, error) {
	tag, err := tx.Exec(ctx, insertSavedUserUsageSQL, ownerUserID.String(), serverNow.UTC())
	if err != nil {
		return savedUserUsageState{}, mapSavedItemPGError(err)
	}
	inserted := tag.RowsAffected() == 1

	usage, found, err := lockExistingSavedUserUsage(ctx, tx, ownerUserID)
	if err != nil {
		return savedUserUsageState{}, err
	}
	if !found {
		return savedUserUsageState{}, saveditemapp.ErrDataInvariant
	}
	if inserted {
		var activeExists bool
		if err := tx.QueryRow(
			ctx,
			`SELECT EXISTS (
                SELECT 1
                FROM saved_items
                WHERE owner_user_id = $1
                  AND relationship_state = 'ACTIVE'
            )`,
			ownerUserID.String(),
		).Scan(&activeExists); err != nil {
			return savedUserUsageState{}, mapSavedItemPGError(err)
		}
		if activeExists {
			return savedUserUsageState{}, saveditemapp.ErrDataInvariant
		}
	}
	return usage, nil
}

func lockExistingSavedUserUsage(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
) (savedUserUsageState, bool, error) {
	var activeCount int64
	var version int64
	err := tx.QueryRow(ctx, lockSavedUserUsageSQL, ownerUserID.String()).Scan(&activeCount, &version)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedUserUsageState{}, false, nil
	}
	if err != nil {
		return savedUserUsageState{}, false, mapSavedItemPGError(err)
	}
	if activeCount < 0 || version < 0 {
		return savedUserUsageState{}, false, saveditemapp.ErrDataInvariant
	}
	return savedUserUsageState{activeCount: activeCount, version: uint64(version)}, true, nil
}

func changeSavedUserUsage(
	ctx context.Context,
	tx pgx.Tx,
	ownerUserID uuid.UUID,
	usage savedUserUsageState,
	delta int64,
	serverNow time.Time,
) (savedUserUsageState, error) {
	if usage.version >= math.MaxInt64 ||
		(delta > 0 && usage.activeCount == math.MaxInt64) ||
		(delta < 0 && usage.activeCount == 0) {
		return savedUserUsageState{}, saveditemapp.ErrDataInvariant
	}
	newCount := usage.activeCount + delta
	if newCount < 0 {
		return savedUserUsageState{}, saveditemapp.ErrDataInvariant
	}
	var updated savedUserUsageState
	var updatedVersion int64
	err := tx.QueryRow(
		ctx,
		updateSavedUserUsageSQL,
		ownerUserID.String(),
		newCount,
		serverNow.UTC(),
		usage.activeCount,
		int64(usage.version),
	).Scan(&updated.activeCount, &updatedVersion)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedUserUsageState{}, domain.ErrMutationStale
	}
	if err != nil {
		return savedUserUsageState{}, mapSavedItemPGError(err)
	}
	if updatedVersion < 0 {
		return savedUserUsageState{}, saveditemapp.ErrDataInvariant
	}
	updated.version = uint64(updatedVersion)
	return updated, nil
}

func insertSavedItemOutbox(
	ctx context.Context,
	tx pgx.Tx,
	eventID uuid.UUID,
	ownerUserID uuid.UUID,
	target domain.SavedTarget,
	relationship savedRelationshipState,
	eventType string,
	serverNow time.Time,
) error {
	tag, err := tx.Exec(
		ctx,
		insertSavedItemOutboxSQL,
		eventID.String(),
		ownerUserID.String(),
		relationship.id.String(),
		eventType,
		string(target.EntityType()),
		target.EntityID(),
		string(relationship.state),
		relationship.stateGeneration.String(),
		relationship.relationshipAttributionID.String(),
		int64(relationship.relationshipVersion),
		serverNow.UTC(),
	)
	if err != nil {
		return mapSavedItemPGError(err)
	}
	if tag.RowsAffected() != 1 {
		return saveditemapp.ErrDataInvariant
	}
	return nil
}

func uint64Pointer(value uint64) *uint64 {
	copy := value
	return &copy
}
