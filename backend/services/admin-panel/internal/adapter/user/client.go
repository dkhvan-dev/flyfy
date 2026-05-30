package user

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	userv1 "kz/inflap/proto/gen/go/user/v1"
)

const defaultAdminUserTimeout = 3 * time.Second

type Client struct {
	conn          *grpc.ClientConn
	service       userv1.UserServiceClient
	internalToken string
	serviceName   string
	timeout       time.Duration
}

func New(target string, internalToken string, serviceName string, timeout time.Duration, opts ...grpc.DialOption) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
	}
	if timeout <= 0 {
		timeout = defaultAdminUserTimeout
	}

	conn, err := grpc.NewClient(strings.TrimSpace(target), opts...)
	if err != nil {
		return nil, err
	}

	return &Client{
		conn:          conn,
		service:       userv1.NewUserServiceClient(conn),
		internalToken: strings.TrimSpace(internalToken),
		serviceName:   strings.TrimSpace(serviceName),
		timeout:       timeout,
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ListAdminUsers(
	ctx context.Context,
	filter model.AdminUserListFilter,
) (model.AdminUserListPage, error) {
	callCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	callCtx = c.withInternalMetadata(callCtx)

	resp, err := c.service.ListAdminUsers(callCtx, &userv1.ListAdminUsersRequest{
		PageSize:       int32(filter.PageSize),
		PageToken:      filter.PageToken,
		Query:          filter.Query,
		Status:         filter.Status,
		Role:           filter.Role,
		CountryCode:    filter.CountryCode,
		CreatedFrom:    timestampPtr(filter.CreatedFrom),
		CreatedTo:      timestampPtr(filter.CreatedTo),
		LastActiveFrom: timestampPtr(filter.LastActiveFrom),
		LastActiveTo:   timestampPtr(filter.LastActiveTo),
	})
	if err != nil {
		return model.AdminUserListPage{}, mapUserServiceError(err)
	}

	items := make([]model.AdminUserListItem, 0, len(resp.GetUsers()))
	for _, item := range resp.GetUsers() {
		items = append(items, adminUserListItemFromProto(item))
	}

	return model.AdminUserListPage{
		Items:         items,
		NextPageToken: resp.GetNextPageToken(),
	}, nil
}

func (c *Client) GetAdminUserDetail(
	ctx context.Context,
	userID uuid.UUID,
) (model.AdminUserDetail, error) {
	callCtx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()
	callCtx = c.withInternalMetadata(callCtx)

	resp, err := c.service.GetAdminUserDetail(callCtx, &userv1.GetAdminUserDetailRequest{
		UserId: userID.String(),
	})
	if err != nil {
		return model.AdminUserDetail{}, mapUserServiceError(err)
	}

	return adminUserDetailFromProto(resp.GetUser())
}

func (c *Client) withInternalMetadata(ctx context.Context) context.Context {
	md := metadata.New(map[string]string{
		"x-internal-service-token": c.internalToken,
		"x-service-name":           c.serviceName,
	})
	return metadata.NewOutgoingContext(ctx, md)
}

func mapUserServiceError(err error) error {
	if st, ok := status.FromError(err); ok {
		switch st.Code() {
		case codes.NotFound:
			return app.ErrUserNotFound
		case codes.InvalidArgument:
			return app.ErrInvalidInput
		default:
			return err
		}
	}
	return err
}

func adminUserListItemFromProto(item *userv1.AdminUserListItem) model.AdminUserListItem {
	if item == nil {
		return model.AdminUserListItem{}
	}
	userID, _ := uuid.Parse(strings.TrimSpace(item.GetUserId()))
	return model.AdminUserListItem{
		UserID:        userID,
		DisplayName:   item.GetDisplayName(),
		MaskedPhone:   item.GetMaskedPhone(),
		MaskedEmail:   item.GetMaskedEmail(),
		CountryCode:   item.GetCountryCode(),
		Roles:         append([]string(nil), item.GetRoles()...),
		AccountStatus: item.GetAccountStatus(),
		GuideStatus:   item.GetGuideStatus(),
		CreatedAt:     timeFromProto(item.GetCreatedAt()),
		LastActiveAt:  timePtrFromProto(item.GetLastActiveAt()),
	}
}

func adminUserDetailFromProto(item *userv1.AdminUserDetail) (model.AdminUserDetail, error) {
	if item == nil {
		return model.AdminUserDetail{}, app.ErrUserNotFound
	}
	userID, err := uuid.Parse(strings.TrimSpace(item.GetUserId()))
	if err != nil {
		return model.AdminUserDetail{}, app.ErrInvalidInput
	}
	return model.AdminUserDetail{
		UserID:        userID,
		DisplayName:   item.GetDisplayName(),
		MaskedPhone:   item.GetMaskedPhone(),
		MaskedEmail:   item.GetMaskedEmail(),
		CountryCode:   item.GetCountryCode(),
		Roles:         append([]string(nil), item.GetRoles()...),
		AccountStatus: item.GetAccountStatus(),
		GuideStatus:   item.GetGuideStatus(),
		CreatedAt:     timeFromProto(item.GetCreatedAt()),
		UpdatedAt:     timeFromProto(item.GetUpdatedAt()),
		LastActiveAt:  timePtrFromProto(item.GetLastActiveAt()),
	}, nil
}

func timestampPtr(v *time.Time) *timestamppb.Timestamp {
	if v == nil {
		return nil
	}
	return timestamppb.New(*v)
}

func timePtrFromProto(v *timestamppb.Timestamp) *time.Time {
	if v == nil {
		return nil
	}
	t := v.AsTime()
	return &t
}

func timeFromProto(v *timestamppb.Timestamp) time.Time {
	if v == nil {
		return time.Time{}
	}
	return v.AsTime()
}
