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

	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

const (
	postNotificationCategory   = "content"
	storyNotificationCategory  = "story"
	postNotificationPriority   = "normal"
	postNotificationTTL        = 7 * 24 * time.Hour
	internalSendPath           = "/internal/v1/notifications/send"
	internalTokenHeader        = "X-Internal-Service-Token"
	internalServiceNameHeader  = "X-Service-Name"
	defaultPostLikeTitle       = "Новая реакция на историю"
	defaultPostLikeActorName   = "Пользователю"
	defaultPostLikeDeepLink    = "/notifications"
	notificationErrorBodyLimit = 4096
)

type Client struct {
	baseURL       string
	internalToken string
	serviceName   string
	httpClient    *http.Client
}

var _ port.PostNotificationGateway = (*Client)(nil)

func New(baseURL string, internalToken string, serviceName string, timeout time.Duration) *Client {
	if timeout <= 0 {
		timeout = 3 * time.Second
	}
	return &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		serviceName:   strings.TrimSpace(serviceName),
		httpClient:    &http.Client{Timeout: timeout},
	}
}

func (c *Client) SendPostLikeNotification(
	ctx context.Context,
	input port.PostLikeNotificationInput,
) error {
	if c == nil || c.baseURL == "" || c.httpClient == nil {
		return fmt.Errorf("notification client is not configured")
	}
	if input.PostID == uuid.Nil ||
		input.PostAuthorUserID == uuid.Nil ||
		input.ActorUserID == uuid.Nil {
		return fmt.Errorf("post like notification requires post, author and actor ids")
	}
	if input.PostAuthorUserID == input.ActorUserID {
		return nil
	}

	data := map[string]string{
		"category":         postNotificationCategory,
		"type":             "post_like",
		"contentType":      "post",
		"postId":           input.PostID.String(),
		"actorUserId":      input.ActorUserID.String(),
		"postAuthorUserId": input.PostAuthorUserID.String(),
	}
	if slug := strings.TrimSpace(input.PostSlug); slug != "" {
		data["postSlug"] = slug
	}
	if title := strings.TrimSpace(input.PostTitle); title != "" {
		data["postTitle"] = title
	}
	if input.PostCoverFileID != nil {
		data["postPreviewFileId"] = input.PostCoverFileID.String()
	}

	payload := sendNotificationRequest{
		IdempotencyKey:   "post-like:" + input.PostID.String() + ":" + input.ActorUserID.String(),
		SourceService:    c.effectiveServiceName(),
		RecipientUserIDs: []string{input.PostAuthorUserID.String()},
		Category:         postNotificationCategory,
		Priority:         postNotificationPriority,
		Title:            defaultPostLikeTitle,
		Body:             postLikeBody(input.ActorDisplayName),
		DeepLink:         postLikeDeepLink(input.PostSlug),
		Data:             data,
		CollapseKey:      "post-like:" + input.PostID.String(),
		TTLSeconds:       int64(postNotificationTTL / time.Second),
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal post like notification: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+internalSendPath,
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("create post like notification request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", payload.IdempotencyKey)
	req.Header.Set(internalServiceNameHeader, payload.SourceService)
	if c.internalToken != "" {
		req.Header.Set(internalTokenHeader, c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call notification-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= http.StatusOK && resp.StatusCode < http.StatusMultipleChoices {
		return nil
	}
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, notificationErrorBodyLimit))
	return fmt.Errorf(
		"notification-service send failed: status=%d message=%s",
		resp.StatusCode,
		strings.TrimSpace(string(respBody)),
	)
}

func (c *Client) SendStoryLikeNotification(
	ctx context.Context,
	input port.StoryLikeNotificationInput,
) error {
	if c == nil || c.baseURL == "" || c.httpClient == nil {
		return fmt.Errorf("notification client is not configured")
	}
	if input.StoryID == uuid.Nil ||
		input.StoryAuthorUserID == uuid.Nil ||
		input.ActorUserID == uuid.Nil {
		return fmt.Errorf("story like notification requires story, author and actor ids")
	}
	if input.StoryAuthorUserID == input.ActorUserID {
		return nil
	}

	data := map[string]string{
		"category":          storyNotificationCategory,
		"type":              "story_like",
		"contentType":       "story",
		"storyId":           input.StoryID.String(),
		"actorUserId":       input.ActorUserID.String(),
		"storyAuthorUserId": input.StoryAuthorUserID.String(),
	}
	if caption := strings.TrimSpace(input.StoryCaption); caption != "" {
		data["storyCaption"] = caption
	}
	if input.StoryPreviewFileID != nil {
		data["storyPreviewFileId"] = input.StoryPreviewFileID.String()
	}

	payload := sendNotificationRequest{
		IdempotencyKey:   "story-like:" + input.StoryID.String() + ":" + input.ActorUserID.String(),
		SourceService:    c.effectiveServiceName(),
		RecipientUserIDs: []string{input.StoryAuthorUserID.String()},
		Category:         storyNotificationCategory,
		Priority:         postNotificationPriority,
		Title:            defaultPostLikeTitle,
		Body:             postLikeBody(input.ActorDisplayName),
		DeepLink:         storyLikeDeepLink(input.StoryID),
		Data:             data,
		CollapseKey:      "story-like:" + input.StoryID.String(),
		TTLSeconds:       int64(postNotificationTTL / time.Second),
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal story like notification: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+internalSendPath,
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("create story like notification request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", payload.IdempotencyKey)
	req.Header.Set(internalServiceNameHeader, payload.SourceService)
	if c.internalToken != "" {
		req.Header.Set(internalTokenHeader, c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call notification-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= http.StatusOK && resp.StatusCode < http.StatusMultipleChoices {
		return nil
	}
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, notificationErrorBodyLimit))
	return fmt.Errorf(
		"notification-service send failed: status=%d message=%s",
		resp.StatusCode,
		strings.TrimSpace(string(respBody)),
	)
}

func (c *Client) effectiveServiceName() string {
	if c != nil && strings.TrimSpace(c.serviceName) != "" {
		return strings.TrimSpace(c.serviceName)
	}
	return "feed-service"
}

func postLikeBody(actorDisplayName string) string {
	actor := strings.TrimSpace(actorDisplayName)
	if actor == "" {
		actor = defaultPostLikeActorName
	}
	return actor + " нравится ваша история"
}

func postLikeDeepLink(postSlug string) string {
	slug := strings.Trim(strings.TrimSpace(postSlug), "/")
	if slug == "" {
		return defaultPostLikeDeepLink
	}
	return "/posts/" + slug
}

func storyLikeDeepLink(storyID uuid.UUID) string {
	if storyID == uuid.Nil {
		return defaultPostLikeDeepLink
	}
	return "/stories/" + storyID.String()
}

type sendNotificationRequest struct {
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
