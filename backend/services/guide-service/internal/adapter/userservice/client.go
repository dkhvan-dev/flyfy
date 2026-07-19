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

	grpcadapter "kz/inflap/backend/services/guide-service/internal/adapter/grpc"
	"kz/inflap/backend/services/guide-service/internal/app"
	userv1 "kz/inflap/proto/gen/go/user/v1"
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

var _ app.SavedGuideUserSource = (*Client)(nil)

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

func (c *Client) GetUserProfile(ctx context.Context, userID uuid.UUID) (*app.PublicUserProfile, error) {
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
				return nil, app.ErrUserNotFound
			case codes.InvalidArgument:
				return nil, app.ErrInvalidGuideUserID
			default:
				return nil, err
			}
		}
		return nil, err
	}

	profile := resp.GetAggregate().GetProfile()
	if profile == nil || strings.TrimSpace(profile.GetUserId()) == "" {
		return nil, app.ErrUserNotFound
	}
	profileUserID, err := uuid.Parse(strings.TrimSpace(profile.GetUserId()))
	if err != nil {
		return nil, app.ErrInvalidGuideUserID
	}

	var avatarFileID *uuid.UUID
	if strings.TrimSpace(profile.GetAvatarFileId()) != "" {
		if parsed, parseErr := uuid.Parse(strings.TrimSpace(profile.GetAvatarFileId())); parseErr == nil {
			avatarFileID = &parsed
		}
	}

	return &app.PublicUserProfile{
		UserID:       profileUserID,
		FirstName:    optionalString(profile.GetFirstName()),
		LastName:     optionalString(profile.GetLastName()),
		Nickname:     optionalString(profile.GetNickname()),
		AvatarFileID: avatarFileID,
		CountryCode:  optionalString(profile.GetCountryCode()),
		Locale:       profile.GetLocale(),
		Timezone:     profile.GetTimezone(),
	}, nil
}

func (c *Client) GetSavedGuideUserSnapshot(
	ctx context.Context,
	userID uuid.UUID,
) (*app.SavedGuideUserSnapshot, error) {
	if userID == uuid.Nil {
		return nil, app.ErrInvalidGuideUserID
	}
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
				return nil, app.ErrUserNotFound
			case codes.InvalidArgument:
				return nil, app.ErrInvalidGuideUserID
			}
		}
		return nil, err
	}

	aggregate := resp.GetAggregate()
	if aggregate == nil || aggregate.GetUser() == nil || aggregate.GetProfile() == nil {
		return nil, app.ErrUserNotFound
	}
	user := aggregate.GetUser()
	profile := aggregate.GetProfile()
	resolvedUserID, err := parseCanonicalUserID(user.GetId())
	if err != nil || resolvedUserID != userID {
		return nil, app.ErrInvalidGuideUserID
	}
	profileUserID, err := parseCanonicalUserID(profile.GetUserId())
	if err != nil || profileUserID != userID {
		return nil, app.ErrInvalidGuideUserID
	}
	accountUpdatedAt, err := parseRequiredSourceTime(user.GetUpdatedAt())
	if err != nil {
		return nil, err
	}
	profileUpdatedAt, err := parseRequiredSourceTime(profile.GetUpdatedAt())
	if err != nil {
		return nil, err
	}

	var avatarFileID *uuid.UUID
	if rawAvatarFileID := profile.GetAvatarFileId(); rawAvatarFileID != "" {
		parsed, parseErr := parseCanonicalUserID(rawAvatarFileID)
		if parseErr != nil {
			return nil, parseErr
		}
		avatarFileID = &parsed
	}

	return &app.SavedGuideUserSnapshot{
		UserID:           userID,
		AccountStatus:    strings.TrimSpace(user.GetStatus()),
		IsDeleted:        user.GetIsDeleted(),
		FirstName:        optionalString(profile.GetFirstName()),
		LastName:         optionalString(profile.GetLastName()),
		Nickname:         optionalString(profile.GetNickname()),
		AvatarFileID:     avatarFileID,
		CountryCode:      optionalString(profile.GetCountryCode()),
		Locale:           strings.TrimSpace(profile.GetLocale()),
		AccountUpdatedAt: accountUpdatedAt,
		ProfileUpdatedAt: profileUpdatedAt,
	}, nil
}

func parseCanonicalUserID(raw string) (uuid.UUID, error) {
	if raw == "" || raw != strings.TrimSpace(raw) || len(raw) != len(uuid.Nil.String()) {
		return uuid.Nil, app.ErrInvalidGuideUserID
	}
	parsed, err := uuid.Parse(raw)
	if err != nil || parsed == uuid.Nil || parsed.String() != raw {
		return uuid.Nil, app.ErrInvalidGuideUserID
	}
	return parsed, nil
}

func parseRequiredSourceTime(raw string) (time.Time, error) {
	if raw == "" || raw != strings.TrimSpace(raw) {
		return time.Time{}, app.ErrSavedSourceUnavailable
	}
	parsed, err := time.Parse(time.RFC3339Nano, raw)
	if err != nil || parsed.IsZero() || parsed.UTC().UnixMicro() <= 0 {
		return time.Time{}, app.ErrSavedSourceUnavailable
	}
	return parsed.UTC(), nil
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

		result[userID] = app.PublicUserProfile{
			UserID:       userID,
			FirstName:    optionalString(item.GetFirstName()),
			LastName:     optionalString(item.GetLastName()),
			Nickname:     optionalString(item.GetNickname()),
			AvatarFileID: avatarFileID,
			CountryCode:  optionalString(item.GetCountryCode()),
			Locale:       item.GetLocale(),
			Timezone:     item.GetTimezone(),
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

func (c *Client) RevokeGuideRole(ctx context.Context, userID uuid.UUID) error {
	callCtx, cancel := context.WithTimeout(ctx, defaultGetUserTimeout)
	defer cancel()
	callCtx = WithInternalMetadata(callCtx, c.internalToken, c.serviceName, "", "")

	_, err := c.service.RevokeUserRole(callCtx, &userv1.RevokeUserRoleRequest{
		UserId: userID.String(),
		Role:   "GUIDE",
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

	return nil
}

func optionalString(value string) *string {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	return &value
}
