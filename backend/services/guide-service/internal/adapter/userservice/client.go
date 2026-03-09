package userservice

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/app"
	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
)

const (
	defaultGetUserTimeout         = 2 * time.Second
	defaultListPublicUsersTimeout = 3 * time.Second
)

type Client struct {
	conn    *grpc.ClientConn
	service userv1.UserServiceClient
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
		service: userv1.NewUserServiceClient(conn),
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ValidateUserExists(ctx context.Context, userID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultGetUserTimeout)
	defer cancel()

	resp, err := c.service.GetUserById(callCtx, &userv1.GetUserByIdRequest{
		UserId: userID.String(),
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrUserNotFound
			case codes.InvalidArgument:
				return app.ErrInvalidGuideUserID
			default:
				return err
			}
		}
		return err
	}

	if resp.GetAggregate() == nil || resp.GetAggregate().GetUser() == nil || resp.GetAggregate().GetUser().GetId() == "" {
		return app.ErrUserNotFound
	}

	return nil
}

func (c *Client) GetPublicUserProfiles(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]app.PublicUserProfile, error) {
	if len(userIDs) == 0 {
		return map[uuid.UUID]app.PublicUserProfile{}, nil
	}

	callCtx, cancel := context.WithTimeout(ctx, defaultListPublicUsersTimeout)
	defer cancel()

	rawIDs := make([]string, 0, len(userIDs))
	for _, id := range userIDs {
		rawIDs = append(rawIDs, id.String())
	}

	resp, err := c.service.GetPublicProfilesByUserIds(callCtx, &userv1.GetPublicProfilesByUserIdsRequest{
		UserIds: rawIDs,
	})
	if err != nil {
		return nil, err
	}

	result := make(map[uuid.UUID]app.PublicUserProfile, len(resp.GetItems()))
	for _, item := range resp.GetItems() {
		userID, parseErr := uuid.Parse(strings.TrimSpace(item.GetUserId()))
		if parseErr != nil {
			continue
		}

		var avatarFileID *uuid.UUID
		if strings.TrimSpace(item.GetAvatarFileId()) != "" {
			if parsed, err := uuid.Parse(strings.TrimSpace(item.GetAvatarFileId())); err == nil {
				avatarFileID = &parsed
			}
		}

		var displayName *string
		if strings.TrimSpace(item.GetDisplayName()) != "" {
			v := strings.TrimSpace(item.GetDisplayName())
			displayName = &v
		}

		var countryCode *string
		if strings.TrimSpace(item.GetCountryCode()) != "" {
			v := strings.TrimSpace(item.GetCountryCode())
			countryCode = &v
		}

		result[userID] = app.PublicUserProfile{
			UserID:       userID,
			DisplayName:  displayName,
			AvatarFileID: avatarFileID,
			CountryCode:  countryCode,
			Locale:       item.GetLocale(),
			Timezone:     item.GetTimezone(),
			IsPublic:     item.GetIsPublic(),
		}
	}

	return result, nil
}
