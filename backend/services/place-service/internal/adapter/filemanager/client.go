package filemanager

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	grpcadapter "kz/inflap/backend/services/place-service/internal/adapter/grpc"
	"kz/inflap/backend/services/place-service/internal/app"
	filev1 "kz/inflap/proto/gen/go/file/v1"
)

const (
	minimumSavedCoverSignedURLTTL = 5 * time.Second
	maximumSavedCoverSignedURLTTL = 20 * time.Minute
)

type Client struct {
	conn           *grpc.ClientConn
	service        filev1.FileServiceClient
	requestTimeout time.Duration
	now            func() time.Time
}

func New(
	target string,
	internalToken string,
	serviceName string,
	requestTimeout time.Duration,
	opts ...grpc.DialOption,
) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{
			grpc.WithTransportCredentials(insecure.NewCredentials()),
		}
	}
	opts = append(opts, grpc.WithChainUnaryInterceptor(
		grpcadapter.InternalTokenInterceptor(
			strings.TrimSpace(internalToken),
			strings.TrimSpace(serviceName),
		),
	))

	conn, err := grpc.NewClient(strings.TrimSpace(target), opts...)
	if err != nil {
		return nil, err
	}
	return &Client{
		conn:           conn,
		service:        filev1.NewFileServiceClient(conn),
		requestTimeout: requestTimeout,
		now:            time.Now,
	}, nil
}

func (c *Client) Close() error {
	if c == nil || c.conn == nil {
		return nil
	}
	return c.conn.Close()
}

func (c *Client) CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error) {
	if c == nil || c.service == nil || c.requestTimeout <= 0 {
		return "", app.ErrSavedCoverFileManagerUnavailable
	}
	if fileID == uuid.Nil {
		return "", app.ErrSavedCoverFileManagerBadResponse
	}

	callCtx, cancel := context.WithTimeout(ctx, c.requestTimeout)
	defer cancel()
	response, err := c.service.CreateDownloadUrl(callCtx, &filev1.CreateDownloadUrlRequest{
		FileId: fileID.String(),
	})
	if err != nil {
		if grpcStatus, ok := status.FromError(err); ok {
			switch grpcStatus.Code() {
			case codes.NotFound:
				return "", app.ErrSavedCoverFileNotFound
			case codes.Canceled, codes.DeadlineExceeded, codes.ResourceExhausted,
				codes.Aborted, codes.Unavailable:
				return "", app.ErrSavedCoverFileManagerUnavailable
			default:
				return "", app.ErrSavedCoverFileManagerBadResponse
			}
		}
		return "", app.ErrSavedCoverFileManagerUnavailable
	}
	if response == nil {
		return "", app.ErrSavedCoverFileManagerBadResponse
	}
	now := time.Now().UTC()
	if c.now != nil {
		now = c.now().UTC()
	}
	expiresAt, err := time.Parse(time.RFC3339, strings.TrimSpace(response.GetExpiresAt()))
	if err != nil {
		return "", app.ErrSavedCoverFileManagerBadResponse
	}
	remainingTTL := expiresAt.Sub(now)
	if remainingTTL < minimumSavedCoverSignedURLTTL ||
		remainingTTL > maximumSavedCoverSignedURLTTL {
		return "", app.ErrSavedCoverFileManagerBadResponse
	}
	return app.ValidateSavedCoverDownloadURL(response.GetUrl())
}
