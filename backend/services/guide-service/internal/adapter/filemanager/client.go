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

	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/adapter/grpc"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/app"
	filev1 "github.com/dkhvan-dev/flyfy/proto/gen/go/file/v1"
)

const (
	defaultGetFileTimeout     = 2 * time.Second
	defaultBindFileTimeout    = 3 * time.Second
	defaultDownloadURLTimeout = 3 * time.Second
)

type Client struct {
	conn          *grpc.ClientConn
	service       filev1.FileServiceClient
	internalToken string
	serviceName   string
}

func New(target string, internalToken string, serviceName string, opts ...grpc.DialOption) (*Client, error) {
	internalToken = strings.TrimSpace(internalToken)
	serviceName = strings.TrimSpace(serviceName)

	if len(opts) == 0 {
		opts = []grpc.DialOption{
			grpc.WithTransportCredentials(insecure.NewCredentials()),
		}
	}
	opts = append(
		opts,
		grpc.WithChainUnaryInterceptor(
			grpcadapter.InternalTokenInterceptor(internalToken, serviceName),
		),
	)

	conn, err := grpc.NewClient(strings.TrimSpace(target), opts...)
	if err != nil {
		return nil, err
	}

	return &Client{
		conn:          conn,
		service:       filev1.NewFileServiceClient(conn),
		internalToken: internalToken,
		serviceName:   serviceName,
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ValidateGuideDocumentFile(ctx context.Context, fileID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultGetFileTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", "")

	resp, err := c.service.GetFile(callCtx, &filev1.GetFileRequest{
		FileId: fileID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrGuideDocumentFileNotFound
			case codes.InvalidArgument:
				return app.ErrGuideDocumentFileNotAllowed
			default:
				return err
			}
		}
		return err
	}

	if resp.GetFileId() == "" {
		return app.ErrGuideDocumentFileNotFound
	}
	if strings.ToUpper(strings.TrimSpace(resp.GetStatus())) != "READY" {
		return app.ErrGuideDocumentFileNotReady
	}
	if strings.ToUpper(strings.TrimSpace(resp.GetPurpose())) != "GUIDE_VERIFICATION_DOC" {
		return app.ErrGuideDocumentFileNotAllowed
	}

	return nil
}

func (c *Client) CreateGuideDocumentDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error) {
	callCtx, cancel := context.WithTimeout(ctx, defaultDownloadURLTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", "")

	resp, err := c.service.CreateDownloadUrl(callCtx, &filev1.CreateDownloadUrlRequest{
		FileId: fileID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return "", app.ErrGuideDocumentFileNotFound
			case codes.InvalidArgument:
				return "", app.ErrGuideDocumentFileNotAllowed
			default:
				return "", err
			}
		}
		return "", err
	}
	return strings.TrimSpace(resp.GetUrl()), nil
}

func (c *Client) BindGuideDocumentToVerificationRequest(
	ctx context.Context,
	fileID uuid.UUID,
	verificationRequestID uuid.UUID,
	createdByUserID *uuid.UUID,
) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultBindFileTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", "")

	req := &filev1.BindFileRequest{
		FileId:    fileID.String(),
		OwnerType: "GUIDE_VERIFICATION_REQUEST",
		OwnerId:   verificationRequestID.String(),
		Purpose:   "GUIDE_VERIFICATION_DOC",
		IsPrimary: false,
	}

	if createdByUserID != nil && *createdByUserID != uuid.Nil {
		req.CreatedByUserId = createdByUserID.String()
	}

	_, err := c.service.BindFile(callCtx, req)
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrGuideDocumentFileNotFound
			case codes.InvalidArgument:
				return app.ErrGuideDocumentFileNotAllowed
			default:
				return err
			}
		}
		return err
	}

	return nil
}
