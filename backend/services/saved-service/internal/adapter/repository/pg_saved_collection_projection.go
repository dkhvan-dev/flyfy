package repository

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

// PrepareProjectionShell persists the operation before source resolution and
// reserves the target row on which later visibility events can advance their
// own revision independently from the source payload revision.
func (repository *PGSavedCollectionRepository) PrepareProjectionShell(
	ctx context.Context,
	command savedcollectionapp.PrepareProjectionShellCommand,
) (*domain.SavedOperation, error) {
	if err := command.ValidateIdentity(); err != nil {
		return nil, err
	}
	command.ServerNow = canonicalPostgresTimestamp(command.ServerNow)
	command.ShellExpiresAt = canonicalPostgresTimestamp(command.ShellExpiresAt)
	command.Identity.SemanticRequestHMAC = append([]byte(nil), command.Identity.SemanticRequestHMAC...)
	tx, err := repository.beginCollectionTx(ctx)
	if err != nil {
		return nil, err
	}
	defer rollbackCollectionTx(tx)

	receipt, err := lockSavedCollectionOperation(ctx, tx, command.Identity)
	if err != nil {
		return nil, err
	}
	if terminal, done, err := replayOrExpireSavedCollectionOperation(
		ctx, tx, receipt, command.Identity, command.ServerNow,
	); done || err != nil {
		return terminal, err
	}
	if command.ServerNow.Before(receipt.CreatedAt()) {
		return nil, savedcollectionapp.ErrInvalidCommand
	}
	if err := command.Validate(receipt.CommitDeadline()); err != nil {
		return nil, err
	}

	if _, err := tx.Exec(
		ctx,
		"SELECT pg_advisory_xact_lock($1)",
		savedProjectionLockKey(command.Target),
	); err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	state, found, err := lockSavedProjection(ctx, tx, command.Target)
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
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
			return nil, mapSavedCollectionPGError(err)
		}
		state, found, err = lockSavedProjection(ctx, tx, command.Target)
		if err != nil {
			return nil, mapSavedCollectionPGError(err)
		}
		if !found {
			return nil, savedcollectionapp.ErrDataInvariant
		}
	}
	if state.sourceService != command.SourceService {
		return nil, savedcollectionapp.ErrDataInvariant
	}
	if _, err := tx.Exec(
		ctx,
		extendSavedProjectionShellSQL,
		string(command.Target.EntityType()),
		command.Target.EntityID(),
		command.ShellExpiresAt.UTC(),
		command.ServerNow.UTC(),
	); err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	if err := commitCollectionTx(ctx, tx); err != nil {
		return nil, err
	}
	return receipt, nil
}

// writePreparedCollectionPublicProjection intentionally refuses to insert. A
// missing row means orchestration skipped the pre-RPC shell step. Holding the
// shared advisory lock makes the existence check and the common independent
// revision comparison one atomic projection critical section.
func writePreparedCollectionPublicProjection(
	ctx context.Context,
	tx pgx.Tx,
	snapshot saveditemapp.PublicProjectionSnapshot,
	serverNow time.Time,
) error {
	if _, err := tx.Exec(
		ctx,
		"SELECT pg_advisory_xact_lock($1)",
		savedProjectionLockKey(snapshot.Target),
	); err != nil {
		return mapSavedCollectionPGError(err)
	}
	_, found, err := lockSavedProjection(ctx, tx, snapshot.Target)
	if err != nil {
		return mapSavedCollectionPGError(err)
	}
	if !found {
		return saveditemapp.ErrDataInvariant
	}
	return writeAuthoritativePublicProjection(ctx, tx, snapshot, serverNow)
}
