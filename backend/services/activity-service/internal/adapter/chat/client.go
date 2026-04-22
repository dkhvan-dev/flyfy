package chat

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

func New(baseURL string, internalToken string, timeout time.Duration) *Client {
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	return &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    &http.Client{Timeout: timeout},
	}
}

func (c *Client) EnsureActivityParticipant(ctx context.Context, input port.EnsureActivityParticipantInput) error {
	if c.baseURL == "" {
		return fmt.Errorf("chat service base url is empty")
	}

	payload := struct {
		ActivityID              string `json:"activityId"`
		ActivityTitle           string `json:"activityTitle,omitempty"`
		ActivityAvatarFileID    string `json:"activityAvatarFileId,omitempty"`
		MessagingAvailableUntil string `json:"messagingAvailableUntil,omitempty"`
		HostUserID              string `json:"hostUserId"`
		UserID                  string `json:"userId"`
		DisplayName             string `json:"displayName,omitempty"`
	}{
		ActivityID:              input.ActivityID.String(),
		ActivityTitle:           input.ActivityTitle,
		ActivityAvatarFileID:    strings.TrimSpace(input.ActivityAvatarFileID),
		MessagingAvailableUntil: formatOptionalTime(input.MessagingAvailableUntil),
		HostUserID:              input.HostUserID.String(),
		UserID:                  input.UserID.String(),
		DisplayName:             input.DisplayName,
	}

	return c.postJSON(ctx, "/v1/internal/activity-conversations/participants", payload)
}

func (c *Client) SyncActivityConversation(ctx context.Context, input port.SyncActivityConversationInput) error {
	if c.baseURL == "" {
		return fmt.Errorf("chat service base url is empty")
	}

	payload := struct {
		ActivityID              string `json:"activityId"`
		ActivityTitle           string `json:"activityTitle,omitempty"`
		ActivityAvatarFileID    string `json:"activityAvatarFileId,omitempty"`
		MessagingAvailableUntil string `json:"messagingAvailableUntil,omitempty"`
	}{
		ActivityID:              input.ActivityID.String(),
		ActivityTitle:           input.ActivityTitle,
		ActivityAvatarFileID:    strings.TrimSpace(input.ActivityAvatarFileID),
		MessagingAvailableUntil: formatOptionalTime(input.MessagingAvailableUntil),
	}

	return c.postJSON(ctx, "/v1/internal/activity-conversations/sync", payload)
}

func (c *Client) postJSON(ctx context.Context, path string, payload any) error {
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal chat payload: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+path,
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("create chat request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Internal-Service-Token", c.internalToken)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call chat service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= http.StatusOK && resp.StatusCode < http.StatusMultipleChoices {
		return nil
	}

	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	return fmt.Errorf("chat service returned %d: %s", resp.StatusCode, strings.TrimSpace(string(respBody)))
}

func formatOptionalTime(value *time.Time) string {
	if value == nil || value.IsZero() {
		return ""
	}
	return value.UTC().Format(time.RFC3339)
}
