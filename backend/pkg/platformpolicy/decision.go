package platformpolicy

import (
	"errors"
	"time"
)

const (
	// MaxDecisionValidity bounds how long any policy decision may authorize
	// personal-data access.
	MaxDecisionValidity = 30 * time.Second
	// MaxClockSkew permits a small control-plane clock lead without extending
	// the decision's validity window.
	MaxClockSkew = 2 * time.Second
)

// State is the complete set of platform personal-data policy states.
type State string

const (
	StateAvailable State = "AVAILABLE"
	StateLocked    State = "LOCKED"
)

// Decision is the closed policy wire contract. It deliberately contains no
// subject, exception, payload, product, or feature-specific fields.
type Decision struct {
	Revision   uint64    `json:"revision"`
	State      State     `json:"state"`
	IssuedAt   time.Time `json:"issued_at"`
	ValidUntil time.Time `json:"valid_until"`
}

var (
	errZeroRevision      = errors.New("platform policy revision must be positive")
	errUnknownState      = errors.New("platform policy state is invalid")
	errMissingIssuedAt   = errors.New("platform policy issued_at is required")
	errMissingValidUntil = errors.New("platform policy valid_until is required")
	errInvalidWindow     = errors.New("platform policy validity window is invalid")
	errWindowTooLong     = errors.New("platform policy validity window is too long")
	errIssuedInFuture    = errors.New("platform policy issued_at is in the future")
	errDecisionExpired   = errors.New("platform policy decision is expired")
)

func validateDecision(decision Decision, now time.Time) (Reason, error) {
	if err := validateDecisionShape(decision); err != nil {
		return ReasonMalformed, err
	}
	switch {
	case decision.IssuedAt.After(now.Add(MaxClockSkew)):
		return ReasonMalformed, errIssuedInFuture
	case !now.Before(decision.ValidUntil):
		return ReasonStale, errDecisionExpired
	default:
		return ReasonNone, nil
	}
}

func validateDecisionShape(decision Decision) error {
	switch {
	case decision.Revision == 0:
		return errZeroRevision
	case decision.State != StateAvailable && decision.State != StateLocked:
		return errUnknownState
	case decision.IssuedAt.IsZero():
		return errMissingIssuedAt
	case decision.ValidUntil.IsZero():
		return errMissingValidUntil
	case !decision.ValidUntil.After(decision.IssuedAt):
		return errInvalidWindow
	case decision.ValidUntil.Sub(decision.IssuedAt) > MaxDecisionValidity:
		return errWindowTooLong
	default:
		return nil
	}
}

func decisionsEqual(left Decision, right Decision) bool {
	return left.Revision == right.Revision &&
		left.State == right.State &&
		left.IssuedAt.Equal(right.IssuedAt) &&
		left.ValidUntil.Equal(right.ValidUntil)
}
