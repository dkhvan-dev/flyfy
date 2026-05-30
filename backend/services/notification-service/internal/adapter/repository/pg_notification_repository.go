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
			token_hash, token_ciphertext, enabled, created_at, updated_at, last_seen_at
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,true,$14,$14,$14)
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
			token_ciphertext = EXCLUDED.token_ciphertext,
			enabled = true,
			updated_at = EXCLUDED.updated_at,
			last_seen_at = EXCLUDED.last_seen_at,
			invalidated_at = NULL,
			invalidation_reason = ''
		RETURNING id, user_id, platform, provider, environment, app_bundle_id,
			app_version, device_model, manufacturer, locale, timezone, token_hash,
			enabled, created_at, updated_at, last_seen_at, invalidated_at, invalidation_reason
	`, device.ID, device.UserID, device.Platform, device.Provider, device.Environment,
		device.AppBundleID, device.AppVersion, device.DeviceModel, device.Manufacturer,
		device.Locale, device.Timezone, tokenHash, tokenCiphertext, device.UpdatedAt)

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
			app_version, device_model, manufacturer, locale, timezone, token_hash,
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

func deliverySelectSQL() string {
	return `
		SELECT d.id, d.request_id, d.device_token_id, d.user_id,
			d.platform, d.provider, d.environment, t.token_ciphertext,
			r.title, r.body, r.image_url, r.deep_link, r.data,
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
