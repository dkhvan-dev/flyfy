package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
)

func TestPhoneVerificationStartsPendingChallenge(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := newPhoneVerificationTestRepo(userID)
	sender := &phoneVerificationTestSender{}
	uc := NewPhoneVerificationUseCase(repo, sender, PhoneVerificationConfig{
		CodeLength:            6,
		CodeTTL:               5 * time.Minute,
		ResendCooldown:        time.Minute,
		MaxVerifyAttempts:     5,
		CodeHashSecret:        "test-secret",
		DevelopmentStaticCode: "123456",
	})

	result, err := uc.Start(ctx, "auth-subject-1", "+7 (777) 123-45-67")
	if err != nil {
		t.Fatalf("Start() error = %v", err)
	}

	if result.ChallengeID == uuid.Nil {
		t.Fatal("Start() returned nil challenge id")
	}
	if result.MaskedPhone != "+7 *** *** 45 67" {
		t.Fatalf("masked phone = %q", result.MaskedPhone)
	}
	if result.ResendAfterSeconds != 60 {
		t.Fatalf("resend cooldown = %d", result.ResendAfterSeconds)
	}
	if sender.lastPhone != "+77771234567" {
		t.Fatalf("sender phone = %q", sender.lastPhone)
	}
	if sender.lastCode != "123456" {
		t.Fatalf("sender code = %q", sender.lastCode)
	}
	if repo.pendingPhone != "+77771234567" {
		t.Fatalf("pending phone = %q", repo.pendingPhone)
	}
}

func TestPhoneVerificationRejectsDuplicateVerifiedPhone(t *testing.T) {
	ctx := context.Background()
	repo := newPhoneVerificationTestRepo(uuid.New())
	repo.verifiedPhones["+77771234567"] = uuid.New()
	uc := NewPhoneVerificationUseCase(repo, &phoneVerificationTestSender{}, PhoneVerificationConfig{
		CodeLength:     6,
		CodeTTL:        5 * time.Minute,
		CodeHashSecret: "test-secret",
	})

	_, err := uc.Start(ctx, "auth-subject-1", "+7 777 123 45 67")
	if !errors.Is(err, ErrPhoneAlreadyTaken) {
		t.Fatalf("Start() error = %v, want ErrPhoneAlreadyTaken", err)
	}
}

func TestPhoneVerificationRejectsAlreadyVerifiedOwnPhone(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := newPhoneVerificationTestRepo(userID)
	verifiedAt := time.Now().UTC()
	verifiedPhone := "+77771234567"
	repo.user.PrimaryPhone = &verifiedPhone
	repo.user.PrimaryPhoneVerifiedAt = &verifiedAt
	sender := &phoneVerificationTestSender{}
	uc := NewPhoneVerificationUseCase(repo, sender, PhoneVerificationConfig{
		CodeLength:            6,
		CodeTTL:               5 * time.Minute,
		CodeHashSecret:        "test-secret",
		DevelopmentStaticCode: "123456",
	})

	_, err := uc.Start(ctx, "auth-subject-1", "+7 (777) 123-45-67")
	if !errors.Is(err, ErrPhoneAlreadyVerified) {
		t.Fatalf("Start() error = %v, want ErrPhoneAlreadyVerified", err)
	}
	if sender.lastPhone != "" {
		t.Fatalf("sender was called for already verified phone: %q", sender.lastPhone)
	}
	if repo.pendingPhone != "" {
		t.Fatalf("pending phone was created: %q", repo.pendingPhone)
	}
	if len(repo.challenges) != 0 {
		t.Fatalf("challenge count = %d, want 0", len(repo.challenges))
	}
}

func TestPhoneVerificationVerifiesChallengeAndPromotesPhone(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	repo := newPhoneVerificationTestRepo(userID)
	uc := NewPhoneVerificationUseCase(repo, &phoneVerificationTestSender{}, PhoneVerificationConfig{
		CodeLength:            6,
		CodeTTL:               5 * time.Minute,
		ResendCooldown:        time.Minute,
		MaxVerifyAttempts:     5,
		CodeHashSecret:        "test-secret",
		DevelopmentStaticCode: "123456",
	})

	result, err := uc.Start(ctx, "auth-subject-1", "+7 777 123 45 67")
	if err != nil {
		t.Fatalf("Start() error = %v", err)
	}

	state, err := uc.Verify(ctx, "auth-subject-1", result.ChallengeID, "123456")
	if err != nil {
		t.Fatalf("Verify() error = %v", err)
	}

	if !state.Verified {
		t.Fatal("Verify() returned unverified state")
	}
	if state.MaskedPhone != "+7 *** *** 45 67" {
		t.Fatalf("masked phone = %q", state.MaskedPhone)
	}
	if repo.user.PrimaryPhone == nil || *repo.user.PrimaryPhone != "+77771234567" {
		t.Fatalf("primary phone = %v", repo.user.PrimaryPhone)
	}
	if repo.user.PrimaryPhoneVerifiedAt == nil {
		t.Fatal("verified timestamp was not set")
	}
	if repo.pendingPhone != "" {
		t.Fatalf("pending phone still set: %q", repo.pendingPhone)
	}
}

func TestPhoneVerificationLocksChallengeAfterTooManyAttempts(t *testing.T) {
	ctx := context.Background()
	repo := newPhoneVerificationTestRepo(uuid.New())
	uc := NewPhoneVerificationUseCase(repo, &phoneVerificationTestSender{}, PhoneVerificationConfig{
		CodeLength:            6,
		CodeTTL:               5 * time.Minute,
		MaxVerifyAttempts:     2,
		CodeHashSecret:        "test-secret",
		DevelopmentStaticCode: "123456",
	})

	result, err := uc.Start(ctx, "auth-subject-1", "+7 777 123 45 67")
	if err != nil {
		t.Fatalf("Start() error = %v", err)
	}

	for i := 0; i < 2; i++ {
		_, err = uc.Verify(ctx, "auth-subject-1", result.ChallengeID, "000000")
		if !errors.Is(err, ErrInvalidPhoneVerificationCode) {
			t.Fatalf("Verify() attempt %d error = %v", i+1, err)
		}
	}

	_, err = uc.Verify(ctx, "auth-subject-1", result.ChallengeID, "123456")
	if !errors.Is(err, ErrPhoneVerificationLocked) {
		t.Fatalf("Verify() after lock error = %v", err)
	}
}

type phoneVerificationTestSender struct {
	lastPhone string
	lastCode  string
}

func (s *phoneVerificationTestSender) SendPhoneVerificationCode(
	ctx context.Context,
	phone string,
	code string,
) error {
	s.lastPhone = phone
	s.lastCode = code
	return nil
}

type phoneVerificationTestRepo struct {
	user           *model.User
	pendingPhone   string
	verifiedPhones map[string]uuid.UUID
	challenges     map[uuid.UUID]*PhoneVerificationChallenge
}

func newPhoneVerificationTestRepo(userID uuid.UUID) *phoneVerificationTestRepo {
	return &phoneVerificationTestRepo{
		user: &model.User{
			ID:            userID,
			AuthSubjectID: "auth-subject-1",
			Status:        enum.UserStatusActive,
		},
		verifiedPhones: map[string]uuid.UUID{},
		challenges:     map[uuid.UUID]*PhoneVerificationChallenge{},
	}
}

func (r *phoneVerificationTestRepo) GetPhoneVerificationUserBySubject(
	ctx context.Context,
	subjectID string,
) (*model.User, error) {
	if subjectID != r.user.AuthSubjectID {
		return nil, ErrUserNotFound
	}
	return r.user, nil
}

func (r *phoneVerificationTestRepo) IsVerifiedPhoneTaken(
	ctx context.Context,
	phone string,
	excludeUserID uuid.UUID,
) (bool, error) {
	userID, ok := r.verifiedPhones[phone]
	return ok && userID != excludeUserID, nil
}

func (r *phoneVerificationTestRepo) CreatePhoneVerificationChallenge(
	ctx context.Context,
	challenge *PhoneVerificationChallenge,
) error {
	r.pendingPhone = challenge.PhoneE164
	copied := *challenge
	r.challenges[challenge.ID] = &copied
	return nil
}

func (r *phoneVerificationTestRepo) GetPhoneVerificationChallenge(
	ctx context.Context,
	userID uuid.UUID,
	challengeID uuid.UUID,
) (*PhoneVerificationChallenge, error) {
	challenge := r.challenges[challengeID]
	if challenge == nil || challenge.UserID != userID {
		return nil, ErrPhoneVerificationNotFound
	}
	copied := *challenge
	return &copied, nil
}

func (r *phoneVerificationTestRepo) RecordPhoneVerificationFailedAttempt(
	ctx context.Context,
	challengeID uuid.UUID,
	locked bool,
) error {
	challenge := r.challenges[challengeID]
	if challenge == nil {
		return ErrPhoneVerificationNotFound
	}
	challenge.AttemptCount++
	if locked {
		challenge.Status = PhoneVerificationStatusLocked
	}
	return nil
}

func (r *phoneVerificationTestRepo) UpdatePhoneVerificationChallengeCode(
	ctx context.Context,
	challenge *PhoneVerificationChallenge,
) error {
	if challenge == nil {
		return ErrPhoneVerificationNotFound
	}
	copied := *challenge
	r.challenges[challenge.ID] = &copied
	return nil
}

func (r *phoneVerificationTestRepo) ConfirmPhoneVerificationChallenge(
	ctx context.Context,
	userID uuid.UUID,
	challengeID uuid.UUID,
) (*model.User, error) {
	challenge := r.challenges[challengeID]
	if challenge == nil || challenge.UserID != userID {
		return nil, ErrPhoneVerificationNotFound
	}
	now := time.Now().UTC()
	r.user.PrimaryPhone = &challenge.PhoneE164
	r.user.PrimaryPhoneVerifiedAt = &now
	r.pendingPhone = ""
	challenge.Status = PhoneVerificationStatusVerified
	challenge.VerifiedAt = &now
	return r.user, nil
}

func (r *phoneVerificationTestRepo) CancelPendingPhoneVerification(
	ctx context.Context,
	userID uuid.UUID,
) error {
	if userID != r.user.ID {
		return ErrUserNotFound
	}
	r.pendingPhone = ""
	return nil
}
