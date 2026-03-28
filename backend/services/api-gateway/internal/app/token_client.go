package app

import (
	"context"
	"time"
)

type TokenClaims struct {
	Subject     string    `json:"sub"`
	UserID      string    `json:"user_id,omitempty"`
	Role        string    `json:"role,omitempty"`
	Roles       []string  `json:"roles,omitempty"`
	Permissions []string  `json:"permissions,omitempty"`
	JTI         string    `json:"jti"`
	IssuedAt    time.Time `json:"iat"`
	ExpiresAt   time.Time `json:"exp"`
}

type TokenVerifier interface {
	VerifyAccessToken(ctx context.Context, accessToken string) (*TokenClaims, error)
}
