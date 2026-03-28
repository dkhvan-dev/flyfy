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

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/app"
	filev1 "github.com/dkhvan-dev/flyfy/proto/gen/go/file/v1"
)

const (
	defaultGetFileTimeout     = 2 * time.Second
	defaultBindFileTimeout    = 3 * time.Second
	defaultDownloadURLTimeout = 2 * time.Second
)

type Client struct {
	conn    *grpc.ClientConn
	service filev1.FileServiceClient
}

func New(target string, opts ...grpc.DialOption) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{
			grpc.WithTransportCredentials(insecure.NewCredentials()),
		}
	}

	conn, err := grpc.NewClient(strings.TrimSpace(target), opts...)
	if err != nil {
		return nil, err
	}

	return &Client{
		conn:    conn,
		service: filev1.NewFileServiceClient(conn),
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ValidateActivityMediaFile(ctx context.Context, fileID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultGetFileTimeout)
	defer cancel()

	resp, err := c.service.GetFile(callCtx, &filev1.GetFileRequest{
		FileId: fileID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrActivityMediaFileNotFound
			case codes.InvalidArgument:
				return app.ErrActivityMediaFileNotAllowed
			default:
				return err
			}
		}
		return err
	}

	if resp.GetFileId() == "" {
		return app.ErrActivityMediaFileNotFound
	}
	if strings.ToUpper(strings.TrimSpace(resp.GetStatus())) != "READY" {
		return app.ErrActivityMediaFileNotReady
	}
	if strings.ToUpper(strings.TrimSpace(resp.GetPurpose())) != "ACTIVITY_MEDIA" {
		return app.ErrActivityMediaFileNotAllowed
	}

	return nil
}

func (c *Client) BindActivityMediaToActivity(
	ctx context.Context,
	fileID uuid.UUID,
	activityID uuid.UUID,
	createdByUserID uuid.UUID,
) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultBindFileTimeout)
	defer cancel()

	req := &filev1.BindFileRequest{
		FileId:    fileID.String(),
		OwnerType: "ACTIVITY",
		OwnerId:   activityID.String(),
		Purpose:   "ACTIVITY_MEDIA",
		IsPrimary: true,
	}
	if createdByUserID != uuid.Nil {
		req.CreatedByUserId = createdByUserID.String()
	}

	_, err := c.service.BindFile(callCtx, req)
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrActivityMediaFileNotFound
			case codes.InvalidArgument:
				return app.ErrActivityMediaFileNotAllowed
			default:
				return err
			}
		}
		return err
	}

	return nil
}

func (c *Client) CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error) {
	callCtx, cancel := context.WithTimeout(ctx, defaultDownloadURLTimeout)
	defer cancel()

	resp, err := c.service.CreateDownloadUrl(callCtx, &filev1.CreateDownloadUrlRequest{
		FileId: fileID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
			return "", app.ErrActivityMediaFileNotFound
		}
		return "", err
	}

	return strings.TrimSpace(resp.GetUrl()), nil
}
