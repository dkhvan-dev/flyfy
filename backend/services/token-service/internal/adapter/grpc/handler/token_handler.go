package handler

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/port"
)

// TokenGRPCHandler implements the gRPC TokenService server.
type TokenGRPCHandler struct {
	generator     port.TokenGenerator
	validator     port.TokenValidator
	revoker       port.TokenRevoker
	authenticator port.ServiceAuthenticator
	logger        zerolog.Logger
}

func NewTokenGRPCHandler(
	gen port.TokenGenerator,
	val port.TokenValidator,
	rev port.TokenRevoker,
	auth port.ServiceAuthenticator,
	logger zerolog.Logger,
) *TokenGRPCHandler {
	return &TokenGRPCHandler{
		generator:     gen,
		validator:     val,
		revoker:       rev,
		authenticator: auth,
		logger:        logger.With().Str("component", "grpc_handler").Logger(),
	}
}

// --- User Token Methods ---

// GenerateUserTokens creates access + refresh tokens for a user.
func (h *TokenGRPCHandler) GenerateUserTokens(ctx context.Context, userID string, role string, permissions []string) (*TokenPairResult, error) {
	uid, err := uuid.Parse(userID)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid user_id: %v", err)
	}

	pair, err := h.generator.GenerateUserTokens(ctx, model.UserClaims{
		UserID:      uid,
		Type:        model.TokenTypeUser,
		Role:        model.UserRole(role),
		Permissions: permissions,
	})
	if err != nil {
		h.logger.Error().Err(err).Str("user_id", userID).Msg("failed to generate user tokens")
		return nil, status.Errorf(codes.Internal, "token generation failed")
	}

	return &TokenPairResult{
		AccessToken:  pair.AccessToken,
		RefreshToken: pair.RefreshToken,
		TokenType:    pair.TokenType,
		ExpiresAt:    timestamppb.New(pair.ExpiresAt),
	}, nil
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

// RefreshTokens validates a refresh token and issues a new pair.
func (h *TokenGRPCHandler) RefreshTokens(ctx context.Context, refreshToken string) (*TokenPairResult, error) {
	// 1. Validate the refresh token
	claims, err := h.validator.ValidateRefreshToken(ctx, refreshToken)
	if err != nil {
		return nil, h.mapValidationError(err)
	}

	// 2. Revoke the old refresh token
	if err := h.revoker.Revoke(ctx, claims.JTI, claims.ExpiresAt.Unix(), "token_refresh"); err != nil {
		h.logger.Warn().Err(err).Str("jti", claims.JTI).Msg("failed to revoke old refresh token")
	}

	// 3. Generate new pair
	uid, _ := uuid.Parse(claims.Subject)
	pair, err := h.generator.GenerateUserTokens(ctx, model.UserClaims{
		UserID:      uid,
		Type:        model.TokenTypeUser,
		Role:        model.UserRole(claims.Role),
		Permissions: claims.Permissions,
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "token generation failed")
	}

	return &TokenPairResult{
		AccessToken:  pair.AccessToken,
		RefreshToken: pair.RefreshToken,
		TokenType:    pair.TokenType,
		ExpiresAt:    timestamppb.New(pair.ExpiresAt),
	}, nil
}

// RevokeToken revokes a token by JTI.
func (h *TokenGRPCHandler) RevokeToken(ctx context.Context, jti string, exp int64, reason string) (bool, error) {
	if jti == "" {
		return false, status.Errorf(codes.InvalidArgument, "jti is required")
	}

	if err := h.revoker.Revoke(ctx, jti, exp, reason); err != nil {
		return false, status.Errorf(codes.Internal, "revocation failed")
	}
	return true, nil
}

// --- Service Token Methods ---

// AuthenticateService validates service credentials and returns a service token.
func (h *TokenGRPCHandler) AuthenticateService(ctx context.Context, serviceID, serviceSecret string) (*ServiceTokenResult, error) {
	token, err := h.authenticator.AuthenticateService(ctx, serviceID, serviceSecret)
	if err != nil {
		switch err {
		case model.ErrServiceNotFound, model.ErrInvalidCredentials:
			return nil, status.Errorf(codes.Unauthenticated, "invalid credentials")
		case model.ErrServiceInactive:
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

// ValidateServiceToken validates a service-to-service token.
func (h *TokenGRPCHandler) ValidateServiceToken(ctx context.Context, token string) (*ValidatedClaimsResult, error) {
	claims, err := h.validator.ValidateServiceToken(ctx, token)
	if err != nil {
		return nil, h.mapValidationError(err)
	}
	return claimsToResult(claims), nil
}

// --- Helper types (used in place of generated proto until protoc runs) ---

type TokenPairResult struct {
	AccessToken  string
	RefreshToken string
	TokenType    string
	ExpiresAt    *timestamppb.Timestamp
}

type ServiceTokenResult struct {
	Token     string
	ExpiresAt *timestamppb.Timestamp
}

type ValidatedClaimsResult struct {
	Valid       bool
	Subject     string
	Type        string
	Role        string
	Roles       []string
	Permissions []string
	JTI         string
	IssuedAt    *timestamppb.Timestamp
	ExpiresAt   *timestamppb.Timestamp
}

// --- Private helpers ---

func (h *TokenGRPCHandler) mapValidationError(err error) error {
	switch err {
	case model.ErrTokenExpired:
		return status.Errorf(codes.Unauthenticated, "token expired")
	case model.ErrTokenRevoked:
		return status.Errorf(codes.Unauthenticated, "token revoked")
	case model.ErrTokenMalformed:
		return status.Errorf(codes.InvalidArgument, "malformed token")
	case model.ErrInvalidSignature:
		return status.Errorf(codes.Unauthenticated, "invalid signature")
	case model.ErrTokenInvalid:
		return status.Errorf(codes.Unauthenticated, "invalid token type")
	default:
		h.logger.Error().Err(err).Msg("unexpected validation error")
		return status.Errorf(codes.Internal, "validation failed")
	}
}

func claimsToResult(c *model.ValidatedClaims) *ValidatedClaimsResult {
	return &ValidatedClaimsResult{
		Valid:       true,
		Subject:     c.Subject,
		Type:        string(c.Type),
		Role:        c.Role,
		Roles:       c.Roles,
		Permissions: c.Permissions,
		JTI:         c.JTI,
		IssuedAt:    timestamppb.New(c.IssuedAt),
		ExpiresAt:   timestamppb.New(c.ExpiresAt),
	}
}
