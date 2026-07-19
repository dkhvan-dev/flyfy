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

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/place-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/place-service/client-key.pem")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("search-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/place-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/place-service/client-key.pem" ||
		transport.ServerName != "search-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
}

func TestLoadInternalHTTPTLSPortFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9490")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.InternalTLSPort != 9490 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9490", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9490" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9490", cfg.HTTP.InternalTLSAddress())
	}
}

func TestLoadSavedSourceGRPCAndServiceAuthDefaults(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.GRPC.Port != 9099 || cfg.GRPC.Address() != ":9099" {
		t.Fatalf("GRPC config = %+v, want :9099", cfg.GRPC)
	}
	if !cfg.Security.ServiceAuthEnabled() {
		t.Fatal("service JWT validation disabled by default")
	}
	if cfg.Security.ServiceAuthIssuer != "tourism-inflap/token-service" {
		t.Fatalf("service auth issuer = %q", cfg.Security.ServiceAuthIssuer)
	}
	if cfg.Security.ServiceAuthCacheTTL != 5*time.Minute {
		t.Fatalf("service auth cache TTL = %s, want 5m", cfg.Security.ServiceAuthCacheTTL)
	}
}

func TestLoadSavedCoverFileManagerDefaults(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.FileManager.GRPCTarget != "dns:///file-manager-service:9093" ||
		cfg.FileManager.RequestTimeout != 3*time.Second {
		t.Fatalf("FileManager config = %+v", cfg.FileManager)
	}
}

func TestLoadSavedCoverFileManagerConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("FILE_MANAGER_GRPC_TARGET", "dns:///files.internal:9443")
	t.Setenv("SAVED_COVER_FILE_MANAGER_TIMEOUT", "1500ms")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.FileManager.GRPCTarget != "dns:///files.internal:9443" ||
		cfg.FileManager.RequestTimeout != 1500*time.Millisecond {
		t.Fatalf("FileManager config = %+v", cfg.FileManager)
	}
}

func TestLoadRejectsUnboundedSavedCoverFileManagerTimeout(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("SAVED_COVER_FILE_MANAGER_TIMEOUT", "30s")

	if _, err := Load(context.Background()); err == nil {
		t.Fatal("Load returned nil error for unbounded Saved cover file-manager timeout")
	}
}

func TestAppConfigRecognizesProductionCaseInsensitively(t *testing.T) {
	t.Parallel()

	if !(AppConfig{Env: " PRODUCTION "}).IsProduction() {
		t.Fatal("IsProduction() = false for normalized production environment")
	}
}

func TestLoadSavedLifecycleDefaultsToDeferredDevelopmentDispatch(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.SavedLifecycle.Enabled {
		t.Fatal("Saved lifecycle dispatch enabled by default in development")
	}
	natsConfig, err := cfg.SavedLifecycle.NATSConfig(cfg.App.Env)
	if err != nil {
		t.Fatalf("NATSConfig returned error: %v", err)
	}
	if natsConfig.URLs != "nats://localhost:4222" ||
		cfg.SavedLifecycle.BatchSize != 50 ||
		cfg.SavedLifecycle.Concurrency != 8 ||
		cfg.SavedLifecycle.LeaseDuration != 2*time.Minute ||
		cfg.SavedLifecycle.MaxAttempts != 20 {
		t.Fatalf("unexpected Saved lifecycle defaults: %+v", cfg.SavedLifecycle)
	}
}

func TestLoadSavedLifecycleRequiresDispatcherInProduction(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("APP_ENV", "production")
	t.Setenv("SAVED_LIFECYCLE_EVENTS_ENABLED", "false")

	_, err := Load(context.Background())
	if err == nil {
		t.Fatal("Load returned nil error for disabled production lifecycle dispatcher")
	}
}

func TestLoadRejectsPlaintextSavedLifecycleNATSInProduction(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("APP_ENV", "production")
	t.Setenv("SAVED_LIFECYCLE_EVENTS_ENABLED", "true")
	t.Setenv("NATS_URL", "nats://nats.internal:4222")

	if _, err := Load(context.Background()); err == nil {
		t.Fatal("Load returned nil error for plaintext production NATS")
	}
}

func TestLoadSavedLifecycleValidatesBoundedWorkerConfig(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("SAVED_LIFECYCLE_EVENTS_ENABLED", "true")
	t.Setenv("SAVED_LIFECYCLE_BATCH_SIZE", "4")
	t.Setenv("SAVED_LIFECYCLE_CONCURRENCY", "5")

	_, err := Load(context.Background())
	if err == nil {
		t.Fatal("Load returned nil error for concurrency above batch size")
	}
}
