package config

import (
	"context"
	"testing"
)

func TestLoadIncludesUserRouteDownstreamDefault(t *testing.T) {
	t.Setenv("TOKEN_SERVICE_ID", "api-gateway")
	t.Setenv("TOKEN_SERVICE_SECRET", "secret")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}
	if cfg.Downstreams.UserRouteService != "http://user-route-service:8096" {
		t.Fatalf("user route downstream = %q", cfg.Downstreams.UserRouteService)
	}
}
