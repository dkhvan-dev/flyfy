package platformpolicy

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func TestCheckerFreshAvailable(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	source := &scriptedSource{steps: []sourceStep{{decision: testDecision(now, 7, StateAvailable)}}}
	checker := newTestChecker(t, source, newFakeClock(now))

	grant, err := checker.Guard(context.Background())
	if err != nil {
		t.Fatalf("Guard() error = %v", err)
	}
	if grant.Revision != 7 {
		t.Fatalf("Guard() revision = %d, want 7", grant.Revision)
	}
	if !grant.ValidUntil.Equal(now.Add(10 * time.Second)) {
		t.Fatalf("Guard() valid until = %s, want %s", grant.ValidUntil, now.Add(10*time.Second))
	}
	if got := source.callCount(); got != 1 {
		t.Fatalf("source calls = %d, want 1", got)
	}

	if _, err := checker.Guard(context.Background()); err != nil {
		t.Fatalf("cached Guard() error = %v", err)
	}
	if got := source.callCount(); got != 1 {
		t.Fatalf("source calls after cached guard = %d, want 1", got)
	}
}

func TestCheckerExplicitLock(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 1, 0, 0, time.UTC)
	decision := testDecision(now, 8, StateLocked)
	source := &scriptedSource{steps: []sourceStep{{decision: decision}}}
	checker := newTestChecker(t, source, newFakeClock(now))

	_, err := checker.Guard(context.Background())
	requireDenialReason(t, err, ReasonLocked)

	readyDecision, err := checker.Readiness(context.Background())
	if err != nil {
		t.Fatalf("Readiness() error = %v", err)
	}
	if !decisionsEqual(readyDecision, decision) {
		t.Fatalf("Readiness() decision = %#v, want %#v", readyDecision, decision)
	}
	if got := source.callCount(); got != 1 {
		t.Fatalf("source calls = %d, want 1", got)
	}
}

func TestCheckerInitialOutageFailsClosed(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 2, 0, 0, time.UTC)
	source := &scriptedSource{steps: []sourceStep{{err: errors.New("dependency unavailable")}}}
	checker := newTestChecker(t, source, newFakeClock(now))

	_, err := checker.Guard(context.Background())
	requireDenialReason(t, err, ReasonUnavailable)
}

func TestCheckerStaleResponseFailsClosed(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 2, 30, 0, time.UTC)
	stale := testDecision(now.Add(-20*time.Second), 9, StateAvailable)
	source := &scriptedSource{steps: []sourceStep{{decision: stale}}}
	checker := newTestChecker(t, source, newFakeClock(now))

	_, err := checker.Guard(context.Background())
	requireDenialReason(t, err, ReasonStale)
}

func TestCheckerMalformedResponseFailsClosed(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 2, 45, 0, time.UTC)
	malformed := testDecision(now, 0, StateAvailable)
	source := &scriptedSource{steps: []sourceStep{{decision: malformed}}}
	checker := newTestChecker(t, source, newFakeClock(now))

	_, err := checker.Guard(context.Background())
	requireDenialReason(t, err, ReasonMalformed)
}

func TestCheckerExpiredAvailableWithOutageFailsClosed(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 3, 0, 0, time.UTC)
	clock := newFakeClock(now)
	source := &scriptedSource{steps: []sourceStep{
		{decision: testDecision(now, 9, StateAvailable)},
		{err: errors.New("dependency unavailable")},
	}}
	checker := newTestChecker(t, source, clock)

	if _, err := checker.Guard(context.Background()); err != nil {
		t.Fatalf("initial Guard() error = %v", err)
	}
	clock.Advance(11 * time.Second)

	_, err := checker.Guard(context.Background())
	requireDenialReason(t, err, ReasonUnavailable)
	if got := source.callCount(); got != 2 {
		t.Fatalf("source calls = %d, want 2", got)
	}
}

func TestCheckerMonotonicAdvanceOnCommitValidation(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 4, 0, 0, time.UTC)
	source := &scriptedSource{steps: []sourceStep{
		{decision: testDecision(now, 10, StateAvailable)},
		{decision: testDecision(now, 11, StateAvailable)},
	}}
	checker := newTestChecker(t, source, newFakeClock(now))

	started, err := checker.Guard(context.Background())
	if err != nil {
		t.Fatalf("Guard() error = %v", err)
	}
	committed, err := checker.ValidateCommit(context.Background(), started.Revision)
	if err != nil {
		t.Fatalf("ValidateCommit() error = %v", err)
	}
	if committed.Revision != 11 {
		t.Fatalf("ValidateCommit() revision = %d, want 11", committed.Revision)
	}
	if got := source.callCount(); got != 2 {
		t.Fatalf("source calls = %d, want forced commit refresh", got)
	}
}

func TestCheckerRejectsRevisionRollbackAndTaintsPriorAllow(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 5, 0, 0, time.UTC)
	source := &scriptedSource{steps: []sourceStep{
		{decision: testDecision(now, 12, StateAvailable)},
		{decision: testDecision(now, 11, StateAvailable)},
		{decision: testDecision(now, 13, StateAvailable)},
	}}
	checker := newTestChecker(t, source, newFakeClock(now))

	if _, err := checker.Guard(context.Background()); err != nil {
		t.Fatalf("initial Guard() error = %v", err)
	}
	_, err := checker.ValidateCommit(context.Background(), 12)
	requireDenialReason(t, err, ReasonRevisionRollback)

	grant, err := checker.Guard(context.Background())
	if err != nil {
		t.Fatalf("Guard() after rollback error = %v", err)
	}
	if grant.Revision != 13 {
		t.Fatalf("Guard() after rollback revision = %d, want 13", grant.Revision)
	}
	if got := source.callCount(); got != 3 {
		t.Fatalf("source calls = %d, want tainted cache refresh", got)
	}
}

func TestCheckerRejectsSameRevisionDecisionChange(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 6, 0, 0, time.UTC)
	available := testDecision(now, 14, StateAvailable)
	locked := available
	locked.State = StateLocked
	source := &scriptedSource{steps: []sourceStep{
		{decision: available},
		{decision: locked},
	}}
	checker := newTestChecker(t, source, newFakeClock(now))

	if _, err := checker.Guard(context.Background()); err != nil {
		t.Fatalf("initial Guard() error = %v", err)
	}
	_, err := checker.ValidateCommit(context.Background(), available.Revision)
	requireDenialReason(t, err, ReasonDecisionConflict)
}

func TestCheckerConcurrentRefreshCoalescing(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 7, 0, 0, time.UTC)
	source := &blockingSource{
		decision: testDecision(now, 15, StateAvailable),
		started:  make(chan struct{}),
		release:  make(chan struct{}),
	}
	checker := newTestChecker(t, source, newFakeClock(now))

	const callers = 32
	start := make(chan struct{})
	results := make(chan error, callers)
	var ready sync.WaitGroup
	ready.Add(callers)
	for range callers {
		go func() {
			ready.Done()
			<-start
			_, err := checker.Guard(context.Background())
			results <- err
		}()
	}
	ready.Wait()
	close(start)

	select {
	case <-source.started:
	case <-time.After(time.Second):
		t.Fatal("policy refresh did not start")
	}
	close(source.release)

	for range callers {
		if err := <-results; err != nil {
			t.Fatalf("concurrent Guard() error = %v", err)
		}
	}
	if got := source.calls.Load(); got != 1 {
		t.Fatalf("source calls = %d, want 1", got)
	}
}

func TestCheckerRequiredMinimumRevision(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 8, 0, 0, time.UTC)
	revision16 := testDecision(now, 16, StateAvailable)
	source := &scriptedSource{steps: []sourceStep{
		{decision: revision16},
		{decision: revision16},
		{decision: testDecision(now, 17, StateAvailable)},
	}}
	checker := newTestChecker(t, source, newFakeClock(now))

	if _, err := checker.Guard(context.Background()); err != nil {
		t.Fatalf("initial Guard() error = %v", err)
	}
	_, err := checker.GuardAtLeast(context.Background(), 17)
	requireDenialReason(t, err, ReasonMinimumRevisionNotMet)

	grant, err := checker.GuardAtLeast(context.Background(), 17)
	if err != nil {
		t.Fatalf("second GuardAtLeast() error = %v", err)
	}
	if grant.Revision != 17 {
		t.Fatalf("second GuardAtLeast() revision = %d, want 17", grant.Revision)
	}
}

func newTestChecker(t *testing.T, source DecisionSource, clock Clock) *Checker {
	t.Helper()
	checker, err := NewChecker(CheckerConfig{
		Source:         source,
		RefreshTimeout: time.Second,
		Clock:          clock,
	})
	if err != nil {
		t.Fatalf("NewChecker() error = %v", err)
	}
	return checker
}

func testDecision(now time.Time, revision uint64, state State) Decision {
	return Decision{
		Revision:   revision,
		State:      state,
		IssuedAt:   now.Add(-time.Second),
		ValidUntil: now.Add(10 * time.Second),
	}
}

func requireDenialReason(t *testing.T, err error, want Reason) {
	t.Helper()
	if err == nil {
		t.Fatalf("error = nil, want denial reason %s", want)
	}
	if !errors.Is(err, ErrDenied) {
		t.Fatalf("errors.Is(error, ErrDenied) = false: %v", err)
	}
	if err.Error() != ExternalDenialCode {
		t.Fatalf("external error = %q, want %q", err.Error(), ExternalDenialCode)
	}
	got, ok := DenialReason(err)
	if !ok {
		t.Fatalf("DenialReason(%v) did not find a reason", err)
	}
	if got != want {
		t.Fatalf("denial reason = %s, want %s", got, want)
	}
	if (want != ReasonLocked) != got.DependencyFailure() {
		t.Fatalf("DependencyFailure() = %t for reason %s", got.DependencyFailure(), got)
	}
}

type fakeClock struct {
	mu  sync.RWMutex
	now time.Time
}

func newFakeClock(now time.Time) *fakeClock {
	return &fakeClock{now: now}
}

func (clock *fakeClock) Now() time.Time {
	clock.mu.RLock()
	defer clock.mu.RUnlock()
	return clock.now
}

func (clock *fakeClock) Advance(duration time.Duration) {
	clock.mu.Lock()
	defer clock.mu.Unlock()
	clock.now = clock.now.Add(duration)
}

type sourceStep struct {
	decision Decision
	err      error
}

type scriptedSource struct {
	mu    sync.Mutex
	steps []sourceStep
	calls int
}

func (source *scriptedSource) FetchDecision(context.Context) (Decision, error) {
	source.mu.Lock()
	defer source.mu.Unlock()
	index := source.calls
	source.calls++
	if index >= len(source.steps) {
		return Decision{}, errors.New("unexpected policy source call")
	}
	step := source.steps[index]
	return step.decision, step.err
}

func (source *scriptedSource) callCount() int {
	source.mu.Lock()
	defer source.mu.Unlock()
	return source.calls
}

type blockingSource struct {
	decision Decision
	started  chan struct{}
	release  chan struct{}
	once     sync.Once
	calls    atomic.Int64
}

func (source *blockingSource) FetchDecision(ctx context.Context) (Decision, error) {
	source.calls.Add(1)
	source.once.Do(func() { close(source.started) })
	select {
	case <-ctx.Done():
		return Decision{}, ctx.Err()
	case <-source.release:
		return source.decision, nil
	}
}
