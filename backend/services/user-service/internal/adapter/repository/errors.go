package repository

import (
	"errors"
	"strings"

	"github.com/jackc/pgx/v5/pgconn"
)

var (
	ErrNotFound        = errors.New("not found")
	ErrConflict        = errors.New("conflict")
	ErrUniqueViolation = errors.New("unique violation")
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

func isUndefinedRelation(err error, relation string) bool {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return false
	}

	if pgErr.Code != "42P01" {
		return false
	}

	relation = strings.TrimSpace(relation)
	if relation == "" {
		return true
	}

	return strings.Contains(pgErr.Message, relation) ||
		strings.Contains(pgErr.Detail, relation) ||
		strings.Contains(pgErr.Where, relation) ||
		strings.Contains(pgErr.InternalQuery, relation)
}
