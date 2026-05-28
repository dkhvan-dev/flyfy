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

const activitySelectColumns = `
	id, host_user_id, source_activity_id,
	title, description,
	format, status, visibility, join_mode, moderation_status,
	moderation_risk_score, moderation_reason_codes, moderation_triggered_at, moderation_reviewed_at,
	category_slug, subcategory_slug, language_code, timezone,
	start_at, end_at, registration_deadline,
	capacity_type, min_participants, max_participants,
	price_type, price_amount, currency, price_locked_at,
	requires_profile_completion, requires_attendance_confirmation, allows_participant_invites, confirmation_deadline,
	country_code, city_id, city_name, address_text, latitude, longitude, map_url, meeting_url,
	author_country_code, author_city_id, author_city_name, author_location_captured_at, visibility_password_hash,
	cancellation_reason, cancellation_source, cancelled_by_user_id, cancelled_at, started_at, completed_at, completion_reason, published_at,
	revision, created_at, updated_at
`

const qualifiedActivitySelectColumns = `
	a.id, a.host_user_id, a.source_activity_id,
	a.title, a.description,
	a.format, a.status, a.visibility, a.join_mode, a.moderation_status,
	a.moderation_risk_score, a.moderation_reason_codes, a.moderation_triggered_at, a.moderation_reviewed_at,
	a.category_slug, a.subcategory_slug, a.language_code, a.timezone,
	a.start_at, a.end_at, a.registration_deadline,
	a.capacity_type, a.min_participants, a.max_participants,
	a.price_type, a.price_amount, a.currency, a.price_locked_at,
	a.requires_profile_completion, a.requires_attendance_confirmation, a.allows_participant_invites, a.confirmation_deadline,
	a.country_code, a.city_id, a.city_name, a.address_text, a.latitude, a.longitude, a.map_url, a.meeting_url,
	a.author_country_code, a.author_city_id, a.author_city_name, a.author_location_captured_at, a.visibility_password_hash,
	a.cancellation_reason, a.cancellation_source, a.cancelled_by_user_id, a.cancelled_at, a.started_at, a.completed_at, a.completion_reason, a.published_at,
	a.revision, a.created_at, a.updated_at
`

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
			moderation_risk_score, moderation_reason_codes, moderation_triggered_at, moderation_reviewed_at,
			category_slug, subcategory_slug, language_code, timezone,
			start_at, end_at, registration_deadline,
			capacity_type, min_participants, max_participants,
			price_type, price_amount, currency, price_locked_at,
			requires_profile_completion, requires_attendance_confirmation, allows_participant_invites, confirmation_deadline,
			country_code, city_id, city_name, address_text, latitude, longitude, map_url, meeting_url,
			author_country_code, author_city_id, author_city_name, author_location_captured_at, visibility_password_hash,
			cancellation_reason, cancellation_source, cancelled_by_user_id, cancelled_at, started_at, completed_at, completion_reason, published_at,
			revision, created_at, updated_at
		) VALUES (
			$1, $2, $3,
			$4, $5,
			$6, $7, $8, $9, $10,
			$11, $12, $13, $14,
			$15, $16, $17, $18,
			$19, $20, $21,
			$22, $23, $24,
			$25, $26, $27, $28,
			$29, $30, $31, $32,
			$33, $34, $35, $36, $37, $38, $39, $40,
			$41, $42, $43, $44, $45,
			$46, $47, $48, $49, $50, $51, $52, $53,
			$54, $55, $56
		)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID, item.HostUserID, item.SourceActivityID,
		item.Title, item.Description,
		string(item.Format), string(item.Status), string(item.Visibility), string(item.JoinMode), string(item.ModerationStatus),
		item.ModerationRiskScore, nonNilStringSlice(item.ModerationReasonCodes), item.ModerationTriggeredAt, item.ModerationReviewedAt,
		item.CategorySlug, item.SubcategorySlug, item.LanguageCode, item.Timezone,
		item.StartAt, item.EndAt, item.RegistrationDeadline,
		string(item.CapacityType), item.MinParticipants, item.MaxParticipants,
		string(item.PriceType), item.PriceAmount, item.Currency, item.PriceLockedAt,
		item.RequiresProfileCompletion, item.RequiresAttendanceConfirmation, item.AllowsParticipantInvites, item.ConfirmationDeadline,
		item.CountryCode, item.CityID, item.CityName, item.AddressText, item.Latitude, item.Longitude, item.MapURL, item.MeetingURL,
		item.AuthorCountryCode, item.AuthorCityID, item.AuthorCityName, item.AuthorLocationCapturedAt, item.VisibilityPasswordHash,
		item.CancellationReason, optionalActivityCancellationSourceString(item.CancellationSource), item.CancelledByUserID, item.CancelledAt, item.StartedAt, item.CompletedAt, item.CompletionReason, item.PublishedAt,
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
			moderation_risk_score = $11,
			moderation_reason_codes = $12,
			moderation_triggered_at = $13,
			moderation_reviewed_at = $14,
			category_slug = $15,
			subcategory_slug = $16,
			language_code = $17,
			timezone = $18,
			start_at = $19,
			end_at = $20,
			registration_deadline = $21,
			capacity_type = $22,
			min_participants = $23,
			max_participants = $24,
			price_type = $25,
			price_amount = $26,
			currency = $27,
			price_locked_at = $28,
			requires_profile_completion = $29,
			requires_attendance_confirmation = $30,
			allows_participant_invites = $31,
			confirmation_deadline = $32,
			country_code = $33,
			city_id = $34,
			city_name = $35,
			address_text = $36,
			latitude = $37,
			longitude = $38,
			map_url = $39,
			meeting_url = $40,
			visibility_password_hash = $41,
			cancellation_reason = $42,
			cancellation_source = $43,
			cancelled_by_user_id = $44,
			cancelled_at = $45,
			started_at = $46,
			completed_at = $47,
			completion_reason = $48,
			published_at = $49,
			revision = $50,
			updated_at = $51
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
		item.ModerationRiskScore,
		nonNilStringSlice(item.ModerationReasonCodes),
		item.ModerationTriggeredAt,
		item.ModerationReviewedAt,
		item.CategorySlug,
		item.SubcategorySlug,
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
		item.AllowsParticipantInvites,
		item.ConfirmationDeadline,
		item.CountryCode,
		item.CityID,
		item.CityName,
		item.AddressText,
		item.Latitude,
		item.Longitude,
		item.MapURL,
		item.MeetingURL,
		item.VisibilityPasswordHash,
		item.CancellationReason,
		optionalActivityCancellationSourceString(item.CancellationSource),
		item.CancelledByUserID,
		item.CancelledAt,
		item.StartedAt,
		item.CompletedAt,
		item.CompletionReason,
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
	` + activitySelectColumns + `
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
	` + activitySelectColumns + `
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

	if len(filter.ModerationStatuses) > 0 {
		parts = append(parts, fmt.Sprintf(" AND moderation_status = ANY($%d)", argPos))
		args = append(args, filter.ModerationStatuses)
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

	if filter.SubcategorySlug != nil && strings.TrimSpace(*filter.SubcategorySlug) != "" {
		parts = append(parts, fmt.Sprintf(" AND subcategory_slug = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.SubcategorySlug))
		argPos++
	}

	if filter.CountryCode != nil && strings.TrimSpace(*filter.CountryCode) != "" {
		parts = append(parts, fmt.Sprintf(" AND country_code = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.CountryCode))
		argPos++
	}

	if filter.CityID != nil {
		parts = append(parts, fmt.Sprintf(" AND city_id = $%d", argPos))
		args = append(args, *filter.CityID)
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

	if len(filter.ModerationStatuses) > 0 {
		parts = append(parts, " ORDER BY moderation_risk_score DESC, moderation_triggered_at ASC NULLS LAST, created_at DESC")
	} else {
		parts = append(parts, " ORDER BY start_at ASC, created_at DESC")
	}
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

func (r *PGActivityRepository) ListActivitiesDueForRegistrationFinalization(
	ctx context.Context,
	before time.Time,
	limit int,
) ([]*model.Activity, error) {
	if limit <= 0 {
		limit = 100
	}

	query := `
		SELECT
	` + activitySelectColumns + `
		FROM activities
		WHERE status = ANY($1)
		  AND registration_deadline <= $2
		ORDER BY registration_deadline ASC
		LIMIT $3
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		[]string{
			string(enum.ActivityStatusPublished),
			string(enum.ActivityStatusEnrollmentOpen),
			string(enum.ActivityStatusFull),
			string(enum.ActivityStatusRegistrationClosed),
			string(enum.ActivityStatusConfirmationPending),
		},
		before.UTC(),
		limit,
	)
	if err != nil {
		return nil, fmt.Errorf("list activities due for registration finalization: %w", err)
	}
	defer rows.Close()

	result := make([]*model.Activity, 0, limit)
	for rows.Next() {
		item, scanErr := scanActivity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan activity due for registration finalization: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) ListActivitiesDueForStart(
	ctx context.Context,
	before time.Time,
	limit int,
) ([]*model.Activity, error) {
	if limit <= 0 {
		limit = 100
	}

	query := `
		SELECT
	` + activitySelectColumns + `
		FROM activities
		WHERE status = ANY($1)
		  AND start_at <= $2
		  AND end_at > $2
		ORDER BY start_at ASC
		LIMIT $3
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		[]string{
			string(enum.ActivityStatusPublished),
			string(enum.ActivityStatusEnrollmentOpen),
			string(enum.ActivityStatusFull),
			string(enum.ActivityStatusRegistrationClosed),
			string(enum.ActivityStatusConfirmed),
		},
		before.UTC(),
		limit,
	)
	if err != nil {
		return nil, fmt.Errorf("list activities due for start: %w", err)
	}
	defer rows.Close()

	result := make([]*model.Activity, 0, limit)
	for rows.Next() {
		item, scanErr := scanActivity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan activity due for start: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) ListActivitiesDueForCompletion(
	ctx context.Context,
	before time.Time,
	limit int,
) ([]*model.Activity, error) {
	if limit <= 0 {
		limit = 100
	}

	query := `
		SELECT
	` + activitySelectColumns + `
		FROM activities
		WHERE status = ANY($1)
		  AND end_at <= $2
		ORDER BY end_at ASC
		LIMIT $3
	`

	rows, err := r.pool.Query(
		ctx,
		query,
		[]string{
			string(enum.ActivityStatusPublished),
			string(enum.ActivityStatusEnrollmentOpen),
			string(enum.ActivityStatusFull),
			string(enum.ActivityStatusRegistrationClosed),
			string(enum.ActivityStatusConfirmed),
			string(enum.ActivityStatusStarted),
		},
		before.UTC(),
		limit,
	)
	if err != nil {
		return nil, fmt.Errorf("list activities due for completion: %w", err)
	}
	defer rows.Close()

	result := make([]*model.Activity, 0, limit)
	for rows.Next() {
		item, scanErr := scanActivity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan activity due for completion: %w", scanErr)
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
			tag = model.NormalizeActivityTagSlug(tag)
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

func (r *PGActivityRepository) CreateAttendanceQRIssue(ctx context.Context, item *model.AttendanceQRIssue) error {
	const query = `
		INSERT INTO activity_attendance_qr_issues (
			jti, activity_id, host_user_id, issued_at, expires_at, usable_until, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	_, err := r.pool.Exec(
		ctx,
		query,
		item.JTI,
		item.ActivityID,
		item.HostUserID,
		item.IssuedAt,
		item.ExpiresAt,
		item.UsableUntil,
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert attendance qr issue: %w", err)
	}

	return nil
}

func (r *PGActivityRepository) GetParticipantByActivityAndUser(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
	const query = `
		SELECT
			id, activity_id, user_id, status, joined_at, approved_at, waitlisted_at,
			payment_due_at, payment_transaction_id, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
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
			payment_due_at, payment_transaction_id, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
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
			payment_due_at, payment_transaction_id, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
			cancelled_at, cancelled_by_user_id, cancel_reason, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10, $11, $12, $13,
			$14, $15, $16, $17, $18
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
		item.PaymentTransactionID,
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
			payment_transaction_id = $7,
			paid_at = $8,
			attendance_confirmed_at = $9,
			checked_in_at = $10,
			attended_at = $11,
			cancelled_at = $12,
			cancelled_by_user_id = $13,
			cancel_reason = $14,
			updated_at = $15
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
		item.PaymentTransactionID,
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
	` + activitySelectColumns + `
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
			payment_due_at, payment_transaction_id, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
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

func (r *PGActivityTxRepository) GetAttendanceQRIssueByJTIForUpdate(
	ctx context.Context,
	jti uuid.UUID,
) (*model.AttendanceQRIssue, error) {
	const query = `
		SELECT
			jti, activity_id, host_user_id, issued_at, expires_at, usable_until, created_at
		FROM activity_attendance_qr_issues
		WHERE jti = $1
		LIMIT 1
		FOR UPDATE
	`

	row := r.tx.QueryRow(ctx, query, jti)
	item, err := scanAttendanceQRIssue(row)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get attendance qr issue for update: %w", err)
	}

	return item, nil
}

func (r *PGActivityTxRepository) GetAttendanceSyncAttemptByScanIDForUpdate(
	ctx context.Context,
	scanID uuid.UUID,
) (*model.AttendanceSyncAttempt, error) {
	const query = `
		SELECT
			scan_id, activity_id, participant_user_id, qr_jti, installation_id,
			scanned_at_device, result_status, failure_code, failure_message, checked_in_at,
			created_at, updated_at
		FROM activity_attendance_sync_attempts
		WHERE scan_id = $1
		LIMIT 1
		FOR UPDATE
	`

	row := r.tx.QueryRow(ctx, query, scanID)
	item, err := scanAttendanceSyncAttempt(row)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get attendance sync attempt for update: %w", err)
	}

	return item, nil
}

func (r *PGActivityTxRepository) HasActiveOverlappingJoinedActivity(
	ctx context.Context,
	userID uuid.UUID,
	excludeActivityID uuid.UUID,
	startAt time.Time,
	endAt time.Time,
) (bool, error) {
	const query = `
		SELECT 1
		FROM activity_participants ap
		INNER JOIN activities a ON a.id = ap.activity_id
		WHERE ap.user_id = $1
		  AND ap.activity_id <> $2
		  AND ap.status IN (
		    'REQUESTED',
		    'APPROVED',
		    'WAITLISTED',
		    'PENDING_PAYMENT',
		    'CONFIRMED',
		    'CHECKED_IN'
		  )
		  AND a.status <> 'CANCELLED'
		  AND a.start_at < $4
		  AND a.end_at > $3
		LIMIT 1
		FOR UPDATE OF ap, a
	`

	var matched int
	err := r.tx.QueryRow(ctx, query, userID, excludeActivityID, startAt, endAt).Scan(&matched)
	if err != nil {
		if err == pgx.ErrNoRows {
			return false, nil
		}
		return false, fmt.Errorf("check overlapping joined activities: %w", err)
	}

	return matched == 1, nil
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

func (r *PGActivityTxRepository) ListParticipantsByActivityIDForUpdate(
	ctx context.Context,
	activityID uuid.UUID,
) ([]*model.ActivityParticipant, error) {
	const query = `
		SELECT
			id, activity_id, user_id, status, joined_at, approved_at, waitlisted_at,
			payment_due_at, payment_transaction_id, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
			cancelled_at, cancelled_by_user_id, cancel_reason, created_at, updated_at
		FROM activity_participants
		WHERE activity_id = $1
		ORDER BY created_at ASC
		FOR UPDATE
	`

	rows, err := r.tx.Query(ctx, query, activityID)
	if err != nil {
		return nil, fmt.Errorf("list participants by activity id for update: %w", err)
	}
	defer rows.Close()

	result := make([]*model.ActivityParticipant, 0)
	for rows.Next() {
		item, scanErr := scanParticipant(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan participant for update: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityTxRepository) CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	const query = `
		INSERT INTO activity_participants (
			id, activity_id, user_id, status, joined_at, approved_at, waitlisted_at,
			payment_due_at, payment_transaction_id, paid_at, attendance_confirmed_at, checked_in_at, attended_at,
			cancelled_at, cancelled_by_user_id, cancel_reason, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10, $11, $12, $13,
			$14, $15, $16, $17, $18
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
		item.PaymentTransactionID,
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
			payment_transaction_id = $7,
			paid_at = $8,
			attendance_confirmed_at = $9,
			checked_in_at = $10,
			attended_at = $11,
			cancelled_at = $12,
			cancelled_by_user_id = $13,
			cancel_reason = $14,
			updated_at = $15
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
		item.PaymentTransactionID,
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

func (r *PGActivityTxRepository) CreateAttendanceSyncAttempt(
	ctx context.Context,
	item *model.AttendanceSyncAttempt,
) error {
	const query = `
		INSERT INTO activity_attendance_sync_attempts (
			scan_id, activity_id, participant_user_id, qr_jti, installation_id,
			scanned_at_device, result_status, failure_code, failure_message, checked_in_at,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5,
			$6, $7, $8, $9, $10,
			$11, $12
		)
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ScanID,
		item.ActivityID,
		item.ParticipantUserID,
		item.QRJTI,
		item.InstallationID,
		item.ScannedAtDevice,
		item.ResultStatus,
		item.FailureCode,
		item.FailureMessage,
		item.CheckedInAt,
		item.CreatedAt,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert attendance sync attempt in tx: %w", err)
	}

	return nil
}

func (r *PGActivityTxRepository) UpdateAttendanceSyncAttempt(
	ctx context.Context,
	item *model.AttendanceSyncAttempt,
) error {
	const query = `
		UPDATE activity_attendance_sync_attempts
		SET
			installation_id = $2,
			scanned_at_device = $3,
			result_status = $4,
			failure_code = $5,
			failure_message = $6,
			checked_in_at = $7,
			updated_at = $8
		WHERE scan_id = $1
	`

	_, err := r.tx.Exec(
		ctx,
		query,
		item.ScanID,
		item.InstallationID,
		item.ScannedAtDevice,
		item.ResultStatus,
		item.FailureCode,
		item.FailureMessage,
		item.CheckedInAt,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update attendance sync attempt in tx: %w", err)
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
			moderation_risk_score = $11,
			moderation_reason_codes = $12,
			moderation_triggered_at = $13,
			moderation_reviewed_at = $14,
			category_slug = $15,
			language_code = $16,
			timezone = $17,
			start_at = $18,
			end_at = $19,
			registration_deadline = $20,
			capacity_type = $21,
			min_participants = $22,
			max_participants = $23,
			price_type = $24,
			price_amount = $25,
			currency = $26,
			price_locked_at = $27,
			requires_profile_completion = $28,
			requires_attendance_confirmation = $29,
			allows_participant_invites = $30,
			confirmation_deadline = $31,
			country_code = $32,
			city_id = $33,
			city_name = $34,
			address_text = $35,
			latitude = $36,
			longitude = $37,
			map_url = $38,
			meeting_url = $39,
			visibility_password_hash = $40,
			cancellation_reason = $41,
			cancellation_source = $42,
			cancelled_by_user_id = $43,
			cancelled_at = $44,
			started_at = $45,
			completed_at = $46,
			completion_reason = $47,
			published_at = $48,
			revision = $49,
			updated_at = $50
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
		item.ModerationRiskScore,
		nonNilStringSlice(item.ModerationReasonCodes),
		item.ModerationTriggeredAt,
		item.ModerationReviewedAt,
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
		item.AllowsParticipantInvites,
		item.ConfirmationDeadline,
		item.CountryCode,
		item.CityID,
		item.CityName,
		item.AddressText,
		item.Latitude,
		item.Longitude,
		item.MapURL,
		item.MeetingURL,
		item.VisibilityPasswordHash,
		item.CancellationReason,
		optionalActivityCancellationSourceString(item.CancellationSource),
		item.CancelledByUserID,
		item.CancelledAt,
		item.StartedAt,
		item.CompletedAt,
		item.CompletionReason,
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
	` + activitySelectColumns + `
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
	` + qualifiedActivitySelectColumns + `
		FROM activities a
		INNER JOIN activity_participants ap ON ap.activity_id = a.id
		WHERE ap.user_id = $1
		  AND a.host_user_id <> $1
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

func (r *PGActivityRepository) ListPublicProfileHostedActivities(
	ctx context.Context,
	filter port.PublicProfileActivityFilter,
) ([]*model.Activity, error) {
	query := `
		SELECT
	` + activitySelectColumns + `
		FROM activities
		WHERE host_user_id = $1
		  AND status = $4
		  AND visibility = $5
	`
	limit := filter.Limit
	if limit <= 0 {
		limit = 20
	}
	offset := filter.Offset
	if offset < 0 {
		offset = 0
	}
	args := []any{
		filter.UserID,
		limit,
		offset,
		string(enum.ActivityStatusCompleted),
		string(enum.ActivityVisibilityPublic),
	}
	where, args := appendPublicProfileActivityFilters("", filter, args)
	query += where
	query += " ORDER BY " + publicProfileActivityOrderBy("", filter.Sort)
	query += " LIMIT $2 OFFSET $3"

	rows, err := r.pool.Query(
		ctx,
		query,
		args...,
	)
	if err != nil {
		return nil, fmt.Errorf("list public profile hosted activities: %w", err)
	}
	defer rows.Close()

	result := make([]*model.Activity, 0)
	for rows.Next() {
		item, scanErr := scanActivity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan public profile hosted activity: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func (r *PGActivityRepository) ListPublicProfileJoinedActivities(
	ctx context.Context,
	filter port.PublicProfileActivityFilter,
) ([]*model.Activity, error) {
	query := `
		SELECT DISTINCT
	` + qualifiedActivitySelectColumns + `
		FROM activities a
		INNER JOIN activity_participants ap ON ap.activity_id = a.id
		WHERE ap.user_id = $1
		  AND a.host_user_id <> $1
		  AND a.status = $4
		  AND a.visibility = $5
		  AND ap.status = ANY($6)
	`

	participantStatuses := []string{
		string(enum.ParticipantStatusApproved),
		string(enum.ParticipantStatusConfirmed),
		string(enum.ParticipantStatusCheckedIn),
		string(enum.ParticipantStatusAttended),
	}
	limit := filter.Limit
	if limit <= 0 {
		limit = 20
	}
	offset := filter.Offset
	if offset < 0 {
		offset = 0
	}
	args := []any{
		filter.UserID,
		limit,
		offset,
		string(enum.ActivityStatusCompleted),
		string(enum.ActivityVisibilityPublic),
		participantStatuses,
	}
	where, args := appendPublicProfileActivityFilters("a", filter, args)
	query += where
	query += " ORDER BY " + publicProfileActivityOrderBy("a", filter.Sort)
	query += " LIMIT $2 OFFSET $3"

	rows, err := r.pool.Query(
		ctx,
		query,
		args...,
	)
	if err != nil {
		return nil, fmt.Errorf("list public profile joined activities: %w", err)
	}
	defer rows.Close()

	result := make([]*model.Activity, 0)
	for rows.Next() {
		item, scanErr := scanActivity(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan public profile joined activity: %w", scanErr)
		}
		result = append(result, item)
	}

	return result, rows.Err()
}

func appendPublicProfileActivityFilters(alias string, filter port.PublicProfileActivityFilter, args []any) (string, []any) {
	var builder strings.Builder
	column := func(name string) string {
		if alias == "" {
			return name
		}
		return alias + "." + name
	}

	if query := strings.TrimSpace(filter.SearchQuery); query != "" {
		args = append(args, "%"+strings.ToLower(query)+"%")
		placeholder := len(args)
		fmt.Fprintf(
			&builder,
			" AND (LOWER(%s) LIKE $%d OR LOWER(%s) LIKE $%d OR LOWER(COALESCE(%s, '')) LIKE $%d OR LOWER(COALESCE(%s, '')) LIKE $%d)",
			column("title"),
			placeholder,
			column("description"),
			placeholder,
			column("city_name"),
			placeholder,
			column("address_text"),
			placeholder,
		)
	}

	if categorySlug := strings.TrimSpace(filter.CategorySlug); categorySlug != "" {
		args = append(args, categorySlug)
		fmt.Fprintf(
			&builder,
			" AND LOWER(%s) = LOWER($%d)",
			column("category_slug"),
			len(args),
		)
	}

	if format := strings.TrimSpace(filter.Format); format != "" {
		args = append(args, strings.ToUpper(format))
		fmt.Fprintf(&builder, " AND %s = $%d", column("format"), len(args))
	}

	if priceType := strings.TrimSpace(filter.PriceType); priceType != "" {
		args = append(args, strings.ToUpper(priceType))
		fmt.Fprintf(&builder, " AND %s = $%d", column("price_type"), len(args))
	}

	return builder.String(), args
}

func publicProfileActivityOrderBy(alias string, sort string) string {
	column := func(name string) string {
		if alias == "" {
			return name
		}
		return alias + "." + name
	}

	switch strings.ToLower(strings.TrimSpace(sort)) {
	case "date_asc":
		return fmt.Sprintf(
			"%s ASC NULLS LAST, %s ASC, %s ASC, %s ASC",
			column("completed_at"),
			column("end_at"),
			column("start_at"),
			column("created_at"),
		)
	case "price_asc":
		return fmt.Sprintf(
			"%s ASC NULLS FIRST, %s DESC NULLS LAST, %s DESC, %s DESC",
			column("price_amount"),
			column("completed_at"),
			column("end_at"),
			column("created_at"),
		)
	case "price_desc":
		return fmt.Sprintf(
			"%s DESC NULLS LAST, %s DESC NULLS LAST, %s DESC, %s DESC",
			column("price_amount"),
			column("completed_at"),
			column("end_at"),
			column("created_at"),
		)
	default:
		return fmt.Sprintf(
			"%s DESC NULLS LAST, %s DESC, %s DESC, %s DESC",
			column("completed_at"),
			column("end_at"),
			column("start_at"),
			column("created_at"),
		)
	}
}

func (r *PGActivityRepository) CountActivityCompletionStatsByUserID(
	ctx context.Context,
	userID uuid.UUID,
) (port.ActivityCompletionStats, error) {
	const query = `
		WITH hosted AS (
			SELECT COUNT(*)::int AS count
			FROM activities
			WHERE host_user_id = $1
			  AND status = $2
		),
		joined AS (
			SELECT COUNT(DISTINCT a.id)::int AS count
			FROM activities a
			INNER JOIN activity_participants ap ON ap.activity_id = a.id
			WHERE ap.user_id = $1
			  AND a.host_user_id <> $1
			  AND a.status = $2
			  AND ap.status = ANY($3)
		)
		SELECT hosted.count, joined.count
		FROM hosted, joined
	`

	participantStatuses := []string{
		string(enum.ParticipantStatusApproved),
		string(enum.ParticipantStatusConfirmed),
		string(enum.ParticipantStatusCheckedIn),
		string(enum.ParticipantStatusAttended),
	}

	var stats port.ActivityCompletionStats
	err := r.pool.QueryRow(
		ctx,
		query,
		userID,
		string(enum.ActivityStatusCompleted),
		participantStatuses,
	).Scan(&stats.HostedCompleted, &stats.JoinedCompleted)
	if err != nil {
		return port.ActivityCompletionStats{}, fmt.Errorf("count activity completion stats by user id: %w", err)
	}

	return stats, nil
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

		formatRaw             string
		statusRaw             string
		visibilityRaw         string
		joinModeRaw           string
		moderationStatusRaw   string
		capacityTypeRaw       string
		priceTypeRaw          string
		cancellationSourceRaw *string
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

		&item.ModerationRiskScore,
		&item.ModerationReasonCodes,
		&item.ModerationTriggeredAt,
		&item.ModerationReviewedAt,

		&item.CategorySlug,
		&item.SubcategorySlug,
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
		&item.AllowsParticipantInvites,
		&item.ConfirmationDeadline,

		&item.CountryCode,
		&item.CityID,
		&item.CityName,
		&item.AddressText,
		&item.Latitude,
		&item.Longitude,
		&item.MapURL,
		&item.MeetingURL,
		&item.AuthorCountryCode,
		&item.AuthorCityID,
		&item.AuthorCityName,
		&item.AuthorLocationCapturedAt,
		&item.VisibilityPasswordHash,

		&item.CancellationReason,
		&cancellationSourceRaw,
		&item.CancelledByUserID,
		&item.CancelledAt,
		&item.StartedAt,
		&item.CompletedAt,
		&item.CompletionReason,
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
	if cancellationSourceRaw != nil {
		source := enum.ActivityCancellationSource(*cancellationSourceRaw)
		item.CancellationSource = &source
	}

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
		&item.PaymentTransactionID,
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

type attendanceQRIssueScanner interface {
	Scan(dest ...any) error
}

func scanAttendanceQRIssue(row attendanceQRIssueScanner) (*model.AttendanceQRIssue, error) {
	var item model.AttendanceQRIssue

	err := row.Scan(
		&item.JTI,
		&item.ActivityID,
		&item.HostUserID,
		&item.IssuedAt,
		&item.ExpiresAt,
		&item.UsableUntil,
		&item.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &item, nil
}

type attendanceSyncAttemptScanner interface {
	Scan(dest ...any) error
}

func scanAttendanceSyncAttempt(
	row attendanceSyncAttemptScanner,
) (*model.AttendanceSyncAttempt, error) {
	var item model.AttendanceSyncAttempt

	err := row.Scan(
		&item.ScanID,
		&item.ActivityID,
		&item.ParticipantUserID,
		&item.QRJTI,
		&item.InstallationID,
		&item.ScannedAtDevice,
		&item.ResultStatus,
		&item.FailureCode,
		&item.FailureMessage,
		&item.CheckedInAt,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

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

func optionalActivityCancellationSourceString(source *enum.ActivityCancellationSource) *string {
	if source == nil {
		return nil
	}
	value := string(*source)
	return &value
}

func nonNilStringSlice(values []string) []string {
	if values == nil {
		return []string{}
	}
	return values
}
