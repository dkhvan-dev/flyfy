package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/saved-service/internal/config"
)

func TestValidateSavedMTLSListenerAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateSavedMTLSListener(config.Config{}, nil); err != nil {
		t.Fatalf("validateSavedMTLSListener() error = %v, want nil", err)
	}
}

func TestValidateSavedMTLSListenerRequiresDedicatedPort(t *testing.T) {
	t.Parallel()

	err := validateSavedMTLSListener(
		config.Config{HTTP: config.HTTPConfig{Port: 8102}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil || !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("validateSavedMTLSListener() error = %v, want missing port error", err)
	}
}

func TestNewHTTPServerAppliesTransportTimeouts(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newHTTPServer(":9502", http.NewServeMux(), config.HTTPConfig{
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       3 * time.Second,
		WriteTimeout:      4 * time.Second,
		IdleTimeout:       5 * time.Second,
	}, tlsConfig)

	if server.TLSConfig != tlsConfig {
		t.Fatal("server did not preserve the TLS config")
	}
	if server.ReadHeaderTimeout != 2*time.Second || server.ReadTimeout != 3*time.Second || server.WriteTimeout != 4*time.Second || server.IdleTimeout != 5*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s/%s, want 2s/3s/4s/5s", server.ReadHeaderTimeout, server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
