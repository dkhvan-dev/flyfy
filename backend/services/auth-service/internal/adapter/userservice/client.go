package userservice

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/auth-service/internal/config"
	userv1 "kz/inflap/proto/gen/go/user/v1"
)

const defaultResolveNicknameTimeout = 2 * time.Second

type Client struct {
	conn          *grpc.ClientConn
	service       userv1.UserServiceClient
	internalToken string
	serviceName   string
}

func New(cfg config.UserServiceConfig, opts ...grpc.DialOption) (*Client, error) {
	target := strings.TrimSpace(cfg.GRPCTarget)
	if target == "" {
		return nil, fmt.Errorf("user-service grpc target is required")
	}

	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
	}

	conn, err := grpc.NewClient(target, opts...)
	if err != nil {
		return nil, fmt.Errorf("connect user-service: %w", err)
	}

	return &Client{
		conn:          conn,
		service:       userv1.NewUserServiceClient(conn),
		internalToken: strings.TrimSpace(cfg.InternalServiceToken),
		serviceName:   strings.TrimSpace(cfg.ServiceName),
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ResolveUserIDByNickname(ctx context.Context, nickname string) (uuid.UUID, error) {
	nickname = strings.TrimSpace(nickname)
	if nickname == "" || c.internalToken == "" {
		return uuid.Nil, nil
	}

	callCtx, cancel := context.WithTimeout(ctx, defaultResolveNicknameTimeout)
	defer cancel()
	callCtx = c.withInternalMetadata(callCtx)

	resp, err := c.service.ResolveUserByNickname(callCtx, &userv1.ResolveUserByNicknameRequest{
		Nickname: nickname,
	})
	if err != nil {
		if st, ok := status.FromError(err); ok {
			switch st.Code() {
			case codes.NotFound, codes.InvalidArgument:
				return uuid.Nil, nil
			}
		}
		return uuid.Nil, fmt.Errorf("ResolveUserByNickname RPC: %w", err)
	}

	authSubjectID := strings.TrimSpace(resp.GetAuthSubjectId())
	if authSubjectID == "" {
		authSubjectID = strings.TrimSpace(resp.GetUserId())
	}

	userID, err := uuid.Parse(authSubjectID)
	if err != nil {
		return uuid.Nil, nil
	}
	return userID, nil
}

func (c *Client) withInternalMetadata(ctx context.Context) context.Context {
	md := metadata.New(map[string]string{
		"x-internal-service-token": c.internalToken,
		"x-service-name":           c.serviceName,
	})
	return metadata.NewOutgoingContext(ctx, md)
}
