package port

import (
	"context"
	"crypto/rsa"
	"time"

	"github.com/google/uuid"

	"github.com/go-jose/go-jose/v4"
	"kz/inflap/backend/services/token-service/internal/domain/model"
)

// --- Primary Ports (driven by incoming requests) ---

// TokenGenerator creates new JWT tokens.
type TokenGenerator interface {
	// GenerateUserTokens creates an access + refresh token pair AND a backing
	// user session. If the user already has an active session, that session is
	// revoked first (single-session enforcement). Device metadata is stored on
	// the new session for diagnostics and future "active sessions" UX.
	GenerateUserTokens(ctx context.Context, claims model.UserClaims, device model.DeviceInfo) (*model.TokenPair, error)

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

// TokenRefresher rotates refresh tokens with reuse detection.
type TokenRefresher interface {
	// RefreshTokens validates the supplied refresh token, rotates it (issuing
	// a new pair), and returns the new pair. Reusing an already-rotated refresh
	// token revokes the entire session (token theft mitigation).
	RefreshTokens(ctx context.Context, refreshToken string, device model.DeviceInfo) (*model.TokenPair, error)
}

// TokenRevoker handles token revocation (logout).
type TokenRevoker interface {
	// Revoke invalidates a token by its JTI.
	Revoke(ctx context.Context, jti string, expiresAt int64, reason string) error

	// IsRevoked checks if a token has been revoked.
	IsRevoked(ctx context.Context, jti string) (bool, error)
}

// SessionManager handles user-session lifecycle from the outside (logout, list, admin).
type SessionManager interface {
	// LogoutSession revokes a single session (typically the caller's own).
	LogoutSession(ctx context.Context, sessionID uuid.UUID, reason string) error

	// ListUserSessions returns all sessions (active + recently revoked) for a user.
	// Used for the "active devices" UX — implementations may bound by recency.
	ListUserSessions(ctx context.Context, userID uuid.UUID) ([]*model.UserSession, error)

	// RevokeAllUserSessions force-logs the user out everywhere (admin / panic button).
	RevokeAllUserSessions(ctx context.Context, userID uuid.UUID, reason string) (int, error)

	// ValidateUserSessionGeneration authoritatively checks that generation is
	// still the user's single active session. Invalid lifecycle states are
	// represented by false; only dependency failures return an error.
	ValidateUserSessionGeneration(ctx context.Context, userID, generation uuid.UUID) (bool, error)
}

type SessionRevocationNotification struct {
	UserID    uuid.UUID
	SessionID uuid.UUID
	Reason    string
}

type SessionRevocationNotifier interface {
	NotifySessionRevoked(ctx context.Context, event SessionRevocationNotification) error
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

// RevocationStore manages the per-JTI revocation list (fast deny-list).
type RevocationStore interface {
	// Add puts a token JTI into the revocation list with TTL.
	Add(ctx context.Context, jti string, expiresAt int64) error

	// Exists checks if a JTI is in the revocation list.
	Exists(ctx context.Context, jti string) (bool, error)
}

// RevokedSessionCache is a fast cache (Redis) of revoked session_ids so that
// every ValidateAccessToken can short-circuit without hitting Postgres.
type RevokedSessionCache interface {
	// MarkRevoked stores the session_id with the given TTL.
	// TTL should outlive the longest-lived access token for that session.
	MarkRevoked(ctx context.Context, sessionID uuid.UUID, ttl time.Duration) error

	// IsRevoked returns true if the session_id is present in the cache.
	IsRevoked(ctx context.Context, sessionID uuid.UUID) (bool, error)
}

// SessionStore persists user_sessions and refresh_token_history.
type SessionStore interface {
	// CreateActive atomically:
	//   1. Revokes any currently-active session for sess.UserID.
	//   2. Inserts the new session.
	// Returns the previously active session (if any) so the caller can push it
	// to the revocation list / audit log.
	//
	// On the very-rare race where the partial-unique index fires, returns
	// model.ErrSessionConflict so the caller can decide on retry/error mapping.
	CreateActive(ctx context.Context, sess *model.UserSession, replaceReason string) (replaced *model.UserSession, err error)

	GetByID(ctx context.Context, sessionID uuid.UUID) (*model.UserSession, error)
	GetActiveByUserID(ctx context.Context, userID uuid.UUID) (*model.UserSession, error)
	GetActiveByRefreshJTI(ctx context.Context, refreshJTI string) (*model.UserSession, error)

	// IsCurrentSessionGeneration performs a fresh authoritative read. It must
	// not consult a cache because callers use it immediately before committing
	// personal-data mutations.
	IsCurrentSessionGeneration(
		ctx context.Context,
		userID, generation uuid.UUID,
		now time.Time,
		inactivityTTL time.Duration,
	) (bool, error)

	// RotateRefresh updates the session's refresh JTI/hash/timestamps and
	// pushes the previous refresh JTI into refresh_token_history. Atomically.
	RotateRefresh(ctx context.Context, sessionID uuid.UUID, prev RotatePrev, next RotateNext) error

	Revoke(ctx context.Context, sessionID uuid.UUID, reason string) error
	RevokeAllForUser(ctx context.Context, userID uuid.UUID, reason string) (int, error)
	TouchLastUsed(ctx context.Context, sessionID uuid.UUID, at time.Time) error

	// FindHistoricalRefreshJTI returns (sessionID, true, nil) if the supplied
	// refresh JTI is in refresh_token_history (i.e. it was already rotated).
	FindHistoricalRefreshJTI(ctx context.Context, refreshJTI string) (uuid.UUID, bool, error)

	ListByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]*model.UserSession, error)
}

// RotatePrev / RotateNext are simple value bundles for SessionStore.RotateRefresh.
type RotatePrev struct {
	RefreshJTI       string
	RefreshTokenHash string
	IssuedAt         time.Time
}

type RotateNext struct {
	RefreshJTI       string
	RefreshTokenHash string
	IssuedAt         time.Time
	ExpiresAt        time.Time
	Device           model.DeviceInfo // overwrite when supplied; empty fields keep existing values
	RotatedAt        time.Time
}

// SessionAuditLogger records session-lifecycle events for security review.
type SessionAuditLogger interface {
	LogSessionEvent(
		ctx context.Context,
		userID uuid.UUID,
		sessionID *uuid.UUID,
		event string,
		ipAddress, userAgent string,
		metadata map[string]string,
	)
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
