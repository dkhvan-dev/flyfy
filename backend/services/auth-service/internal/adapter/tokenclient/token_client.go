package tokenclient

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/rs/zerolog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/auth-service/internal/config"
	"kz/inflap/backend/services/auth-service/internal/domain/model"
	"kz/inflap/backend/services/auth-service/internal/domain/port"
	tokenpb "kz/inflap/proto/gen/go/token"
)

type TokenServiceClient struct {
	conn   *grpc.ClientConn
	client tokenpb.TokenServiceClient
	cfg    config.TokenServiceConfig
	logger zerolog.Logger

	mu           sync.RWMutex
	serviceToken string
	tokenExpiry  time.Time
}

func NewTokenServiceClient(cfg config.TokenServiceConfig, logger zerolog.Logger, opts ...grpc.DialOption) (*TokenServiceClient, error) {
	if len(opts) == 0 {
		opts = []grpc.DialOption{grpc.WithTransportCredentials(insecure.NewCredentials())}
	}
	conn, err := grpc.NewClient(cfg.Addr, opts...)
	if err != nil {
		return nil, fmt.Errorf("connecting to token-service at %s: %w", cfg.Addr, err)
	}

	return &TokenServiceClient{
		conn:   conn,
		client: tokenpb.NewTokenServiceClient(conn),
		cfg:    cfg,
		logger: logger.With().Str("component", "token_client").Logger(),
	}, nil
}

func (c *TokenServiceClient) Close() error {
	return c.conn.Close()
}

func (c *TokenServiceClient) getServiceToken(ctx context.Context) (string, error) {
	c.mu.RLock()
	if c.serviceToken != "" && time.Now().Before(c.tokenExpiry.Add(-1*time.Minute)) {
		token := c.serviceToken
		c.mu.RUnlock()
		return token, nil
	}
	c.mu.RUnlock()

	c.mu.Lock()
	defer c.mu.Unlock()

	if c.serviceToken != "" && time.Now().Before(c.tokenExpiry.Add(-1*time.Minute)) {
		return c.serviceToken, nil
	}

	c.logger.Info().Msg("requesting new S2S service token from token-service")

	token, expiresAt, err := c.authenticateService(ctx)
	if err != nil {
		return "", fmt.Errorf("S2S authentication failed: %w", err)
	}

	c.serviceToken = token
	c.tokenExpiry = expiresAt

	c.logger.Info().
		Time("expires_at", expiresAt).
		Msg("S2S service token obtained")

	return token, nil
}

func (c *TokenServiceClient) withServiceAuth(ctx context.Context) (context.Context, error) {
	token, err := c.getServiceToken(ctx)
	if err != nil {
		return nil, err
	}

	md := metadata.Pairs("authorization", "Bearer "+token)
	return metadata.NewOutgoingContext(ctx, md), nil
}

func (c *TokenServiceClient) authenticateService(ctx context.Context) (string, time.Time, error) {
	req := &tokenpb.AuthenticateServiceRequest{
		ServiceId:     c.cfg.ServiceID,
		ServiceSecret: c.cfg.ServiceSecret,
	}

	resp, err := c.client.AuthenticateService(ctx, req)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("AuthenticateService RPC: %w", err)
	}

	if resp.GetExpiresAt() == nil {
		return "", time.Time{}, fmt.Errorf("AuthenticateService RPC: missing expires_at")
	}

	return resp.GetToken(), resp.GetExpiresAt().AsTime(), nil
}

func (c *TokenServiceClient) invalidateServiceToken() {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.serviceToken = ""
	c.tokenExpiry = time.Time{}
}

func isUnauthenticatedRPC(err error) bool {
	st, ok := status.FromError(err)
	return ok && st.Code() == codes.Unauthenticated
}

func (c *TokenServiceClient) GenerateUserTokens(
	ctx context.Context,
	userID, role string,
	permissions []string,
	device model.DeviceInfo,
) (*model.AuthResult, error) {
	authCtx, err := c.withServiceAuth(ctx)
	if err != nil {
		return nil, err
	}

	req := &tokenpb.GenerateUserTokensRequest{
		UserId:      userID,
		Role:        role,
		Permissions: permissions,
		Device:      deviceToProto(device),
	}

	resp, err := c.client.GenerateUserTokens(authCtx, req)
	if err != nil && isUnauthenticatedRPC(err) {
		c.invalidateServiceToken()
		retryCtx, retryErr := c.withServiceAuth(ctx)
		if retryErr == nil {
			resp, err = c.client.GenerateUserTokens(retryCtx, req)
		}
	}
	if err != nil {
		return nil, fmt.Errorf("GenerateUserTokens RPC: %w", err)
	}

	return tokenPairRespToAuthResult(resp), nil
}

func (c *TokenServiceClient) RefreshTokens(ctx context.Context, refreshToken string, device model.DeviceInfo) (*model.AuthResult, error) {
	authCtx, err := c.withServiceAuth(ctx)
	if err != nil {
		return nil, err
	}

	req := &tokenpb.RefreshTokensRequest{
		RefreshToken: refreshToken,
		Device:       deviceToProto(device),
	}

	resp, err := c.client.RefreshTokens(authCtx, req)
	if err != nil && isUnauthenticatedRPC(err) {
		c.invalidateServiceToken()
		retryCtx, retryErr := c.withServiceAuth(ctx)
		if retryErr == nil {
			resp, err = c.client.RefreshTokens(retryCtx, req)
		}
	}
	if err != nil {
		return nil, fmt.Errorf("RefreshTokens RPC: %w", err)
	}

	return tokenPairRespToAuthResult(resp), nil
}

func (c *TokenServiceClient) RevokeToken(ctx context.Context, jti string, expiresAt int64, reason string) error {
	authCtx, err := c.withServiceAuth(ctx)
	if err != nil {
		return err
	}

	req := &tokenpb.RevokeTokenRequest{
		Jti:    jti,
		Exp:    expiresAt,
		Reason: reason,
	}

	_, err = c.client.RevokeToken(authCtx, req)
	if err != nil && isUnauthenticatedRPC(err) {
		c.invalidateServiceToken()
		retryCtx, retryErr := c.withServiceAuth(ctx)
		if retryErr == nil {
			_, err = c.client.RevokeToken(retryCtx, req)
		}
	}
	if err != nil {
		return fmt.Errorf("RevokeToken RPC: %w", err)
	}

	return nil
}

func (c *TokenServiceClient) ValidateAccessToken(ctx context.Context, token string) (*port.TokenClaims, error) {
	authCtx, err := c.withServiceAuth(ctx)
	if err != nil {
		return nil, err
	}

	req := &tokenpb.ValidateTokenRequest{
		Token: token,
	}

	resp, err := c.client.ValidateAccessToken(authCtx, req)
	if err != nil && isUnauthenticatedRPC(err) {
		c.invalidateServiceToken()
		retryCtx, retryErr := c.withServiceAuth(ctx)
		if retryErr == nil {
			resp, err = c.client.ValidateAccessToken(retryCtx, req)
		}
	}
	if err != nil {
		return nil, fmt.Errorf("ValidateAccessToken RPC: %w", err)
	}

	var exp int64
	if resp.GetExpiresAt() != nil {
		exp = resp.GetExpiresAt().AsTime().Unix()
	}

	return &port.TokenClaims{
		Subject:     resp.GetSubject(),
		Role:        resp.GetRole(),
		Permissions: resp.GetPermissions(),
		JTI:         resp.GetJti(),
		SessionID:   resp.GetSessionId(),
		ExpiresAt:   exp,
	}, nil
}

func (c *TokenServiceClient) ValidateRefreshToken(ctx context.Context, token string) (*port.TokenClaims, error) {
	authCtx, err := c.withServiceAuth(ctx)
	if err != nil {
		return nil, err
	}

	req := &tokenpb.ValidateTokenRequest{
		Token: token,
	}

	resp, err := c.client.ValidateRefreshToken(authCtx, req)
	if err != nil && isUnauthenticatedRPC(err) {
		c.invalidateServiceToken()
		retryCtx, retryErr := c.withServiceAuth(ctx)
		if retryErr == nil {
			resp, err = c.client.ValidateRefreshToken(retryCtx, req)
		}
	}
	if err != nil {
		return nil, fmt.Errorf("ValidateRefreshToken RPC: %w", err)
	}

	var exp int64
	if resp.GetExpiresAt() != nil {
		exp = resp.GetExpiresAt().AsTime().Unix()
	}

	return &port.TokenClaims{
		Subject:     resp.GetSubject(),
		Role:        resp.GetRole(),
		Permissions: resp.GetPermissions(),
		JTI:         resp.GetJti(),
		SessionID:   resp.GetSessionId(),
		ExpiresAt:   exp,
	}, nil
}

// RevokeSession revokes a single user session by id (preferred over RevokeToken).
func (c *TokenServiceClient) RevokeSession(ctx context.Context, sessionID, reason string) error {
	authCtx, err := c.withServiceAuth(ctx)
	if err != nil {
		return err
	}

	req := &tokenpb.RevokeSessionRequest{
		SessionId: sessionID,
		Reason:    reason,
	}

	_, err = c.client.RevokeSession(authCtx, req)
	if err != nil && isUnauthenticatedRPC(err) {
		c.invalidateServiceToken()
		retryCtx, retryErr := c.withServiceAuth(ctx)
		if retryErr == nil {
			_, err = c.client.RevokeSession(retryCtx, req)
		}
	}
	if err != nil {
		return fmt.Errorf("RevokeSession RPC: %w", err)
	}
	return nil
}

// --- helpers ---

func deviceToProto(d model.DeviceInfo) *tokenpb.DeviceInfo {
	if d == (model.DeviceInfo{}) {
		return nil
	}
	return &tokenpb.DeviceInfo{
		DeviceId:   d.DeviceID,
		Platform:   d.Platform,
		OsVersion:  d.OSVersion,
		AppVersion: d.AppVersion,
		Model:      d.Model,
		UserAgent:  d.UserAgent,
		IpAddress:  d.IPAddress,
	}
}

func tokenPairRespToAuthResult(resp *tokenpb.TokenPairResponse) *model.AuthResult {
	out := &model.AuthResult{
		AccessToken:  resp.GetAccessToken(),
		RefreshToken: resp.GetRefreshToken(),
		TokenType:    resp.GetTokenType(),
		SessionID:    resp.GetSessionId(),
	}
	if resp.GetExpiresAt() != nil {
		out.ExpiresAt = resp.GetExpiresAt().AsTime()
	}
	if resp.GetRefreshExpiresAt() != nil {
		out.RefreshExpiresAt = resp.GetRefreshExpiresAt().AsTime()
	}
	return out
}
