package savedoutbox

import (
	"fmt"
	"time"
)

const (
	defaultBatchSize      = 100
	defaultConcurrency    = 8
	defaultLeaseDuration  = 5 * time.Minute
	defaultPublishTimeout = 5 * time.Second
	defaultMaxAttempts    = 8
	defaultRetryBase      = time.Second
	defaultRetryMax       = 15 * time.Minute
	defaultCleanupBatch   = 500
)

type Config struct {
	BatchSize      int
	Concurrency    int
	LeaseDuration  time.Duration
	PublishTimeout time.Duration
	MaxAttempts    int
	RetryBase      time.Duration
	RetryMax       time.Duration
	CleanupBatch   int
}

func DefaultConfig() Config {
	return Config{
		BatchSize:      defaultBatchSize,
		Concurrency:    defaultConcurrency,
		LeaseDuration:  defaultLeaseDuration,
		PublishTimeout: defaultPublishTimeout,
		MaxAttempts:    defaultMaxAttempts,
		RetryBase:      defaultRetryBase,
		RetryMax:       defaultRetryMax,
		CleanupBatch:   defaultCleanupBatch,
	}
}

func (config Config) Validate() error {
	switch {
	case config.BatchSize < 1 || config.BatchSize > MaxClaimBatch:
		return fmt.Errorf("%w: batch size must be in [1,%d]", ErrInvalidConfig, MaxClaimBatch)
	case config.Concurrency < 1 || config.Concurrency > config.BatchSize:
		return fmt.Errorf("%w: concurrency must be in [1,batch size]", ErrInvalidConfig)
	case config.PublishTimeout <= 0 || config.PublishTimeout > 30*time.Second:
		return fmt.Errorf("%w: publish timeout must be in (0,30s]", ErrInvalidConfig)
	case config.LeaseDuration < minimumLeaseDuration(config) || config.LeaseDuration > time.Hour:
		return fmt.Errorf("%w: lease duration does not cover a bounded batch", ErrInvalidConfig)
	case config.MaxAttempts < 1 || config.MaxAttempts > MaxDeliveryAttempts:
		return fmt.Errorf("%w: max attempts must be in [1,%d]", ErrInvalidConfig, MaxDeliveryAttempts)
	case config.RetryBase < 100*time.Millisecond || config.RetryMax < config.RetryBase ||
		config.RetryMax > 24*time.Hour:
		return fmt.Errorf("%w: retry bounds are invalid", ErrInvalidConfig)
	case config.CleanupBatch < 1 || config.CleanupBatch > MaxCleanupBatch:
		return fmt.Errorf("%w: cleanup batch must be in [1,%d]", ErrInvalidConfig, MaxCleanupBatch)
	default:
		return nil
	}
}

func minimumLeaseDuration(config Config) time.Duration {
	waves := (config.BatchSize + config.Concurrency - 1) / config.Concurrency
	return 2 * time.Duration(waves) * config.PublishTimeout
}
