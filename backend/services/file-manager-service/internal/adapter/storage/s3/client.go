package s3

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	awss3 "github.com/aws/aws-sdk-go-v2/service/s3"

	appconfig "kz/inflap/backend/services/file-manager-service/internal/config"
	"kz/inflap/backend/services/file-manager-service/internal/domain/port"
)

type Client struct {
	s3Client *awss3.Client
	presign  *awss3.PresignClient
}

func New(ctx context.Context, cfg appconfig.StorageConfig) (*Client, error) {
	loadOptions := []func(*awsconfig.LoadOptions) error{
		awsconfig.WithRegion(cfg.Region),
		awsconfig.WithCredentialsProvider(
			credentials.NewStaticCredentialsProvider(
				cfg.AccessKeyID,
				cfg.SecretAccessKey,
				"",
			),
		),
		awsconfig.WithHTTPClient(newHTTPClient(cfg)),
	}

	awsCfg, err := awsconfig.LoadDefaultConfig(ctx, loadOptions...)
	if err != nil {
		return nil, fmt.Errorf("load aws config: %w", err)
	}

	s3Client := awss3.NewFromConfig(awsCfg, func(o *awss3.Options) {
		o.UsePathStyle = cfg.UsePathStyle

		if strings.TrimSpace(cfg.Endpoint) != "" {
			o.BaseEndpoint = aws.String(cfg.Endpoint)
		}
	})

	return &Client{
		s3Client: s3Client,
		presign:  awss3.NewPresignClient(s3Client),
	}, nil
}

func newHTTPClient(cfg appconfig.StorageConfig) *http.Client {
	transport := http.DefaultTransport.(*http.Transport).Clone()
	if cfg.HTTPMaxIdleConns > 0 {
		transport.MaxIdleConns = cfg.HTTPMaxIdleConns
	}
	if cfg.HTTPMaxIdleConnsPerHost > 0 {
		transport.MaxIdleConnsPerHost = cfg.HTTPMaxIdleConnsPerHost
	}
	if cfg.HTTPMaxConnsPerHost > 0 {
		transport.MaxConnsPerHost = cfg.HTTPMaxConnsPerHost
	}
	transport.IdleConnTimeout = cfg.ParsedHTTPIdleConnTimeout()

	return &http.Client{
		Transport: transport,
	}
}

func (c *Client) CreatePresignedUpload(ctx context.Context, req port.PresignUploadRequest) (*port.PresignUploadResponse, error) {
	if strings.TrimSpace(req.Bucket) == "" {
		return nil, fmt.Errorf("bucket is required")
	}
	if strings.TrimSpace(req.ObjectKey) == "" {
		return nil, fmt.Errorf("object key is required")
	}
	if strings.TrimSpace(req.ContentType) == "" {
		return nil, fmt.Errorf("content type is required")
	}
	if req.ExpiresIn <= 0 {
		return nil, fmt.Errorf("expires in must be greater than zero")
	}

	presigned, err := c.presign.PresignPutObject(
		ctx,
		&awss3.PutObjectInput{
			Bucket:      aws.String(req.Bucket),
			Key:         aws.String(req.ObjectKey),
			ContentType: aws.String(req.ContentType),
		},
		func(opts *awss3.PresignOptions) {
			opts.Expires = req.ExpiresIn
		},
	)
	if err != nil {
		return nil, fmt.Errorf("presign put object: %w", err)
	}

	return &port.PresignUploadResponse{
		Method:    "PUT",
		URL:       presigned.URL,
		ExpiresAt: time.Now().UTC().Add(req.ExpiresIn),
		Headers: map[string]string{
			"Content-Type": req.ContentType,
		},
	}, nil
}

func (c *Client) PutObject(ctx context.Context, req port.PutObjectRequest) error {
	if strings.TrimSpace(req.Bucket) == "" {
		return fmt.Errorf("bucket is required")
	}
	if strings.TrimSpace(req.ObjectKey) == "" {
		return fmt.Errorf("object key is required")
	}
	if strings.TrimSpace(req.ContentType) == "" {
		return fmt.Errorf("content type is required")
	}

	_, err := c.s3Client.PutObject(ctx, &awss3.PutObjectInput{
		Bucket:        aws.String(req.Bucket),
		Key:           aws.String(req.ObjectKey),
		Body:          bytes.NewReader(req.Body),
		ContentLength: aws.Int64(int64(len(req.Body))),
		ContentType:   aws.String(req.ContentType),
	})
	if err != nil {
		return fmt.Errorf("put object: %w", err)
	}

	return nil
}

func (c *Client) StatObject(ctx context.Context, bucket, objectKey string) (*port.ObjectMeta, error) {
	out, err := c.s3Client.HeadObject(ctx, &awss3.HeadObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(objectKey),
	})
	if err != nil {
		return nil, fmt.Errorf("head object: %w", err)
	}

	contentType := ""
	if out.ContentType != nil {
		contentType = *out.ContentType
	}

	etag := ""
	if out.ETag != nil {
		etag = strings.Trim(*out.ETag, "\"")
	}

	var sizeBytes int64
	if out.ContentLength != nil {
		sizeBytes = *out.ContentLength
	}

	return &port.ObjectMeta{
		Bucket:      bucket,
		ObjectKey:   objectKey,
		SizeBytes:   sizeBytes,
		ContentType: contentType,
		ETag:        etag,
	}, nil
}

func (c *Client) CreatePresignedDownload(ctx context.Context, bucket, objectKey string, ttl time.Duration) (string, error) {
	if ttl <= 0 {
		return "", fmt.Errorf("ttl must be greater than zero")
	}

	presigned, err := c.presign.PresignGetObject(
		ctx,
		&awss3.GetObjectInput{
			Bucket: aws.String(bucket),
			Key:    aws.String(objectKey),
		},
		func(opts *awss3.PresignOptions) {
			opts.Expires = ttl
		},
	)
	if err != nil {
		return "", fmt.Errorf("presign get object: %w", err)
	}

	return presigned.URL, nil
}

func (c *Client) GetObject(ctx context.Context, bucket, objectKey string) (io.ReadCloser, string, error) {
	out, err := c.s3Client.GetObject(ctx, &awss3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(objectKey),
	})
	if err != nil {
		return nil, "", fmt.Errorf("get object: %w", err)
	}

	contentType := ""
	if out.ContentType != nil {
		contentType = strings.TrimSpace(*out.ContentType)
	}

	return out.Body, contentType, nil
}

func (c *Client) DeleteObject(ctx context.Context, bucket, objectKey string) error {
	_, err := c.s3Client.DeleteObject(ctx, &awss3.DeleteObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(objectKey),
	})
	if err != nil {
		return fmt.Errorf("delete object: %w", err)
	}

	return nil
}
