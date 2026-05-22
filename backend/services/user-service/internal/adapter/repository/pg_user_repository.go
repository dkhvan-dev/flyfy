package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/port"
)

type PGUserRepository struct {
	pool *pgxpool.Pool
}

func NewPGUserRepository(pool *pgxpool.Pool) *PGUserRepository {
	return &PGUserRepository{pool: pool}
}

func (r *PGUserRepository) CreateUserAggregate(
	ctx context.Context,
	user *model.User,
	profile *model.UserProfile,
	settings *model.UserSettings,
	reputation *model.UserReputation,
	defaultRole *model.UserSystemRole,
) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const userQuery = `
		INSERT INTO users (
			id, auth_subject_id, status, primary_phone, primary_email, last_seen_at, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
	`
	if _, err = tx.Exec(
		ctx,
		userQuery,
		user.ID,
		user.AuthSubjectID,
		string(user.Status),
		user.PrimaryPhone,
		user.PrimaryEmail,
		user.LastSeenAt,
	); err != nil {
		return fmt.Errorf("insert user: %w", err)
	}

	const profileQuery = `
		INSERT INTO user_profiles (
			user_id, first_name, last_name, display_name, bio, birth_date,
			avatar_file_id, city_id, country_code, locale, timezone, currency,
			is_profile_completed, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11, $12,
			$13, NOW(), NOW()
		)
	`
	if _, err = tx.Exec(
		ctx,
		profileQuery,
		profile.UserID,
		profile.FirstName,
		profile.LastName,
		profile.DisplayName,
		profile.Bio,
		profile.BirthDate,
		profile.AvatarFileID,
		profile.CityID,
		profile.CountryCode,
		profile.Locale,
		profile.Timezone,
		profile.Currency,
		profile.IsProfileCompleted,
	); err != nil {
		return fmt.Errorf("insert profile: %w", err)
	}

	const settingsQuery = `
		INSERT INTO user_settings (
			user_id, notifications_push_enabled, notifications_email_enabled,
			notifications_sms_enabled, marketing_enabled, dark_mode_enabled,
			created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
	`
	if _, err = tx.Exec(
		ctx,
		settingsQuery,
		settings.UserID,
		settings.NotificationsPushEnabled,
		settings.NotificationsEmailEnabled,
		settings.NotificationsSMSEnabled,
		settings.MarketingEnabled,
		settings.DarkModeEnabled,
	); err != nil {
		return fmt.Errorf("insert settings: %w", err)
	}

	const reputationQuery = `
		INSERT INTO user_reputation (
			user_id, trust_score, risk_score, completed_bookings,
			completed_activities, cancellations_count, reports_count,
			created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
	`
	if _, err = tx.Exec(
		ctx,
		reputationQuery,
		reputation.UserID,
		reputation.TrustScore,
		reputation.RiskScore,
		reputation.CompletedBookings,
		reputation.CompletedActivities,
		reputation.CancellationsCount,
		reputation.ReportsCount,
	); err != nil {
		return fmt.Errorf("insert reputation: %w", err)
	}

	const roleQuery = `
		INSERT INTO user_system_roles (
			user_id, role, granted_at, granted_by
		) VALUES ($1, $2, NOW(), $3)
	`
	if _, err = tx.Exec(
		ctx,
		roleQuery,
		defaultRole.UserID,
		string(defaultRole.Role),
		defaultRole.GrantedBy,
	); err != nil {
		return fmt.Errorf("insert default role: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}

	return nil
}

func (r *PGUserRepository) GetUserByID(ctx context.Context, userID uuid.UUID) (*model.User, error) {
	const query = `
		SELECT
			id, auth_subject_id, status, primary_phone, primary_email,
			is_deleted, deleted_at, last_seen_at, created_at, updated_at
		FROM users
		WHERE id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, userID)

	var (
		item      model.User
		statusRaw string
	)

	err := row.Scan(
		&item.ID,
		&item.AuthSubjectID,
		&statusRaw,
		&item.PrimaryPhone,
		&item.PrimaryEmail,
		&item.IsDeleted,
		&item.DeletedAt,
		&item.LastSeenAt,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select user by id: %w", err)
	}

	item.Status = enum.UserStatus(statusRaw)
	return &item, nil
}

func (r *PGUserRepository) GetUserBySubject(ctx context.Context, subject string) (*model.User, error) {
	const query = `
		SELECT
			id, auth_subject_id, status, primary_phone, primary_email,
			is_deleted, deleted_at, last_seen_at, created_at, updated_at
		FROM users
		WHERE auth_subject_id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, subject)

	var (
		item      model.User
		statusRaw string
	)

	err := row.Scan(
		&item.ID,
		&item.AuthSubjectID,
		&statusRaw,
		&item.PrimaryPhone,
		&item.PrimaryEmail,
		&item.IsDeleted,
		&item.DeletedAt,
		&item.LastSeenAt,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select user by subject: %w", err)
	}

	item.Status = enum.UserStatus(statusRaw)
	return &item, nil
}

func (r *PGUserRepository) IsDisplayNameTaken(
	ctx context.Context,
	displayName string,
	excludeUserID uuid.UUID,
) (bool, error) {
	displayName = strings.TrimSpace(displayName)
	if displayName == "" {
		return false, nil
	}

	const query = `
		SELECT EXISTS (
			SELECT 1
			FROM user_profiles
			WHERE LOWER(BTRIM(display_name)) = LOWER(BTRIM($1))
			  AND user_id <> $2
		)
	`

	var exists bool
	if err := r.pool.QueryRow(ctx, query, displayName, excludeUserID).Scan(&exists); err != nil {
		return false, fmt.Errorf("check display name existence: %w", err)
	}

	return exists, nil
}

func (r *PGUserRepository) GetProfileByUserID(ctx context.Context, userID uuid.UUID) (*model.UserProfile, error) {
	const query = `
		SELECT
			p.user_id, p.first_name, p.last_name, p.display_name, p.bio, p.birth_date,
			p.avatar_file_id, p.city_id, p.country_code, p.locale, p.timezone, p.currency,
			p.is_profile_completed,
			COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE) AS is_online,
			u.last_seen_at,
			p.created_at, p.updated_at
		FROM user_profiles p
		JOIN users u ON u.id = p.user_id
		WHERE p.user_id = $1
	`

	var profile model.UserProfile
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&profile.UserID,
		&profile.FirstName,
		&profile.LastName,
		&profile.DisplayName,
		&profile.Bio,
		&profile.BirthDate,
		&profile.AvatarFileID,
		&profile.CityID,
		&profile.CountryCode,
		&profile.Locale,
		&profile.Timezone,
		&profile.Currency,
		&profile.IsProfileCompleted,
		&profile.IsOnline,
		&profile.LastSeenAt,
		&profile.CreatedAt,
		&profile.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, app.ErrUserNotFound
		}
		return nil, fmt.Errorf("get profile by user id: %w", err)
	}

	return &profile, nil
}

func (r *PGUserRepository) UpdateLastSeen(ctx context.Context, userID uuid.UUID) (*model.User, error) {
	const query = `
		UPDATE users
		SET last_seen_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND is_deleted = FALSE
		RETURNING
			id, auth_subject_id, status, primary_phone, primary_email,
			is_deleted, deleted_at, last_seen_at, created_at, updated_at
	`

	var (
		item      model.User
		statusRaw string
	)

	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&item.ID,
		&item.AuthSubjectID,
		&statusRaw,
		&item.PrimaryPhone,
		&item.PrimaryEmail,
		&item.IsDeleted,
		&item.DeletedAt,
		&item.LastSeenAt,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("update last seen: %w", err)
	}

	item.Status = enum.UserStatus(statusRaw)
	return &item, nil
}

func (r *PGUserRepository) GetSettingsByUserID(ctx context.Context, userID uuid.UUID) (*model.UserSettings, error) {
	const query = `
		SELECT
			user_id, notifications_push_enabled, notifications_email_enabled,
			notifications_sms_enabled, marketing_enabled, dark_mode_enabled,
			created_at, updated_at
		FROM user_settings
		WHERE user_id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, userID)

	var item model.UserSettings
	err := row.Scan(
		&item.UserID,
		&item.NotificationsPushEnabled,
		&item.NotificationsEmailEnabled,
		&item.NotificationsSMSEnabled,
		&item.MarketingEnabled,
		&item.DarkModeEnabled,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select settings by user id: %w", err)
	}

	return &item, nil
}

func (r *PGUserRepository) GetReputationByUserID(ctx context.Context, userID uuid.UUID) (*model.UserReputation, error) {
	const query = `
		SELECT
			user_id, trust_score, risk_score, completed_bookings,
			completed_activities, cancellations_count, reports_count,
			created_at, updated_at
		FROM user_reputation
		WHERE user_id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, userID)

	var item model.UserReputation
	err := row.Scan(
		&item.UserID,
		&item.TrustScore,
		&item.RiskScore,
		&item.CompletedBookings,
		&item.CompletedActivities,
		&item.CancellationsCount,
		&item.ReportsCount,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select reputation by user id: %w", err)
	}

	return &item, nil
}

func (r *PGUserRepository) ListRolesByUserID(ctx context.Context, userID uuid.UUID) ([]*model.UserSystemRole, error) {
	const query = `
		SELECT
			id, user_id, role, granted_at, granted_by, created_at
		FROM user_system_roles
		WHERE user_id = $1
		ORDER BY created_at ASC
	`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("query roles by user id: %w", err)
	}
	defer rows.Close()

	var result []*model.UserSystemRole
	for rows.Next() {
		var (
			item    model.UserSystemRole
			roleRaw string
		)

		if err := rows.Scan(
			&item.ID,
			&item.UserID,
			&roleRaw,
			&item.GrantedAt,
			&item.GrantedBy,
			&item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan user role: %w", err)
		}

		item.Role = enum.SystemRole(roleRaw)
		result = append(result, &item)
	}

	return result, rows.Err()
}

func (r *PGUserRepository) CountFollowersByUserID(ctx context.Context, userID uuid.UUID) (int, error) {
	const query = `
		SELECT COUNT(*)
		FROM user_follows
		WHERE followed_user_id = $1
	`

	var count int
	if err := r.pool.QueryRow(ctx, query, userID).Scan(&count); err != nil {
		if isUndefinedRelation(err, "user_follows") {
			return 0, nil
		}
		return 0, fmt.Errorf("count followers by user id: %w", err)
	}

	return count, nil
}

func (r *PGUserRepository) IsFollowing(
	ctx context.Context,
	followerUserID uuid.UUID,
	followedUserID uuid.UUID,
) (bool, error) {
	const query = `
		SELECT EXISTS(
			SELECT 1
			FROM user_follows
			WHERE follower_user_id = $1 AND followed_user_id = $2
		)
	`

	var exists bool
	if err := r.pool.QueryRow(ctx, query, followerUserID, followedUserID).Scan(&exists); err != nil {
		if isUndefinedRelation(err, "user_follows") {
			return false, nil
		}
		return false, fmt.Errorf("check follow exists: %w", err)
	}

	return exists, nil
}

func (r *PGUserRepository) GetFriendship(
	ctx context.Context,
	userAID uuid.UUID,
	userBID uuid.UUID,
) (*model.UserFriendship, error) {
	const query = `
		SELECT id,
		       requester_user_id,
		       addressee_user_id,
		       status,
		       requested_at,
		       responded_at,
		       updated_at
		FROM user_friendships
		WHERE (requester_user_id = $1 AND addressee_user_id = $2)
		   OR (requester_user_id = $2 AND addressee_user_id = $1)
		LIMIT 1
	`

	var (
		item      model.UserFriendship
		statusRaw string
	)
	if err := r.pool.QueryRow(ctx, query, userAID, userBID).Scan(
		&item.ID,
		&item.RequesterUserID,
		&item.AddresseeUserID,
		&statusRaw,
		&item.RequestedAt,
		&item.RespondedAt,
		&item.UpdatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		if isUndefinedRelation(err, "user_friendships") {
			return nil, nil
		}
		return nil, fmt.Errorf("get friendship: %w", err)
	}

	item.Status = enum.FriendshipStatus(statusRaw)
	return &item, nil
}

func (r *PGUserRepository) UpdateProfile(ctx context.Context, profile *model.UserProfile) error {
	const query = `
		UPDATE user_profiles
		SET
			first_name = $2,
			last_name = $3,
			display_name = $4,
			bio = $5,
			birth_date = $6,
			avatar_file_id = $7,
			city_id = $8,
			country_code = $9,
			locale = $10,
			timezone = $11,
			currency = $12,
			is_profile_completed = $13,
			updated_at = NOW()
		WHERE user_id = $1
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		profile.UserID,
		profile.FirstName,
		profile.LastName,
		profile.DisplayName,
		profile.Bio,
		profile.BirthDate,
		profile.AvatarFileID,
		profile.CityID,
		profile.CountryCode,
		profile.Locale,
		profile.Timezone,
		profile.Currency,
		profile.IsProfileCompleted,
	)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" && pgErr.ConstraintName == "uq_user_profiles_display_name_ci" {
			return app.ErrDisplayNameAlreadyTaken
		}
		return fmt.Errorf("update profile: %w", err)
	}

	return nil
}

func (r *PGUserRepository) FollowUser(
	ctx context.Context,
	followerUserID uuid.UUID,
	followedUserID uuid.UUID,
) error {
	const query = `
		INSERT INTO user_follows (follower_user_id, followed_user_id, created_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (follower_user_id, followed_user_id) DO NOTHING
	`

	if _, err := r.pool.Exec(ctx, query, followerUserID, followedUserID); err != nil {
		if isUndefinedRelation(err, "user_follows") {
			return app.ErrFollowFeatureUnavailable
		}
		return fmt.Errorf("insert user follow: %w", err)
	}

	return nil
}

func (r *PGUserRepository) UnfollowUser(
	ctx context.Context,
	followerUserID uuid.UUID,
	followedUserID uuid.UUID,
) error {
	const query = `
		DELETE FROM user_follows
		WHERE follower_user_id = $1 AND followed_user_id = $2
	`

	if _, err := r.pool.Exec(ctx, query, followerUserID, followedUserID); err != nil {
		if isUndefinedRelation(err, "user_follows") {
			return app.ErrFollowFeatureUnavailable
		}
		return fmt.Errorf("delete user follow: %w", err)
	}

	return nil
}

func (r *PGUserRepository) CreateFriendRequest(
	ctx context.Context,
	requesterUserID uuid.UUID,
	addresseeUserID uuid.UUID,
) error {
	const query = `
		INSERT INTO user_friendships (
			requester_user_id,
			addressee_user_id,
			status,
			requested_at,
			updated_at
		)
		VALUES ($1, $2, 'PENDING', NOW(), NOW())
	`

	if _, err := r.pool.Exec(ctx, query, requesterUserID, addresseeUserID); err != nil {
		if isUndefinedRelation(err, "user_friendships") {
			return app.ErrFriendshipFeatureUnavailable
		}
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			return app.ErrFriendshipAlreadyExists
		}
		return fmt.Errorf("insert friend request: %w", err)
	}

	return nil
}

func (r *PGUserRepository) AcceptFriendRequest(
	ctx context.Context,
	requesterUserID uuid.UUID,
	addresseeUserID uuid.UUID,
) error {
	const query = `
		UPDATE user_friendships
		SET status = 'ACCEPTED',
		    responded_at = NOW(),
		    updated_at = NOW()
		WHERE requester_user_id = $1
		  AND addressee_user_id = $2
		  AND status = 'PENDING'
	`

	tag, err := r.pool.Exec(ctx, query, requesterUserID, addresseeUserID)
	if err != nil {
		if isUndefinedRelation(err, "user_friendships") {
			return app.ErrFriendshipFeatureUnavailable
		}
		return fmt.Errorf("accept friend request: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return app.ErrFriendRequestNotFound
	}

	return nil
}

func (r *PGUserRepository) DeleteFriendship(
	ctx context.Context,
	userAID uuid.UUID,
	userBID uuid.UUID,
) error {
	const query = `
		DELETE FROM user_friendships
		WHERE (requester_user_id = $1 AND addressee_user_id = $2)
		   OR (requester_user_id = $2 AND addressee_user_id = $1)
	`

	if _, err := r.pool.Exec(ctx, query, userAID, userBID); err != nil {
		if isUndefinedRelation(err, "user_friendships") {
			return app.ErrFriendshipFeatureUnavailable
		}
		return fmt.Errorf("delete friendship: %w", err)
	}

	return nil
}

func (r *PGUserRepository) UpdateSettings(ctx context.Context, settings *model.UserSettings) error {
	const query = `
		UPDATE user_settings
		SET
			notifications_push_enabled = $2,
			notifications_email_enabled = $3,
			notifications_sms_enabled = $4,
			marketing_enabled = $5,
			dark_mode_enabled = $6,
			updated_at = $7
		WHERE user_id = $1
	`

	tag, err := r.pool.Exec(
		ctx,
		query,
		settings.UserID,
		settings.NotificationsPushEnabled,
		settings.NotificationsEmailEnabled,
		settings.NotificationsSMSEnabled,
		settings.MarketingEnabled,
		settings.DarkModeEnabled,
		settings.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update settings: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func (r *PGUserRepository) GrantRole(ctx context.Context, role *model.UserSystemRole) error {
	const query = `
		INSERT INTO user_system_roles (
			id, user_id, role, granted_at, granted_by, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		role.ID,
		role.UserID,
		string(role.Role),
		role.GrantedAt,
		role.GrantedBy,
		role.CreatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert role: %w", err)
	}

	return nil
}

func (r *PGUserRepository) HasRole(ctx context.Context, userID uuid.UUID, role enum.SystemRole) (bool, error) {
	const query = `
		SELECT EXISTS(
			SELECT 1
			FROM user_system_roles
			WHERE user_id = $1 AND role = $2
		)
	`

	var exists bool
	if err := r.pool.QueryRow(ctx, query, userID, string(role)).Scan(&exists); err != nil {
		return false, fmt.Errorf("check role exists: %w", err)
	}

	return exists, nil
}

func (r *PGUserRepository) ListPublicProfiles(ctx context.Context, limit int, offset int) ([]*model.UserProfile, error) {
	const query = `
		SELECT
			p.user_id, p.first_name, p.last_name, p.display_name, p.bio, p.birth_date,
			p.avatar_file_id, p.city_id, p.country_code, p.locale, p.timezone, p.currency,
			p.is_profile_completed,
			COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE) AS is_online,
			u.last_seen_at,
			p.created_at, p.updated_at
		FROM user_profiles p
		JOIN users u ON u.id = p.user_id
		WHERE u.is_deleted = FALSE
		ORDER BY p.created_at DESC
		LIMIT $1 OFFSET $2
	`

	rows, err := r.pool.Query(ctx, query, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("query public profiles: %w", err)
	}
	defer rows.Close()

	var items []*model.UserProfile
	for rows.Next() {
		var profile model.UserProfile
		if err = rows.Scan(
			&profile.UserID,
			&profile.FirstName,
			&profile.LastName,
			&profile.DisplayName,
			&profile.Bio,
			&profile.BirthDate,
			&profile.AvatarFileID,
			&profile.CityID,
			&profile.CountryCode,
			&profile.Locale,
			&profile.Timezone,
			&profile.Currency,
			&profile.IsProfileCompleted,
			&profile.IsOnline,
			&profile.LastSeenAt,
			&profile.CreatedAt,
			&profile.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan public profile: %w", err)
		}
		items = append(items, &profile)
	}

	return items, rows.Err()
}

func (r *PGUserRepository) GetPublicProfilesByUserIDs(ctx context.Context, userIDs []uuid.UUID) ([]*model.UserProfile, error) {
	if len(userIDs) == 0 {
		return []*model.UserProfile{}, nil
	}

	const query = `
		SELECT
			p.user_id, p.first_name, p.last_name, p.display_name, p.bio, p.birth_date,
			p.avatar_file_id, p.city_id, p.country_code, p.locale, p.timezone, p.currency,
			p.is_profile_completed,
			COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE) AS is_online,
			u.last_seen_at,
			p.created_at, p.updated_at
		FROM user_profiles p
		JOIN users u ON u.id = p.user_id
		WHERE p.user_id = ANY($1)
		  AND u.is_deleted = FALSE
	`

	rows, err := r.pool.Query(ctx, query, userIDs)
	if err != nil {
		return nil, fmt.Errorf("query public profiles by user ids: %w", err)
	}
	defer rows.Close()

	var result []*model.UserProfile
	for rows.Next() {
		var item model.UserProfile
		if err := rows.Scan(
			&item.UserID,
			&item.FirstName,
			&item.LastName,
			&item.DisplayName,
			&item.Bio,
			&item.BirthDate,
			&item.AvatarFileID,
			&item.CityID,
			&item.CountryCode,
			&item.Locale,
			&item.Timezone,
			&item.Currency,
			&item.IsProfileCompleted,
			&item.IsOnline,
			&item.LastSeenAt,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan public profile by user ids: %w", err)
		}
		result = append(result, &item)
	}

	return result, rows.Err()
}

func (r *PGUserRepository) ListPublicUserIDsByCountryCodes(
	ctx context.Context,
	countryCodes []string,
) ([]uuid.UUID, error) {
	if len(countryCodes) == 0 {
		return []uuid.UUID{}, nil
	}

	const query = `
		SELECT p.user_id
		FROM user_profiles p
		JOIN users u ON u.id = p.user_id
		WHERE u.is_deleted = FALSE
		  AND UPPER(COALESCE(p.country_code, '')) = ANY($1)
		ORDER BY p.created_at DESC, p.user_id ASC
	`

	rows, err := r.pool.Query(ctx, query, countryCodes)
	if err != nil {
		return nil, fmt.Errorf("query public user ids by country codes: %w", err)
	}
	defer rows.Close()

	result := make([]uuid.UUID, 0)
	for rows.Next() {
		var userID uuid.UUID
		if err = rows.Scan(&userID); err != nil {
			return nil, fmt.Errorf("scan public user id by country code: %w", err)
		}
		result = append(result, userID)
	}

	return result, rows.Err()
}

func (r *PGUserRepository) ListFollowersByUserID(
	ctx context.Context,
	userID uuid.UUID,
	searchQuery string,
	limit int,
	offset int,
) ([]*model.UserProfile, error) {
	const query = `
		SELECT
			p.user_id, p.first_name, p.last_name, p.display_name, p.bio, p.birth_date,
			p.avatar_file_id, p.city_id, p.country_code, p.locale, p.timezone, p.currency,
			p.is_profile_completed,
			COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE) AS is_online,
			u.last_seen_at,
			p.created_at, p.updated_at
		FROM user_follows f
		JOIN user_profiles p ON p.user_id = f.follower_user_id
		JOIN users u ON u.id = p.user_id
		WHERE f.followed_user_id = $1
		  AND u.is_deleted = FALSE
		  AND (
			$2 = ''
			OR COALESCE(p.display_name, '') ILIKE '%' || $2 || '%'
			OR COALESCE(p.first_name, '') ILIKE '%' || $2 || '%'
			OR COALESCE(p.last_name, '') ILIKE '%' || $2 || '%'
			OR TRIM(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, '')) ILIKE '%' || $2 || '%'
		  )
		ORDER BY f.created_at DESC, p.created_at DESC
		LIMIT $3 OFFSET $4
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		userID,
		strings.TrimSpace(searchQuery),
		limit,
		offset,
	)
	if err != nil {
		if isUndefinedRelation(err, "user_follows") {
			return []*model.UserProfile{}, nil
		}
		return nil, fmt.Errorf("query followers by user id: %w", err)
	}
	defer rows.Close()

	return scanProfileListRows(rows, "follower profile")
}

func (r *PGUserRepository) ListFriendsByUserID(
	ctx context.Context,
	userID uuid.UUID,
	options port.UserConnectionListOptions,
) ([]*model.UserProfile, error) {
	orderClause := buildProfileConnectionOrderClause(
		options.Sort,
		options.SortDirection,
		"fr.updated_at",
	)
	query := `
		SELECT
			p.user_id, p.first_name, p.last_name, p.display_name, p.bio, p.birth_date,
			p.avatar_file_id, p.city_id, p.country_code, p.locale, p.timezone, p.currency,
			p.is_profile_completed,
			COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE) AS is_online,
			u.last_seen_at,
			p.created_at, p.updated_at
		FROM user_friendships fr
		JOIN user_profiles p
			ON p.user_id = CASE
				WHEN fr.requester_user_id = $1 THEN fr.addressee_user_id
				ELSE fr.requester_user_id
			END
		JOIN users u ON u.id = p.user_id
		WHERE (fr.requester_user_id = $1 OR fr.addressee_user_id = $1)
		  AND fr.status = 'ACCEPTED'
		  AND u.is_deleted = FALSE
		  AND (
			$2 = ''
			OR COALESCE(p.display_name, '') ILIKE '%' || $2 || '%'
			OR COALESCE(p.first_name, '') ILIKE '%' || $2 || '%'
			OR COALESCE(p.last_name, '') ILIKE '%' || $2 || '%'
			OR TRIM(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, '')) ILIKE '%' || $2 || '%'
		  )
		  AND (
			$3 = FALSE
			OR COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE)
		  )
		` + orderClause + `
		LIMIT $4 OFFSET $5
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		userID,
		strings.TrimSpace(options.SearchQuery),
		options.OnlineOnly,
		options.Limit,
		options.Offset,
	)
	if err != nil {
		if isUndefinedRelation(err, "user_friendships") {
			return []*model.UserProfile{}, nil
		}
		return nil, fmt.Errorf("query friends by user id: %w", err)
	}
	defer rows.Close()

	return scanProfileListRows(rows, "friend profile")
}

func (r *PGUserRepository) ListIncomingFriendRequestsByUserID(
	ctx context.Context,
	userID uuid.UUID,
	options port.UserConnectionListOptions,
) ([]*model.UserFriendRequest, error) {
	const query = `
		SELECT
			p.user_id, p.first_name, p.last_name, p.display_name, p.bio, p.birth_date,
			p.avatar_file_id, p.city_id, p.country_code, p.locale, p.timezone, p.currency,
			p.is_profile_completed,
			COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE) AS is_online,
			u.last_seen_at,
			p.created_at, p.updated_at,
			fr.requested_at
		FROM user_friendships fr
		JOIN user_profiles p ON p.user_id = fr.requester_user_id
		JOIN users u ON u.id = p.user_id
		WHERE fr.addressee_user_id = $1
		  AND fr.status = 'PENDING'
		  AND u.is_deleted = FALSE
		  AND (
			$2 = ''
			OR COALESCE(p.display_name, '') ILIKE '%' || $2 || '%'
			OR COALESCE(p.first_name, '') ILIKE '%' || $2 || '%'
			OR COALESCE(p.last_name, '') ILIKE '%' || $2 || '%'
			OR TRIM(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, '')) ILIKE '%' || $2 || '%'
		  )
		ORDER BY fr.requested_at DESC, p.user_id ASC
		LIMIT $3 OFFSET $4
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		userID,
		strings.TrimSpace(options.SearchQuery),
		options.Limit,
		options.Offset,
	)
	if err != nil {
		if isUndefinedRelation(err, "user_friendships") {
			return []*model.UserFriendRequest{}, nil
		}
		return nil, fmt.Errorf("query incoming friend requests by user id: %w", err)
	}
	defer rows.Close()

	return scanFriendRequestListRows(rows)
}

func (r *PGUserRepository) ListFollowingByUserID(
	ctx context.Context,
	userID uuid.UUID,
	options port.UserConnectionListOptions,
) ([]*model.UserProfile, error) {
	orderClause := buildProfileConnectionOrderClause(
		options.Sort,
		options.SortDirection,
		"f.created_at",
	)
	query := `
		SELECT
			p.user_id, p.first_name, p.last_name, p.display_name, p.bio, p.birth_date,
			p.avatar_file_id, p.city_id, p.country_code, p.locale, p.timezone, p.currency,
			p.is_profile_completed,
			COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE) AS is_online,
			u.last_seen_at,
			p.created_at, p.updated_at
		FROM user_follows f
		JOIN user_profiles p ON p.user_id = f.followed_user_id
		JOIN users u ON u.id = p.user_id
		WHERE f.follower_user_id = $1
		  AND u.is_deleted = FALSE
		  AND (
			$2 = ''
			OR COALESCE(p.display_name, '') ILIKE '%' || $2 || '%'
			OR COALESCE(p.first_name, '') ILIKE '%' || $2 || '%'
			OR COALESCE(p.last_name, '') ILIKE '%' || $2 || '%'
			OR TRIM(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, '')) ILIKE '%' || $2 || '%'
		  )
		  AND (
			$3 = FALSE
			OR COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE)
		  )
		` + orderClause + `
		LIMIT $4 OFFSET $5
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		userID,
		strings.TrimSpace(options.SearchQuery),
		options.OnlineOnly,
		options.Limit,
		options.Offset,
	)
	if err != nil {
		if isUndefinedRelation(err, "user_follows") {
			return []*model.UserProfile{}, nil
		}
		return nil, fmt.Errorf("query following by user id: %w", err)
	}
	defer rows.Close()

	return scanProfileListRows(rows, "following profile")
}

func buildProfileConnectionOrderClause(
	sort string,
	direction string,
	recentExpr string,
) string {
	sortDirection := "DESC"
	if strings.EqualFold(strings.TrimSpace(direction), "asc") {
		sortDirection = "ASC"
	}

	nameExpr := "LOWER(COALESCE(NULLIF(p.display_name, ''), NULLIF(TRIM(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, '')), ''), p.user_id::text))"
	onlineExpr := "COALESCE(u.last_seen_at >= NOW() - INTERVAL '2 minutes', FALSE)"

	switch strings.ToLower(strings.TrimSpace(sort)) {
	case "name":
		return fmt.Sprintf(
			" ORDER BY %s %s, %s DESC, p.user_id ASC ",
			nameExpr,
			sortDirection,
			recentExpr,
		)
	case "online":
		return fmt.Sprintf(
			" ORDER BY %s %s, %s DESC, %s ASC, p.user_id ASC ",
			onlineExpr,
			sortDirection,
			recentExpr,
			nameExpr,
		)
	default:
		return fmt.Sprintf(
			" ORDER BY %s %s, p.created_at DESC, p.user_id ASC ",
			recentExpr,
			sortDirection,
		)
	}
}

func scanProfileListRows(rows pgx.Rows, itemName string) ([]*model.UserProfile, error) {
	var result []*model.UserProfile
	for rows.Next() {
		var item model.UserProfile
		if err := rows.Scan(
			&item.UserID,
			&item.FirstName,
			&item.LastName,
			&item.DisplayName,
			&item.Bio,
			&item.BirthDate,
			&item.AvatarFileID,
			&item.CityID,
			&item.CountryCode,
			&item.Locale,
			&item.Timezone,
			&item.Currency,
			&item.IsProfileCompleted,
			&item.IsOnline,
			&item.LastSeenAt,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan %s: %w", itemName, err)
		}
		result = append(result, &item)
	}

	return result, rows.Err()
}

func scanFriendRequestListRows(rows pgx.Rows) ([]*model.UserFriendRequest, error) {
	var result []*model.UserFriendRequest
	for rows.Next() {
		var profile model.UserProfile
		var requestedAt time.Time
		if err := rows.Scan(
			&profile.UserID,
			&profile.FirstName,
			&profile.LastName,
			&profile.DisplayName,
			&profile.Bio,
			&profile.BirthDate,
			&profile.AvatarFileID,
			&profile.CityID,
			&profile.CountryCode,
			&profile.Locale,
			&profile.Timezone,
			&profile.Currency,
			&profile.IsProfileCompleted,
			&profile.IsOnline,
			&profile.LastSeenAt,
			&profile.CreatedAt,
			&profile.UpdatedAt,
			&requestedAt,
		); err != nil {
			return nil, fmt.Errorf("scan incoming friend request: %w", err)
		}
		result = append(result, &model.UserFriendRequest{
			Profile:     &profile,
			RequestedAt: requestedAt,
		})
	}

	return result, rows.Err()
}

func (r *PGUserRepository) PatchUserIdentityBySubject(
	ctx context.Context,
	subjectID string,
	primaryPhone *string,
	primaryEmail *string,
) error {
	subjectID = strings.TrimSpace(subjectID)
	if subjectID == "" {
		return nil
	}

	var phone *string
	if primaryPhone != nil {
		v := strings.TrimSpace(*primaryPhone)
		if v != "" {
			phone = &v
		}
	}

	var email *string
	if primaryEmail != nil {
		v := strings.TrimSpace(*primaryEmail)
		if v != "" {
			email = &v
		}
	}

	if phone == nil && email == nil {
		return nil
	}

	const query = `
		UPDATE users
		SET
			primary_phone = CASE
				WHEN ($2::text IS NOT NULL AND (primary_phone IS NULL OR btrim(primary_phone) = ''))
				THEN $2::text
				ELSE primary_phone
			END,
			primary_email = CASE
				WHEN ($3::text IS NOT NULL AND (primary_email IS NULL OR btrim(primary_email) = ''))
				THEN $3::text
				ELSE primary_email
			END,
			updated_at = NOW()
		WHERE auth_subject_id = $1
	`

	_, err := r.pool.Exec(ctx, query, subjectID, phone, email)
	if err != nil {
		return fmt.Errorf("patch user identity by subject: %w", err)
	}

	return nil
}
