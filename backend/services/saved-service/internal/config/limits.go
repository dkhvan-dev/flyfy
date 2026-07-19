package config

import "fmt"

const (
	hardMaxActiveSaves              = 10_000
	hardMaxActiveCollections        = 200
	hardMaxMembershipsPerCollection = 5_000
	hardMaxMembershipsPerOwner      = 50_000
	hardMaxStatusBatchTargets       = 100
	hardMaxConcurrentOperations     = 32
	hardMaxDesiredCollectionIDs     = 200
	hardMaxPageSize                 = 100
	hardMaxSearchCodePoints         = 200
	hardMaxCollectionTitleCodePoint = 80
)

type OwnerLimitsConfig struct {
	MaxActiveSaves              int `env:"OWNER_MAX_ACTIVE_SAVES, default=10000"`
	MaxActiveCollections        int `env:"OWNER_MAX_ACTIVE_COLLECTIONS, default=200"`
	MaxMembershipsPerCollection int `env:"OWNER_MAX_MEMBERSHIPS_PER_COLLECTION, default=5000"`
	MaxMembershipsPerOwner      int `env:"OWNER_MAX_MEMBERSHIPS, default=50000"`
	MaxStatusBatchTargets       int `env:"OWNER_MAX_STATUS_BATCH_TARGETS, default=100"`
	MaxConcurrentOperations     int `env:"SUBJECT_MAX_PENDING_OPERATIONS, default=32"`
	MaxDesiredCollectionIDs     int `env:"OWNER_MAX_DESIRED_COLLECTION_IDS, default=200"`
	DefaultPageSize             int `env:"SAVED_DEFAULT_PAGE_SIZE, default=30"`
	MaxPageSize                 int `env:"SAVED_MAX_PAGE_SIZE, default=100"`
	MaxSearchCodePoints         int `env:"SAVED_MAX_SEARCH_CODE_POINTS, default=200"`
	MaxCollectionTitleCodePoint int `env:"SAVED_MAX_COLLECTION_TITLE_CODE_POINTS, default=80"`
}

func (limits OwnerLimitsConfig) Validate() error {
	checks := []struct {
		name  string
		value int
		max   int
	}{
		{name: "OWNER_MAX_ACTIVE_SAVES", value: limits.MaxActiveSaves, max: hardMaxActiveSaves},
		{name: "OWNER_MAX_ACTIVE_COLLECTIONS", value: limits.MaxActiveCollections, max: hardMaxActiveCollections},
		{name: "OWNER_MAX_MEMBERSHIPS_PER_COLLECTION", value: limits.MaxMembershipsPerCollection, max: hardMaxMembershipsPerCollection},
		{name: "OWNER_MAX_MEMBERSHIPS", value: limits.MaxMembershipsPerOwner, max: hardMaxMembershipsPerOwner},
		{name: "OWNER_MAX_STATUS_BATCH_TARGETS", value: limits.MaxStatusBatchTargets, max: hardMaxStatusBatchTargets},
		{name: "SUBJECT_MAX_PENDING_OPERATIONS", value: limits.MaxConcurrentOperations, max: hardMaxConcurrentOperations},
		{name: "OWNER_MAX_DESIRED_COLLECTION_IDS", value: limits.MaxDesiredCollectionIDs, max: hardMaxDesiredCollectionIDs},
		{name: "SAVED_MAX_PAGE_SIZE", value: limits.MaxPageSize, max: hardMaxPageSize},
		{name: "SAVED_MAX_SEARCH_CODE_POINTS", value: limits.MaxSearchCodePoints, max: hardMaxSearchCodePoints},
		{name: "SAVED_MAX_COLLECTION_TITLE_CODE_POINTS", value: limits.MaxCollectionTitleCodePoint, max: hardMaxCollectionTitleCodePoint},
	}
	for _, check := range checks {
		if check.value <= 0 || check.value > check.max {
			return fmt.Errorf("%s must be within [1, %d]", check.name, check.max)
		}
	}
	if limits.DefaultPageSize <= 0 || limits.DefaultPageSize > limits.MaxPageSize {
		return fmt.Errorf("SAVED_DEFAULT_PAGE_SIZE must be within [1, SAVED_MAX_PAGE_SIZE]")
	}
	if limits.MaxMembershipsPerCollection > limits.MaxMembershipsPerOwner {
		return fmt.Errorf("OWNER_MAX_MEMBERSHIPS_PER_COLLECTION must not exceed OWNER_MAX_MEMBERSHIPS")
	}
	if limits.MaxDesiredCollectionIDs > limits.MaxActiveCollections {
		return fmt.Errorf("OWNER_MAX_DESIRED_COLLECTION_IDS must not exceed OWNER_MAX_ACTIVE_COLLECTIONS")
	}
	return nil
}
