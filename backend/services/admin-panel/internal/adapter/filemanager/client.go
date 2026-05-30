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

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

type Client struct {
	baseURL       string
	httpClient    *http.Client
	internalToken string
}

func NewClient(baseURL string, timeout time.Duration, internalToken string) *Client {
	baseURL = strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: timeout,
		},
		internalToken: strings.TrimSpace(internalToken),
	}
}

func (c *Client) UploadPublicAttractionImage(ctx context.Context, input model.FileUploadInput) (*model.UploadedFile, error) {
	ownerID := input.OwnerID.String()
	ownerType := input.OwnerType
	createReq := createUploadRequest{
		OriginalName: input.FileName,
		ContentType:  input.ContentType,
		SizeBytes:    int64(len(input.Content)),
		Purpose:      input.Purpose,
		Visibility:   input.Visibility,
		OwnerType:    &ownerType,
		OwnerID:      &ownerID,
	}
	var createResp createUploadResponse
	if err := c.doJSON(ctx, http.MethodPost, "/v1/files/upload-requests", createReq, &createResp); err != nil {
		return nil, err
	}
	fileID, err := uuid.Parse(createResp.FileID)
	if err != nil {
		return nil, fmt.Errorf("file-manager returned invalid file id: %w", err)
	}
	if err = c.doBytes(ctx, http.MethodPut, "/v1/files/"+fileID.String()+"/binary", input.ContentType, input.Content); err != nil {
		return nil, err
	}
	if err = c.doJSON(ctx, http.MethodPost, "/v1/files/"+fileID.String()+"/complete", nil, nil); err != nil {
		return nil, err
	}
	return &model.UploadedFile{ID: fileID}, nil
}

func (c *Client) GetPublicContent(ctx context.Context, fileID uuid.UUID) (*model.FileContent, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/v1/public/files/"+fileID.String()+"/content", nil)
	if err != nil {
		return nil, err
	}
	c.applyHeaders(req, "")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		raw, _ := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
		return nil, fmt.Errorf("file-manager GET public content returned %d: %s", resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 25<<20))
	if err != nil {
		return nil, err
	}
	contentType := strings.TrimSpace(resp.Header.Get("Content-Type"))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	return &model.FileContent{ContentType: contentType, Content: raw}, nil
}

func (c *Client) doJSON(ctx context.Context, method string, path string, body any, dest any) error {
	var reader io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(payload)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reader)
	if err != nil {
		return err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	c.applyHeaders(req, "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("file-manager %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	if dest != nil && len(raw) > 0 {
		if err = json.Unmarshal(raw, dest); err != nil {
			return err
		}
	}
	return nil
}

func (c *Client) doBytes(ctx context.Context, method string, path string, contentType string, body []byte) error {
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", contentType)
	c.applyHeaders(req, "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("file-manager %s %s returned %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(raw)))
	}
	return nil
}

func (c *Client) applyHeaders(req *http.Request, accept string) {
	if accept != "" {
		req.Header.Set("Accept", accept)
	}
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
		req.Header.Set("X-Internal-Service-Token", c.internalToken)
		req.Header.Set("X-Internal-Service", "admin-panel")
		req.Header.Set("X-Auth-Subject", "admin-panel")
		req.Header.Set("X-User-Roles", "SUPER_ADMIN,ADMIN")
	}
}

type createUploadRequest struct {
	OriginalName string  `json:"originalName"`
	ContentType  string  `json:"contentType"`
	SizeBytes    int64   `json:"sizeBytes"`
	Purpose      string  `json:"purpose"`
	Visibility   string  `json:"visibility"`
	OwnerType    *string `json:"ownerType,omitempty"`
	OwnerID      *string `json:"ownerId,omitempty"`
}

type createUploadResponse struct {
	FileID string `json:"fileId"`
}
