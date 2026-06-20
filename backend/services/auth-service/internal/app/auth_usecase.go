package app

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"net/mail"
	"strings"
	"unicode"

	"github.com/google/uuid"
	"github.com/rs/zerolog"
	"golang.org/x/crypto/bcrypt"

	"kz/inflap/backend/services/auth-service/internal/config"
	"kz/inflap/backend/services/auth-service/internal/domain/model"
	"kz/inflap/backend/services/auth-service/internal/domain/port"
)

// AuthUseCase implements the core authentication business logic.
type AuthUseCase struct {
	userRepo       port.UserRepository
	otpStore       port.OTPStore
	otpSender      port.OTPSender
	emailOTPSender port.EmailOTPSender
	nicknameLookup port.NicknameResolver
	googleVerifier port.OAuthVerifier
	appleVerifier  port.OAuthVerifier
	tokenClient    port.TokenClient
	fraud          port.FraudEvaluator
	featureFlags   port.FeatureFlagReader
	techBreaks     port.TechBreakChecker
	otpCfg         config.OTPConfig
	securityCfg    config.AuthSecurityConfig
	env            string
	logger         zerolog.Logger
}

const (
	featureFlagOTPBypassCode    = "0000"
	onboardingDomainCode        = "ONBOARDING"
	skipSendingPhoneOTPFlag     = "SKIP_SENDING_PHONE_OTP"
	skipSendingEmailOTPFlag     = "SKIP_SENDING_EMAIL_OTP"
	techBreakScopeAuthorization = "AUTHORIZATION"
	techBreakScopeRegistration  = "REGISTRATION"
)

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
	return NewAuthUseCaseWithFraud(
		userRepo,
		otpStore,
		otpSender,
		googleVerifier,
		appleVerifier,
		tokenClient,
		nil,
		otpCfg,
		config.AuthSecurityConfig{},
		"",
		logger,
	)
}

func NewAuthUseCaseWithFraud(
	userRepo port.UserRepository,
	otpStore port.OTPStore,
	otpSender port.OTPSender,
	googleVerifier port.OAuthVerifier,
	appleVerifier port.OAuthVerifier,
	tokenClient port.TokenClient,
	fraud port.FraudEvaluator,
	otpCfg config.OTPConfig,
	securityCfg config.AuthSecurityConfig,
	env string,
	logger zerolog.Logger,
) *AuthUseCase {
	return &AuthUseCase{
		userRepo:       userRepo,
		otpStore:       otpStore,
		otpSender:      otpSender,
		googleVerifier: googleVerifier,
		appleVerifier:  appleVerifier,
		tokenClient:    tokenClient,
		fraud:          fraud,
		otpCfg:         otpCfg,
		securityCfg:    securityCfg,
		env:            strings.TrimSpace(env),
		logger:         logger.With().Str("component", "auth_usecase").Logger(),
	}
}

func (uc *AuthUseCase) SetEmailOTPSender(sender port.EmailOTPSender) {
	uc.emailOTPSender = sender
}

func (uc *AuthUseCase) SetNicknameResolver(resolver port.NicknameResolver) {
	uc.nicknameLookup = resolver
}

func (uc *AuthUseCase) SetFeatureFlagReader(reader port.FeatureFlagReader) {
	uc.featureFlags = reader
}

func (uc *AuthUseCase) SetTechBreakChecker(checker port.TechBreakChecker) {
	uc.techBreaks = checker
}

// --- Phone OTP Flow ---

// SendOTP generates and sends an OTP to the given phone number.
func (uc *AuthUseCase) SendOTP(ctx context.Context, phone string, device model.DeviceInfo) error {
	phone = normalizePhone(phone)
	if phone == "" {
		return model.ErrPhoneRequired
	}

	if err := uc.ensureNoOnboardingTechBreak(ctx, techBreakScopeAuthorization, "", ""); err != nil {
		return err
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action: "AUTH_OTP_REQUEST",
		Phone:  phone,
		Device: device,
	}); err != nil {
		uc.logger.Warn().Err(err).Str("phone", maskPhone(phone)).Msg("OTP blocked by fraud policy")
		return model.ErrOTPRateLimit
	}

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

	if uc.shouldSkipPhoneOTPSending(ctx, phone) {
		uc.logger.Info().Str("phone", maskPhone(phone)).Msg("OTP sending skipped by feature flag")
		return nil
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
func (uc *AuthUseCase) VerifyOTPAndLogin(ctx context.Context, phone, code string, device model.DeviceInfo) (*model.AuthResult, error) {
	phone = normalizePhone(phone)
	if phone == "" {
		return nil, model.ErrPhoneRequired
	}

	if err := uc.ensureNoOnboardingTechBreak(ctx, techBreakScopeAuthorization, "", ""); err != nil {
		return nil, err
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action: "AUTH_OTP_VERIFY",
		Phone:  phone,
		Device: device,
	}); err != nil {
		uc.logger.Warn().Err(err).Str("phone", maskPhone(phone)).Msg("OTP verify blocked by fraud policy")
		return nil, model.ErrRateLimited
	}

	valid, err := true, error(nil)
	if !uc.isPhoneOTPBypassAllowed(ctx, phone, code) {
		valid, err = uc.otpStore.Verify(ctx, phone, code)
	}
	if err != nil {
		return nil, fmt.Errorf("verifying OTP: %w", err)
	}
	if !valid {
		return nil, model.ErrInvalidOTP
	}

	user, isNew, err := uc.findOrCreateUserByPhone(ctx, phone)
	if err != nil {
		return nil, err
	}
	if !user.IsActive {
		return nil, model.ErrUserBlocked
	}

	result, err := uc.tokenClient.GenerateUserTokens(ctx, user.ID.String(), string(user.Role), nil, device)
	if err != nil {
		uc.logger.Error().Err(err).Str("user_id", user.ID.String()).Msg("failed to generate tokens")
		return nil, model.ErrTokenServiceUnavailable
	}

	result.IsNewUser = isNew
	result.PrimaryPhoneHint = strPtr(phone)

	uc.logger.Info().
		Str("user_id", user.ID.String()).
		Bool("is_new", isNew).
		Str("session_id", result.SessionID).
		Msg("phone login successful")

	return result, nil
}

// --- Email/Password Flow ---

// StartEmailRegistration creates an inactive email credential and sends an OTP
// to verify ownership of the email address before allowing password login.
func (uc *AuthUseCase) StartEmailRegistration(ctx context.Context, email, password string, device model.DeviceInfo) error {
	email, err := normalizeEmail(email)
	if err != nil {
		return err
	}
	password = strings.TrimSpace(password)
	if err := validatePassword(password); err != nil {
		return err
	}

	if err := uc.ensureNoOnboardingTechBreak(ctx, techBreakScopeRegistration, email, ""); err != nil {
		return err
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action:   "AUTH_EMAIL_REGISTRATION_START",
		Provider: model.ProviderEmail,
		Device:   device,
		Metadata: map[string]any{
			"email": maskEmail(email),
		},
	}); err != nil {
		uc.logger.Warn().Err(err).Str("email", maskEmail(email)).Msg("email registration blocked by fraud policy")
		return model.ErrRateLimited
	}

	existing, err := uc.userRepo.FindByEmail(ctx, email)
	if err != nil {
		return fmt.Errorf("finding user by email: %w", err)
	}

	passwordHash, err := hashPassword(password)
	if err != nil {
		return fmt.Errorf("hashing password: %w", err)
	}

	if existing != nil {
		if existing.EmailVerified {
			return model.ErrEmailAlreadyExists
		}
		if err := uc.userRepo.UpdatePasswordHash(ctx, existing.ID, passwordHash); err != nil {
			return fmt.Errorf("updating pending email auth user password: %w", err)
		}
	} else {
		user := &model.AuthUser{
			ID:            uuid.New(),
			Email:         &email,
			PasswordHash:  &passwordHash,
			EmailVerified: false,
			Role:          model.RoleTourist,
			IsActive:      true,
		}
		if err := uc.userRepo.Create(ctx, user); err != nil {
			return fmt.Errorf("creating email auth user: %w", err)
		}
	}

	code, err := generateOTP(uc.otpCfg.Length)
	if err != nil {
		return fmt.Errorf("generating email OTP: %w", err)
	}

	destination := emailOTPDestination(email)
	if err := uc.otpStore.Store(ctx, destination, code); err != nil {
		return fmt.Errorf("storing email OTP: %w", err)
	}

	if uc.emailOTPSender == nil {
		return fmt.Errorf("email OTP sender is not configured")
	}
	if uc.shouldSkipEmailOTPSending(ctx, email) {
		uc.logger.Info().Str("email", maskEmail(email)).Msg("email OTP sending skipped by feature flag")
		return nil
	}
	if err := uc.emailOTPSender.SendEmailOTP(ctx, email, code); err != nil {
		uc.logger.Error().Err(err).Str("email", maskEmail(email)).Msg("failed to send email OTP")
		return fmt.Errorf("sending email OTP: %w", err)
	}

	uc.logger.Info().Str("email", maskEmail(email)).Msg("email registration OTP sent")
	return nil
}

// VerifyEmailRegistration verifies the email OTP and signs the user in.
func (uc *AuthUseCase) VerifyEmailRegistration(ctx context.Context, email, code string, device model.DeviceInfo) (*model.AuthResult, error) {
	email, err := normalizeEmail(email)
	if err != nil {
		return nil, err
	}
	code = strings.TrimSpace(code)
	if code == "" {
		return nil, model.ErrInvalidOTP
	}

	if err := uc.ensureNoOnboardingTechBreak(ctx, techBreakScopeRegistration, email, ""); err != nil {
		return nil, err
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action:   "AUTH_EMAIL_REGISTRATION_VERIFY",
		Provider: model.ProviderEmail,
		Device:   device,
		Metadata: map[string]any{
			"email": maskEmail(email),
		},
	}); err != nil {
		uc.logger.Warn().Err(err).Str("email", maskEmail(email)).Msg("email registration verify blocked by fraud policy")
		return nil, model.ErrRateLimited
	}

	if !uc.isEmailOTPBypassAllowed(ctx, email, code) {
		valid, err := uc.otpStore.Verify(ctx, emailOTPDestination(email), code)
		if err != nil {
			return nil, fmt.Errorf("verifying email OTP: %w", err)
		}
		if !valid {
			return nil, model.ErrInvalidOTP
		}
	}

	user, err := uc.userRepo.FindByEmail(ctx, email)
	if err != nil {
		return nil, fmt.Errorf("finding user by email: %w", err)
	}
	if user == nil || user.PasswordHash == nil || *user.PasswordHash == "" {
		return nil, model.ErrInvalidCredentials
	}
	if !user.IsActive {
		return nil, model.ErrUserBlocked
	}
	if !user.EmailVerified {
		if err := uc.userRepo.UpdateEmailVerification(ctx, user.ID, true); err != nil {
			return nil, err
		}
		user.EmailVerified = true
	}

	result, err := uc.tokenClient.GenerateUserTokens(ctx, user.ID.String(), string(user.Role), nil, device)
	if err != nil {
		uc.logger.Error().Err(err).Str("user_id", user.ID.String()).Msg("failed to generate tokens")
		return nil, model.ErrTokenServiceUnavailable
	}

	result.IsNewUser = true
	result.PrimaryEmailHint = strPtr(email)

	uc.logger.Info().
		Str("user_id", user.ID.String()).
		Str("session_id", result.SessionID).
		Msg("email registration verified")

	return result, nil
}

// PasswordLogin authenticates by email or nickname with a password.
func (uc *AuthUseCase) PasswordLogin(ctx context.Context, identifier, password string, device model.DeviceInfo) (*model.AuthResult, error) {
	identifier = strings.TrimSpace(identifier)
	password = strings.TrimSpace(password)
	if identifier == "" || password == "" {
		return nil, model.ErrInvalidCredentials
	}

	if err := uc.ensureNoOnboardingTechBreakForIdentifier(ctx, techBreakScopeAuthorization, identifier); err != nil {
		return nil, err
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action:   "AUTH_PASSWORD_LOGIN",
		Provider: model.ProviderEmail,
		Device:   device,
		Metadata: map[string]any{
			"identifier": maskIdentifier(identifier),
		},
	}); err != nil {
		uc.logger.Warn().Err(err).Str("identifier", maskIdentifier(identifier)).Msg("password login blocked by fraud policy")
		return nil, model.ErrRateLimited
	}

	user, err := uc.findPasswordUserByIdentifier(ctx, identifier)
	if err != nil {
		return nil, err
	}
	if user == nil || !user.IsActive || !user.EmailVerified || user.PasswordHash == nil || *user.PasswordHash == "" {
		return nil, model.ErrInvalidCredentials
	}
	if err := verifyPassword(*user.PasswordHash, password); err != nil {
		return nil, model.ErrInvalidCredentials
	}

	result, err := uc.tokenClient.GenerateUserTokens(ctx, user.ID.String(), string(user.Role), nil, device)
	if err != nil {
		uc.logger.Error().Err(err).Str("user_id", user.ID.String()).Msg("failed to generate tokens")
		return nil, model.ErrTokenServiceUnavailable
	}

	if user.Email != nil {
		result.PrimaryEmailHint = strPtr(*user.Email)
	}

	uc.logger.Info().
		Str("user_id", user.ID.String()).
		Str("session_id", result.SessionID).
		Msg("password login successful")

	return result, nil
}

// StartPasswordReset sends a reset OTP to the account email, if the account can
// be recovered by email or nickname. Missing accounts return nil to avoid
// account enumeration from the public auth surface.
func (uc *AuthUseCase) StartPasswordReset(ctx context.Context, identifier string, device model.DeviceInfo) error {
	identifier = strings.TrimSpace(identifier)
	if identifier == "" {
		return model.ErrInvalidCredentials
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action:   "AUTH_PASSWORD_RESET_START",
		Provider: model.ProviderEmail,
		Device:   device,
		Metadata: map[string]any{
			"identifier": maskIdentifier(identifier),
		},
	}); err != nil {
		uc.logger.Warn().Err(err).Str("identifier", maskIdentifier(identifier)).Msg("password reset start blocked by fraud policy")
		return model.ErrRateLimited
	}

	user, err := uc.findPasswordUserByIdentifier(ctx, identifier)
	if errors.Is(err, model.ErrInvalidCredentials) {
		uc.logger.Info().Str("identifier", maskIdentifier(identifier)).Msg("password reset requested for unknown identifier")
		return nil
	}
	if err != nil {
		return err
	}
	if !isPasswordResetEligible(user) {
		uc.logger.Info().Str("identifier", maskIdentifier(identifier)).Msg("password reset requested for non-recoverable account")
		return nil
	}

	email := strings.ToLower(strings.TrimSpace(*user.Email))
	destination := passwordResetOTPDestination(email)
	if err := uc.otpStore.CheckRateLimit(ctx, destination); err != nil {
		uc.logger.Warn().Str("email", maskEmail(email)).Msg("password reset OTP rate limited")
		return model.ErrOTPRateLimit
	}

	code, err := generateOTP(uc.otpCfg.Length)
	if err != nil {
		return fmt.Errorf("generating password reset OTP: %w", err)
	}
	if err := uc.otpStore.Store(ctx, destination, code); err != nil {
		return fmt.Errorf("storing password reset OTP: %w", err)
	}

	if uc.emailOTPSender == nil {
		return fmt.Errorf("email OTP sender is not configured")
	}
	if err := uc.emailOTPSender.SendEmailOTP(ctx, email, code); err != nil {
		uc.logger.Error().Err(err).Str("email", maskEmail(email)).Msg("failed to send password reset OTP")
		return fmt.Errorf("sending password reset OTP: %w", err)
	}

	uc.logger.Info().Str("email", maskEmail(email)).Msg("password reset OTP sent")
	return nil
}

// VerifyPasswordReset verifies a reset OTP and updates the password hash.
func (uc *AuthUseCase) VerifyPasswordReset(ctx context.Context, identifier, code, password string, device model.DeviceInfo) error {
	identifier = strings.TrimSpace(identifier)
	code = strings.TrimSpace(code)
	password = strings.TrimSpace(password)
	if identifier == "" {
		return model.ErrInvalidCredentials
	}
	if code == "" {
		return model.ErrInvalidOTP
	}
	if err := validatePassword(password); err != nil {
		return err
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action:   "AUTH_PASSWORD_RESET_VERIFY",
		Provider: model.ProviderEmail,
		Device:   device,
		Metadata: map[string]any{
			"identifier": maskIdentifier(identifier),
		},
	}); err != nil {
		uc.logger.Warn().Err(err).Str("identifier", maskIdentifier(identifier)).Msg("password reset verify blocked by fraud policy")
		return model.ErrRateLimited
	}

	user, err := uc.findPasswordUserByIdentifier(ctx, identifier)
	if err != nil {
		if errors.Is(err, model.ErrInvalidCredentials) {
			return model.ErrInvalidOTP
		}
		return err
	}
	if !isPasswordResetEligible(user) {
		return model.ErrInvalidOTP
	}

	email := strings.ToLower(strings.TrimSpace(*user.Email))
	valid, err := uc.otpStore.Verify(ctx, passwordResetOTPDestination(email), code)
	if err != nil {
		return fmt.Errorf("verifying password reset OTP: %w", err)
	}
	if !valid {
		return model.ErrInvalidOTP
	}

	if !user.EmailVerified {
		if err := uc.userRepo.UpdateEmailVerification(ctx, user.ID, true); err != nil {
			return fmt.Errorf("marking password reset email verified: %w", err)
		}
		user.EmailVerified = true
	}

	passwordHash, err := hashPassword(password)
	if err != nil {
		return fmt.Errorf("hashing password: %w", err)
	}
	if err := uc.userRepo.UpdatePasswordHash(ctx, user.ID, passwordHash); err != nil {
		return fmt.Errorf("updating password hash: %w", err)
	}

	uc.logger.Info().Str("user_id", user.ID.String()).Msg("password reset completed")
	return nil
}

// StartPasswordChange validates the active session and current password, then
// sends a sensitive-action OTP to the verified account email.
func (uc *AuthUseCase) StartPasswordChange(ctx context.Context, accessToken, currentPassword string, device model.DeviceInfo) error {
	currentPassword = strings.TrimSpace(currentPassword)
	if currentPassword == "" {
		return model.ErrPasswordRequired
	}

	user, err := uc.authenticatedPasswordUser(ctx, accessToken)
	if err != nil {
		return err
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action:      "AUTH_PASSWORD_CHANGE_START",
		ActorUserID: &user.ID,
		Provider:    model.ProviderEmail,
		Device:      device,
		Metadata: map[string]any{
			"email": maskEmail(*user.Email),
		},
	}); err != nil {
		uc.logger.Warn().Err(err).Str("user_id", user.ID.String()).Msg("password change start blocked by fraud policy")
		return model.ErrRateLimited
	}

	if err := verifyPassword(*user.PasswordHash, currentPassword); err != nil {
		return model.ErrInvalidCredentials
	}

	destination := passwordChangeOTPDestination(user.ID)
	if err := uc.otpStore.CheckRateLimit(ctx, destination); err != nil {
		uc.logger.Warn().Str("user_id", user.ID.String()).Msg("password change OTP rate limited")
		return model.ErrOTPRateLimit
	}

	code, err := generateOTP(uc.otpCfg.Length)
	if err != nil {
		return fmt.Errorf("generating password change OTP: %w", err)
	}
	if err := uc.otpStore.Store(ctx, destination, code); err != nil {
		return fmt.Errorf("storing password change OTP: %w", err)
	}

	if uc.emailOTPSender == nil {
		return fmt.Errorf("email OTP sender is not configured")
	}
	email := strings.ToLower(strings.TrimSpace(*user.Email))
	if err := uc.emailOTPSender.SendEmailOTP(ctx, email, code); err != nil {
		uc.logger.Error().Err(err).Str("email", maskEmail(email)).Msg("failed to send password change OTP")
		return fmt.Errorf("sending password change OTP: %w", err)
	}

	uc.logger.Info().Str("user_id", user.ID.String()).Msg("password change OTP sent")
	return nil
}

// VerifyPasswordChange confirms the sensitive-action OTP and updates the
// authenticated user's password. The current password is checked again so a
// stale OTP cannot finish the change after the password was rotated.
func (uc *AuthUseCase) VerifyPasswordChange(ctx context.Context, accessToken, currentPassword, code, newPassword string, device model.DeviceInfo) error {
	currentPassword = strings.TrimSpace(currentPassword)
	code = strings.TrimSpace(code)
	newPassword = strings.TrimSpace(newPassword)
	if currentPassword == "" {
		return model.ErrPasswordRequired
	}
	if code == "" {
		return model.ErrInvalidOTP
	}
	if err := validatePassword(newPassword); err != nil {
		return err
	}

	user, err := uc.authenticatedPasswordUser(ctx, accessToken)
	if err != nil {
		return err
	}

	if err := uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action:      "AUTH_PASSWORD_CHANGE_VERIFY",
		ActorUserID: &user.ID,
		Provider:    model.ProviderEmail,
		Device:      device,
		Metadata: map[string]any{
			"email": maskEmail(*user.Email),
		},
	}); err != nil {
		uc.logger.Warn().Err(err).Str("user_id", user.ID.String()).Msg("password change verify blocked by fraud policy")
		return model.ErrRateLimited
	}

	if err := verifyPassword(*user.PasswordHash, currentPassword); err != nil {
		return model.ErrInvalidCredentials
	}
	if err := verifyPassword(*user.PasswordHash, newPassword); err == nil {
		return model.ErrPasswordUnchanged
	}

	valid, err := uc.otpStore.Verify(ctx, passwordChangeOTPDestination(user.ID), code)
	if err != nil {
		return fmt.Errorf("verifying password change OTP: %w", err)
	}
	if !valid {
		return model.ErrInvalidOTP
	}

	passwordHash, err := hashPassword(newPassword)
	if err != nil {
		return fmt.Errorf("hashing password: %w", err)
	}
	if err := uc.userRepo.UpdatePasswordHash(ctx, user.ID, passwordHash); err != nil {
		return fmt.Errorf("updating password hash: %w", err)
	}

	uc.logger.Info().Str("user_id", user.ID.String()).Msg("password changed")
	return nil
}

// --- OAuth Flows ---

// GoogleLogin authenticates via Google ID Token.
func (uc *AuthUseCase) GoogleLogin(ctx context.Context, idToken string, device model.DeviceInfo) (*model.AuthResult, error) {
	userInfo, err := uc.googleVerifier.Verify(ctx, idToken)
	if err != nil {
		return nil, model.ErrOAuthFailed
	}

	return uc.oauthLogin(ctx, model.ProviderGoogle, userInfo, device)
}

// AppleLogin authenticates via Apple ID Token.
func (uc *AuthUseCase) AppleLogin(ctx context.Context, idToken string, device model.DeviceInfo) (*model.AuthResult, error) {
	userInfo, err := uc.appleVerifier.Verify(ctx, idToken)
	if err != nil {
		return nil, model.ErrOAuthFailed
	}

	return uc.oauthLogin(ctx, model.ProviderApple, userInfo, device)
}

// oauthLogin is the shared logic for Google/Apple login.
func (uc *AuthUseCase) oauthLogin(ctx context.Context, provider model.AuthProvider, info *model.OAuthUserInfo, device model.DeviceInfo) (*model.AuthResult, error) {
	if info.ProviderID == "" {
		return nil, model.ErrOAuthProviderID
	}

	user, err := uc.userRepo.FindByProvider(ctx, provider, info.ProviderID)
	if err != nil {
		return nil, fmt.Errorf("finding user by provider: %w", err)
	}

	isNew := false
	if user == nil {
		isNew = true

		user = &model.AuthUser{
			ID:       uuid.New(),
			Role:     model.RoleTourist,
			IsActive: true,
		}
		if err := uc.userRepo.Create(ctx, user); err != nil {
			return nil, fmt.Errorf("creating user: %w", err)
		}

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

	result, err := uc.tokenClient.GenerateUserTokens(ctx, user.ID.String(), string(user.Role), nil, device)
	if err != nil {
		return nil, model.ErrTokenServiceUnavailable
	}

	result.IsNewUser = isNew

	if email := strings.TrimSpace(info.Email); email != "" {
		result.PrimaryEmailHint = strPtr(email)
	}

	uc.logger.Info().
		Str("user_id", user.ID.String()).
		Str("provider", string(provider)).
		Bool("is_new", isNew).
		Str("session_id", result.SessionID).
		Msg("OAuth login successful")

	return result, nil
}

// --- Token Management ---

// RefreshTokens issues new tokens using a refresh token.
func (uc *AuthUseCase) RefreshTokens(ctx context.Context, refreshToken string, device model.DeviceInfo) (*model.AuthResult, error) {
	claims, err := uc.tokenClient.ValidateRefreshToken(ctx, refreshToken)
	if err != nil {
		uc.logger.Error().Err(err).Msg("refresh token validation failed")
		return nil, model.ErrInvalidRefreshToken
	}

	var actorUserID *uuid.UUID
	if claims != nil {
		if parsed, parseErr := uuid.Parse(strings.TrimSpace(claims.Subject)); parseErr == nil {
			actorUserID = &parsed
		}
	}
	if err = uc.enforceAuthFraud(ctx, port.FraudAssessmentInput{
		Action:      "AUTH_TOKEN_REFRESH",
		ActorUserID: actorUserID,
		Device:      device,
	}); err != nil {
		uc.logger.Warn().Err(err).Msg("token refresh blocked by fraud policy")
		return nil, model.ErrRateLimited
	}

	result, err := uc.tokenClient.RefreshTokens(ctx, refreshToken, device)
	if err != nil {
		uc.logger.Error().Err(err).Msg("token refresh failed")
		return nil, model.ErrInvalidRefreshToken
	}
	return result, nil
}

func (uc *AuthUseCase) enforceAuthFraud(ctx context.Context, input port.FraudAssessmentInput) error {
	if uc.fraud == nil {
		return nil
	}

	decision, err := uc.fraud.AssessAuth(ctx, input)
	if err != nil {
		return fmt.Errorf("assess auth fraud: %w", err)
	}
	if decision == nil || decision.ShadowMode || decision.Decision == "" || decision.Decision == port.FraudDecisionAllow {
		return nil
	}
	return model.ErrRateLimited
}

func (uc *AuthUseCase) ensureNoOnboardingTechBreak(ctx context.Context, scopeCode string, email string, nickname string) error {
	if uc.techBreaks == nil {
		return nil
	}
	input := port.TechBreakCheckInput{
		DomainCode: onboardingDomainCode,
		Email:      strings.ToLower(strings.TrimSpace(email)),
		Nickname:   strings.TrimSpace(nickname),
		ScopeCodes: []string{scopeCode},
	}
	active, err := uc.techBreaks.HasActiveTechBreak(ctx, input)
	if err != nil {
		uc.logger.Warn().Err(err).Str("domain_code", input.DomainCode).Str("scope_code", scopeCode).Msg("tech break check failed")
		return nil
	}
	if active {
		return model.ErrTechnicalMaintenance
	}
	return nil
}

func (uc *AuthUseCase) ensureNoOnboardingTechBreakForIdentifier(ctx context.Context, scopeCode string, identifier string) error {
	identifier = strings.TrimSpace(identifier)
	if identifier == "" {
		return nil
	}
	if email, err := normalizeEmail(identifier); err == nil {
		return uc.ensureNoOnboardingTechBreak(ctx, scopeCode, email, "")
	}
	return uc.ensureNoOnboardingTechBreak(ctx, scopeCode, "", identifier)
}

func (uc *AuthUseCase) isPhoneOTPBypassAllowed(ctx context.Context, phone string, code string) bool {
	if uc.isFeatureFlagValueEnabled(ctx, skipSendingPhoneOTPFlag, phone, normalizePhone) &&
		strings.TrimSpace(code) == featureFlagOTPBypassCode {
		return true
	}
	return uc.isTestOTPBypassAllowed(phone, code)
}

func (uc *AuthUseCase) isEmailOTPBypassAllowed(ctx context.Context, email string, code string) bool {
	return uc.isFeatureFlagValueEnabled(ctx, skipSendingEmailOTPFlag, email, normalizeFeatureFlagEmail) &&
		strings.TrimSpace(code) == featureFlagOTPBypassCode
}

func (uc *AuthUseCase) shouldSkipPhoneOTPSending(ctx context.Context, phone string) bool {
	return uc.isFeatureFlagValueEnabled(ctx, skipSendingPhoneOTPFlag, phone, normalizePhone)
}

func (uc *AuthUseCase) shouldSkipEmailOTPSending(ctx context.Context, email string) bool {
	return uc.isFeatureFlagValueEnabled(ctx, skipSendingEmailOTPFlag, email, normalizeFeatureFlagEmail)
}

func (uc *AuthUseCase) isFeatureFlagValueEnabled(
	ctx context.Context,
	flagCode string,
	rawValue string,
	normalize func(string) string,
) bool {
	if uc.featureFlags == nil {
		return false
	}
	expected := normalize(rawValue)
	if expected == "" {
		return false
	}
	flag, err := uc.featureFlags.GetFeatureFlag(ctx, onboardingDomainCode, flagCode)
	if err != nil {
		uc.logger.Warn().Err(err).Str("domain_code", onboardingDomainCode).Str("feature_flag", flagCode).Msg("feature flag check failed")
		return false
	}
	if !flag.Enabled || flag.Type != port.FeatureFlagTypeArrayString {
		return false
	}
	for _, value := range flag.Values {
		if normalize(value) == expected {
			return true
		}
	}
	return false
}

func normalizeFeatureFlagEmail(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

func (uc *AuthUseCase) isTestOTPBypassAllowed(phone string, code string) bool {
	env := strings.TrimSpace(uc.env)
	if strings.EqualFold(env, "production") {
		return false
	}

	if !uc.securityCfg.TestOTPBypassEnabled {
		return false
	}
	expectedCode := strings.TrimSpace(uc.securityCfg.TestOTPBypassCode)
	if expectedCode == "" || strings.TrimSpace(code) != expectedCode {
		return false
	}
	for _, configuredPhone := range strings.Split(uc.securityCfg.TestOTPBypassPhones, ",") {
		if normalizePhone(configuredPhone) == phone {
			return true
		}
	}
	return false
}

// Logout revokes the current session. We extract the session_id from whichever
// token the client provides — preferring the access token (cheaper to validate).
// Falls back to per-JTI revoke for defence in depth and so that pre-session
// tokens (issued by an older token-service) can still be invalidated.
func (uc *AuthUseCase) Logout(ctx context.Context, accessToken, refreshToken string) error {
	var sessionID string

	if accessToken != "" {
		if claims, err := uc.tokenClient.ValidateAccessToken(ctx, accessToken); err == nil {
			if claims.SessionID != "" {
				sessionID = claims.SessionID
			} else if revokeErr := uc.tokenClient.RevokeToken(ctx, claims.JTI, claims.ExpiresAt, "logout"); revokeErr != nil {
				uc.logger.Warn().Err(revokeErr).Str("jti", claims.JTI).Msg("failed to revoke access JTI")
			}
		}
	}

	if refreshToken != "" {
		if claims, err := uc.tokenClient.ValidateRefreshToken(ctx, refreshToken); err == nil {
			if sessionID == "" && claims.SessionID != "" {
				sessionID = claims.SessionID
			} else if claims.SessionID == "" {
				if revokeErr := uc.tokenClient.RevokeToken(ctx, claims.JTI, claims.ExpiresAt, "logout"); revokeErr != nil {
					uc.logger.Warn().Err(revokeErr).Str("jti", claims.JTI).Msg("failed to revoke refresh JTI")
				}
			}
		}
	}

	if sessionID != "" {
		if err := uc.tokenClient.RevokeSession(ctx, sessionID, "user_logout"); err != nil {
			uc.logger.Warn().Err(err).Str("session_id", sessionID).Msg("failed to revoke session")
			return err
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

func (uc *AuthUseCase) findPasswordUserByIdentifier(ctx context.Context, identifier string) (*model.AuthUser, error) {
	if email, err := normalizeEmail(identifier); err == nil {
		user, findErr := uc.userRepo.FindByEmail(ctx, email)
		if findErr != nil {
			return nil, fmt.Errorf("finding user by email: %w", findErr)
		}
		return user, nil
	}

	if uc.nicknameLookup == nil {
		return nil, model.ErrInvalidCredentials
	}

	userID, err := uc.nicknameLookup.ResolveUserIDByNickname(ctx, identifier)
	if err != nil || userID == uuid.Nil {
		return nil, model.ErrInvalidCredentials
	}

	user, err := uc.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("finding user by id: %w", err)
	}
	return user, nil
}

func (uc *AuthUseCase) authenticatedPasswordUser(ctx context.Context, accessToken string) (*model.AuthUser, error) {
	accessToken = strings.TrimSpace(accessToken)
	if accessToken == "" {
		return nil, model.ErrInvalidCredentials
	}
	if uc.tokenClient == nil {
		return nil, model.ErrInvalidCredentials
	}

	claims, err := uc.tokenClient.ValidateAccessToken(ctx, accessToken)
	if err != nil || claims == nil {
		return nil, model.ErrInvalidCredentials
	}

	userID, err := uuid.Parse(strings.TrimSpace(claims.Subject))
	if err != nil || userID == uuid.Nil {
		return nil, model.ErrInvalidCredentials
	}

	user, err := uc.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("finding authenticated user by id: %w", err)
	}
	if user == nil {
		return nil, model.ErrInvalidCredentials
	}
	if !user.IsActive {
		return nil, model.ErrUserBlocked
	}
	if user.Email == nil || strings.TrimSpace(*user.Email) == "" || !user.EmailVerified {
		return nil, model.ErrEmailNotVerified
	}
	if user.PasswordHash == nil || *user.PasswordHash == "" {
		return nil, model.ErrInvalidCredentials
	}
	return user, nil
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

func normalizeEmail(email string) (string, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" {
		return "", model.ErrEmailRequired
	}
	if len(email) > 320 {
		return "", model.ErrEmailInvalid
	}
	address, err := mail.ParseAddress(email)
	if err != nil || address == nil || strings.TrimSpace(address.Address) != email {
		return "", model.ErrEmailInvalid
	}
	return email, nil
}

func validatePassword(password string) error {
	password = strings.TrimSpace(password)
	if password == "" {
		return model.ErrPasswordRequired
	}
	if len(password) < 8 || len(password) > 128 {
		return model.ErrPasswordWeak
	}

	var hasLetter bool
	var hasDigit bool
	for _, r := range password {
		if unicode.IsLetter(r) {
			hasLetter = true
		}
		if unicode.IsDigit(r) {
			hasDigit = true
		}
	}
	if !hasLetter || !hasDigit {
		return model.ErrPasswordWeak
	}
	return nil
}

func hashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}

func verifyPassword(passwordHash, password string) error {
	return bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password))
}

func emailOTPDestination(email string) string {
	return "email:" + strings.ToLower(strings.TrimSpace(email))
}

func passwordResetOTPDestination(email string) string {
	return "password_reset:" + strings.ToLower(strings.TrimSpace(email))
}

func passwordChangeOTPDestination(userID uuid.UUID) string {
	return "password_change:" + userID.String()
}

func isPasswordResetEligible(user *model.AuthUser) bool {
	return user != nil &&
		user.IsActive &&
		user.Email != nil &&
		strings.TrimSpace(*user.Email) != "" &&
		user.PasswordHash != nil &&
		*user.PasswordHash != ""
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

func maskEmail(email string) string {
	email = strings.TrimSpace(email)
	parts := strings.Split(email, "@")
	if len(parts) != 2 {
		return "***"
	}
	local := parts[0]
	domain := parts[1]
	if local == "" || domain == "" {
		return "***"
	}
	if len(local) <= 2 {
		return local[:1] + "***@" + domain
	}
	return local[:2] + "***@" + domain
}

func maskIdentifier(identifier string) string {
	if email, err := normalizeEmail(identifier); err == nil {
		return maskEmail(email)
	}
	identifier = strings.TrimSpace(identifier)
	if len(identifier) <= 3 {
		return "***"
	}
	return identifier[:2] + "***"
}

func strPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
