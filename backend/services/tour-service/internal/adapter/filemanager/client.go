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

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/app"
	filev1 "github.com/dkhvan-dev/flyfy/proto/gen/go/file/v1"
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

func (c *Client) ValidateTourCoverFile(ctx context.Context, fileID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, getFileTimeout)
	defer cancel()

	resp, err := c.service.GetFile(callCtx, &filev1.GetFileRequest{FileId: fileID.String()})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrTourCoverFileNotFound
			case codes.InvalidArgument:
				return app.ErrTourCoverFileNotAllowed
			}
		}
		return err
	}
	if strings.TrimSpace(resp.GetFileId()) == "" {
		return app.ErrTourCoverFileNotFound
	}
	if !strings.EqualFold(resp.GetStatus(), "READY") {
		return app.ErrTourCoverFileNotReady
	}
	if !strings.EqualFold(resp.GetPurpose(), "TOUR_MEDIA") &&
		!strings.EqualFold(resp.GetPurpose(), "ACTIVITY_MEDIA") &&
		!strings.EqualFold(resp.GetPurpose(), "ATTRACTION_MEDIA") {
		return app.ErrTourCoverFileNotAllowed
	}
	return nil
}

func (c *Client) BindTourCoverFile(ctx context.Context, fileID uuid.UUID, tourID uuid.UUID, createdByUserID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, bindFileTimeout)
	defer cancel()

	_, err := c.service.BindFile(callCtx, &filev1.BindFileRequest{
		FileId:          fileID.String(),
		OwnerType:       "TOUR",
		OwnerId:         tourID.String(),
		Purpose:         "TOUR_MEDIA",
		IsPrimary:       true,
		CreatedByUserId: createdByUserID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrTourCoverFileNotFound
			case codes.InvalidArgument:
				return app.ErrTourCoverFileNotAllowed
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
			return "", app.ErrTourCoverFileNotFound
		}
		return "", err
	}
	return strings.TrimSpace(resp.GetUrl()), nil
}
