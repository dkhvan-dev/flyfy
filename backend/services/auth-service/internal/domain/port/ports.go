package port

import (
	"context"

	"github.com/google/uuid"

	"kz/inflap/backend/services/auth-service/internal/domain/model"
)

// --- Primary Ports (driven by incoming requests) ---

// Authenticator is the main use-case port for authentication flows.
// All login/refresh methods take DeviceInfo so the new session can record device
// metadata; pass an empty struct if the caller doesn't have it.
type Authenticator interface {
	// SendOTP sends an OTP code to the given phone number.
	SendOTP(ctx context.Context, phone string, device model.DeviceInfo) error

	// VerifyOTPAndLogin verifies the OTP code and returns tokens.
	VerifyOTPAndLogin(ctx context.Context, phone, code string, device model.DeviceInfo) (*model.AuthResult, error)

	// StartEmailRegistration sends an OTP for email/password registration.
	StartEmailRegistration(ctx context.Context, email, password string, device model.DeviceInfo) error

	// VerifyEmailRegistration verifies an email OTP and returns tokens.
	VerifyEmailRegistration(ctx context.Context, email, code string, device model.DeviceInfo) (*model.AuthResult, error)

	// PasswordLogin authenticates by email or nickname and password.
	PasswordLogin(ctx context.Context, identifier, password string, device model.DeviceInfo) (*model.AuthResult, error)

	// GoogleLogin authenticates a user via Google ID Token.
	GoogleLogin(ctx context.Context, idToken string, device model.DeviceInfo) (*model.AuthResult, error)

	// AppleLogin authenticates a user via Apple ID Token.
	AppleLogin(ctx context.Context, idToken string, device model.DeviceInfo) (*model.AuthResult, error)

	// RefreshTokens issues a new token pair using a refresh token.
	RefreshTokens(ctx context.Context, refreshToken string, device model.DeviceInfo) (*model.AuthResult, error)

	// Logout revokes the session associated with the supplied tokens.
	Logout(ctx context.Context, accessToken, refreshToken string) error
}

// --- Secondary Ports (driven by the application) ---

// UserRepository manages auth users in the database.
type UserRepository interface {
	// FindByPhone returns a user by phone number.
	FindByPhone(ctx context.Context, phone string) (*model.AuthUser, error)

	// FindByEmail returns a user by normalized email.
	FindByEmail(ctx context.Context, email string) (*model.AuthUser, error)

	// FindByID returns a user by auth/user id.
	FindByID(ctx context.Context, userID uuid.UUID) (*model.AuthUser, error)

	// FindByProvider returns a user by OAuth provider + provider ID.
	FindByProvider(ctx context.Context, provider model.AuthProvider, providerID string) (*model.AuthUser, error)

	// Create creates a new user and returns it.
	Create(ctx context.Context, user *model.AuthUser) error

	// LinkProvider links an OAuth provider to an existing user.
	LinkProvider(ctx context.Context, link *model.AuthProviderLink) error

	// UpdateEmailVerification marks a user's email as verified or unverified.
	UpdateEmailVerification(ctx context.Context, userID uuid.UUID, verified bool) error

	// UpdatePasswordHash replaces the password hash for an existing auth user.
	UpdatePasswordHash(ctx context.Context, userID uuid.UUID, passwordHash string) error
}

// OTPStore manages OTP codes (storage + rate limiting).
type OTPStore interface {
	// Store saves an OTP for a phone with TTL.
	Store(ctx context.Context, phone, code string) error

	// Verify checks if the code matches the stored OTP.
	Verify(ctx context.Context, phone, code string) (bool, error)

	// CheckRateLimit returns an error if OTP requests are rate-limited for this phone.
	CheckRateLimit(ctx context.Context, phone string) error
}

// OTPSender sends OTP codes via SMS or another channel.
type OTPSender interface {
	// Send delivers the OTP code to the phone number.
	Send(ctx context.Context, phone, code string) error
}

type EmailOTPSender interface {
	SendEmailOTP(ctx context.Context, email, code string) error
}

type NicknameResolver interface {
	ResolveUserIDByNickname(ctx context.Context, nickname string) (uuid.UUID, error)
}

// OAuthVerifier verifies OAuth ID tokens from a specific provider.
type OAuthVerifier interface {
	// Verify validates the ID token and extracts user info.
	Verify(ctx context.Context, idToken string) (*model.OAuthUserInfo, error)
}

// TokenClient communicates with the token-service via gRPC.
type TokenClient interface {
	// GenerateUserTokens requests a token pair for a user. Device metadata
	// (when supplied) is stored on the new session for audit / future "active
	// devices" UI.
	GenerateUserTokens(ctx context.Context, userID, role string, permissions []string, device model.DeviceInfo) (*model.AuthResult, error)

	// RefreshTokens validates a refresh token and issues a new token pair.
	RefreshTokens(ctx context.Context, refreshToken string, device model.DeviceInfo) (*model.AuthResult, error)

	// RevokeToken revokes a specific token by JTI (legacy single-JTI revoke).
	RevokeToken(ctx context.Context, jti string, expiresAt int64, reason string) error

	// RevokeSession revokes a single user session (preferred logout path).
	RevokeSession(ctx context.Context, sessionID, reason string) error

	// ValidateAccessToken validates an access token and extracts claims.
	ValidateAccessToken(ctx context.Context, token string) (*TokenClaims, error)

	// ValidateRefreshToken validates a refresh token and extracts claims.
	ValidateRefreshToken(ctx context.Context, token string) (*TokenClaims, error)
}

// TokenClaims represents the parsed claims from the token-service.
type TokenClaims struct {
	Subject     string
	Role        string
	Permissions []string
	JTI         string
	SessionID   string
	ExpiresAt   int64
}

type FraudDecision string

const (
	FraudDecisionAllow     FraudDecision = "ALLOW"
	FraudDecisionChallenge FraudDecision = "CHALLENGE"
	FraudDecisionReview    FraudDecision = "REVIEW"
	FraudDecisionBlock     FraudDecision = "BLOCK"
)

type FraudAssessmentInput struct {
	Action      string
	ActorUserID *uuid.UUID
	Phone       string
	Provider    model.AuthProvider
	ProviderID  string
	Device      model.DeviceInfo
	Metadata    map[string]any
}

type FraudAssessmentResult struct {
	Decision   FraudDecision
	RiskScore  int
	Reasons    []string
	ShadowMode bool
}

type FraudEvaluator interface {
	AssessAuth(ctx context.Context, input FraudAssessmentInput) (*FraudAssessmentResult, error)
}
