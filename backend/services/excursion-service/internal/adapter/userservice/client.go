package userservice

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/grpc"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
)

const profileProjectionTimeout = 3 * time.Second

type Client struct {
	conn    *grpc.ClientConn
	service userv1.UserServiceClient
}

func New(target string, internalToken string, serviceName string, opts ...grpc.DialOption) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
	}
	opts = append(
		opts,
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			strings.TrimSpace(internalToken),
			strings.TrimSpace(serviceName),
		)),
	)
	conn, err := grpc.NewClient(strings.TrimSpace(target), opts...)
	if err != nil {
		return nil, err
	}
	return &Client{conn: conn, service: userv1.NewUserServiceClient(conn)}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) GetUserProfileProjections(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]port.UserProfileProjection, error) {
	if len(userIDs) == 0 {
		return map[uuid.UUID]port.UserProfileProjection{}, nil
	}

	callCtx, cancel := context.WithTimeout(ctx, profileProjectionTimeout)
	defer cancel()

	rawIDs := make([]string, 0, len(userIDs))
	for _, id := range userIDs {
		if id == uuid.Nil {
			continue
		}
		rawIDs = append(rawIDs, id.String())
	}
	if len(rawIDs) == 0 {
		return map[uuid.UUID]port.UserProfileProjection{}, nil
	}

	resp, err := c.service.GetPublicProfilesByUserIds(callCtx, &userv1.GetPublicProfilesByUserIdsRequest{
		UserIds: rawIDs,
	})
	if err != nil {
		return nil, err
	}

	result := make(map[uuid.UUID]port.UserProfileProjection, len(resp.GetItems()))
	for _, item := range resp.GetItems() {
		userID, parseErr := uuid.Parse(strings.TrimSpace(item.GetUserId()))
		if parseErr != nil {
			continue
		}
		var displayName *string
		if value := strings.TrimSpace(item.GetDisplayName()); value != "" {
			displayName = &value
		}
		var avatarFileID *uuid.UUID
		if value := strings.TrimSpace(item.GetAvatarFileId()); value != "" {
			if parsed, err := uuid.Parse(value); err == nil {
				avatarFileID = &parsed
			}
		}
		result[userID] = port.UserProfileProjection{
			UserID:       userID,
			DisplayName:  displayName,
			AvatarFileID: avatarFileID,
		}
	}
	return result, nil
}
