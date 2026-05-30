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

	"kz/inflap/backend/services/excursion-service/internal/app"
	filev1 "kz/inflap/proto/gen/go/file/v1"
)

const (
	getFileTimeout     = 2 * time.Second
	bindFileTimeout    = 3 * time.Second
	downloadURLTimeout = 2 * time.Second
)

type Client struct {
	conn    *grpc.ClientConn
	service filev1.FileServiceClient
}

func New(target string, opts ...grpc.DialOption) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
	}
	conn, err := grpc.NewClient(strings.TrimSpace(target), opts...)
	if err != nil {
		return nil, err
	}
	return &Client{conn: conn, service: filev1.NewFileServiceClient(conn)}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ValidateExcursionCoverFile(ctx context.Context, fileID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, getFileTimeout)
	defer cancel()

	resp, err := c.service.GetFile(callCtx, &filev1.GetFileRequest{FileId: fileID.String()})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrExcursionCoverFileNotFound
			case codes.InvalidArgument:
				return app.ErrExcursionCoverFileNotAllowed
			}
		}
		return err
	}
	if strings.TrimSpace(resp.GetFileId()) == "" {
		return app.ErrExcursionCoverFileNotFound
	}
	if !strings.EqualFold(resp.GetStatus(), "READY") {
		return app.ErrExcursionCoverFileNotReady
	}
	if !strings.EqualFold(resp.GetPurpose(), "EXCURSION_MEDIA") &&
		!strings.EqualFold(resp.GetPurpose(), "ACTIVITY_MEDIA") &&
		!strings.EqualFold(resp.GetPurpose(), "ATTRACTION_MEDIA") {
		return app.ErrExcursionCoverFileNotAllowed
	}
	return nil
}

func (c *Client) BindExcursionCoverFile(ctx context.Context, fileID uuid.UUID, excursionID uuid.UUID, createdByUserID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, bindFileTimeout)
	defer cancel()

	_, err := c.service.BindFile(callCtx, &filev1.BindFileRequest{
		FileId:          fileID.String(),
		OwnerType:       "EXCURSION",
		OwnerId:         excursionID.String(),
		Purpose:         "EXCURSION_MEDIA",
		IsPrimary:       true,
		CreatedByUserId: createdByUserID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrExcursionCoverFileNotFound
			case codes.InvalidArgument:
				return app.ErrExcursionCoverFileNotAllowed
			}
		}
		return err
	}
	return nil
}

func (c *Client) CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error) {
	callCtx, cancel := context.WithTimeout(ctx, downloadURLTimeout)
	defer cancel()

	resp, err := c.service.CreateDownloadUrl(callCtx, &filev1.CreateDownloadUrlRequest{FileId: fileID.String()})
	if err != nil {
		if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
			return "", app.ErrExcursionCoverFileNotFound
		}
		return "", err
	}
	return strings.TrimSpace(resp.GetUrl()), nil
}
