package model

import "errors"

var (
	// User errors
	ErrUserNotFound = errors.New("user not found")
	ErrUserBlocked  = errors.New("user account is blocked")

	// Email/password auth errors
	ErrEmailRequired            = errors.New("email is required")
	ErrEmailInvalid             = errors.New("email is invalid")
	ErrPasswordRequired         = errors.New("password is required")
	ErrPasswordWeak             = errors.New("password is too weak")
	ErrEmailAlreadyExists       = errors.New("email is already registered")
	ErrEmailNotVerified         = errors.New("email is not verified")
	ErrInvalidCredentials       = errors.New("invalid credentials")
	ErrPasswordUnchanged        = errors.New("new password must differ from current password")
	ErrNicknameLoginUnavailable = errors.New("nickname login is temporarily unavailable")

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
