package app

import (
	"context"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

const (
	SubjectNotificationRequested = "notifications.requested"
	SubjectDeliveryPrefix        = "notifications.delivery"

	defaultMaxDeliveryAttempts = 8
	maxRetryBackoff            = 15 * time.Minute

	MaxRecipientsPerRequest = 10000
	MaxTitleLength          = 180
	MaxBodyLength           = 2000
	MaxDataKeys             = 50
	MaxDataKeyLength        = 64
	MaxDataValueLength      = 1024
	MaxCollapseKeyLength    = 128
	MaxDeepLinkLength       = 2048
	MaxTTL                  = 30 * 24 * time.Hour
)

type Repository interface {
	UpsertDeviceToken(ctx context.Context, device model.DeviceToken) (*model.DeviceToken, error)
	DeactivateDeviceToken(ctx context.Context, userID uuid.UUID, deviceID uuid.UUID, reason string) error
	CreateNotificationRequest(ctx context.Context, request model.NotificationRequest) (*model.NotificationRequest, bool, error)
	GetNotificationRequest(ctx context.Context, requestID uuid.UUID) (*model.NotificationRequest, error)
	ListActiveDeviceTokens(ctx context.Context, userIDs []uuid.UUID) ([]*model.DeviceToken, error)
	CreateDelivery(ctx context.Context, delivery model.Delivery) (*model.Delivery, bool, error)
	GetDelivery(ctx context.Context, deliveryID uuid.UUID) (*model.Delivery, error)
	MarkDeliveryResult(ctx context.Context, deliveryID uuid.UUID, update DeliveryResultUpdate) error
	DeactivateDeviceTokenByID(ctx context.Context, deviceID uuid.UUID, reason string) error
	MarkRequestFanoutCompleted(ctx context.Context, requestID uuid.UUID, totalDeliveries int) error
	ListDueDeliveries(ctx context.Context, now time.Time, limit int) ([]model.Delivery, error)
}

type Publisher interface {
	Publish(ctx context.Context, subject string, payload any, messageID string) error
}

type PushProvider interface {
	Send(ctx context.Context, token string, delivery model.Delivery) (*model.ProviderSendResult, error)
}

type DeliveryResultUpdate struct {
	Status            model.DeliveryStatus
	AttemptCount      int
	NextAttemptAt     time.Time
	ProviderMessageID string
	ErrorCode         string
	ErrorMessage      string
}

type RegisterDeviceInput struct {
	UserID       uuid.UUID
	Platform     model.Platform
	Provider     model.Provider
	Environment  model.Environment
	Token        string
	AppBundleID  string
	AppVersion   string
	DeviceModel  string
	Manufacturer string
	Locale       string
	Timezone     string
}

type SendNotificationInput struct {
	IdempotencyKey   string
	SourceService    string
	RecipientUserIDs []uuid.UUID
	Category         string
	Priority         model.Priority
	Payload          model.NotificationPayload
	ScheduledAt      time.Time
}

type NotificationUseCase struct {
	repo      Repository
	publisher Publisher
	providers map[model.Provider]PushProvider
	now       func() time.Time
}

type Option func(*NotificationUseCase)

func WithClock(clock func() time.Time) Option {
	return func(uc *NotificationUseCase) {
		if clock != nil {
			uc.now = clock
		}
	}
}

func NewNotificationUseCase(
	repo Repository,
	publisher Publisher,
	providers map[model.Provider]PushProvider,
	opts ...Option,
) *NotificationUseCase {
	uc := &NotificationUseCase{
		repo:      repo,
		publisher: publisher,
		providers: providers,
		now: func() time.Time {
			return time.Now().UTC()
		},
	}
	for _, opt := range opts {
		opt(uc)
	}
	return uc
}

func (uc *NotificationUseCase) RegisterDevice(ctx context.Context, input RegisterDeviceInput) (*model.DeviceToken, error) {
	if uc == nil || uc.repo == nil {
		return nil, fmt.Errorf("notification use case is not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user id is required", model.ErrInvalidInput)
	}
	if !input.Platform.IsValid() {
		return nil, fmt.Errorf("%w: unsupported platform", model.ErrInvalidInput)
	}
	if !input.Provider.IsValid() {
		return nil, fmt.Errorf("%w: unsupported provider", model.ErrInvalidInput)
	}
	if !input.Environment.IsValid() {
		return nil, fmt.Errorf("%w: unsupported environment", model.ErrInvalidInput)
	}
	if !model.IsProviderCompatible(input.Platform, input.Provider) {
		return nil, fmt.Errorf("%w: provider is not compatible with platform", model.ErrInvalidInput)
	}
	if strings.TrimSpace(input.Token) == "" {
		return nil, fmt.Errorf("%w: device token is required", model.ErrInvalidInput)
	}
	if strings.TrimSpace(input.AppBundleID) == "" {
		return nil, fmt.Errorf("%w: app bundle id is required", model.ErrInvalidInput)
	}

	now := uc.now().UTC()
	device := model.DeviceToken{
		ID:           uuid.New(),
		UserID:       input.UserID,
		Platform:     input.Platform,
		Provider:     input.Provider,
		Environment:  input.Environment,
		AppBundleID:  strings.TrimSpace(input.AppBundleID),
		AppVersion:   strings.TrimSpace(input.AppVersion),
		DeviceModel:  strings.TrimSpace(input.DeviceModel),
		Manufacturer: strings.TrimSpace(input.Manufacturer),
		Locale:       model.NormalizeLocale(input.Locale),
		Timezone:     strings.TrimSpace(input.Timezone),
		Token:        strings.TrimSpace(input.Token),
		Enabled:      true,
		CreatedAt:    now,
		UpdatedAt:    now,
		LastSeenAt:   now,
	}

	return uc.repo.UpsertDeviceToken(ctx, device)
}

func (uc *NotificationUseCase) DeactivateDevice(ctx context.Context, userID uuid.UUID, deviceID uuid.UUID, reason string) error {
	if userID == uuid.Nil || deviceID == uuid.Nil {
		return fmt.Errorf("%w: user id and device id are required", model.ErrInvalidInput)
	}
	return uc.repo.DeactivateDeviceToken(ctx, userID, deviceID, strings.TrimSpace(reason))
}

func (uc *NotificationUseCase) SendNotification(
	ctx context.Context,
	input SendNotificationInput,
) (*model.NotificationRequest, error) {
	if uc == nil || uc.repo == nil || uc.publisher == nil {
		return nil, fmt.Errorf("notification use case is not configured")
	}
	if strings.TrimSpace(input.IdempotencyKey) == "" {
		return nil, fmt.Errorf("%w: idempotency key is required", model.ErrInvalidInput)
	}
	if strings.TrimSpace(input.SourceService) == "" {
		return nil, fmt.Errorf("%w: source service is required", model.ErrInvalidInput)
	}
	if len(input.RecipientUserIDs) == 0 {
		return nil, fmt.Errorf("%w: at least one recipient is required", model.ErrInvalidInput)
	}
	if len(input.RecipientUserIDs) > MaxRecipientsPerRequest {
		return nil, fmt.Errorf("%w: too many recipients", model.ErrInvalidInput)
	}
	if strings.TrimSpace(input.Payload.Title) == "" && strings.TrimSpace(input.Payload.Body) == "" {
		return nil, fmt.Errorf("%w: notification title or body is required", model.ErrInvalidInput)
	}
	if err := validatePayload(input.Payload); err != nil {
		return nil, err
	}

	recipients := dedupeUUIDs(input.RecipientUserIDs)
	if len(recipients) == 0 {
		return nil, fmt.Errorf("%w: at least one valid recipient is required", model.ErrInvalidInput)
	}

	now := uc.now().UTC()
	scheduledAt := input.ScheduledAt
	if scheduledAt.IsZero() {
		scheduledAt = now
	}

	request := model.NotificationRequest{
		ID:               uuid.New(),
		IdempotencyKey:   strings.TrimSpace(input.IdempotencyKey),
		SourceService:    strings.TrimSpace(input.SourceService),
		RecipientUserIDs: recipients,
		Category:         strings.TrimSpace(input.Category),
		Priority:         input.Priority.Normalize(),
		Payload:          normalizePayload(input.Payload),
		Status:           "accepted",
		ScheduledAt:      scheduledAt.UTC(),
		CreatedAt:        now,
	}

	created, inserted, err := uc.repo.CreateNotificationRequest(ctx, request)
	if err != nil {
		return nil, err
	}
	if !inserted {
		return created, nil
	}

	if err := uc.publisher.Publish(ctx, SubjectNotificationRequested, created, created.ID.String()); err != nil {
		return nil, err
	}
	return created, nil
}

func (uc *NotificationUseCase) FanoutRequest(ctx context.Context, requestID uuid.UUID) (int, error) {
	if requestID == uuid.Nil {
		return 0, fmt.Errorf("%w: request id is required", model.ErrInvalidInput)
	}
	request, err := uc.repo.GetNotificationRequest(ctx, requestID)
	if err != nil {
		return 0, err
	}
	devices, err := uc.repo.ListActiveDeviceTokens(ctx, request.RecipientUserIDs)
	if err != nil {
		return 0, err
	}

	createdCount := 0
	now := uc.now().UTC()
	for _, device := range devices {
		if device == nil || !device.Enabled || strings.TrimSpace(device.Token) == "" {
			continue
		}
		if !model.IsProviderCompatible(device.Platform, device.Provider) {
			continue
		}
		delivery := model.Delivery{
			ID:            uuid.New(),
			RequestID:     request.ID,
			DeviceTokenID: device.ID,
			UserID:        device.UserID,
			Platform:      device.Platform,
			Provider:      device.Provider,
			Environment:   device.Environment,
			Category:      request.Category,
			Token:         device.Token,
			Payload:       request.Payload,
			Priority:      request.Priority.Normalize(),
			Status:        model.DeliveryPending,
			MaxAttempts:   defaultMaxDeliveryAttempts,
			NextAttemptAt: now,
		}
		created, inserted, err := uc.repo.CreateDelivery(ctx, delivery)
		if err != nil {
			return createdCount, err
		}
		if !inserted {
			continue
		}
		createdCount++
		if uc.publisher != nil {
			subject := fmt.Sprintf("%s.%s", SubjectDeliveryPrefix, created.Provider)
			if err := uc.publisher.Publish(ctx, subject, created, created.ID.String()); err != nil {
				return createdCount, err
			}
		}
	}
	if err := uc.repo.MarkRequestFanoutCompleted(ctx, request.ID, createdCount); err != nil {
		return createdCount, err
	}
	return createdCount, nil
}

func (uc *NotificationUseCase) DeliverNotification(ctx context.Context, deliveryID uuid.UUID) error {
	if deliveryID == uuid.Nil {
		return fmt.Errorf("%w: delivery id is required", model.ErrInvalidInput)
	}
	delivery, err := uc.repo.GetDelivery(ctx, deliveryID)
	if err != nil {
		return err
	}

	provider, ok := uc.providers[delivery.Provider]
	if !ok || provider == nil {
		return uc.markRetryOrFailure(ctx, delivery, delivery.AttemptCount+1, model.ErrProviderUnavailable.Error(), "provider is not configured", 0)
	}

	attempt := delivery.AttemptCount + 1
	result, err := provider.Send(ctx, delivery.Token, *delivery)
	if err != nil {
		return uc.markRetryOrFailure(ctx, delivery, attempt, "PROVIDER_ERROR", err.Error(), 0)
	}
	if result == nil {
		return uc.markRetryOrFailure(ctx, delivery, attempt, "PROVIDER_EMPTY_RESULT", "provider returned empty result", 0)
	}

	switch result.Status {
	case model.ProviderSendSucceeded:
		return uc.repo.MarkDeliveryResult(ctx, delivery.ID, DeliveryResultUpdate{
			Status:            model.DeliverySucceeded,
			AttemptCount:      attempt,
			ProviderMessageID: result.ProviderMessageID,
		})
	case model.ProviderSendInvalidToken:
		if err := uc.repo.DeactivateDeviceTokenByID(ctx, delivery.DeviceTokenID, result.ErrorCode); err != nil {
			return err
		}
		return uc.repo.MarkDeliveryResult(ctx, delivery.ID, DeliveryResultUpdate{
			Status:       model.DeliveryInvalidToken,
			AttemptCount: attempt,
			ErrorCode:    result.ErrorCode,
			ErrorMessage: result.ErrorMessage,
		})
	case model.ProviderSendRetryable:
		return uc.markRetryOrFailure(ctx, delivery, attempt, result.ErrorCode, result.ErrorMessage, result.RetryAfter)
	case model.ProviderSendTerminal:
		return uc.repo.MarkDeliveryResult(ctx, delivery.ID, DeliveryResultUpdate{
			Status:       model.DeliveryFailed,
			AttemptCount: attempt,
			ErrorCode:    result.ErrorCode,
			ErrorMessage: result.ErrorMessage,
		})
	default:
		return uc.markRetryOrFailure(ctx, delivery, attempt, "UNKNOWN_PROVIDER_STATUS", string(result.Status), 0)
	}
}

func (uc *NotificationUseCase) PublishDueDeliveries(ctx context.Context, limit int) (int, error) {
	if limit <= 0 {
		limit = 100
	}
	deliveries, err := uc.repo.ListDueDeliveries(ctx, uc.now().UTC(), limit)
	if err != nil {
		return 0, err
	}
	for _, delivery := range deliveries {
		subject := fmt.Sprintf("%s.%s", SubjectDeliveryPrefix, delivery.Provider)
		messageID := fmt.Sprintf("%s:%d", delivery.ID.String(), uc.now().UTC().UnixNano())
		if err := uc.publisher.Publish(ctx, subject, delivery, messageID); err != nil {
			return 0, err
		}
	}
	return len(deliveries), nil
}

func (uc *NotificationUseCase) markRetryOrFailure(
	ctx context.Context,
	delivery *model.Delivery,
	attempt int,
	errorCode string,
	errorMessage string,
	retryAfter time.Duration,
) error {
	status := model.DeliveryRetryScheduled
	var nextAttemptAt time.Time
	if attempt >= delivery.MaxAttempts && delivery.MaxAttempts > 0 {
		status = model.DeliveryFailed
	} else {
		nextAttemptAt = uc.now().UTC().Add(maxDuration(retryAfter, retryBackoff(attempt)))
	}
	return uc.repo.MarkDeliveryResult(ctx, delivery.ID, DeliveryResultUpdate{
		Status:        status,
		AttemptCount:  attempt,
		NextAttemptAt: nextAttemptAt,
		ErrorCode:     strings.TrimSpace(errorCode),
		ErrorMessage:  strings.TrimSpace(errorMessage),
	})
}

func dedupeUUIDs(values []uuid.UUID) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(values))
	result := make([]uuid.UUID, 0, len(values))
	for _, value := range values {
		if value == uuid.Nil {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func normalizePayload(payload model.NotificationPayload) model.NotificationPayload {
	payload.Title = strings.TrimSpace(payload.Title)
	payload.Body = strings.TrimSpace(payload.Body)
	payload.ImageURL = strings.TrimSpace(payload.ImageURL)
	payload.DeepLink = strings.TrimSpace(payload.DeepLink)
	payload.CollapseKey = strings.TrimSpace(payload.CollapseKey)
	if payload.Data == nil {
		payload.Data = map[string]string{}
	}
	if payload.TTL <= 0 {
		payload.TTL = 24 * time.Hour
	}
	if payload.TTL > MaxTTL {
		payload.TTL = MaxTTL
	}
	return payload
}

func validatePayload(payload model.NotificationPayload) error {
	if len([]rune(payload.Title)) > MaxTitleLength {
		return fmt.Errorf("%w: notification title is too long", model.ErrInvalidInput)
	}
	if len([]rune(payload.Body)) > MaxBodyLength {
		return fmt.Errorf("%w: notification body is too long", model.ErrInvalidInput)
	}
	if len(payload.Data) > MaxDataKeys {
		return fmt.Errorf("%w: notification data has too many keys", model.ErrInvalidInput)
	}
	for key, value := range payload.Data {
		if len([]rune(key)) > MaxDataKeyLength {
			return fmt.Errorf("%w: notification data key is too long", model.ErrInvalidInput)
		}
		if len([]rune(value)) > MaxDataValueLength {
			return fmt.Errorf("%w: notification data value is too long", model.ErrInvalidInput)
		}
	}
	if len([]rune(payload.CollapseKey)) > MaxCollapseKeyLength {
		return fmt.Errorf("%w: collapse key is too long", model.ErrInvalidInput)
	}
	if len([]rune(payload.DeepLink)) > MaxDeepLinkLength {
		return fmt.Errorf("%w: deep link is too long", model.ErrInvalidInput)
	}
	if payload.TTL > MaxTTL {
		return fmt.Errorf("%w: ttl is too large", model.ErrInvalidInput)
	}
	return nil
}

func retryBackoff(attempt int) time.Duration {
	if attempt < 1 {
		attempt = 1
	}
	power := math.Min(float64(attempt-1), 8)
	backoff := time.Duration(math.Pow(2, power)) * time.Second
	if backoff > maxRetryBackoff {
		return maxRetryBackoff
	}
	return backoff
}

func maxDuration(a time.Duration, b time.Duration) time.Duration {
	if a > b {
		return a
	}
	return b
}
