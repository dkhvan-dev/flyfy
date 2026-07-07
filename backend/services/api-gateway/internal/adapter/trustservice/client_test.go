package trustservice

import (
	"strings"
	"testing"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

func TestNewWithTransportAuthFailsFastWhenMTLSConfigInvalid(t *testing.T) {
	_, err := NewWithTransportAuth(
		config.TrustServiceConfig{Target: "dns:///trust-service:9096"},
		"gateway-secret",
		transportauth.Config{Mode: transportauth.ModeEnforce},
	)
	if err == nil {
		t.Fatal("NewWithTransportAuth error = nil, want invalid mTLS config error")
	}
	if !strings.Contains(err.Error(), "initialize trust-service mTLS transport") {
		t.Fatalf("error = %q, want trust-service mTLS context", err)
	}
}
