package main

import (
	"testing"
	"time"
)

func TestParseFlagsUsesBoundedDefaults(t *testing.T) {
	t.Parallel()
	config, err := parseFlags(nil)
	if err != nil {
		t.Fatalf("parseFlags() error = %v", err)
	}
	if config.Mode != "status" || config.BatchSize != 500 || config.MaxBatches != 100 ||
		config.Pause != 25*time.Millisecond {
		t.Fatalf("parseFlags() = %+v", config)
	}
}

func TestParseFlagsRejectsUnsafeOrAmbiguousInput(t *testing.T) {
	t.Parallel()
	for _, arguments := range [][]string{
		{"-mode=unknown"},
		{"-batch-size=0"},
		{"-batch-size=1001"},
		{"-max-batches=0"},
		{"-lock-timeout=0"},
		{"-statement-timeout=500ms"},
		{"unexpected"},
	} {
		if _, err := parseFlags(arguments); err == nil {
			t.Fatalf("parseFlags(%v) succeeded", arguments)
		}
	}
}

func TestParseFlagsAcceptsRolloutMode(t *testing.T) {
	t.Parallel()
	config, err := parseFlags([]string{"-mode=ROLLOUT", "-max-batches=10000"})
	if err != nil {
		t.Fatalf("parseFlags() error = %v", err)
	}
	if config.Mode != "rollout" || config.MaxBatches != 10_000 {
		t.Fatalf("parseFlags() = %+v", config)
	}
}
