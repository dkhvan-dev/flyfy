package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/chat-service/internal/config"
)

func TestValidateChatServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateChatServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateChatServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateChatServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateChatServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9097}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateChatServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_GRPC_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateChatServiceMTLSPortRequiresHTTPDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateChatServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9097, InternalTLSPort: 9447}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateChatServiceMTLSPort() error = nil, want missing internal HTTP TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal HTTP TLS port context", err)
	}
}

func TestValidateChatServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateChatServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9097, InternalTLSPort: 9097}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateChatServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from GRPC_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalChatHTTPMTLSServer(t *testing.T) {
	t.Parallel()

	handler := http.NewServeMux()
	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalChatHTTPMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			InternalTLSPort: 9488,
			ReadTimeout:     time.Second,
			WriteTimeout:    2 * time.Second,
			IdleTimeout:     3 * time.Second,
		},
	}, handler, tlsConfig)

	if server == nil {
		t.Fatal("newInternalChatHTTPMTLSServer() = nil, want server")
	}
	if server.Addr != ":9488" {
		t.Fatalf("server addr = %q, want :9488", server.Addr)
	}
	if server.Handler != handler {
		t.Fatal("server handler was not preserved")
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLS config was not preserved")
	}
	if server.ReadTimeout != time.Second || server.WriteTimeout != 2*time.Second || server.IdleTimeout != 3*time.Second {
		t.Fatalf("timeouts = %s/%s/%s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
