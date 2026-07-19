package repository

import (
	"context"

	"github.com/jackc/pgx/v5"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const removeSavedRelationshipSQL = `
UPDATE saved_items
SET relationship_state = 'REMOVED',
    relationship_version = relationship_version + 1,
    dependent_membership_version = dependent_membership_version + $4,
    removed_at = $5,
    purge_eligible_at = $5::timestamptz + INTERVAL '14 days',
    updated_at = $5
WHERE owner_user_id = $1
  AND entity_type = $2
  AND entity_id = $3
  AND relationship_state = 'ACTIVE'
  AND relationship_version = $6
  AND dependent_membership_version = $7
RETURNING id::text,
          relationship_state,
          state_generation::text,
          relationship_attribution_id::text,
          relationship_version,
          dependent_membership_version,
          saved_at,
          updated_at`

func (r *PGSavedItemRepository) GlobalUnsave(
	ctx context.Context,
	command saveditemapp.GlobalUnsaveCommand,
) (*domain.SavedOperation, error) {
	if err := command.ValidateIdentity(); err != nil {
		return nil, err
	}
	command.Identity.SemanticRequestHMAC = append([]byte(nil), command.Identity.SemanticRequestHMAC...)

	tx, err := r.begin(ctx)
	if err != nil {
		return nil, err
	}
	defer rollbackSavedItemTx(tx)

	// Collection assignment uses the same relationship lock, so no membership
	// can be restored after this transaction observes ACTIVE.
	receipt, err := lockSavedItemOperation(ctx, tx, command.Identity)
	if err != nil {
		return nil, err
	}
	if receipt.Status() != domain.OperationStatusPending {
		if err := commitSavedItemTx(ctx, tx); err != nil {
			return nil, err
		}
		return receipt, nil
	}
	if !command.ServerNow.Before(receipt.CommitDeadline()) {
		receipt, err = expireSavedItemOperation(ctx, tx, receipt, command.Identity, command.ServerNow)
		if err != nil {
			return nil, err
		}
		if err := commitSavedItemTx(ctx, tx); err != nil {
			return nil, err
		}
		return receipt, nil
	}
	if command.ServerNow.Before(receipt.CreatedAt()) {
		return nil, saveditemapp.ErrInvalidCommand
	}
	if err := command.Validate(receipt.CommitDeadline()); err != nil {
		return nil, err
	}

	relationship, found, err := lockSavedRelationship(ctx, tx, command.OwnerUserID, command.Target)
	if err != nil {
		return nil, err
	}
	if !found {
		return completeGlobalUnsaveNoOp(ctx, tx, receipt, command, nil, 0)
	}
	if command.ServerNow.Before(relationship.updatedAt) {
		return nil, saveditemapp.ErrDataInvariant
	}
	if relationship.state == domain.RelationshipStateRemoved {
		return completeGlobalUnsaveNoOp(ctx, tx, receipt, command, &relationship, relationship.relationshipVersion)
	}

	memberships, err := lockEffectiveSavedMemberships(
		ctx,
		tx,
		command.OwnerUserID,
		relationship.id,
		command.ServerNow,
	)
	if err != nil {
		return nil, err
	}

	usage, found, err := lockExistingSavedUserUsage(ctx, tx, command.OwnerUserID)
	if err != nil {
		return nil, err
	}
	if !found || usage.activeCount <= 0 {
		return nil, saveditemapp.ErrDataInvariant
	}

	if len(memberships.membershipIDs) > 0 {
		collectionUsage, err := lockSavedCollectionUsage(ctx, tx, command.OwnerUserID)
		if err != nil {
			return nil, err
		}
		if err := removeLockedEffectiveMemberships(
			ctx,
			tx,
			command.OwnerUserID,
			relationship.id,
			memberships,
			command.ServerNow,
		); err != nil {
			return nil, err
		}
		if err := decrementSavedCollectionUsage(
			ctx,
			tx,
			command.OwnerUserID,
			collectionUsage,
			len(memberships.membershipIDs),
			command.ServerNow,
		); err != nil {
			return nil, err
		}
	}

	observedRelationshipVersion := relationship.relationshipVersion
	relationship, err = removeActiveSavedRelationship(
		ctx,
		tx,
		command,
		relationship,
		len(memberships.membershipIDs) > 0,
	)
	if err != nil {
		return nil, err
	}
	usage, err = changeSavedUserUsage(ctx, tx, command.OwnerUserID, usage, -1, command.ServerNow)
	if err != nil {
		return nil, err
	}
	if err := insertSavedItemOutbox(
		ctx,
		tx,
		command.RemovedOutboxEventID,
		command.OwnerUserID,
		command.Target,
		relationship,
		"SAVED_ITEM_REMOVED",
		command.ServerNow,
	); err != nil {
		return nil, err
	}

	refreshScope := domain.RefreshScopeSavedItems
	if len(memberships.membershipIDs) > 0 {
		refreshScope = domain.RefreshScopeBoth
	}
	if err := receipt.Succeed(
		command.ServerNow,
		domain.OperationOutcomeApplied,
		refreshScope,
		domain.OperationVersionEffects{
			ObservedRelationshipVersion: &observedRelationshipVersion,
			AppliedRelationship: &domain.AppliedRelationshipVersion{
				Generation: relationship.stateGeneration,
				Version:    relationship.relationshipVersion,
			},
			AppliedUserUsageVersion:           uint64Pointer(usage.version),
			AppliedDependentMembershipVersion: uint64Pointer(relationship.dependentMembershipVersion),
		},
	); err != nil {
		return nil, err
	}
	receipt, err = finishSavedItemOperation(ctx, tx, receipt, command.Identity)
	if err != nil {
		return nil, err
	}
	if err := commitSavedItemTx(ctx, tx); err != nil {
		return nil, err
	}
	return receipt, nil
}

func completeGlobalUnsaveNoOp(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	command saveditemapp.GlobalUnsaveCommand,
	relationship *savedRelationshipState,
	observedRelationshipVersion uint64,
) (*domain.SavedOperation, error) {
	usage, found, err := lockExistingSavedUserUsage(ctx, tx, command.OwnerUserID)
	if err != nil {
		return nil, err
	}
	usageVersion := uint64(0)
	if found {
		usageVersion = usage.version
	}
	versions := domain.OperationVersionEffects{
		ObservedRelationshipVersion: &observedRelationshipVersion,
		AppliedUserUsageVersion:     &usageVersion,
	}
	if relationship != nil {
		versions.AppliedRelationship = &domain.AppliedRelationshipVersion{
			Generation: relationship.stateGeneration,
			Version:    relationship.relationshipVersion,
		}
		versions.AppliedDependentMembershipVersion = uint64Pointer(
			relationship.dependentMembershipVersion,
		)
	}
	if err := receipt.Succeed(
		command.ServerNow,
		domain.OperationOutcomeNoOp,
		domain.RefreshScopeSavedItems,
		versions,
	); err != nil {
		return nil, err
	}
	receipt, err = finishSavedItemOperation(ctx, tx, receipt, command.Identity)
	if err != nil {
		return nil, err
	}
	if err := commitSavedItemTx(ctx, tx); err != nil {
		return nil, err
	}
	return receipt, nil
}

func removeActiveSavedRelationship(
	ctx context.Context,
	tx pgx.Tx,
	command saveditemapp.GlobalUnsaveCommand,
	relationship savedRelationshipState,
	membershipsChanged bool,
) (savedRelationshipState, error) {
	dependentIncrement := int64(0)
	if membershipsChanged {
		dependentIncrement = 1
	}
	state, found, err := scanSavedRelationship(tx.QueryRow(
		ctx,
		removeSavedRelationshipSQL,
		command.OwnerUserID.String(),
		string(command.Target.EntityType()),
		command.Target.EntityID(),
		dependentIncrement,
		command.ServerNow.UTC(),
		int64(relationship.relationshipVersion),
		int64(relationship.dependentMembershipVersion),
	))
	if err != nil {
		return savedRelationshipState{}, err
	}
	if !found {
		return savedRelationshipState{}, domain.ErrMutationStale
	}
	return state, nil
}
