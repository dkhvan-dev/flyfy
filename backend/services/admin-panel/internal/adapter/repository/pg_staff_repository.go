package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

type PGStaffRepository struct {
	pool *pgxpool.Pool
}

func NewPGStaffRepository(pool *pgxpool.Pool) *PGStaffRepository {
	return &PGStaffRepository{pool: pool}
}

func (r *PGStaffRepository) GetByID(ctx context.Context, id uuid.UUID) (*model.StaffUser, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, email, display_name, password_hash, status, failed_login_count,
		       locked_until, last_login_at, password_changed_at, created_by_staff_id,
		       created_at, updated_at, disabled_at
		FROM staff_users
		WHERE id = $1
	`, id)
	return scanStaffUser(row)
}

func (r *PGStaffRepository) GetByEmail(ctx context.Context, email string) (*model.StaffUser, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, email, display_name, password_hash, status, failed_login_count,
		       locked_until, last_login_at, password_changed_at, created_by_staff_id,
		       created_at, updated_at, disabled_at
		FROM staff_users
		WHERE LOWER(email) = LOWER($1)
	`, strings.TrimSpace(email))
	return scanStaffUser(row)
}

func (r *PGStaffRepository) List(ctx context.Context, limit int, offset int) ([]*model.StaffUser, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, email, display_name, password_hash, status, failed_login_count,
		       locked_until, last_login_at, password_changed_at, created_by_staff_id,
		       created_at, updated_at, disabled_at
		FROM staff_users
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []*model.StaffUser
	for rows.Next() {
		item, err := scanStaffUser(rows)
		if err != nil {
			return nil, err
		}
		_, roles, err := r.GetPermissions(ctx, item.ID)
		if err != nil {
			return nil, err
		}
		item.Roles = roles
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGStaffRepository) Create(ctx context.Context, staff *model.StaffUser, passwordHash string, roles []enum.StaffRole) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	_, err = tx.Exec(ctx, `
		INSERT INTO staff_users (
			id, email, display_name, password_hash, status, failed_login_count,
			created_by_staff_id, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, 0, $6, $7, $8)
	`, staff.ID, staff.Email, staff.DisplayName, passwordHash, string(staff.Status), staff.CreatedByStaffID, staff.CreatedAt, staff.UpdatedAt)
	if err != nil {
		return err
	}
	for _, role := range roles {
		if _, err = tx.Exec(ctx, `
			INSERT INTO staff_user_roles(staff_user_id, role_code, assigned_by, assigned_at)
			VALUES ($1, $2, $3, $4)
			ON CONFLICT DO NOTHING
		`, staff.ID, string(role), staff.CreatedByStaffID, staff.CreatedAt); err != nil {
			return err
		}
	}
	return tx.Commit(ctx)
}

func (r *PGStaffRepository) UpdateProfileAndRoles(ctx context.Context, id uuid.UUID, displayName string, roles []enum.StaffRole, assignedBy uuid.UUID, now time.Time) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	roleCodes := make([]string, 0, len(roles))
	for _, role := range roles {
		roleCodes = append(roleCodes, string(role))
	}

	if _, err = tx.Exec(ctx, `
		UPDATE staff_users
		SET display_name = $2,
		    updated_at = $3
		WHERE id = $1
	`, id, displayName, now); err != nil {
		return err
	}
	if _, err = tx.Exec(ctx, `
		UPDATE staff_user_roles
		SET revoked_at = $3
		WHERE staff_user_id = $1
		  AND revoked_at IS NULL
		  AND NOT (role_code = ANY($2::text[]))
	`, id, roleCodes, now); err != nil {
		return err
	}
	for _, role := range roleCodes {
		if _, err = tx.Exec(ctx, `
			INSERT INTO staff_user_roles(staff_user_id, role_code, assigned_by, assigned_at)
			SELECT $1, $2, $3, $4
			WHERE NOT EXISTS (
				SELECT 1
				FROM staff_user_roles
				WHERE staff_user_id = $1
				  AND role_code = $2
				  AND revoked_at IS NULL
			)
		`, id, role, assignedBy, now); err != nil {
			return err
		}
	}
	return tx.Commit(ctx)
}

func (r *PGStaffRepository) UpdateLoginSuccess(ctx context.Context, id uuid.UUID, now time.Time) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE staff_users
		SET failed_login_count = 0,
		    locked_until = NULL,
		    last_login_at = $2,
		    updated_at = $2,
		    status = CASE
		        WHEN status = 'LOCKED' AND password_changed_at IS NULL THEN 'PASSWORD_RESET_REQUIRED'
		        WHEN status = 'LOCKED' THEN 'ACTIVE'
		        ELSE status
		    END
		WHERE id = $1
	`, id, now)
	return err
}

func (r *PGStaffRepository) UpdateLoginFailure(ctx context.Context, id uuid.UUID, failedCount int, lockedUntil *time.Time) error {
	status := enum.StaffStatusActive
	if lockedUntil != nil {
		status = enum.StaffStatusLocked
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE staff_users
		SET failed_login_count = $2,
		    locked_until = $3,
		    status = CASE WHEN $3::timestamptz IS NULL THEN status ELSE $4 END,
		    updated_at = NOW()
		WHERE id = $1
	`, id, failedCount, lockedUntil, string(status))
	return err
}

func (r *PGStaffRepository) UpdatePassword(ctx context.Context, id uuid.UUID, passwordHash string, status enum.StaffStatus, now time.Time) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE staff_users
		SET password_hash = $2,
		    status = $3,
		    failed_login_count = 0,
		    locked_until = NULL,
		    password_changed_at = $4,
		    updated_at = $4
		WHERE id = $1
	`, id, passwordHash, string(status), now)
	return err
}

func (r *PGStaffRepository) SetStatus(ctx context.Context, id uuid.UUID, status enum.StaffStatus, now time.Time) error {
	var disabledAt *time.Time
	if status == enum.StaffStatusDisabled {
		disabledAt = &now
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE staff_users
		SET status = $2,
		    disabled_at = $3,
		    updated_at = $4
		WHERE id = $1
	`, id, string(status), disabledAt, now)
	return err
}

func (r *PGStaffRepository) GetPermissions(ctx context.Context, staffID uuid.UUID) ([]enum.Permission, []enum.StaffRole, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT DISTINCT sur.role_code, srp.permission_code
		FROM staff_user_roles sur
		LEFT JOIN staff_role_permissions srp ON srp.role_code = sur.role_code
		WHERE sur.staff_user_id = $1
		  AND sur.revoked_at IS NULL
		ORDER BY sur.role_code, srp.permission_code
	`, staffID)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()
	roleSeen := map[enum.StaffRole]struct{}{}
	permissionSeen := map[enum.Permission]struct{}{}
	var roles []enum.StaffRole
	var permissions []enum.Permission
	for rows.Next() {
		var roleRaw string
		var permissionRaw *string
		if err = rows.Scan(&roleRaw, &permissionRaw); err != nil {
			return nil, nil, err
		}
		role := enum.StaffRole(roleRaw)
		if _, ok := roleSeen[role]; !ok {
			roleSeen[role] = struct{}{}
			roles = append(roles, role)
		}
		if permissionRaw != nil && strings.TrimSpace(*permissionRaw) != "" {
			permission := enum.Permission(*permissionRaw)
			if _, ok := permissionSeen[permission]; !ok {
				permissionSeen[permission] = struct{}{}
				permissions = append(permissions, permission)
			}
		}
	}
	return permissions, roles, rows.Err()
}

type staffScanner interface {
	Scan(dest ...any) error
}

func scanStaffUser(row staffScanner) (*model.StaffUser, error) {
	var item model.StaffUser
	var status string
	err := row.Scan(
		&item.ID,
		&item.Email,
		&item.DisplayName,
		&item.PasswordHash,
		&status,
		&item.FailedLoginCount,
		&item.LockedUntil,
		&item.LastLoginAt,
		&item.PasswordChangedAt,
		&item.CreatedByStaffID,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.DisabledAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	item.Status = enum.StaffStatus(status)
	return &item, nil
}
