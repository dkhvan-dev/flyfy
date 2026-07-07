package main

import (
	"crypto/tls"
	"strings"
	"testing"

	"kz/inflap/backend/services/notification-service/internal/config"
)

func TestValidateNotificationServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateNotificationServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateNotificationServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateNotificationServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateNotificationServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8097}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateNotificationServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateNotificationServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateNotificationServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8097, InternalTLSPort: 8097}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateNotificationServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}
