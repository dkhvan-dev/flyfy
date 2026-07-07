package config

import (
	"context"
	"testing"
	"time"
)

func TestLoadDefaultsForSearchService(t *testing.T) {
	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.App.Name != "search-service" {
		t.Fatalf("app name = %q, want search-service", cfg.App.Name)
	}
	if cfg.HTTP.Port != 8101 {
		t.Fatalf("http port = %d, want 8101", cfg.HTTP.Port)
	}
	if cfg.HTTP.InternalTLSPort != 0 {
		t.Fatalf("internal tls port = %d, want 0 default", cfg.HTTP.InternalTLSPort)
	}
	if cfg.Database.DSN != "" {
		t.Fatalf("database dsn = %q, want empty default", cfg.Database.DSN)
	}
}

func TestLoadInternalTLSHTTPPortFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9101")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.HTTP.InternalTLSPort != 9101 {
		t.Fatalf("internal tls port = %d, want 9101", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9101" {
		t.Fatalf("internal tls address = %q, want :9101", cfg.HTTP.InternalTLSAddress())
	}
}

func TestLoadSecurityConfigFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_SERVICE_TOKEN", "secret-token")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.Security.InternalServiceToken != "secret-token" {
		t.Fatalf("internal service token = %q, want secret-token", cfg.Security.InternalServiceToken)
	}
}

func TestLoadDocumentEventWorkerConfig(t *testing.T) {
	t.Setenv("SEARCH_DOCUMENT_EVENT_WORKER_ENABLED", "false")
	t.Setenv("SEARCH_DOCUMENT_EVENT_WORKER_POLL_INTERVAL", "2s")
	t.Setenv("SEARCH_DOCUMENT_EVENT_WORKER_BATCH_SIZE", "25")
	t.Setenv("SEARCH_DOCUMENT_EVENT_WORKER_MAX_ATTEMPTS", "7")
	t.Setenv("SEARCH_DOCUMENT_EVENT_WORKER_BASE_BACKOFF", "3s")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if cfg.DocumentEvents.WorkerEnabled {
		t.Fatal("worker enabled = true, want false")
	}
	if cfg.DocumentEvents.WorkerPollInterval != 2*time.Second ||
		cfg.DocumentEvents.WorkerBatchSize != 25 ||
		cfg.DocumentEvents.WorkerMaxAttempts != 7 ||
		cfg.DocumentEvents.WorkerBaseBackoff != 3*time.Second {
		t.Fatalf("document event worker config = %+v", cfg.DocumentEvents)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("MTLS_MODE", "enforce")
	t.Setenv("MTLS_CA_CERT_PATH", "/run/mtls/ca.pem")
	t.Setenv("MTLS_SERVER_CERT_PATH", "/run/mtls/search-service/server.pem")
	t.Setenv("MTLS_SERVER_KEY_PATH", "/run/mtls/search-service/server-key.pem")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/run/mtls/search-service/client.pem")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/run/mtls/search-service/client-key.pem")
	t.Setenv("MTLS_ALLOWED_SPIFFE_IDS", "spiffe://inflap/test/activity-service,spiffe://inflap/test/user-service")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	transport := cfg.MTLS.ServerConfig()
	if transport.Mode != "enforce" ||
		transport.CACertPath != "/run/mtls/ca.pem" ||
		transport.ServerCertPath != "/run/mtls/search-service/server.pem" ||
		len(transport.AllowedSPIFFEIDs) != 2 {
		t.Fatalf("mTLS transport config = %+v", transport)
	}
}
