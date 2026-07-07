package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/place-service/internal/config"
)

func TestValidatePlaceServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validatePlaceServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validatePlaceServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidatePlaceServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validatePlaceServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8090}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validatePlaceServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidatePlaceServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validatePlaceServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8090, InternalTLSPort: 8090}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validatePlaceServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalPlaceMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalPlaceMTLSServer(
		&config.Config{HTTP: config.HTTPConfig{Port: 8090, InternalTLSPort: 9490}},
		http.NewServeMux(),
		tlsConfig,
		2*time.Second,
		3*time.Second,
		4*time.Second,
	)

	if server == nil {
		t.Fatal("newInternalPlaceMTLSServer() = nil, want server")
	}
	if server.Addr != ":9490" {
		t.Fatalf("server addr = %q, want :9490", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
