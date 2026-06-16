package config

import (
	"context"
	"testing"
)

func TestLoadIncludesSocialStartupReconciliationConfig(t *testing.T) {
	t.Setenv("POSTGRES_HOST", "localhost")
	t.Setenv("POSTGRES_USER", "user_service")
	t.Setenv("POSTGRES_PASSWORD", "secret")
	t.Setenv("POSTGRES_DB", "user_service_db")
	t.Setenv("INTERNAL_SERVICE_TOKEN", "internal-token")
	t.Setenv("USER_SOCIAL_OUTBOX_STARTUP_BACKFILL_ENABLED", "true")
	t.Setenv("USER_SOCIAL_OUTBOX_STARTUP_DRAIN_ENABLED", "true")
	t.Setenv("USER_SOCIAL_OUTBOX_STARTUP_MAX_DRAIN_BATCHES", "7")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load returned error: %v", err)
	}

	if !cfg.Social.StartupBackfillEnabled {
		t.Fatalf("StartupBackfillEnabled = false, want true")
	}
	if !cfg.Social.StartupDrainEnabled {
		t.Fatalf("StartupDrainEnabled = false, want true")
	}
	if cfg.Social.StartupMaxDrainBatches != 7 {
		t.Fatalf("StartupMaxDrainBatches = %d, want 7", cfg.Social.StartupMaxDrainBatches)
	}
}
