package main

import (
	"crypto/tls"
	"net/http"
	"testing"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/search-service/internal/config"
)

func TestNewInternalMTLSServerDisabledWithoutPort(t *testing.T) {
	t.Parallel()

	server := newInternalMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			ReadTimeout:  2 * time.Second,
			WriteTimeout: 3 * time.Second,
			IdleTimeout:  4 * time.Second,
		},
	}, http.NewServeMux(), &tls.Config{})
	if server != nil {
		t.Fatalf("internal mTLS server = %#v, want nil when INTERNAL_HTTP_TLS_PORT is not set", server)
	}
}

func TestNewInternalMTLSServerUsesDedicatedTLSPort(t *testing.T) {
	t.Parallel()

	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS13}
	server := newInternalMTLSServer(&config.Config{
		HTTP: config.HTTPConfig{
			InternalTLSPort: 9101,
			ReadTimeout:     2 * time.Second,
			WriteTimeout:    3 * time.Second,
			IdleTimeout:     4 * time.Second,
		},
	}, http.NewServeMux(), tlsConfig)
	if server == nil {
		t.Fatal("internal mTLS server = nil, want server")
	}
	if server.Addr != ":9101" {
		t.Fatalf("server addr = %q, want :9101", server.Addr)
	}
	if server.TLSConfig != tlsConfig {
		t.Fatal("server TLSConfig was not preserved")
	}
}

func TestNewServiceAuthJWKSHTTPClientKeepsPlainClientWhenMTLSDisabled(t *testing.T) {
	t.Parallel()

	client, err := newServiceAuthJWKSHTTPClient(&config.Config{
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

func TestNewServiceAuthJWKSHTTPClientFailsFastWhenMTLSEnabledWithoutCA(t *testing.T) {
	t.Parallel()

	_, err := newServiceAuthJWKSHTTPClient(&config.Config{
		Security: config.SecurityConfig{
			ServiceAuthJWKSURL: "https://token-service:9081/.well-known/jwks.json",
		},
		MTLS: transportauth.EnvConfig{Mode: "enforce"},
	})
	if err == nil {
		t.Fatal("newServiceAuthJWKSHTTPClient() error = nil, want missing CA error")
	}
}
