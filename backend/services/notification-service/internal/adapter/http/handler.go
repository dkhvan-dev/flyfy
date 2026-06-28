package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/notification-service/internal/app"
	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

const maxInternalSendBodyBytes = 1024 * 1024

type notificationUseCase interface {
	RegisterDevice(ctx context.Context, input app.RegisterDeviceInput) (*model.DeviceToken, error)
	DeactivateDevice(ctx context.Context, userID uuid.UUID, deviceID uuid.UUID, reason string) error
	DeactivateSessionDevices(ctx context.Context, userID uuid.UUID, sessionID string, reason string) (int, error)
	ListUserNotificationCategories(ctx context.Context, userID uuid.UUID, limit int) ([]model.NotificationCategorySummary, error)
	ListUserNotifications(ctx context.Context, userID uuid.UUID, category string, limit int, offset int) ([]model.UserNotification, error)
	MarkUserNotificationsRead(ctx context.Context, userID uuid.UUID, category string) (int, error)
	MarkUserNotificationRead(ctx context.Context, userID uuid.UUID, notificationID uuid.UUID) (int, error)
	GetNotificationPreferences(ctx context.Context, userID uuid.UUID) (*model.NotificationPreferences, error)
	UpdateNotificationPreferences(ctx context.Context, userID uuid.UUID, params model.UpdateNotificationPreferencesParams) (*model.NotificationPreferences, error)
	SendNotification(ctx context.Context, input app.SendNotificationInput) (*model.NotificationRequest, error)
}

type Handler struct {
	useCase              notificationUseCase
	internalServiceToken string
}

func NewHandler(useCase notificationUseCase, internalServiceToken string) *Handler {
	return &Handler{
		useCase:              useCase,
		internalServiceToken: strings.TrimSpace(internalServiceToken),
	}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("POST /v1/notifications/device-tokens", h.RegisterDeviceToken)
	mux.HandleFunc("DELETE /v1/notifications/device-tokens/{deviceID}", h.DeactivateDeviceToken)
	mux.HandleFunc("GET /v1/notifications/categories", h.ListNotificationCategories)
	mux.HandleFunc("GET /v1/notifications", h.ListNotifications)
	mux.HandleFunc("POST /v1/notifications/read-all", h.MarkNotificationsRead)
	mux.HandleFunc("POST /v1/notifications/{notificationID}/read", h.MarkNotificationRead)
	mux.HandleFunc("GET /v1/notifications/preferences", h.GetNotificationPreferences)
	mux.HandleFunc("PUT /v1/notifications/preferences", h.UpdateNotificationPreferences)
	mux.HandleFunc("POST /internal/v1/notifications/send", h.SendInternalNotification)
	mux.HandleFunc("POST /internal/v1/notifications/sessions/revoke", h.RevokeSessionDevices)
	mux.HandleFunc("POST /v1/internal/notifications/send", h.SendInternalNotification)
	mux.HandleFunc("POST /v1/internal/notifications/sessions/revoke", h.RevokeSessionDevices)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

type registerDeviceTokenRequest struct {
	Platform             string `json:"platform"`
	Provider             string `json:"provider"`
	Environment          string `json:"environment"`
	SessionID            string `json:"sessionId"`
	DeviceInstallationID string `json:"deviceInstallationId"`
	Token                string `json:"token"`
	AppBundleID          string `json:"appBundleId"`
	AppVersion           string `json:"appVersion"`
	DeviceModel          string `json:"deviceModel"`
	Manufacturer         string `json:"manufacturer"`
	Locale               string `json:"locale"`
	Timezone             string `json:"timezone"`
}

type deviceTokenResponse struct {
	ID           string `json:"id"`
	Platform     string `json:"platform"`
	Provider     string `json:"provider"`
	Environment  string `json:"environment"`
	AppBundleID  string `json:"appBundleId"`
	AppVersion   string `json:"appVersion"`
	Enabled      bool   `json:"enabled"`
	LastSeenAt   string `json:"lastSeenAt"`
	RegisteredAt string `json:"registeredAt"`
}

func (h *Handler) RegisterDeviceToken(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "request must come through trusted gateway")
		return
	}
	userID, ok := authenticatedUserID(w, r)
	if !ok {
		return
	}
	var req registerDeviceTokenRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}

	device, err := h.useCase.RegisterDevice(r.Context(), app.RegisterDeviceInput{
		UserID:               userID,
		Platform:             model.Platform(strings.TrimSpace(req.Platform)),
		Provider:             model.Provider(strings.TrimSpace(req.Provider)),
		Environment:          model.Environment(strings.TrimSpace(req.Environment)),
		SessionID:            req.SessionID,
		DeviceInstallationID: req.DeviceInstallationID,
		Token:                req.Token,
		AppBundleID:          req.AppBundleID,
		AppVersion:           req.AppVersion,
		DeviceModel:          req.DeviceModel,
		Manufacturer:         req.Manufacturer,
		Locale:               req.Locale,
		Timezone:             req.Timezone,
	})
	if err != nil {
		writeAppError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, toDeviceTokenResponse(device))
}

func (h *Handler) DeactivateDeviceToken(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "request must come through trusted gateway")
		return
	}
	userID, ok := authenticatedUserID(w, r)
	if !ok {
		return
	}
	deviceID, err := uuid.Parse(strings.TrimSpace(r.PathValue("deviceID")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid device id")
		return
	}
	if err = h.useCase.DeactivateDevice(r.Context(), userID, deviceID, "user_deleted"); err != nil {
		writeAppError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type revokeSessionDevicesRequest struct {
	UserID    string `json:"userId"`
	SessionID string `json:"sessionId"`
	Reason    string `json:"reason"`
}

func (h *Handler) RevokeSessionDevices(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "missing internal service token")
		return
	}
	if strings.TrimSpace(r.Header.Get("X-Service-Name")) == "" {
		writeError(w, http.StatusUnauthorized, "missing internal service identity")
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, maxInternalSendBodyBytes)
	var req revokeSessionDevicesRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}
	userID, err := uuid.Parse(strings.TrimSpace(req.UserID))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}
	deactivated, err := h.useCase.DeactivateSessionDevices(
		r.Context(),
		userID,
		req.SessionID,
		req.Reason,
	)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"deactivatedCount": deactivated})
}

type userNotificationResponse struct {
	ID        string            `json:"id"`
	Category  string            `json:"category"`
	Priority  string            `json:"priority"`
	Title     string            `json:"title"`
	Body      string            `json:"body"`
	ImageURL  string            `json:"imageUrl"`
	DeepLink  string            `json:"deepLink"`
	Data      map[string]string `json:"data"`
	CreatedAt string            `json:"createdAt"`
	ReadAt    *string           `json:"readAt"`
}

type notificationCategorySummaryResponse struct {
	Category    string                   `json:"category"`
	UnreadCount int                      `json:"unreadCount"`
	TotalCount  int                      `json:"totalCount"`
	Latest      userNotificationResponse `json:"latest"`
}

type markNotificationsReadRequest struct {
	Category string `json:"category"`
}

type notificationPreferencesResponse struct {
	PushEnabled            bool   `json:"pushEnabled"`
	ActivityEnabled        bool   `json:"activityEnabled"`
	ExcursionEnabled       bool   `json:"excursionEnabled"`
	ChatEnabled            bool   `json:"chatEnabled"`
	MarketingEnabled       bool   `json:"marketingEnabled"`
	QuietHoursEnabled      bool   `json:"quietHoursEnabled"`
	QuietHoursStartMinutes int    `json:"quietHoursStartMinutes"`
	QuietHoursEndMinutes   int    `json:"quietHoursEndMinutes"`
	Timezone               string `json:"timezone"`
}

type updateNotificationPreferencesRequest struct {
	PushEnabled            *bool   `json:"pushEnabled,omitempty"`
	ActivityEnabled        *bool   `json:"activityEnabled,omitempty"`
	ExcursionEnabled       *bool   `json:"excursionEnabled,omitempty"`
	ChatEnabled            *bool   `json:"chatEnabled,omitempty"`
	MarketingEnabled       *bool   `json:"marketingEnabled,omitempty"`
	QuietHoursEnabled      *bool   `json:"quietHoursEnabled,omitempty"`
	QuietHoursStartMinutes *int    `json:"quietHoursStartMinutes,omitempty"`
	QuietHoursEndMinutes   *int    `json:"quietHoursEndMinutes,omitempty"`
	Timezone               *string `json:"timezone,omitempty"`
}

func (h *Handler) ListNotificationCategories(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "request must come through trusted gateway")
		return
	}
	userID, ok := authenticatedUserID(w, r)
	if !ok {
		return
	}
	limit, ok := parseIntQuery(w, r, "limit")
	if !ok {
		return
	}
	categories, err := h.useCase.ListUserNotificationCategories(r.Context(), userID, limit)
	if err != nil {
		writeAppError(w, err)
		return
	}
	response := make([]notificationCategorySummaryResponse, 0, len(categories))
	for _, category := range categories {
		response = append(response, toNotificationCategorySummaryResponse(category))
	}
	writeJSON(w, http.StatusOK, map[string]any{"categories": response})
}

func (h *Handler) ListNotifications(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "request must come through trusted gateway")
		return
	}
	userID, ok := authenticatedUserID(w, r)
	if !ok {
		return
	}
	limit, ok := parseIntQuery(w, r, "limit")
	if !ok {
		return
	}
	offset, ok := parseIntQuery(w, r, "offset")
	if !ok {
		return
	}
	notifications, err := h.useCase.ListUserNotifications(
		r.Context(),
		userID,
		r.URL.Query().Get("category"),
		limit,
		offset,
	)
	if err != nil {
		writeAppError(w, err)
		return
	}
	response := make([]userNotificationResponse, 0, len(notifications))
	for _, notification := range notifications {
		response = append(response, toUserNotificationResponse(notification))
	}
	writeJSON(w, http.StatusOK, map[string]any{"notifications": response})
}

func (h *Handler) MarkNotificationsRead(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "request must come through trusted gateway")
		return
	}
	userID, ok := authenticatedUserID(w, r)
	if !ok {
		return
	}
	var req markNotificationsReadRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}
	updated, err := h.useCase.MarkUserNotificationsRead(r.Context(), userID, req.Category)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"updatedCount": updated})
}

func (h *Handler) MarkNotificationRead(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "request must come through trusted gateway")
		return
	}
	userID, ok := authenticatedUserID(w, r)
	if !ok {
		return
	}
	notificationID, err := uuid.Parse(strings.TrimSpace(r.PathValue("notificationID")))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid notification id")
		return
	}
	updated, err := h.useCase.MarkUserNotificationRead(r.Context(), userID, notificationID)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"updatedCount": updated})
}

func (h *Handler) GetNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "request must come through trusted gateway")
		return
	}
	userID, ok := authenticatedUserID(w, r)
	if !ok {
		return
	}
	preferences, err := h.useCase.GetNotificationPreferences(r.Context(), userID)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, toNotificationPreferencesResponse(preferences))
}

func (h *Handler) UpdateNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "request must come through trusted gateway")
		return
	}
	userID, ok := authenticatedUserID(w, r)
	if !ok {
		return
	}
	var req updateNotificationPreferencesRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}
	preferences, err := h.useCase.UpdateNotificationPreferences(
		r.Context(),
		userID,
		model.UpdateNotificationPreferencesParams{
			PushEnabled:            req.PushEnabled,
			ActivityEnabled:        req.ActivityEnabled,
			ExcursionEnabled:       req.ExcursionEnabled,
			ChatEnabled:            req.ChatEnabled,
			MarketingEnabled:       req.MarketingEnabled,
			QuietHoursEnabled:      req.QuietHoursEnabled,
			QuietHoursStartMinutes: req.QuietHoursStartMinutes,
			QuietHoursEndMinutes:   req.QuietHoursEndMinutes,
			Timezone:               req.Timezone,
		},
	)
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, toNotificationPreferencesResponse(preferences))
}

type sendNotificationRequest struct {
	IdempotencyKey   string            `json:"idempotencyKey"`
	SourceService    string            `json:"sourceService"`
	RecipientUserIDs []string          `json:"recipientUserIds"`
	Category         string            `json:"category"`
	Priority         string            `json:"priority"`
	Title            string            `json:"title"`
	Body             string            `json:"body"`
	ImageURL         string            `json:"imageUrl"`
	DeepLink         string            `json:"deepLink"`
	Data             map[string]string `json:"data"`
	CollapseKey      string            `json:"collapseKey"`
	TTLSeconds       int64             `json:"ttlSeconds"`
}

func (h *Handler) SendInternalNotification(w http.ResponseWriter, r *http.Request) {
	if !h.isInternalRequest(r) {
		writeError(w, http.StatusUnauthorized, "missing internal service token")
		return
	}
	sourceService := strings.TrimSpace(r.Header.Get("X-Service-Name"))
	if sourceService == "" {
		writeError(w, http.StatusUnauthorized, "missing internal service identity")
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, maxInternalSendBodyBytes)
	var req sendNotificationRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}
	if req.SourceService != "" && strings.TrimSpace(req.SourceService) != sourceService {
		writeError(w, http.StatusBadRequest, "source service does not match caller identity")
		return
	}
	recipients := make([]uuid.UUID, 0, len(req.RecipientUserIDs))
	for _, raw := range req.RecipientUserIDs {
		recipientID, err := uuid.Parse(strings.TrimSpace(raw))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid recipient user id")
			return
		}
		recipients = append(recipients, recipientID)
	}
	ttl := time.Duration(req.TTLSeconds) * time.Second
	request, err := h.useCase.SendNotification(r.Context(), app.SendNotificationInput{
		IdempotencyKey:   valueOrDefault(req.IdempotencyKey, r.Header.Get("Idempotency-Key")),
		SourceService:    sourceService,
		RecipientUserIDs: recipients,
		Category:         req.Category,
		Priority:         model.Priority(req.Priority),
		Payload: model.NotificationPayload{
			Title:       req.Title,
			Body:        req.Body,
			ImageURL:    req.ImageURL,
			DeepLink:    req.DeepLink,
			Data:        req.Data,
			CollapseKey: req.CollapseKey,
			TTL:         ttl,
		},
	})
	if err != nil {
		writeAppError(w, err)
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]any{
		"requestId": request.ID.String(),
		"status":    request.Status,
	})
}

func (h *Handler) isInternalRequest(r *http.Request) bool {
	expected := strings.TrimSpace(h.internalServiceToken)
	if expected == "" {
		return false
	}
	return strings.TrimSpace(r.Header.Get("X-Internal-Service-Token")) == expected
}

func authenticatedUserID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	userID, err := uuid.Parse(strings.TrimSpace(UserIDFromContext(r.Context())))
	if err != nil {
		writeError(w, http.StatusUnauthorized, "missing authenticated user context")
		return uuid.Nil, false
	}
	return userID, true
}

func decodeJSON(r *http.Request, dest any) error {
	defer r.Body.Close()
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	return decoder.Decode(dest)
}

func parseIntQuery(w http.ResponseWriter, r *http.Request, key string) (int, bool) {
	raw := strings.TrimSpace(r.URL.Query().Get(key))
	if raw == "" {
		return 0, true
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid "+key)
		return 0, false
	}
	return value, true
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeAppError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, model.ErrInvalidInput):
		writeError(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, model.ErrUnauthorized):
		writeError(w, http.StatusUnauthorized, "unauthorized")
	case errors.Is(err, model.ErrNotFound):
		writeError(w, http.StatusNotFound, "not found")
	default:
		writeError(w, http.StatusInternalServerError, "internal error")
	}
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func toDeviceTokenResponse(device *model.DeviceToken) deviceTokenResponse {
	return deviceTokenResponse{
		ID:           device.ID.String(),
		Platform:     string(device.Platform),
		Provider:     string(device.Provider),
		Environment:  string(device.Environment),
		AppBundleID:  device.AppBundleID,
		AppVersion:   device.AppVersion,
		Enabled:      device.Enabled,
		LastSeenAt:   device.LastSeenAt.Format(time.RFC3339),
		RegisteredAt: device.CreatedAt.Format(time.RFC3339),
	}
}

func toNotificationCategorySummaryResponse(category model.NotificationCategorySummary) notificationCategorySummaryResponse {
	return notificationCategorySummaryResponse{
		Category:    category.Category,
		UnreadCount: category.UnreadCount,
		TotalCount:  category.TotalCount,
		Latest:      toUserNotificationResponse(category.Latest),
	}
}

func toUserNotificationResponse(notification model.UserNotification) userNotificationResponse {
	var readAt *string
	if notification.ReadAt != nil {
		value := notification.ReadAt.UTC().Format(time.RFC3339)
		readAt = &value
	}
	data := notification.Payload.Data
	if data == nil {
		data = map[string]string{}
	}
	return userNotificationResponse{
		ID:        notification.ID.String(),
		Category:  notification.Category,
		Priority:  string(notification.Priority.Normalize()),
		Title:     notification.Payload.Title,
		Body:      notification.Payload.Body,
		ImageURL:  notification.Payload.ImageURL,
		DeepLink:  notification.Payload.DeepLink,
		Data:      data,
		CreatedAt: notification.CreatedAt.UTC().Format(time.RFC3339),
		ReadAt:    readAt,
	}
}

func toNotificationPreferencesResponse(preferences *model.NotificationPreferences) notificationPreferencesResponse {
	if preferences == nil {
		value := model.DefaultNotificationPreferences(uuid.Nil)
		preferences = &value
	}
	preferences.Normalize()
	return notificationPreferencesResponse{
		PushEnabled:            preferences.PushEnabled,
		ActivityEnabled:        preferences.ActivityEnabled,
		ExcursionEnabled:       preferences.ExcursionEnabled,
		ChatEnabled:            preferences.ChatEnabled,
		MarketingEnabled:       preferences.MarketingEnabled,
		QuietHoursEnabled:      preferences.QuietHoursEnabled,
		QuietHoursStartMinutes: preferences.QuietHoursStartMinutes,
		QuietHoursEndMinutes:   preferences.QuietHoursEndMinutes,
		Timezone:               preferences.Timezone,
	}
}
