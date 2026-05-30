package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
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
	mux.HandleFunc("POST /internal/v1/notifications/send", h.SendInternalNotification)
	mux.HandleFunc("POST /v1/internal/notifications/send", h.SendInternalNotification)
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

type registerDeviceTokenRequest struct {
	Platform     string `json:"platform"`
	Provider     string `json:"provider"`
	Environment  string `json:"environment"`
	Token        string `json:"token"`
	AppBundleID  string `json:"appBundleId"`
	AppVersion   string `json:"appVersion"`
	DeviceModel  string `json:"deviceModel"`
	Manufacturer string `json:"manufacturer"`
	Locale       string `json:"locale"`
	Timezone     string `json:"timezone"`
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
		UserID:       userID,
		Platform:     model.Platform(strings.TrimSpace(req.Platform)),
		Provider:     model.Provider(strings.TrimSpace(req.Provider)),
		Environment:  model.Environment(strings.TrimSpace(req.Environment)),
		Token:        req.Token,
		AppBundleID:  req.AppBundleID,
		AppVersion:   req.AppVersion,
		DeviceModel:  req.DeviceModel,
		Manufacturer: req.Manufacturer,
		Locale:       req.Locale,
		Timezone:     req.Timezone,
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
