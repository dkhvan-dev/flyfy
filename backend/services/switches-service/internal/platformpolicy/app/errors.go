package app

import "errors"

var (
	ErrInvalidCommand   = errors.New("invalid platform policy command")
	ErrRevisionConflict = errors.New("platform policy revision conflict")
	ErrStateUnchanged   = errors.New("platform policy state is unchanged")
	ErrUnavailable      = errors.New("platform policy unavailable")
)
