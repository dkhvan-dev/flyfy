package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/auth-service/internal/domain/model"
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
