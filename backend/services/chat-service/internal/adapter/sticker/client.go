package sticker

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

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

func NewClient(baseURL string, internalToken string, httpClient *http.Client) *Client {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 5 * time.Second}
	}

	return &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    httpClient,
	}
}

func (c *Client) ValidateSend(
	ctx context.Context,
	senderUserID uuid.UUID,
	stickerID uuid.UUID,
) (*port.StickerMetadata, error) {
	body := bytes.NewBuffer(nil)
	if err := json.NewEncoder(body).Encode(validateSendRequest{
		UserID:    senderUserID.String(),
		StickerID: stickerID.String(),
	}); err != nil {
		return nil, fmt.Errorf("encode sticker validation request: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/internal/v1/stickers/validate-send",
		body,
	)
	if err != nil {
		return nil, fmt.Errorf("create sticker validation request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	if c.internalToken != "" {
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("call sticker-service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return nil, fmt.Errorf("sticker-service validation failed: status=%d message=%s", resp.StatusCode, readErrorMessage(resp.Body))
	}

	var payload validateSendResponse
	if err = json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("decode sticker validation response: %w", err)
	}

	parsedStickerID, err := uuid.Parse(strings.TrimSpace(payload.StickerID))
	if err != nil {
		return nil, fmt.Errorf("sticker-service returned invalid sticker id: %w", err)
	}
	packID, err := uuid.Parse(strings.TrimSpace(payload.PackID))
	if err != nil {
		return nil, fmt.Errorf("sticker-service returned invalid pack id: %w", err)
	}
	fileID, err := uuid.Parse(strings.TrimSpace(payload.FileID))
	if err != nil {
		return nil, fmt.Errorf("sticker-service returned invalid file id: %w", err)
	}
	fallbackFileID := fileID
	if strings.TrimSpace(payload.FallbackFileID) != "" {
		fallbackFileID, err = uuid.Parse(strings.TrimSpace(payload.FallbackFileID))
		if err != nil {
			return nil, fmt.Errorf("sticker-service returned invalid fallback file id: %w", err)
		}
	}
	var previewFileID *uuid.UUID
	if strings.TrimSpace(payload.PreviewFileID) != "" {
		parsed, err := uuid.Parse(strings.TrimSpace(payload.PreviewFileID))
		if err != nil {
			return nil, fmt.Errorf("sticker-service returned invalid preview file id: %w", err)
		}
		previewFileID = &parsed
	}

	return &port.StickerMetadata{
		StickerID:      parsedStickerID,
		PackID:         packID,
		PackSlug:       payload.PackSlug,
		Slug:           payload.Slug,
		FileID:         fileID,
		FallbackFileID: fallbackFileID,
		PreviewFileID:  previewFileID,
		ContentType:    payload.ContentType,
		Width:          payload.Width,
		Height:         payload.Height,
		DurationMS:     payload.DurationMS,
		Status:         payload.Status,
	}, nil
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

type validateSendRequest struct {
	UserID    string `json:"userId"`
	StickerID string `json:"stickerId"`
}

type validateSendResponse struct {
	StickerID      string `json:"stickerId"`
	PackID         string `json:"packId"`
	PackSlug       string `json:"packSlug"`
	Slug           string `json:"slug"`
	FileID         string `json:"fileId"`
	FallbackFileID string `json:"fallbackFileId"`
	PreviewFileID  string `json:"previewFileId"`
	ContentType    string `json:"contentType"`
	Width          int    `json:"width"`
	Height         int    `json:"height"`
	DurationMS     int    `json:"durationMs"`
	Status         string `json:"status"`
}
