package productrollout

import (
	"context"

	"github.com/google/uuid"
)

const CohortCount = 10_000

// Capability is a closed code used both for rule lookup and cohort isolation.
type Capability string

const (
	CapabilitySavedCore        Capability = "saved_core"
	CapabilitySavedSearch      Capability = "saved_search"
	CapabilitySavedCollections Capability = "saved_collections"
	CapabilityEntityAttraction Capability = "entity_attraction"
	CapabilityEntityActivity   Capability = "entity_activity"
	CapabilityEntityUser       Capability = "entity_user"
	CapabilityEntityPost       Capability = "entity_post"
)

var capabilities = [...]Capability{
	CapabilitySavedCore,
	CapabilitySavedSearch,
	CapabilitySavedCollections,
	CapabilityEntityAttraction,
	CapabilityEntityActivity,
	CapabilityEntityUser,
	CapabilityEntityPost,
}

func (capability Capability) IsValid() bool {
	switch capability {
	case CapabilitySavedCore,
		CapabilitySavedSearch,
		CapabilitySavedCollections,
		CapabilityEntityAttraction,
		CapabilityEntityActivity,
		CapabilityEntityUser,
		CapabilityEntityPost:
		return true
	default:
		return false
	}
}

type Platform string

const (
	PlatformAndroid Platform = "android"
	PlatformIOS     Platform = "ios"
)

func (platform Platform) IsValid() bool {
	return platform == PlatformAndroid || platform == PlatformIOS
}

// Rule is a rollout rule supplied by environment-scoped configuration.
// A missing minimum build means that every positive build is eligible.
type Rule struct {
	Enabled                bool
	BasisPoints            int
	AllowedPlatforms       []Platform
	MinimumBuildByPlatform map[Platform]uint64
}

type EntityRules struct {
	Attraction Rule
	Activity   Rule
	User       Rule
	Post       Rule
}

type Config struct {
	SavedCore        Rule
	SavedSearch      Rule
	SavedCollections Rule
	Entities         EntityRules
}

type Request struct {
	OwnerID  uuid.UUID
	Platform Platform
	Build    uint64
}

type EntityDecision struct {
	Attraction bool
	Activity   bool
	User       bool
	Post       bool
}

type Decision struct {
	SavedCore        bool
	SavedSearch      bool
	SavedCollections bool
	Entities         EntityDecision
}

// Allows returns false for unknown capabilities.
func (decision Decision) Allows(capability Capability) bool {
	switch capability {
	case CapabilitySavedCore:
		return decision.SavedCore
	case CapabilitySavedSearch:
		return decision.SavedSearch
	case CapabilitySavedCollections:
		return decision.SavedCollections
	case CapabilityEntityAttraction:
		return decision.Entities.Attraction
	case CapabilityEntityActivity:
		return decision.Entities.Activity
	case CapabilityEntityUser:
		return decision.Entities.User
	case CapabilityEntityPost:
		return decision.Entities.Post
	default:
		return false
	}
}

// Gate keeps callers independent from the concrete in-memory evaluator.
type Gate interface {
	Evaluate(context.Context, Request) (Decision, error)
}

func (config Config) rule(capability Capability) Rule {
	switch capability {
	case CapabilitySavedCore:
		return config.SavedCore
	case CapabilitySavedSearch:
		return config.SavedSearch
	case CapabilitySavedCollections:
		return config.SavedCollections
	case CapabilityEntityAttraction:
		return config.Entities.Attraction
	case CapabilityEntityActivity:
		return config.Entities.Activity
	case CapabilityEntityUser:
		return config.Entities.User
	case CapabilityEntityPost:
		return config.Entities.Post
	default:
		return Rule{}
	}
}

func (decision *Decision) set(capability Capability, allowed bool) {
	switch capability {
	case CapabilitySavedCore:
		decision.SavedCore = allowed
	case CapabilitySavedSearch:
		decision.SavedSearch = allowed
	case CapabilitySavedCollections:
		decision.SavedCollections = allowed
	case CapabilityEntityAttraction:
		decision.Entities.Attraction = allowed
	case CapabilityEntityActivity:
		decision.Entities.Activity = allowed
	case CapabilityEntityUser:
		decision.Entities.User = allowed
	case CapabilityEntityPost:
		decision.Entities.Post = allowed
	}
}
