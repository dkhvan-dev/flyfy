package config

import (
	"context"
	"testing"
	"time"
)

func setRequiredConfigEnv(t *testing.T) {
	t.Helper()
	t.Setenv("POSTGRES_HOST", "postgres")
	t.Setenv("POSTGRES_USER", "guide_service")
	t.Setenv("POSTGRES_PASSWORD", "guide_secret")
	t.Setenv("POSTGRES_DB", "guide_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
}

func TestLoadSearchServiceDefaults(t *testing.T) {
	setRequiredConfigEnv(t)

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

func TestLoadSavedLifecycleDefaultsDisabled(t *testing.T) {
	setRequiredConfigEnv(t)

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.SavedLifecycle.Enabled {
		t.Fatal("Saved lifecycle enabled by default, want explicit rollout")
	}
	natsConfig, err := cfg.SavedLifecycle.NATSConfig(cfg.App.Env)
	if err != nil {
		t.Fatalf("NATSConfig returned error: %v", err)
	}
	if cfg.SavedLifecycle.Subject != "saved.source.guide.lifecycle.v1" ||
		natsConfig.URLs != "nats://nats:4222" ||
		cfg.SavedLifecycle.DeliveredRetention != 14*24*time.Hour ||
		cfg.SavedLifecycle.DeadRetention != 90*24*time.Hour ||
		cfg.SavedLifecycle.ReconcileInterval != time.Minute {
		t.Fatalf("Saved lifecycle defaults = %+v", cfg.SavedLifecycle)
	}
}

func TestLoadSavedLifecycleRejectsUnsafeLease(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("SAVED_LIFECYCLE_ENABLED", "true")
	t.Setenv("SAVED_LIFECYCLE_LEASE_DURATION", "2s")
	t.Setenv("SAVED_LIFECYCLE_PUBLISH_TIMEOUT", "3s")

	if _, err := Load(context.Background()); err == nil {
		t.Fatal("Load accepted a Saved lifecycle lease shorter than publish timeout")
	}
}

func TestLoadRejectsPlaintextSavedLifecycleNATSInStaging(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("APP_ENV", "staging")
	t.Setenv("SAVED_LIFECYCLE_ENABLED", "true")
	t.Setenv("NATS_URL", "nats://nats.internal:4222")

	if _, err := Load(context.Background()); err == nil {
		t.Fatal("Load returned nil error for plaintext staging NATS")
	}
}

func TestLoadSearchServiceConfigFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
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

func TestLoadExcursionServiceConfigFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("EXCURSION_SERVICE_HTTP_URL", "http://excursion.test")
	t.Setenv("EXCURSION_SERVICE_TIMEOUT", "1200ms")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.Excursion.BaseURL != "http://excursion.test" {
		t.Fatalf("excursion service url = %q", cfg.Excursion.BaseURL)
	}
	if cfg.Excursion.Timeout != 1200*time.Millisecond {
		t.Fatalf("excursion service timeout = %s, want 1200ms", cfg.Excursion.Timeout)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/guide-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/guide-service/server-key.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/guide-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/guide-service/client-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/excursion-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "excursion-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("search-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/guide-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/guide-service/client-key.pem" ||
		transport.ServerName != "search-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.ServerCertPath != "/run/mtls/guide-service/server.pem" ||
		serverTransport.ServerKeyPath != "/run/mtls/guide-service/server-key.pem" ||
		len(serverTransport.AllowedSPIFFEIDs) != 1 ||
		len(serverTransport.AllowedDNSNames) != 1 {
		t.Fatalf("server mTLS transport config = %+v", serverTransport)
	}
}

func TestLoadInternalGRPCTLSPortFromEnvironment(t *testing.T) {
	setRequiredConfigEnv(t)
	t.Setenv("INTERNAL_GRPC_TLS_PORT", "9445")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9485")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.GRPC.InternalTLSPort != 9445 {
		t.Fatalf("InternalTLSPort = %d, want 9445", cfg.GRPC.InternalTLSPort)
	}
	if cfg.GRPC.InternalTLSAddress() != ":9445" {
		t.Fatalf("InternalTLSAddress() = %q, want :9445", cfg.GRPC.InternalTLSAddress())
	}
	if cfg.HTTP.InternalTLSPort != 9485 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9485", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9485" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9485", cfg.HTTP.InternalTLSAddress())
	}
}
