package config

import (
	"context"
	"testing"
)

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9495")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/admin-panel/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/admin-panel/server-key.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/admin-panel/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/admin-panel/client-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/api-gateway")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "api-gateway")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	transport := cfg.MTLS.ClientConfig("trust-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ServerCertPath != "/run/mtls/admin-panel/server.pem" ||
		transport.ServerKeyPath != "/run/mtls/admin-panel/server-key.pem" ||
		transport.ClientCertPath != "/run/mtls/admin-panel/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/admin-panel/client-key.pem" ||
		transport.ServerName != "trust-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
	if cfg.HTTP.InternalTLSPort != 9495 {
		t.Fatalf("internal TLS port = %d, want 9495", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9495" {
		t.Fatalf("internal TLS address = %q, want :9495", cfg.HTTP.InternalTLSAddress())
	}
	server := cfg.MTLS.ServerConfig()
	if len(server.AllowedSPIFFEIDs) != 1 || server.AllowedSPIFFEIDs[0] != "spiffe://inflap/test/api-gateway" {
		t.Fatalf("allowed SPIFFE IDs = %#v", server.AllowedSPIFFEIDs)
	}
	if len(server.AllowedDNSNames) != 1 || server.AllowedDNSNames[0] != "api-gateway" {
		t.Fatalf("allowed DNS names = %#v", server.AllowedDNSNames)
	}
}
