package tokenservice

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"

	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/adapter"
	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/config"
	tokenpb "github.com/dkhvan-dev/flyfy/proto/gen/go/token"
)

type Client struct {
	cfg     config.TokenServiceConfig
	conn    *grpc.ClientConn
	service tokenpb.TokenServiceClient

	mu           sync.RWMutex
	serviceToken string
}

func New(cfg config.TokenServiceConfig, opts ...grpc.DialOption) (*Client, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{
			grpc.WithTransportCredentials(insecure.NewCredentials()),
		}
	}

	conn, err := grpc.NewClient(strings.TrimSpace(cfg.Target), opts...)
	if err != nil {
		return nil, fmt.Errorf("create token-service grpc client: %w", err)
	}

	return &Client{
		cfg:     cfg,
		conn:    conn,
		service: tokenpb.NewTokenServiceClient(conn),
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) VerifyAccessToken(ctx context.Context, accessToken string) (*app.TokenClaims, error) {
	accessToken = strings.TrimSpace(accessToken)
	if accessToken == "" {
		return nil, fmt.Errorf("access token is required")
	}

	claims, err := c.verifyWithCachedServiceToken(ctx, accessToken)
	if err == nil {
		return claims, nil
	}

	if !adapter.IsAuthFailure(err) {
		return nil, err
	}

	c.resetServiceToken()

	claims, retryErr := c.verifyWithCachedServiceToken(ctx, accessToken)
	if retryErr != nil {
		return nil, retryErr
	}

	return claims, nil
}

func (c *Client) verifyWithCachedServiceToken(ctx context.Context, accessToken string) (*app.TokenClaims, error) {
	serviceToken, err := c.getOrAuthenticateServiceToken(ctx)
	if err != nil {
		return nil, err
	}

	callCtx, cancel := context.WithTimeout(ctx, c.timeout())
	defer cancel()

	callCtx = metadata.AppendToOutgoingContext(
		callCtx,
		"authorization", "Bearer "+serviceToken,
	)

	resp, err := c.service.ValidateAccessToken(callCtx, &tokenpb.ValidateTokenRequest{
		Token: accessToken,
	})
	if err != nil {
		return nil, fmt.Errorf("validate access token: %w", err)
	}

	claims := &app.TokenClaims{
		Subject: adapter.ValueOrEmpty(resp.GetSubject()),
		UserID:  adapter.ValueOrEmpty(resp.GetUserId()),
		Roles:   adapter.NormalizeRoles(resp.GetRoles(), resp.GetRole()),
	}

	if claims.Subject == "" {
		return nil, fmt.Errorf("token-service returned empty subject")
	}

	return claims, nil
}

func (c *Client) getOrAuthenticateServiceToken(ctx context.Context) (string, error) {
	c.mu.RLock()
	token := c.serviceToken
	c.mu.RUnlock()

	if strings.TrimSpace(token) != "" {
		return token, nil
	}

	return c.authenticateService(ctx)
}

func (c *Client) authenticateService(ctx context.Context) (string, error) {
	callCtx, cancel := context.WithTimeout(ctx, c.timeout())
	defer cancel()

	resp, err := c.service.AuthenticateService(callCtx, &tokenpb.AuthenticateServiceRequest{
		ServiceId:     c.cfg.ServiceID,
		ServiceSecret: c.cfg.ServiceSecret,
	})
	if err != nil {
		return "", fmt.Errorf("authenticate service in token-service: %w", err)
	}

	token := strings.TrimSpace(resp.GetToken())
	if token == "" {
		return "", fmt.Errorf("token-service returned empty service token")
	}

	c.mu.Lock()
	c.serviceToken = token
	c.mu.Unlock()

	return token, nil
}

func (c *Client) resetServiceToken() {
	c.mu.Lock()
	c.serviceToken = ""
	c.mu.Unlock()
}

func (c *Client) timeout() time.Duration {
	if c.cfg.CallTimeout <= 0 {
		return 3 * time.Second
	}
	return c.cfg.CallTimeout
}
