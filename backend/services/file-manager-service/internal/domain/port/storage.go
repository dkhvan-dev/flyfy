package port

import (
	"context"
	"io"
	"time"
)

type PresignUploadRequest struct {
	Bucket      string
	ObjectKey   string
	ContentType string
	ExpiresIn   time.Duration
}

type PresignUploadResponse struct {
	Method    string
	URL       string
	ExpiresAt time.Time
	Headers   map[string]string
}

type PutObjectRequest struct {
	Bucket      string
	ObjectKey   string
	ContentType string
	Body        []byte
}

type ObjectMeta struct {
	Bucket      string
	ObjectKey   string
	SizeBytes   int64
	ContentType string
	ETag        string
}

type StorageProvider interface {
	CreatePresignedUpload(ctx context.Context, req PresignUploadRequest) (*PresignUploadResponse, error)
	PutObject(ctx context.Context, req PutObjectRequest) error
	StatObject(ctx context.Context, bucket, objectKey string) (*ObjectMeta, error)
	CreatePresignedDownload(ctx context.Context, bucket, objectKey string, ttl time.Duration) (string, error)
	GetObject(ctx context.Context, bucket, objectKey string) (io.ReadCloser, string, error)
	DeleteObject(ctx context.Context, bucket, objectKey string) error
}
