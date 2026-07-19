package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/feed-service/internal/config"
)

func TestNewNotificationServiceHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newNotificationServiceHTTPClient(&config.Config{
		Notification: config.NotificationServiceConfig{
			HTTPURL:        "http://notification-service:8097",
			RequestTimeout: 750 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newNotificationServiceHTTPClient() error = %v, want nil", err)
	}
	if client == nil {
		t.Fatal("newNotificationServiceHTTPClient() = nil, want client")
	}
	if client.Timeout != 750*time.Millisecond {
		t.Fatalf("client timeout = %s, want 750ms", client.Timeout)
	}
}

func TestValidateFeedServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateFeedServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateFeedServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateFeedServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateFeedServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8087}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateFeedServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateFeedServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateFeedServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8087, InternalTLSPort: 8087}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateFeedServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestValidateFeedServiceMTLSPortRequiresDedicatedGRPCPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateFeedServiceMTLSPort(
		&config.Config{
			HTTP: config.HTTPConfig{Port: 8087, InternalTLSPort: 9487},
			GRPC: config.GRPCConfig{Port: 9098},
		},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil || !strings.Contains(err.Error(), "INTERNAL_GRPC_TLS_PORT is required") {
		t.Fatalf("validateFeedServiceMTLSPort() error = %v, want missing gRPC TLS port", err)
	}
}

func TestValidateFeedServiceMTLSPortAcceptsSeparateHTTPAndGRPCPorts(t *testing.T) {
	t.Parallel()

	err := validateFeedServiceMTLSPort(
		&config.Config{
			HTTP: config.HTTPConfig{Port: 8087, InternalTLSPort: 9487},
			GRPC: config.GRPCConfig{Port: 9098, InternalTLSPort: 9448},
		},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err != nil {
		t.Fatalf("validateFeedServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestNewInternalFeedMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalFeedMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			Port:            8087,
			InternalTLSPort: 9487,
			ReadTimeout:     2 * time.Second,
			WriteTimeout:    3 * time.Second,
			IdleTimeout:     4 * time.Second,
		},
	}, http.NewServeMux(), tlsConfig)

	if server == nil {
		t.Fatal("newInternalFeedMTLSServer() = nil, want server")
	}
	if server.Addr != ":9487" {
		t.Fatalf("server addr = %q, want :9487", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
