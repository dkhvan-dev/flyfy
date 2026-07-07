package config

import (
	"context"
	"testing"
)

func TestLoadDefaultsKeepInternalMTLSDisabled(t *testing.T) {
	setRequiredEnv(t)

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.GRPC.Port != 9096 {
		t.Fatalf("grpc port = %d, want 9096", cfg.GRPC.Port)
	}
	if cfg.GRPC.InternalTLSPort != 0 {
		t.Fatalf("internal grpc tls port = %d, want 0 default", cfg.GRPC.InternalTLSPort)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("INTERNAL_GRPC_TLS_PORT", "19096")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/trust-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/trust-service/server-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/api-gateway,spiffe://inflap/test/activity-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "api-gateway,activity-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.GRPC.InternalTLSPort != 19096 {
		t.Fatalf("internal grpc tls port = %d, want 19096", cfg.GRPC.InternalTLSPort)
	}
	transport := cfg.MTLS.ServerConfig()
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ServerCertPath != "/run/mtls/trust-service/server.pem" ||
		transport.ServerKeyPath != "/run/mtls/trust-service/server-key.pem" ||
		len(transport.AllowedSPIFFEIDs) != 2 ||
		len(transport.AllowedDNSNames) != 2 {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
}

func setRequiredEnv(t *testing.T) {
	t.Helper()

	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "trust_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "trust_service")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-secret")
}
