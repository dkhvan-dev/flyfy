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

	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

const (
	chatCategory          = "chat"
	chatPriority          = "normal"
	chatNotificationTTL   = 24 * time.Hour
	defaultSenderTitle    = "Inflap"
	defaultMessageBody    = "New message"
	internalSendPath      = "/internal/v1/notifications/send"
	internalTokenHeader   = "X-Internal-Service-Token"
	internalServiceHeader = "X-Service-Name"
)

type Client struct {
	baseURL       string
	internalToken string
	serviceName   string
	httpClient    *http.Client
}

var _ port.ChatNotificationSender = (*Client)(nil)

func NewClient(baseURL string, internalToken string, serviceName string, httpClient *http.Client) *Client {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 2 * time.Second}
	}
	return &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		serviceName:   strings.TrimSpace(serviceName),
		httpClient:    httpClient,
	}
}

func (c *Client) SendChatMessageNotification(
	ctx context.Context,
	notification port.ChatNotification,
) error {
	if len(notification.RecipientUserIDs) == 0 {
		return nil
	}
	if c == nil || c.baseURL == "" || c.httpClient == nil {
		return fmt.Errorf("notification client is not configured")
	}
	if notification.ConversationID == uuid.Nil || notification.MessageID == uuid.Nil || notification.SenderUserID == uuid.Nil {
		return fmt.Errorf("chat notification requires conversation, message and sender ids")
	}
	serviceName := c.serviceName
	if serviceName == "" {
		serviceName = "chat-service"
	}

	data := map[string]string{
		"type":           notificationEventType(notification),
		"conversationId": notification.ConversationID.String(),
		"messageId":      notification.MessageID.String(),
		"senderUserId":   notification.SenderUserID.String(),
		"actorUserId":    notification.SenderUserID.String(),
		"chatType":       strings.TrimSpace(notification.ConversationType),
		"messageType":    strings.TrimSpace(notification.MessageType),
	}
	if reactionEmoji := strings.TrimSpace(notification.ReactionEmoji); reactionEmoji != "" {
		data["reactionEmoji"] = reactionEmoji
	}

	requestPayload := sendNotificationRequest{
		IdempotencyKey:   idempotencyKey(notification),
		SourceService:    serviceName,
		RecipientUserIDs: stringifyUUIDs(notification.RecipientUserIDs),
		Category:         chatCategory,
		Priority:         chatPriority,
		Title:            notificationTitle(notification),
		Body:             notificationBody(notification),
		DeepLink:         "/chats/" + notification.ConversationID.String(),
		Data:             data,
		CollapseKey:      "chat:" + notification.ConversationID.String(),
		TTLSeconds:       int64(chatNotificationTTL / time.Second),
	}

	body := bytes.NewBuffer(nil)
	if err := json.NewEncoder(body).Encode(requestPayload); err != nil {
		return fmt.Errorf("encode chat notification request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+internalSendPath, body)
	if err != nil {
		return fmt.Errorf("create chat notification request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", requestPayload.IdempotencyKey)
	req.Header.Set(internalServiceHeader, serviceName)
	if c.internalToken != "" {
		req.Header.Set(internalTokenHeader, c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call notification-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return fmt.Errorf("notification-service send failed: status=%d message=%s", resp.StatusCode, readErrorMessage(resp.Body))
	}
	return nil
}

func notificationEventType(notification port.ChatNotification) string {
	value := strings.TrimSpace(notification.EventType)
	if value != "" {
		return value
	}
	return "chat_message"
}

func idempotencyKey(notification port.ChatNotification) string {
	value := strings.TrimSpace(notification.IdempotencyKey)
	if value != "" {
		return value
	}
	return "chat-message-" + notification.MessageID.String()
}

func notificationTitle(notification port.ChatNotification) string {
	value := strings.TrimSpace(notification.SenderDisplayName)
	if value != "" {
		return value
	}
	return defaultSenderTitle
}

func notificationBody(notification port.ChatNotification) string {
	value := strings.TrimSpace(notification.Body)
	if value != "" {
		return value
	}
	return defaultMessageBody
}

func stringifyUUIDs(values []uuid.UUID) []string {
	result := make([]string, 0, len(values))
	seen := make(map[uuid.UUID]struct{}, len(values))
	for _, value := range values {
		if value == uuid.Nil {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value.String())
	}
	return result
}

func readErrorMessage(body io.Reader) string {
	payload, err := io.ReadAll(io.LimitReader(body, 512))
	if err != nil || len(payload) == 0 {
		return "unknown"
	}
	var structured struct {
		Error string `json:"error"`
	}
	if json.Unmarshal(payload, &structured) == nil && strings.TrimSpace(structured.Error) != "" {
		return strings.TrimSpace(structured.Error)
	}
	return strings.TrimSpace(string(payload))
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
