package main

import (
	"crypto/tls"
	"net/http"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/translation-service/internal/config"
)

func TestValidateTranslationServiceMTLSPortAllowsDisabledMTLS(t *testing.T) {
	t.Parallel()

	if err := validateTranslationServiceMTLSPort(config.Config{}, nil); err != nil {
		t.Fatalf("validateTranslationServiceMTLSPort() error = %v, want nil", err)
	}
}

func TestValidateTranslationServiceMTLSPortRequiresDedicatedPortWhenEnabled(t *testing.T) {
	t.Parallel()

	err := validateTranslationServiceMTLSPort(
		config.Config{HTTP: config.HTTPConfig{Port: 8094}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateTranslationServiceMTLSPort() error = nil, want missing internal TLS port error")
	}
	if !strings.Contains(err.Error(), "INTERNAL_HTTP_TLS_PORT is required") {
		t.Fatalf("error = %q, want missing internal TLS port context", err)
	}
}

func TestValidateTranslationServiceMTLSPortRejectsPlaintextPortReuse(t *testing.T) {
	t.Parallel()

	err := validateTranslationServiceMTLSPort(
		config.Config{HTTP: config.HTTPConfig{Port: 8094, InternalTLSPort: 8094}},
		&tls.Config{MinVersion: tls.VersionTLS13},
	)
	if err == nil {
		t.Fatal("validateTranslationServiceMTLSPort() error = nil, want port reuse error")
	}
	if !strings.Contains(err.Error(), "must be different from HTTP_PORT") {
		t.Fatalf("error = %q, want port reuse context", err)
	}
}

func TestNewInternalTranslationMTLSServerUsesDedicatedPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalTranslationMTLSServer(config.Config{
		HTTP: config.HTTPConfig{
			Port:            8094,
			InternalTLSPort: 9497,
			ReadTimeout:     2 * time.Second,
			WriteTimeout:    3 * time.Second,
			IdleTimeout:     4 * time.Second,
		},
	}, http.NewServeMux(), tlsConfig)

	if server == nil {
		t.Fatal("newInternalTranslationMTLSServer() = nil, want server")
	}
	if server.Addr != ":9497" {
		t.Fatalf("server addr = %q, want :9497", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
	if server.ReadTimeout != 2*time.Second || server.WriteTimeout != 3*time.Second || server.IdleTimeout != 4*time.Second {
		t.Fatalf("server timeouts = %s/%s/%s, want 2s/3s/4s", server.ReadTimeout, server.WriteTimeout, server.IdleTimeout)
	}
}

func TestNewServiceAuthJWKSHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newServiceAuthJWKSHTTPClient(config.Config{
		Security: config.SecurityConfig{
			ServiceAuthJWKSURL: "http://token-service:8081/.well-known/jwks.json",
		},
	})
	if err != nil {
		t.Fatalf("newServiceAuthJWKSHTTPClient() error = %v", err)
	}
	if client.Transport != nil {
		t.Fatalf("client transport = %#v, want nil default transport for disabled mTLS", client.Transport)
	}
}

func TestNewServiceAuthJWKSHTTPClientRequiresClientCertificateWhenMTLSEnforced(t *testing.T) {
	t.Parallel()

	_, err := newServiceAuthJWKSHTTPClient(config.Config{
		Security: config.SecurityConfig{
			ServiceAuthJWKSURL: "https://token-service:9481/.well-known/jwks.json",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newServiceAuthJWKSHTTPClient() error = nil, want missing client certificate error")
	}
	if !strings.Contains(err.Error(), "MTLS_CLIENT_CERT_PATH") {
		t.Fatalf("error = %q, want missing client certificate context", err)
	}
}

func TestNewServiceAuthJWKSHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newServiceAuthJWKSHTTPClient(config.Config{
		Security: config.SecurityConfig{
			ServiceAuthJWKSURL: "https://token-service:9481/.well-known/jwks.json",
		},
		MTLS: transportauth.EnvConfig{
			Mode:           "enforce",
			ClientCertPath: "/missing/client.crt",
			ClientKeyPath:  "/missing/client.key",
		},
	})
	if err == nil {
		t.Fatal("newServiceAuthJWKSHTTPClient() error = nil, want missing CA error")
	}
}
