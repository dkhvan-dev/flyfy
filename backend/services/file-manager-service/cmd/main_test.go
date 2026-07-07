package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/file-manager-service/internal/config"
)

func TestValidateFileManagerServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateFileManagerServiceMTLSPort(&config.Config{}, nil); err != nil {
		t.Fatalf("validateFileManagerServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateFileManagerServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateFileManagerServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9093}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateFileManagerServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_GRPC_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateFileManagerServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateFileManagerServiceMTLSPort(
		&config.Config{GRPC: config.GRPCConfig{Port: 9093, InternalTLSPort: 9093}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateFileManagerServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from GRPC_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestValidateFileManagerServiceMTLSPortRequiresDedicatedHTTPPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateFileManagerServiceMTLSPort(
		&config.Config{
			HTTP: config.HTTPConfig{Port: 8083},
			GRPC: config.GRPCConfig{Port: 9093, InternalTLSPort: 9443},
		},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateFileManagerServiceMTLSPort() error = nil, want missing internal HTTP TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal HTTP TLS port context", err)
	}
}

func TestValidateFileManagerServiceMTLSPortRejectsPlaintextHTTPPortReuse(t *testing.T) {
	t.Parallel()

	err := validateFileManagerServiceMTLSPort(
		&config.Config{
			HTTP: config.HTTPConfig{Port: 8083, InternalTLSPort: 8083},
			GRPC: config.GRPCConfig{Port: 9093, InternalTLSPort: 9443},
		},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateFileManagerServiceMTLSPort() error = nil, want HTTP port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want HTTP port reuse context", err)
	}
}

func TestNewInternalFileManagerHTTPMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalFileManagerHTTPMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			Port:            8083,
			InternalTLSPort: 9483,
			ReadTimeout:     2 * time.Second,
			WriteTimeout:    3 * time.Second,
			IdleTimeout:     4 * time.Second,
		},
	}, http.NewServeMux(), tlsConfig)

	if server == nil {
		t.Fatal("newInternalFileManagerHTTPMTLSServer() = nil, want server")
	}
	if server.Addr != ":9483" {
		t.Fatalf("server addr = %q, want :9483", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}
