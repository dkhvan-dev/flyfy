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

	grpcadapter "kz/inflap/backend/services/stories-service/internal/adapter/grpc"
	"kz/inflap/backend/services/stories-service/internal/app"
	userv1 "kz/inflap/proto/gen/go/user/v1"
)

const (
	defaultResolveUserTimeout  = 2 * time.Second
	defaultListProfilesTimeout = 3 * time.Second
)

type Client struct {
	conn          *grpc.ClientConn
	service       userv1.UserServiceClient
	internalToken string
	serviceName   string
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
		conn:          conn,
		service:       userv1.NewUserServiceClient(conn),
		internalToken: internalToken,
		serviceName:   serviceName,
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ResolveUserIDBySubject(ctx context.Context, subject string) (uuid.UUID, error) {
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return uuid.Nil, app.ErrUserNotFound
	}

	callCtx, cancel := context.WithTimeout(ctx, defaultResolveUserTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", subject)

	resp, err := c.service.GetUserBySubject(callCtx, &userv1.GetUserBySubjectRequest{
		SubjectId: subject,
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return uuid.Nil, app.ErrUserNotFound
			default:
				return uuid.Nil, err
			}
		}
		return uuid.Nil, err
	}

	aggregate := resp.GetAggregate()
	if aggregate == nil || aggregate.GetUser() == nil || strings.TrimSpace(aggregate.GetUser().GetId()) == "" {
		return uuid.Nil, app.ErrUserNotFound
	}

	userID, err := uuid.Parse(strings.TrimSpace(aggregate.GetUser().GetId()))
	if err != nil {
		return uuid.Nil, app.ErrUserNotFound
	}

	return userID, nil
}

func (c *Client) GetPublicUserProfiles(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]app.PublicUserProfile, error) {
	if len(userIDs) == 0 {
		return map[uuid.UUID]app.PublicUserProfile{}, nil
	}

	callCtx, cancel := context.WithTimeout(ctx, defaultListProfilesTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", "")

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

		var nickname *string
		if strings.TrimSpace(item.GetNickname()) != "" {
			v := strings.TrimSpace(item.GetNickname())
			nickname = &v
		}

		var countryCode *string
		if strings.TrimSpace(item.GetCountryCode()) != "" {
			v := strings.TrimSpace(item.GetCountryCode())
			countryCode = &v
		}

		result[userID] = app.PublicUserProfile{
			UserID:       userID,
			Nickname:     nickname,
			AvatarFileID: avatarFileID,
			CountryCode:  countryCode,
			Locale:       item.GetLocale(),
			Timezone:     item.GetTimezone(),
		}
	}

	return result, nil
}
