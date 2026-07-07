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

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

type Client struct {
	baseURL       string
	internalToken string
	serviceName   string
	httpClient    *http.Client
}

type Option func(*Client)

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

func New(baseURL string, internalToken string, serviceName string, timeout time.Duration, opts ...Option) *Client {
	if timeout <= 0 {
		timeout = 3 * time.Second
	}
	client := &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		serviceName:   strings.TrimSpace(serviceName),
		httpClient:    &http.Client{Timeout: timeout},
	}
	for _, opt := range opts {
		if opt != nil {
			opt(client)
		}
	}
	return client
}

func (c *Client) SendUserNotification(ctx context.Context, input port.UserNotificationInput) error {
	if c.baseURL == "" {
		return fmt.Errorf("notification service base url is empty")
	}

	recipientUserIDs := make([]string, 0, len(input.RecipientUserIDs))
	for _, userID := range input.RecipientUserIDs {
		if userID == uuid.Nil {
			continue
		}
		recipientUserIDs = append(recipientUserIDs, userID.String())
	}
	if len(recipientUserIDs) == 0 {
		return nil
	}

	payload := struct {
		IdempotencyKey   string            `json:"idempotencyKey"`
		SourceService    string            `json:"sourceService,omitempty"`
		RecipientUserIDs []string          `json:"recipientUserIds"`
		Category         string            `json:"category"`
		Priority         string            `json:"priority"`
		Title            string            `json:"title"`
		Body             string            `json:"body"`
		DeepLink         string            `json:"deepLink,omitempty"`
		Data             map[string]string `json:"data,omitempty"`
		CollapseKey      string            `json:"collapseKey,omitempty"`
		TTLSeconds       int64             `json:"ttlSeconds,omitempty"`
	}{
		IdempotencyKey:   input.IdempotencyKey,
		SourceService:    c.serviceName,
		RecipientUserIDs: recipientUserIDs,
		Category:         input.Category,
		Priority:         input.Priority,
		Title:            input.Title,
		Body:             input.Body,
		DeepLink:         input.DeepLink,
		Data:             input.Data,
		CollapseKey:      input.CollapseKey,
		TTLSeconds:       int64(input.TTL.Seconds()),
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal admin user notification: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/internal/v1/notifications/send",
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("create admin user notification request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Internal-Service-Token", c.internalToken)
	req.Header.Set("X-Service-Name", c.serviceName)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call notification service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= http.StatusOK && resp.StatusCode < http.StatusMultipleChoices {
		return nil
	}

	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	return fmt.Errorf(
		"notification service returned %d: %s",
		resp.StatusCode,
		strings.TrimSpace(string(respBody)),
	)
}

var _ port.UserNotificationGateway = (*Client)(nil)
