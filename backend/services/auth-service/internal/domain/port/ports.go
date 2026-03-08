package port

import (
	"context"

	"github.com/dkhvan-dev/flyfy/backend/services/auth-service/internal/domain/model"
)

// --- Primary Ports (driven by incoming requests) ---

// Authenticator is the main use-case port for authentication flows.
type Authenticator interface {
	// SendOTP sends an OTP code to the given phone number.
	SendOTP(ctx context.Context, phone string) error

	// VerifyOTPAndLogin verifies the OTP code and returns tokens.
	VerifyOTPAndLogin(ctx context.Context, phone, code string) (*model.AuthResult, error)

	// GoogleLogin authenticates a user via Google ID Token.
	GoogleLogin(ctx context.Context, idToken string) (*model.AuthResult, error)

	// AppleLogin authenticates a user via Apple ID Token.
	AppleLogin(ctx context.Context, idToken string) (*model.AuthResult, error)

	// RefreshTokens issues a new token pair using a refresh token.
	RefreshTokens(ctx context.Context, refreshToken string) (*model.AuthResult, error)

	// Logout revokes the given tokens.
	Logout(ctx context.Context, accessToken, refreshToken string) error
}

// --- Secondary Ports (driven by the application) ---

// UserRepository manages auth users in the database.
type UserRepository interface {
	// FindByPhone returns a user by phone number.
	FindByPhone(ctx context.Context, phone string) (*model.AuthUser, error)

	// FindByProvider returns a user by OAuth provider + provider ID.
	FindByProvider(ctx context.Context, provider model.AuthProvider, providerID string) (*model.AuthUser, error)

	// Create creates a new user and returns it.
	Create(ctx context.Context, user *model.AuthUser) error

	// LinkProvider links an OAuth provider to an existing user.
	LinkProvider(ctx context.Context, link *model.AuthProviderLink) error
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

// OAuthVerifier verifies OAuth ID tokens from a specific provider.
type OAuthVerifier interface {
	// Verify validates the ID token and extracts user info.
	Verify(ctx context.Context, idToken string) (*model.OAuthUserInfo, error)
}

// TokenClient communicates with the token-service via gRPC.
type TokenClient interface {
	// GenerateUserTokens requests a token pair for a user.
	GenerateUserTokens(ctx context.Context, userID, role string, permissions []string) (*model.AuthResult, error)

	// RefreshTokens validates a refresh token and issues a new token pair.
	RefreshTokens(ctx context.Context, refreshToken string) (*model.AuthResult, error)

	// RevokeToken revokes a specific token by JTI.
	RevokeToken(ctx context.Context, jti string, expiresAt int64, reason string) error

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
	ExpiresAt   int64
}
