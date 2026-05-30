package app

import (
	"context"
	"errors"
	"sort"
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

func TestListUserNotificationCategoriesReturnsLatestPerCategory(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()
	olderActivityID := uuid.New()
	latestActivityID := uuid.New()
	excursionID := uuid.New()
	otherUserID := uuid.New()

	uc.repo.requests[olderActivityID] = &model.NotificationRequest{
		ID:               olderActivityID,
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "activity",
		Priority:         model.PriorityNormal,
		Payload: model.NotificationPayload{
			Title: "Older activity update",
			Body:  "This should not be the category preview",
		},
		CreatedAt: uc.now.Add(-2 * time.Hour),
	}
	uc.repo.requests[latestActivityID] = &model.NotificationRequest{
		ID:               latestActivityID,
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "activity",
		Priority:         model.PriorityHigh,
		Payload: model.NotificationPayload{
			Title:    "Latest activity update",
			DeepLink: "/activities/activity-1",
			Data:     map[string]string{"activityId": "activity-1"},
		},
		CreatedAt: uc.now.Add(-time.Hour),
	}
	uc.repo.requests[excursionID] = &model.NotificationRequest{
		ID:               excursionID,
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "excursion",
		Payload:          model.NotificationPayload{Title: "Excursion approved"},
		CreatedAt:        uc.now,
	}
	otherUserRequestID := uuid.New()
	uc.repo.requests[otherUserRequestID] = &model.NotificationRequest{
		ID:               otherUserRequestID,
		RecipientUserIDs: []uuid.UUID{otherUserID},
		Category:         "activity",
		Payload:          model.NotificationPayload{Title: "Other user's notification"},
		CreatedAt:        uc.now.Add(time.Hour),
	}
	uc.repo.markRead(userID, olderActivityID, uc.now.Add(-30*time.Minute))

	categories, err := uc.ListUserNotificationCategories(context.Background(), userID, 10)
	if err != nil {
		t.Fatalf("ListUserNotificationCategories returned error: %v", err)
	}

	if len(categories) != 2 {
		t.Fatalf("expected 2 categories, got %d", len(categories))
	}
	if categories[0].Category != "excursion" {
		t.Fatalf("expected newest category first, got %q", categories[0].Category)
	}
	if categories[1].Category != "activity" {
		t.Fatalf("expected activity category second, got %q", categories[1].Category)
	}
	if categories[1].Latest.ID != latestActivityID {
		t.Fatalf("expected latest activity request in preview")
	}
	if categories[1].UnreadCount != 1 {
		t.Fatalf("expected one unread activity notification, got %d", categories[1].UnreadCount)
	}
	if categories[1].TotalCount != 2 {
		t.Fatalf("expected two activity notifications, got %d", categories[1].TotalCount)
	}
}

func TestMarkUserNotificationsReadMarksOnlySelectedCategory(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()
	activityID := uuid.New()
	excursionID := uuid.New()

	uc.repo.requests[activityID] = &model.NotificationRequest{
		ID:               activityID,
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "activity",
		Payload:          model.NotificationPayload{Title: "Activity"},
		CreatedAt:        uc.now,
	}
	uc.repo.requests[excursionID] = &model.NotificationRequest{
		ID:               excursionID,
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "excursion",
		Payload:          model.NotificationPayload{Title: "Excursion"},
		CreatedAt:        uc.now,
	}

	updated, err := uc.MarkUserNotificationsRead(context.Background(), userID, "activity")
	if err != nil {
		t.Fatalf("MarkUserNotificationsRead returned error: %v", err)
	}

	if updated != 1 {
		t.Fatalf("expected one updated notification, got %d", updated)
	}
	if !uc.repo.isRead(userID, activityID) {
		t.Fatalf("expected activity notification to be read")
	}
	if uc.repo.isRead(userID, excursionID) {
		t.Fatalf("did not expect excursion notification to be read")
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

func TestDeactivateSessionDevicesStopsFanoutToRevokedSession(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()
	requestID := uuid.New()
	oldDeviceID := uuid.New()
	newDeviceID := uuid.New()
	legacyDeviceID := uuid.New()
	oldSessionID := uuid.NewString()
	newSessionID := uuid.NewString()

	uc.repo.requests[requestID] = &model.NotificationRequest{
		ID:               requestID,
		RecipientUserIDs: []uuid.UUID{userID},
		Priority:         model.PriorityHigh,
		Payload:          model.NotificationPayload{Title: "Session-bound push"},
	}
	uc.repo.devices[oldDeviceID] = &model.DeviceToken{
		ID:          oldDeviceID,
		UserID:      userID,
		SessionID:   oldSessionID,
		Platform:    model.PlatformAndroid,
		Provider:    model.ProviderFCM,
		Environment: model.EnvironmentProduction,
		Token:       "old-fcm-token",
		Enabled:     true,
	}
	uc.repo.devices[newDeviceID] = &model.DeviceToken{
		ID:          newDeviceID,
		UserID:      userID,
		SessionID:   newSessionID,
		Platform:    model.PlatformAndroid,
		Provider:    model.ProviderFCM,
		Environment: model.EnvironmentProduction,
		Token:       "new-fcm-token",
		Enabled:     true,
	}
	uc.repo.devices[legacyDeviceID] = &model.DeviceToken{
		ID:          legacyDeviceID,
		UserID:      userID,
		Platform:    model.PlatformAndroid,
		Provider:    model.ProviderFCM,
		Environment: model.EnvironmentProduction,
		Token:       "legacy-sessionless-token",
		Enabled:     true,
	}

	deactivated, err := uc.DeactivateSessionDevices(
		context.Background(),
		userID,
		oldSessionID,
		"new_login",
	)
	if err != nil {
		t.Fatalf("DeactivateSessionDevices returned error: %v", err)
	}
	if deactivated != 2 {
		t.Fatalf("expected old-session and legacy sessionless devices to be deactivated, got %d", deactivated)
	}

	created, err := uc.FanoutRequest(context.Background(), requestID)
	if err != nil {
		t.Fatalf("FanoutRequest returned error: %v", err)
	}

	if created != 1 {
		t.Fatalf("expected fanout only to the active session device, got %d", created)
	}
	for _, delivery := range uc.repo.deliveries {
		if delivery.DeviceTokenID != newDeviceID {
			t.Fatalf("expected delivery for new session device %s, got %s", newDeviceID, delivery.DeviceTokenID)
		}
	}
}

func TestFanoutRequestSkipsPushForDisabledNotificationCategory(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()
	requestID := uuid.New()
	deviceID := uuid.New()

	uc.repo.requests[requestID] = &model.NotificationRequest{
		ID:               requestID,
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "activity",
		Priority:         model.PriorityHigh,
		Payload:          model.NotificationPayload{Title: "Activity update"},
	}
	uc.repo.devices[deviceID] = &model.DeviceToken{
		ID:          deviceID,
		UserID:      userID,
		Platform:    model.PlatformAndroid,
		Provider:    model.ProviderFCM,
		Environment: model.EnvironmentProduction,
		Token:       "fcm-token",
		Enabled:     true,
	}
	uc.repo.preferences[userID] = model.NotificationPreferences{
		UserID:           userID,
		PushEnabled:      true,
		ActivityEnabled:  false,
		ExcursionEnabled: true,
		ChatEnabled:      true,
		MarketingEnabled: false,
	}

	created, err := uc.FanoutRequest(context.Background(), requestID)
	if err != nil {
		t.Fatalf("FanoutRequest returned error: %v", err)
	}

	if created != 0 {
		t.Fatalf("expected no deliveries when activity push is disabled, got %d", created)
	}
	if uc.publisher.publishCount != 0 {
		t.Fatalf("expected no delivery publishes, got %d", uc.publisher.publishCount)
	}
}

func TestFanoutRequestQuietHoursSuppressNormalButNotHighPriorityPush(t *testing.T) {
	uc := newTestUseCase()
	userID := uuid.New()
	deviceID := uuid.New()
	normalRequestID := uuid.New()
	highRequestID := uuid.New()
	uc.now = time.Date(2026, 5, 31, 22, 30, 0, 0, time.UTC)
	uc.NotificationUseCase.now = func() time.Time { return uc.now }

	uc.repo.requests[normalRequestID] = &model.NotificationRequest{
		ID:               normalRequestID,
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "excursion",
		Priority:         model.PriorityNormal,
		Payload:          model.NotificationPayload{Title: "Normal reminder"},
	}
	uc.repo.requests[highRequestID] = &model.NotificationRequest{
		ID:               highRequestID,
		RecipientUserIDs: []uuid.UUID{userID},
		Category:         "excursion",
		Priority:         model.PriorityHigh,
		Payload:          model.NotificationPayload{Title: "Critical reminder"},
	}
	uc.repo.devices[deviceID] = &model.DeviceToken{
		ID:          deviceID,
		UserID:      userID,
		Platform:    model.PlatformAndroid,
		Provider:    model.ProviderFCM,
		Environment: model.EnvironmentProduction,
		Token:       "fcm-token",
		Enabled:     true,
	}
	uc.repo.preferences[userID] = model.NotificationPreferences{
		UserID:                 userID,
		PushEnabled:            true,
		ActivityEnabled:        true,
		ExcursionEnabled:       true,
		ChatEnabled:            true,
		MarketingEnabled:       false,
		QuietHoursEnabled:      true,
		QuietHoursStartMinutes: 22 * 60,
		QuietHoursEndMinutes:   8 * 60,
		Timezone:               "UTC",
	}

	normalCreated, err := uc.FanoutRequest(context.Background(), normalRequestID)
	if err != nil {
		t.Fatalf("normal FanoutRequest returned error: %v", err)
	}
	highCreated, err := uc.FanoutRequest(context.Background(), highRequestID)
	if err != nil {
		t.Fatalf("high FanoutRequest returned error: %v", err)
	}

	if normalCreated != 0 {
		t.Fatalf("expected quiet hours to suppress normal priority push, got %d", normalCreated)
	}
	if highCreated != 1 {
		t.Fatalf("expected high priority push to bypass quiet hours, got %d", highCreated)
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
	reads       map[uuid.UUID]map[uuid.UUID]time.Time
	preferences map[uuid.UUID]model.NotificationPreferences
}

func newMemoryRepository() *memoryRepository {
	return &memoryRepository{
		devices:     make(map[uuid.UUID]*model.DeviceToken),
		requests:    make(map[uuid.UUID]*model.NotificationRequest),
		idempotency: make(map[string]uuid.UUID),
		deliveries:  make(map[uuid.UUID]*model.Delivery),
		invalidated: make(map[uuid.UUID]bool),
		reads:       make(map[uuid.UUID]map[uuid.UUID]time.Time),
		preferences: make(map[uuid.UUID]model.NotificationPreferences),
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

func (r *memoryRepository) DeactivateDeviceTokensBySession(
	ctx context.Context,
	userID uuid.UUID,
	sessionID string,
	reason string,
) (int, error) {
	count := 0
	for _, device := range r.devices {
		if device.UserID != userID || !device.Enabled {
			continue
		}
		if device.SessionID != sessionID && device.SessionID != "" {
			continue
		}
		device.Enabled = false
		device.InvalidationReason = reason
		count++
	}
	return count, nil
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

func (r *memoryRepository) ListUserNotificationCategorySummaries(
	ctx context.Context,
	userID uuid.UUID,
	limit int,
) ([]model.NotificationCategorySummary, error) {
	byCategory := make(map[string]*model.NotificationCategorySummary)
	for _, request := range r.requests {
		if !requestRecipientContains(request, userID) {
			continue
		}
		category := normalizeCategory(request.Category)
		readAt, hasReadAt := r.readAt(userID, request.ID)
		notification := userNotificationFromRequest(request, readAt, hasReadAt)
		summary, ok := byCategory[category]
		if !ok {
			byCategory[category] = &model.NotificationCategorySummary{
				Category: category,
				Latest:   notification,
			}
			summary = byCategory[category]
		}
		summary.TotalCount++
		if notification.ReadAt == nil {
			summary.UnreadCount++
		}
		if notification.CreatedAt.After(summary.Latest.CreatedAt) ||
			(notification.CreatedAt.Equal(summary.Latest.CreatedAt) && notification.ID.String() > summary.Latest.ID.String()) {
			summary.Latest = notification
		}
	}

	summaries := make([]model.NotificationCategorySummary, 0, len(byCategory))
	for _, summary := range byCategory {
		summaries = append(summaries, *summary)
	}
	sort.Slice(summaries, func(i, j int) bool {
		left := summaries[i].Latest
		right := summaries[j].Latest
		if left.CreatedAt.Equal(right.CreatedAt) {
			return left.ID.String() > right.ID.String()
		}
		return left.CreatedAt.After(right.CreatedAt)
	})
	if limit > 0 && len(summaries) > limit {
		summaries = summaries[:limit]
	}
	return summaries, nil
}

func (r *memoryRepository) ListUserNotifications(
	ctx context.Context,
	userID uuid.UUID,
	category string,
	limit int,
	offset int,
) ([]model.UserNotification, error) {
	notifications := make([]model.UserNotification, 0)
	for _, request := range r.requests {
		if !requestRecipientContains(request, userID) {
			continue
		}
		if normalizeCategory(request.Category) != category {
			continue
		}
		readAt, hasReadAt := r.readAt(userID, request.ID)
		notifications = append(
			notifications,
			userNotificationFromRequest(request, readAt, hasReadAt),
		)
	}
	sort.Slice(notifications, func(i, j int) bool {
		if notifications[i].CreatedAt.Equal(notifications[j].CreatedAt) {
			return notifications[i].ID.String() > notifications[j].ID.String()
		}
		return notifications[i].CreatedAt.After(notifications[j].CreatedAt)
	})
	if offset >= len(notifications) {
		return []model.UserNotification{}, nil
	}
	notifications = notifications[offset:]
	if limit > 0 && len(notifications) > limit {
		notifications = notifications[:limit]
	}
	return notifications, nil
}

func (r *memoryRepository) MarkUserNotificationsRead(
	ctx context.Context,
	userID uuid.UUID,
	category string,
) (int, error) {
	updated := 0
	for _, request := range r.requests {
		if !requestRecipientContains(request, userID) {
			continue
		}
		if normalizeCategory(request.Category) != category {
			continue
		}
		if r.isRead(userID, request.ID) {
			continue
		}
		r.markRead(userID, request.ID, time.Now().UTC())
		updated++
	}
	return updated, nil
}

func (r *memoryRepository) GetNotificationPreferences(
	ctx context.Context,
	userID uuid.UUID,
) (*model.NotificationPreferences, error) {
	if preferences, ok := r.preferences[userID]; ok {
		return &preferences, nil
	}
	defaults := model.DefaultNotificationPreferences(userID)
	return &defaults, nil
}

func (r *memoryRepository) UpsertNotificationPreferences(
	ctx context.Context,
	preferences model.NotificationPreferences,
) (*model.NotificationPreferences, error) {
	preferences.Normalize()
	r.preferences[preferences.UserID] = preferences
	return &preferences, nil
}

func (r *memoryRepository) ListNotificationPreferences(
	ctx context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]model.NotificationPreferences, error) {
	result := make(map[uuid.UUID]model.NotificationPreferences, len(userIDs))
	for _, userID := range userIDs {
		if userID == uuid.Nil {
			continue
		}
		preferences, ok := r.preferences[userID]
		if !ok {
			preferences = model.DefaultNotificationPreferences(userID)
		}
		result[userID] = preferences
	}
	return result, nil
}

func (r *memoryRepository) markRead(userID uuid.UUID, requestID uuid.UUID, readAt time.Time) {
	if r.reads[userID] == nil {
		r.reads[userID] = make(map[uuid.UUID]time.Time)
	}
	r.reads[userID][requestID] = readAt
}

func (r *memoryRepository) isRead(userID uuid.UUID, requestID uuid.UUID) bool {
	_, ok := r.readAt(userID, requestID)
	return ok
}

func (r *memoryRepository) readAt(userID uuid.UUID, requestID uuid.UUID) (*time.Time, bool) {
	userReads := r.reads[userID]
	if userReads == nil {
		return nil, false
	}
	readAt, ok := userReads[requestID]
	if !ok {
		return nil, false
	}
	return &readAt, true
}

func requestRecipientContains(request *model.NotificationRequest, userID uuid.UUID) bool {
	for _, recipientID := range request.RecipientUserIDs {
		if recipientID == userID {
			return true
		}
	}
	return false
}

func userNotificationFromRequest(
	request *model.NotificationRequest,
	readAt *time.Time,
	_ bool,
) model.UserNotification {
	return model.UserNotification{
		ID:        request.ID,
		Category:  normalizeCategory(request.Category),
		Priority:  request.Priority.Normalize(),
		Payload:   request.Payload,
		CreatedAt: request.CreatedAt,
		ReadAt:    readAt,
	}
}
