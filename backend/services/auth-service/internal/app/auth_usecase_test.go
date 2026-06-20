package app

import (
	"context"
	"errors"
	"io"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"kz/inflap/backend/services/auth-service/internal/config"
	"kz/inflap/backend/services/auth-service/internal/domain/model"
	"kz/inflap/backend/services/auth-service/internal/domain/port"
)

func TestAuthUseCaseDoesNotContainLegacyHardcodedOTPPhones(t *testing.T) {
	source, err := os.ReadFile("auth_usecase.go")
	if err != nil {
		t.Fatalf("ReadFile() error = %v", err)
	}
	body := string(source)
	for _, phone := range []string{"+" + "7705" + "1698779", "+" + "7705" + "1471066"} {
		if strings.Contains(body, phone) {
			t.Fatalf("auth usecase still contains legacy hardcoded OTP bypass phone %s", phone)
		}
	}
}

func TestVerifyOTPAndLoginDoesNotAllowLegacyZeroOTPWithoutFeatureFlag(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{verifyResult: false}
	uc := newTestAuthUseCase(userRepo, otpStore, "development")

	result, err := uc.VerifyOTPAndLogin(context.Background(), "77000000001", "000000", model.DeviceInfo{})
	if !errors.Is(err, model.ErrInvalidOTP) {
		t.Fatalf("VerifyOTPAndLogin() error = %v, want %v", err, model.ErrInvalidOTP)
	}
	if result != nil {
		t.Fatalf("VerifyOTPAndLogin() result = %#v, want nil", result)
	}
	if otpStore.verifyCalls != 1 {
		t.Fatalf("OTP store was called %d times, want 1 without feature flag bypass", otpStore.verifyCalls)
	}
}

func TestVerifyOTPAndLoginAllowsPhoneFeatureFlagWithFourZeroOTP(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{verifyResult: false}
	uc := newTestAuthUseCase(userRepo, otpStore, "production")
	uc.SetFeatureFlagReader(stubFeatureFlagReader{
		flags: map[string]port.FeatureFlag{
			"ONBOARDING:SKIP_SENDING_PHONE_OTP": {
				Enabled: true,
				Type:    port.FeatureFlagTypeArrayString,
				Values:  []string{"+77000000001"},
			},
		},
	})

	result, err := uc.VerifyOTPAndLogin(context.Background(), "77000000001", "0000", model.DeviceInfo{})
	if err != nil {
		t.Fatalf("VerifyOTPAndLogin() error = %v", err)
	}
	if result == nil || result.AccessToken == "" || result.RefreshToken == "" {
		t.Fatal("VerifyOTPAndLogin() did not return issued tokens")
	}
	if otpStore.verifyCalls != 0 {
		t.Fatalf("OTP store was called %d times, want 0 for feature-flag OTP bypass", otpStore.verifyCalls)
	}
}

func TestSendOTPSkipsDeliveryWhenPhoneFeatureFlagMatches(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{}
	otpSender := &spyOTPSender{}
	uc := newTestAuthUseCaseWithSender(userRepo, otpStore, otpSender, "production")
	uc.SetFeatureFlagReader(stubFeatureFlagReader{
		flags: map[string]port.FeatureFlag{
			"ONBOARDING:SKIP_SENDING_PHONE_OTP": {
				Enabled: true,
				Type:    port.FeatureFlagTypeArrayString,
				Values:  []string{"+77000000001"},
			},
		},
	})

	if err := uc.SendOTP(context.Background(), "77000000001", model.DeviceInfo{}); err != nil {
		t.Fatalf("SendOTP() error = %v", err)
	}
	if otpSender.calls != 0 {
		t.Fatalf("OTP sender was called %d times, want 0 when skip flag matches", otpSender.calls)
	}
	if otpStore.lastStoreCode == "" {
		t.Fatal("OTP store code is empty, want a stored code for rate-limit and audit consistency")
	}
}

func TestEmailRegistrationFeatureFlagSkipsSendAndAllowsFourZeroOTP(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{verifyResult: false}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)
	uc.env = "production"
	uc.SetFeatureFlagReader(stubFeatureFlagReader{
		flags: map[string]port.FeatureFlag{
			"ONBOARDING:SKIP_SENDING_EMAIL_OTP": {
				Enabled: true,
				Type:    port.FeatureFlagTypeArrayString,
				Values:  []string{"dkhvan.developer@gmail.com"},
			},
		},
	})

	if err := uc.StartEmailRegistration(context.Background(), "dkhvan.developer@gmail.com", "Passw0rd!", model.DeviceInfo{}); err != nil {
		t.Fatalf("StartEmailRegistration() error = %v", err)
	}
	if emailSender.lastEmail != "" {
		t.Fatalf("email sender was called for %q, want no delivery when skip flag matches", emailSender.lastEmail)
	}

	result, err := uc.VerifyEmailRegistration(context.Background(), "dkhvan.developer@gmail.com", "0000", model.DeviceInfo{})
	if err != nil {
		t.Fatalf("VerifyEmailRegistration() error = %v", err)
	}
	if result == nil || result.AccessToken == "" {
		t.Fatal("VerifyEmailRegistration() did not return issued tokens")
	}
	if otpStore.verifyCalls != 0 {
		t.Fatalf("OTP store was called %d times, want 0 for feature-flag email OTP bypass", otpStore.verifyCalls)
	}
}

func TestAuthFlowReturnsTechnicalMaintenanceWhenActiveTechBreakMatches(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{}
	uc := newTestAuthUseCase(userRepo, otpStore, "production")
	uc.SetTechBreakChecker(stubTechBreakChecker{active: true})

	err := uc.SendOTP(context.Background(), "77000000001", model.DeviceInfo{})
	if !errors.Is(err, model.ErrTechnicalMaintenance) {
		t.Fatalf("SendOTP() error = %v, want %v", err, model.ErrTechnicalMaintenance)
	}
	if otpStore.lastStoreCode != "" {
		t.Fatal("OTP was stored even though active technical maintenance should block before side effects")
	}
}

func newTestAuthUseCase(userRepo port.UserRepository, otpStore port.OTPStore, env string) *AuthUseCase {
	return newTestAuthUseCaseWithSender(userRepo, otpStore, noopOTPSender{}, env)
}

func newTestAuthUseCaseWithSender(
	userRepo port.UserRepository,
	otpStore port.OTPStore,
	otpSender port.OTPSender,
	env string,
) *AuthUseCase {
	return NewAuthUseCaseWithFraud(
		userRepo,
		otpStore,
		otpSender,
		nil,
		nil,
		stubTokenClient{},
		nil,
		config.OTPConfig{Length: 6},
		config.AuthSecurityConfig{},
		env,
		zerolog.New(io.Discard),
	)
}

type inMemoryUserRepository struct {
	byPhone map[string]*model.AuthUser
	byEmail map[string]*model.AuthUser
	byID    map[uuid.UUID]*model.AuthUser
}

func newInMemoryUserRepository() *inMemoryUserRepository {
	return &inMemoryUserRepository{
		byPhone: make(map[string]*model.AuthUser),
		byEmail: make(map[string]*model.AuthUser),
		byID:    make(map[uuid.UUID]*model.AuthUser),
	}
}

func (r *inMemoryUserRepository) FindByPhone(_ context.Context, phone string) (*model.AuthUser, error) {
	return r.byPhone[phone], nil
}

func (r *inMemoryUserRepository) FindByEmail(_ context.Context, email string) (*model.AuthUser, error) {
	return r.byEmail[strings.ToLower(strings.TrimSpace(email))], nil
}

func (r *inMemoryUserRepository) FindByID(_ context.Context, userID uuid.UUID) (*model.AuthUser, error) {
	return r.byID[userID], nil
}

func (r *inMemoryUserRepository) FindByProvider(_ context.Context, _ model.AuthProvider, _ string) (*model.AuthUser, error) {
	return nil, nil
}

func (r *inMemoryUserRepository) Create(_ context.Context, user *model.AuthUser) error {
	if user.Phone != nil {
		r.byPhone[*user.Phone] = user
	}
	if user.Email != nil {
		r.byEmail[strings.ToLower(strings.TrimSpace(*user.Email))] = user
	}
	r.byID[user.ID] = user
	return nil
}

func (r *inMemoryUserRepository) LinkProvider(_ context.Context, _ *model.AuthProviderLink) error {
	return nil
}

func (r *inMemoryUserRepository) UpdateEmailVerification(_ context.Context, userID uuid.UUID, verified bool) error {
	if user := r.byID[userID]; user != nil {
		user.EmailVerified = verified
	}
	return nil
}

func (r *inMemoryUserRepository) UpdatePasswordHash(_ context.Context, userID uuid.UUID, passwordHash string) error {
	if user := r.byID[userID]; user != nil {
		user.PasswordHash = &passwordHash
		if user.Email != nil {
			r.byEmail[strings.ToLower(strings.TrimSpace(*user.Email))] = user
		}
	}
	return nil
}

type spyOTPStore struct {
	verifyCalls              int
	verifyResult             bool
	verifyErr                error
	rateLimitErr             error
	lastStoreDestination     string
	lastStoreCode            string
	lastVerifyDestination    string
	lastVerifyCode           string
	lastRateLimitDestination string
}

func (s *spyOTPStore) Store(_ context.Context, destination, code string) error {
	s.lastStoreDestination = destination
	s.lastStoreCode = code
	return nil
}

func (s *spyOTPStore) Verify(_ context.Context, destination, code string) (bool, error) {
	s.verifyCalls++
	s.lastVerifyDestination = destination
	s.lastVerifyCode = code
	return s.verifyResult, s.verifyErr
}

func (s *spyOTPStore) CheckRateLimit(_ context.Context, destination string) error {
	s.lastRateLimitDestination = destination
	return s.rateLimitErr
}

type noopOTPSender struct{}

func (noopOTPSender) Send(_ context.Context, _, _ string) error {
	return nil
}

type spyOTPSender struct {
	calls     int
	lastPhone string
	lastCode  string
}

func (s *spyOTPSender) Send(_ context.Context, phone, code string) error {
	s.calls++
	s.lastPhone = phone
	s.lastCode = code
	return nil
}

type spyEmailOTPSender struct {
	lastEmail string
	lastCode  string
}

func (s *spyEmailOTPSender) SendEmailOTP(_ context.Context, email, code string) error {
	s.lastEmail = email
	s.lastCode = code
	return nil
}

type stubNicknameResolver struct {
	users map[string]uuid.UUID
}

func (s *stubNicknameResolver) ResolveUserIDByNickname(_ context.Context, nickname string) (uuid.UUID, error) {
	if s == nil {
		return uuid.Nil, nil
	}
	return s.users[strings.ToLower(strings.TrimSpace(nickname))], nil
}

func newTestEmailAuthUseCase(
	userRepo port.UserRepository,
	otpStore port.OTPStore,
	emailSender port.EmailOTPSender,
	resolver port.NicknameResolver,
) *AuthUseCase {
	uc := newTestAuthUseCase(userRepo, otpStore, "development")
	uc.SetEmailOTPSender(emailSender)
	uc.SetNicknameResolver(resolver)
	return uc
}

func mustPasswordHash(t *testing.T, password string) *string {
	t.Helper()
	hash, err := hashPassword(password)
	if err != nil {
		t.Fatalf("hashPassword() error = %v", err)
	}
	return &hash
}

type stubTokenClient struct {
	accessClaims      *port.TokenClaims
	validateAccessErr error
}

func (stubTokenClient) GenerateUserTokens(_ context.Context, _, _ string, _ []string, _ model.DeviceInfo) (*model.AuthResult, error) {
	return &model.AuthResult{
		AccessToken:      "access-token",
		RefreshToken:     "refresh-token",
		TokenType:        "Bearer",
		ExpiresAt:        time.Now().Add(time.Hour),
		RefreshExpiresAt: time.Now().Add(24 * time.Hour),
		SessionID:        uuid.NewString(),
	}, nil
}

func (stubTokenClient) RefreshTokens(_ context.Context, _ string, _ model.DeviceInfo) (*model.AuthResult, error) {
	return nil, nil
}

func (stubTokenClient) RevokeToken(_ context.Context, _ string, _ int64, _ string) error {
	return nil
}

func (stubTokenClient) RevokeSession(_ context.Context, _, _ string) error {
	return nil
}

func (c stubTokenClient) ValidateAccessToken(_ context.Context, _ string) (*port.TokenClaims, error) {
	if c.validateAccessErr != nil {
		return nil, c.validateAccessErr
	}
	return c.accessClaims, nil
}

func (stubTokenClient) ValidateRefreshToken(_ context.Context, _ string) (*port.TokenClaims, error) {
	return nil, nil
}

type stubFeatureFlagReader struct {
	flags map[string]port.FeatureFlag
	err   error
}

func (s stubFeatureFlagReader) GetFeatureFlag(_ context.Context, domainCode string, code string) (port.FeatureFlag, error) {
	if s.err != nil {
		return port.FeatureFlag{}, s.err
	}
	return s.flags[strings.ToUpper(strings.TrimSpace(domainCode))+":"+strings.ToUpper(strings.TrimSpace(code))], nil
}

type stubTechBreakChecker struct {
	active bool
	err    error
	last   port.TechBreakCheckInput
}

func (s stubTechBreakChecker) HasActiveTechBreak(_ context.Context, input port.TechBreakCheckInput) (bool, error) {
	s.last = input
	if s.err != nil {
		return false, s.err
	}
	return s.active, nil
}
