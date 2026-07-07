package config

import (
	"context"
	"testing"
)

func TestLoadIncludesUserRouteDownstreamDefault(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.Downstreams.UserRouteService != "http://user-route-service:8096" {
		t.Fatalf("user route downstream = %q", cfg.Downstreams.UserRouteService)
	}
}

func TestLoadIncludesSearchDownstreamDefault(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.Downstreams.SearchService != "http://search-service:8101" {
		t.Fatalf("search downstream = %q", cfg.Downstreams.SearchService)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/api-gateway/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/api-gateway/client-key.pem")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("token-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/api-gateway/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/api-gateway/client-key.pem" ||
		transport.ServerName != "token-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
}
