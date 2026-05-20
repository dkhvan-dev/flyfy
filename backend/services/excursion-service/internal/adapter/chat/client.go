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

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
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

func (c *Client) SyncExcursionScheduleSlotConversation(
	ctx context.Context,
	input port.SyncExcursionScheduleSlotConversationInput,
) error {
	if c.baseURL == "" {
		return fmt.Errorf("chat service base url is empty")
	}

	participantUserIDs := make([]string, 0, len(input.ParticipantUserIDs))
	for _, userID := range input.ParticipantUserIDs {
		participantUserIDs = append(participantUserIDs, userID.String())
	}
	payload := struct {
		ScheduleSlotID          string   `json:"scheduleSlotId"`
		ExcursionTitle          string   `json:"excursionTitle,omitempty"`
		ExcursionAvatarFileID   string   `json:"excursionAvatarFileId,omitempty"`
		MessagingAvailableUntil string   `json:"messagingAvailableUntil,omitempty"`
		GuideUserID             string   `json:"guideUserId"`
		ParticipantUserIDs      []string `json:"participantUserIds,omitempty"`
	}{
		ScheduleSlotID:          input.ScheduleSlotID.String(),
		ExcursionTitle:          input.ExcursionTitle,
		ExcursionAvatarFileID:   strings.TrimSpace(input.ExcursionAvatarFileID),
		MessagingAvailableUntil: formatOptionalTime(input.MessagingAvailableUntil),
		GuideUserID:             input.GuideUserID.String(),
		ParticipantUserIDs:      participantUserIDs,
	}

	return c.postJSON(ctx, "/v1/internal/excursion-schedule-slot-conversations/sync", payload)
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
