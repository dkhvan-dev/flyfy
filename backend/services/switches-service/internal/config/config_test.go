package config

import (
	"context"
	"testing"
)

func setRequiredConfigEnv(t *testing.T) {
	t.Helper()
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/switches-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/switches-service/server-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/activity-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "activity-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.Mode != "enforce" ||
		serverTransport.CACertPath != "/run/mtls/ca.pem" ||
		serverTransport.ServerCertPath != "/run/mtls/switches-service/server.pem" ||
		serverTransport.ServerKeyPath != "/run/mtls/switches-service/server-key.pem" ||
		len(serverTransport.AllowedSPIFFEIDs) != 1 ||
		len(serverTransport.AllowedDNSNames) != 1 {
		t.Fatalf("server mTLS transport config = %+v", serverTransport)
	}
}

func TestLoadInternalHTTPTLSPortFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9497")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.InternalTLSPort != 9497 {
		t.Fatalf("InternalTLSPort = %d, want 9497", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9497" {
		t.Fatalf("InternalTLSAddress() = %q, want :9497", cfg.HTTP.InternalTLSAddress())
	}
}
