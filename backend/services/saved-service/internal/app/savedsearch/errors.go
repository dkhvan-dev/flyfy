package savedsearch

// ErrorCode is closed so search failures never expose owner IDs, collection
// IDs, SQL details, or the submitted query.
type ErrorCode string

const (
	ErrorCodeInvalidQuery          ErrorCode = "SAVED_SEARCH_INVALID"
	ErrorCodeCollectionNotFound    ErrorCode = "SAVED_COLLECTION_NOT_FOUND"
	ErrorCodeRepositoryUnavailable ErrorCode = "SAVED_SEARCH_REPOSITORY_UNAVAILABLE"
	ErrorCodeDataInvariant         ErrorCode = "SAVED_SEARCH_DATA_INVARIANT"
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
