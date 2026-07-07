package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/guide-service/internal/config"
)

func TestValidateGuideServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateGuideServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateGuideServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateGuideServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateGuideServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9095}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateGuideServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_GRPC_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateGuideServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateGuideServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9095, InternalTLSPort: 9095}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateGuideServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from GRPC_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestValidateGuideServiceMTLSPortRequiresHTTPDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateGuideServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9095, InternalTLSPort: 9445}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateGuideServiceMTLSPort() error = nil, want missing internal HTTP TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing HTTP internal TLS port context", err)
	}
}

func TestNewInternalGuideHTTPMTLSServer(t *testing.T) {
	t.Parallel()

	handler := http.NewServeMux()
	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalGuideHTTPMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			InternalTLSPort: 9485,
			ReadTimeout:     time.Second,
			WriteTimeout:    2 * time.Second,
			IdleTimeout:     3 * time.Second,
		},
	}, handler, tlsConfig)

	if server == nil {
		t.Fatal("newInternalGuideHTTPMTLSServer() = nil, want server")
	}
	if server.Addr != ":9485" {
		t.Fatalf("server addr = %q, want :9485", server.Addr)
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
