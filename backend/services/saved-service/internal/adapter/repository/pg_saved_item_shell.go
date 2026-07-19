package repository

import (
	"context"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const insertSavedProjectionShellSQL = `
INSERT INTO saved_content_projections (
    entity_type,
    entity_id,
    source_service,
    source_revision,
    projection_revision,
    visibility_revision,
    visibility_status,
    search_document_version,
    shell_expires_at,
    ever_referenced,
    created_at,
    updated_at
) VALUES ($1, $2, $3, 0, 0, 0, 'UNKNOWN', 0, $4, FALSE, $5, $5)
ON CONFLICT (entity_type, entity_id) DO NOTHING`

const extendSavedProjectionShellSQL = `
UPDATE saved_content_projections
SET shell_expires_at = GREATEST(shell_expires_at, $3),
    updated_at = GREATEST(updated_at, $4)
WHERE entity_type = $1
  AND entity_id = $2
  AND ever_referenced = FALSE`

func (r *PGSavedItemRepository) PrepareProjectionShell(
	ctx context.Context,
	command saveditemapp.PrepareProjectionShellCommand,
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
	if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", savedProjectionLockKey(command.Target)); err != nil {
		return nil, mapSavedItemPGError(err)
	}
	state, found, err := lockSavedProjection(ctx, tx, command.Target)
	if err != nil {
		return nil, err
	}
	if !found {
		if _, err := tx.Exec(
			ctx,
			insertSavedProjectionShellSQL,
			string(command.Target.EntityType()),
			command.Target.EntityID(),
			command.SourceService,
			command.ShellExpiresAt.UTC(),
			command.ServerNow.UTC(),
		); err != nil {
			return nil, mapSavedItemPGError(err)
		}
		state, found, err = lockSavedProjection(ctx, tx, command.Target)
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, saveditemapp.ErrDataInvariant
		}
	}
	if state.sourceService != command.SourceService {
		return nil, saveditemapp.ErrDataInvariant
	}
	if _, err := tx.Exec(
		ctx,
		extendSavedProjectionShellSQL,
		string(command.Target.EntityType()),
		command.Target.EntityID(),
		command.ShellExpiresAt.UTC(),
		command.ServerNow.UTC(),
	); err != nil {
		return nil, mapSavedItemPGError(err)
	}
	if err := commitSavedItemTx(ctx, tx); err != nil {
		return nil, err
	}
	return receipt, nil
}
