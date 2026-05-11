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

	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/adapter/grpc"
	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/app"
	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
)

const (
	defaultGetUserTimeout         = 2 * time.Second
	defaultListPublicUsersTimeout = 3 * time.Second
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
		service:       userv1.NewUserServiceClient(conn),
		internalToken: internalToken,
		serviceName:   serviceName,
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ValidateUserExists(ctx context.Context, userID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultGetUserTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", "")

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

func (c *Client) ResolveUserIDBySubject(ctx context.Context, subject string) (uuid.UUID, error) {
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return uuid.Nil, app.ErrUserNotFound
	}

	callCtx, cancel := context.WithTimeout(ctx, defaultGetUserTimeout)
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
			case codes.InvalidArgument:
				return uuid.Nil, app.ErrInvalidGuideUserID
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
		return uuid.Nil, app.ErrInvalidGuideUserID
	}

	return userID, nil
}

func (c *Client) GetPublicUserProfiles(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]app.PublicUserProfile, error) {
	if len(userIDs) == 0 {
		return map[uuid.UUID]app.PublicUserProfile{}, nil
	}

	callCtx, cancel := context.WithTimeout(ctx, defaultListPublicUsersTimeout)
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

func (c *Client) ListPublicUserIDsByCountryCodes(
	ctx context.Context,
	countryCodes []string,
) ([]uuid.UUID, error) {
	if len(countryCodes) == 0 {
		return []uuid.UUID{}, nil
	}

	callCtx, cancel := context.WithTimeout(ctx, defaultListPublicUsersTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", "")

	resp, err := c.service.ListPublicUserIdsByCountryCodes(
		callCtx,
		&userv1.ListPublicUserIdsByCountryCodesRequest{
			CountryCodes: countryCodes,
		},
	)
	if err != nil {
		return nil, err
	}

	result := make([]uuid.UUID, 0, len(resp.GetUserIds()))
	for _, raw := range resp.GetUserIds() {
		userID, parseErr := uuid.Parse(strings.TrimSpace(raw))
		if parseErr != nil {
			continue
		}
		result = append(result, userID)
	}

	return result, nil
}

func (c *Client) GrantGuideRole(ctx context.Context, userID uuid.UUID, grantedBy *uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultGetUserTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", "")

	req := &userv1.GrantUserRoleRequest{
		UserId: userID.String(),
		Role:   "GUIDE",
	}
	if grantedBy != nil && *grantedBy != uuid.Nil {
		req.GrantedBy = grantedBy.String()
	}

	_, err := c.service.GrantUserRole(callCtx, req)
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound:
				return app.ErrUserNotFound
			case codes.AlreadyExists:
				return nil
			case codes.InvalidArgument:
				return app.ErrInvalidGuideUserID
			default:
				return err
			}
		}
		return err
	}

	return nil
}
