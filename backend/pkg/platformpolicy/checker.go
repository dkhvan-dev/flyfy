package platformpolicy

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

const (
	DefaultRefreshTimeout = time.Second
	MaximumRefreshTimeout = 5 * time.Second
)

// Clock supports deterministic expiry checks without weakening production
// validation.
type Clock interface {
	Now() time.Time
}

type wallClock struct{}

func (wallClock) Now() time.Time { return time.Now() }

type CheckerConfig struct {
	Source         DecisionSource
	RefreshTimeout time.Duration
	Clock          Clock
}

// Grant is returned only for a currently valid AVAILABLE decision. Revision is
// intended to be retained by a caller and required again at final commit.
type Grant struct {
	Revision   uint64
	ValidUntil time.Time
}

// Checker coalesces on-demand refreshes and enforces one monotonic decision
// stream in memory. It has no persistent cache or background scheduler.
type Checker struct {
	source         DecisionSource
	refreshTimeout time.Duration
	clock          Clock

	mu          sync.Mutex
	decision    Decision
	hasDecision bool
	tainted     bool
	inFlight    *refreshCall
}

type refreshCall struct {
	done     chan struct{}
	decision Decision
	reason   Reason
	cause    error
}

func NewChecker(cfg CheckerConfig) (*Checker, error) {
	if cfg.Source == nil {
		return nil, errors.New("platform policy decision source is required")
	}
	refreshTimeout := cfg.RefreshTimeout
	if refreshTimeout == 0 {
		refreshTimeout = DefaultRefreshTimeout
	}
	if refreshTimeout < 0 || refreshTimeout > MaximumRefreshTimeout {
		return nil, fmt.Errorf("platform policy refresh timeout must be within (0, %s]", MaximumRefreshTimeout)
	}
	clock := cfg.Clock
	if clock == nil {
		clock = wallClock{}
	}
	return &Checker{
		source:         cfg.Source,
		refreshTimeout: refreshTimeout,
		clock:          clock,
	}, nil
}

// Guard grants access only from an unexpired AVAILABLE decision.
func (checker *Checker) Guard(ctx context.Context) (Grant, error) {
	decision, err := checker.resolve(ctx, 0, false, true)
	if err != nil {
		return Grant{}, err
	}
	return grantFromDecision(decision), nil
}

// GuardAtLeast additionally requires a policy revision at least as new as the
// supplied revision.
func (checker *Checker) GuardAtLeast(ctx context.Context, minimumRevision uint64) (Grant, error) {
	decision, err := checker.resolve(ctx, minimumRevision, false, true)
	if err != nil {
		return Grant{}, err
	}
	return grantFromDecision(decision), nil
}

// ValidateCommit performs a fresh, coalesced policy read and requires at least
// minimumRevision. It is intended for the final commit of an operation that
// previously received a Grant.
func (checker *Checker) ValidateCommit(ctx context.Context, minimumRevision uint64) (Grant, error) {
	decision, err := checker.resolve(ctx, minimumRevision, true, true)
	if err != nil {
		return Grant{}, err
	}
	return grantFromDecision(decision), nil
}

// Readiness verifies that enforcement has a current valid decision. A LOCKED
// decision is dependency-ready and is returned with nil error, while Guard and
// ValidateCommit continue to deny access.
func (checker *Checker) Readiness(ctx context.Context) (Decision, error) {
	return checker.resolve(ctx, 0, false, false)
}

func grantFromDecision(decision Decision) Grant {
	return Grant{Revision: decision.Revision, ValidUntil: decision.ValidUntil}
}

func (checker *Checker) resolve(
	ctx context.Context,
	minimumRevision uint64,
	forceRefresh bool,
	requireAvailable bool,
) (Decision, error) {
	if checker == nil || checker.source == nil || checker.clock == nil {
		return Decision{}, newDenial(ReasonUnavailable, errors.New("platform policy checker is unavailable"))
	}
	if ctx == nil {
		return Decision{}, newDenial(ReasonUnavailable, errors.New("platform policy context is nil"))
	}
	if err := ctx.Err(); err != nil {
		return Decision{}, newDenial(ReasonUnavailable, err)
	}

	now := checker.clock.Now()
	checker.mu.Lock()
	if checker.inFlight != nil {
		call := checker.inFlight
		checker.mu.Unlock()
		return checker.await(ctx, call, minimumRevision, requireAvailable)
	}

	if checker.hasDecision {
		cached := checker.decision
		reason, _ := validateDecision(cached, now)
		if requireAvailable && reason == ReasonNone && cached.State == StateLocked {
			checker.mu.Unlock()
			return Decision{}, newDenial(ReasonLocked, nil)
		}
		if !forceRefresh && !checker.tainted && reason == ReasonNone {
			if !requireAvailable || cached.Revision >= minimumRevision {
				checker.mu.Unlock()
				return cached, nil
			}
		}
	}

	call := &refreshCall{done: make(chan struct{})}
	checker.inFlight = call
	refreshBase := context.WithoutCancel(ctx)
	checker.mu.Unlock()

	go checker.refresh(refreshBase, call)
	return checker.await(ctx, call, minimumRevision, requireAvailable)
}

func (checker *Checker) await(
	ctx context.Context,
	call *refreshCall,
	minimumRevision uint64,
	requireAvailable bool,
) (Decision, error) {
	select {
	case <-ctx.Done():
		return Decision{}, newDenial(ReasonUnavailable, ctx.Err())
	case <-call.done:
		if call.reason != ReasonNone {
			return Decision{}, newDenial(call.reason, call.cause)
		}
		if requireAvailable && call.decision.State == StateLocked {
			return Decision{}, newDenial(ReasonLocked, nil)
		}
		if requireAvailable && call.decision.Revision < minimumRevision {
			cause := fmt.Errorf(
				"platform policy revision %d is below required revision %d",
				call.decision.Revision,
				minimumRevision,
			)
			return Decision{}, newDenial(ReasonMinimumRevisionNotMet, cause)
		}
		return call.decision, nil
	}
}

func (checker *Checker) refresh(base context.Context, call *refreshCall) {
	refreshCtx, cancel := context.WithTimeout(base, checker.refreshTimeout)
	decision, err := checker.source.FetchDecision(refreshCtx)
	cancel()

	reason := ReasonNone
	cause := error(nil)
	if err != nil {
		reason = sourceFailureReason(err)
		cause = err
	} else {
		reason, cause = validateDecision(decision, checker.clock.Now())
	}

	checker.mu.Lock()
	defer checker.mu.Unlock()

	if reason == ReasonNone && checker.hasDecision {
		switch {
		case decision.Revision < checker.decision.Revision:
			reason = ReasonRevisionRollback
			cause = fmt.Errorf(
				"platform policy revision rolled back from %d to %d",
				checker.decision.Revision,
				decision.Revision,
			)
		case decision.Revision == checker.decision.Revision && !decisionsEqual(decision, checker.decision):
			reason = ReasonDecisionConflict
			cause = errors.New("platform policy decision changed without a revision advance")
		}
	}

	if reason == ReasonNone {
		if !checker.hasDecision || decision.Revision > checker.decision.Revision {
			checker.decision = decision
			checker.hasDecision = true
		} else {
			decision = checker.decision
		}
		checker.tainted = false
	} else {
		checker.tainted = true
	}

	call.decision = decision
	call.reason = reason
	call.cause = cause
	checker.inFlight = nil
	close(call.done)
}

func sourceFailureReason(err error) Reason {
	var fetchErr *FetchError
	if errors.As(err, &fetchErr) {
		switch fetchErr.Kind() {
		case FetchFailureMalformed, FetchFailureOversized:
			return ReasonMalformed
		}
	}
	return ReasonUnavailable
}
