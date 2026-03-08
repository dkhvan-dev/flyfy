package port

import (
	"context"
	"crypto/rsa"

	"github.com/go-jose/go-jose/v4"
	"github.com/dkhvan-dev/flyfy/token-service/internal/domain/model"
)

// --- Primary Ports (driven by incoming requests) ---

// TokenGenerator creates new JWT tokens.
type TokenGenerator interface {
	// GenerateUserTokens creates access + refresh token pair for a user.
	GenerateUserTokens(ctx context.Context, claims model.UserClaims) (*model.TokenPair, error)

	// GenerateServiceToken creates a service-to-service JWT.
	GenerateServiceToken(ctx context.Context, claims model.ServiceClaims) (*model.ServiceToken, error)
}

// TokenValidator verifies and parses JWT tokens.
type TokenValidator interface {
	// ValidateAccessToken verifies a user access token and returns parsed claims.
	ValidateAccessToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error)

	// ValidateRefreshToken verifies a refresh token and returns parsed claims.
	ValidateRefreshToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error)

	// ValidateServiceToken verifies a service-to-service token.
	ValidateServiceToken(ctx context.Context, tokenStr string) (*model.ValidatedClaims, error)
}

// TokenRevoker handles token revocation (logout).
type TokenRevoker interface {
	// Revoke invalidates a token by its JTI.
	Revoke(ctx context.Context, jti string, expiresAt int64, reason string) error

	// IsRevoked checks if a token has been revoked.
	IsRevoked(ctx context.Context, jti string) (bool, error)
}

// ServiceAuthenticator handles service-to-service authentication.
type ServiceAuthenticator interface {
	// AuthenticateService verifies service credentials and returns a service token.
	AuthenticateService(ctx context.Context, serviceID, serviceSecret string) (*model.ServiceToken, error)
}

// KeyManager handles RSA key lifecycle.
type KeyManager interface {
	// RotateKeys generates a new key pair and deactivates old ones (beyond retention).
	RotateKeys(ctx context.Context) error

	// GetJWKS returns the JSON Web Key Set (public keys only).
	GetJWKS(ctx context.Context) (*jose.JSONWebKeySet, error)
}

// --- Secondary Ports (driven by the application) ---

// KeyStore persists RSA key pairs.
type KeyStore interface {
	// GetActiveKey returns the current active private key and its key ID.
	GetActiveKey(ctx context.Context) (keyID string, key *rsa.PrivateKey, err error)

	// GetPublicKeys returns all non-expired public keys for JWKS.
	GetPublicKeys(ctx context.Context) ([]jose.JSONWebKey, error)

	// StoreKey persists a new key pair.
	StoreKey(ctx context.Context, keyID string, key *rsa.PrivateKey) error

	// DeactivateKey marks a key as inactive.
	DeactivateKey(ctx context.Context, keyID string) error

	// DeleteExpiredKeys removes keys older than the retention period.
	DeleteExpiredKeys(ctx context.Context, maxKeys int) error
}

// RevocationStore manages the token revocation list.
type RevocationStore interface {
	// Add puts a token JTI into the revocation list with TTL.
	Add(ctx context.Context, jti string, expiresAt int64) error

	// Exists checks if a JTI is in the revocation list.
	Exists(ctx context.Context, jti string) (bool, error)
}

// ServiceAccountStore manages service account data.
type ServiceAccountStore interface {
	// GetByServiceID retrieves a service account by its ID.
	GetByServiceID(ctx context.Context, serviceID string) (*model.ServiceAccount, error)

	// GetRoles retrieves all roles assigned to a service account.
	GetRoles(ctx context.Context, accountID string) ([]string, error)
}

// AuditLogger logs security events.
type AuditLogger interface {
	// LogServiceAuth logs a service authentication attempt.
	LogServiceAuth(ctx context.Context, callerID, targetAction, result string, metadata map[string]string)
}

// PasswordVerifier handles secure password/secret comparison.
type PasswordVerifier interface {
	// Verify compares a hashed value with a plaintext value.
	// Returns true if they match.
	Verify(hash, plaintext string) bool

	// Hash creates a hash from a plaintext value.
	Hash(plaintext string) (string, error)
}