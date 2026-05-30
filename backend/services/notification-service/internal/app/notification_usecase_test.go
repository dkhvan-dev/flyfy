package app

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

func TestRegisterDeviceRejectsProviderPlatformMismatch(t *testing.T) {
	uc := newTestUseCase()

	_, err := uc.RegisterDevice(context.Background(), RegisterDeviceInput{
		UserID:      uuid.New(),
		Platform:    model.PlatformIOS,
		Provider:    model.ProviderFCM,
		Environment: model.EnvironmentProduction,
		Token:       "ios-token",
		AppBundleID: "kz.inflap",
	})

	if !errors.Is(err, model.ErrInvalidInput) {
		t.Fatalf("expected invalid input, got %v", err)
	}
}

func TestRegisterDeviceUpsertsCompatibleToken(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()

	device, err := uc.RegisterDevice(context.Background(), RegisterDeviceInput{
		UserID:       userID,
		Platform:     model.PlatformAndroid,
		Provider:     model.ProviderHMS,
		Environment:  model.EnvironmentProduction,
		Token:        "hms-token",
		AppBundleID:  "kz.inflap",
		AppVersion:   "1.8.0",
		Manufacturer: "Huawei",
		Locale:       "RU",
		Timezone:     "Asia/Almaty",
	})
	if err != nil {
		t.Fatalf("RegisterDevice returned error: %v", err)
	}

	if device.UserID != userID {
		t.Fatalf("unexpected user id: %s", device.UserID)
	}
	if device.Provider != model.ProviderHMS {
		t.Fatalf("unexpected provider: %s", device.Provider)
	}
	if device.Locale != "ru" {
		t.Fatalf("expected normalized locale, got %q", device.Locale)
	}
	if len(uc.repo.devices) != 1 {
		t.Fatalf("expected one stored device, got %d", len(uc.repo.devices))
	}
}

func TestSendNotificationPublishesOnlyForNewIdempotencyKey(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()

	input := SendNotificationInput{
		IdempotencyKey:   "activity:joined:123",
		SourceService:    "activity-service",
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "activity",
		Priority:         model.PriorityHigh,
		Payload: model.NotificationPayload{
			Title: "New activity update",
			Body:  "Your trip has a new participant",
			Data:  map[string]string{"activityId": "123"},
		},
	}

	first, err := uc.SendNotification(context.Background(), input)
	if err != nil {
		t.Fatalf("first SendNotification returned error: %v", err)
	}
	second, err := uc.SendNotification(context.Background(), input)
	if err != nil {
		t.Fatalf("second SendNotification returned error: %v", err)
	}

	if first.ID != second.ID {
		t.Fatalf("expected same request for duplicate idempotency key")
	}
	if uc.publisher.publishCount != 1 {
		t.Fatalf("expected one publish, got %d", uc.publisher.publishCount)
	}
}

func TestSendNotificationScopesIdempotencyBySourceService(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()
	input := SendNotificationInput{
		IdempotencyKey:   "same-business-key",
		SourceService:    "activity-service",
		RecipientUserIDs: []uuid.UUID{userID},
		Payload:          model.NotificationPayload{Title: "Activity"},
	}

	first, err := uc.SendNotification(context.Background(), input)
	if err != nil {
		t.Fatalf("first SendNotification returned error: %v", err)
	}
	input.SourceService = "chat-service"
	second, err := uc.SendNotification(context.Background(), input)
	if err != nil {
		t.Fatalf("second SendNotification returned error: %v", err)
	}

	if first.ID == second.ID {
		t.Fatalf("expected different requests for different source services")
	}
	if uc.publisher.publishCount != 2 {
		t.Fatalf("expected two publishes, got %d", uc.publisher.publishCount)
	}
}

func TestSendNotificationRejectsOversizedFanoutAndPayload(t *testing.T) {
	uc := newTestUseCase()
	recipients := make([]uuid.UUID, MaxRecipientsPerRequest+1)
	for i := range recipients {
		recipients[i] = uuid.New()
	}

	_, err := uc.SendNotification(context.Background(), SendNotificationInput{
		IdempotencyKey:   "large-fanout",
		SourceService:    "activity-service",
		RecipientUserIDs: recipients,
		Payload:          model.NotificationPayload{Title: "Too many"},
	})
	if !errors.Is(err, model.ErrInvalidInput) {
		t.Fatalf("expected invalid input for large fanout, got %v", err)
	}

	_, err = uc.SendNotification(context.Background(), SendNotificationInput{
		IdempotencyKey:   "large-body",
		SourceService:    "activity-service",
		RecipientUserIDs: []uuid.UUID{uuid.New()},
		Payload:          model.NotificationPayload{Body: strings.Repeat("x", MaxBodyLength+1)},
	})
	if !errors.Is(err, model.ErrInvalidInput) {
		t.Fatalf("expected invalid input for large payload, got %v", err)
	}
}

func TestFanoutRequestCreatesDeliveryForEachActiveDevice(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()
	requestID := uuid.New()
	fcmDeviceID := uuid.New()
	hmsDeviceID := uuid.New()
	disabledDeviceID := uuid.New()

	uc.repo.requests[requestID] = &model.NotificationRequest{
		ID:               requestID,
		RecipientUserIDs: []uuid.UUID{userID},
		Priority:         model.PriorityHigh,
		Payload:          model.NotificationPayload{Title: "Hello", Body: "World"},
	}
	uc.repo.devices[fcmDeviceID] = &model.DeviceToken{
		ID:          fcmDeviceID,
		UserID:      userID,
		Platform:    model.PlatformAndroid,
		Provider:    model.ProviderFCM,
		Environment: model.EnvironmentProduction,
		Token:       "fcm-token",
		Enabled:     true,
	}
	uc.repo.devices[hmsDeviceID] = &model.DeviceToken{
		ID:          hmsDeviceID,
		UserID:      userID,
		Platform:    model.PlatformAndroid,
		Provider:    model.ProviderHMS,
		Environment: model.EnvironmentProduction,
		Token:       "hms-token",
		Enabled:     true,
	}
	uc.repo.devices[disabledDeviceID] = &model.DeviceToken{
		ID:          disabledDeviceID,
		UserID:      userID,
		Platform:    model.PlatformIOS,
		Provider:    model.ProviderAPNS,
		Environment: model.EnvironmentProduction,
		Token:       "apns-token",
		Enabled:     false,
	}

	created, err := uc.FanoutRequest(context.Background(), requestID)
	if err != nil {
		t.Fatalf("FanoutRequest returned error: %v", err)
	}

	if created != 2 {
		t.Fatalf("expected 2 deliveries, got %d", created)
	}
	if uc.publisher.publishCount != 2 {
		t.Fatalf("expected 2 delivery publishes, got %d", uc.publisher.publishCount)
	}
}

func TestDeliverDueNotificationInvalidatesDeviceOnInvalidToken(t *testing.T) {
	uc := newTestUseCase()
	deliveryID := uuid.New()
	deviceID := uuid.New()
	uc.providers[model.ProviderFCM] = providerFunc(func(context.Context, string, model.Delivery) (*model.ProviderSendResult, error) {
		return &model.ProviderSendResult{
			Status:       model.ProviderSendInvalidToken,
			ErrorCode:    "UNREGISTERED",
			ErrorMessage: "token is no longer registered",
		}, nil
	})
	uc.repo.deliveries[deliveryID] = &model.Delivery{
		ID:            deliveryID,
		DeviceTokenID: deviceID,
		Provider:      model.ProviderFCM,
		Token:         "expired-token",
		Status:        model.DeliveryPending,
		MaxAttempts:   5,
	}

	if err := uc.DeliverNotification(context.Background(), deliveryID); err != nil {
		t.Fatalf("DeliverNotification returned error: %v", err)
	}

	if !uc.repo.invalidated[deviceID] {
		t.Fatalf("expected device token to be invalidated")
	}
	if uc.repo.deliveries[deliveryID].Status != model.DeliveryInvalidToken {
		t.Fatalf("expected invalid token status, got %s", uc.repo.deliveries[deliveryID].Status)
	}
}

func TestDeliverDueNotificationSchedulesRetryWithBackoff(t *testing.T) {
	uc := newTestUseCase()
	deliveryID := uuid.New()
	uc.now = time.Date(2026, 5, 30, 12, 0, 0, 0, time.UTC)
	uc.NotificationUseCase.now = func() time.Time { return uc.now }
	uc.providers[model.ProviderAPNS] = providerFunc(func(context.Context, string, model.Delivery) (*model.ProviderSendResult, error) {
		return &model.ProviderSendResult{
			Status:       model.ProviderSendRetryable,
			ErrorCode:    "TooManyRequests",
			ErrorMessage: "provider throttled request",
			RetryAfter:   30 * time.Second,
		}, nil
	})
	uc.repo.deliveries[deliveryID] = &model.Delivery{
		ID:           deliveryID,
		Provider:     model.ProviderAPNS,
		Token:        "apns-token",
		Status:       model.DeliveryPending,
		AttemptCount: 1,
		MaxAttempts:  5,
	}

	if err := uc.DeliverNotification(context.Background(), deliveryID); err != nil {
		t.Fatalf("DeliverNotification returned error: %v", err)
	}

	delivery := uc.repo.deliveries[deliveryID]
	if delivery.Status != model.DeliveryRetryScheduled {
		t.Fatalf("expected retry scheduled, got %s", delivery.Status)
	}
	if delivery.NextAttemptAt.Before(uc.now.Add(30 * time.Second)) {
		t.Fatalf("expected retry-after to be respected, got %s", delivery.NextAttemptAt)
	}
}

func TestPublishDueDeliveriesRequeuesRetryScheduledDeliveries(t *testing.T) {
	uc := newTestUseCase()
	uc.now = time.Date(2026, 5, 30, 12, 0, 0, 0, time.UTC)
	uc.NotificationUseCase.now = func() time.Time { return uc.now }
	dueID := uuid.New()
	futureID := uuid.New()
	uc.repo.deliveries[dueID] = &model.Delivery{
		ID:            dueID,
		Provider:      model.ProviderFCM,
		Status:        model.DeliveryRetryScheduled,
		NextAttemptAt: uc.now.Add(-time.Second),
	}
	uc.repo.deliveries[futureID] = &model.Delivery{
		ID:            futureID,
		Provider:      model.ProviderFCM,
		Status:        model.DeliveryRetryScheduled,
		NextAttemptAt: uc.now.Add(time.Minute),
	}

	published, err := uc.PublishDueDeliveries(context.Background(), 100)
	if err != nil {
		t.Fatalf("PublishDueDeliveries returned error: %v", err)
	}

	if published != 1 {
		t.Fatalf("expected one due delivery, got %d", published)
	}
	if uc.publisher.publishCount != 1 {
		t.Fatalf("expected one publish, got %d", uc.publisher.publishCount)
	}
}

type testUseCase struct {
	*NotificationUseCase
	repo      *memoryRepository
	publisher *memoryPublisher
	providers map[model.Provider]PushProvider
	now       time.Time
}

func newTestUseCase() *testUseCase {
	repo := newMemoryRepository()
	publisher := &memoryPublisher{}
	providers := map[model.Provider]PushProvider{
		model.ProviderFCM: providerFunc(func(context.Context, string, model.Delivery) (*model.ProviderSendResult, error) {
			return &model.ProviderSendResult{Status: model.ProviderSendSucceeded}, nil
		}),
		model.ProviderAPNS: providerFunc(func(context.Context, string, model.Delivery) (*model.ProviderSendResult, error) {
			return &model.ProviderSendResult{Status: model.ProviderSendSucceeded}, nil
		}),
		model.ProviderHMS: providerFunc(func(context.Context, string, model.Delivery) (*model.ProviderSendResult, error) {
			return &model.ProviderSendResult{Status: model.ProviderSendSucceeded}, nil
		}),
	}
	now := time.Date(2026, 5, 30, 10, 0, 0, 0, time.UTC)
	uc := NewNotificationUseCase(repo, publisher, providers, WithClock(func() time.Time { return now }))
	return &testUseCase{
		NotificationUseCase: uc,
		repo:                repo,
		publisher:           publisher,
		providers:           providers,
		now:                 now,
	}
}

type providerFunc func(context.Context, string, model.Delivery) (*model.ProviderSendResult, error)

func (f providerFunc) Send(ctx context.Context, token string, delivery model.Delivery) (*model.ProviderSendResult, error) {
	return f(ctx, token, delivery)
}

type memoryPublisher struct {
	publishCount int
}

func (p *memoryPublisher) Publish(ctx context.Context, subject string, payload any, messageID string) error {
	p.publishCount++
	return nil
}

type memoryRepository struct {
	devices     map[uuid.UUID]*model.DeviceToken
	requests    map[uuid.UUID]*model.NotificationRequest
	idempotency map[string]uuid.UUID
	deliveries  map[uuid.UUID]*model.Delivery
	invalidated map[uuid.UUID]bool
}

func newMemoryRepository() *memoryRepository {
	return &memoryRepository{
		devices:     make(map[uuid.UUID]*model.DeviceToken),
		requests:    make(map[uuid.UUID]*model.NotificationRequest),
		idempotency: make(map[string]uuid.UUID),
		deliveries:  make(map[uuid.UUID]*model.Delivery),
		invalidated: make(map[uuid.UUID]bool),
	}
}

func (r *memoryRepository) UpsertDeviceToken(ctx context.Context, device model.DeviceToken) (*model.DeviceToken, error) {
	if device.ID == uuid.Nil {
		device.ID = uuid.New()
	}
	device.Enabled = true
	r.devices[device.ID] = &device
	return &device, nil
}

func (r *memoryRepository) DeactivateDeviceToken(ctx context.Context, userID uuid.UUID, deviceID uuid.UUID, reason string) error {
	device, ok := r.devices[deviceID]
	if !ok || device.UserID != userID {
		return model.ErrNotFound
	}
	device.Enabled = false
	device.InvalidationReason = reason
	return nil
}

func (r *memoryRepository) CreateNotificationRequest(ctx context.Context, request model.NotificationRequest) (*model.NotificationRequest, bool, error) {
	key := request.SourceService + ":" + request.IdempotencyKey
	if id, ok := r.idempotency[key]; ok {
		return r.requests[id], false, nil
	}
	if request.ID == uuid.Nil {
		request.ID = uuid.New()
	}
	r.requests[request.ID] = &request
	r.idempotency[key] = request.ID
	return &request, true, nil
}

func (r *memoryRepository) GetNotificationRequest(ctx context.Context, requestID uuid.UUID) (*model.NotificationRequest, error) {
	request, ok := r.requests[requestID]
	if !ok {
		return nil, model.ErrNotFound
	}
	return request, nil
}

func (r *memoryRepository) ListActiveDeviceTokens(ctx context.Context, userIDs []uuid.UUID) ([]*model.DeviceToken, error) {
	userSet := make(map[uuid.UUID]struct{}, len(userIDs))
	for _, userID := range userIDs {
		userSet[userID] = struct{}{}
	}
	var devices []*model.DeviceToken
	for _, device := range r.devices {
		if _, ok := userSet[device.UserID]; ok && device.Enabled {
			devices = append(devices, device)
		}
	}
	return devices, nil
}

func (r *memoryRepository) CreateDelivery(ctx context.Context, delivery model.Delivery) (*model.Delivery, bool, error) {
	for _, existing := range r.deliveries {
		if existing.RequestID == delivery.RequestID && existing.DeviceTokenID == delivery.DeviceTokenID {
			return existing, false, nil
		}
	}
	if delivery.ID == uuid.Nil {
		delivery.ID = uuid.New()
	}
	r.deliveries[delivery.ID] = &delivery
	return &delivery, true, nil
}

func (r *memoryRepository) GetDelivery(ctx context.Context, deliveryID uuid.UUID) (*model.Delivery, error) {
	delivery, ok := r.deliveries[deliveryID]
	if !ok {
		return nil, model.ErrNotFound
	}
	return delivery, nil
}

func (r *memoryRepository) MarkDeliveryResult(ctx context.Context, deliveryID uuid.UUID, update DeliveryResultUpdate) error {
	delivery, ok := r.deliveries[deliveryID]
	if !ok {
		return model.ErrNotFound
	}
	delivery.Status = update.Status
	delivery.AttemptCount = update.AttemptCount
	delivery.NextAttemptAt = update.NextAttemptAt
	delivery.LastErrorCode = update.ErrorCode
	delivery.LastError = update.ErrorMessage
	return nil
}

func (r *memoryRepository) DeactivateDeviceTokenByID(ctx context.Context, deviceID uuid.UUID, reason string) error {
	r.invalidated[deviceID] = true
	if device, ok := r.devices[deviceID]; ok {
		device.Enabled = false
		device.InvalidationReason = reason
	}
	return nil
}

func (r *memoryRepository) MarkRequestFanoutCompleted(ctx context.Context, requestID uuid.UUID, totalDeliveries int) error {
	request, ok := r.requests[requestID]
	if !ok {
		return model.ErrNotFound
	}
	request.Status = "fanout_completed"
	return nil
}

func (r *memoryRepository) ListDueDeliveries(ctx context.Context, now time.Time, limit int) ([]model.Delivery, error) {
	deliveries := make([]model.Delivery, 0)
	for _, delivery := range r.deliveries {
		if len(deliveries) >= limit {
			break
		}
		if (delivery.Status == model.DeliveryPending || delivery.Status == model.DeliveryRetryScheduled) &&
			!delivery.NextAttemptAt.After(now) {
			deliveries = append(deliveries, *delivery)
		}
	}
	return deliveries, nil
}
