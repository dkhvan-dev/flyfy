package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/auth-service/internal/domain/model"
)

// PgUserRepository implements port.UserRepository using PostgreSQL.
type PgUserRepository struct {
	pool *pgxpool.Pool
}

func NewPgUserRepository(pool *pgxpool.Pool) *PgUserRepository {
	return &PgUserRepository{pool: pool}
}

// FindByPhone returns a user by phone number.
func (r *PgUserRepository) FindByPhone(ctx context.Context, phone string) (*model.AuthUser, error) {
	query := `
		SELECT id, phone, email, password_hash, email_verified, role, is_active, created_at, updated_at
		FROM auth_users
		WHERE phone = $1
	`

	var user model.AuthUser
	err := r.pool.QueryRow(ctx, query, phone).Scan(
		&user.ID, &user.Phone, &user.Email, &user.PasswordHash, &user.EmailVerified,
		&user.Role, &user.IsActive,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil // user not found is not an error
		}
		return nil, fmt.Errorf("querying user by phone: %w", err)
	}
	return &user, nil
}

func (r *PgUserRepository) FindByEmail(ctx context.Context, email string) (*model.AuthUser, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" {
		return nil, nil
	}
	query := `
		SELECT id, phone, email, password_hash, email_verified, role, is_active, created_at, updated_at
		FROM auth_users
		WHERE LOWER(BTRIM(email)) = LOWER(BTRIM($1))
	`

	var user model.AuthUser
	err := r.pool.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Phone, &user.Email, &user.PasswordHash, &user.EmailVerified,
		&user.Role, &user.IsActive,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("querying user by email: %w", err)
	}
	return &user, nil
}

func (r *PgUserRepository) FindByID(ctx context.Context, userID uuid.UUID) (*model.AuthUser, error) {
	if userID == uuid.Nil {
		return nil, nil
	}
	query := `
		SELECT id, phone, email, password_hash, email_verified, role, is_active, created_at, updated_at
		FROM auth_users
		WHERE id = $1
	`

	var user model.AuthUser
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&user.ID, &user.Phone, &user.Email, &user.PasswordHash, &user.EmailVerified,
		&user.Role, &user.IsActive,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("querying user by id: %w", err)
	}
	return &user, nil
}

// FindByProvider returns a user by OAuth provider + provider ID.
func (r *PgUserRepository) FindByProvider(ctx context.Context, provider model.AuthProvider, providerID string) (*model.AuthUser, error) {
	query := `
		SELECT u.id, u.phone, u.email, u.password_hash, u.email_verified, u.role, u.is_active, u.created_at, u.updated_at
		FROM auth_users u
		INNER JOIN auth_providers ap ON ap.user_id = u.id
		WHERE ap.provider = $1 AND ap.provider_id = $2
	`

	var user model.AuthUser
	err := r.pool.QueryRow(ctx, query, string(provider), providerID).Scan(
		&user.ID, &user.Phone, &user.Email, &user.PasswordHash, &user.EmailVerified,
		&user.Role, &user.IsActive,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("querying user by provider: %w", err)
	}
	return &user, nil
}

// Create inserts a new user into the database.
func (r *PgUserRepository) Create(ctx context.Context, user *model.AuthUser) error {
	query := `
		INSERT INTO auth_users (id, phone, email, password_hash, email_verified, role, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	_, err := r.pool.Exec(ctx, query,
		user.ID,
		user.Phone,
		user.Email,
		user.PasswordHash,
		user.EmailVerified,
		user.Role,
		user.IsActive,
	)
	if err != nil {
		return fmt.Errorf("creating user: %w", err)
	}
	return nil
}

func (r *PgUserRepository) UpdateEmailVerification(ctx context.Context, userID uuid.UUID, verified bool) error {
	if userID == uuid.Nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE auth_users
		SET email_verified = $2
		WHERE id = $1
	`, userID, verified)
	if err != nil {
		return fmt.Errorf("updating email verification: %w", err)
	}
	return nil
}

func (r *PgUserRepository) UpdatePasswordHash(ctx context.Context, userID uuid.UUID, passwordHash string) error {
	if userID == uuid.Nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE auth_users
		SET password_hash = $2,
		    updated_at = NOW()
		WHERE id = $1
	`, userID, passwordHash)
	if err != nil {
		return fmt.Errorf("updating password hash: %w", err)
	}
	return nil
}

// LinkProvider links an OAuth provider to an existing user.
func (r *PgUserRepository) LinkProvider(ctx context.Context, link *model.AuthProviderLink) error {
	query := `
		INSERT INTO auth_providers (id, user_id, provider, provider_id, email)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (provider, provider_id) DO NOTHING
	`

	_, err := r.pool.Exec(ctx, query, link.ID, link.UserID, string(link.Provider), link.ProviderID, link.Email)
	if err != nil {
		return fmt.Errorf("linking provider: %w", err)
	}
	return nil
}
