package config

import (
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
