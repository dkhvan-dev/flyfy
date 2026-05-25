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

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/port"
)

type Client struct {
	baseURL       string
	httpClient    *http.Client
	internalToken string
}

func NewClient(baseURL string, timeout time.Duration, internalToken string) *Client {
	baseURL = strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if timeout <= 0 {
		timeout = 5 * time.Second
	}
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: timeout,
		},
		internalToken: strings.TrimSpace(internalToken),
	}
}

func (c *Client) ListFlaggedMessages(ctx context.Context, limit int, offset int) ([]model.ChatMessageModerationItem, error) {
	values := url.Values{}
	values.Set("limit", fmt.Sprintf("%d", limit))
	values.Set("offset", fmt.Sprintf("%d", offset))
	var resp chatMessageListResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/chat/messages/moderation/flagged?"+values.Encode(), nil, nil, &resp); err != nil {
		return nil, err
	}
	items := make([]model.ChatMessageModerationItem, 0, len(resp.Items))
	for _, item := range resp.Items {
		items = append(items, item.toModel())
	}
	return items, nil
}

func (c *Client) GetMessage(ctx context.Context, id uuid.UUID) (*model.ChatMessageModerationItem, error) {
	var resp chatMessageResponse
	if err := c.doJSON(ctx, http.MethodGet, "/v1/admin/chat/messages/"+id.String(), nil, nil, &resp); err != nil {
		return nil, err
	}
	item := resp.toModel()
	return &item, nil
}

func (c *Client) ApproveMessage(ctx context.Context, input port.ChatMessageDecisionInput) (*model.ChatMessageModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	body := map[string]any{
		"internalComment": input.InternalComment,
	}
	var resp chatMessageResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/chat/messages/"+input.MessageID.String()+"/moderation/approve", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) HideMessage(ctx context.Context, input port.ChatMessageDecisionInput) (*model.ChatMessageModerationItem, []byte, error) {
	headers := c.decisionHeaders(input)
	body := map[string]any{
		"reasonCodes":     input.ReasonCodes,
		"publicComment":   input.PublicComment,
		"internalComment": input.InternalComment,
	}
	var resp chatMessageResponse
	raw, err := c.doJSONRaw(ctx, http.MethodPost, "/v1/admin/chat/messages/"+input.MessageID.String()+"/moderation/reject", headers, body, &resp)
	if err != nil {
		return nil, nil, err
	}
	item := resp.toModel()
	return &item, raw, nil
}

func (c *Client) decisionHeaders(input port.ChatMessageDecisionInput) map[string]string {
	headers := map[string]string{
		"X-Auth-Subject":  "admin-panel:" + input.ActorStaffID.String(),
		"X-User-Id":       input.ActorStaffID.String(),
		"X-User-Roles":    "SUPER_ADMIN,CHAT_MODERATOR",
		"Idempotency-Key": input.IdempotencyKey,
	}
	if input.RequestID != "" {
		headers["X-Request-Id"] = input.RequestID
	}
	return headers
}

func (c *Client) doJSON(ctx context.Context, method string, path string, headers map[string]string, body any, dest any) error {
	_, err := c.doJSONRaw(ctx, method, path, headers, body, dest)
	return err
}

func (c *Client) doJSONRaw(ctx context.Context, method string, path string, headers map[string]string, body any, dest any) ([]byte, error) {
	var reader io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reader = bytes.NewReader(payload)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reader)
	if err != nil {
		return nil, err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Accept", "application/json")
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Internal-Service", "admin-panel")
		req.Header.Set("X-Auth-Subject", "admin-panel")
		req.Header.Set("X-User-Roles", "SUPER_ADMIN,CHAT_MODERATOR")
	}
	for key, value := range headers {
		if strings.TrimSpace(value) != "" {
			req.Header.Set(key, value)
		}
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("chat-service %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil {
		if err = json.Unmarshal(raw, dest); err != nil {
			return nil, err
		}
	}
	return raw, nil
}

type chatMessageListResponse struct {
	Items []chatMessageResponse `json:"items"`
}

type chatParticipantResponse struct {
	UserID      string `json:"userId"`
	DisplayName string `json:"displayName"`
	Role        string `json:"role"`
}

type chatMessageContextResponse struct {
	ID                string   `json:"id"`
	SenderUserID      string   `json:"senderUserId"`
	SenderDisplayName string   `json:"senderDisplayName"`
	Type              string   `json:"type"`
	Content           string   `json:"content"`
	FileIDs           []string `json:"fileIds"`
	EditedAt          *string  `json:"editedAt"`
	DeletedAt         *string  `json:"deletedAt"`
	SentAt            string   `json:"sentAt"`
}

type chatMessageResponse struct {
	ID                      string                       `json:"id"`
	ConversationID          string                       `json:"conversationId"`
	ConversationType        string                       `json:"conversationType"`
	ConversationTitle       string                       `json:"conversationTitle"`
	ActivityID              *string                      `json:"activityId"`
	ExcursionScheduleSlotID *string                      `json:"excursionScheduleSlotId"`
	SenderUserID            string                       `json:"senderUserId"`
	SenderDisplayName       string                       `json:"senderDisplayName"`
	Type                    string                       `json:"type"`
	Content                 string                       `json:"content"`
	FileIDs                 []string                     `json:"fileIds"`
	ModerationStatus        string                       `json:"moderationStatus"`
	ModerationRiskScore     int                          `json:"moderationRiskScore"`
	ModerationReasonCodes   []string                     `json:"moderationReasonCodes"`
	ModerationTriggeredAt   *string                      `json:"moderationTriggeredAt"`
	ModerationReviewedAt    *string                      `json:"moderationReviewedAt"`
	ContextBefore           []chatMessageContextResponse `json:"contextBefore"`
	ContextAfter            []chatMessageContextResponse `json:"contextAfter"`
	Participants            []chatParticipantResponse    `json:"participants"`
	Revision                int                          `json:"revision"`
	EditedAt                *string                      `json:"editedAt"`
	DeletedAt               *string                      `json:"deletedAt"`
	SentAt                  string                       `json:"sentAt"`
	CreatedAt               string                       `json:"createdAt"`
	UpdatedAt               string                       `json:"updatedAt"`
}

func (r chatMessageResponse) toModel() model.ChatMessageModerationItem {
	id, _ := uuid.Parse(r.ID)
	conversationID, _ := uuid.Parse(r.ConversationID)
	senderUserID, _ := uuid.Parse(r.SenderUserID)
	return model.ChatMessageModerationItem{
		ID:                      id,
		ConversationID:          conversationID,
		ConversationType:        r.ConversationType,
		ConversationTitle:       r.ConversationTitle,
		ActivityID:              parseOptionalUUID(r.ActivityID),
		ExcursionScheduleSlotID: parseOptionalUUID(r.ExcursionScheduleSlotID),
		SenderUserID:            senderUserID,
		SenderDisplayName:       r.SenderDisplayName,
		Type:                    r.Type,
		Content:                 r.Content,
		FileIDs:                 append([]string(nil), r.FileIDs...),
		ModerationStatus:        r.ModerationStatus,
		ModerationRiskScore:     r.ModerationRiskScore,
		ModerationReasonCodes:   append([]string(nil), r.ModerationReasonCodes...),
		ModerationTriggeredAt:   parseOptionalTime(r.ModerationTriggeredAt),
		ModerationReviewedAt:    parseOptionalTime(r.ModerationReviewedAt),
		ContextBefore:           chatContextItemsToModel(r.ContextBefore),
		ContextAfter:            chatContextItemsToModel(r.ContextAfter),
		Participants:            chatParticipantsToModel(r.Participants),
		Revision:                r.Revision,
		EditedAt:                parseOptionalTime(r.EditedAt),
		DeletedAt:               parseOptionalTime(r.DeletedAt),
		SentAt:                  parseTime(r.SentAt),
		CreatedAt:               parseTime(r.CreatedAt),
		UpdatedAt:               parseTime(r.UpdatedAt),
	}
}

func chatContextItemsToModel(items []chatMessageContextResponse) []model.ChatMessageContextItem {
	out := make([]model.ChatMessageContextItem, 0, len(items))
	for _, item := range items {
		id, _ := uuid.Parse(item.ID)
		senderUserID, _ := uuid.Parse(item.SenderUserID)
		out = append(out, model.ChatMessageContextItem{
			ID:                id,
			SenderUserID:      senderUserID,
			SenderDisplayName: item.SenderDisplayName,
			Type:              item.Type,
			Content:           item.Content,
			FileIDs:           append([]string(nil), item.FileIDs...),
			EditedAt:          parseOptionalTime(item.EditedAt),
			DeletedAt:         parseOptionalTime(item.DeletedAt),
			SentAt:            parseTime(item.SentAt),
		})
	}
	return out
}

func chatParticipantsToModel(items []chatParticipantResponse) []model.ChatParticipantModerationItem {
	out := make([]model.ChatParticipantModerationItem, 0, len(items))
	for _, item := range items {
		userID, _ := uuid.Parse(item.UserID)
		out = append(out, model.ChatParticipantModerationItem{
			UserID:      userID,
			DisplayName: item.DisplayName,
			Role:        item.Role,
		})
	}
	return out
}

func parseOptionalUUID(value *string) *uuid.UUID {
	if value == nil {
		return nil
	}
	parsed, err := uuid.Parse(strings.TrimSpace(*value))
	if err != nil {
		return nil
	}
	return &parsed
}

func parseTime(value string) time.Time {
	parsed, _ := time.Parse(time.RFC3339, strings.TrimSpace(value))
	return parsed
}

func parseOptionalTime(value *string) *time.Time {
	if value == nil {
		return nil
	}
	parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(*value))
	if err != nil {
		return nil
	}
	return &parsed
}
