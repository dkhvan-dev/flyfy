package model

import (
	"time"

	"github.com/google/uuid"
)

// AuthProvider represents the authentication method.
type AuthProvider string

const (
	ProviderPhone  AuthProvider = "phone"
	ProviderEmail  AuthProvider = "email"
	ProviderGoogle AuthProvider = "google"
	ProviderApple  AuthProvider = "apple"
)

// UserRole represents the role of a user in the system.
type UserRole string

const (
	RoleTourist UserRole = "tourist"
	RoleGuide   UserRole = "guide"
	RoleAgency  UserRole = "agency"
	RoleAdmin   UserRole = "admin"
)

// AuthUser represents a user in the auth system.
type AuthUser struct {
	ID            uuid.UUID `json:"id"`
	Phone         *string   `json:"phone,omitempty"`
	Email         *string   `json:"email,omitempty"`
	PasswordHash  *string   `json:"password_hash,omitempty"`
	EmailVerified bool      `json:"email_verified"`
	Role          UserRole  `json:"role"`
	IsActive      bool      `json:"is_active"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// AuthProviderLink represents an OAuth provider linked to a user.
type AuthProviderLink struct {
	ID         uuid.UUID    `json:"id"`
	UserID     uuid.UUID    `json:"user_id"`
	Provider   AuthProvider `json:"provider"`
	ProviderID string       `json:"provider_id"`
	Email      *string      `json:"email,omitempty"`
	CreatedAt  time.Time    `json:"created_at"`
}

// OTPRequest represents a request to send an OTP code.
type OTPRequest struct {
	Phone string `json:"phone"`
}

// OTPVerification represents an OTP verification attempt.
type OTPVerification struct {
	Phone string `json:"phone"`
	Code  string `json:"code"`
}

// OAuthLoginRequest represents a login request via an OAuth provider.
type OAuthLoginRequest struct {
	Provider AuthProvider `json:"provider"`
	IDToken  string       `json:"id_token"`
}

// OAuthUserInfo represents user info extracted from an OAuth ID token.
type OAuthUserInfo struct {
	ProviderID string `json:"provider_id"` // "sub" from the token
	Email      string `json:"email,omitempty"`
	Name       string `json:"name,omitempty"`
}
