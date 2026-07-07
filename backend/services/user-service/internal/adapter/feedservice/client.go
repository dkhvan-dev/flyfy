package feedservice

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"kz/inflap/backend/services/user-service/internal/domain/model"
)

type Client struct {
	baseURL        string
	internalToken  string
	serviceID      string
	requestTimeout time.Duration
	httpClient     *http.Client
}

type Option func(*Client)

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		if httpClient != nil {
			c.httpClient = httpClient
		}
	}
}

func New(baseURL string, internalToken string, serviceID string, requestTimeout time.Duration, options ...Option) *Client {
	if requestTimeout <= 0 {
		requestTimeout = 3 * time.Second
	}
	client := &Client{
		baseURL:        strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken:  strings.TrimSpace(internalToken),
		serviceID:      strings.TrimSpace(serviceID),
		requestTimeout: requestTimeout,
		httpClient: &http.Client{
			Timeout: requestTimeout,
		},
	}
	for _, option := range options {
		option(client)
	}
	return client
}

func (c *Client) PublishUserSocialEvent(ctx context.Context, event model.UserSocialOutboxEvent) error {
	if c == nil || c.baseURL == "" {
		return fmt.Errorf("feed-service client is not configured")
	}
	payload := feedSocialEventRequest{
		EventID:         event.ID.String(),
		ViewerUserID:    event.ViewerUserID.String(),
		TargetUserID:    event.TargetUserID.String(),
		EdgeType:        event.EdgeType,
		Active:          event.Active,
		SourceUpdatedAt: event.SourceUpdatedAt.UTC().Format(time.RFC3339Nano),
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal feed social event: %w", err)
	}

	reqCtx, cancel := context.WithTimeout(ctx, c.requestTimeout)
	defer cancel()

	req, err := http.NewRequestWithContext(
		reqCtx,
		http.MethodPost,
		c.baseURL+"/internal/v1/feed/social-events",
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("build feed social event request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Internal-Service-Token", c.internalToken)
	if c.serviceID != "" {
		req.Header.Set("X-Source-Service", c.serviceID)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("send feed social event: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		snippet, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return fmt.Errorf("feed social event status %d: %s", resp.StatusCode, strings.TrimSpace(string(snippet)))
	}
	return nil
}

type feedSocialEventRequest struct {
	EventID         string `json:"eventId"`
	ViewerUserID    string `json:"viewerUserId"`
	TargetUserID    string `json:"targetUserId"`
	EdgeType        string `json:"edgeType"`
	Active          bool   `json:"active"`
	SourceUpdatedAt string `json:"sourceUpdatedAt"`
}
