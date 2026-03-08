package app

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"fmt"
	"time"

	"github.com/go-jose/go-jose/v4"
	josejwt "github.com/go-jose/go-jose/v4/jwt"
	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/config"
	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/port"
)

// jwtCustomClaims wraps standard + custom claims for JWT serialization.
type jwtCustomClaims struct {
	Type        model.TokenType `json:"type"`
	Role        string          `json:"role,omitempty"`
	Roles       []string        `json:"roles,omitempty"`
	Permissions []string        `json:"permissions,omitempty"`
	TokenKind   string          `json:"kind"` // "access", "refresh", "service"
}

// TokenUseCase implements the core token business logic.
type TokenUseCase struct {
	cfg              config.JWTConfig
	keyStore         port.KeyStore
	revStore         port.RevocationStore
	svcStore         port.ServiceAccountStore
	passwordVerifier port.PasswordVerifier
	audit            port.AuditLogger
	logger           zerolog.Logger
}

// NewTokenUseCase creates a new TokenUseCase.
func NewTokenUseCase(
	cfg config.JWTConfig,
	keyStore port.KeyStore,
	revStore port.RevocationStore,
	svcStore port.ServiceAccountStore,
	passwordVerifier port.PasswordVerifier,
	audit port.AuditLogger,
	logger zerolog.Logger,
) *TokenUseCase {
	return &TokenUseCase{
		cfg:              cfg,
		keyStore:         keyStore,
		revStore:         revStore,
		svcStore:         svcStore,
		passwordVerifier: passwordVerifier,
		audit:            audit,
		logger:           logger.With().Str("component", "token_usecase").Logger(),
	}
}

// --- TokenGenerator ---

func (uc *TokenUseCase) GenerateUserTokens(ctx context.Context, claims model.UserClaims) (*model.TokenPair, error) {
	now := time.Now()
	accessExp := now.Add(uc.cfg.AccessTokenTTL)
	refreshExp := now.Add(uc.cfg.RefreshTokenTTL)

	accessJTI := uuid.New().String()
	refreshJTI := uuid.New().String()

	// Build access token
	accessToken, err := uc.signToken(ctx, josejwt.Claims{
		Issuer:    uc.cfg.Issuer,
		Subject:   claims.UserID.String(),
		IssuedAt:  josejwt.NewNumericDate(now),
		Expiry:    josejwt.NewNumericDate(accessExp),
		NotBefore: josejwt.NewNumericDate(now),
		ID:        accessJTI,
	}, jwtCustomClaims{
		Type:        model.TokenTypeUser,
		Role:        string(claims.Role),
		Permissions: claims.Permissions,
		TokenKind:   "access",
	})
	if err != nil {
		return nil, fmt.Errorf("signing access token: %w", err)
	}

	// Build refresh token
	refreshToken, err := uc.signToken(ctx, josejwt.Claims{
		Issuer:    uc.cfg.Issuer,
		Subject:   claims.UserID.String(),
		IssuedAt:  josejwt.NewNumericDate(now),
		Expiry:    josejwt.NewNumericDate(refreshExp),
		NotBefore: josejwt.NewNumericDate(now),
		ID:        refreshJTI,
	}, jwtCustomClaims{
		Type:      model.TokenTypeUser,
		Role:      string(claims.Role),
		TokenKind: "refresh",
	})
	if err != nil {
		return nil, fmt.Errorf("signing refresh token: %w", err)
	}

	uc.logger.Info().
		Str("user_id", claims.UserID.String()).
		Str("role", string(claims.Role)).
		Msg("user token pair generated")

	return &model.TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresAt:    accessExp,
		TokenType:    "Bearer",
	}, nil
}

func (uc *TokenUseCase) GenerateServiceToken(ctx context.Context, claims model.ServiceClaims) (*model.ServiceToken, error) {
	now := time.Now()
	exp := now.Add(uc.cfg.ServiceTokenTTL)
	jti := uuid.New().String()

	token, err := uc.signToken(ctx, josejwt.Claims{
		Issuer:    uc.cfg.Issuer,
		Subject:   claims.ServiceID,
		IssuedAt:  josejwt.NewNumericDate(now),
		Expiry:    josejwt.NewNumericDate(exp),
		NotBefore: josejwt.NewNumericDate(now),
		ID:        jti,
	}, jwtCustomClaims{
		Type:      model.TokenTypeService,
		Roles:     claims.Roles,
		TokenKind: "service",
	})
	if err != nil {
		return nil, fmt.Errorf("signing service token: %w", err)
	}

	uc.logger.Info().
		Str("service_id", claims.ServiceID).
		Int("roles_count", len(claims.Roles)).
		Msg("service token generated")

	return &model.ServiceToken{
		Token:     token,
		ExpiresAt: exp,
	}, nil
}

// --- TokenValidator ---

func (uc *TokenUseCase) ValidateAccessToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error) {
	return uc.validateToken(ctx, tokenStr, "access")
}

func (uc *TokenUseCase) ValidateRefreshToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error) {
	return uc.validateToken(ctx, tokenStr, "refresh")
}

func (uc *TokenUseCase) ValidateServiceToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error) {
	return uc.validateToken(ctx, tokenStr, "service")
}

// --- TokenRevoker ---

func (uc *TokenUseCase) Revoke(ctx context.Context, jti string, expiresAt int64, reason string) error {
	if err := uc.revStore.Add(ctx, jti, expiresAt); err != nil {
		return fmt.Errorf("adding to revocation list: %w", err)
	}

	uc.logger.Info().Str("jti", jti).Str("reason", reason).Msg("token revoked")
	return nil
}

func (uc *TokenUseCase) IsRevoked(ctx context.Context, jti string) (bool, error) {
	return uc.revStore.Exists(ctx, jti)
}

// --- ServiceAuthenticator ---

func (uc *TokenUseCase) AuthenticateService(ctx context.Context, serviceID, serviceSecret string) (*model.ServiceToken, error) {
	account, err := uc.svcStore.GetByServiceID(ctx, serviceID)
	if err != nil {
		uc.audit.LogServiceAuth(ctx, serviceID, "authenticate", "not_found", nil)
		return nil, model.ErrServiceNotFound
	}

	if !account.IsActive {
		uc.audit.LogServiceAuth(ctx, serviceID, "authenticate", "inactive", nil)
		return nil, model.ErrServiceInactive
	}

	// Verify secret via the injected PasswordVerifier port
	if !uc.passwordVerifier.Verify(account.SecretHash, serviceSecret) {
		uc.audit.LogServiceAuth(ctx, serviceID, "authenticate", "bad_credentials", nil)
		return nil, model.ErrInvalidCredentials
	}

	// Generate service token with the account's roles
	token, err := uc.GenerateServiceToken(ctx, model.ServiceClaims{
		ServiceID: account.ServiceID,
		Type:      model.TokenTypeService,
		Roles:     account.Roles,
	})
	if err != nil {
		return nil, err
	}

	uc.audit.LogServiceAuth(ctx, serviceID, "authenticate", "granted", map[string]string{
		"roles_count": fmt.Sprintf("%d", len(account.Roles)),
	})

	return token, nil
}

// --- KeyManager ---

func (uc *TokenUseCase) RotateKeys(ctx context.Context) error {
	key, err := rsa.GenerateKey(rand.Reader, uc.cfg.RSAKeySize)
	if err != nil {
		return fmt.Errorf("generating RSA key: %w", err)
	}

	keyID := fmt.Sprintf("key-%s", uuid.New().String()[:8])

	if err := uc.keyStore.StoreKey(ctx, keyID, key); err != nil {
		return fmt.Errorf("storing new key: %w", err)
	}

	// Clean up old keys beyond retention limit
	if err := uc.keyStore.DeleteExpiredKeys(ctx, uc.cfg.MaxKeysInJWKS); err != nil {
		uc.logger.Warn().Err(err).Msg("failed to clean up old keys")
	}

	uc.logger.Info().Str("key_id", keyID).Msg("key rotation completed")
	return nil
}

func (uc *TokenUseCase) GetJWKS(ctx context.Context) (*jose.JSONWebKeySet, error) {
	keys, err := uc.keyStore.GetPublicKeys(ctx)
	if err != nil {
		return nil, fmt.Errorf("fetching public keys: %w", err)
	}
	return &jose.JSONWebKeySet{Keys: keys}, nil
}

// --- Private helpers ---

// signToken creates a signed JWT string using the active RSA key.
func (uc *TokenUseCase) signToken(ctx context.Context, stdClaims josejwt.Claims, custom jwtCustomClaims) (string, error) {
	keyID, privateKey, err := uc.keyStore.GetActiveKey(ctx)
	if err != nil {
		return "", fmt.Errorf("getting active key: %w", err)
	}

	signerOpts := (&jose.SignerOptions{}).
		WithType("JWT").
		WithHeader("kid", keyID)

	signer, err := jose.NewSigner(
		jose.SigningKey{Algorithm: jose.RS256, Key: privateKey},
		signerOpts,
	)
	if err != nil {
		return "", fmt.Errorf("creating signer: %w", err)
	}

	token, err := josejwt.Signed(signer).
		Claims(stdClaims).
		Claims(custom).
		Serialize()
	if err != nil {
		return "", fmt.Errorf("serializing token: %w", err)
	}

	return token, nil
}

// validateToken parses, verifies and checks a JWT token.
func (uc *TokenUseCase) validateToken(ctx context.Context, tokenStr string, expectedKind string) (*model.ValidatedClaims, error) {
	// 1. Parse the token (without verification yet)
	tok, err := josejwt.ParseSigned(tokenStr, []jose.SignatureAlgorithm{jose.RS256})
	if err != nil {
		return nil, model.ErrTokenMalformed
	}

	// 2. Get public keys to verify signature
	pubKeys, err := uc.keyStore.GetPublicKeys(ctx)
	if err != nil {
		return nil, fmt.Errorf("fetching public keys: %w", err)
	}

	// 3. Try to verify with each known public key
	var stdClaims josejwt.Claims
	var custom jwtCustomClaims
	verified := false

	for _, jwk := range pubKeys {
		if err := tok.Claims(jwk.Key, &stdClaims, &custom); err == nil {
			verified = true
			break
		}
	}

	if !verified {
		return nil, model.ErrInvalidSignature
	}

	// 4. Validate standard claims (expiry, not-before, issuer)
	expected := josejwt.Expected{
		Issuer: uc.cfg.Issuer,
		Time:   time.Now(),
	}
	if err := stdClaims.Validate(expected); err != nil {
		return nil, model.ErrTokenExpired
	}

	// 5. Validate token kind matches expectation
	if custom.TokenKind != expectedKind {
		return nil, model.ErrTokenInvalid
	}

	// 6. Check revocation list
	if stdClaims.ID != "" {
		revoked, err := uc.revStore.Exists(ctx, stdClaims.ID)
		if err != nil {
			uc.logger.Warn().Err(err).Str("jti", stdClaims.ID).Msg("revocation check failed")
		}
		if revoked {
			return nil, model.ErrTokenRevoked
		}
	}

	return &model.ValidatedClaims{
		Subject:     stdClaims.Subject,
		Type:        custom.Type,
		Role:        custom.Role,
		Roles:       custom.Roles,
		Permissions: custom.Permissions,
		JTI:         stdClaims.ID,
		IssuedAt:    stdClaims.IssuedAt.Time(),
		ExpiresAt:   stdClaims.Expiry.Time(),
	}, nil
}
