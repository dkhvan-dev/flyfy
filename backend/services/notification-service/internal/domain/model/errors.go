package model

import "errors"

var (
	ErrInvalidInput        = errors.New("invalid input")
	ErrUnauthorized        = errors.New("unauthorized")
	ErrNotFound            = errors.New("not found")
	ErrProviderDisabled    = errors.New("push provider disabled")
	ErrProviderUnavailable = errors.New("push provider unavailable")
)
