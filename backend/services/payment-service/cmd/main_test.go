package main

import (
	"crypto/tls"
	"strings"
	"testing"

	"kz/inflap/backend/services/payment-service/internal/config"
)

func TestValidatePaymentServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validatePaymentServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validatePaymentServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidatePaymentServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validatePaymentServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8091}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validatePaymentServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidatePaymentServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validatePaymentServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8091, InternalTLSPort: 8091}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validatePaymentServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}
