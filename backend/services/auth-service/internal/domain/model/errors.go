package model

import "errors"

var (
	// User errors
	ErrUserNotFound = errors.New("user not found")
	ErrUserBlocked  = errors.New("user account is blocked")

	// OTP errors
	ErrInvalidOTP    = errors.New("invalid or expired OTP code")
	ErrOTPExpired    = errors.New("OTP code has expired")
	ErrOTPRateLimit  = errors.New("too many OTP requests, try again later")
	ErrPhoneRequired = errors.New("phone number is required")

	// OAuth errors
	ErrOAuthFailed         = errors.New("OAuth token verification failed")
	ErrOAuthProviderID     = errors.New("provider ID is missing from token")
	ErrUnsupportedProvider = errors.New("unsupported auth provider")

	// Token errors
	ErrTokenServiceUnavailable = errors.New("token service is unavailable")
	ErrInvalidRefreshToken     = errors.New("invalid or expired refresh token")

	// General
	ErrRateLimited = errors.New("rate limit exceeded")
)
