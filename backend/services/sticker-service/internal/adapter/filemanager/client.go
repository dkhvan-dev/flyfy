package filemanager

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/sticker-service/internal/domain/port"
	"github.com/google/uuid"
)

const (
	headerInternalServiceToken = "X-Internal-Service-Token"
	headerUserID               = "X-User-Id"

	filePurposeChatSticker = "CHAT_STICKER"
	fileVisibilityPublic   = "PUBLIC"
	ownerTypeUser          = "USER"
)

type Client struct {
	baseURL       string
	internalToken string
	httpClient    *http.Client
}

func NewClient(baseURL string, internalToken string, httpClient *http.Client) *Client {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 10 * time.Second}
	}

	return &Client{
		baseURL:       strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		internalToken: strings.TrimSpace(internalToken),
		httpClient:    httpClient,
	}
}

func (c *Client) CreateStickerUploadRequest(
	ctx context.Context,
	input port.CreateStickerUploadRequest,
) (*port.CreateStickerUploadResponse, error) {
	reqBody := createUploadRequestBody{
		OriginalName: input.OriginalName,
		ContentType:  input.ContentType,
		SizeBytes:    input.SizeBytes,
		Purpose:      filePurposeChatSticker,
		Visibility:   fileVisibilityPublic,
		OwnerType:    ownerTypeUser,
		OwnerID:      input.UserID.String(),
	}

	var resp createUploadResponseBody
	if err := c.doJSON(ctx, http.MethodPost, "/v1/files/upload-requests", input.UserID, reqBody, &resp); err != nil {
		return nil, err
	}

	fileID, err := uuid.Parse(strings.TrimSpace(resp.FileID))
	if err != nil {
		return nil, fmt.Errorf("file-manager returned invalid file id: %w", err)
	}

	expiresAt, err := time.Parse(time.RFC3339, strings.TrimSpace(resp.Upload.ExpiresAt))
	if err != nil {
		return nil, fmt.Errorf("file-manager returned invalid upload expiry: %w", err)
	}

	return &port.CreateStickerUploadResponse{
		FileID:    fileID,
		Method:    resp.Upload.Method,
		URL:       resp.Upload.URL,
		Headers:   resp.Upload.Headers,
		ExpiresAt: expiresAt,
	}, nil
}

func (c *Client) GetFile(ctx context.Context, fileID uuid.UUID) (*port.FileMetadata, error) {
	var resp fileResponseBody
	if err := c.doJSON(ctx, http.MethodGet, "/v1/files/"+fileID.String(), uuid.Nil, nil, &resp); err != nil {
		return nil, err
	}

	parsedID, err := uuid.Parse(strings.TrimSpace(resp.ID))
	if err != nil {
		return nil, fmt.Errorf("file-manager returned invalid file id: %w", err)
	}

	return &port.FileMetadata{
		ID:          parsedID,
		Status:      resp.Status,
		ContentType: firstNonEmpty(resp.DetectedContentType, resp.ContentType),
		SizeBytes:   resp.SizeBytes,
	}, nil
}

func (c *Client) BindStickerFileToUser(ctx context.Context, fileID uuid.UUID, userID uuid.UUID) error {
	reqBody := bindFileRequestBody{
		OwnerType: ownerTypeUser,
		OwnerID:   userID.String(),
		Purpose:   filePurposeChatSticker,
		IsPrimary: false,
	}

	return c.doJSON(
		ctx,
		http.MethodPost,
		"/v1/internal/files/"+fileID.String()+"/bindings",
		userID,
		reqBody,
		nil,
	)
}

func (c *Client) doJSON(
	ctx context.Context,
	method string,
	path string,
	userID uuid.UUID,
	requestPayload any,
	responsePayload any,
) error {
	var body io.Reader
	if requestPayload != nil {
		buf := bytes.NewBuffer(nil)
		if err := json.NewEncoder(buf).Encode(requestPayload); err != nil {
			return fmt.Errorf("encode file-manager request: %w", err)
		}
		body = buf
	}

	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, body)
	if err != nil {
		return fmt.Errorf("create file-manager request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	if requestPayload != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.internalToken != "" {
		req.Header.Set(headerInternalServiceToken, c.internalToken)
	}
	if userID != uuid.Nil {
		req.Header.Set(headerUserID, userID.String())
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call file-manager: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return fmt.Errorf("file-manager request failed: status=%d message=%s", resp.StatusCode, readErrorMessage(resp.Body))
	}

	if responsePayload == nil {
		return nil
	}
	if err = json.NewDecoder(resp.Body).Decode(responsePayload); err != nil {
		return fmt.Errorf("decode file-manager response: %w", err)
	}
	return nil
}

func readErrorMessage(body io.Reader) string {
	const maxErrorBytes = 512

	payload, err := io.ReadAll(io.LimitReader(body, maxErrorBytes))
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

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return strings.TrimSpace(value)
		}
	}
	return ""
}

type createUploadRequestBody struct {
	OriginalName string `json:"originalName"`
	ContentType  string `json:"contentType"`
	SizeBytes    int64  `json:"sizeBytes"`
	Purpose      string `json:"purpose"`
	Visibility   string `json:"visibility"`
	OwnerType    string `json:"ownerType"`
	OwnerID      string `json:"ownerId"`
}

type createUploadResponseBody struct {
	FileID string               `json:"fileId"`
	Upload uploadDescriptorBody `json:"upload"`
}

type uploadDescriptorBody struct {
	Method    string            `json:"method"`
	URL       string            `json:"url"`
	Headers   map[string]string `json:"headers"`
	ExpiresAt string            `json:"expiresAt"`
}

type fileResponseBody struct {
	ID                  string `json:"id"`
	Status              string `json:"status"`
	ContentType         string `json:"contentType"`
	DetectedContentType string `json:"detectedContentType"`
	SizeBytes           int64  `json:"sizeBytes"`
}

type bindFileRequestBody struct {
	OwnerType string `json:"ownerType"`
	OwnerID   string `json:"ownerId"`
	Purpose   string `json:"purpose"`
	IsPrimary bool   `json:"isPrimary"`
}
