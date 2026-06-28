package chat

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

type Client struct {
	baseURL        string
	httpClient     *http.Client
	internalToken  string
	supportSubject string
}

func NewClient(baseURL string, timeout time.Duration, internalToken string, supportSubject string) *Client {
	baseURL = strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: timeout,
		},
		internalToken:  strings.TrimSpace(internalToken),
		supportSubject: strings.TrimSpace(supportSubject),
	}
}

func (c *Client) EnsureSupportConversation(ctx context.Context, userID string) (app.SupportChatConversationResult, error) {
	userID = strings.TrimSpace(userID)
	if c == nil || c.baseURL == "" || c.supportSubject == "" || userID == "" {
		return app.SupportChatConversationResult{}, fmt.Errorf("invalid support chat conversation request")
	}

	payload, err := json.Marshal(createConversationRequest{
		Type:               "direct",
		ParticipantUserIDs: []string{userID},
	})
	if err != nil {
		return app.SupportChatConversationResult{}, fmt.Errorf("encode support chat conversation: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/v1/conversations", bytes.NewReader(payload))
	if err != nil {
		return app.SupportChatConversationResult{}, fmt.Errorf("create support chat conversation request: %w", err)
	}
	c.applyHeaders(req)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return app.SupportChatConversationResult{}, fmt.Errorf("ensure support chat conversation: %w", err)
	}
	defer resp.Body.Close()

	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return app.SupportChatConversationResult{}, fmt.Errorf("read support chat conversation response: %w", err)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return app.SupportChatConversationResult{}, fmt.Errorf("chat-service create conversation returned %d: %s", resp.StatusCode, strings.TrimSpace(string(raw)))
	}

	var decoded createConversationResponse
	if err := json.Unmarshal(raw, &decoded); err != nil {
		return app.SupportChatConversationResult{}, fmt.Errorf("decode support chat conversation response: %w", err)
	}
	return app.SupportChatConversationResult{ConversationID: strings.TrimSpace(decoded.ID)}, nil
}

func (c *Client) SendSupportMessage(ctx context.Context, input app.SupportChatMessageInput) (app.SupportChatMessageResult, error) {
	conversationID := strings.TrimSpace(input.ConversationID)
	message := strings.TrimSpace(input.Message)
	if c == nil || c.baseURL == "" || c.supportSubject == "" || conversationID == "" || message == "" {
		return app.SupportChatMessageResult{}, fmt.Errorf("invalid support chat message request")
	}

	fileIDs := normalizeSupportFileIDs(input.FileIDs)
	messageType := "text"
	if len(fileIDs) > 0 {
		messageType = "file"
	}
	body := sendMessageRequest{
		Content: message,
		Type:    messageType,
		FileIDs: fileIDs,
	}
	if actorDisplayName := strings.TrimSpace(input.ActorDisplayName); actorDisplayName != "" {
		body.SenderDisplayName = actorDisplayName
	}
	if clientMessageID := strings.TrimSpace(input.ClientMessageID); clientMessageID != "" {
		body.ClientMessageID = &clientMessageID
	}

	payload, err := json.Marshal(body)
	if err != nil {
		return app.SupportChatMessageResult{}, fmt.Errorf("encode support chat message: %w", err)
	}
	path := "/v1/conversations/" + url.PathEscape(conversationID) + "/messages"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(payload))
	if err != nil {
		return app.SupportChatMessageResult{}, fmt.Errorf("create support chat message request: %w", err)
	}
	c.applyHeaders(req)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return app.SupportChatMessageResult{}, fmt.Errorf("send support chat message: %w", err)
	}
	defer resp.Body.Close()

	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return app.SupportChatMessageResult{}, fmt.Errorf("read support chat message response: %w", err)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return app.SupportChatMessageResult{}, fmt.Errorf("chat-service %s returned %d: %s", path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}

	var decoded sendMessageResponse
	if err := json.Unmarshal(raw, &decoded); err != nil {
		return app.SupportChatMessageResult{}, fmt.Errorf("decode support chat message response: %w", err)
	}
	return app.SupportChatMessageResult{MessageID: strings.TrimSpace(decoded.ID)}, nil
}

func (c *Client) applyHeaders(req *http.Request) {
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Auth-Subject", c.supportSubject)
	req.Header.Set("X-User-Roles", "SUPPORT_AGENT,SUPPORT_ADMIN")
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Internal-Service", "support-service")
	}
}

type createConversationRequest struct {
	Type               string   `json:"type"`
	ParticipantUserIDs []string `json:"participantUserIds"`
}

type createConversationResponse struct {
	ID string `json:"id"`
}

type sendMessageRequest struct {
	Content           string   `json:"content"`
	Type              string   `json:"type"`
	SenderDisplayName string   `json:"senderDisplayName,omitempty"`
	ClientMessageID   *string  `json:"clientMessageId,omitempty"`
	FileIDs           []string `json:"fileIds"`
}

type sendMessageResponse struct {
	ID string `json:"id"`
}

func normalizeSupportFileIDs(values []string) []string {
	if len(values) == 0 {
		return []string{}
	}
	const maxFileIDs = 10
	normalized := make([]string, 0, min(len(values), maxFileIDs))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		fileID := strings.TrimSpace(value)
		if fileID == "" {
			continue
		}
		if len(fileID) > 128 {
			fileID = fileID[:128]
		}
		if _, ok := seen[fileID]; ok {
			continue
		}
		seen[fileID] = struct{}{}
		normalized = append(normalized, fileID)
		if len(normalized) >= maxFileIDs {
			break
		}
	}
	return normalized
}
