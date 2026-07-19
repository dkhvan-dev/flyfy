package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/connectivity"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/transportauth"
	authadapter "kz/inflap/backend/services/saved-service/internal/adapter/auth"
	"kz/inflap/backend/services/saved-service/internal/config"
)

type databaseStub struct {
	err error
}

func (stub databaseStub) Ping(context.Context) error {
	return stub.err
}

type tokenSourceStub struct {
	token      string
	closeName  string
	closeOrder *[]string
	closeCount int
}

func (stub *tokenSourceStub) Token(context.Context) (string, error) {
	return stub.token, nil
}

func (stub *tokenSourceStub) Close() error {
	stub.closeCount++
	if stub.closeOrder != nil {
		*stub.closeOrder = append(*stub.closeOrder, stub.closeName)
	}
	return nil
}

type connectionStub struct {
	name       string
	closeOrder *[]string
	closeCount int
	state      connectivity.State
}

func (*connectionStub) Invoke(context.Context, string, any, any, ...grpc.CallOption) error {
	return nil
}

func (*connectionStub) NewStream(
	context.Context,
	*grpc.StreamDesc,
	string,
	...grpc.CallOption,
) (grpc.ClientStream, error) {
	return nil, errors.New("streaming is unsupported")
}

func (stub *connectionStub) GetState() connectivity.State {
	if stub.state == connectivity.Idle {
		return connectivity.Ready
	}
	return stub.state
}

func (*connectionStub) Connect() {}

func (*connectionStub) WaitForStateChange(context.Context, connectivity.State) bool {
	return true
}

func (stub *connectionStub) Close() error {
	stub.closeCount++
	if stub.closeOrder != nil {
		*stub.closeOrder = append(*stub.closeOrder, stub.name)
	}
	return nil
}

type transportStub struct {
	name       string
	closeOrder *[]string
	closeCount int
}

func (*transportStub) RoundTrip(*http.Request) (*http.Response, error) {
	return nil, errors.New("network is disabled in bootstrap unit tests")
}

func (stub *transportStub) CloseIdleConnections() {
	stub.closeCount++
	if stub.closeOrder != nil {
		*stub.closeOrder = append(*stub.closeOrder, stub.name)
	}
}

type bearerVerifierStub struct{}

func (bearerVerifierStub) ValidateBearer(
	context.Context,
	string,
	[]string,
) (*serviceauth.Claims, error) {
	return &serviceauth.Claims{Subject: config.GatewaySubject}, nil
}

func TestNewBuildsDependenciesAndClosesInReverseOrder(t *testing.T) {
	cfg := developmentConfig(t)
	var closeOrder []string
	tokenSource := &tokenSourceStub{
		token:      "service-token",
		closeName:  "service-token",
		closeOrder: &closeOrder,
	}
	connections := make([]*connectionStub, 0, 5)
	transports := make([]*transportStub, 0, 3)
	var verifierConfig serviceauth.VerifierConfig

	hooks := buildHooks{
		newTokenSource: func(received serviceauth.TokenSourceConfig, _ ...grpc.DialOption) (serviceTokenSource, error) {
			if received.ServiceID != "saved-service" || received.ServiceSecret == "" {
				t.Fatalf("unexpected token source config: service_id=%q", received.ServiceID)
			}
			return tokenSource, nil
		},
		dialGRPC: func(_ string, _ ...grpc.DialOption) (grpcConnection, error) {
			names := []string{"token-session", "attraction-source", "activity-source", "user-source", "post-source"}
			connection := &connectionStub{name: names[len(connections)], closeOrder: &closeOrder}
			connections = append(connections, connection)
			return connection, nil
		},
		newHTTPTransport: func(transportauth.Config) (managedHTTPTransport, error) {
			names := []string{"gateway-jwks-http", "user-access-http", "platform-policy-http"}
			transport := &transportStub{name: names[len(transports)], closeOrder: &closeOrder}
			transports = append(transports, transport)
			return transport, nil
		},
		newVerifier: func(received serviceauth.VerifierConfig) (authadapter.BearerVerifier, error) {
			verifierConfig = received
			return bearerVerifierStub{}, nil
		},
	}

	dependencies, err := newWithHooks(cfg, databaseStub{}, hooks)
	if err != nil {
		t.Fatalf("newWithHooks() error = %v", err)
	}
	if dependencies.ServiceTokens == nil || dependencies.Sources == nil ||
		dependencies.SessionValidator == nil || dependencies.PlatformPolicy == nil ||
		dependencies.PolicyGate == nil ||
		dependencies.OperationHMAC == nil || dependencies.CursorCodec == nil ||
		dependencies.GatewayAuthorizer == nil || dependencies.UserAccess == nil ||
		dependencies.Readiness == nil {
		t.Fatalf("incomplete dependencies: %+v", dependencies)
	}
	if len(connections) != 5 || len(transports) != 3 {
		t.Fatalf("connections/transports = %d/%d, want 5/3", len(connections), len(transports))
	}
	if verifierConfig.Issuer != cfg.GatewayAuth.Issuer ||
		verifierConfig.JWKSURL != cfg.GatewayAuth.JWKSURL ||
		verifierConfig.Client == nil || verifierConfig.Client.Timeout != cfg.GatewayAuth.HTTPTimeout {
		t.Fatalf("unexpected verifier config: issuer=%q url=%q", verifierConfig.Issuer, verifierConfig.JWKSURL)
	}
	request, requestErr := http.NewRequest(http.MethodGet, "https://elsewhere.invalid", nil)
	if requestErr != nil {
		t.Fatal(requestErr)
	}
	if redirectErr := verifierConfig.Client.CheckRedirect(request, nil); !errors.Is(redirectErr, http.ErrUseLastResponse) {
		t.Fatalf("JWKS redirect policy error = %v", redirectErr)
	}
	wantReadiness := []string{
		"postgres",
		"platform-policy",
		"service-token",
		"token-session",
		"attraction-source",
		"activity-source",
		"user-source",
		"post-source",
	}
	if got := fmt.Sprint(dependencies.Readiness.Names()); got != fmt.Sprint(wantReadiness) {
		t.Fatalf("readiness names = %s, want %v", got, wantReadiness)
	}

	if err := dependencies.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}
	if err := dependencies.Close(); err != nil {
		t.Fatalf("second Close() error = %v", err)
	}
	wantCloseOrder := []string{
		"platform-policy-http",
		"user-access-http",
		"gateway-jwks-http",
		"post-source",
		"user-source",
		"activity-source",
		"attraction-source",
		"token-session",
		"service-token",
	}
	if got := fmt.Sprint(closeOrder); got != fmt.Sprint(wantCloseOrder) {
		t.Fatalf("close order = %s, want %v", got, wantCloseOrder)
	}
	if tokenSource.closeCount != 1 {
		t.Fatalf("token source close count = %d", tokenSource.closeCount)
	}
	for _, connection := range connections {
		if connection.closeCount != 1 {
			t.Fatalf("%s close count = %d", connection.name, connection.closeCount)
		}
	}
	for _, transport := range transports {
		if transport.closeCount != 1 {
			t.Fatalf("%s close count = %d", transport.name, transport.closeCount)
		}
	}
}

func TestNewCleansUpPartialConstructionFailure(t *testing.T) {
	cfg := developmentConfig(t)
	var closeOrder []string
	tokenSource := &tokenSourceStub{
		token:      "service-token",
		closeName:  "service-token",
		closeOrder: &closeOrder,
	}
	firstConnection := &connectionStub{name: "token-session", closeOrder: &closeOrder}
	dialCount := 0
	hooks := buildHooks{
		newTokenSource: func(serviceauth.TokenSourceConfig, ...grpc.DialOption) (serviceTokenSource, error) {
			return tokenSource, nil
		},
		dialGRPC: func(string, ...grpc.DialOption) (grpcConnection, error) {
			dialCount++
			if dialCount == 1 {
				return firstConnection, nil
			}
			return nil, errors.New("injected dial failure")
		},
		newHTTPTransport: func(transportauth.Config) (managedHTTPTransport, error) {
			return &transportStub{}, nil
		},
		newVerifier: func(serviceauth.VerifierConfig) (authadapter.BearerVerifier, error) {
			return bearerVerifierStub{}, nil
		},
	}

	dependencies, err := newWithHooks(cfg, databaseStub{}, hooks)
	if err == nil || dependencies != nil {
		t.Fatalf("newWithHooks() = (%v, %v), want failure", dependencies, err)
	}
	if got := fmt.Sprint(closeOrder); got != "[token-session service-token]" {
		t.Fatalf("partial cleanup order = %s", got)
	}
	if firstConnection.closeCount != 1 || tokenSource.closeCount != 1 {
		t.Fatalf("partial cleanup counts = connection:%d token:%d", firstConnection.closeCount, tokenSource.closeCount)
	}
	for _, secret := range []string{
		cfg.TokenService.ServiceSecret.Value(),
		cfg.PlatformPolicy.InternalServiceToken.Value(),
	} {
		if strings.Contains(err.Error(), secret) {
			t.Fatalf("constructor error disclosed secret: %v", err)
		}
	}
}

func TestBoundedUnaryClientInterceptorPreservesShorterDeadline(t *testing.T) {
	interceptor := boundedUnaryClientInterceptor(2)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	called := false
	err := interceptor(
		ctx,
		"/saved.test/Method",
		nil,
		nil,
		nil,
		func(callCtx context.Context, _ string, _ any, _ any, _ *grpc.ClientConn, _ ...grpc.CallOption) error {
			called = true
			return callCtx.Err()
		},
	)
	if !called || !errors.Is(err, context.Canceled) {
		t.Fatalf("interceptor called/error = %v/%v", called, err)
	}
}

func developmentConfig(t *testing.T) *config.Config {
	t.Helper()
	t.Setenv("APP_NAME", "saved-service")
	t.Setenv("APP_ENV", "test")
	t.Setenv("POSTGRES_PASSWORD", "test-only-postgres-password")
	t.Setenv("MTLS_MODE", "disabled")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "0")
	cfg, err := config.Load(context.Background())
	if err != nil {
		t.Fatalf("config.Load() error = %v", err)
	}
	return cfg
}
