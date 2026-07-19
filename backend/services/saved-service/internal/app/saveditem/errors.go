package saveditem

// ErrorCode is intentionally closed so repository failures cannot expose SQL,
// identifiers, or request data through an exported error message.
type ErrorCode string

const (
	ErrorCodeInvalidCommand        ErrorCode = "SAVED_ITEM_INVALID_COMMAND"
	ErrorCodeOperationNotFound     ErrorCode = "SAVED_OPERATION_NOT_FOUND"
	ErrorCodeRepositoryUnavailable ErrorCode = "SAVED_REPOSITORY_UNAVAILABLE"
	ErrorCodeDataInvariant         ErrorCode = "SAVED_DATA_INVARIANT"
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
	ErrInvalidCommand        = &Error{Code: ErrorCodeInvalidCommand}
	ErrOperationNotFound     = &Error{Code: ErrorCodeOperationNotFound}
	ErrRepositoryUnavailable = &Error{Code: ErrorCodeRepositoryUnavailable}
	ErrDataInvariant         = &Error{Code: ErrorCodeDataInvariant}
)
