package repository

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
)

type PGSavedQueryRepository struct {
	pool *pgxpool.Pool
}

var _ savedqueryapp.Repository = (*PGSavedQueryRepository)(nil)

func NewPGSavedQueryRepository(pool *pgxpool.Pool) (*PGSavedQueryRepository, error) {
	if pool == nil {
		return nil, savedqueryapp.ErrInvalidQuery
	}
	return &PGSavedQueryRepository{pool: pool}, nil
}

type savedQueryExecutor interface {
	Query(context.Context, string, ...any) (pgx.Rows, error)
	QueryRow(context.Context, string, ...any) pgx.Row
}

type savedQueryScanner interface {
	Scan(...any) error
}

func mapSavedQueryPGError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	var postgresError *pgconn.PgError
	if errors.As(err, &postgresError) {
		if strings.HasPrefix(postgresError.Code, "22") || strings.HasPrefix(postgresError.Code, "23") {
			return savedqueryapp.ErrDataInvariant
		}
	}
	return savedqueryapp.ErrRepositoryUnavailable
}
