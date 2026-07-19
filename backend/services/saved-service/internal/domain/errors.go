package domain

// ErrorCode is the stable, transport-neutral identifier for a domain failure.
type ErrorCode string

const (
	ErrorCodeTargetTypeUnsupported      ErrorCode = "SAVED_TARGET_TYPE_UNSUPPORTED"
	ErrorCodeTargetUnavailable          ErrorCode = "SAVED_TARGET_UNAVAILABLE"
	ErrorCodeDependencyUnavailable      ErrorCode = "SAVED_DEPENDENCY_UNAVAILABLE"
	ErrorCodeMutationStale              ErrorCode = "SAVED_MUTATION_STALE"
	ErrorCodeReplayMismatch             ErrorCode = "SAVED_MUTATION_REPLAY_MISMATCH"
	ErrorCodeCollectionNotFound         ErrorCode = "SAVED_COLLECTION_NOT_FOUND"
	ErrorCodeCollectionDeleted          ErrorCode = "SAVED_COLLECTION_DELETED"
	ErrorCodeCollectionTitleInvalid     ErrorCode = "SAVED_COLLECTION_TITLE_INVALID"
	ErrorCodeCollectionTitleConflict    ErrorCode = "SAVED_COLLECTION_TITLE_CONFLICT"
	ErrorCodeCollectionLimitReached     ErrorCode = "SAVED_COLLECTION_LIMIT_REACHED"
	ErrorCodeCollectionItemLimitReached ErrorCode = "SAVED_COLLECTION_ITEM_LIMIT_REACHED"
	ErrorCodeMembershipLimitReached     ErrorCode = "SAVED_MEMBERSHIP_LIMIT_REACHED"
	ErrorCodeItemLimitReached           ErrorCode = "SAVED_ITEM_LIMIT_REACHED"
	ErrorCodeRequestInProgress          ErrorCode = "SAVED_REQUEST_IN_PROGRESS"
	ErrorCodeOperationExpired           ErrorCode = "SAVED_OPERATION_EXPIRED"
	ErrorCodeCursorInvalid              ErrorCode = "SAVED_CURSOR_INVALID"
	ErrorCodeRateLimited                ErrorCode = "SAVED_RATE_LIMITED"
	ErrorCodeTemporarilyUnavailable     ErrorCode = "SAVED_TEMPORARILY_UNAVAILABLE"
	ErrorCodePlatformPersonalDataLocked ErrorCode = "PLATFORM_PERSONAL_DATA_LOCKED"
)

func (c ErrorCode) IsValid() bool {
	switch c {
	case ErrorCodeTargetTypeUnsupported,
		ErrorCodeTargetUnavailable,
		ErrorCodeDependencyUnavailable,
		ErrorCodeMutationStale,
		ErrorCodeReplayMismatch,
		ErrorCodeCollectionNotFound,
		ErrorCodeCollectionDeleted,
		ErrorCodeCollectionTitleInvalid,
		ErrorCodeCollectionTitleConflict,
		ErrorCodeCollectionLimitReached,
		ErrorCodeCollectionItemLimitReached,
		ErrorCodeMembershipLimitReached,
		ErrorCodeItemLimitReached,
		ErrorCodeRequestInProgress,
		ErrorCodeOperationExpired,
		ErrorCodeCursorInvalid,
		ErrorCodeRateLimited,
		ErrorCodeTemporarilyUnavailable,
		ErrorCodePlatformPersonalDataLocked:
		return true
	default:
		return false
	}
}

// DomainError contains only an externally safe classification. It must not
// carry target, user, or request-payload data.
type DomainError struct {
	Code         ErrorCode
	Retryable    bool
	RetryAfterMS *int64
}

func (e *DomainError) Error() string {
	return string(e.Code)
}

func (e *DomainError) Is(target error) bool {
	other, ok := target.(*DomainError)
	return ok && e.Code == other.Code
}

var (
	ErrTargetTypeUnsupported      = &DomainError{Code: ErrorCodeTargetTypeUnsupported}
	ErrTargetUnavailable          = &DomainError{Code: ErrorCodeTargetUnavailable}
	ErrDependencyUnavailable      = &DomainError{Code: ErrorCodeDependencyUnavailable, Retryable: true}
	ErrMutationStale              = &DomainError{Code: ErrorCodeMutationStale}
	ErrReplayMismatch             = &DomainError{Code: ErrorCodeReplayMismatch}
	ErrCollectionNotFound         = &DomainError{Code: ErrorCodeCollectionNotFound}
	ErrCollectionDeleted          = &DomainError{Code: ErrorCodeCollectionDeleted}
	ErrCollectionTitleInvalid     = &DomainError{Code: ErrorCodeCollectionTitleInvalid}
	ErrCollectionTitleConflict    = &DomainError{Code: ErrorCodeCollectionTitleConflict}
	ErrCollectionLimitReached     = &DomainError{Code: ErrorCodeCollectionLimitReached}
	ErrCollectionItemLimitReached = &DomainError{Code: ErrorCodeCollectionItemLimitReached}
	ErrMembershipLimitReached     = &DomainError{Code: ErrorCodeMembershipLimitReached}
	ErrItemLimitReached           = &DomainError{Code: ErrorCodeItemLimitReached}
	ErrRequestInProgress          = &DomainError{Code: ErrorCodeRequestInProgress, Retryable: true}
	ErrOperationExpired           = &DomainError{Code: ErrorCodeOperationExpired}
	ErrCursorInvalid              = &DomainError{Code: ErrorCodeCursorInvalid}
	ErrRateLimited                = &DomainError{Code: ErrorCodeRateLimited, Retryable: true}
	ErrTemporarilyUnavailable     = &DomainError{Code: ErrorCodeTemporarilyUnavailable, Retryable: true}
	ErrPlatformPersonalDataLocked = &DomainError{Code: ErrorCodePlatformPersonalDataLocked}
)
