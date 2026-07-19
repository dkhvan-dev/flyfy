package config

import (
	"context"
	"testing"
	"time"
)

func TestLoadSearchServiceDefaults(t *testing.T) {
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
	if !cfg.Security.ServiceAuthEnabled() {
		t.Fatal("service JWT verification is disabled by default")
	}
	natsConfig, err := cfg.SavedLifecycle.NATSConfig(cfg.App.Env)
	if err != nil {
		t.Fatalf("NATSConfig returned error: %v", err)
	}
	if cfg.Security.ServiceAuthIssuer != "tourism-inflap/token-service" ||
		cfg.Security.ServiceAuthJWKSURL != "http://token-service:8081/.well-known/jwks.json" ||
		cfg.Security.ServiceAuthCacheTTL != 5*time.Minute {
		t.Fatalf("service auth config = %+v", cfg.Security)
	}
	if !cfg.SavedLifecycle.Enabled ||
		natsConfig.URLs != "nats://localhost:4222" ||
		cfg.SavedLifecycle.WorkerBatchSize != 50 ||
		cfg.SavedLifecycle.LeaseDuration != 2*time.Minute ||
		cfg.SavedLifecycle.PublishTimeout != 2*time.Second ||
		cfg.SavedLifecycle.CleanupInterval != time.Minute {
		t.Fatalf("Saved lifecycle defaults = %+v", cfg.SavedLifecycle)
	}
}

func TestLoadSavedLifecycleConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("NATS_URL", "nats://nats.test:4222")
	t.Setenv("ACTIVITY_SAVED_LIFECYCLE_BATCH_SIZE", "25")
	t.Setenv("ACTIVITY_SAVED_LIFECYCLE_LEASE_DURATION", "90s")
	t.Setenv("ACTIVITY_SAVED_LIFECYCLE_PUBLISH_TIMEOUT", "3s")
	t.Setenv("ACTIVITY_SAVED_LIFECYCLE_CLEANUP_BATCH_SIZE", "300")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	natsConfig, err := cfg.SavedLifecycle.NATSConfig(cfg.App.Env)
	if err != nil {
		t.Fatalf("NATSConfig returned error: %v", err)
	}
	if natsConfig.URLs != "nats://nats.test:4222" ||
		cfg.SavedLifecycle.WorkerBatchSize != 25 ||
		cfg.SavedLifecycle.LeaseDuration != 90*time.Second ||
		cfg.SavedLifecycle.PublishTimeout != 3*time.Second ||
		cfg.SavedLifecycle.CleanupBatchSize != 300 {
		t.Fatalf("Saved lifecycle config = %+v", cfg.SavedLifecycle)
	}
}

func TestLoadRejectsPlaintextSavedLifecycleNATSInProduction(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("APP_ENV", "production")
	t.Setenv("NATS_URL", "nats://nats.internal:4222")

	if _, err := Load(context.Background()); err == nil {
		t.Fatal("Load returned nil error for plaintext production NATS")
	}
}

func TestLoadRejectsSavedLifecycleBatchThatOutlivesLease(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("ACTIVITY_SAVED_LIFECYCLE_BATCH_SIZE", "50")
	t.Setenv("ACTIVITY_SAVED_LIFECYCLE_LEASE_DURATION", "30s")
	t.Setenv("ACTIVITY_SAVED_LIFECYCLE_PUBLISH_TIMEOUT", "2s")

	if _, err := Load(context.Background()); err == nil {
		t.Fatal("Load returned nil error for a Saved lifecycle batch longer than its lease")
	}
}

func TestLoadRejectsInvalidSavedLifecycleLease(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("ACTIVITY_SAVED_LIFECYCLE_LEASE_DURATION", "0s")

	if _, err := Load(context.Background()); err == nil {
		t.Fatal("Load returned nil error for zero Saved lifecycle lease")
	}
}

func TestLoadSearchServiceConfigFromEnvironment(t *testing.T) {
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

func TestLoadActivityTranslationConfig(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("TRANSLATION_SERVICE_URL", "https://translation-service:9497")
	t.Setenv("ACTIVITY_TRANSLATION_WORKER_ENABLED", "true")
	t.Setenv("ACTIVITY_TRANSLATION_WORKER_BATCH_SIZE", "17")
	t.Setenv("ACTIVITY_TRANSLATION_REQUEST_TIMEOUT", "6s")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if !cfg.Translation.AsyncEnabled || !cfg.Translation.WorkerEnabled {
		t.Fatalf("translation flags = %+v", cfg.Translation)
	}
	if cfg.Translation.BaseURL != "https://translation-service:9497" ||
		cfg.Translation.WorkerBatchSize != 17 ||
		cfg.Translation.RequestTimeout != 6*time.Second {
		t.Fatalf("translation config = %+v", cfg.Translation)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/activity-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/activity-service/server-key.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/activity-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/activity-service/client-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/chat-service")
	t.Setenv("MTLS_ALLOWED_DNS_NAMES", "chat-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("search-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/activity-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/activity-service/client-key.pem" ||
		transport.ServerName != "search-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}

	serverTransport := cfg.MTLS.ServerConfig()
	if serverTransport.ServerCertPath != "/run/mtls/activity-service/server.pem" ||
		serverTransport.ServerKeyPath != "/run/mtls/activity-service/server-key.pem" ||
		len(serverTransport.AllowedSPIFFEIDs) != 1 ||
		len(serverTransport.AllowedDNSNames) != 1 {
		t.Fatalf("server mTLS transport config = %+v", serverTransport)
	}
}

func TestLoadInternalGRPCTLSPortFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("INTERNAL_GRPC_TLS_PORT", "9446")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9486")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.GRPC.InternalTLSPort != 9446 {
		t.Fatalf("InternalTLSPort = %d, want 9446", cfg.GRPC.InternalTLSPort)
	}
	if cfg.GRPC.InternalTLSAddress() != ":9446" {
		t.Fatalf("InternalTLSAddress() = %q, want :9446", cfg.GRPC.InternalTLSAddress())
	}
	if cfg.HTTP.InternalTLSPort != 9486 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9486", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9486" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9486", cfg.HTTP.InternalTLSAddress())
	}
}
