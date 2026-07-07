package serviceauth

import "errors"

var (
	ErrMissingBearerToken = errors.New("missing bearer token")
	ErrInvalidBearerToken = errors.New("invalid bearer token")
	ErrInvalidServiceJWT  = errors.New("invalid service jwt")
	ErrForbiddenService   = errors.New("service is not allowed")
)

func IsUnauthorized(err error) bool {
	return errors.Is(err, ErrMissingBearerToken) ||
		errors.Is(err, ErrInvalidBearerToken) ||
		errors.Is(err, ErrInvalidServiceJWT)
}

func IsForbidden(err error) bool {
	return errors.Is(err, ErrForbiddenService)
}
