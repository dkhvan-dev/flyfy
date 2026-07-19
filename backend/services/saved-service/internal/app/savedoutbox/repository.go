package savedoutbox

import (
	"context"
	"time"
)

const (
	MaxClaimBatch       = 500
	MaxCleanupBatch     = 5_000
	MaxDeliveryAttempts = 100
	TerminalRetention   = 14 * 24 * time.Hour
)

type FailureCode string

const (
	FailureInvalidEvent      FailureCode = "INVALID_OUTBOX_EVENT"
	FailurePublishFailed     FailureCode = "PUBLISH_FAILED"
	FailurePublishTimeout    FailureCode = "PUBLISH_TIMEOUT"
	FailureLeaseExpired      FailureCode = "LEASE_EXPIRED"
	FailureAttemptsExhausted FailureCode = "DELIVERY_ATTEMPTS_EXHAUSTED"
)

func (code FailureCode) IsValid() bool {
	switch code {
	case FailureInvalidEvent,
		FailurePublishFailed,
		FailurePublishTimeout,
		FailureLeaseExpired,
		FailureAttemptsExhausted:
		return true
	default:
		return false
	}
}

type ClaimRequest struct {
	Now         time.Time
	Limit       int
	MaxAttempts int
}

func (request ClaimRequest) Validate() error {
	if !validOutboxTime(request.Now) || request.Limit < 1 || request.Limit > MaxClaimBatch ||
		request.MaxAttempts < 1 || request.MaxAttempts > MaxDeliveryAttempts {
		return ErrInvalidRequest
	}
	return nil
}

type RecoveryRequest struct {
	Now                time.Time
	LeaseExpiredBefore time.Time
	TerminalExpiresAt  time.Time
	Limit              int
	MaxAttempts        int
}

func (request RecoveryRequest) Validate() error {
	if !validOutboxTime(request.Now) || !validOutboxTime(request.LeaseExpiredBefore) ||
		request.LeaseExpiredBefore.After(request.Now) ||
		!request.TerminalExpiresAt.Equal(request.Now.Add(TerminalRetention)) ||
		request.Limit < 1 || request.Limit > MaxClaimBatch ||
		request.MaxAttempts < 1 || request.MaxAttempts > MaxDeliveryAttempts {
		return ErrInvalidRequest
	}
	return nil
}

type RecoveryResult struct {
	Released int
	Dead     int
}

func (result RecoveryResult) Validate(limit int) error {
	if limit < 1 || result.Released < 0 || result.Dead < 0 ||
		result.Released+result.Dead > limit {
		return ErrPersistenceInvariant
	}
	return nil
}

type Delivery struct {
	Lease       Lease
	DeliveredAt time.Time
	RetainUntil time.Time
}

func (delivery Delivery) Validate() error {
	if err := delivery.Lease.Validate(); err != nil || !validOutboxTime(delivery.DeliveredAt) ||
		delivery.DeliveredAt.Before(delivery.Lease.AcquiredAt) ||
		!delivery.RetainUntil.Equal(delivery.DeliveredAt.Add(TerminalRetention)) {
		return ErrInvalidRequest
	}
	return nil
}

type Failure struct {
	Lease         Lease
	Code          FailureCode
	FailedAt      time.Time
	NextAttemptAt time.Time
	RetainUntil   time.Time
	MaxAttempts   int
	Permanent     bool
}

func (failure Failure) Validate() error {
	if err := failure.Lease.Validate(); err != nil || !failure.Code.IsValid() ||
		!validOutboxTime(failure.FailedAt) || failure.FailedAt.Before(failure.Lease.AcquiredAt) ||
		failure.NextAttemptAt.Before(failure.FailedAt) ||
		!failure.RetainUntil.Equal(failure.FailedAt.Add(TerminalRetention)) ||
		failure.MaxAttempts < 1 || failure.MaxAttempts > MaxDeliveryAttempts ||
		failure.Lease.Attempt > failure.MaxAttempts {
		return ErrInvalidRequest
	}
	return nil
}

func (failure Failure) MustBecomeDead() bool {
	return failure.Permanent || failure.Lease.Attempt >= failure.MaxAttempts
}

type FailureDisposition string

const (
	FailureRetryScheduled FailureDisposition = "RETRY_SCHEDULED"
	FailureDead           FailureDisposition = "DEAD"
)

func (disposition FailureDisposition) IsValid() bool {
	return disposition == FailureRetryScheduled || disposition == FailureDead
}

type CleanupRequest struct {
	Now   time.Time
	Limit int
}

func (request CleanupRequest) Validate() error {
	if !validOutboxTime(request.Now) || request.Limit < 1 || request.Limit > MaxCleanupBatch {
		return ErrInvalidRequest
	}
	return nil
}

type Repository interface {
	RecoverStaleLeases(context.Context, RecoveryRequest) (RecoveryResult, error)
	ClaimDue(context.Context, ClaimRequest) ([]ClaimedRecord, error)
	MarkDelivered(context.Context, Delivery) error
	MarkFailed(context.Context, Failure) (FailureDisposition, error)
	DeleteExpired(context.Context, CleanupRequest) (int64, error)
}

// Publisher must return only after the broker has acknowledged publication and
// must honor context cancellation. Implementations may be called concurrently.
type Publisher interface {
	Publish(context.Context, Event) error
}
