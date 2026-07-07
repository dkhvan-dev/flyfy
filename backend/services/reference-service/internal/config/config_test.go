package config

import (
	"context"
	"testing"
	"time"
)

func TestLoadParsesInternalMTLSServerConfig(t *testing.T) {
	t.Setenv("HTTP_PORT", "8089")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9489")
	t.Setenv("HTTP_READ_TIMEOUT", "2s")
	t.Setenv("HTTP_WRITE_TIMEOUT", "3s")
	t.Setenv("HTTP_IDLE_TIMEOUT", "4s")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.crt")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/reference-service/server.crt")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/reference-service/server.key")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/reference-service/client.crt")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/reference-service/client.key")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/api-gateway")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "api-gateway")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.HTTP.Port != 8089 {
		t.Fatalf("HTTP.Port = %d, want 8089", cfg.HTTP.Port)
	}
	if cfg.HTTP.InternalTLSPort != 9489 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9489", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.Address() != ":8089" {
		t.Fatalf("HTTP.Address() = %q, want :8089", cfg.HTTP.Address())
	}
	if cfg.HTTP.InternalTLSAddress() != ":9489" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9489", cfg.HTTP.InternalTLSAddress())
	}
	if cfg.HTTP.ReadTimeout != 2*time.Second || cfg.HTTP.WriteTimeout != 3*time.Second || cfg.HTTP.IdleTimeout != 4*time.Second {
		t.Fatalf("HTTP timeouts = %s/%s/%s, want 2s/3s/4s", cfg.HTTP.ReadTimeout, cfg.HTTP.WriteTimeout, cfg.HTTP.IdleTimeout)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.ServerCertPath != "/run/mtls/reference-service/server.crt" ||
		serverTransport.ServerKeyPath != "/run/mtls/reference-service/server.key" ||
		len(serverTransport.AllowedSPIFFEIDs) != 1 ||
		serverTransport.AllowedSPIFFEIDs[0] != "spiffe://inflap/test/api-gateway" ||
		len(serverTransport.AllowedDNSNames) != 1 ||
		serverTransport.AllowedDNSNames[0] != "api-gateway" {
		t.Fatalf("mTLS server config = %+v", serverTransport)
	}
}
