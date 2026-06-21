package notification

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"kz/inflap/backend/services/checklist-service/internal/app"
)

type HTTPSenderConfig struct {
	BaseURL              string
	InternalServiceToken string
	SourceService        string
	Timeout              time.Duration
	HTTPClient           *http.Client
}

type HTTPSender struct {
	client               *http.Client
	endpoint             string
	internalServiceToken string
	sourceService        string
}

func NewHTTPSender(config HTTPSenderConfig) (*HTTPSender, error) {
	baseURL := strings.TrimRight(strings.TrimSpace(config.BaseURL), "/")
	token := strings.TrimSpace(config.InternalServiceToken)
	if baseURL == "" {
		return nil, fmt.Errorf("notification service base URL is required")
	}
	if token == "" {
		return nil, fmt.Errorf("notification internal service token is required")
	}

	timeout := config.Timeout
	if timeout <= 0 {
		timeout = 3 * time.Second
	}
	client := config.HTTPClient
	if client == nil {
		client = &http.Client{Timeout: timeout}
	}

	sourceService := strings.TrimSpace(config.SourceService)
	if sourceService == "" {
		sourceService = "checklist-service"
	}

	return &HTTPSender{
		client:               client,
		endpoint:             baseURL + "/internal/v1/notifications/send",
		internalServiceToken: token,
		sourceService:        sourceService,
	}, nil
}

type sendNotificationRequest struct {
	IdempotencyKey   string            `json:"idempotencyKey"`
	SourceService    string            `json:"sourceService"`
	RecipientUserIDs []string          `json:"recipientUserIds"`
	Category         string            `json:"category"`
	Priority         string            `json:"priority"`
	Title            string            `json:"title"`
	Body             string            `json:"body"`
	DeepLink         string            `json:"deepLink"`
	Data             map[string]string `json:"data"`
	CollapseKey      string            `json:"collapseKey"`
	TTLSeconds       int64             `json:"ttlSeconds"`
}

func (s *HTTPSender) SendChecklistNotification(
	ctx context.Context,
	request app.ChecklistNotificationRequest,
) error {
	if s == nil || s.client == nil {
		return fmt.Errorf("notification sender is not configured")
	}

	payload := sendNotificationRequest{
		IdempotencyKey:   strings.TrimSpace(request.IdempotencyKey),
		SourceService:    s.sourceService,
		RecipientUserIDs: []string{strings.TrimSpace(request.RecipientUserID)},
		Category:         strings.TrimSpace(request.Category),
		Priority:         strings.TrimSpace(request.Priority),
		Title:            strings.TrimSpace(request.Title),
		Body:             strings.TrimSpace(request.Body),
		DeepLink:         strings.TrimSpace(request.DeepLink),
		Data:             request.Data,
		CollapseKey:      strings.TrimSpace(request.CollapseKey),
		TTLSeconds:       int64(request.TTL / time.Second),
	}
	if payload.TTLSeconds <= 0 {
		payload.TTLSeconds = int64((24 * time.Hour) / time.Second)
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal checklist notification request: %w", err)
	}

	httpRequest, err := http.NewRequestWithContext(ctx, http.MethodPost, s.endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("build checklist notification request: %w", err)
	}
	httpRequest.Header.Set("Content-Type", "application/json")
	httpRequest.Header.Set("X-Internal-Service-Token", s.internalServiceToken)
	httpRequest.Header.Set("X-Service-Name", s.sourceService)
	httpRequest.Header.Set("Idempotency-Key", payload.IdempotencyKey)

	response, err := s.client.Do(httpRequest)
	if err != nil {
		return fmt.Errorf("send checklist notification: %w", err)
	}
	defer response.Body.Close()

	if response.StatusCode >= http.StatusOK && response.StatusCode < http.StatusMultipleChoices {
		return nil
	}
	responseBody, _ := io.ReadAll(io.LimitReader(response.Body, 4096))
	return fmt.Errorf("send checklist notification: notification-service status %d: %s", response.StatusCode, strings.TrimSpace(string(responseBody)))
}
