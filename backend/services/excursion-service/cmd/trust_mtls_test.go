package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/excursion-service/internal/config"
)

func TestNewTrustPolicyClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	_, err := newTrustPolicyClient(&config.Config{
		App:      config.AppConfig{Name: "excursion-service"},
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		Trust: config.TrustServiceConfig{
			Enabled: true,
			Target:  "trust-service:9096",
			Timeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newTrustPolicyClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize trustpolicy mTLS transport") {
		t.Fatalf("error = %q, want trustpolicy mTLS context", err)
	}
}
