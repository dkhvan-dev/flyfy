package policy

import (
	"context"
	"errors"
	"testing"
	"time"

	"kz/inflap/backend/pkg/platformpolicy"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type decisionSourceFunc func(context.Context) (platformpolicy.Decision, error)

func (source decisionSourceFunc) FetchDecision(ctx context.Context) (platformpolicy.Decision, error) {
	return source(ctx)
}

type checkerStub struct {
	guardGrant      platformpolicy.Grant
	guardErr        error
	commitGrant     platformpolicy.Grant
	commitErr       error
	minimumRevision uint64
}

func (stub *checkerStub) Guard(context.Context) (platformpolicy.Grant, error) {
	return stub.guardGrant, stub.guardErr
}

func (stub *checkerStub) ValidateCommit(
	_ context.Context,
	minimumRevision uint64,
) (platformpolicy.Grant, error) {
	stub.minimumRevision = minimumRevision
	return stub.commitGrant, stub.commitErr
}

func TestGateReturnsSavedPolicyGrant(t *testing.T) {
	checker := &checkerStub{
		guardGrant:  platformpolicy.Grant{Revision: 41},
		commitGrant: platformpolicy.Grant{Revision: 42},
	}
	gate, err := NewGate(checker)
	if err != nil {
		t.Fatalf("NewGate() error = %v", err)
	}
	grant, err := gate.Guard(context.Background())
	if err != nil {
		t.Fatalf("Guard() error = %v", err)
	}
	if grant.Revision != 41 {
		t.Fatalf("Guard() revision = %d, want 41", grant.Revision)
	}
	if err := gate.ValidateCommit(context.Background(), 41); err != nil {
		t.Fatalf("ValidateCommit() error = %v", err)
	}
	if checker.minimumRevision != 41 {
		t.Fatalf("minimum revision = %d, want 41", checker.minimumRevision)
	}
}

func TestGateMapsLockedToStableDomainError(t *testing.T) {
	gate := gateWithDecision(t, platformpolicy.StateLocked, nil)

	_, err := gate.Guard(context.Background())
	if !errors.Is(err, domain.ErrPlatformPersonalDataLocked) {
		t.Fatalf("Guard() error = %v, want platform lock", err)
	}
	assertSafeDomainError(t, err)
}

func TestGateMapsEveryOtherFailureToDependencyUnavailable(t *testing.T) {
	t.Run("policy dependency denial", func(t *testing.T) {
		gate := gateWithDecision(t, platformpolicy.StateAvailable, errors.New("sensitive upstream detail"))
		_, err := gate.Guard(context.Background())
		if !errors.Is(err, domain.ErrDependencyUnavailable) {
			t.Fatalf("Guard() error = %v, want dependency unavailable", err)
		}
		assertSafeDomainError(t, err)
	})

	t.Run("unexpected checker error", func(t *testing.T) {
		gate, err := NewGate(&checkerStub{guardErr: errors.New("unexpected sensitive error")})
		if err != nil {
			t.Fatalf("NewGate() error = %v", err)
		}
		_, guardErr := gate.Guard(context.Background())
		if !errors.Is(guardErr, domain.ErrDependencyUnavailable) {
			t.Fatalf("Guard() error = %v, want dependency unavailable", guardErr)
		}
		assertSafeDomainError(t, guardErr)
	})

	t.Run("zero grant", func(t *testing.T) {
		gate, err := NewGate(&checkerStub{})
		if err != nil {
			t.Fatalf("NewGate() error = %v", err)
		}
		_, guardErr := gate.Guard(context.Background())
		if !errors.Is(guardErr, domain.ErrDependencyUnavailable) {
			t.Fatalf("Guard() error = %v, want dependency unavailable", guardErr)
		}
	})
}

func TestGateValidateCommitMapsLockAndRejectsBrokenGrant(t *testing.T) {
	t.Run("locked", func(t *testing.T) {
		gate := gateWithDecision(t, platformpolicy.StateLocked, nil)
		err := gate.ValidateCommit(context.Background(), 1)
		if !errors.Is(err, domain.ErrPlatformPersonalDataLocked) {
			t.Fatalf("ValidateCommit() error = %v, want platform lock", err)
		}
		assertSafeDomainError(t, err)
	})

	t.Run("revision below minimum", func(t *testing.T) {
		gate, err := NewGate(&checkerStub{commitGrant: platformpolicy.Grant{Revision: 7}})
		if err != nil {
			t.Fatalf("NewGate() error = %v", err)
		}
		commitErr := gate.ValidateCommit(context.Background(), 8)
		if !errors.Is(commitErr, domain.ErrDependencyUnavailable) {
			t.Fatalf("ValidateCommit() error = %v, want dependency unavailable", commitErr)
		}
		assertSafeDomainError(t, commitErr)
	})
}

func gateWithDecision(
	t *testing.T,
	state platformpolicy.State,
	sourceErr error,
) *Gate {
	t.Helper()
	now := time.Now().UTC()
	checker, err := platformpolicy.NewChecker(platformpolicy.CheckerConfig{
		Source: decisionSourceFunc(func(context.Context) (platformpolicy.Decision, error) {
			if sourceErr != nil {
				return platformpolicy.Decision{}, sourceErr
			}
			return platformpolicy.Decision{
				Revision:   1,
				State:      state,
				IssuedAt:   now,
				ValidUntil: now.Add(20 * time.Second),
			}, nil
		}),
	})
	if err != nil {
		t.Fatalf("platformpolicy.NewChecker() error = %v", err)
	}
	gate, err := NewGate(checker)
	if err != nil {
		t.Fatalf("NewGate() error = %v", err)
	}
	return gate
}

func assertSafeDomainError(t *testing.T, err error) {
	t.Helper()
	var domainError *domain.DomainError
	if !errors.As(err, &domainError) {
		t.Fatalf("error type = %T, want *domain.DomainError", err)
	}
}
