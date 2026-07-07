package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/checklist-service/internal/config"
)

func TestNewNotificationServiceHTTPClientAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	client, err := newNotificationServiceHTTPClient(&config.Config{
		Notifications: config.NotificationConfig{
			ServiceBaseURL: "http://notification-service:8097",
			HTTPTimeout:    750 * time.Millisecond,
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

func TestValidateChecklistServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateChecklistServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateChecklistServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateChecklistServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateChecklistServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8099}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateChecklistServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateChecklistServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateChecklistServiceMTLSPort(
		&config.Config{HTTP: config.HTTPConfig{Port: 8099, InternalTLSPort: 8099}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateChecklistServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalChecklistMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalChecklistMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			Port:            8099,
			InternalTLSPort: 9499,
			ReadTimeout:     2 * time.Second,
			WriteTimeout:    3 * time.Second,
			IdleTimeout:     4 * time.Second,
		},
	}, http.NewServeMux(), tlsConfig)

	if server == nil {
		t.Fatal("newInternalChecklistMTLSServer() = nil, want server")
	}
	if server.Addr != ":9499" {
		t.Fatalf("server addr = %q, want :9499", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
