package savedlifecycle

import (
	"context"
	"errors"
)

type ErrorCode string

const (
	ErrorCodeInvalidSubject           ErrorCode = "INVALID_SUBJECT"
	ErrorCodeMalformedProtobuf        ErrorCode = "MALFORMED_PROTOBUF"
	ErrorCodeUnknownContractField     ErrorCode = "UNKNOWN_CONTRACT_FIELD"
	ErrorCodeInvalidEventID           ErrorCode = "INVALID_EVENT_ID"
	ErrorCodeInvalidTarget            ErrorCode = "INVALID_TARGET"
	ErrorCodeInvalidRevision          ErrorCode = "INVALID_REVISION"
	ErrorCodeRevisionConflict         ErrorCode = "REVISION_CONFLICT"
	ErrorCodeInvalidTimestamp         ErrorCode = "INVALID_TIMESTAMP"
	ErrorCodeInvalidKindVisibility    ErrorCode = "INVALID_KIND_VISIBILITY"
	ErrorCodeInvalidPublicProjection  ErrorCode = "INVALID_PUBLIC_PROJECTION"
	ErrorCodePayloadForbidden         ErrorCode = "PAYLOAD_FORBIDDEN"
	ErrorCodeEventIdentityConflict    ErrorCode = "EVENT_IDENTITY_CONFLICT"
	ErrorCodeProjectionSourceConflict ErrorCode = "PROJECTION_SOURCE_CONFLICT"
	ErrorCodePersistenceInvariant     ErrorCode = "PERSISTENCE_INVARIANT"
	ErrorCodeRepositoryUnavailable    ErrorCode = "REPOSITORY_UNAVAILABLE"
	ErrorCodeProcessingTimeout        ErrorCode = "PROCESSING_TIMEOUT"
	ErrorCodeCanceled                 ErrorCode = "CANCELED"
	ErrorCodeUnknown                  ErrorCode = "UNKNOWN"
)

var (
	ErrPermanent             = errors.New("permanent Saved lifecycle error")
	ErrRepositoryUnavailable = errors.New("Saved lifecycle repository unavailable")
)

// PermanentError contains only a closed code so poison messages can be
// classified and dead-lettered without retaining or logging their payload.
type PermanentError struct {
	Code ErrorCode
}

func (e *PermanentError) Error() string {
	if e == nil || e.Code == "" {
		return string(ErrorCodeUnknown)
	}
	return string(e.Code)
}

func (e *PermanentError) Unwrap() error { return ErrPermanent }

func NewPermanentError(code ErrorCode) error {
	if code == "" {
		code = ErrorCodeUnknown
	}
	return &PermanentError{Code: code}
}

func IsPermanent(err error) bool {
	return errors.Is(err, ErrPermanent)
}

func CodeOf(err error) ErrorCode {
	if err == nil {
		return ""
	}
	var permanent *PermanentError
	if errors.As(err, &permanent) && permanent.Code != "" {
		return permanent.Code
	}
	switch {
	case errors.Is(err, ErrRepositoryUnavailable):
		return ErrorCodeRepositoryUnavailable
	case errors.Is(err, context.Canceled):
		return ErrorCodeCanceled
	case errors.Is(err, context.DeadlineExceeded):
		return ErrorCodeProcessingTimeout
	default:
		return ErrorCodeUnknown
	}
}
