package app

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/model"
)

var (
	ErrPhoneRequired                = errors.New("phone number is required")
	ErrPhoneInvalid                 = errors.New("phone number is invalid")
	ErrPhoneAlreadyTaken            = errors.New("phone number is unavailable")
	ErrPhoneAlreadyVerified         = errors.New("phone number is already verified for this account")
	ErrPhoneVerificationNotFound    = errors.New("phone verification challenge not found")
	ErrPhoneVerificationExpired     = errors.New("phone verification challenge has expired")
	ErrInvalidPhoneVerificationCode = errors.New("invalid phone verification code")
	ErrPhoneVerificationLocked      = errors.New("phone verification challenge is locked")
	ErrPhoneVerificationRateLimited = errors.New("phone verification rate limit exceeded")
	ErrPhoneVerificationUnavailable = errors.New("phone verification is temporarily unavailable")
)

type PhoneVerificationStatus string

const (
	PhoneVerificationStatusPending   PhoneVerificationStatus = "PENDING"
	PhoneVerificationStatusVerified  PhoneVerificationStatus = "VERIFIED"
	PhoneVerificationStatusExpired   PhoneVerificationStatus = "EXPIRED"
	PhoneVerificationStatusLocked    PhoneVerificationStatus = "LOCKED"
	PhoneVerificationStatusCancelled PhoneVerificationStatus = "CANCELLED"
)

type PhoneVerificationConfig struct {
	CodeLength            int
	CodeTTL               time.Duration
	ResendCooldown        time.Duration
	MaxVerifyAttempts     int
	CodeHashSecret        string
	DevelopmentStaticCode string
}

type PhoneVerificationChallenge struct {
	ID           uuid.UUID
	UserID       uuid.UUID
	PhoneE164    string
	CodeHash     string
	Status       PhoneVerificationStatus
	AttemptCount int
	ResendCount  int
	LastSentAt   time.Time
	ExpiresAt    time.Time
	CreatedAt    time.Time
	VerifiedAt   *time.Time
}

type PhoneVerificationStartResult struct {
	ChallengeID        uuid.UUID
	MaskedPhone        string
	ResendAfterSeconds int
	ExpiresAt          time.Time
}

type PhoneVerificationState struct {
	Verified    bool
	MaskedPhone string
	VerifiedAt  *time.Time
}

type PhoneVerificationRepository interface {
	GetPhoneVerificationUserBySubject(ctx context.Context, subjectID string) (*model.User, error)
	IsVerifiedPhoneTaken(ctx context.Context, phone string, excludeUserID uuid.UUID) (bool, error)
	CreatePhoneVerificationChallenge(ctx context.Context, challenge *PhoneVerificationChallenge) error
	GetPhoneVerificationChallenge(ctx context.Context, userID uuid.UUID, challengeID uuid.UUID) (*PhoneVerificationChallenge, error)
	UpdatePhoneVerificationChallengeCode(ctx context.Context, challenge *PhoneVerificationChallenge) error
	RecordPhoneVerificationFailedAttempt(ctx context.Context, challengeID uuid.UUID, locked bool) error
	ConfirmPhoneVerificationChallenge(ctx context.Context, userID uuid.UUID, challengeID uuid.UUID) (*model.User, error)
	CancelPendingPhoneVerification(ctx context.Context, userID uuid.UUID) error
}

type PhoneVerificationSender interface {
	SendPhoneVerificationCode(ctx context.Context, phone string, code string) error
}

type PhoneVerificationUseCase struct {
	repo   PhoneVerificationRepository
	sender PhoneVerificationSender
	cfg    PhoneVerificationConfig
	now    func() time.Time
}

func NewPhoneVerificationUseCase(
	repo PhoneVerificationRepository,
	sender PhoneVerificationSender,
	cfg PhoneVerificationConfig,
) *PhoneVerificationUseCase {
	cfg = normalizePhoneVerificationConfig(cfg)
	return &PhoneVerificationUseCase{
		repo:   repo,
		sender: sender,
		cfg:    cfg,
		now:    func() time.Time { return time.Now().UTC() },
	}
}

func (u *PhoneVerificationUseCase) Start(
	ctx context.Context,
	subjectID string,
	phone string,
) (*PhoneVerificationStartResult, error) {
	if u == nil || u.repo == nil || u.sender == nil {
		return nil, ErrPhoneVerificationUnavailable
	}

	subjectID = strings.TrimSpace(subjectID)
	if subjectID == "" {
		return nil, ErrInvalidSubjectID
	}

	phone, err := normalizePhoneE164(phone)
	if err != nil {
		return nil, err
	}

	user, err := u.repo.GetPhoneVerificationUserBySubject(ctx, subjectID)
	if err != nil {
		return nil, err
	}
	if user == nil || user.IsDeleted {
		return nil, ErrUserNotFound
	}
	if userAlreadyHasVerifiedPhone(user, phone) {
		return nil, ErrPhoneAlreadyVerified
	}

	taken, err := u.repo.IsVerifiedPhoneTaken(ctx, phone, user.ID)
	if err != nil {
		return nil, fmt.Errorf("check verified phone uniqueness: %w", err)
	}
	if taken {
		return nil, ErrPhoneAlreadyTaken
	}

	code, err := u.generateCode()
	if err != nil {
		return nil, fmt.Errorf("generate phone verification code: %w", err)
	}

	now := u.now()
	challenge := &PhoneVerificationChallenge{
		ID:         uuid.New(),
		UserID:     user.ID,
		PhoneE164:  phone,
		CodeHash:   u.hashCode(user.ID, phone, code),
		Status:     PhoneVerificationStatusPending,
		LastSentAt: now,
		ExpiresAt:  now.Add(u.cfg.CodeTTL),
		CreatedAt:  now,
	}

	if err = u.repo.CreatePhoneVerificationChallenge(ctx, challenge); err != nil {
		return nil, fmt.Errorf("create phone verification challenge: %w", err)
	}

	if err = u.sender.SendPhoneVerificationCode(ctx, phone, code); err != nil {
		return nil, fmt.Errorf("send phone verification code: %w", err)
	}

	return &PhoneVerificationStartResult{
		ChallengeID:        challenge.ID,
		MaskedPhone:        MaskPhoneForDisplay(phone),
		ResendAfterSeconds: int(u.cfg.ResendCooldown.Seconds()),
		ExpiresAt:          challenge.ExpiresAt,
	}, nil
}

func (u *PhoneVerificationUseCase) Verify(
	ctx context.Context,
	subjectID string,
	challengeID uuid.UUID,
	code string,
) (*PhoneVerificationState, error) {
	if u == nil || u.repo == nil {
		return nil, ErrPhoneVerificationUnavailable
	}
	if challengeID == uuid.Nil {
		return nil, ErrPhoneVerificationNotFound
	}

	subjectID = strings.TrimSpace(subjectID)
	if subjectID == "" {
		return nil, ErrInvalidSubjectID
	}

	user, err := u.repo.GetPhoneVerificationUserBySubject(ctx, subjectID)
	if err != nil {
		return nil, err
	}
	if user == nil || user.IsDeleted {
		return nil, ErrUserNotFound
	}

	challenge, err := u.repo.GetPhoneVerificationChallenge(ctx, user.ID, challengeID)
	if err != nil {
		return nil, err
	}
	if challenge == nil {
		return nil, ErrPhoneVerificationNotFound
	}

	switch challenge.Status {
	case PhoneVerificationStatusVerified:
		return phoneVerificationStateFromUser(user), nil
	case PhoneVerificationStatusLocked:
		return nil, ErrPhoneVerificationLocked
	case PhoneVerificationStatusExpired:
		return nil, ErrPhoneVerificationExpired
	case PhoneVerificationStatusPending, "":
	default:
		return nil, ErrPhoneVerificationNotFound
	}

	if !challenge.ExpiresAt.IsZero() && !u.now().Before(challenge.ExpiresAt) {
		return nil, ErrPhoneVerificationExpired
	}

	code = strings.TrimSpace(code)
	expected := u.hashCode(user.ID, challenge.PhoneE164, code)
	if subtle.ConstantTimeCompare([]byte(expected), []byte(challenge.CodeHash)) != 1 {
		nextAttemptCount := challenge.AttemptCount + 1
		locked := nextAttemptCount > u.cfg.MaxVerifyAttempts
		if nextAttemptCount == u.cfg.MaxVerifyAttempts {
			locked = true
		}
		if err = u.repo.RecordPhoneVerificationFailedAttempt(ctx, challenge.ID, locked); err != nil {
			return nil, fmt.Errorf("record phone verification attempt: %w", err)
		}
		return nil, ErrInvalidPhoneVerificationCode
	}

	updatedUser, err := u.repo.ConfirmPhoneVerificationChallenge(ctx, user.ID, challenge.ID)
	if err != nil {
		return nil, err
	}
	return phoneVerificationStateFromUser(updatedUser), nil
}

func (u *PhoneVerificationUseCase) Resend(
	ctx context.Context,
	subjectID string,
	challengeID uuid.UUID,
) (*PhoneVerificationStartResult, error) {
	if u == nil || u.repo == nil || u.sender == nil {
		return nil, ErrPhoneVerificationUnavailable
	}

	user, challenge, err := u.pendingChallengeForSubject(ctx, subjectID, challengeID)
	if err != nil {
		return nil, err
	}

	now := u.now()
	if now.Before(challenge.LastSentAt.Add(u.cfg.ResendCooldown)) {
		return nil, ErrPhoneVerificationRateLimited
	}

	code, err := u.generateCode()
	if err != nil {
		return nil, fmt.Errorf("generate phone verification resend code: %w", err)
	}

	challenge.CodeHash = u.hashCode(user.ID, challenge.PhoneE164, code)
	challenge.ResendCount++
	challenge.LastSentAt = now
	challenge.ExpiresAt = now.Add(u.cfg.CodeTTL)

	if err = u.repo.UpdatePhoneVerificationChallengeCode(ctx, challenge); err != nil {
		return nil, fmt.Errorf("update phone verification challenge: %w", err)
	}
	if err = u.sender.SendPhoneVerificationCode(ctx, challenge.PhoneE164, code); err != nil {
		return nil, fmt.Errorf("send phone verification code: %w", err)
	}

	return &PhoneVerificationStartResult{
		ChallengeID:        challenge.ID,
		MaskedPhone:        MaskPhoneForDisplay(challenge.PhoneE164),
		ResendAfterSeconds: int(u.cfg.ResendCooldown.Seconds()),
		ExpiresAt:          challenge.ExpiresAt,
	}, nil
}

func (u *PhoneVerificationUseCase) Cancel(ctx context.Context, subjectID string) error {
	if u == nil || u.repo == nil {
		return ErrPhoneVerificationUnavailable
	}

	subjectID = strings.TrimSpace(subjectID)
	if subjectID == "" {
		return ErrInvalidSubjectID
	}

	user, err := u.repo.GetPhoneVerificationUserBySubject(ctx, subjectID)
	if err != nil {
		return err
	}
	if user == nil || user.IsDeleted {
		return ErrUserNotFound
	}
	return u.repo.CancelPendingPhoneVerification(ctx, user.ID)
}

func (u *PhoneVerificationUseCase) pendingChallengeForSubject(
	ctx context.Context,
	subjectID string,
	challengeID uuid.UUID,
) (*model.User, *PhoneVerificationChallenge, error) {
	if challengeID == uuid.Nil {
		return nil, nil, ErrPhoneVerificationNotFound
	}

	subjectID = strings.TrimSpace(subjectID)
	if subjectID == "" {
		return nil, nil, ErrInvalidSubjectID
	}

	user, err := u.repo.GetPhoneVerificationUserBySubject(ctx, subjectID)
	if err != nil {
		return nil, nil, err
	}
	if user == nil || user.IsDeleted {
		return nil, nil, ErrUserNotFound
	}

	challenge, err := u.repo.GetPhoneVerificationChallenge(ctx, user.ID, challengeID)
	if err != nil {
		return nil, nil, err
	}
	if challenge == nil {
		return nil, nil, ErrPhoneVerificationNotFound
	}
	if challenge.Status == PhoneVerificationStatusLocked {
		return nil, nil, ErrPhoneVerificationLocked
	}
	if challenge.Status != "" && challenge.Status != PhoneVerificationStatusPending {
		return nil, nil, ErrPhoneVerificationNotFound
	}
	if !challenge.ExpiresAt.IsZero() && !u.now().Before(challenge.ExpiresAt) {
		return nil, nil, ErrPhoneVerificationExpired
	}

	return user, challenge, nil
}

func userAlreadyHasVerifiedPhone(user *model.User, phone string) bool {
	if user == nil || user.PrimaryPhone == nil || user.PrimaryPhoneVerifiedAt == nil {
		return false
	}

	currentPhone, err := normalizePhoneE164(*user.PrimaryPhone)
	if err != nil {
		return false
	}
	return currentPhone == phone
}

func normalizePhoneVerificationConfig(cfg PhoneVerificationConfig) PhoneVerificationConfig {
	if cfg.CodeLength <= 0 {
		cfg.CodeLength = 6
	}
	if cfg.CodeLength > 10 {
		cfg.CodeLength = 10
	}
	if cfg.CodeTTL <= 0 {
		cfg.CodeTTL = 5 * time.Minute
	}
	if cfg.ResendCooldown <= 0 {
		cfg.ResendCooldown = time.Minute
	}
	if cfg.MaxVerifyAttempts <= 0 {
		cfg.MaxVerifyAttempts = 5
	}
	cfg.CodeHashSecret = strings.TrimSpace(cfg.CodeHashSecret)
	if cfg.CodeHashSecret == "" {
		cfg.CodeHashSecret = "development-phone-verification-secret"
	}
	cfg.DevelopmentStaticCode = strings.TrimSpace(cfg.DevelopmentStaticCode)
	return cfg
}

func (u *PhoneVerificationUseCase) generateCode() (string, error) {
	if u.cfg.DevelopmentStaticCode != "" {
		return u.cfg.DevelopmentStaticCode, nil
	}

	var builder strings.Builder
	builder.Grow(u.cfg.CodeLength)
	for i := 0; i < u.cfg.CodeLength; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			return "", err
		}
		builder.WriteByte(byte('0' + n.Int64()))
	}
	return builder.String(), nil
}

func (u *PhoneVerificationUseCase) hashCode(userID uuid.UUID, phone string, code string) string {
	mac := hmac.New(sha256.New, []byte(u.cfg.CodeHashSecret))
	mac.Write([]byte(userID.String()))
	mac.Write([]byte{0})
	mac.Write([]byte(phone))
	mac.Write([]byte{0})
	mac.Write([]byte(strings.TrimSpace(code)))
	return hex.EncodeToString(mac.Sum(nil))
}

func normalizePhoneE164(phone string) (string, error) {
	phone = strings.TrimSpace(phone)
	if phone == "" {
		return "", ErrPhoneRequired
	}

	var builder strings.Builder
	for i, r := range phone {
		switch {
		case r == '+' && i == 0:
			builder.WriteRune(r)
		case unicode.IsDigit(r):
			builder.WriteRune(r)
		case unicode.IsSpace(r) || r == '-' || r == '(' || r == ')':
			continue
		default:
			return "", ErrPhoneInvalid
		}
	}

	normalized := builder.String()
	if strings.HasPrefix(normalized, "00") {
		normalized = "+" + strings.TrimPrefix(normalized, "00")
	}
	if !strings.HasPrefix(normalized, "+") {
		return "", ErrPhoneInvalid
	}

	digitCount := 0
	for _, r := range normalized[1:] {
		if !unicode.IsDigit(r) {
			return "", ErrPhoneInvalid
		}
		digitCount++
	}
	if digitCount < 8 || digitCount > 15 {
		return "", ErrPhoneInvalid
	}
	return normalized, nil
}

func MaskPhoneForDisplay(phone string) string {
	phone, err := normalizePhoneE164(phone)
	if err != nil {
		return ""
	}
	digits := strings.TrimPrefix(phone, "+")
	if len(digits) == 11 && strings.HasPrefix(digits, "7") {
		return fmt.Sprintf("+7 *** *** %s %s", digits[7:9], digits[9:11])
	}
	if len(digits) <= 4 {
		return "+" + digits
	}
	last := digits[len(digits)-4:]
	return fmt.Sprintf("+%s *** ** %s", digits[:1], last)
}

func phoneVerificationStateFromUser(user *model.User) *PhoneVerificationState {
	if user == nil || user.PrimaryPhone == nil || strings.TrimSpace(*user.PrimaryPhone) == "" {
		return &PhoneVerificationState{}
	}
	return &PhoneVerificationState{
		Verified:    user.PrimaryPhoneVerifiedAt != nil,
		MaskedPhone: MaskPhoneForDisplay(*user.PrimaryPhone),
		VerifiedAt:  user.PrimaryPhoneVerifiedAt,
	}
}
