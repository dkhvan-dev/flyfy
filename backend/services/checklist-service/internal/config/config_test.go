package config

import (
	"context"
	"strings"
	"testing"
	"time"
)

func TestDBConfigBuildsDSNAndParsesPoolDurations(t *testing.T) {
	cfg := DBConfig{
		Host:            "checklist-postgres",
		Port:            5432,
		Name:            "checklist_service_db",
		User:            "checklist_service",
		Password:        "secret",
		SSLMode:         "disable",
		MaxConnLifetime: "45m",
		MaxConnIdleTime: "7m",
	}

	dsn := cfg.DSN()
	if !strings.Contains(dsn, "postgres://checklist_service:secret@checklist-postgres:5432/checklist_service_db") {
		t.Fatalf("unexpected dsn: %s", dsn)
	}
	if !strings.Contains(dsn, "sslmode=disable") {
		t.Fatalf("expected sslmode in dsn: %s", dsn)
	}
	if got := cfg.ParsedMaxConnLifetime(); got != 45*time.Minute {
		t.Fatalf("max lifetime = %s, want 45m", got)
	}
	if got := cfg.ParsedMaxConnIdleTime(); got != 7*time.Minute {
		t.Fatalf("max idle = %s, want 7m", got)
	}
}

func TestLoadMTLSConfigFromEnvironment(t *testing.T) {
	t.Setenv("MTLS_MODE", "disabled")
	t.Setenv("MTLS_CA_CERT_PATH", "/certs/ca.crt")
	t.Setenv("MTLS_CLIENT_CERT_PATH", "/certs/checklist-service/client.crt")
	t.Setenv("MTLS_CLIENT_KEY_PATH", "/certs/checklist-service/client.key")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v, want nil", err)
	}

	if cfg.MTLS.CACertPath != "/certs/ca.crt" {
		t.Fatalf("MTLS.CACertPath = %q, want /certs/ca.crt", cfg.MTLS.CACertPath)
	}
	if cfg.MTLS.ClientCertPath != "/certs/checklist-service/client.crt" {
		t.Fatalf("MTLS.ClientCertPath = %q, want checklist client cert path", cfg.MTLS.ClientCertPath)
	}
	if cfg.MTLS.ClientKeyPath != "/certs/checklist-service/client.key" {
		t.Fatalf("MTLS.ClientKeyPath = %q, want checklist client key path", cfg.MTLS.ClientKeyPath)
	}
}

func TestLoadInternalHTTPTLSPortFromEnvironment(t *testing.T) {
	t.Setenv("INTERNAL_HTTP_TLS_PORT", "9499")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v, want nil", err)
	}

	if cfg.HTTP.InternalTLSPort != 9499 {
		t.Fatalf("HTTP.InternalTLSPort = %d, want 9499", cfg.HTTP.InternalTLSPort)
	}
	if cfg.HTTP.InternalTLSAddress() != ":9499" {
		t.Fatalf("HTTP.InternalTLSAddress() = %q, want :9499", cfg.HTTP.InternalTLSAddress())
	}
}
