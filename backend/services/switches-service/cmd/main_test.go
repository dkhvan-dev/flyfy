package main

import (
	"crypto/tls"
	"strings"
	"testing"

	"kz/inflap/backend/services/switches-service/internal/config"
)

func TestValidateSwitchesServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateSwitchesServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateSwitchesServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateSwitchesServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateSwitchesServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8096}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateSwitchesServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateSwitchesServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateSwitchesServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8096, InternalTLSPort: 8096}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateSwitchesServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}
