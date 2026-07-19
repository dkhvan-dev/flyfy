package savedquery

// ErrorCode is closed so query failures never expose SQL, owner IDs, targets,
// or collection identifiers to callers.
type ErrorCode string

const (
	ErrorCodeInvalidQuery          ErrorCode = "SAVED_QUERY_INVALID"
	ErrorCodeCollectionNotFound    ErrorCode = "SAVED_COLLECTION_NOT_FOUND"
	ErrorCodeRepositoryUnavailable ErrorCode = "SAVED_QUERY_REPOSITORY_UNAVAILABLE"
	ErrorCodeDataInvariant         ErrorCode = "SAVED_QUERY_DATA_INVARIANT"
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
	ErrInvalidQuery          = &Error{Code: ErrorCodeInvalidQuery}
	ErrCollectionNotFound    = &Error{Code: ErrorCodeCollectionNotFound}
	ErrRepositoryUnavailable = &Error{Code: ErrorCodeRepositoryUnavailable}
	ErrDataInvariant         = &Error{Code: ErrorCodeDataInvariant}
)
