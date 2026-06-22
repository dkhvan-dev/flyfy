package app

import "errors"

var (
	ErrEngineUnavailable  = errors.New("routing engine unavailable")
	ErrTransitUnavailable = errors.New("routing transit unavailable")
)
