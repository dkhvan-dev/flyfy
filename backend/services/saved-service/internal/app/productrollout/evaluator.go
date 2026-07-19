package productrollout

import (
	"context"
	"fmt"

	"github.com/google/uuid"
)

type platformConstraint struct {
	allowed      bool
	minimumBuild uint64
}

type compiledRule struct {
	enabled     bool
	basisPoints uint16
	android     platformConstraint
	ios         platformConstraint
}

type Evaluator struct {
	rules map[Capability]compiledRule
}

var _ Gate = (*Evaluator)(nil)

func NewEvaluator(config Config) (*Evaluator, error) {
	rules := make(map[Capability]compiledRule, len(capabilities))
	for _, capability := range capabilities {
		compiled, err := compileRule(capability, config.rule(capability))
		if err != nil {
			return nil, err
		}
		rules[capability] = compiled
	}

	return &Evaluator{rules: rules}, nil
}

// Evaluate is side-effect free. Invalid request metadata returns a zero
// decision, so expansion fails closed.
func (evaluator *Evaluator) Evaluate(ctx context.Context, request Request) (Decision, error) {
	if evaluator == nil {
		return Decision{}, ErrInvalidConfiguration
	}
	if ctx == nil || request.OwnerID == uuid.Nil || !request.Platform.IsValid() || request.Build == 0 {
		return Decision{}, ErrInvalidRequest
	}
	if err := ctx.Err(); err != nil {
		return Decision{}, err
	}

	decision := Decision{}
	for _, capability := range capabilities {
		rule := evaluator.rules[capability]
		decision.set(capability, rule.allows(request, capability))
	}
	if !decision.SavedCore {
		decision.SavedSearch = false
		decision.SavedCollections = false
		decision.Entities = EntityDecision{}
	}
	return decision, nil
}

func compileRule(capability Capability, rule Rule) (compiledRule, error) {
	if rule.BasisPoints < 0 || rule.BasisPoints > CohortCount {
		return compiledRule{}, invalidRule(capability, "basis points must be between 0 and 10000")
	}
	if rule.Enabled && len(rule.AllowedPlatforms) == 0 {
		return compiledRule{}, invalidRule(capability, "enabled rule requires an allowed platform")
	}
	if len(rule.AllowedPlatforms) > 2 {
		return compiledRule{}, invalidRule(capability, "allowed platforms contain duplicates or unknown values")
	}

	compiled := compiledRule{
		enabled:     rule.Enabled,
		basisPoints: uint16(rule.BasisPoints),
	}
	for _, platform := range rule.AllowedPlatforms {
		constraint, ok := compiled.constraint(platform)
		if !ok {
			return compiledRule{}, invalidRule(capability, "allowed platform is unknown")
		}
		if constraint.allowed {
			return compiledRule{}, invalidRule(capability, "allowed platform is duplicated")
		}
		constraint.allowed = true
		compiled.setConstraint(platform, constraint)
	}

	for platform, minimumBuild := range rule.MinimumBuildByPlatform {
		if !platform.IsValid() {
			return compiledRule{}, invalidRule(capability, "minimum build platform is unknown")
		}
		if minimumBuild == 0 {
			return compiledRule{}, invalidRule(capability, "minimum build must be positive")
		}
		constraint, _ := compiled.constraint(platform)
		if !constraint.allowed {
			return compiledRule{}, invalidRule(capability, "minimum build platform is not allowed")
		}
		constraint.minimumBuild = minimumBuild
		compiled.setConstraint(platform, constraint)
	}

	return compiled, nil
}

func (rule compiledRule) allows(request Request, capability Capability) bool {
	if !rule.enabled {
		return false
	}
	constraint, ok := rule.constraint(request.Platform)
	if !ok || !constraint.allowed || request.Build < constraint.minimumBuild {
		return false
	}

	return int(cohortForValid(request.OwnerID, capability)) < int(rule.basisPoints)
}

func (rule compiledRule) constraint(platform Platform) (platformConstraint, bool) {
	switch platform {
	case PlatformAndroid:
		return rule.android, true
	case PlatformIOS:
		return rule.ios, true
	default:
		return platformConstraint{}, false
	}
}

func (rule *compiledRule) setConstraint(platform Platform, constraint platformConstraint) {
	switch platform {
	case PlatformAndroid:
		rule.android = constraint
	case PlatformIOS:
		rule.ios = constraint
	}
}

func invalidRule(capability Capability, reason string) error {
	return fmt.Errorf("%w: %s: %s", ErrInvalidConfiguration, capability, reason)
}
