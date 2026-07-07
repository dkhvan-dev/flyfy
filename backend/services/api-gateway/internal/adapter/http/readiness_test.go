package http

import (
	nethttp "net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
)

func TestHTTPReadinessCheckerBuildsMTLSClientPerTarget(t *testing.T) {
	caPath := writeTestCA(t)

	checker, err := NewHTTPReadinessCheckerWithTransportAuth(
		"https://search-service:9501/health",
		0,
		transportauth.EnvConfig{
			Mode:       string(transportauth.ModeEnforce),
			CACertPath: caPath,
		},
	)
	if err != nil {
		t.Fatalf("NewHTTPReadinessCheckerWithTransportAuth() error = %v", err)
	}
	if checker.client.Timeout != 2*time.Second {
		t.Fatalf("client timeout = %s, want 2s", checker.client.Timeout)
	}

	transport, ok := checker.client.Transport.(*nethttp.Transport)
	if !ok {
		t.Fatalf("client transport type = %T, want *http.Transport", checker.client.Transport)
	}
	if transport.TLSClientConfig == nil {
		t.Fatal("TLSClientConfig is nil, want mTLS client config")
	}
	if got := transport.TLSClientConfig.ServerName; got != "search-service" {
		t.Fatalf("TLS server name = %q, want search-service", got)
	}
}

func TestHTTPReadinessCheckerFailsFastWhenMTLSEnforceConfigInvalid(t *testing.T) {
	_, err := NewHTTPReadinessCheckerWithTransportAuth(
		"https://search-service:9501/health",
		time.Second,
		transportauth.EnvConfig{Mode: string(transportauth.ModeEnforce)},
	)
	if err == nil {
		t.Fatal("NewHTTPReadinessCheckerWithTransportAuth() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize readiness mTLS client") {
		t.Fatalf("error = %q, want readiness mTLS context", err)
	}
}
