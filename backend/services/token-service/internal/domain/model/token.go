package model

import (
	"time"

	"github.com/google/uuid"
)

// TokenType distinguishes between user and service tokens.
type TokenType string

const (
	TokenTypeUser    TokenType = "user"
	TokenTypeService TokenType = "service"
)

// UserRole represents the role of a user in the system.
type UserRole string

const (
	RoleTourist UserRole = "tourist"
	RoleGuide   UserRole = "guide"
	RoleAgency  UserRole = "agency"
	RoleAdmin   UserRole = "admin"
)

// --- Claims ---

// UserClaims holds claims for user tokens (access + refresh).
type UserClaims struct {
	UserID      uuid.UUID `json:"sub"`
	Type        TokenType `json:"type"`
	Role        UserRole  `json:"role"`
	Permissions []string  `json:"permissions,omitempty"`
}

// ServiceClaims holds claims for service-to-service tokens.
type ServiceClaims struct {
	ServiceID string    `json:"sub"`
	Type      TokenType `json:"type"`
	Roles     []string  `json:"roles"`
}

// --- Token Pair ---

// TokenPair is the result of generating access + refresh tokens.
type TokenPair struct {
	AccessToken      string    `json:"access_token"`
	RefreshToken     string    `json:"refresh_token"`
	ExpiresAt        time.Time `json:"expires_at"`         // access expiry
	RefreshExpiresAt time.Time `json:"refresh_expires_at"` // refresh expiry
	TokenType        string    `json:"token_type"`
	SessionID        uuid.UUID `json:"session_id"`
}

// ServiceToken is the result of generating a service token.
type ServiceToken struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

// --- Key Pair ---

// KeyPair represents an RSA key pair with metadata.
type KeyPair struct {
	ID        string    `json:"id"`
	Active    bool      `json:"active"`
	CreatedAt time.Time `json:"created_at"`
	RotatedAt time.Time `json:"rotated_at,omitempty"`
}

// --- Service Account ---

// ServiceAccount represents a microservice's identity and permissions.
type ServiceAccount struct {
	ID          uuid.UUID `json:"id"`
	ServiceID   string    `json:"service_id"`
	SecretHash  string    `json:"-"`
	DisplayName string    `json:"display_name"`
	IsActive    bool      `json:"is_active"`
	Roles       []string  `json:"roles"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// --- Revocation ---

// RevokedToken represents a token that has been explicitly revoked.
type RevokedToken struct {
	JTI       string    `json:"jti"`
	ExpiresAt time.Time `json:"expires_at"`
	RevokedAt time.Time `json:"revoked_at"`
	Reason    string    `json:"reason,omitempty"`
}

// --- Validation Result ---

// ValidatedClaims is the result of successful token validation.
type ValidatedClaims struct {
	Subject     string    `json:"sub"`
	UserID      string    `json:"user_id,omitempty"`
	Type        TokenType `json:"type"`
	Role        string    `json:"role,omitempty"`  // for user tokens
	Roles       []string  `json:"roles,omitempty"` // for service tokens
	Permissions []string  `json:"permissions,omitempty"`
	JTI         string    `json:"jti"`
	SessionID   string    `json:"sid,omitempty"` // user-token sessions only
	IssuedAt    time.Time `json:"iat"`
	ExpiresAt   time.Time `json:"exp"`
}
