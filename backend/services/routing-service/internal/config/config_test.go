package config

import (
	"context"
	"testing"
)

func TestLoadReadsCityScopedTransitFlags(t *testing.T) {
	t.Setenv("ROUTING_TRANSIT_ENABLED", "true")
	t.Setenv("ROUTING_TRANSIT_CITY_CODE", "ALA")
	t.Setenv("ROUTING_TRANSIT_GTFS_VERSION", "almaty-gtfs-2026-06-21")
	t.Setenv("ROUTING_ENABLE_OTP", "true")
	t.Setenv("OTP_URL", "http://otp:8080")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if !cfg.Data.TransitEnabled {
		t.Fatal("TransitEnabled = false, want true")
	}
	if cfg.Data.TransitCityCode != "ALA" {
		t.Fatalf("TransitCityCode = %q, want ALA", cfg.Data.TransitCityCode)
	}
	if cfg.Data.GTFSVersion != "almaty-gtfs-2026-06-21" {
		t.Fatalf("GTFSVersion = %q", cfg.Data.GTFSVersion)
	}
	if !cfg.TransitRuntimeEnabled() {
		t.Fatal("TransitRuntimeEnabled() = false, want true")
	}
}

func TestTransitRuntimeRequiresOTPURL(t *testing.T) {
	t.Setenv("ROUTING_TRANSIT_ENABLED", "true")
	t.Setenv("ROUTING_TRANSIT_CITY_CODE", "ALA")
	t.Setenv("ROUTING_TRANSIT_GTFS_VERSION", "almaty-gtfs-2026-06-21")
	t.Setenv("ROUTING_ENABLE_OTP", "true")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.TransitRuntimeEnabled() {
		t.Fatal("TransitRuntimeEnabled() = true without OTP_URL")
	}
}

func TestLoadKeepsLegacyGTFSVersionFallback(t *testing.T) {
	t.Setenv("ROUTING_GTFS_VERSION", "legacy-gtfs-version")

	cfg, err := Load(context.Background())
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.Data.GTFSVersion != "legacy-gtfs-version" {
		t.Fatalf("GTFSVersion = %q, want legacy fallback", cfg.Data.GTFSVersion)
	}
}
