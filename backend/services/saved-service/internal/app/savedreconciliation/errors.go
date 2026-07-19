package savedreconciliation

// ErrorCode is intentionally closed. Reconciliation errors must remain safe
// for metrics and logs and therefore never carry target identifiers or source
// error text.
type ErrorCode string

const (
	ErrorCodeInvalidConfig         ErrorCode = "SAVED_RECONCILIATION_INVALID_CONFIG"
	ErrorCodeInvalidDependencies   ErrorCode = "SAVED_RECONCILIATION_INVALID_DEPENDENCIES"
	ErrorCodeRepositoryUnavailable ErrorCode = "SAVED_RECONCILIATION_REPOSITORY_UNAVAILABLE"
	ErrorCodeDataInvariant         ErrorCode = "SAVED_RECONCILIATION_DATA_INVARIANT"
	ErrorCodeCommitOutcomeUnknown  ErrorCode = "SAVED_RECONCILIATION_COMMIT_OUTCOME_UNKNOWN"
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
	ErrInvalidConfig         = &Error{Code: ErrorCodeInvalidConfig}
	ErrInvalidDependencies   = &Error{Code: ErrorCodeInvalidDependencies}
	ErrRepositoryUnavailable = &Error{Code: ErrorCodeRepositoryUnavailable}
	ErrDataInvariant         = &Error{Code: ErrorCodeDataInvariant}
	ErrCommitOutcomeUnknown  = &Error{Code: ErrorCodeCommitOutcomeUnknown}
)
