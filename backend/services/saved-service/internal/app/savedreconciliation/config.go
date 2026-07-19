package savedreconciliation

import "time"

const (
	DefaultBatchSize          = 16
	DefaultStaleAfter         = 6 * time.Hour
	DefaultRunTimeout         = 90 * time.Second
	DefaultResolveTimeout     = time.Second
	DefaultResolveAttempts    = 2
	DefaultRepositoryAttempts = 2
	DefaultRetryBase          = 50 * time.Millisecond
	DefaultRetryMax           = 250 * time.Millisecond
	DefaultLeaseDuration      = 30 * time.Second
	DefaultFailureBackoffBase = 30 * time.Second
	DefaultFailureBackoffMax  = 30 * time.Minute
	DefaultPermanentFailures  = 3

	maxBatchSize          = 500
	maxRunTimeout         = 10 * time.Minute
	maxResolveTimeout     = 2 * time.Second
	maxAttempts           = 3
	maxStaleAfter         = 30 * 24 * time.Hour
	maxLeaseDuration      = 5 * time.Minute
	maxFailureBackoff     = 24 * time.Hour
	maxPermanentFailures  = 10
	minimumRunTimeout     = time.Second
	minimumStaleAfter     = time.Minute
	minimumLeaseDuration  = time.Second
	minimumFailureBackoff = time.Second
)

// Config bounds database work, source calls, retries, and total wall time for
// one scheduler invocation.
type Config struct {
	BatchSize          int
	StaleAfter         time.Duration
	RunTimeout         time.Duration
	ResolveTimeout     time.Duration
	ResolveAttempts    int
	RepositoryAttempts int
	RetryBase          time.Duration
	RetryMax           time.Duration
	LeaseDuration      time.Duration
	FailureBackoffBase time.Duration
	FailureBackoffMax  time.Duration
	PermanentFailures  int
}

func DefaultConfig() Config {
	return Config{
		BatchSize:          DefaultBatchSize,
		StaleAfter:         DefaultStaleAfter,
		RunTimeout:         DefaultRunTimeout,
		ResolveTimeout:     DefaultResolveTimeout,
		ResolveAttempts:    DefaultResolveAttempts,
		RepositoryAttempts: DefaultRepositoryAttempts,
		RetryBase:          DefaultRetryBase,
		RetryMax:           DefaultRetryMax,
		LeaseDuration:      DefaultLeaseDuration,
		FailureBackoffBase: DefaultFailureBackoffBase,
		FailureBackoffMax:  DefaultFailureBackoffMax,
		PermanentFailures:  DefaultPermanentFailures,
	}
}

func (c Config) Validate() error {
	if c.BatchSize < 1 || c.BatchSize > maxBatchSize ||
		c.StaleAfter < minimumStaleAfter || c.StaleAfter > maxStaleAfter ||
		c.RunTimeout < minimumRunTimeout || c.RunTimeout > maxRunTimeout ||
		c.ResolveTimeout <= 0 || c.ResolveTimeout > maxResolveTimeout ||
		c.ResolveAttempts < 1 || c.ResolveAttempts > maxAttempts ||
		c.RepositoryAttempts < 1 || c.RepositoryAttempts > maxAttempts ||
		c.RetryBase <= 0 || c.RetryMax < c.RetryBase ||
		c.RetryMax > time.Second ||
		c.LeaseDuration < minimumLeaseDuration || c.LeaseDuration > maxLeaseDuration ||
		c.FailureBackoffBase < minimumFailureBackoff ||
		c.FailureBackoffMax < c.FailureBackoffBase ||
		c.FailureBackoffMax > maxFailureBackoff ||
		c.PermanentFailures < 1 || c.PermanentFailures > maxPermanentFailures {
		return ErrInvalidConfig
	}
	resolveBudget := time.Duration(c.ResolveAttempts)*c.ResolveTimeout +
		time.Duration(c.ResolveAttempts-1)*c.RetryMax
	repositoryRetryBudget := time.Duration(c.RepositoryAttempts-1) * c.RetryMax
	if c.LeaseDuration <= resolveBudget+repositoryRetryBudget {
		return ErrInvalidConfig
	}
	worstCaseRunBudget := time.Duration(c.BatchSize)*(resolveBudget+2*repositoryRetryBudget) +
		repositoryRetryBudget
	if worstCaseRunBudget > c.RunTimeout {
		return ErrInvalidConfig
	}
	return nil
}
