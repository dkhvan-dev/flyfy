package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type PGSavedItemRepository struct {
	pool *pgxpool.Pool
}

var _ saveditemapp.Repository = (*PGSavedItemRepository)(nil)

func NewPGSavedItemRepository(pool *pgxpool.Pool) (*PGSavedItemRepository, error) {
	if pool == nil {
		return nil, saveditemapp.ErrInvalidCommand
	}
	return &PGSavedItemRepository{pool: pool}, nil
}

func (r *PGSavedItemRepository) begin(ctx context.Context) (pgx.Tx, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if r == nil || r.pool == nil {
		return nil, saveditemapp.ErrRepositoryUnavailable
	}
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.ReadCommitted,
		AccessMode: pgx.ReadWrite,
	})
	if err != nil {
		return nil, mapSavedItemPGError(err)
	}
	return tx, nil
}

func commitSavedItemTx(ctx context.Context, tx pgx.Tx) error {
	if err := tx.Commit(ctx); err != nil {
		return mapSavedItemPGError(err)
	}
	return nil
}

func rollbackSavedItemTx(tx pgx.Tx) {
	_ = tx.Rollback(context.Background())
}

func mapSavedItemPGError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	var postgresError *pgconn.PgError
	if errors.As(err, &postgresError) {
		switch postgresError.Code {
		case "23505":
			return domain.ErrMutationStale
		case "22003", "23502", "23503", "23514":
			return saveditemapp.ErrDataInvariant
		default:
			return saveditemapp.ErrRepositoryUnavailable
		}
	}
	return saveditemapp.ErrRepositoryUnavailable
}
