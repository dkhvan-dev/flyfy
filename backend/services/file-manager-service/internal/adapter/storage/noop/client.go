package noop

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/port"
)

type Client struct{}

func New() *Client {
	return &Client{}
}

func (c *Client) CreatePresignedUpload(ctx context.Context, req port.PresignUploadRequest) (*port.PresignUploadResponse, error) {
	if req.ExpiresIn <= 0 {
		return nil, fmt.Errorf("expires in must be greater than zero")
	}

	return &port.PresignUploadResponse{
		Method:    "PUT",
		URL:       fmt.Sprintf("noop://upload/%s/%s?requestId=%s", req.Bucket, req.ObjectKey, uuid.NewString()),
		ExpiresAt: time.Now().UTC().Add(req.ExpiresIn),
		Headers: map[string]string{
			"Content-Type":   req.ContentType,
			"X-Noop-Storage": "true",
		},
	}, nil
}

func (c *Client) PutObject(ctx context.Context, req port.PutObjectRequest) error {
	return nil
}

func (c *Client) StatObject(ctx context.Context, bucket, objectKey string) (*port.ObjectMeta, error) {
	return &port.ObjectMeta{
		Bucket:      bucket,
		ObjectKey:   objectKey,
		SizeBytes:   0,
		ContentType: "application/octet-stream",
		ETag:        uuid.NewString(),
	}, nil
}

func (c *Client) CreatePresignedDownload(ctx context.Context, bucket, objectKey string, ttl time.Duration) (string, error) {
	if ttl <= 0 {
		return "", fmt.Errorf("ttl must be greater than zero")
	}

	return fmt.Sprintf("noop://download/%s/%s?expiresIn=%s", bucket, objectKey, ttl.String()), nil
}

func (c *Client) DeleteObject(ctx context.Context, bucket, objectKey string) error {
	return nil
}
