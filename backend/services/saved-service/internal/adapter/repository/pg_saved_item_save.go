package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func (r *PGSavedItemRepository) Save(
	ctx context.Context,
	command saveditemapp.SaveCommand,
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

	// The originating receipt is deliberately the first database lock.
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

	if err := writeAuthoritativePublicProjection(ctx, tx, command.Projection, command.ServerNow); err != nil {
		if !errors.Is(err, errSavedProjectionRevisionRollback) {
			return nil, err
		}
		return rejectAndCommitSavedItemOperation(
			ctx,
			tx,
			receipt,
			command.Identity,
			command.ServerNow,
			domain.ErrMutationStale,
			domain.RefreshScopeNone,
		)
	}

	relationship, found, err := lockSavedRelationship(
		ctx,
		tx,
		command.OwnerUserID,
		command.Projection.Target,
	)
	if err != nil {
		return nil, err
	}
	observedRelationshipVersion := uint64(0)
	if found {
		observedRelationshipVersion = relationship.relationshipVersion
		if command.ServerNow.Before(relationship.updatedAt) {
			return nil, saveditemapp.ErrDataInvariant
		}
	}

	usage, err := ensureAndLockSavedUserUsage(ctx, tx, command.OwnerUserID, command.ServerNow)
	if err != nil {
		return nil, err
	}
	activationRequired := !found || relationship.state == domain.RelationshipStateRemoved
	if !activationRequired && usage.activeCount == 0 {
		return nil, saveditemapp.ErrDataInvariant
	}
	if activationRequired && uint64(usage.activeCount) >= command.EffectiveMaxActiveSaves() {
		return rejectAndCommitSavedItemOperation(
			ctx,
			tx,
			receipt,
			command.Identity,
			command.ServerNow,
			domain.ErrItemLimitReached,
			domain.RefreshScopeNone,
		)
	}

	outcome := domain.OperationOutcomeNoOp
	if activationRequired {
		if found {
			relationship, err = reactivateSavedRelationship(ctx, tx, command)
		} else {
			relationship, err = insertSavedRelationship(ctx, tx, command)
		}
		if err != nil {
			return nil, err
		}
		usage, err = changeSavedUserUsage(ctx, tx, command.OwnerUserID, usage, 1, command.ServerNow)
		if err != nil {
			return nil, err
		}
		if err := markSavedProjectionReferenced(
			ctx,
			tx,
			command.Projection.Target,
			command.ServerNow,
		); err != nil {
			return nil, err
		}
		if err := insertSavedItemOutbox(
			ctx,
			tx,
			command.ActivatedOutboxEventID,
			command.OwnerUserID,
			command.Projection.Target,
			relationship,
			"SAVED_ITEM_ACTIVATED",
			command.ServerNow,
		); err != nil {
			return nil, err
		}
		outcome = domain.OperationOutcomeApplied
	} else if err := markSavedProjectionReferenced(
		ctx,
		tx,
		command.Projection.Target,
		command.ServerNow,
	); err != nil {
		return nil, err
	}

	if err := receipt.Succeed(
		command.ServerNow,
		outcome,
		domain.RefreshScopeSavedItems,
		domain.OperationVersionEffects{
			ObservedRelationshipVersion: &observedRelationshipVersion,
			AppliedRelationship: &domain.AppliedRelationshipVersion{
				Generation: relationship.stateGeneration,
				Version:    relationship.relationshipVersion,
			},
			AppliedUserUsageVersion: uint64Pointer(usage.version),
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

func rejectAndCommitSavedItemOperation(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	identity saveditemapp.MutationIdentity,
	serverNow time.Time,
	cause *domain.DomainError,
	refreshScope domain.RefreshScope,
) (*domain.SavedOperation, error) {
	if err := receipt.Reject(serverNow, cause, refreshScope); err != nil {
		return nil, err
	}
	terminal, err := finishSavedItemOperation(ctx, tx, receipt, identity)
	if err != nil {
		return nil, err
	}
	if err := commitSavedItemTx(ctx, tx); err != nil {
		return nil, err
	}
	return terminal, nil
}
