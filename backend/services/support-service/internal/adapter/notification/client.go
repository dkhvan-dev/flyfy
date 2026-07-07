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

	"kz/inflap/backend/services/support-service/internal/app"
)

type Client struct {
	baseURL         string
	internalToken   string
	serviceName     string
	operatorUserIDs []string
	httpClient      *http.Client
}

type Option func(*Client)

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

func New(baseURL string, internalToken string, serviceName string, operatorUserIDs []string, timeout time.Duration, opts ...Option) *Client {
	if timeout <= 0 {
		timeout = 3 * time.Second
	}
	client := &Client{
		baseURL:         strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken:   strings.TrimSpace(internalToken),
		serviceName:     strings.TrimSpace(serviceName),
		operatorUserIDs: normalizeOperatorUserIDs(operatorUserIDs),
		httpClient:      &http.Client{Timeout: timeout},
	}
	for _, opt := range opts {
		if opt != nil {
			opt(client)
		}
	}
	return client
}

func (c *Client) NotifySupportOperators(ctx context.Context, input app.SupportOperatorNotificationInput) error {
	if c.baseURL == "" {
		return fmt.Errorf("notification service base url is empty")
	}
	if len(c.operatorUserIDs) == 0 {
		return nil
	}

	return c.sendNotification(ctx, notificationPayload{
		IdempotencyKey:   input.IdempotencyKey,
		SourceService:    c.serviceName,
		RecipientUserIDs: c.operatorUserIDs,
		Category:         input.Category,
		Priority:         input.Priority,
		Title:            input.Title,
		Body:             input.Body,
		DeepLink:         input.DeepLink,
		Data:             input.Data,
		CollapseKey:      input.CollapseKey,
		TTLSeconds:       int64(input.TTL.Seconds()),
	}, "support operator")
}

func (c *Client) NotifySupportUser(ctx context.Context, userID string, input app.SupportUserNotificationInput) error {
	if c.baseURL == "" {
		return fmt.Errorf("notification service base url is empty")
	}
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return fmt.Errorf("notification recipient user id is empty")
	}

	return c.sendNotification(ctx, notificationPayload{
		IdempotencyKey:   input.IdempotencyKey,
		SourceService:    c.serviceName,
		RecipientUserIDs: []string{userID},
		Category:         input.Category,
		Priority:         input.Priority,
		Title:            input.Title,
		Body:             input.Body,
		DeepLink:         input.DeepLink,
		Data:             input.Data,
		CollapseKey:      input.CollapseKey,
		TTLSeconds:       int64(input.TTL.Seconds()),
	}, "support user")
}

type notificationPayload struct {
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
}

func (c *Client) sendNotification(ctx context.Context, payload notificationPayload, subject string) error {
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal %s notification: %w", subject, err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/internal/v1/notifications/send",
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("create %s notification request: %w", subject, err)
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

func normalizeOperatorUserIDs(input []string) []string {
	out := make([]string, 0, len(input))
	seen := make(map[string]struct{}, len(input))
	for _, item := range input {
		item = strings.TrimSpace(item)
		if item == "" {
			continue
		}
		if _, ok := seen[item]; ok {
			continue
		}
		seen[item] = struct{}{}
		out = append(out, item)
	}
	return out
}

var _ app.SupportOperatorNotifier = (*Client)(nil)
var _ app.SupportUserNotifier = (*Client)(nil)
