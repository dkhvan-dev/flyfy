package config

import (
	"context"
	"testing"
)

func TestLoadDefaultsKeepInternalMTLSPortsDisabled(t *testing.T) {
	t.Parallel()

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.GRPCPort != 50051 {
		t.Fatalf("grpc port = %d, want 50051", cfg.GRPCPort)
	}
	if cfg.InternalGRPCTLSPort != 0 {
		t.Fatalf("internal grpc tls port = %d, want 0 default", cfg.InternalGRPCTLSPort)
	}
	if cfg.HTTPPort != 8081 {
		t.Fatalf("http port = %d, want 8081", cfg.HTTPPort)
	}
	if cfg.InternalHTTPTLSPort != 0 {
		t.Fatalf("internal http tls port = %d, want 0 default", cfg.InternalHTTPTLSPort)
	}
}

func TestLoadInternalMTLSPortsFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_GRPC_TLS_PORT", "55051")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9081")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.InternalGRPCTLSPort != 55051 {
		t.Fatalf("internal grpc tls port = %d, want 55051", cfg.InternalGRPCTLSPort)
	}
	if cfg.InternalHTTPTLSPort != 9081 {
		t.Fatalf("internal http tls port = %d, want 9081", cfg.InternalHTTPTLSPort)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/token-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/token-service/server-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/activity-service,spiffe://inflap/test/api-gateway")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	transport := cfg.MTLS.ServerConfig()
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ServerCertPath != "/run/mtls/token-service/server.pem" ||
		len(transport.AllowedSPIFFEIDs) != 2 {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
}
