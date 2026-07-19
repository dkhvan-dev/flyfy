package savedruntime

import (
	"errors"
	"fmt"
	"time"
)

const (
	maxTaskTimeout = 15 * time.Minute
	maxInterval    = 7 * 24 * time.Hour
	maxBackoff     = time.Hour
)

var ErrInvalidConfig = errors.New("invalid Saved background runtime configuration")

// Config bounds every database-facing scheduler invocation and every retry
// delay. The lifecycle runner owns its provisioning and message-level limits.
type Config struct {
	OutboxPollInterval         time.Duration
	OutboxBusyInterval         time.Duration
	OutboxDispatchTimeout      time.Duration
	OutboxCleanupInterval      time.Duration
	OutboxCleanupTimeout       time.Duration
	OutboxBackoffBase          time.Duration
	OutboxBackoffMax           time.Duration
	MaintenanceInterval        time.Duration
	MaintenanceBusyInterval    time.Duration
	MaintenanceRunTimeout      time.Duration
	MaintenanceBackoffBase     time.Duration
	MaintenanceBackoffMax      time.Duration
	ReconciliationInterval     time.Duration
	ReconciliationBusyInterval time.Duration
	ReconciliationRunTimeout   time.Duration
	ReconciliationBackoffBase  time.Duration
	ReconciliationBackoffMax   time.Duration
}

func DefaultConfig() Config {
	return Config{
		OutboxPollInterval: 250 * time.Millisecond,
		OutboxBusyInterval: 10 * time.Millisecond,
		// Covers all waves of the default 100-item, 8-worker dispatcher even
		// when each publish reaches its five-second timeout.
		OutboxDispatchTimeout:      2 * time.Minute,
		OutboxCleanupInterval:      time.Hour,
		OutboxCleanupTimeout:       30 * time.Second,
		OutboxBackoffBase:          time.Second,
		OutboxBackoffMax:           time.Minute,
		MaintenanceInterval:        15 * time.Minute,
		MaintenanceBusyInterval:    250 * time.Millisecond,
		MaintenanceRunTimeout:      2 * time.Minute,
		MaintenanceBackoffBase:     5 * time.Second,
		MaintenanceBackoffMax:      5 * time.Minute,
		ReconciliationInterval:     30 * time.Second,
		ReconciliationBusyInterval: 250 * time.Millisecond,
		ReconciliationRunTimeout:   2 * time.Minute,
		ReconciliationBackoffBase:  5 * time.Second,
		ReconciliationBackoffMax:   5 * time.Minute,
	}
}

func (config Config) Validate() error {
	if err := validateDuration("outbox poll interval", config.OutboxPollInterval, maxInterval); err != nil {
		return err
	}
	if err := validateDuration("outbox busy interval", config.OutboxBusyInterval, config.OutboxPollInterval); err != nil {
		return err
	}
	if err := validateDuration("outbox dispatch timeout", config.OutboxDispatchTimeout, maxTaskTimeout); err != nil {
		return err
	}
	if err := validateDuration("outbox cleanup interval", config.OutboxCleanupInterval, maxInterval); err != nil {
		return err
	}
	if err := validateDuration("outbox cleanup timeout", config.OutboxCleanupTimeout, maxTaskTimeout); err != nil {
		return err
	}
	if err := validateBackoff(
		"outbox",
		config.OutboxBackoffBase,
		config.OutboxBackoffMax,
	); err != nil {
		return err
	}
	if err := validateDuration("maintenance interval", config.MaintenanceInterval, maxInterval); err != nil {
		return err
	}
	if err := validateDuration(
		"maintenance busy interval",
		config.MaintenanceBusyInterval,
		config.MaintenanceInterval,
	); err != nil {
		return err
	}
	if err := validateDuration("maintenance run timeout", config.MaintenanceRunTimeout, maxTaskTimeout); err != nil {
		return err
	}
	if err := validateBackoff(
		"maintenance",
		config.MaintenanceBackoffBase,
		config.MaintenanceBackoffMax,
	); err != nil {
		return err
	}
	if err := validateDuration("reconciliation interval", config.ReconciliationInterval, maxInterval); err != nil {
		return err
	}
	if err := validateDuration(
		"reconciliation busy interval",
		config.ReconciliationBusyInterval,
		config.ReconciliationInterval,
	); err != nil {
		return err
	}
	if err := validateDuration("reconciliation run timeout", config.ReconciliationRunTimeout, maxTaskTimeout); err != nil {
		return err
	}
	return validateBackoff(
		"reconciliation",
		config.ReconciliationBackoffBase,
		config.ReconciliationBackoffMax,
	)
}

func validateDuration(name string, value, maximum time.Duration) error {
	if value <= 0 || value > maximum {
		return fmt.Errorf("%w: %s must be in (0,%s]", ErrInvalidConfig, name, maximum)
	}
	return nil
}

func validateBackoff(name string, base, maximum time.Duration) error {
	if base <= 0 || maximum < base || maximum > maxBackoff {
		return fmt.Errorf(
			"%w: %s backoff must satisfy 0 < base <= max <= %s",
			ErrInvalidConfig,
			name,
			maxBackoff,
		)
	}
	return nil
}
