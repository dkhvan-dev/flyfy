package app

import "context"

type TokenClaims struct {
	Subject string
	UserID  string
	Roles   []string
}

type TokenVerifier interface {
	VerifyAccessToken(ctx context.Context, accessToken string) (*TokenClaims, error)
}
