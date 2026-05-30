package notification

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"kz/inflap/backend/services/token-service/internal/domain/port"
)

type Client struct {
	baseURL              string
	internalServiceToken string
	httpClient           *http.Client
}

func NewClient(baseURL string, internalServiceToken string, timeout time.Duration) *Client {
	if timeout <= 0 {
		timeout = 2 * time.Second
	}
	return &Client{
		baseURL:              strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalServiceToken: strings.TrimSpace(internalServiceToken),
		httpClient:           &http.Client{Timeout: timeout},
	}
}

func (c *Client) NotifySessionRevoked(
	ctx context.Context,
	event port.SessionRevocationNotification,
) error {
	if c == nil || c.baseURL == "" || c.internalServiceToken == "" {
		return nil
	}
	body, err := json.Marshal(map[string]string{
		"userId":    event.UserID.String(),
		"sessionId": event.SessionID.String(),
		"reason":    strings.TrimSpace(event.Reason),
	})
	if err != nil {
		return fmt.Errorf("marshal session revocation notification: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/internal/v1/notifications/sessions/revoke",
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("build notification request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Internal-Service-Token", c.internalServiceToken)
	req.Header.Set("X-Service-Name", "token-service")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call notification service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("notification service returned status %d", resp.StatusCode)
	}
	return nil
}
