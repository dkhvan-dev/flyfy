package savedmaintenance

import (
	"errors"
	"fmt"
	"time"
)

const (
	DefaultBatchSize           = 100
	DefaultMaxBatchesPerRun    = 8
	DefaultOperationRetention  = 14 * 24 * time.Hour
	DefaultProjectionRetention = 14 * 24 * time.Hour

	maxBatchSize        = 1000
	maxBatchesPerRun    = 64
	minimumRetentionAge = time.Hour
)

var ErrInvalidConfig = errors.New("invalid saved maintenance config")

// Config bounds both individual database transactions and one scheduler run.
// OperationRetention must match the current database/domain retention contract.
type Config struct {
	BatchSize           int
	MaxBatchesPerRun    int
	OperationRetention  time.Duration
	ProjectionRetention time.Duration
}

func DefaultConfig() Config {
	return Config{
		BatchSize:           DefaultBatchSize,
		MaxBatchesPerRun:    DefaultMaxBatchesPerRun,
		OperationRetention:  DefaultOperationRetention,
		ProjectionRetention: DefaultProjectionRetention,
	}
}

func (c Config) Validate() error {
	if c.BatchSize < 1 || c.BatchSize > maxBatchSize {
		return fmt.Errorf("%w: batch size must be between 1 and %d", ErrInvalidConfig, maxBatchSize)
	}
	if c.MaxBatchesPerRun < 1 || c.MaxBatchesPerRun > maxBatchesPerRun {
		return fmt.Errorf(
			"%w: max batches per run must be between 1 and %d",
			ErrInvalidConfig,
			maxBatchesPerRun,
		)
	}
	if c.OperationRetention != DefaultOperationRetention {
		return fmt.Errorf(
			"%w: operation retention must match the current 14-day schema contract",
			ErrInvalidConfig,
		)
	}
	if c.ProjectionRetention < minimumRetentionAge {
		return fmt.Errorf("%w: projection retention must be at least one hour", ErrInvalidConfig)
	}
	return nil
}
