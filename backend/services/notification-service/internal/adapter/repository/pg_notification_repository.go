package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/notification-service/internal/app"
	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

type PGNotificationRepository struct {
	pool      *pgxpool.Pool
	protector *app.TokenProtector
}

func NewPGNotificationRepository(pool *pgxpool.Pool, protector *app.TokenProtector) *PGNotificationRepository {
	return &PGNotificationRepository{
		pool:      pool,
		protector: protector,
	}
}

func (r *PGNotificationRepository) UpsertDeviceToken(
	ctx context.Context,
	device model.DeviceToken,
) (*model.DeviceToken, error) {
	tokenHash := r.protector.Hash(device.Token)
	tokenCiphertext, err := r.protector.Encrypt(device.Token)
	if err != nil {
		return nil, err
	}

	row := r.pool.QueryRow(ctx, `
		INSERT INTO notification_device_tokens (
			id, user_id, platform, provider, environment, app_bundle_id,
			app_version, device_model, manufacturer, locale, timezone,
			session_id, device_installation_id,
			token_hash, token_ciphertext, enabled, created_at, updated_at, last_seen_at
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,true,$16,$16,$16)
		ON CONFLICT (provider, environment, token_hash)
		DO UPDATE SET
			user_id = EXCLUDED.user_id,
			platform = EXCLUDED.platform,
			app_bundle_id = EXCLUDED.app_bundle_id,
			app_version = EXCLUDED.app_version,
			device_model = EXCLUDED.device_model,
			manufacturer = EXCLUDED.manufacturer,
			locale = EXCLUDED.locale,
			timezone = EXCLUDED.timezone,
			session_id = EXCLUDED.session_id,
			device_installation_id = EXCLUDED.device_installation_id,
			token_ciphertext = EXCLUDED.token_ciphertext,
			enabled = true,
			updated_at = EXCLUDED.updated_at,
			last_seen_at = EXCLUDED.last_seen_at,
			invalidated_at = NULL,
			invalidation_reason = ''
		RETURNING id, user_id, platform, provider, environment, app_bundle_id,
			app_version, device_model, manufacturer, locale, timezone,
			session_id, device_installation_id, token_hash,
			enabled, created_at, updated_at, last_seen_at, invalidated_at, invalidation_reason
	`, device.ID, device.UserID, device.Platform, device.Provider, device.Environment,
		device.AppBundleID, device.AppVersion, device.DeviceModel, device.Manufacturer,
		device.Locale, device.Timezone, device.SessionID, device.DeviceInstallationID,
		tokenHash, tokenCiphertext, device.UpdatedAt)

	return scanDevice(row, nil)
}

func (r *PGNotificationRepository) DeactivateDeviceToken(
	ctx context.Context,
	userID uuid.UUID,
	deviceID uuid.UUID,
	reason string,
) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE notification_device_tokens
		SET enabled = false,
			invalidated_at = NOW(),
			invalidation_reason = $3,
			updated_at = NOW()
		WHERE id = $1 AND user_id = $2
	`, deviceID, userID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return model.ErrNotFound
	}
	return nil
}

func (r *PGNotificationRepository) DeactivateDeviceTokensBySession(
	ctx context.Context,
	userID uuid.UUID,
	sessionID string,
	reason string,
) (int, error) {
	tag, err := r.pool.Exec(ctx, `
		UPDATE notification_device_tokens
		SET enabled = false,
			invalidated_at = NOW(),
			invalidation_reason = $3,
			updated_at = NOW()
		WHERE user_id = $1
			AND (session_id = $2 OR session_id = '')
			AND enabled = true
			AND invalidated_at IS NULL
	`, userID, sessionID, reason)
	if err != nil {
		return 0, err
	}
	return int(tag.RowsAffected()), nil
}

func (r *PGNotificationRepository) CreateNotificationRequest(
	ctx context.Context,
	request model.NotificationRequest,
) (*model.NotificationRequest, bool, error) {
	data, err := json.Marshal(request.Payload.Data)
	if err != nil {
		return nil, false, fmt.Errorf("marshal notification data: %w", err)
	}

	row := r.pool.QueryRow(ctx, `
		INSERT INTO notification_requests (
			id, idempotency_key, source_service, recipient_user_ids,
			category, priority, title, body, image_url, deep_link, data,
			collapse_key, ttl_seconds, status, scheduled_at, created_at
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)
		ON CONFLICT (source_service, idempotency_key) DO NOTHING
		RETURNING id
	`, request.ID, request.IdempotencyKey, request.SourceService, request.RecipientUserIDs,
		request.Category, request.Priority, request.Payload.Title, request.Payload.Body,
		request.Payload.ImageURL, request.Payload.DeepLink, data, request.Payload.CollapseKey,
		int64(request.Payload.TTL.Seconds()), request.Status, request.ScheduledAt, request.CreatedAt)

	var insertedID uuid.UUID
	if err = row.Scan(&insertedID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			existing, getErr := r.getRequestByIdempotencyKey(ctx, request.SourceService, request.IdempotencyKey)
			return existing, false, getErr
		}
		return nil, false, err
	}
	created, err := r.GetNotificationRequest(ctx, insertedID)
	return created, true, err
}

func (r *PGNotificationRepository) GetNotificationRequest(
	ctx context.Context,
	requestID uuid.UUID,
) (*model.NotificationRequest, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, idempotency_key, source_service, recipient_user_ids,
			category, priority, title, body, image_url, deep_link, data,
			collapse_key, ttl_seconds, status, scheduled_at, created_at
		FROM notification_requests
		WHERE id = $1
	`, requestID)
	return scanRequest(row)
}

func (r *PGNotificationRepository) getRequestByIdempotencyKey(
	ctx context.Context,
	sourceService string,
	idempotencyKey string,
) (*model.NotificationRequest, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, idempotency_key, source_service, recipient_user_ids,
			category, priority, title, body, image_url, deep_link, data,
			collapse_key, ttl_seconds, status, scheduled_at, created_at
		FROM notification_requests
		WHERE source_service = $1 AND idempotency_key = $2
	`, sourceService, idempotencyKey)
	return scanRequest(row)
}

func (r *PGNotificationRepository) ListActiveDeviceTokens(
	ctx context.Context,
	userIDs []uuid.UUID,
) ([]*model.DeviceToken, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, platform, provider, environment, app_bundle_id,
			app_version, device_model, manufacturer, locale, timezone,
			session_id, device_installation_id, token_hash,
			token_ciphertext, enabled, created_at, updated_at, last_seen_at,
			invalidated_at, invalidation_reason
		FROM notification_device_tokens
		WHERE enabled = true
			AND invalidated_at IS NULL
			AND user_id = ANY($1)
	`, userIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	devices := make([]*model.DeviceToken, 0)
	for rows.Next() {
		var tokenCiphertext string
		device, err := scanDevice(rows, &tokenCiphertext)
		if err != nil {
			return nil, err
		}
		token, err := r.protector.Decrypt(tokenCiphertext)
		if err != nil {
			return nil, err
		}
		device.Token = token
		devices = append(devices, device)
	}
	return devices, rows.Err()
}

func (r *PGNotificationRepository) CreateDelivery(
	ctx context.Context,
	delivery model.Delivery,
) (*model.Delivery, bool, error) {
	row := r.pool.QueryRow(ctx, `
		INSERT INTO notification_deliveries (
			id, request_id, device_token_id, user_id, platform, provider,
			environment, priority, status, attempt_count, max_attempts,
			next_attempt_at, created_at, updated_at
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,NOW(),NOW())
		ON CONFLICT (request_id, device_token_id) DO NOTHING
		RETURNING id
	`, delivery.ID, delivery.RequestID, delivery.DeviceTokenID, delivery.UserID,
		delivery.Platform, delivery.Provider, delivery.Environment, delivery.Priority,
		delivery.Status, delivery.AttemptCount, delivery.MaxAttempts, delivery.NextAttemptAt)

	var insertedID uuid.UUID
	if err := row.Scan(&insertedID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			existing, getErr := r.getDeliveryByRequestAndDevice(ctx, delivery.RequestID, delivery.DeviceTokenID)
			return existing, false, getErr
		}
		return nil, false, err
	}
	created, err := r.GetDelivery(ctx, insertedID)
	return created, true, err
}

func (r *PGNotificationRepository) GetDelivery(ctx context.Context, deliveryID uuid.UUID) (*model.Delivery, error) {
	row := r.pool.QueryRow(ctx, deliverySelectSQL()+` WHERE d.id = $1`, deliveryID)
	return r.scanDelivery(row)
}

func (r *PGNotificationRepository) getDeliveryByRequestAndDevice(
	ctx context.Context,
	requestID uuid.UUID,
	deviceTokenID uuid.UUID,
) (*model.Delivery, error) {
	row := r.pool.QueryRow(ctx, deliverySelectSQL()+` WHERE d.request_id = $1 AND d.device_token_id = $2`, requestID, deviceTokenID)
	return r.scanDelivery(row)
}

func (r *PGNotificationRepository) MarkDeliveryResult(
	ctx context.Context,
	deliveryID uuid.UUID,
	update app.DeliveryResultUpdate,
) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(ctx, `
		UPDATE notification_deliveries
		SET status = $2,
			attempt_count = $3,
			next_attempt_at = NULLIF($4, '0001-01-01T00:00:00Z'::timestamptz),
			provider_message_id = $5,
			last_error_code = $6,
			last_error = $7,
			updated_at = NOW()
		WHERE id = $1
	`, deliveryID, update.Status, update.AttemptCount, update.NextAttemptAt,
		update.ProviderMessageID, update.ErrorCode, update.ErrorMessage)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return model.ErrNotFound
	}

	if _, err = tx.Exec(ctx, `
		INSERT INTO notification_delivery_attempts (
			delivery_id, provider, status, provider_message_id,
			error_code, error_message, attempted_at
		)
		SELECT id, provider, $2, $3, $4, $5, NOW()
		FROM notification_deliveries
		WHERE id = $1
	`, deliveryID, update.Status, update.ProviderMessageID, update.ErrorCode, update.ErrorMessage); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *PGNotificationRepository) DeactivateDeviceTokenByID(
	ctx context.Context,
	deviceID uuid.UUID,
	reason string,
) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE notification_device_tokens
		SET enabled = false,
			invalidated_at = NOW(),
			invalidation_reason = $2,
			updated_at = NOW()
		WHERE id = $1
	`, deviceID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return model.ErrNotFound
	}
	return nil
}

func (r *PGNotificationRepository) MarkRequestFanoutCompleted(
	ctx context.Context,
	requestID uuid.UUID,
	totalDeliveries int,
) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE notification_requests
		SET status = 'fanout_completed',
			total_deliveries = $2,
			fanout_completed_at = NOW()
		WHERE id = $1
	`, requestID, totalDeliveries)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return model.ErrNotFound
	}
	return nil
}

func (r *PGNotificationRepository) ListDueDeliveries(
	ctx context.Context,
	now time.Time,
	limit int,
) ([]model.Delivery, error) {
	if limit <= 0 {
		limit = 100
	}
	rows, err := r.pool.Query(ctx, `
		WITH due AS (
			SELECT id
			FROM notification_deliveries
			WHERE status IN ('pending', 'retry_scheduled')
				AND next_attempt_at <= $1
			ORDER BY next_attempt_at ASC, created_at ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		UPDATE notification_deliveries d
		SET next_attempt_at = $1 + INTERVAL '30 seconds',
			updated_at = NOW()
		FROM due
		WHERE d.id = due.id
		RETURNING d.id, d.provider
	`, now, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	deliveries := make([]model.Delivery, 0, limit)
	for rows.Next() {
		var delivery model.Delivery
		if err := rows.Scan(&delivery.ID, &delivery.Provider); err != nil {
			return nil, err
		}
		deliveries = append(deliveries, delivery)
	}
	return deliveries, rows.Err()
}

func (r *PGNotificationRepository) ListUserNotificationCategorySummaries(
	ctx context.Context,
	userID uuid.UUID,
	limit int,
) ([]model.NotificationCategorySummary, error) {
	rows, err := r.pool.Query(ctx, `
		WITH user_requests AS (
			SELECT
				r.id,
				COALESCE(NULLIF(BTRIM(r.category), ''), 'general') AS category,
				r.priority,
				r.title,
				r.body,
				r.image_url,
				r.deep_link,
				r.data,
				r.created_at,
				ur.read_at
			FROM notification_requests r
			LEFT JOIN notification_user_reads ur
				ON ur.request_id = r.id AND ur.user_id = $1
			WHERE r.recipient_user_ids @> ARRAY[$1]::uuid[]
				AND r.scheduled_at <= NOW()
		),
		ranked AS (
			SELECT
				*,
				ROW_NUMBER() OVER (PARTITION BY category ORDER BY created_at DESC, id DESC) AS rn,
				COUNT(*) FILTER (WHERE read_at IS NULL) OVER (PARTITION BY category) AS unread_count,
				COUNT(*) OVER (PARTITION BY category) AS total_count
			FROM user_requests
		)
		SELECT
			id,
			category,
			priority,
			title,
			body,
			image_url,
			deep_link,
			data,
			created_at,
			read_at,
			unread_count,
			total_count
		FROM ranked
		WHERE rn = 1
		ORDER BY created_at DESC, id DESC
		LIMIT $2
	`, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	summaries := make([]model.NotificationCategorySummary, 0, limit)
	for rows.Next() {
		notification, unreadCount, totalCount, err := scanCategorySummary(rows)
		if err != nil {
			return nil, err
		}
		summaries = append(summaries, model.NotificationCategorySummary{
			Category:    notification.Category,
			Latest:      notification,
			UnreadCount: unreadCount,
			TotalCount:  totalCount,
		})
	}
	return summaries, rows.Err()
}

func (r *PGNotificationRepository) ListUserNotifications(
	ctx context.Context,
	userID uuid.UUID,
	category string,
	limit int,
	offset int,
) ([]model.UserNotification, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			r.id,
			COALESCE(NULLIF(BTRIM(r.category), ''), 'general') AS category,
			r.priority,
			r.title,
			r.body,
			r.image_url,
			r.deep_link,
			r.data,
			r.created_at,
			ur.read_at
		FROM notification_requests r
		LEFT JOIN notification_user_reads ur
			ON ur.request_id = r.id AND ur.user_id = $1
		WHERE r.recipient_user_ids @> ARRAY[$1]::uuid[]
			AND COALESCE(NULLIF(BTRIM(r.category), ''), 'general') = $2
			AND r.scheduled_at <= NOW()
		ORDER BY r.created_at DESC, r.id DESC
		LIMIT $3 OFFSET $4
	`, userID, category, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	notifications := make([]model.UserNotification, 0, limit)
	for rows.Next() {
		notification, err := scanUserNotification(rows)
		if err != nil {
			return nil, err
		}
		notifications = append(notifications, notification)
	}
	return notifications, rows.Err()
}

func (r *PGNotificationRepository) MarkUserNotificationsRead(
	ctx context.Context,
	userID uuid.UUID,
	category string,
) (int, error) {
	tag, err := r.pool.Exec(ctx, `
		WITH target_requests AS (
			SELECT r.id
			FROM notification_requests r
			WHERE r.recipient_user_ids @> ARRAY[$1]::uuid[]
				AND COALESCE(NULLIF(BTRIM(r.category), ''), 'general') = $2
				AND r.scheduled_at <= NOW()
		)
		INSERT INTO notification_user_reads (user_id, request_id, read_at)
		SELECT $1, id, NOW()
		FROM target_requests
		ON CONFLICT (user_id, request_id) DO NOTHING
	`, userID, category)
	if err != nil {
		return 0, err
	}
	return int(tag.RowsAffected()), nil
}

func (r *PGNotificationRepository) MarkUserNotificationRead(
	ctx context.Context,
	userID uuid.UUID,
	notificationID uuid.UUID,
) (int, error) {
	tag, err := r.pool.Exec(ctx, `
		INSERT INTO notification_user_reads (user_id, request_id, read_at)
		SELECT $1, r.id, NOW()
		FROM notification_requests r
		WHERE r.id = $2
			AND r.recipient_user_ids @> ARRAY[$1]::uuid[]
			AND r.scheduled_at <= NOW()
		ON CONFLICT (user_id, request_id) DO NOTHING
	`, userID, notificationID)
	if err != nil {
		return 0, err
	}
	return int(tag.RowsAffected()), nil
}

func (r *PGNotificationRepository) GetNotificationPreferences(
	ctx context.Context,
	userID uuid.UUID,
) (*model.NotificationPreferences, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT
			user_id,
			push_enabled,
			activity_enabled,
			excursion_enabled,
			chat_enabled,
			marketing_enabled,
			quiet_hours_enabled,
			quiet_hours_start_minutes,
			quiet_hours_end_minutes,
			timezone,
			created_at,
			updated_at
		FROM notification_preferences
		WHERE user_id = $1
	`, userID)
	preferences, err := scanNotificationPreferences(row)
	if err != nil {
		if errors.Is(err, model.ErrNotFound) {
			defaults := model.DefaultNotificationPreferences(userID)
			return &defaults, nil
		}
		return nil, err
	}
	return preferences, nil
}

func (r *PGNotificationRepository) UpsertNotificationPreferences(
	ctx context.Context,
	preferences model.NotificationPreferences,
) (*model.NotificationPreferences, error) {
	preferences.Normalize()
	row := r.pool.QueryRow(ctx, `
		INSERT INTO notification_preferences (
			user_id,
			push_enabled,
			activity_enabled,
			excursion_enabled,
			chat_enabled,
			marketing_enabled,
			quiet_hours_enabled,
			quiet_hours_start_minutes,
			quiet_hours_end_minutes,
			timezone,
			created_at,
			updated_at
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NOW(),NOW())
		ON CONFLICT (user_id)
		DO UPDATE SET
			push_enabled = EXCLUDED.push_enabled,
			activity_enabled = EXCLUDED.activity_enabled,
			excursion_enabled = EXCLUDED.excursion_enabled,
			chat_enabled = EXCLUDED.chat_enabled,
			marketing_enabled = EXCLUDED.marketing_enabled,
			quiet_hours_enabled = EXCLUDED.quiet_hours_enabled,
			quiet_hours_start_minutes = EXCLUDED.quiet_hours_start_minutes,
			quiet_hours_end_minutes = EXCLUDED.quiet_hours_end_minutes,
			timezone = EXCLUDED.timezone,
			updated_at = NOW()
		RETURNING
			user_id,
			push_enabled,
			activity_enabled,
			excursion_enabled,
			chat_enabled,
			marketing_enabled,
			quiet_hours_enabled,
			quiet_hours_start_minutes,
			quiet_hours_end_minutes,
			timezone,
			created_at,
			updated_at
	`, preferences.UserID, preferences.PushEnabled, preferences.ActivityEnabled,
		preferences.ExcursionEnabled, preferences.ChatEnabled, preferences.MarketingEnabled,
		preferences.QuietHoursEnabled, preferences.QuietHoursStartMinutes,
		preferences.QuietHoursEndMinutes, preferences.Timezone)
	return scanNotificationPreferences(row)
}

func (r *PGNotificationRepository) ListNotificationPreferences(
	ctx context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]model.NotificationPreferences, error) {
	preferencesByUserID := make(map[uuid.UUID]model.NotificationPreferences, len(userIDs))
	for _, userID := range userIDs {
		if userID == uuid.Nil {
			continue
		}
		preferencesByUserID[userID] = model.DefaultNotificationPreferences(userID)
	}
	if len(preferencesByUserID) == 0 {
		return preferencesByUserID, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT
			user_id,
			push_enabled,
			activity_enabled,
			excursion_enabled,
			chat_enabled,
			marketing_enabled,
			quiet_hours_enabled,
			quiet_hours_start_minutes,
			quiet_hours_end_minutes,
			timezone,
			created_at,
			updated_at
		FROM notification_preferences
		WHERE user_id = ANY($1)
	`, userIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		preferences, err := scanNotificationPreferences(rows)
		if err != nil {
			return nil, err
		}
		preferencesByUserID[preferences.UserID] = *preferences
	}
	return preferencesByUserID, rows.Err()
}

type scanner interface {
	Scan(dest ...any) error
}

func scanDevice(row scanner, tokenCiphertextDest *string) (*model.DeviceToken, error) {
	var device model.DeviceToken
	var invalidatedAt *time.Time
	var tokenCiphertext string
	dest := []any{
		&device.ID,
		&device.UserID,
		&device.Platform,
		&device.Provider,
		&device.Environment,
		&device.AppBundleID,
		&device.AppVersion,
		&device.DeviceModel,
		&device.Manufacturer,
		&device.Locale,
		&device.Timezone,
		&device.SessionID,
		&device.DeviceInstallationID,
		&device.TokenHash,
	}
	if tokenCiphertextDest != nil {
		dest = append(dest, &tokenCiphertext)
	}
	dest = append(dest,
		&device.Enabled,
		&device.CreatedAt,
		&device.UpdatedAt,
		&device.LastSeenAt,
		&invalidatedAt,
		&device.InvalidationReason,
	)
	if err := row.Scan(dest...); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, model.ErrNotFound
		}
		return nil, err
	}
	device.InvalidatedAt = invalidatedAt
	if tokenCiphertextDest != nil {
		*tokenCiphertextDest = tokenCiphertext
	}
	return &device, nil
}

func scanRequest(row scanner) (*model.NotificationRequest, error) {
	var request model.NotificationRequest
	var dataBytes []byte
	var ttlSeconds int64
	if err := row.Scan(
		&request.ID,
		&request.IdempotencyKey,
		&request.SourceService,
		&request.RecipientUserIDs,
		&request.Category,
		&request.Priority,
		&request.Payload.Title,
		&request.Payload.Body,
		&request.Payload.ImageURL,
		&request.Payload.DeepLink,
		&dataBytes,
		&request.Payload.CollapseKey,
		&ttlSeconds,
		&request.Status,
		&request.ScheduledAt,
		&request.CreatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, model.ErrNotFound
		}
		return nil, err
	}
	if len(dataBytes) > 0 {
		if err := json.Unmarshal(dataBytes, &request.Payload.Data); err != nil {
			return nil, fmt.Errorf("unmarshal notification data: %w", err)
		}
	}
	request.Payload.TTL = time.Duration(ttlSeconds) * time.Second
	return &request, nil
}

func scanCategorySummary(row scanner) (model.UserNotification, int, int, error) {
	var unreadCount int64
	var totalCount int64
	notification, err := scanUserNotificationWithExtra(row, &unreadCount, &totalCount)
	if err != nil {
		return model.UserNotification{}, 0, 0, err
	}
	return notification, int(unreadCount), int(totalCount), nil
}

func scanUserNotification(row scanner) (model.UserNotification, error) {
	return scanUserNotificationWithExtra(row)
}

func scanUserNotificationWithExtra(row scanner, extraDest ...any) (model.UserNotification, error) {
	var notification model.UserNotification
	var dataBytes []byte
	var readAt *time.Time
	dest := []any{
		&notification.ID,
		&notification.Category,
		&notification.Priority,
		&notification.Payload.Title,
		&notification.Payload.Body,
		&notification.Payload.ImageURL,
		&notification.Payload.DeepLink,
		&dataBytes,
		&notification.CreatedAt,
		&readAt,
	}
	dest = append(dest, extraDest...)
	if err := row.Scan(dest...); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return model.UserNotification{}, model.ErrNotFound
		}
		return model.UserNotification{}, err
	}
	if len(dataBytes) > 0 {
		if err := json.Unmarshal(dataBytes, &notification.Payload.Data); err != nil {
			return model.UserNotification{}, fmt.Errorf("unmarshal user notification data: %w", err)
		}
	}
	if notification.Payload.Data == nil {
		notification.Payload.Data = map[string]string{}
	}
	notification.ReadAt = readAt
	return notification, nil
}

func scanNotificationPreferences(row scanner) (*model.NotificationPreferences, error) {
	var preferences model.NotificationPreferences
	if err := row.Scan(
		&preferences.UserID,
		&preferences.PushEnabled,
		&preferences.ActivityEnabled,
		&preferences.ExcursionEnabled,
		&preferences.ChatEnabled,
		&preferences.MarketingEnabled,
		&preferences.QuietHoursEnabled,
		&preferences.QuietHoursStartMinutes,
		&preferences.QuietHoursEndMinutes,
		&preferences.Timezone,
		&preferences.CreatedAt,
		&preferences.UpdatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, model.ErrNotFound
		}
		return nil, err
	}
	preferences.Normalize()
	return &preferences, nil
}

func deliverySelectSQL() string {
	return `
		SELECT d.id, d.request_id, d.device_token_id, d.user_id,
			d.platform, d.provider, d.environment, t.token_ciphertext,
			r.category, r.title, r.body, r.image_url, r.deep_link, r.data,
			r.collapse_key, r.ttl_seconds, d.priority, d.status,
			d.attempt_count, d.max_attempts, COALESCE(d.next_attempt_at, NOW()),
			COALESCE(d.last_error_code, ''), COALESCE(d.last_error, '')
		FROM notification_deliveries d
		JOIN notification_requests r ON r.id = d.request_id
		JOIN notification_device_tokens t ON t.id = d.device_token_id
	`
}

func (r *PGNotificationRepository) scanDelivery(row scanner) (*model.Delivery, error) {
	var delivery model.Delivery
	var tokenCiphertext string
	var dataBytes []byte
	var ttlSeconds int64
	if err := row.Scan(
		&delivery.ID,
		&delivery.RequestID,
		&delivery.DeviceTokenID,
		&delivery.UserID,
		&delivery.Platform,
		&delivery.Provider,
		&delivery.Environment,
		&tokenCiphertext,
		&delivery.Category,
		&delivery.Payload.Title,
		&delivery.Payload.Body,
		&delivery.Payload.ImageURL,
		&delivery.Payload.DeepLink,
		&dataBytes,
		&delivery.Payload.CollapseKey,
		&ttlSeconds,
		&delivery.Priority,
		&delivery.Status,
		&delivery.AttemptCount,
		&delivery.MaxAttempts,
		&delivery.NextAttemptAt,
		&delivery.LastErrorCode,
		&delivery.LastError,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, model.ErrNotFound
		}
		return nil, err
	}
	token, err := r.protector.Decrypt(tokenCiphertext)
	if err != nil {
		return nil, err
	}
	delivery.Token = token
	if len(dataBytes) > 0 {
		if err = json.Unmarshal(dataBytes, &delivery.Payload.Data); err != nil {
			return nil, fmt.Errorf("unmarshal delivery data: %w", err)
		}
	}
	delivery.Payload.TTL = time.Duration(ttlSeconds) * time.Second
	return &delivery, nil
}
