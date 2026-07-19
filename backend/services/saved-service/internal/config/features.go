package config

import (
	"fmt"
	"regexp"
	"strings"
)

const hardMaxQuotaWarningRemaining = 1_000

const rolloutCohortCount = 10_000

var capabilityRevisionPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$`)

// FeatureConfig controls product exposure independently from the emergency
// personal-data access policy, which is always evaluated by middleware first.
type FeatureConfig struct {
	CapabilityRevision    string `env:"SAVED_CAPABILITY_REVISION, default=saved-v1"`
	SavedItemsEnabled     bool   `env:"SAVED_ITEMS_PRODUCT_ENABLED, default=true"`
	SearchEnabled         bool   `env:"SAVED_SEARCH_PRODUCT_ENABLED, default=false"`
	CollectionsEnabled    bool   `env:"SAVED_COLLECTIONS_PRODUCT_ENABLED, default=false"`
	QuotaWarningRemaining int    `env:"SAVED_QUOTA_WARNING_REMAINING, default=100"`
}

// RolloutConfig deliberately keeps one minimum build per platform. Percentage
// controls remain capability-specific without introducing a remote flag store.
type RolloutConfig struct {
	AndroidMinimumBuild    uint64 `env:"SAVED_ROLLOUT_ANDROID_MIN_BUILD, default=1"`
	IOSMinimumBuild        uint64 `env:"SAVED_ROLLOUT_IOS_MIN_BUILD, default=1"`
	CoreBasisPoints        int    `env:"SAVED_ROLLOUT_CORE_BASIS_POINTS, default=10000"`
	SearchBasisPoints      int    `env:"SAVED_ROLLOUT_SEARCH_BASIS_POINTS, default=10000"`
	CollectionsBasisPoints int    `env:"SAVED_ROLLOUT_COLLECTIONS_BASIS_POINTS, default=10000"`
	AttractionBasisPoints  int    `env:"SAVED_ROLLOUT_ATTRACTION_BASIS_POINTS, default=10000"`
	ActivityBasisPoints    int    `env:"SAVED_ROLLOUT_ACTIVITY_BASIS_POINTS, default=10000"`
	UserBasisPoints        int    `env:"SAVED_ROLLOUT_USER_BASIS_POINTS, default=10000"`
	PostBasisPoints        int    `env:"SAVED_ROLLOUT_POST_BASIS_POINTS, default=10000"`
}

func (cfg RolloutConfig) Validate() error {
	if cfg.AndroidMinimumBuild == 0 || cfg.IOSMinimumBuild == 0 {
		return fmt.Errorf("Saved rollout minimum builds must be positive")
	}
	values := []int{
		cfg.CoreBasisPoints,
		cfg.SearchBasisPoints,
		cfg.CollectionsBasisPoints,
		cfg.AttractionBasisPoints,
		cfg.ActivityBasisPoints,
		cfg.UserBasisPoints,
		cfg.PostBasisPoints,
	}
	for _, value := range values {
		if value < 0 || value > rolloutCohortCount {
			return fmt.Errorf("Saved rollout basis points must be within [0, 10000]")
		}
	}
	return nil
}

func (cfg FeatureConfig) Validate(limits OwnerLimitsConfig) error {
	revision := strings.TrimSpace(cfg.CapabilityRevision)
	if revision != cfg.CapabilityRevision || !capabilityRevisionPattern.MatchString(revision) {
		return fmt.Errorf("SAVED_CAPABILITY_REVISION must be a stable 1-128 character identifier")
	}
	if !cfg.SavedItemsEnabled && (cfg.SearchEnabled || cfg.CollectionsEnabled) {
		return fmt.Errorf("Saved search and collections require SAVED_ITEMS_PRODUCT_ENABLED=true")
	}
	if cfg.QuotaWarningRemaining < 0 ||
		cfg.QuotaWarningRemaining > hardMaxQuotaWarningRemaining ||
		cfg.QuotaWarningRemaining > limits.MaxActiveSaves {
		return fmt.Errorf("SAVED_QUOTA_WARNING_REMAINING must be within [0, min(1000, OWNER_MAX_ACTIVE_SAVES)]")
	}
	return nil
}
