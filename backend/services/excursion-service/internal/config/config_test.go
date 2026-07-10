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

func TestLoadPlaceServiceConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("PLACE_SERVICE_URL", "http://place.test")
	t.Setenv("PLACE_SERVICE_TIMEOUT", "1200ms")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.Place.BaseURL != "http://place.test" {
		t.Fatalf("place service url = %q", cfg.Place.BaseURL)
	}
	if cfg.Place.Timeout != 1200*time.Millisecond {
		t.Fatalf("place service timeout = %s, want 1200ms", cfg.Place.Timeout)
	}
}

func TestLoadExcursionTranslationDefaultsKeepWritesIndependentFromProvider(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if !cfg.Translation.AsyncEnabled {
		t.Fatal("async translation must be enabled by default")
	}
	if cfg.Translation.WorkerEnabled {
		t.Fatal("translation worker must be disabled by default")
	}
	if cfg.Translation.WorkerBatchSize != 10 || cfg.Translation.WorkerInterval != 2*time.Second {
		t.Fatalf("worker defaults = batch %d interval %s", cfg.Translation.WorkerBatchSize, cfg.Translation.WorkerInterval)
	}
	if cfg.Translation.MaxAttempts != 5 || cfg.Translation.RetryBaseDelay != 30*time.Second {
		t.Fatalf("retry defaults = attempts %d delay %s", cfg.Translation.MaxAttempts, cfg.Translation.RetryBaseDelay)
	}
	if cfg.Translation.RequestTimeout != 8*time.Second || cfg.Translation.WorkerLockTimeout != 2*time.Minute {
		t.Fatalf("timeout defaults = request %s lock %s", cfg.Translation.RequestTimeout, cfg.Translation.WorkerLockTimeout)
	}
}

func TestLoadExcursionTranslationConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("EXCURSION_ASYNC_TRANSLATION_ENABLED", "true")
	t.Setenv("EXCURSION_TRANSLATION_WORKER_ENABLED", "true")
	t.Setenv("EXCURSION_TRANSLATION_WORKER_BATCH_SIZE", "25")
	t.Setenv("EXCURSION_TRANSLATION_WORKER_INTERVAL", "3s")
	t.Setenv("EXCURSION_TRANSLATION_MAX_ATTEMPTS", "7")
	t.Setenv("EXCURSION_TRANSLATION_RETRY_BASE_DELAY", "45s")
	t.Setenv("EXCURSION_TRANSLATION_REQUEST_TIMEOUT", "6s")
	t.Setenv("EXCURSION_TRANSLATION_LOCK_TIMEOUT", "90s")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if !cfg.Translation.AsyncEnabled || !cfg.Translation.WorkerEnabled {
		t.Fatal("async translation config was not enabled")
	}
	if cfg.Translation.WorkerBatchSize != 25 || cfg.Translation.WorkerInterval != 3*time.Second {
		t.Fatalf("worker config = batch %d interval %s", cfg.Translation.WorkerBatchSize, cfg.Translation.WorkerInterval)
	}
	if cfg.Translation.MaxAttempts != 7 || cfg.Translation.RetryBaseDelay != 45*time.Second {
		t.Fatalf("retry config = attempts %d delay %s", cfg.Translation.MaxAttempts, cfg.Translation.RetryBaseDelay)
	}
	if cfg.Translation.RequestTimeout != 6*time.Second || cfg.Translation.WorkerLockTimeout != 90*time.Second {
		t.Fatalf("timeout config = request %s lock %s", cfg.Translation.RequestTimeout, cfg.Translation.WorkerLockTimeout)
	}
}

func TestLoadGuideServiceHTTPConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("GUIDE_SERVICE_URL", "http://guide.test")
	t.Setenv("GUIDE_SERVICE_HTTP_TIMEOUT", "7s")
	t.Setenv("GUIDE_SERVICE_VERIFY_TIMEOUT", "9s")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.GuideService.BaseURL != "http://guide.test" {
		t.Fatalf("guide service url = %q", cfg.GuideService.BaseURL)
	}
	if cfg.GuideService.HTTPTimeout != 7*time.Second {
		t.Fatalf("guide service http timeout = %s, want 7s", cfg.GuideService.HTTPTimeout)
	}
	if cfg.GuideService.VerifyTimeout != 9*time.Second {
		t.Fatalf("guide service verify timeout = %s, want 9s", cfg.GuideService.VerifyTimeout)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/excursion-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/excursion-service/client-key.pem")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ClientConfig("search-service")
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ClientCertPath != "/run/mtls/excursion-service/client.pem" ||
		transport.ClientKeyPath != "/run/mtls/excursion-service/client-key.pem" ||
		transport.ServerName != "search-service" {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
}

func TestLoadInternalHTTPTLSPortFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9493")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.InternalTLSPort != 9493 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9493", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9493" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9493", cfg.HTTP.InternalTLSAddress())
	}
}
