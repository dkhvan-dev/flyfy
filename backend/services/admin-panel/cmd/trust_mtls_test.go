package main

import (
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/admin-panel/internal/config"
)

func TestNewTrustClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	_, err := newTrustClient(&config.Config{
		App:      config.AppConfig{Name: "admin-panel"},
		Security: config.SecurityConfig{TrustedInternalToken: "internal-token"},
		Trust: config.TrustServiceConfig{
			Target:  "trust-service:9096",
			Timeout: time.Second,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newTrustClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize admin trust mTLS transport") {
		t.Fatalf("error = %q, want admin trust mTLS context", err)
	}
}
