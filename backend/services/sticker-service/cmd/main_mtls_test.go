package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/sticker-service/internal/config"
)

func TestValidateStickerServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateStickerServiceMTLSPort(config.Config{}, nil); err != nil {
		t.Fatalf("validateStickerServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateStickerServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateStickerServiceMTLSPort(
		config.Config{HTTP: config.HTTPConfig{Port: 8092}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateStickerServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateStickerServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateStickerServiceMTLSPort(
		config.Config{HTTP: config.HTTPConfig{Port: 8092, InternalTLSPort: 8092}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateStickerServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalStickerMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalStickerMTLSServer(config.Config{
		HTTP: config.HTTPConfig{
			Port:            8092,
			InternalTLSPort: 9492,
			ReadTimeout:     2 * time.Second,
			WriteTimeout:    3 * time.Second,
			IdleTimeout:     4 * time.Second,
		},
	}, http.NewServeMux(), tlsConfig)

	if server == nil {
		t.Fatal("newInternalStickerMTLSServer() = nil, want server")
	}
	if server.Addr != ":9492" {
		t.Fatalf("server addr = %q, want :9492", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}

func TestNewFileManagerClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newFileManagerClient(&config.Config{
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		FileManager: config.FileManagerConfig{
			BaseURL: "http://file-manager-service:8083",
			Timeout: 800 * time.Millisecond,
		},
	})
	if err != nil {
		t.Fatalf("newFileManagerClient() error = %v", err)
	}
	if client == nil {
		t.Fatal("newFileManagerClient() = nil, want client")
	}
}

func TestNewFileManagerClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newFileManagerClient(&config.Config{
		Security: config.SecurityConfig{InternalServiceToken: "internal-token"},
		FileManager: config.FileManagerConfig{
			BaseURL: "https://file-manager-service:9443",
			Timeout: 800 * time.Millisecond,
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newFileManagerClient() error = nil, want missing CA error")
	}
	if !strings.Contains(err.Error(), "initialize file-manager mTLS transport") {
		t.Fatalf("error = %q, want file-manager mTLS context", err)
	}
}
