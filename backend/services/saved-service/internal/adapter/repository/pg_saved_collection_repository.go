package repository

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	savedcollectionapp "kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type savedCollectionIDGenerator interface {
	NewV4() uuid.UUID
}

type randomSavedCollectionIDs struct{}

func (randomSavedCollectionIDs) NewV4() uuid.UUID { return uuid.New() }

type PGSavedCollectionRepository struct {
	pool   *pgxpool.Pool
	limits savedcollectionapp.Limits
	ids    savedCollectionIDGenerator
}

var _ savedcollectionapp.Repository = (*PGSavedCollectionRepository)(nil)

func NewPGSavedCollectionRepository(
	pool *pgxpool.Pool,
	limits savedcollectionapp.Limits,
	ids savedCollectionIDGenerator,
) (*PGSavedCollectionRepository, error) {
	if pool == nil {
		return nil, savedcollectionapp.ErrInvalidCommand
	}
	limits = limits.WithDefaults()
	if err := limits.Validate(); err != nil {
		return nil, err
	}
	if ids == nil {
		ids = randomSavedCollectionIDs{}
	}
	return &PGSavedCollectionRepository{pool: pool, limits: limits, ids: ids}, nil
}

func (repository *PGSavedCollectionRepository) beginCollectionTx(ctx context.Context) (pgx.Tx, error) {
	if err := validateSavedCollectionContext(ctx); err != nil {
		return nil, err
	}
	if repository == nil || repository.pool == nil {
		return nil, savedcollectionapp.ErrRepositoryUnavailable
	}
	tx, err := repository.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.ReadCommitted,
		AccessMode: pgx.ReadWrite,
	})
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	return tx, nil
}

func validateSavedCollectionContext(ctx context.Context) error {
	if ctx == nil {
		return savedcollectionapp.ErrInvalidCommand
	}
	return ctx.Err()
}

func commitCollectionTx(ctx context.Context, tx pgx.Tx) error {
	if err := tx.Commit(ctx); err != nil {
		return mapSavedCollectionPGError(err)
	}
	return nil
}

func rollbackCollectionTx(tx pgx.Tx) {
	_ = tx.Rollback(context.Background())
}

func canonicalPostgresTimestamp(value time.Time) time.Time {
	return value.UTC().Truncate(time.Microsecond)
}

func mapSavedCollectionPGError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	if errors.Is(err, saveditemapp.ErrInvalidCommand) {
		return savedcollectionapp.ErrInvalidCommand
	}
	if errors.Is(err, saveditemapp.ErrOperationNotFound) {
		return savedcollectionapp.ErrOperationNotFound
	}
	if errors.Is(err, saveditemapp.ErrDataInvariant) {
		return savedcollectionapp.ErrDataInvariant
	}
	if errors.Is(err, saveditemapp.ErrRepositoryUnavailable) {
		return savedcollectionapp.ErrRepositoryUnavailable
	}
	if errors.Is(err, domain.ErrMutationStale) {
		return domain.ErrMutationStale
	}
	var postgresError *pgconn.PgError
	if errors.As(err, &postgresError) {
		switch postgresError.Code {
		case "23505":
			if postgresError.ConstraintName == "idx_saved_collections_active_title" {
				return domain.ErrCollectionTitleConflict
			}
			return domain.ErrMutationStale
		case "22003", "23502", "23503", "23514":
			return savedcollectionapp.ErrDataInvariant
		default:
			return savedcollectionapp.ErrRepositoryUnavailable
		}
	}
	return savedcollectionapp.ErrRepositoryUnavailable
}

func lockSavedCollectionOwner(ctx context.Context, tx pgx.Tx, ownerUserID uuid.UUID) error {
	if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", savedCollectionOwnerLockKey(ownerUserID)); err != nil {
		return mapSavedCollectionPGError(err)
	}
	return nil
}

func savedCollectionOwnerLockKey(ownerUserID uuid.UUID) int64 {
	digest := sha256.New()
	digest.Write([]byte("inflap-saved-collections-owner-v1"))
	digest.Write(ownerUserID[:])
	sum := digest.Sum(nil)
	return int64(binary.BigEndian.Uint64(sum[:8]))
}

func collectionSavedItemIdentity(identity savedcollectionapp.MutationIdentity) saveditemapp.MutationIdentity {
	return saveditemapp.MutationIdentity{
		SubjectID:             identity.SubjectID,
		SessionGeneration:     identity.SessionGeneration,
		OperationID:           identity.OperationID,
		Kind:                  identity.Kind,
		SemanticRequestHMAC:   append([]byte(nil), identity.SemanticRequestHMAC...),
		RequestHMACKeyVersion: identity.RequestHMACKeyVersion,
	}
}

func lockSavedCollectionOperation(
	ctx context.Context,
	tx pgx.Tx,
	identity savedcollectionapp.MutationIdentity,
) (*domain.SavedOperation, error) {
	receipt, err := lockSavedItemOperation(ctx, tx, collectionSavedItemIdentity(identity))
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	if !identity.Matches(receipt) {
		return nil, domain.ErrReplayMismatch
	}
	return receipt, nil
}

func finishSavedCollectionOperation(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	identity savedcollectionapp.MutationIdentity,
) (*domain.SavedOperation, error) {
	terminal, err := finishSavedItemOperation(ctx, tx, receipt, collectionSavedItemIdentity(identity))
	if err != nil {
		return nil, mapSavedCollectionPGError(err)
	}
	return terminal, nil
}

func expireSavedCollectionOperation(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	identity savedcollectionapp.MutationIdentity,
	serverNow time.Time,
) (*domain.SavedOperation, error) {
	if err := receipt.Expire(serverNow); err != nil {
		return nil, err
	}
	return finishSavedCollectionOperation(ctx, tx, receipt, identity)
}

func rejectSavedCollectionOperation(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	identity savedcollectionapp.MutationIdentity,
	serverNow time.Time,
	cause *domain.DomainError,
	refreshScope domain.RefreshScope,
) (*domain.SavedOperation, error) {
	if err := receipt.Reject(serverNow, cause, refreshScope); err != nil {
		return nil, err
	}
	terminal, err := finishSavedCollectionOperation(ctx, tx, receipt, identity)
	if err != nil {
		return nil, err
	}
	if err := commitCollectionTx(ctx, tx); err != nil {
		return nil, err
	}
	return terminal, nil
}

func replayOrExpireSavedCollectionOperation(
	ctx context.Context,
	tx pgx.Tx,
	receipt *domain.SavedOperation,
	identity savedcollectionapp.MutationIdentity,
	serverNow time.Time,
) (*domain.SavedOperation, bool, error) {
	if receipt.Status() != domain.OperationStatusPending {
		if err := commitCollectionTx(ctx, tx); err != nil {
			return nil, true, err
		}
		return receipt, true, nil
	}
	if serverNow.Before(receipt.CommitDeadline()) {
		return receipt, false, nil
	}
	terminal, err := expireSavedCollectionOperation(ctx, tx, receipt, identity, serverNow)
	if err != nil {
		return nil, true, err
	}
	if err := commitCollectionTx(ctx, tx); err != nil {
		return nil, true, err
	}
	return terminal, true, nil
}
