package savedmaintenance

import (
	"errors"
	"fmt"
)

type ErrorKind string

const (
	ErrorKindUnavailable ErrorKind = "UNAVAILABLE"
	ErrorKindContention  ErrorKind = "CONTENTION"
	ErrorKindInvariant   ErrorKind = "INVARIANT"
)

// Error is safe for a scheduler to classify without parsing database messages.
type Error struct {
	Operation string
	Kind      ErrorKind
	Retryable bool
	Cause     error
}

func NewError(operation string, kind ErrorKind, retryable bool, cause error) *Error {
	return &Error{
		Operation: operation,
		Kind:      kind,
		Retryable: retryable,
		Cause:     cause,
	}
}

func (e *Error) Error() string {
	if e == nil {
		return "<nil>"
	}
	if e.Cause == nil {
		return fmt.Sprintf("saved maintenance %s failed (%s)", e.Operation, e.Kind)
	}
	return fmt.Sprintf("saved maintenance %s failed (%s): %v", e.Operation, e.Kind, e.Cause)
}

func (e *Error) Unwrap() error {
	if e == nil {
		return nil
	}
	return e.Cause
}

func IsRetryable(err error) bool {
	var maintenanceError *Error
	return errors.As(err, &maintenanceError) && maintenanceError.Retryable
}
