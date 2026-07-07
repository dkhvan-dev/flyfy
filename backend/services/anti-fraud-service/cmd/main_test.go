package main

import (
	"crypto/tls"
	"strings"
	"testing"

	"kz/inflap/backend/services/anti-fraud-service/internal/config"
)

func TestValidateAntiFraudServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateAntiFraudServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateAntiFraudServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateAntiFraudServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateAntiFraudServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8096}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateAntiFraudServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateAntiFraudServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateAntiFraudServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8096, InternalTLSPort: 8096}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateAntiFraudServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}
