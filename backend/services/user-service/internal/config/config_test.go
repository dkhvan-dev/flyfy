package config

import (
	"context"
	"testing"
	"time"
)

func TestLoadIncludesSocialStartupReconciliationConfig(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "user_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "user_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("USER_SOCIAL_OUTBOX_STARTUP_BACKFILL_ENABLED", "true")
	t.Setenv("USER_SOCIAL_OUTBOX_STARTUP_DRAIN_ENABLED", "true")
	t.Setenv("USER_SOCIAL_OUTBOX_STARTUP_MAX_DRAIN_BATCHES", "7")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if !cfg.Social.StartupBackfillEnabled {
		t.Fatalf("StartupBackfillEnabled = false, want true")
	}
	if !cfg.Social.StartupDrainEnabled {
		t.Fatalf("StartupDrainEnabled = false, want true")
	}
	if cfg.Social.StartupMaxDrainBatches != 7 {
		t.Fatalf("StartupMaxDrainBatches = %d, want 7", cfg.Social.StartupMaxDrainBatches)
	}
}

func TestLoadSearchServiceDefaults(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "user_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "user_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.SearchService.Enabled {
		t.Fatal("search indexing enabled by default, want disabled")
	}
	if cfg.SearchService.HTTPURL != "http://search-service:8101" {
		t.Fatalf("search service url = %q", cfg.SearchService.HTTPURL)
	}
	if cfg.SearchService.Timeout != 800*time.Millisecond {
		t.Fatalf("search service timeout = %s, want 800ms", cfg.SearchService.Timeout)
	}
}

func TestLoadSearchServiceConfigFromEnvironment(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "user_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "user_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("SEARCH_INDEXING_ENABLED", "true")
	t.Setenv("SEARCH_SERVICE_HTTP_URL", "http://search.test")
	t.Setenv("SEARCH_SERVICE_TIMEOUT", "250ms")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if !cfg.SearchService.Enabled {
		t.Fatal("search indexing disabled, want enabled")
	}
	if cfg.SearchService.HTTPURL != "http://search.test" {
		t.Fatalf("search service url = %q", cfg.SearchService.HTTPURL)
	}
	if cfg.SearchService.Timeout != 250*time.Millisecond {
		t.Fatalf("search service timeout = %s, want 250ms", cfg.SearchService.Timeout)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "user_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "user_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/user-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/user-service/server-key.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/user-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/user-service/client-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/activity-service,spiffe://inflap/test/auth-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "activity-service,auth-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("search-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/user-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/user-service/client-key.pem" ||
		transport.ServerName != "search-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.ServerCertPath != "/run/mtls/user-service/server.pem" ||
		serverTransport.ServerKeyPath != "/run/mtls/user-service/server-key.pem" ||
		len(serverTransport.AllowedSPIFFEIDs) != 2 ||
		len(serverTransport.AllowedDNSNames) != 2 {
		t.Fatalf("server mTLS transport config = %+v", serverTransport)
	}
}

func TestLoadInternalGRPCTLSPortFromEnvironment(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "user_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "user_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("INTERNAL_GRPC_TLS_PORT", "9444")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9484")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.GRPC.InternalTLSPort != 9444 {
		t.Fatalf("InternalTLSPort = %d, want 9444", cfg.GRPC.InternalTLSPort)
	}
	if cfg.GRPC.InternalTLSAddress() != ":9444" {
		t.Fatalf("InternalTLSAddress() = %q, want :9444", cfg.GRPC.InternalTLSAddress())
	}
	if cfg.HTTP.InternalTLSPort != 9484 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9484", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9484" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9484", cfg.HTTP.InternalTLSAddress())
	}
}
