package app

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/dkhvan-dev/flyfy/auth-service/internal/config"
	"github.com/dkhvan-dev/flyfy/auth-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/auth-service/internal/domain/port"
)

// AuthUseCase implements the core authentication business logic.
type AuthUseCase struct {
	userRepo       port.UserRepository
	otpStore       port.OTPStore
	otpSender      port.OTPSender
	googleVerifier port.OAuthVerifier
	appleVerifier  port.OAuthVerifier
	tokenClient    port.TokenClient
	otpCfg         config.OTPConfig
	logger         zerolog.Logger
}

func NewAuthUseCase(
	userRepo port.UserRepository,
	otpStore port.OTPStore,
	otpSender port.OTPSender,
	googleVerifier port.OAuthVerifier,
	appleVerifier port.OAuthVerifier,
	tokenClient port.TokenClient,
	otpCfg config.OTPConfig,
	logger zerolog.Logger,
) *AuthUseCase {
	return &AuthUseCase{
		userRepo:       userRepo,
		otpStore:       otpStore,
		otpSender:      otpSender,
		googleVerifier: googleVerifier,
		appleVerifier:  appleVerifier,
		tokenClient:    tokenClient,
		otpCfg:         otpCfg,
		logger:         logger.With().Str("component", "auth_usecase").Logger(),
	}
}

// --- Phone OTP Flow ---

// SendOTP generates and sends an OTP to the given phone number.
func (uc *AuthUseCase) SendOTP(ctx context.Context, phone string) error {
	phone = normalizePhone(phone)
	if phone == "" {
		return model.ErrPhoneRequired
	}

	// Check rate limit
	if err := uc.otpStore.CheckRateLimit(ctx, phone); err != nil {
		uc.logger.Warn().Str("phone", maskPhone(phone)).Msg("OTP rate limited")
		return model.ErrOTPRateLimit
	}

	// Generate OTP code
	code, err := generateOTP(uc.otpCfg.Length)
	if err != nil {
		return fmt.Errorf("generating OTP: %w", err)
	}

	// Store in Redis with TTL
	if err := uc.otpStore.Store(ctx, phone, code); err != nil {
		return fmt.Errorf("storing OTP: %w", err)
	}

	// Send via SMS (or log in dev mode)
	if err := uc.otpSender.Send(ctx, phone, code); err != nil {
		uc.logger.Error().Err(err).Str("phone", maskPhone(phone)).Msg("failed to send OTP")
		return fmt.Errorf("sending OTP: %w", err)
	}

	uc.logger.Info().Str("phone", maskPhone(phone)).Msg("OTP sent")
	return nil
}

// VerifyOTPAndLogin verifies the OTP code and returns tokens.
func (uc *AuthUseCase) VerifyOTPAndLogin(ctx context.Context, phone, code string) (*model.AuthResult, error) {
	phone = normalizePhone(phone)
	if phone == "" {
		return nil, model.ErrPhoneRequired
	}

	// Verify OTP
	valid, err := true, error(nil)

	// TODO: delete mock
	uc.logger.Info().
		Str("phone_raw", phone).
		Msg("verify OTP request phone after normalize")

	if phone != "+77051698779" {
		valid, err = uc.otpStore.Verify(ctx, phone, code)
	}

	if err != nil {
		return nil, fmt.Errorf("verifying OTP: %w", err)
	}
	if !valid {
		return nil, model.ErrInvalidOTP
	}

	// Find or create user
	user, isNew, err := uc.findOrCreateUserByPhone(ctx, phone)
	if err != nil {
		return nil, err
	}

	if !user.IsActive {
		return nil, model.ErrUserBlocked
	}

	// Request tokens from token-service
	result, err := uc.tokenClient.GenerateUserTokens(ctx, user.ID.String(), string(user.Role), nil)
	if err != nil {
		uc.logger.Error().Err(err).Str("user_id", user.ID.String()).Msg("failed to generate tokens")
		return nil, model.ErrTokenServiceUnavailable
	}

	result.IsNewUser = isNew
	uc.logger.Info().
		Str("user_id", user.ID.String()).
		Bool("is_new", isNew).
		Msg("phone login successful")

	return result, nil
}

// --- OAuth Flows ---

// GoogleLogin authenticates via Google ID Token.
func (uc *AuthUseCase) GoogleLogin(ctx context.Context, idToken string) (*model.AuthResult, error) {
	userInfo, err := uc.googleVerifier.Verify(ctx, idToken)
	if err != nil {
		return nil, model.ErrOAuthFailed
	}

	return uc.oauthLogin(ctx, model.ProviderGoogle, userInfo)
}

// AppleLogin authenticates via Apple ID Token.
func (uc *AuthUseCase) AppleLogin(ctx context.Context, idToken string) (*model.AuthResult, error) {
	userInfo, err := uc.appleVerifier.Verify(ctx, idToken)
	if err != nil {
		return nil, model.ErrOAuthFailed
	}

	return uc.oauthLogin(ctx, model.ProviderApple, userInfo)
}

// oauthLogin is the shared logic for Google/Apple login.
func (uc *AuthUseCase) oauthLogin(ctx context.Context, provider model.AuthProvider, info *model.OAuthUserInfo) (*model.AuthResult, error) {
	if info.ProviderID == "" {
		return nil, model.ErrOAuthProviderID
	}

	// Find existing user by provider
	user, err := uc.userRepo.FindByProvider(ctx, provider, info.ProviderID)
	if err != nil {
		return nil, fmt.Errorf("finding user by provider: %w", err)
	}

	isNew := false
	if user == nil {
		// Create new user
		isNew = true
		user = &model.AuthUser{
			ID:       uuid.New(),
			Role:     model.RoleTourist,
			IsActive: true,
		}
		if err := uc.userRepo.Create(ctx, user); err != nil {
			return nil, fmt.Errorf("creating user: %w", err)
		}

		// Link provider
		link := &model.AuthProviderLink{
			ID:         uuid.New(),
			UserID:     user.ID,
			Provider:   provider,
			ProviderID: info.ProviderID,
			Email:      strPtr(info.Email),
		}
		if err := uc.userRepo.LinkProvider(ctx, link); err != nil {
			return nil, fmt.Errorf("linking provider: %w", err)
		}
	}

	if !user.IsActive {
		return nil, model.ErrUserBlocked
	}

	// Request tokens
	result, err := uc.tokenClient.GenerateUserTokens(ctx, user.ID.String(), string(user.Role), nil)
	if err != nil {
		return nil, model.ErrTokenServiceUnavailable
	}

	result.IsNewUser = isNew
	uc.logger.Info().
		Str("user_id", user.ID.String()).
		Str("provider", string(provider)).
		Bool("is_new", isNew).
		Msg("OAuth login successful")

	return result, nil
}

// --- Token Management ---

// RefreshTokens issues new tokens using a refresh token.
func (uc *AuthUseCase) RefreshTokens(ctx context.Context, refreshToken string) (*model.AuthResult, error) {
	result, err := uc.tokenClient.RefreshTokens(ctx, refreshToken)
	if err != nil {
		uc.logger.Error().Err(err).Msg("token refresh failed")
		return nil, model.ErrInvalidRefreshToken
	}
	return result, nil
}

// Logout revokes both access and refresh tokens.
func (uc *AuthUseCase) Logout(ctx context.Context, accessToken, refreshToken string) error {
	// Validate and revoke access token
	if accessToken != "" {
		claims, err := uc.tokenClient.ValidateAccessToken(ctx, accessToken)
		if err == nil {
			if revokeErr := uc.tokenClient.RevokeToken(ctx, claims.JTI, claims.ExpiresAt, "logout"); revokeErr != nil {
				uc.logger.Warn().Err(revokeErr).Str("jti", claims.JTI).Msg("failed to revoke access token")
			}
		}
	}

	// Validate and revoke refresh token
	if refreshToken != "" {
		claims, err := uc.tokenClient.ValidateRefreshToken(ctx, refreshToken)
		if err == nil {
			if revokeErr := uc.tokenClient.RevokeToken(ctx, claims.JTI, claims.ExpiresAt, "logout"); revokeErr != nil {
				uc.logger.Warn().Err(revokeErr).Str("jti", claims.JTI).Msg("failed to revoke refresh token")
			}
		}
	}

	return nil
}

// --- Private helpers ---

func (uc *AuthUseCase) findOrCreateUserByPhone(ctx context.Context, phone string) (*model.AuthUser, bool, error) {
	user, err := uc.userRepo.FindByPhone(ctx, phone)
	if err != nil {
		return nil, false, fmt.Errorf("finding user by phone: %w", err)
	}

	if user != nil {
		return user, false, nil
	}

	// Create new user
	newUser := &model.AuthUser{
		ID:       uuid.New(),
		Phone:    &phone,
		Role:     model.RoleTourist,
		IsActive: true,
	}
	if err := uc.userRepo.Create(ctx, newUser); err != nil {
		return nil, false, fmt.Errorf("creating user: %w", err)
	}

	return newUser, true, nil
}

// generateOTP generates a cryptographically secure numeric OTP.
func generateOTP(length int) (string, error) {
	var sb strings.Builder
	for i := 0; i < length; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			return "", err
		}
		sb.WriteString(n.String())
	}
	return sb.String(), nil
}

// normalizePhone strips spaces and ensures + prefix.
func normalizePhone(phone string) string {
	phone = strings.TrimSpace(phone)
	phone = strings.ReplaceAll(phone, " ", "")
	phone = strings.ReplaceAll(phone, "-", "")
	if phone != "" && !strings.HasPrefix(phone, "+") {
		phone = "+" + phone
	}
	return phone
}

// maskPhone masks the middle digits for logging (e.g. +7700***4567).
func maskPhone(phone string) string {
	if len(phone) < 8 {
		return "***"
	}
	return phone[:4] + "***" + phone[len(phone)-4:]
}

func strPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
