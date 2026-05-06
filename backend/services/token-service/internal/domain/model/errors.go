package model

import "errors"

var (
	ErrTokenExpired       = errors.New("token has expired")
	ErrTokenRevoked       = errors.New("token has been revoked")
	ErrTokenInvalid       = errors.New("token is invalid")
	ErrTokenMalformed     = errors.New("token is malformed")
	ErrInvalidSignature   = errors.New("token signature is invalid")
	ErrKeyNotFound        = errors.New("signing key not found")
	ErrNoActiveKey        = errors.New("no active signing key available")
	ErrServiceNotFound    = errors.New("service account not found")
	ErrServiceInactive    = errors.New("service account is inactive")
	ErrInvalidCredentials = errors.New("invalid service credentials")
	ErrPermissionDenied   = errors.New("permission denied")
	ErrRateLimited        = errors.New("rate limit exceeded")

	ErrSessionNotFound  = errors.New("user session not found")
	ErrSessionRevoked   = errors.New("user session has been revoked")
	ErrSessionExpired   = errors.New("user session has expired due to inactivity")
	ErrSessionConflict  = errors.New("concurrent session creation conflict")
	ErrTokenReuseDetect = errors.New("refresh token reuse detected; session revoked")
)
