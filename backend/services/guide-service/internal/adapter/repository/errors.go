package repository

import (
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
)

var (
	ErrNotFound        = errors.New("not found")
	ErrConflict        = errors.New("conflict")
	ErrUniqueViolation = errors.New("unique violation")
	ErrLeaseLost       = errors.New("lease lost")
)

func classifyPGError(err error) error {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		switch pgErr.Code {
		case "23505":
			return ErrUniqueViolation
		}
	}
	return err
}
