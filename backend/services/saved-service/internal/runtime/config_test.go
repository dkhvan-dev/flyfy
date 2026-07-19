package savedruntime

import (
	"errors"
	"testing"
	"time"
)

func TestDefaultConfigIsValid(t *testing.T) {
	t.Parallel()

	if err := DefaultConfig().Validate(); err != nil {
		t.Fatalf("DefaultConfig().Validate() error = %v", err)
	}
}

func TestConfigRejectsUnboundedOrInvalidDurations(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		mutate func(*Config)
	}{
		{"zero poll interval", func(config *Config) { config.OutboxPollInterval = 0 }},
		{"busy interval above poll", func(config *Config) { config.OutboxBusyInterval = time.Second }},
		{"dispatch timeout above bound", func(config *Config) { config.OutboxDispatchTimeout = maxTaskTimeout + 1 }},
		{"cleanup interval above bound", func(config *Config) { config.OutboxCleanupInterval = maxInterval + 1 }},
		{"outbox backoff reversed", func(config *Config) { config.OutboxBackoffMax = config.OutboxBackoffBase - 1 }},
		{"maintenance busy interval above regular", func(config *Config) {
			config.MaintenanceBusyInterval = config.MaintenanceInterval + 1
		}},
		{"maintenance timeout above bound", func(config *Config) { config.MaintenanceRunTimeout = maxTaskTimeout + 1 }},
		{"maintenance backoff above bound", func(config *Config) { config.MaintenanceBackoffMax = maxBackoff + 1 }},
		{"reconciliation busy interval above regular", func(config *Config) {
			config.ReconciliationBusyInterval = config.ReconciliationInterval + 1
		}},
		{"reconciliation timeout above bound", func(config *Config) {
			config.ReconciliationRunTimeout = maxTaskTimeout + 1
		}},
		{"reconciliation backoff above bound", func(config *Config) {
			config.ReconciliationBackoffMax = maxBackoff + 1
		}},
	}

	for _, test := range tests {
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			config := DefaultConfig()
			test.mutate(&config)
			if err := config.Validate(); !errors.Is(err, ErrInvalidConfig) {
				t.Fatalf("Validate() error = %v, want ErrInvalidConfig", err)
			}
		})
	}
}

func TestBoundedBackoff(t *testing.T) {
	t.Parallel()

	base := 100 * time.Millisecond
	maximum := 350 * time.Millisecond
	wants := []time.Duration{base, base, 2 * base, maximum, maximum, maximum}
	for failures, want := range wants {
		if got := boundedBackoff(base, maximum, failures); got != want {
			t.Fatalf("boundedBackoff(..., %d) = %s, want %s", failures, got, want)
		}
	}
}
