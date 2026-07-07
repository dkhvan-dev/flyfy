package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/auth-service/internal/config"
)

func TestValidateAuthServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateAuthServiceMTLSPort(config.Config{}, nil); err != nil {
		t.Fatalf("validateAuthServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateAuthServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateAuthServiceMTLSPort(
		config.Config{HTTPPort: 8082},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateAuthServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateAuthServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateAuthServiceMTLSPort(
		config.Config{HTTPPort: 8082, InternalHTTPTLSPort: 8082},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateAuthServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalAuthMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalAuthMTLSServer(config.Config{
		HTTPPort:            8082,
		InternalHTTPTLSPort: 9482,
	}, http.NewServeMux(), tlsConfig)

	if server == nil {
		t.Fatal("newInternalAuthMTLSServer() = nil, want server")
	}
	if server.Addr != ":9482" {
		t.Fatalf("server addr = %q, want :9482", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 5*time.Second || server.WriteTimeout != 10*time.Second || server.IdleTimeout != 30*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 5s/10s/30s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
