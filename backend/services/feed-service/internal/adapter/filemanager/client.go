package filemanager

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	grpcadapter "kz/inflap/backend/services/feed-service/internal/adapter/grpc"
	"kz/inflap/backend/services/feed-service/internal/app"
	filev1 "kz/inflap/proto/gen/go/file/v1"
)

const (
	defaultBindFileTimeout = 3 * time.Second
	postOwnerType          = "POST"
	postMediaPurpose       = "POST_MEDIA"
)

type Client struct {
	conn    *grpc.ClientConn
	service filev1.FileServiceClient
}

func New(target string, internalToken string, serviceName string, opts ...grpc.DialOption) (*Client, error) {
	internalToken = strings.TrimSpace(internalToken)
	serviceName = strings.TrimSpace(serviceName)

	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
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
		conn:    conn,
		service: filev1.NewFileServiceClient(conn),
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) BindPostMedia(ctx context.Context, input app.PostMediaBindingInput) (app.PostMediaBindingResult, error) {
	if input.PostID == uuid.Nil || input.ActorUserID == uuid.Nil {
		return app.PostMediaBindingResult{}, app.ErrInvalidPostMedia
	}
	if len(input.FileIDs) == 0 {
		return app.PostMediaBindingResult{}, nil
	}

	primaryFileID := uuid.Nil
	if input.PrimaryFileID != nil {
		primaryFileID = *input.PrimaryFileID
	}

	result := app.PostMediaBindingResult{
		Files: make(map[uuid.UUID]app.PostMediaFileMetadata, len(input.FileIDs)),
	}
	for _, fileID := range bindOrder(input.FileIDs, primaryFileID) {
		if fileID == uuid.Nil {
			return app.PostMediaBindingResult{}, app.ErrInvalidPostMedia
		}

		file, err := c.getFile(ctx, fileID)
		if err != nil {
			return app.PostMediaBindingResult{}, err
		}

		callCtx, cancel := context.WithTimeout(ctx, defaultBindFileTimeout)
		_, err = c.service.BindFile(callCtx, &filev1.BindFileRequest{
			FileId:          fileID.String(),
			OwnerType:       postOwnerType,
			OwnerId:         input.PostID.String(),
			Purpose:         postMediaPurpose,
			IsPrimary:       fileID == primaryFileID,
			CreatedByUserId: input.ActorUserID.String(),
		})
		cancel()
		if err != nil {
			return app.PostMediaBindingResult{}, mapBindFileError(err)
		}
		result.Files[fileID] = fileMetadataFromProto(file)
	}

	return result, nil
}

func (c *Client) getFile(ctx context.Context, fileID uuid.UUID) (*filev1.GetFileResponse, error) {
	callCtx, cancel := context.WithTimeout(ctx, defaultBindFileTimeout)
	defer cancel()

	file, err := c.service.GetFile(callCtx, &filev1.GetFileRequest{
		FileId: fileID.String(),
	})
	if err != nil {
		return nil, mapBindFileError(err)
	}
	return file, nil
}

func fileMetadataFromProto(file *filev1.GetFileResponse) app.PostMediaFileMetadata {
	if file == nil {
		return app.PostMediaFileMetadata{}
	}

	return app.PostMediaFileMetadata{
		Width:           positiveInt32Ptr(file.GetWidth()),
		Height:          positiveInt32Ptr(file.GetHeight()),
		DurationMS:      positiveInt32Ptr(file.GetDurationMs()),
		ThumbnailFileID: uuidPtrFromString(file.GetThumbnailFileId()),
	}
}

func positiveInt32Ptr(value int32) *int {
	if value <= 0 {
		return nil
	}
	converted := int(value)
	return &converted
}

func uuidPtrFromString(value string) *uuid.UUID {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	parsed, err := uuid.Parse(value)
	if err != nil || parsed == uuid.Nil {
		return nil
	}
	return &parsed
}

func bindOrder(fileIDs []uuid.UUID, primaryFileID uuid.UUID) []uuid.UUID {
	if primaryFileID == uuid.Nil {
		return append([]uuid.UUID(nil), fileIDs...)
	}

	ordered := make([]uuid.UUID, 0, len(fileIDs))
	for _, fileID := range fileIDs {
		if fileID != primaryFileID {
			ordered = append(ordered, fileID)
		}
	}
	for _, fileID := range fileIDs {
		if fileID == primaryFileID {
			ordered = append(ordered, fileID)
			break
		}
	}
	return ordered
}

func mapBindFileError(err error) error {
	st, ok := status.FromError(err)
	if !ok {
		return err
	}

	switch st.Code() {
	case codes.InvalidArgument,
		codes.NotFound,
		codes.FailedPrecondition,
		codes.PermissionDenied,
		codes.Aborted:
		return fmt.Errorf("%w: %s", app.ErrInvalidPostMedia, st.Message())
	default:
		return err
	}
}
