package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/model"
)

// PgServiceAccountStore implements port.ServiceAccountStore using PostgreSQL.
type PgServiceAccountStore struct {
	pool *pgxpool.Pool
}

func NewPgServiceAccountStore(pool *pgxpool.Pool) *PgServiceAccountStore {
	return &PgServiceAccountStore{pool: pool}
}

func (s *PgServiceAccountStore) GetByServiceID(ctx context.Context, serviceID string) (*model.ServiceAccount, error) {
	query := `
		SELECT sa.id, sa.service_id, sa.service_secret, sa.display_name, sa.is_active,
		       sa.created_at, sa.updated_at
		FROM service_accounts sa
		WHERE sa.service_id = $1
	`

	var account model.ServiceAccount
	err := s.pool.QueryRow(ctx, query, serviceID).Scan(
		&account.ID,
		&account.ServiceID,
		&account.SecretHash,
		&account.DisplayName,
		&account.IsActive,
		&account.CreatedAt,
		&account.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("querying service account: %w", err)
	}

	// Fetch roles
	roles, err := s.GetRoles(ctx, account.ID.String())
	if err != nil {
		return nil, err
	}
	account.Roles = roles

	return &account, nil
}

func (s *PgServiceAccountStore) GetRoles(ctx context.Context, accountID string) ([]string, error) {
	uid, err := uuid.Parse(accountID)
	if err != nil {
		return nil, fmt.Errorf("invalid account ID: %w", err)
	}

	query := `
		SELECT role FROM service_roles
		WHERE account_id = $1
		ORDER BY role
	`

	rows, err := s.pool.Query(ctx, query, uid)
	if err != nil {
		return nil, fmt.Errorf("querying service roles: %w", err)
	}
	defer rows.Close()

	var roles []string
	for rows.Next() {
		var role string
		if err := rows.Scan(&role); err != nil {
			return nil, fmt.Errorf("scanning role: %w", err)
		}
		roles = append(roles, role)
	}
	return roles, rows.Err()
}
