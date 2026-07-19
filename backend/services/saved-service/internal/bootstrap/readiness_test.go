package bootstrap

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc/connectivity"

	"kz/inflap/backend/pkg/platformpolicy"
)

type policyReadinessStub struct {
	err error
}

func (stub policyReadinessStub) Readiness(context.Context) (platformpolicy.Decision, error) {
	return platformpolicy.Decision{
		Revision:   1,
		State:      platformpolicy.StateAvailable,
		IssuedAt:   time.Now().UTC(),
		ValidUntil: time.Now().UTC().Add(time.Minute),
	}, stub.err
}

func TestReadinessChecksDatabasePolicyTokenAndGRPC(t *testing.T) {
	tokenSource := &tokenSourceStub{token: "service-token"}
	connections := []namedGRPCConnection{
		{name: "source", connection: &connectionStub{state: connectivity.Ready}},
	}
	readiness, err := newReadiness(
		databaseStub{},
		policyReadinessStub{},
		tokenSource,
		time.Second,
		connections,
	)
	if err != nil {
		t.Fatalf("newReadiness() error = %v", err)
	}
	if err := readiness.Check(context.Background()); err != nil {
		t.Fatalf("Check() error = %v", err)
	}
}

func TestReadinessReturnsSanitizedDependencyFailure(t *testing.T) {
	sensitive := "postgres-host-and-credential-detail"
	readiness, err := newReadiness(
		databaseStub{err: errors.New(sensitive)},
		policyReadinessStub{},
		&tokenSourceStub{token: "service-token"},
		time.Second,
		nil,
	)
	if err != nil {
		t.Fatalf("newReadiness() error = %v", err)
	}
	checkErr := readiness.Check(context.Background())
	if !errors.Is(checkErr, ErrDependencyNotReady) {
		t.Fatalf("Check() error = %v", checkErr)
	}
	if strings.Contains(checkErr.Error(), sensitive) {
		t.Fatalf("Check() disclosed dependency error: %v", checkErr)
	}
}
