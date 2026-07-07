package config

import (
	"context"
	"testing"
)

func setRequiredConfigEnv(t *testing.T) {
	t.Helper()
	t.Setenv("POSTGRES_HOST", "postgres")
	t.Setenv("POSTGRES_USER", "payment_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "payment_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/payment-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/payment-service/server-key.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/payment-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/payment-service/client-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/activity-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "activity-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("anti-fraud-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/payment-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/payment-service/client-key.pem" ||
		transport.ServerName != "anti-fraud-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.ServerCertPath != "/run/mtls/payment-service/server.pem" ||
		serverTransport.ServerKeyPath != "/run/mtls/payment-service/server-key.pem" ||
		len(serverTransport.AllowedSPIFFEIDs) != 1 ||
		len(serverTransport.AllowedDNSNames) != 1 {
		t.Fatalf("server mTLS transport config = %+v", serverTransport)
	}
}

func TestLoadInternalHTTPTLSPortFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9491")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.InternalTLSPort != 9491 {
		t.Fatalf("InternalTLSPort = %d, want 9491", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9491" {
		t.Fatalf("InternalTLSAddress() = %q, want :9491", cfg.HTTP.InternalTLSAddress())
	}
}
