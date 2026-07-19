package savedcollection

// ErrorCode is closed so collection infrastructure never exposes SQL,
// owner identifiers, titles, or opaque media references through errors.
type ErrorCode string

const (
	ErrorCodeInvalidCommand            ErrorCode = "SAVED_COLLECTION_INVALID_COMMAND"
	ErrorCodeOperationNotFound         ErrorCode = "SAVED_OPERATION_NOT_FOUND"
	ErrorCodePublicEligibilityRequired ErrorCode = "SAVED_PUBLIC_ELIGIBILITY_REQUIRED"
	ErrorCodeRepositoryUnavailable     ErrorCode = "SAVED_REPOSITORY_UNAVAILABLE"
	ErrorCodeDataInvariant             ErrorCode = "SAVED_DATA_INVARIANT"
)

type Error struct {
	Code ErrorCode
}

func (e *Error) Error() string {
	if e == nil {
		return string(ErrorCodeRepositoryUnavailable)
	}
	return string(e.Code)
}

func (e *Error) Is(target error) bool {
	other, ok := target.(*Error)
	return ok && e != nil && e.Code == other.Code
}

var (
	ErrInvalidCommand            = &Error{Code: ErrorCodeInvalidCommand}
	ErrOperationNotFound         = &Error{Code: ErrorCodeOperationNotFound}
	ErrPublicEligibilityRequired = &Error{Code: ErrorCodePublicEligibilityRequired}
	ErrRepositoryUnavailable     = &Error{Code: ErrorCodeRepositoryUnavailable}
	ErrDataInvariant             = &Error{Code: ErrorCodeDataInvariant}
)
