package natstransport

import (
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/nats-io/nats.go"
)

func TestConnectionOptionsAreExplicitlyBounded(t *testing.T) {
	t.Parallel()

	env := boundedEnvConfig()
	env.URLs = "nats://localhost:4222"
	cfg, err := env.Build("development", "")
	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	prepared, err := cfg.prepare()
	if err != nil {
		t.Fatalf("prepare() error = %v", err)
	}
	options := nats.GetDefaultOptions()
	for _, option := range connectionOptions(cfg, prepared, "activity-service-saved-lifecycle", Hooks{}) {
		if err = option(&options); err != nil {
			t.Fatalf("apply option: %v", err)
		}
	}
	if options.Name != "activity-service-saved-lifecycle" ||
		options.Timeout != 3*time.Second ||
		options.ReconnectWait != time.Second ||
		options.MaxReconnect != 30 ||
		options.ReconnectJitter != 100*time.Millisecond ||
		options.ReconnectJitterTLS != 500*time.Millisecond ||
		options.ReconnectBufSize != 1024*1024 ||
		options.PingInterval != 20*time.Second ||
		options.MaxPingsOut != 2 ||
		options.DrainTimeout != 5*time.Second ||
		!options.RetryOnFailedConnect {
		t.Fatalf("unexpected NATS options: %+v", options)
	}
}

func TestSecureConnectionOptionsUseTLS13AndCredentials(t *testing.T) {
	t.Parallel()

	fixture := newSecureFixture(t)
	cfg, err := fixture.env.Build("staging", "")
	if err != nil {
		t.Fatalf("Build() error = %v", err)
	}
	prepared, err := cfg.prepare()
	if err != nil {
		t.Fatalf("prepare() error = %v", err)
	}
	options := nats.GetDefaultOptions()
	for _, option := range connectionOptions(cfg, prepared, "guide-service-saved-lifecycle", Hooks{}) {
		if err = option(&options); err != nil {
			t.Fatalf("apply option: %v", err)
		}
	}
	if !options.Secure || options.TLSConfig == nil || options.TLSConfig.MinVersion != 0x0304 {
		t.Fatal("secure options do not enforce TLS 1.3")
	}
	if options.UserJWT == nil || options.SignatureCB == nil {
		t.Fatal("NATS credentials callbacks are not configured")
	}
}

func TestSanitizedErrorsNeverRetainSourceDetails(t *testing.T) {
	t.Parallel()

	secret := "nats://user:password@private.internal /run/secrets/nats.creds"
	err := sanitizeError(secret, errors.New(secret))
	formatted := fmt.Sprintf("%s %v %#v", err, err, err)
	for _, value := range []string{"user", "password", "private.internal", "/run/secrets"} {
		if strings.Contains(formatted, value) {
			t.Fatalf("sanitized error leaked %q: %s", value, formatted)
		}
	}
	var transportError *Error
	if !errors.As(err, &transportError) || transportError.Code() != ErrorTransport {
		t.Fatalf("sanitized error = %#v", err)
	}
	if errors.Unwrap(err) != nil {
		t.Fatal("sanitized error retained its source error")
	}
}

func TestConnectRejectsInvalidConfigWithoutEchoingSecrets(t *testing.T) {
	t.Parallel()

	secret := "nats://user:password@private.internal:4222"
	env := boundedEnvConfig()
	env.URLs = secret
	cfg := Config{
		Environment:    "development",
		URLs:           env.URLs,
		TLSMinVersion:  env.TLSMinVersion,
		ConnectTimeout: env.ConnectTimeout,
		ReconnectWait:  env.ReconnectWait,
		MaxReconnects:  env.MaxReconnects,
		PingInterval:   env.PingInterval,
		MaxPingsOut:    env.MaxPingsOut,
		DrainTimeout:   env.DrainTimeout,
	}
	_, err := Connect(cfg, "place-service-saved-lifecycle", Hooks{})
	if err == nil {
		t.Fatal("Connect() error = nil, want rejection")
	}
	if strings.Contains(err.Error(), "password") || strings.Contains(err.Error(), "private.internal") {
		t.Fatalf("Connect() error leaked config: %v", err)
	}
}

func TestDrainNilConnection(t *testing.T) {
	t.Parallel()

	if err := Drain(nil); err != nil {
		t.Fatalf("Drain(nil) error = %v", err)
	}
}
