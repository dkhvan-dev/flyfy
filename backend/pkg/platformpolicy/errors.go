package platformpolicy

import "errors"

// ExternalDenialCode is intentionally identical for every fail-closed denial.
// Internal metrics should use DenialReason instead of changing this code.
const ExternalDenialCode = "PLATFORM_PERSONAL_DATA_LOCKED"

// ErrDenied matches every policy denial without exposing its internal cause.
var ErrDenied = errors.New(ExternalDenialCode)

// Reason is an internal, low-cardinality denial reason suitable for metrics.
type Reason string

const (
	ReasonNone                  Reason = ""
	ReasonLocked                Reason = "LOCKED"
	ReasonUnavailable           Reason = "DEPENDENCY_UNAVAILABLE"
	ReasonStale                 Reason = "POLICY_STALE"
	ReasonMalformed             Reason = "POLICY_MALFORMED"
	ReasonRevisionRollback      Reason = "REVISION_ROLLBACK"
	ReasonDecisionConflict      Reason = "DECISION_CONFLICT"
	ReasonMinimumRevisionNotMet Reason = "MINIMUM_REVISION_NOT_MET"
)

// DependencyFailure reports whether the reason represents an inability to
// establish a current permitting decision rather than an explicit lock.
func (reason Reason) DependencyFailure() bool {
	return reason != ReasonNone && reason != ReasonLocked
}

// DenialError preserves a metrics-safe reason while presenting one stable
// external denial code.
type DenialError struct {
	reason Reason
	cause  error
}

func newDenial(reason Reason, cause error) *DenialError {
	return &DenialError{reason: reason, cause: cause}
}

func (err *DenialError) Error() string {
	return ExternalDenialCode
}

func (err *DenialError) Is(target error) bool {
	return target == ErrDenied
}

func (err *DenialError) Unwrap() error {
	if err == nil {
		return nil
	}
	return err.cause
}

// Reason returns the internal denial reason.
func (err *DenialError) Reason() Reason {
	if err == nil {
		return ReasonNone
	}
	return err.reason
}

// DenialReason extracts a typed reason without requiring callers to expose a
// different API error or response body.
func DenialReason(err error) (Reason, bool) {
	var denial *DenialError
	if !errors.As(err, &denial) {
		return ReasonNone, false
	}
	return denial.Reason(), true
}
