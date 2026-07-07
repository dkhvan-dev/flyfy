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
