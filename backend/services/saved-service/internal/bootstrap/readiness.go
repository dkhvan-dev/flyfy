package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"time"

	"google.golang.org/grpc/connectivity"

	"kz/inflap/backend/pkg/platformpolicy"
	"kz/inflap/backend/pkg/serviceauth"
)

var ErrDependencyNotReady = errors.New("saved-service dependency is not ready")

type DatabasePinger interface {
	Ping(context.Context) error
}

type policyReadiness interface {
	Readiness(context.Context) (platformpolicy.Decision, error)
}

type grpcConnectivity interface {
	GetState() connectivity.State
	Connect()
	WaitForStateChange(context.Context, connectivity.State) bool
}

type readinessProbe struct {
	name    string
	timeout time.Duration
	check   func(context.Context) error
}

type Readiness struct {
	probes []readinessProbe
}

func newReadiness(
	database DatabasePinger,
	policy policyReadiness,
	tokens serviceauth.TokenSource,
	connectTimeout time.Duration,
	connections []namedGRPCConnection,
) (*Readiness, error) {
	if database == nil || policy == nil || tokens == nil || connectTimeout <= 0 {
		return nil, errors.New("invalid readiness dependencies")
	}
	probes := []readinessProbe{
		{
			name:    "postgres",
			timeout: connectTimeout,
			check:   database.Ping,
		},
		{
			name:    "platform-policy",
			timeout: connectTimeout,
			check: func(ctx context.Context) error {
				_, err := policy.Readiness(ctx)
				return err
			},
		},
		{
			name:    "service-token",
			timeout: connectTimeout,
			check: func(ctx context.Context) error {
				_, err := tokens.Token(ctx)
				return err
			},
		},
	}
	for _, connection := range connections {
		if connection.name == "" || connection.connection == nil {
			return nil, errors.New("invalid readiness gRPC connection")
		}
		current := connection
		probes = append(probes, readinessProbe{
			name:    current.name,
			timeout: connectTimeout,
			check: func(ctx context.Context) error {
				return waitForGRPCReady(ctx, current.connection)
			},
		})
	}
	return &Readiness{probes: probes}, nil
}

func (readiness *Readiness) Check(ctx context.Context) error {
	if ctx == nil || readiness == nil || len(readiness.probes) == 0 {
		return ErrDependencyNotReady
	}
	for _, probe := range readiness.probes {
		if err := ctx.Err(); err != nil {
			return fmt.Errorf("%w: %s", ErrDependencyNotReady, probe.name)
		}
		probeCtx, cancel := context.WithTimeout(ctx, probe.timeout)
		err := probe.check(probeCtx)
		cancel()
		if err != nil {
			return fmt.Errorf("%w: %s", ErrDependencyNotReady, probe.name)
		}
	}
	return nil
}

func (readiness *Readiness) Names() []string {
	if readiness == nil {
		return nil
	}
	names := make([]string, 0, len(readiness.probes))
	for _, probe := range readiness.probes {
		names = append(names, probe.name)
	}
	return names
}

func waitForGRPCReady(ctx context.Context, connection grpcConnectivity) error {
	if ctx == nil || connection == nil {
		return ErrDependencyNotReady
	}
	connection.Connect()
	for {
		state := connection.GetState()
		switch state {
		case connectivity.Ready:
			return nil
		case connectivity.Shutdown:
			return ErrDependencyNotReady
		}
		if !connection.WaitForStateChange(ctx, state) {
			return ErrDependencyNotReady
		}
	}
}
