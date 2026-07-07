package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/reference-service/internal/config"
)

func TestValidateReferenceServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateReferenceServiceMTLSPort(config.Config{}, nil); err != nil {
		t.Fatalf("validateReferenceServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateReferenceServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateReferenceServiceMTLSPort(
		config.Config{HTTP: config.HTTPConfig{Port: 8089}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateReferenceServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateReferenceServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateReferenceServiceMTLSPort(
		config.Config{HTTP: config.HTTPConfig{Port: 8089, InternalTLSPort: 8089}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateReferenceServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalReferenceMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalReferenceMTLSServer(config.Config{
		HTTP: config.HTTPConfig{
			Port:            8089,
			InternalTLSPort: 9489,
			ReadTimeout:     2 * time.Second,
			WriteTimeout:    3 * time.Second,
			IdleTimeout:     4 * time.Second,
		},
	}, http.NewServeMux(), tlsConfig)

	if server == nil {
		t.Fatal("newInternalReferenceMTLSServer() = nil, want server")
	}
	if server.Addr != ":9489" {
		t.Fatalf("server addr = %q, want :9489", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
