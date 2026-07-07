package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/activity-service/internal/config"
)

func TestValidateActivityServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateActivityServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateActivityServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateActivityServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateActivityServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9096}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateActivityServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_GRPC_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateActivityServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateActivityServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9096, InternalTLSPort: 9096}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateActivityServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from GRPC_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestValidateActivityServiceMTLSPortRequiresHTTPDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateActivityServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9096, InternalTLSPort: 9446}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateActivityServiceMTLSPort() error = nil, want missing internal HTTP TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing HTTP internal TLS port context", err)
	}
}

func TestNewInternalActivityHTTPMTLSServer(t *testing.T) {
	t.Parallel()

	handler := http.NewServeMux()
	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalActivityHTTPMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			InternalTLSPort: 9486,
			ReadTimeout:     time.Second,
			WriteTimeout:    2 * time.Second,
			IdleTimeout:     3 * time.Second,
		},
	}, handler, tlsConfig)

	if server == nil {
		t.Fatal("newInternalActivityHTTPMTLSServer() = nil, want server")
	}
	if server.Addr != ":9486" {
		t.Fatalf("server addr = %q, want :9486", server.Addr)
	}
	if server.Handler != handler {
		t.Fatal("server handler was not preserved")
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLS config was not preserved")
	}
	if server.ReadTimeout != time.Second || server.WriteTimeout != 2*time.Second || server.IdleTimeout != 3*time.Second {
		t.Fatalf("timeouts = %s/%s/%s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
