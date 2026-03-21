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

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type PGActivityRepository struct {
	pool *pgxpool.Pool
}

func NewPGActivityRepository(pool *pgxpool.Pool) *PGActivityRepository {
	return &PGActivityRepository{pool: pool}
}

type PGActivityTxRepository struct {
	tx pgx.Tx
}

func (r *PGActivityRepository) WithTx(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}

	defer func() {
		_ = tx.Rollback(ctx)
	}()

	txRepo := &PGActivityTxRepository{tx: tx}

	if err = fn(txRepo); err != nil {
		return err
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}

	return nil
}

func (r *PGActivityRepository) CreateActivity(ctx context.Context, item *model.Activity) error {
	const query = `
		INSERT INTO activities (
			id, host_user_id, source_activity_id,
			title, description,
			format, status, visibility, join_mode, moderation_status,
			category_slug, language_code, timezone,
			start_at, end_at, registration_deadline,
			capacity_type, min_participants, max_participants,
			price_type, price_amount, currency, price_locked_at,
			requires_profile_completion, requires_attendance_confirmation, confirmation_deadline,
			country_code, city_name, address_text, latitude, longitude, map_url, meeting_url, visibility_password_hash,
			cancellation_reason, cancelled_at, started_at, completed_at, published_at,
			revision, created_at, updated_at
		) VALUES (
			$1, $2, $3,
			$4, $5,
			$6, $7, $8, $9, $10,
			$11, $12, $13,
			$14, $15, $16,
			$17, $18, $19,
			$20, $21, $22, $23,
			$24, $25, $26,
			$27, $28, $29, $30, $31, $32, $33, $34,
			$35, $36, $37, $38, $39,
			$40, $41, $42
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID, item.HostUserID, item.SourceActivityID,
		item.Title, item.Description,
		string(item.Format), string(item.Status), string(item.Visibility), string(item.JoinMode), string(item.ModerationStatus),
		item.CategorySlug, item.LanguageCode, item.Timezone,
		item.StartAt, item.EndAt, item.RegistrationDeadline,
		string(item.CapacityType), item.MinParticipants, item.MaxParticipants,
		string(item.PriceType), item.PriceAmount, item.Currency, item.PriceLockedAt,
		item.RequiresProfileCompletion, item.RequiresAttendanceConfirmation, item.ConfirmationDeadline,
		item.CountryCode, item.CityName, item.AddressText, item.Latitude, item.Longitude, item.MapURL, item.MeetingURL, item.VisibilityPasswordHash,
		item.CancellationReason, item.CancelledAt, item.StartedAt, item.CompletedAt, item.PublishedAt,
		item.Revision, item.CreatedAt, item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert activity: %w", err)
	}

	return nil
}

func (r *PGActivityRepository) UpdateActivity(ctx context.Context, item *model.Activity) error {
	const query = `
		UPDATE activities
		SET
			host_user_id = $2,
			source_activity_id = $3,
			title = $4,
			description = $5,
			format = $6,
			status = $7,
			visibility = $8,
			join_mode = $9,
			moderation_status = $10,
			category_slug = $11,
			language_code = $12,
			timezone = $13,
			start_at = $14,
			end_at = $15,
			registration_deadline = $16,
			capacity_type = $17,
			min_participants = $18,
			max_participants = $19,
			price_type = $20,
			price_amount = $21,
			currency = $22,
			price_locked_at = $23,
			requires_profile_completion = $24,
			requires_attendance_confirmation = $25,
			confirmation_deadline = $26,
			country_code = $27,
			city_name = $28,
			address_text = $29,
			latitude = $30,
			longitude = $31,
			map_url = $32,
			meeting_url = $33,
			visibility_password_hash = $34,
			cancellation_reason = $35,
			cancelled_at = $36,
			started_at = $37,
			completed_at = $38,
			published_at = $39,
			revision = $40,
			updated_at = $41
		WHERE id = $1
	`

	tag, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		item.HostUserID,
		item.SourceActivityID,
		item.Title,
		item.Description,
		string(item.Format),
		string(item.Status),
		string(item.Visibility),
		string(item.JoinMode),
		string(item.ModerationStatus),
		item.CategorySlug,
		item.LanguageCode,
		item.Timezone,
		item.StartAt,
		item.EndAt,
		item.RegistrationDeadline,
		string(item.CapacityType),
		item.MinParticipants,
		item.MaxParticipants,
		string(item.PriceType),
		item.PriceAmount,
		item.Currency,
		item.PriceLockedAt,
		item.RequiresProfileCompletion,
		item.RequiresAttendanceConfirmation,
		item.ConfirmationDeadline,
		item.CountryCode,
		item.CityName,
		item.AddressText,
		item.Latitude,
		item.Longitude,
		item.MapURL,
		item.MeetingURL,
		item.VisibilityPasswordHash,
		item.CancellationReason,
		item.CancelledAt,
		item.StartedAt,
		item.CompletedAt,
		item.PublishedAt,
		item.Revision,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update activity: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil
	}

	return nil
}

func (r *PGActivityRepository) GetActivityByID(ctx context.Context, activityID uuid.UUID) (*model.Activity, error) {
	const query = `
		SELECT
			id, host_user_id, source_activity_id,
			title, description,
			format, status, visibility, join_mode, moderation_status,
			category_slug, language_code, timezone,
			start_at, end_at, registration_deadline,
			capacity_type, min_participants, max_participants,
			price_type, price_amount, currency, price_locked_at,
			requires_profile_completion, requires_attendance_confirmation, confirmation_deadline,
			country_code, city_name, address_text, latitude, longitude, map_url, meeting_url, visibility_password_hash,
			cancellation_reason, cancelled_at, started_at, completed_at, published_at,
			revision, created_at, updated_at
		FROM activities
		WHERE id = $1
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, activityID)
	item, err := scanActivity(row)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get activity by id: %w", err)
	}

	return item, nil
}

func (r *PGActivityRepository) ListActivities(ctx context.Context, filter port.ActivityFilter) ([]*model.Activity, error) {
	base := `
		SELECT
			id, host_user_id, source_activity_id,
			title, description,
			format, status, visibility, join_mode, moderation_status,
			category_slug, language_code, timezone,
			start_at, end_at, registration_deadline,
			capacity_type, min_participants, max_participants,
			price_type, price_amount, currency, price_locked_at,
			requires_profile_completion, requires_attendance_confirmation, confirmation_deadline,
			country_code, city_name, address_text, latitude, longitude, map_url, meeting_url, visibility_password_hash,
			cancellation_reason, cancelled_at, started_at, completed_at, published_at,
			revision, created_at, updated_at
		FROM activities
		WHERE 1 = 1
	`

	args := make([]any, 0, 10)
	parts := []string{base}
	argPos := 1

	if filter.HostUserID != nil {
		parts = append(parts, fmt.Sprintf(" AND host_user_id = $%d", argPos))
		args = append(args, *filter.HostUserID)
		argPos++
	}

	if len(filter.Statuses) > 0 {
		parts = append(parts, fmt.Sprintf(" AND status = ANY($%d)", argPos))
		args = append(args, filter.Statuses)
		argPos++
	}

	if filter.Visibility != nil && strings.TrimSpace(*filter.Visibility) != "" {
		parts = append(parts, fmt.Sprintf(" AND visibility = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.Visibility))
		argPos++
	}

	if filter.CategorySlug != nil && strings.TrimSpace(*filter.CategorySlug) != "" {
		parts = append(parts, fmt.Sprintf(" AND category_slug = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.CategorySlug))
		argPos++
	}

	if filter.CountryCode != nil && strings.TrimSpace(*filter.CountryCode) != "" {
		parts = append(parts, fmt.Sprintf(" AND country_code = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.CountryCode))
		argPos++
	}

	if filter.CityName != nil && strings.TrimSpace(*filter.CityName) != "" {
		parts = append(parts, fmt.Sprintf(" AND city_name ILIKE $%d", argPos))
		args = append(args, "%"+strings.TrimSpace(*filter.CityName)+"%")
		argPos++
	}

	if filter.LanguageCode != nil && strings.TrimSpace(*filter.LanguageCode) != "" {
		parts = append(parts, fmt.Sprintf(" AND language_code = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.LanguageCode))
		argPos++
	}

	if filter.SearchQuery != nil && strings.TrimSpace(*filter.SearchQuery) != "" {
		q := "%" + strings.TrimSpace(*filter.SearchQuery) + "%"
		parts = append(parts, fmt.Sprintf(" AND (title ILIKE $%d OR description ILIKE $%d)", argPos, argPos))
		args = append(args, q)
		argPos++
	}

	parts = append(parts, " ORDER BY start_at ASC, created_at DESC")
	parts = append(parts, fmt.Sprintf(" LIMIT $%d OFFSET $%d", argPos, argPos+1))
	args = append(args, filter.Limit, filter.Offset)

	query := strings.Join(parts, "")

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("list activities: %w", err)
	}
	defer rows.Close()

	result := make([]*model.Activity, 0)
	for rows.Next() {
		item, scanErr := scanActivity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan listed activity: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) CreateActivityEvent(ctx context.Context, item *model.ActivityEvent) error {
	const query = `
		INSERT INTO activity_events (
			id, activity_id, event_type, actor_user_id, payload, created_at
		) VALUES ($1, $2, $3, $4, $5::jsonb, $6)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		item.ActivityID,
		string(item.EventType),
		item.ActorUserID,
		string(item.PayloadJSON),
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert activity event: %w", err)
	}

	return nil
}

func (r *PGActivityRepository) ListTagsByActivityID(ctx context.Context, activityID uuid.UUID) ([]string, error) {
	const query = `
		SELECT tag_slug
		FROM activity_tags
		WHERE activity_id = $1
		ORDER BY tag_slug ASC
	`

	rows, err := r.pool.Query(ctx, query, activityID)
	if err != nil {
		return nil, fmt.Errorf("list activity tags: %w", err)
	}
	defer rows.Close()

	result := make([]string, 0)
	for rows.Next() {
		var tag string
		if err = rows.Scan(&tag); err != nil {
			return nil, fmt.Errorf("scan activity tag: %w", err)
		}
		result = append(result, tag)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) ReplaceTags(ctx context.Context, activityID uuid.UUID, tags []string) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin replace tags tx: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if _, err = tx.Exec(ctx, `DELETE FROM activity_tags WHERE activity_id = $1`, activityID); err != nil {
		return fmt.Errorf("delete activity tags: %w", err)
	}

	if len(tags) > 0 {
		const insertQuery = `
			INSERT INTO activity_tags (id, activity_id, tag_slug, created_at)
			VALUES ($1, $2, $3, $4)
		`
		now := time.Now().UTC()
		for _, tag := range tags {
			tag = strings.TrimSpace(strings.ToLower(tag))
			if tag == "" {
				continue
			}
			if _, err = tx.Exec(ctx, insertQuery, uuid.New(), activityID, tag, now); err != nil {
				return fmt.Errorf("insert activity tag: %w", err)
			}
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit replace tags tx: %w", err)
	}

	return nil
}

func (r *PGActivityRepository) ListMediaByActivityID(ctx context.Context, activityID uuid.UUID) ([]*model.ActivityMedia, error) {
	const query = `
		SELECT id, activity_id, file_id, media_type, sort_order, is_cover, created_at
		FROM activity_media
		WHERE activity_id = $1
		ORDER BY sort_order ASC, created_at ASC
	`

	rows, err := r.pool.Query(ctx, query, activityID)
	if err != nil {
		return nil, fmt.Errorf("list activity media: %w", err)
	}
	defer rows.Close()

	result := make([]*model.ActivityMedia, 0)
	for rows.Next() {
		item, scanErr := scanActivityMedia(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan activity media: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) ReplaceMedia(ctx context.Context, activityID uuid.UUID, items []*model.ActivityMedia) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin replace media tx: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if _, err = tx.Exec(ctx, `DELETE FROM activity_media WHERE activity_id = $1`, activityID); err != nil {
		return fmt.Errorf("delete activity media: %w", err)
	}

	if len(items) > 0 {
		const insertQuery = `
			INSERT INTO activity_media (
				id, activity_id, file_id, media_type, sort_order, is_cover, created_at
			) VALUES ($1, $2, $3, $4, $5, $6, $7)
		`

		for _, item := range items {
			if _, err = tx.Exec(
				ctx,
				insertQuery,
				item.ID,
				item.ActivityID,
				item.FileID,
				string(item.MediaType),
				item.SortOrder,
				item.IsCover,
				item.CreatedAt,
			); err != nil {
				return fmt.Errorf("insert activity media: %w", err)
			}
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit replace media tx: %w", err)
	}

	return nil
}

func (r *PGActivityRepository) GetParticipantByActivityAndUser(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
	const query = `
		SELECT
			id, activity_id, user_id, status, joined_at, approved_at, waitlisted_at,
			payment_due_at, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
			cancelled_at, cancelled_by_user_id, cancel_reason, created_at, updated_at
		FROM activity_participants
		WHERE activity_id = $1 AND user_id = $2
		ORDER BY created_at DESC
		LIMIT 1
	`

	row := r.pool.QueryRow(ctx, query, activityID, userID)
	item, err := scanParticipant(row)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get participant by activity and user: %w", err)
	}

	return item, nil
}

func (r *PGActivityRepository) ListParticipantsByActivityID(ctx context.Context, activityID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error) {
	const query = `
		SELECT
			id, activity_id, user_id, status, joined_at, approved_at, waitlisted_at,
			payment_due_at, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
			cancelled_at, cancelled_by_user_id, cancel_reason, created_at, updated_at
		FROM activity_participants
		WHERE activity_id = $1
		ORDER BY created_at ASC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.pool.Query(ctx, query, activityID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list participants by activity id: %w", err)
	}
	defer rows.Close()

	result := make([]*model.ActivityParticipant, 0)
	for rows.Next() {
		item, scanErr := scanParticipant(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan participant: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	const query = `
		INSERT INTO activity_participants (
			id, activity_id, user_id, status, joined_at, approved_at, waitlisted_at,
			payment_due_at, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
			cancelled_at, cancelled_by_user_id, cancel_reason, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10, $11, $12,
			$13, $14, $15, $16, $17
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		item.ActivityID,
		item.UserID,
		string(item.Status),
		item.JoinedAt,
		item.ApprovedAt,
		item.WaitlistedAt,
		item.PaymentDueAt,
		item.PaidAt,
		item.AttendanceConfirmedAt,
		item.CheckedInAt,
		item.AttendedAt,
		item.CancelledAt,
		item.CancelledByUserID,
		item.CancelReason,
		item.CreatedAt,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert participant: %w", translateUniqueViolation(err))
	}

	return nil
}

func (r *PGActivityRepository) UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	const query = `
		UPDATE activity_participants
		SET
			status = $2,
			joined_at = $3,
			approved_at = $4,
			waitlisted_at = $5,
			payment_due_at = $6,
			paid_at = $7,
			attendance_confirmed_at = $8,
			checked_in_at = $9,
			attended_at = $10,
			cancelled_at = $11,
			cancelled_by_user_id = $12,
			cancel_reason = $13,
			updated_at = $14
		WHERE id = $1
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		string(item.Status),
		item.JoinedAt,
		item.ApprovedAt,
		item.WaitlistedAt,
		item.PaymentDueAt,
		item.PaidAt,
		item.AttendanceConfirmedAt,
		item.CheckedInAt,
		item.AttendedAt,
		item.CancelledAt,
		item.CancelledByUserID,
		item.CancelReason,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update participant: %w", err)
	}

	return nil
}

func (r *PGActivityRepository) CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error {
	const query = `
		INSERT INTO activity_participant_events (
			id, activity_id, participant_id, user_id, event_type, actor_user_id, payload, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		item.ActivityID,
		item.ParticipantID,
		item.UserID,
		item.EventType,
		item.ActorUserID,
		string(item.PayloadJSON),
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert participant event: %w", err)
	}

	return nil
}

/* -------------------- TX repository -------------------- */

func (r *PGActivityTxRepository) GetActivityByIDForUpdate(ctx context.Context, activityID uuid.UUID) (*model.Activity, error) {
	const query = `
		SELECT
			id, host_user_id, source_activity_id,
			title, description,
			format, status, visibility, join_mode, moderation_status,
			category_slug, language_code, timezone,
			start_at, end_at, registration_deadline,
			capacity_type, min_participants, max_participants,
			price_type, price_amount, currency, price_locked_at,
			requires_profile_completion, requires_attendance_confirmation, confirmation_deadline,
			country_code, city_name, address_text, latitude, longitude, map_url, meeting_url,
			cancellation_reason, cancelled_at, started_at, completed_at, published_at,
			revision, created_at, updated_at
		FROM activities
		WHERE id = $1
		FOR UPDATE
	`

	row := r.tx.QueryRow(ctx, query, activityID)
	item, err := scanActivity(row)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get activity by id for update: %w", err)
	}

	return item, nil
}

func (r *PGActivityTxRepository) GetParticipantByActivityAndUserForUpdate(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
	const query = `
		SELECT
			id, activity_id, user_id, status, joined_at, approved_at, waitlisted_at,
			payment_due_at, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
			cancelled_at, cancelled_by_user_id, cancel_reason, created_at, updated_at
		FROM activity_participants
		WHERE activity_id = $1 AND user_id = $2
		ORDER BY created_at DESC
		LIMIT 1
		FOR UPDATE
	`

	row := r.tx.QueryRow(ctx, query, activityID, userID)
	item, err := scanParticipant(row)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get participant by activity and user for update: %w", err)
	}

	return item, nil
}

func (r *PGActivityTxRepository) CountOccupiedSlotsForUpdate(ctx context.Context, activityID uuid.UUID) (int, error) {
	const query = `
		SELECT COUNT(*)
		FROM activity_participants
		WHERE activity_id = $1
		  AND status IN ('APPROVED', 'PENDING_PAYMENT', 'CONFIRMED', 'CHECKED_IN')
	`

	var count int
	if err := r.tx.QueryRow(ctx, query, activityID).Scan(&count); err != nil {
		return 0, fmt.Errorf("count occupied slots for update: %w", err)
	}

	return count, nil
}

func (r *PGActivityTxRepository) CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	const query = `
		INSERT INTO activity_participants (
			id, activity_id, user_id, status, joined_at, approved_at, waitlisted_at,
			payment_due_at, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
			cancelled_at, cancelled_by_user_id, cancel_reason, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10, $11, $12,
			$13, $14, $15, $16, $17
		)
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ID,
		item.ActivityID,
		item.UserID,
		string(item.Status),
		item.JoinedAt,
		item.ApprovedAt,
		item.WaitlistedAt,
		item.PaymentDueAt,
		item.PaidAt,
		item.AttendanceConfirmedAt,
		item.CheckedInAt,
		item.AttendedAt,
		item.CancelledAt,
		item.CancelledByUserID,
		item.CancelReason,
		item.CreatedAt,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert participant in tx: %w", translateUniqueViolation(err))
	}

	return nil
}

func (r *PGActivityTxRepository) UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	const query = `
		UPDATE activity_participants
		SET
			status = $2,
			joined_at = $3,
			approved_at = $4,
			waitlisted_at = $5,
			payment_due_at = $6,
			paid_at = $7,
			attendance_confirmed_at = $8,
			checked_in_at = $9,
			attended_at = $10,
			cancelled_at = $11,
			cancelled_by_user_id = $12,
			cancel_reason = $13,
			updated_at = $14
		WHERE id = $1
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ID,
		string(item.Status),
		item.JoinedAt,
		item.ApprovedAt,
		item.WaitlistedAt,
		item.PaymentDueAt,
		item.PaidAt,
		item.AttendanceConfirmedAt,
		item.CheckedInAt,
		item.AttendedAt,
		item.CancelledAt,
		item.CancelledByUserID,
		item.CancelReason,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update participant in tx: %w", err)
	}

	return nil
}

func (r *PGActivityTxRepository) CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error {
	const query = `
		INSERT INTO activity_participant_events (
			id, activity_id, participant_id, user_id, event_type, actor_user_id, payload, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8)
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ID,
		item.ActivityID,
		item.ParticipantID,
		item.UserID,
		item.EventType,
		item.ActorUserID,
		string(item.PayloadJSON),
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert participant event in tx: %w", err)
	}

	return nil
}

func (r *PGActivityTxRepository) CreateActivityEvent(ctx context.Context, item *model.ActivityEvent) error {
	const query = `
		INSERT INTO activity_events (
			id, activity_id, event_type, actor_user_id, payload, created_at
		) VALUES ($1, $2, $3, $4, $5::jsonb, $6)
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ID,
		item.ActivityID,
		string(item.EventType),
		item.ActorUserID,
		string(item.PayloadJSON),
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert activity event in tx: %w", err)
	}

	return nil
}

func (r *PGActivityTxRepository) UpdateActivity(ctx context.Context, item *model.Activity) error {
	const query = `
		UPDATE activities
		SET
			host_user_id = $2,
			source_activity_id = $3,
			title = $4,
			description = $5,
			format = $6,
			status = $7,
			visibility = $8,
			join_mode = $9,
			moderation_status = $10,
			category_slug = $11,
			language_code = $12,
			timezone = $13,
			start_at = $14,
			end_at = $15,
			registration_deadline = $16,
			capacity_type = $17,
			min_participants = $18,
			max_participants = $19,
			price_type = $20,
			price_amount = $21,
			currency = $22,
			price_locked_at = $23,
			requires_profile_completion = $24,
			requires_attendance_confirmation = $25,
			confirmation_deadline = $26,
			country_code = $27,
			city_name = $28,
			address_text = $29,
			latitude = $30,
			longitude = $31,
			map_url = $32,
			meeting_url = $33,
			visibility_password_hash = $34,
			cancellation_reason = $35,
			cancelled_at = $36,
			started_at = $37,
			completed_at = $38,
			published_at = $39,
			revision = $40,
			updated_at = $41
		WHERE id = $1
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ID,
		item.HostUserID,
		item.SourceActivityID,
		item.Title,
		item.Description,
		string(item.Format),
		string(item.Status),
		string(item.Visibility),
		string(item.JoinMode),
		string(item.ModerationStatus),
		item.CategorySlug,
		item.LanguageCode,
		item.Timezone,
		item.StartAt,
		item.EndAt,
		item.RegistrationDeadline,
		string(item.CapacityType),
		item.MinParticipants,
		item.MaxParticipants,
		string(item.PriceType),
		item.PriceAmount,
		item.Currency,
		item.PriceLockedAt,
		item.RequiresProfileCompletion,
		item.RequiresAttendanceConfirmation,
		item.ConfirmationDeadline,
		item.CountryCode,
		item.CityName,
		item.AddressText,
		item.Latitude,
		item.Longitude,
		item.MapURL,
		item.MeetingURL,
		item.VisibilityPasswordHash,
		item.CancellationReason,
		item.CancelledAt,
		item.StartedAt,
		item.CompletedAt,
		item.PublishedAt,
		item.Revision,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update activity in tx: %w", err)
	}

	return nil
}

func (r *PGActivityRepository) ListHostedActivitiesByUserID(
	ctx context.Context,
	userID uuid.UUID,
	limit int,
	offset int,
) ([]*model.Activity, error) {
	const query = `
		SELECT
			id, host_user_id, source_activity_id,
			title, description,
			format, status, visibility, join_mode, moderation_status,
			category_slug, language_code, timezone,
			start_at, end_at, registration_deadline,
			capacity_type, min_participants, max_participants,
			price_type, price_amount, currency, price_locked_at,
			requires_profile_completion, requires_attendance_confirmation, confirmation_deadline,
			country_code, city_name, address_text, latitude, longitude, map_url, meeting_url, visibility_password_hash,
			cancellation_reason, cancelled_at, started_at, completed_at, published_at,
			revision, created_at, updated_at
		FROM activities
		WHERE host_user_id = $1
		ORDER BY start_at DESC, created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.pool.Query(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list hosted activities by user id: %w", err)
	}
	defer rows.Close()

	result := make([]*model.Activity, 0)
	for rows.Next() {
		item, scanErr := scanActivity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan hosted activity: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) ListJoinedActivitiesByUserID(
	ctx context.Context,
	userID uuid.UUID,
	limit int,
	offset int,
) ([]*model.Activity, error) {
	const query = `
		SELECT DISTINCT
			a.id, a.host_user_id, a.source_activity_id,
			a.title, a.description,
			a.format, a.status, a.visibility, a.join_mode, a.moderation_status,
			a.category_slug, a.language_code, a.timezone,
			a.start_at, a.end_at, a.registration_deadline,
			a.capacity_type, a.min_participants, a.max_participants,
			a.price_type, a.price_amount, a.currency, a.price_locked_at,
			a.requires_profile_completion, a.requires_attendance_confirmation, a.confirmation_deadline,
			a.country_code, a.city_name, a.address_text, a.latitude, a.longitude, a.map_url, a.meeting_url, a.visibility_password_hash,
			a.cancellation_reason, a.cancelled_at, a.started_at, a.completed_at, a.published_at,
			a.revision, a.created_at, a.updated_at
		FROM activities a
		INNER JOIN activity_participants ap ON ap.activity_id = a.id
		WHERE ap.user_id = $1
		  AND ap.status IN (
		    'REQUESTED',
		    'APPROVED',
		    'WAITLISTED',
		    'PENDING_PAYMENT',
		    'CONFIRMED',
		    'CHECKED_IN',
		    'ATTENDED',
		    'NO_SHOW',
		    'CANCELLED',
		    'EXPIRED',
		    'DECLINED'
		  )
		ORDER BY a.start_at DESC, a.created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.pool.Query(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list joined activities by user id: %w", err)
	}
	defer rows.Close()

	result := make([]*model.Activity, 0)
	for rows.Next() {
		item, scanErr := scanActivity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan joined activity: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) ListActiveBlockedURLPatterns(ctx context.Context) ([]*model.BlockedURLPattern, error) {
	const query = `
		SELECT id, pattern_type, pattern_value, action, is_active, comment, created_at
		FROM blocked_url_patterns
		WHERE is_active = TRUE
		ORDER BY created_at ASC
	`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("list active blocked url patterns: %w", err)
	}
	defer rows.Close()

	result := make([]*model.BlockedURLPattern, 0)
	for rows.Next() {
		var (
			item        model.BlockedURLPattern
			patternType string
			action      string
		)

		if err = rows.Scan(
			&item.ID,
			&patternType,
			&item.PatternValue,
			&action,
			&item.IsActive,
			&item.Comment,
			&item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan blocked url pattern: %w", err)
		}

		item.PatternType = model.BlockedURLPatternType(patternType)
		item.Action = model.BlockedURLPatternAction(action)
		result = append(result, &item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) CountActivitiesCreatedSince(
	ctx context.Context,
	hostUserID uuid.UUID,
	since time.Time,
) (int, error) {
	const query = `
		SELECT COUNT(*)
		FROM activities
		WHERE host_user_id = $1
		  AND created_at >= $2
	`

	var count int
	if err := r.pool.QueryRow(ctx, query, hostUserID, since).Scan(&count); err != nil {
		return 0, fmt.Errorf("count activities created since: %w", err)
	}

	return count, nil
}

/* -------------------- scanners -------------------- */

type activityScanner interface {
	Scan(dest ...any) error
}

func scanActivity(row activityScanner) (*model.Activity, error) {
	var (
		item model.Activity

		formatRaw           string
		statusRaw           string
		visibilityRaw       string
		joinModeRaw         string
		moderationStatusRaw string
		capacityTypeRaw     string
		priceTypeRaw        string
	)

	err := row.Scan(
		&item.ID,
		&item.HostUserID,
		&item.SourceActivityID,

		&item.Title,
		&item.Description,

		&formatRaw,
		&statusRaw,
		&visibilityRaw,
		&joinModeRaw,
		&moderationStatusRaw,

		&item.CategorySlug,
		&item.LanguageCode,
		&item.Timezone,

		&item.StartAt,
		&item.EndAt,
		&item.RegistrationDeadline,

		&capacityTypeRaw,
		&item.MinParticipants,
		&item.MaxParticipants,

		&priceTypeRaw,
		&item.PriceAmount,
		&item.Currency,
		&item.PriceLockedAt,

		&item.RequiresProfileCompletion,
		&item.RequiresAttendanceConfirmation,
		&item.ConfirmationDeadline,

		&item.CountryCode,
		&item.CityName,
		&item.AddressText,
		&item.Latitude,
		&item.Longitude,
		&item.MapURL,
		&item.MeetingURL,
		&item.VisibilityPasswordHash,

		&item.CancellationReason,
		&item.CancelledAt,
		&item.StartedAt,
		&item.CompletedAt,
		&item.PublishedAt,

		&item.Revision,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	item.Format = enum.ActivityFormat(formatRaw)
	item.Status = enum.ActivityStatus(statusRaw)
	item.Visibility = enum.ActivityVisibility(visibilityRaw)
	item.JoinMode = enum.ActivityJoinMode(joinModeRaw)
	item.ModerationStatus = enum.ActivityModerationStatus(moderationStatusRaw)
	item.CapacityType = enum.ActivityCapacityType(capacityTypeRaw)
	item.PriceType = enum.ActivityPriceType(priceTypeRaw)

	return &item, nil
}

type mediaScanner interface {
	Scan(dest ...any) error
}

func scanActivityMedia(row mediaScanner) (*model.ActivityMedia, error) {
	var (
		item         model.ActivityMedia
		mediaTypeRaw string
	)

	err := row.Scan(
		&item.ID,
		&item.ActivityID,
		&item.FileID,
		&mediaTypeRaw,
		&item.SortOrder,
		&item.IsCover,
		&item.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	item.MediaType = model.ActivityMediaType(mediaTypeRaw)
	return &item, nil
}

type participantScanner interface {
	Scan(dest ...any) error
}

func scanParticipant(row participantScanner) (*model.ActivityParticipant, error) {
	var (
		item      model.ActivityParticipant
		statusRaw string
	)

	err := row.Scan(
		&item.ID,
		&item.ActivityID,
		&item.UserID,
		&statusRaw,
		&item.JoinedAt,
		&item.ApprovedAt,
		&item.WaitlistedAt,
		&item.PaymentDueAt,
		&item.PaidAt,
		&item.AttendanceConfirmedAt,
		&item.CheckedInAt,
		&item.AttendedAt,
		&item.CancelledAt,
		&item.CancelledByUserID,
		&item.CancelReason,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	item.Status = enum.ParticipantStatus(statusRaw)
	return &item, nil
}

/* -------------------- helpers -------------------- */

func translateUniqueViolation(err error) error {
	var pgErr *pgconn.PgError
	if ok := errors.As(err, &pgErr); ok {
		if pgErr.Code == "23505" {
			return fmt.Errorf("unique constraint violation: %w", err)
		}
	}
	return err
}
