package config

import (
	"context"
	"testing"
)

func TestLoadUsesProductionReadyDefaults(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "user-route-service")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.App.Name != "user-route-service" {
		t.Fatalf("app name = %q", cfg.App.Name)
	}
	if cfg.HTTP.Port != 8096 {
		t.Fatalf("http port = %d, want 8096", cfg.HTTP.Port)
	}
	if cfg.DB.Database != "user_route_service_db" {
		t.Fatalf("db name = %q", cfg.DB.Database)
	}
	if cfg.DB.MaxConns < cfg.DB.MinConns {
		t.Fatalf("max conns should be >= min conns: %#v", cfg.DB)
	}
}
