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

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/app"
	filev1 "github.com/dkhvan-dev/flyfy/proto/gen/go/file/v1"
)

const (
	defaultGetFileTimeout  = 2 * time.Second
	defaultBindFileTimeout = 3 * time.Second
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

func (c *Client) ValidateAvatarFile(ctx context.Context, fileID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultGetFileTimeout)
	defer cancel()

	resp, err := c.service.GetFile(callCtx, &filev1.GetFileRequest{
		FileId: fileID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrAvatarFileNotFound
			case codes.InvalidArgument:
				return app.ErrAvatarFileNotAllowed
			default:
				return err
			}
		}
		return err
	}

	if resp.GetFileId() == "" {
		return app.ErrAvatarFileNotFound
	}
	if strings.ToUpper(strings.TrimSpace(resp.GetStatus())) != "READY" {
		return app.ErrAvatarFileNotReady
	}
	if strings.ToUpper(strings.TrimSpace(resp.GetPurpose())) != "AVATAR" {
		return app.ErrAvatarFileNotAllowed
	}

	return nil
}

func (c *Client) BindAvatarToUser(ctx context.Context, fileID uuid.UUID, userID uuid.UUID, createdByUserID *uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultBindFileTimeout)
	defer cancel()

	req := &filev1.BindFileRequest{
		FileId:    fileID.String(),
		OwnerType: "USER",
		OwnerId:   userID.String(),
		Purpose:   "AVATAR",
		IsPrimary: true,
	}

	if createdByUserID != nil && *createdByUserID != uuid.Nil {
		req.CreatedByUserId = createdByUserID.String()
	}

	_, err := c.service.BindFile(callCtx, req)
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrAvatarFileNotFound
			case codes.InvalidArgument:
				return app.ErrAvatarFileNotAllowed
			default:
				return err
			}
		}
		return err
	}

	return nil
}
