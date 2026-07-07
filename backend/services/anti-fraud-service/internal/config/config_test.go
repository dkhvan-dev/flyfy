package config

import (
	"context"
	"testing"
)

func setRequiredConfigEnv(t *testing.T) {
	t.Helper()
	t.Setenv("POSTGRES_HOST", "postgres")
	t.Setenv("POSTGRES_USER", "anti_fraud_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "anti_fraud_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/anti-fraud-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/anti-fraud-service/server-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/activity-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "activity-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.Mode != "enforce" ||
		serverTransport.CACertPath != "/run/mtls/ca.pem" ||
		serverTransport.ServerCertPath != "/run/mtls/anti-fraud-service/server.pem" ||
		serverTransport.ServerKeyPath != "/run/mtls/anti-fraud-service/server-key.pem" ||
		len(serverTransport.AllowedSPIFFEIDs) != 1 ||
		len(serverTransport.AllowedDNSNames) != 1 {
		t.Fatalf("server mTLS transport config = %+v", serverTransport)
	}
}

func TestLoadInternalHTTPTLSPortFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9496")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.InternalTLSPort != 9496 {
		t.Fatalf("InternalTLSPort = %d, want 9496", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9496" {
		t.Fatalf("InternalTLSAddress() = %q, want :9496", cfg.HTTP.InternalTLSAddress())
	}
}
