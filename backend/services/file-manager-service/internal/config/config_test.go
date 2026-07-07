package config

import (
	"context"
	"testing"
)

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/file-manager-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/file-manager-service/server-key.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/file-manager-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/file-manager-service/client-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/activity-service,spiffe://inflap/test/excursion-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "activity-service,excursion-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	transport := cfg.MTLS.ClientConfig("trust-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/file-manager-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/file-manager-service/client-key.pem" ||
		transport.ServerName != "trust-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.ServerCertPath != "/run/mtls/file-manager-service/server.pem" ||
		serverTransport.ServerKeyPath != "/run/mtls/file-manager-service/server-key.pem" ||
		len(serverTransport.AllowedSPIFFEIDs) != 2 ||
		len(serverTransport.AllowedDNSNames) != 2 {
		t.Fatalf("server mTLS transport config = %+v", serverTransport)
	}
}

func TestLoadInternalGRPCTLSPortFromEnvironment(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("INTERNAL_GRPC_TLS_PORT", "9443")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9483")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.GRPC.InternalTLSPort != 9443 {
		t.Fatalf("InternalTLSPort = %d, want 9443", cfg.GRPC.InternalTLSPort)
	}
	if cfg.GRPC.InternalTLSAddress() != ":9443" {
		t.Fatalf("InternalTLSAddress() = %q, want :9443", cfg.GRPC.InternalTLSAddress())
	}
	if cfg.HTTP.InternalTLSPort != 9483 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9483", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9483" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9483", cfg.HTTP.InternalTLSAddress())
	}
}

func setRequiredEnv(t *testing.T) {
	t.Helper()

	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "file_manager")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "file_manager")
	t.Setenv("STORAGE_ENDPOINT", "http://localhost:9000")
	t.Setenv("STORAGE_ACCESS_KEY_ID", "access")
	t.Setenv("STORAGE_SECRET_ACCESS_KEY", "secret")
	t.Setenv("STORAGE_BUCKET", "files")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-secret")
}
