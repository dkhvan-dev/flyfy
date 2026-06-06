package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/auth-service/internal/domain/model"
	"kz/inflap/backend/services/auth-service/internal/domain/port"
)

func TestStartEmailRegistrationStoresEmailOTPAndPendingPassword(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)

	err := uc.StartEmailRegistration(
		context.Background(),
		"  Traveler@Example.COM ",
		"travel42Pass",
		model.DeviceInfo{},
	)

	if err != nil {
		t.Fatalf("StartEmailRegistration() error = %v", err)
	}
	if otpStore.lastStoreDestination != "email:traveler@example.com" {
		t.Fatalf("OTP destination = %q, want email:traveler@example.com", otpStore.lastStoreDestination)
	}
	if emailSender.lastEmail != "traveler@example.com" {
		t.Fatalf("email sender destination = %q, want traveler@example.com", emailSender.lastEmail)
	}
	user := userRepo.byEmail["traveler@example.com"]
	if user == nil || user.PasswordHash == nil || *user.PasswordHash == "" {
		t.Fatal("unverified auth user with password hash was not stored")
	}
	if user.EmailVerified {
		t.Fatal("email must not be marked verified before OTP verification")
	}
}

func TestStartEmailRegistrationResendsOTPForUnverifiedEmail(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)

	if err := uc.StartEmailRegistration(context.Background(), "traveler@example.com", "travel42Pass", model.DeviceInfo{}); err != nil {
		t.Fatalf("first StartEmailRegistration() error = %v", err)
	}
	user := userRepo.byEmail["traveler@example.com"]
	if user == nil || user.PasswordHash == nil {
		t.Fatal("pending auth user was not created")
	}
	firstUserID := user.ID
	firstHash := *user.PasswordHash
	firstCode := emailSender.lastCode

	if err := uc.StartEmailRegistration(context.Background(), "TRAVELER@example.com", "newTravel42Pass", model.DeviceInfo{}); err != nil {
		t.Fatalf("second StartEmailRegistration() error = %v", err)
	}

	user = userRepo.byEmail["traveler@example.com"]
	if user.ID != firstUserID {
		t.Fatalf("pending auth user ID changed from %s to %s", firstUserID, user.ID)
	}
	if user.PasswordHash == nil || *user.PasswordHash == firstHash {
		t.Fatal("pending auth user password hash was not updated")
	}
	if emailSender.lastEmail != "traveler@example.com" {
		t.Fatalf("email sender destination = %q, want traveler@example.com", emailSender.lastEmail)
	}
	if emailSender.lastCode == "" || emailSender.lastCode == firstCode {
		t.Fatalf("email OTP code was not regenerated, first=%q last=%q", firstCode, emailSender.lastCode)
	}
	if otpStore.lastStoreDestination != "email:traveler@example.com" {
		t.Fatalf("OTP destination = %q, want email:traveler@example.com", otpStore.lastStoreDestination)
	}
}

func TestStartEmailRegistrationRejectsVerifiedEmail(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	uc := newTestEmailAuthUseCase(userRepo, &spyOTPStore{}, &spyEmailOTPSender{}, nil)

	if err := uc.StartEmailRegistration(context.Background(), "traveler@example.com", "travel42Pass", model.DeviceInfo{}); err != nil {
		t.Fatalf("StartEmailRegistration() error = %v", err)
	}
	userRepo.byEmail["traveler@example.com"].EmailVerified = true

	err := uc.StartEmailRegistration(context.Background(), "traveler@example.com", "newTravel42Pass", model.DeviceInfo{})
	if !errors.Is(err, model.ErrEmailAlreadyExists) {
		t.Fatalf("StartEmailRegistration() error = %v, want %v", err, model.ErrEmailAlreadyExists)
	}
}

func TestVerifyEmailRegistrationIssuesTokens(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{verifyResult: true}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)

	if err := uc.StartEmailRegistration(context.Background(), "traveler@example.com", "travel42Pass", model.DeviceInfo{}); err != nil {
		t.Fatalf("StartEmailRegistration() error = %v", err)
	}

	result, err := uc.VerifyEmailRegistration(context.Background(), "TRAVELER@example.com", "123456", model.DeviceInfo{})
	if err != nil {
		t.Fatalf("VerifyEmailRegistration() error = %v", err)
	}
	if result == nil || result.AccessToken == "" || result.RefreshToken == "" {
		t.Fatal("VerifyEmailRegistration() did not issue tokens")
	}
	if result.PrimaryEmailHint == nil || *result.PrimaryEmailHint != "traveler@example.com" {
		t.Fatalf("PrimaryEmailHint = %v, want traveler@example.com", result.PrimaryEmailHint)
	}
	if _, ok := userRepo.byEmail["traveler@example.com"]; !ok {
		t.Fatal("auth user was not created by email")
	}
}

func TestPasswordLoginAcceptsEmailIdentifier(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	uc := newTestEmailAuthUseCase(userRepo, &spyOTPStore{}, &spyEmailOTPSender{}, nil)
	if err := uc.StartEmailRegistration(context.Background(), "traveler@example.com", "travel42Pass", model.DeviceInfo{}); err != nil {
		t.Fatalf("StartEmailRegistration() error = %v", err)
	}
	user := userRepo.byEmail["traveler@example.com"]
	if user == nil {
		t.Fatal("auth user was not created")
	}
	user.EmailVerified = true

	result, err := uc.PasswordLogin(context.Background(), "TRAVELER@example.com", "travel42Pass", model.DeviceInfo{})
	if err != nil {
		t.Fatalf("PasswordLogin() error = %v", err)
	}
	if result == nil || result.AccessToken == "" {
		t.Fatal("PasswordLogin() did not issue tokens")
	}
}

func TestPasswordLoginAcceptsNicknameIdentifierViaResolver(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	resolver := &stubNicknameResolver{
		users: map[string]uuid.UUID{"nomad_aru": userID},
	}
	uc := newTestEmailAuthUseCase(userRepo, &spyOTPStore{}, &spyEmailOTPSender{}, resolver)

	result, err := uc.PasswordLogin(context.Background(), "nomad_aru", "travel42Pass", model.DeviceInfo{})
	if err != nil {
		t.Fatalf("PasswordLogin() error = %v", err)
	}
	if result == nil || result.AccessToken == "" {
		t.Fatal("PasswordLogin() did not issue tokens")
	}
}

func TestPasswordLoginRejectsUnknownNicknameWithoutEnumeration(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	uc := newTestEmailAuthUseCase(userRepo, &spyOTPStore{}, &spyEmailOTPSender{}, &stubNicknameResolver{})

	result, err := uc.PasswordLogin(context.Background(), "missing_nickname", "travel42Pass", model.DeviceInfo{})
	if !errors.Is(err, model.ErrInvalidCredentials) {
		t.Fatalf("PasswordLogin() error = %v, want %v", err, model.ErrInvalidCredentials)
	}
	if result != nil {
		t.Fatalf("PasswordLogin() result = %#v, want nil", result)
	}
}

func TestStartPasswordResetSendsOTPForEmailWithoutSigningIn(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	userRepo.byEmail["traveler@example.com"] = userRepo.byID[userID]
	otpStore := &spyOTPStore{}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)

	err := uc.StartPasswordReset(context.Background(), "  Traveler@Example.COM ", model.DeviceInfo{})

	if err != nil {
		t.Fatalf("StartPasswordReset() error = %v", err)
	}
	if otpStore.lastStoreDestination != "password_reset:traveler@example.com" {
		t.Fatalf("OTP destination = %q, want password_reset:traveler@example.com", otpStore.lastStoreDestination)
	}
	if emailSender.lastEmail != "traveler@example.com" {
		t.Fatalf("email sender destination = %q, want traveler@example.com", emailSender.lastEmail)
	}
}

func TestStartPasswordResetSendsOTPForUnverifiedPendingEmail(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: false,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	userRepo.byEmail["traveler@example.com"] = userRepo.byID[userID]
	otpStore := &spyOTPStore{}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)

	err := uc.StartPasswordReset(context.Background(), "Traveler@Example.COM", model.DeviceInfo{})

	if err != nil {
		t.Fatalf("StartPasswordReset() error = %v", err)
	}
	if otpStore.lastStoreDestination != "password_reset:traveler@example.com" {
		t.Fatalf("OTP destination = %q, want password_reset:traveler@example.com", otpStore.lastStoreDestination)
	}
	if emailSender.lastEmail != "traveler@example.com" {
		t.Fatalf("email sender destination = %q, want traveler@example.com", emailSender.lastEmail)
	}
}

func TestStartPasswordResetChecksOTPRateLimitBeforeSending(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	userRepo.byEmail["traveler@example.com"] = userRepo.byID[userID]
	otpStore := &spyOTPStore{rateLimitErr: errors.New("too many requests")}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)

	err := uc.StartPasswordReset(context.Background(), "traveler@example.com", model.DeviceInfo{})

	if !errors.Is(err, model.ErrOTPRateLimit) {
		t.Fatalf("StartPasswordReset() error = %v, want %v", err, model.ErrOTPRateLimit)
	}
	if otpStore.lastRateLimitDestination != "password_reset:traveler@example.com" {
		t.Fatalf("rate limit destination = %q, want password_reset:traveler@example.com", otpStore.lastRateLimitDestination)
	}
	if otpStore.lastStoreDestination != "" {
		t.Fatalf("OTP destination = %q, want empty when rate-limited", otpStore.lastStoreDestination)
	}
	if emailSender.lastEmail != "" {
		t.Fatalf("email sender destination = %q, want empty when rate-limited", emailSender.lastEmail)
	}
}

func TestStartPasswordResetDoesNotRevealMissingIdentifier(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	otpStore := &spyOTPStore{}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, &stubNicknameResolver{})

	err := uc.StartPasswordReset(context.Background(), "missing_nickname", model.DeviceInfo{})

	if err != nil {
		t.Fatalf("StartPasswordReset() error = %v, want nil for non-enumerating response", err)
	}
	if otpStore.lastStoreDestination != "" {
		t.Fatalf("OTP destination = %q, want empty for missing account", otpStore.lastStoreDestination)
	}
	if emailSender.lastEmail != "" {
		t.Fatalf("email sender destination = %q, want empty for missing account", emailSender.lastEmail)
	}
}

func TestVerifyPasswordResetUpdatesPasswordAndAllowsLogin(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	userRepo.byEmail["traveler@example.com"] = userRepo.byID[userID]
	otpStore := &spyOTPStore{verifyResult: true}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, &spyEmailOTPSender{}, nil)

	err := uc.VerifyPasswordReset(
		context.Background(),
		"TRAVELER@example.com",
		"123456",
		"newTravel42Pass",
		model.DeviceInfo{},
	)

	if err != nil {
		t.Fatalf("VerifyPasswordReset() error = %v", err)
	}
	if otpStore.lastVerifyDestination != "password_reset:traveler@example.com" {
		t.Fatalf("OTP verify destination = %q, want password_reset:traveler@example.com", otpStore.lastVerifyDestination)
	}
	if _, err := uc.PasswordLogin(context.Background(), "traveler@example.com", "travel42Pass", model.DeviceInfo{}); !errors.Is(err, model.ErrInvalidCredentials) {
		t.Fatalf("PasswordLogin() with old password error = %v, want %v", err, model.ErrInvalidCredentials)
	}
	if result, err := uc.PasswordLogin(context.Background(), "traveler@example.com", "newTravel42Pass", model.DeviceInfo{}); err != nil || result == nil {
		t.Fatalf("PasswordLogin() with new password result=%#v error=%v, want success", result, err)
	}
}

func TestVerifyPasswordResetMarksPendingEmailVerified(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: false,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	userRepo.byEmail["traveler@example.com"] = userRepo.byID[userID]
	otpStore := &spyOTPStore{verifyResult: true}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, &spyEmailOTPSender{}, nil)

	err := uc.VerifyPasswordReset(
		context.Background(),
		"traveler@example.com",
		"123456",
		"newTravel42Pass",
		model.DeviceInfo{},
	)

	if err != nil {
		t.Fatalf("VerifyPasswordReset() error = %v", err)
	}
	if !userRepo.byID[userID].EmailVerified {
		t.Fatal("VerifyPasswordReset() did not mark pending email as verified")
	}
	if result, err := uc.PasswordLogin(context.Background(), "traveler@example.com", "newTravel42Pass", model.DeviceInfo{}); err != nil || result == nil {
		t.Fatalf("PasswordLogin() after reset result=%#v error=%v, want success", result, err)
	}
}

func TestStartPasswordResetAcceptsNicknameIdentifierViaResolver(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	resolver := &stubNicknameResolver{
		users: map[string]uuid.UUID{"nomad_aru": userID},
	}
	otpStore := &spyOTPStore{}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, resolver)

	err := uc.StartPasswordReset(context.Background(), "Nomad_Aru", model.DeviceInfo{})

	if err != nil {
		t.Fatalf("StartPasswordReset() error = %v", err)
	}
	if otpStore.lastStoreDestination != "password_reset:traveler@example.com" {
		t.Fatalf("OTP destination = %q, want password_reset:traveler@example.com", otpStore.lastStoreDestination)
	}
	if emailSender.lastEmail != "traveler@example.com" {
		t.Fatalf("email sender destination = %q, want traveler@example.com", emailSender.lastEmail)
	}
}

func TestVerifyPasswordResetAcceptsNicknameIdentifierViaResolver(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	resolver := &stubNicknameResolver{
		users: map[string]uuid.UUID{"nomad_aru": userID},
	}
	otpStore := &spyOTPStore{verifyResult: true}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, &spyEmailOTPSender{}, resolver)

	err := uc.VerifyPasswordReset(
		context.Background(),
		"Nomad_Aru",
		"123456",
		"newTravel42Pass",
		model.DeviceInfo{},
	)

	if err != nil {
		t.Fatalf("VerifyPasswordReset() error = %v", err)
	}
	if otpStore.lastVerifyDestination != "password_reset:traveler@example.com" {
		t.Fatalf("OTP verify destination = %q, want password_reset:traveler@example.com", otpStore.lastVerifyDestination)
	}
	if _, err := uc.PasswordLogin(context.Background(), "nomad_aru", "travel42Pass", model.DeviceInfo{}); !errors.Is(err, model.ErrInvalidCredentials) {
		t.Fatalf("PasswordLogin() with old password error = %v, want %v", err, model.ErrInvalidCredentials)
	}
	if result, err := uc.PasswordLogin(context.Background(), "nomad_aru", "newTravel42Pass", model.DeviceInfo{}); err != nil || result == nil {
		t.Fatalf("PasswordLogin() with new password result=%#v error=%v, want success", result, err)
	}
}

func TestStartPasswordChangeSendsOTPAfterCurrentPasswordCheck(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	userRepo.byEmail["traveler@example.com"] = userRepo.byID[userID]
	otpStore := &spyOTPStore{}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)
	uc.tokenClient = stubTokenClient{
		accessClaims: &port.TokenClaims{Subject: userID.String(), Role: string(model.RoleTourist)},
	}

	err := uc.StartPasswordChange(context.Background(), "access-token", "travel42Pass", model.DeviceInfo{})

	if err != nil {
		t.Fatalf("StartPasswordChange() error = %v", err)
	}
	wantDestination := "password_change:" + userID.String()
	if otpStore.lastRateLimitDestination != wantDestination {
		t.Fatalf("rate limit destination = %q, want %q", otpStore.lastRateLimitDestination, wantDestination)
	}
	if otpStore.lastStoreDestination != wantDestination {
		t.Fatalf("OTP destination = %q, want %q", otpStore.lastStoreDestination, wantDestination)
	}
	if emailSender.lastEmail != "traveler@example.com" {
		t.Fatalf("email sender destination = %q, want traveler@example.com", emailSender.lastEmail)
	}
}

func TestStartPasswordChangeRejectsWrongCurrentPassword(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	otpStore := &spyOTPStore{}
	emailSender := &spyEmailOTPSender{}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, emailSender, nil)
	uc.tokenClient = stubTokenClient{
		accessClaims: &port.TokenClaims{Subject: userID.String(), Role: string(model.RoleTourist)},
	}

	err := uc.StartPasswordChange(context.Background(), "access-token", "wrongTravel42Pass", model.DeviceInfo{})

	if !errors.Is(err, model.ErrInvalidCredentials) {
		t.Fatalf("StartPasswordChange() error = %v, want %v", err, model.ErrInvalidCredentials)
	}
	if otpStore.lastStoreDestination != "" {
		t.Fatalf("OTP destination = %q, want empty for wrong current password", otpStore.lastStoreDestination)
	}
	if emailSender.lastEmail != "" {
		t.Fatalf("email sender destination = %q, want empty for wrong current password", emailSender.lastEmail)
	}
}

func TestVerifyPasswordChangeUpdatesPasswordAfterOTP(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	userRepo.byEmail["traveler@example.com"] = userRepo.byID[userID]
	otpStore := &spyOTPStore{verifyResult: true}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, &spyEmailOTPSender{}, nil)
	uc.tokenClient = stubTokenClient{
		accessClaims: &port.TokenClaims{Subject: userID.String(), Role: string(model.RoleTourist)},
	}

	err := uc.VerifyPasswordChange(
		context.Background(),
		"access-token",
		"travel42Pass",
		"123456",
		"newTravel42Pass",
		model.DeviceInfo{},
	)

	if err != nil {
		t.Fatalf("VerifyPasswordChange() error = %v", err)
	}
	wantDestination := "password_change:" + userID.String()
	if otpStore.lastVerifyDestination != wantDestination {
		t.Fatalf("OTP verify destination = %q, want %q", otpStore.lastVerifyDestination, wantDestination)
	}
	if _, err := uc.PasswordLogin(context.Background(), "traveler@example.com", "travel42Pass", model.DeviceInfo{}); !errors.Is(err, model.ErrInvalidCredentials) {
		t.Fatalf("PasswordLogin() with old password error = %v, want %v", err, model.ErrInvalidCredentials)
	}
	if result, err := uc.PasswordLogin(context.Background(), "traveler@example.com", "newTravel42Pass", model.DeviceInfo{}); err != nil || result == nil {
		t.Fatalf("PasswordLogin() with new password result=%#v error=%v, want success", result, err)
	}
}

func TestVerifyPasswordChangeRejectsReusedPassword(t *testing.T) {
	userRepo := newInMemoryUserRepository()
	userID := uuid.New()
	userRepo.byID[userID] = &model.AuthUser{
		ID:            userID,
		Email:         strPtr("traveler@example.com"),
		PasswordHash:  mustPasswordHash(t, "travel42Pass"),
		EmailVerified: true,
		Role:          model.RoleTourist,
		IsActive:      true,
	}
	otpStore := &spyOTPStore{verifyResult: true}
	uc := newTestEmailAuthUseCase(userRepo, otpStore, &spyEmailOTPSender{}, nil)
	uc.tokenClient = stubTokenClient{
		accessClaims: &port.TokenClaims{Subject: userID.String(), Role: string(model.RoleTourist)},
	}

	err := uc.VerifyPasswordChange(
		context.Background(),
		"access-token",
		"travel42Pass",
		"123456",
		"travel42Pass",
		model.DeviceInfo{},
	)

	if !errors.Is(err, model.ErrPasswordUnchanged) {
		t.Fatalf("VerifyPasswordChange() error = %v, want %v", err, model.ErrPasswordUnchanged)
	}
	if otpStore.verifyCalls != 0 {
		t.Fatalf("OTP store was called %d times, want 0 for reused password", otpStore.verifyCalls)
	}
}
