package repository

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	savedsearchapp "kz/inflap/backend/services/saved-service/internal/app/savedsearch"
)

type PGSavedSearchRepository struct {
	pool *pgxpool.Pool
}

var _ savedsearchapp.Repository = (*PGSavedSearchRepository)(nil)

func NewPGSavedSearchRepository(pool *pgxpool.Pool) (*PGSavedSearchRepository, error) {
	if pool == nil {
		return nil, savedsearchapp.ErrInvalidQuery
	}
	return &PGSavedSearchRepository{pool: pool}, nil
}

type savedSearchExecutor interface {
	Query(context.Context, string, ...any) (pgx.Rows, error)
}

type savedSearchScanner interface {
	Scan(...any) error
}

func mapSavedSearchPGError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	var postgresError *pgconn.PgError
	if errors.As(err, &postgresError) &&
		(strings.HasPrefix(postgresError.Code, "22") || strings.HasPrefix(postgresError.Code, "23")) {
		return savedsearchapp.ErrDataInvariant
	}
	return savedsearchapp.ErrRepositoryUnavailable
}
