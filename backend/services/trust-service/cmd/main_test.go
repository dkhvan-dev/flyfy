package main

import (
	"crypto/tls"
	"testing"

	"kz/inflap/backend/services/trust-service/internal/config"
)

func TestValidateTrustServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateTrustServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateTrustServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateTrustServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateTrustServiceMTLSPort(&config.Config{}, &tls.Config{MinVersion: tls.VersionTLS13})
	if err == nil {
		t.Fatal("validateTrustServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
}
