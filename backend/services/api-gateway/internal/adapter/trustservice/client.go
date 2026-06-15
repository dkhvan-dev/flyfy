package trustservice

import (
	"context"
	"fmt"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"

	"kz/inflap/backend/services/api-gateway/internal/config"
	trustv1 "kz/inflap/proto/gen/go/trust/v1"
)

const defaultCallTimeout = 3 * time.Second

type Client struct {
	cfg           config.TrustServiceConfig
	internalToken string
	conn          *grpc.ClientConn
	service       trustv1.TrustServiceClient
}

func New(cfg config.TrustServiceConfig, internalToken string, opts ...grpc.DialOption) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{
			grpc.WithTransportCredentials(insecure.NewCredentials()),
		}
	}

	conn, err := grpc.NewClient(strings.TrimSpace(cfg.Target), opts...)
	if err != nil {
		return nil, fmt.Errorf("create trust-service grpc client: %w", err)
	}

	return &Client{
		cfg:           cfg,
		internalToken: strings.TrimSpace(internalToken),
		conn:          conn,
		service:       trustv1.NewTrustServiceClient(conn),
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) GetTrustProfile(ctx context.Context, userID string, requestID string, subject string) (*trustv1.GetTrustProfileResponse, error) {
	callCtx, cancel := c.callContext(ctx, requestID, subject)
	defer cancel()

	return c.service.GetTrustProfile(callCtx, &trustv1.GetTrustProfileRequest{
		UserId: strings.TrimSpace(userID),
	})
}

func (c *Client) ListRestrictionAppeals(ctx context.Context, userID string, status trustv1.RestrictionAppealStatus, requestID string, subject string) (*trustv1.ListRestrictionAppealsResponse, error) {
	callCtx, cancel := c.callContext(ctx, requestID, subject)
	defer cancel()

	return c.service.ListRestrictionAppeals(callCtx, &trustv1.ListRestrictionAppealsRequest{
		UserId: strings.TrimSpace(userID),
		Status: status,
	})
}

func (c *Client) SubmitRestrictionAppeal(ctx context.Context, req *trustv1.SubmitRestrictionAppealRequest, requestID string, subject string) (*trustv1.SubmitRestrictionAppealResponse, error) {
	callCtx, cancel := c.callContext(ctx, requestID, subject)
	defer cancel()

	return c.service.SubmitRestrictionAppeal(callCtx, req)
}

func (c *Client) callContext(ctx context.Context, requestID string, subject string) (context.Context, context.CancelFunc) {
	timeout := c.cfg.CallTimeout
	if timeout <= 0 {
		timeout = defaultCallTimeout
	}

	callCtx, cancel := context.WithTimeout(ctx, timeout)
	serviceName := strings.TrimSpace(c.cfg.ServiceName)
	if serviceName == "" {
		serviceName = "api-gateway"
	}
	callCtx = metadata.AppendToOutgoingContext(
		callCtx,
		"x-internal-service-token", c.internalToken,
		"x-service-name", serviceName,
		"x-request-id", strings.TrimSpace(requestID),
		"x-subject", strings.TrimSpace(subject),
	)
	return callCtx, cancel
}
