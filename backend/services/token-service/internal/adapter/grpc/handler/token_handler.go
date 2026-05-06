package handler

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/port"
)

// TokenGRPCHandler bridges the gRPC TokenService surface to the use case ports.
type TokenGRPCHandler struct {
	generator     port.TokenGenerator
	validator     port.TokenValidator
	refresher     port.TokenRefresher
	revoker       port.TokenRevoker
	sessions      port.SessionManager
	authenticator port.ServiceAuthenticator
	logger        zerolog.Logger
}

func NewTokenGRPCHandler(
	gen port.TokenGenerator,
	val port.TokenValidator,
	refresher port.TokenRefresher,
	rev port.TokenRevoker,
	sessions port.SessionManager,
	auth port.ServiceAuthenticator,
	logger zerolog.Logger,
) *TokenGRPCHandler {
	return &TokenGRPCHandler{
		generator:     gen,
		validator:     val,
		refresher:     refresher,
		revoker:       rev,
		sessions:      sessions,
		authenticator: auth,
		logger:        logger.With().Str("component", "grpc_handler").Logger(),
	}
}

// --- User Token Methods ---

// GenerateUserTokens creates access + refresh tokens for a user and a fresh session.
func (h *TokenGRPCHandler) GenerateUserTokens(
	ctx context.Context,
	userID, role string,
	permissions []string,
	device model.DeviceInfo,
) (*TokenPairResult, error) {
	uid, err := uuid.Parse(userID)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid user_id: %v", err)
	}

	pair, err := h.generator.GenerateUserTokens(ctx, model.UserClaims{
		UserID:      uid,
		Type:        model.TokenTypeUser,
		Role:        model.UserRole(role),
		Permissions: permissions,
	}, device)
	if err != nil {
		h.logger.Error().Err(err).Str("user_id", userID).Msg("failed to generate user tokens")
		return nil, status.Errorf(codes.Internal, "token generation failed")
	}

	return tokenPairToResult(pair), nil
}

// ValidateAccessToken validates a user access token.
func (h *TokenGRPCHandler) ValidateAccessToken(ctx context.Context, token string) (*ValidatedClaimsResult, error) {
	claims, err := h.validator.ValidateAccessToken(ctx, token)
	if err != nil {
		return nil, h.mapValidationError(err)
	}
	return claimsToResult(claims), nil
}

// ValidateRefreshToken validates a user refresh token.
func (h *TokenGRPCHandler) ValidateRefreshToken(ctx context.Context, token string) (*ValidatedClaimsResult, error) {
	claims, err := h.validator.ValidateRefreshToken(ctx, token)
	if err != nil {
		return nil, h.mapValidationError(err)
	}
	return claimsToResult(claims), nil
}

// RefreshTokens validates a refresh token, applies reuse detection, rotates the
// session's refresh JTI, and issues a new pair.
func (h *TokenGRPCHandler) RefreshTokens(ctx context.Context, refreshToken string, device model.DeviceInfo) (*TokenPairResult, error) {
	pair, err := h.refresher.RefreshTokens(ctx, refreshToken, device)
	if err != nil {
		return nil, h.mapValidationError(err)
	}
	return tokenPairToResult(pair), nil
}

// RevokeToken revokes a token by JTI (legacy single-JTI revoke).
func (h *TokenGRPCHandler) RevokeToken(ctx context.Context, jti string, exp int64, reason string) (bool, error) {
	if jti == "" {
		return false, status.Errorf(codes.InvalidArgument, "jti is required")
	}
	if err := h.revoker.Revoke(ctx, jti, exp, reason); err != nil {
		return false, status.Errorf(codes.Internal, "revocation failed")
	}
	return true, nil
}

// --- Session Methods ---

func (h *TokenGRPCHandler) ListUserSessions(ctx context.Context, userID string) ([]*UserSessionResult, error) {
	uid, err := uuid.Parse(userID)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid user_id: %v", err)
	}
	sessions, err := h.sessions.ListUserSessions(ctx, uid)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list sessions")
	}
	out := make([]*UserSessionResult, 0, len(sessions))
	for _, s := range sessions {
		out = append(out, sessionToResult(s))
	}
	return out, nil
}

func (h *TokenGRPCHandler) RevokeSession(ctx context.Context, sessionID, reason string) (bool, error) {
	sid, err := uuid.Parse(sessionID)
	if err != nil {
		return false, status.Errorf(codes.InvalidArgument, "invalid session_id: %v", err)
	}
	if reason == "" {
		reason = model.RevokeReasonUserLogout
	}
	if err := h.sessions.LogoutSession(ctx, sid, reason); err != nil {
		return false, status.Errorf(codes.Internal, "failed to revoke session")
	}
	return true, nil
}

func (h *TokenGRPCHandler) RevokeAllUserSessions(ctx context.Context, userID, reason string) (int32, error) {
	uid, err := uuid.Parse(userID)
	if err != nil {
		return 0, status.Errorf(codes.InvalidArgument, "invalid user_id: %v", err)
	}
	if reason == "" {
		reason = model.RevokeReasonAdmin
	}
	count, err := h.sessions.RevokeAllUserSessions(ctx, uid, reason)
	if err != nil {
		return 0, status.Errorf(codes.Internal, "failed to revoke sessions")
	}
	return int32(count), nil
}

// --- Service Token Methods ---

func (h *TokenGRPCHandler) AuthenticateService(ctx context.Context, serviceID, serviceSecret string) (*ServiceTokenResult, error) {
	token, err := h.authenticator.AuthenticateService(ctx, serviceID, serviceSecret)
	if err != nil {
		switch {
		case errors.Is(err, model.ErrServiceNotFound), errors.Is(err, model.ErrInvalidCredentials):
			return nil, status.Errorf(codes.Unauthenticated, "invalid credentials")
		case errors.Is(err, model.ErrServiceInactive):
			return nil, status.Errorf(codes.PermissionDenied, "service account is inactive")
		default:
			return nil, status.Errorf(codes.Internal, "authentication failed")
		}
	}
	return &ServiceTokenResult{
		Token:     token.Token,
		ExpiresAt: timestamppb.New(token.ExpiresAt),
	}, nil
}

func (h *TokenGRPCHandler) ValidateServiceToken(ctx context.Context, token string) (*ValidatedClaimsResult, error) {
	claims, err := h.validator.ValidateServiceToken(ctx, token)
	if err != nil {
		return nil, h.mapValidationError(err)
	}
	return claimsToResult(claims), nil
}

// --- Result types (used in place of generated proto for handler ↔ server adaptation) ---

type TokenPairResult struct {
	AccessToken      string
	RefreshToken     string
	TokenType        string
	ExpiresAt        *timestamppb.Timestamp
	RefreshExpiresAt *timestamppb.Timestamp
	SessionID        string
}

type ServiceTokenResult struct {
	Token     string
	ExpiresAt *timestamppb.Timestamp
}

type ValidatedClaimsResult struct {
	Valid       bool
	Subject     string
	UserID      string
	Type        string
	Role        string
	Roles       []string
	Permissions []string
	JTI         string
	SessionID   string
	IssuedAt    *timestamppb.Timestamp
	ExpiresAt   *timestamppb.Timestamp
}

type UserSessionResult struct {
	SessionID        string
	UserID           string
	Device           model.DeviceInfo
	CreatedAt        *timestamppb.Timestamp
	LastUsedAt       *timestamppb.Timestamp
	LastRefreshedAt  *timestamppb.Timestamp
	RefreshExpiresAt *timestamppb.Timestamp
}

// --- Private helpers ---

func (h *TokenGRPCHandler) mapValidationError(err error) error {
	switch {
	case errors.Is(err, model.ErrTokenExpired):
		return status.Errorf(codes.Unauthenticated, "token expired")
	case errors.Is(err, model.ErrTokenRevoked), errors.Is(err, model.ErrTokenReuseDetect),
		errors.Is(err, model.ErrSessionRevoked), errors.Is(err, model.ErrSessionExpired):
		return status.Errorf(codes.Unauthenticated, "token revoked")
	case errors.Is(err, model.ErrTokenMalformed):
		return status.Errorf(codes.InvalidArgument, "malformed token")
	case errors.Is(err, model.ErrInvalidSignature):
		return status.Errorf(codes.Unauthenticated, "invalid signature")
	case errors.Is(err, model.ErrTokenInvalid):
		return status.Errorf(codes.Unauthenticated, "invalid token type")
	default:
		h.logger.Error().Err(err).Msg("unexpected validation error")
		return status.Errorf(codes.Internal, "validation failed")
	}
}

func tokenPairToResult(p *model.TokenPair) *TokenPairResult {
	return &TokenPairResult{
		AccessToken:      p.AccessToken,
		RefreshToken:     p.RefreshToken,
		TokenType:        p.TokenType,
		ExpiresAt:        timestamppb.New(p.ExpiresAt),
		RefreshExpiresAt: timestamppb.New(p.RefreshExpiresAt),
		SessionID:        p.SessionID.String(),
	}
}

func claimsToResult(c *model.ValidatedClaims) *ValidatedClaimsResult {
	return &ValidatedClaimsResult{
		Valid:       true,
		Subject:     c.Subject,
		UserID:      c.UserID,
		Type:        string(c.Type),
		Role:        c.Role,
		Roles:       c.Roles,
		Permissions: c.Permissions,
		JTI:         c.JTI,
		SessionID:   c.SessionID,
		IssuedAt:    timestamppb.New(c.IssuedAt),
		ExpiresAt:   timestamppb.New(c.ExpiresAt),
	}
}

func sessionToResult(s *model.UserSession) *UserSessionResult {
	res := &UserSessionResult{
		SessionID:        s.ID.String(),
		UserID:           s.UserID.String(),
		Device:           s.Device,
		CreatedAt:        timestamppb.New(s.CreatedAt),
		LastUsedAt:       timestamppb.New(s.LastUsedAt),
		RefreshExpiresAt: timestamppb.New(s.RefreshExpiresAt),
	}
	if s.LastRefreshedAt != nil {
		res.LastRefreshedAt = timestamppb.New(*s.LastRefreshedAt)
	}
	return res
}
