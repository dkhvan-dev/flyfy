package main

import (
	"crypto/tls"
	"net/http"
	"testing"
	"time"

	"kz/inflap/backend/services/token-service/internal/config"
)

func TestValidateTokenServiceMTLSPortsAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateTokenServiceMTLSPorts(&config.Config{}, nil); err != nil {
		t.Fatalf("validateTokenServiceMTLSPorts() error = %v, want nil", err)
	}
}

func TestValidateTokenServiceMTLSPortsRequiresDualInternalPortsWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateTokenServiceMTLSPorts(&config.Config{
		InternalGRPCTLSPort: 55051,
	}, &tls.Config{MinVersion: tls.VersionTLS13})
	if err == nil {
		t.Fatal("validateTokenServiceMTLSPorts() error = nil, want missing HTTP TLS port error")
	}
}

func TestNewInternalMTLSHTTPServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalMTLSHTTPServer(&config.Config{
		InternalHTTPTLSPort: 9081,
	}, http.NewServeMux(), tlsConfig)
	if server == nil {
		t.Fatal("internal mTLS HTTP server = nil, want server")
	}
	if server.Addr != ":9081" {
		t.Fatalf("server addr = %q, want :9081", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
}

func TestNewNotificationServiceHTTPClientAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	client, err := newNotificationServiceHTTPClient(&config.Config{
		Notification: config.NotificationConfig{
			HTTPURL: "http://notification-service:8097",
			Timeout: 750 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newNotificationServiceHTTPClient() error = %v, want nil", err)
	}
	if client == nil {
		t.Fatal("newNotificationServiceHTTPClient() = nil, want client")
	}
	if client.Timeout != 750*time.Millisecond {
		t.Fatalf("client timeout = %v, want 750ms", client.Timeout)
	}
}
