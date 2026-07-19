package productrollout_test

import (
	"context"
	"errors"
	"strconv"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
)

var testOwner = uuid.MustParse("7d444840-9dc0-11d1-b245-5ffdce74fad2")

func TestCohortForHasStableCapabilitySeparatedContract(t *testing.T) {
	t.Parallel()

	tests := []struct {
		capability productrollout.Capability
		want       uint16
	}{
		{capability: productrollout.CapabilitySavedCore, want: 268},
		{capability: productrollout.CapabilitySavedSearch, want: 2_815},
		{capability: productrollout.CapabilitySavedCollections, want: 3_236},
		{capability: productrollout.CapabilityEntityAttraction, want: 267},
		{capability: productrollout.CapabilityEntityActivity, want: 180},
		{capability: productrollout.CapabilityEntityUser, want: 5_240},
	}

	seen := make(map[uint16]productrollout.Capability, len(tests))
	for _, test := range tests {
		got, err := productrollout.CohortFor(testOwner, test.capability)
		if err != nil {
			t.Fatalf("CohortFor(%q) error = %v", test.capability, err)
		}
		if got != test.want {
			t.Errorf("CohortFor(%q) = %d, want %d", test.capability, got, test.want)
		}
		if got >= productrollout.CohortCount {
			t.Errorf("CohortFor(%q) = %d, outside cohort range", test.capability, got)
		}
		if previous, exists := seen[got]; exists {
			t.Errorf("capabilities %q and %q share test cohort %d", previous, test.capability, got)
		}
		seen[got] = test.capability

		repeated, err := productrollout.CohortFor(testOwner, test.capability)
		if err != nil || repeated != got {
			t.Errorf("CohortFor(%q) is not sticky: first=%d repeated=%d error=%v", test.capability, got, repeated, err)
		}
	}
}

func TestCohortForAlwaysStaysInRangeAndIsSticky(t *testing.T) {
	t.Parallel()

	for index := 0; index < 1_000; index++ {
		owner := uuid.NewSHA1(uuid.NameSpaceOID, []byte(strconv.Itoa(index)))
		for _, capability := range allCapabilities() {
			first, err := productrollout.CohortFor(owner, capability)
			if err != nil {
				t.Fatalf("CohortFor() error = %v", err)
			}
			second, err := productrollout.CohortFor(owner, capability)
			if err != nil || first != second || first >= productrollout.CohortCount {
				t.Fatalf("CohortFor() = (%d, %d, %v)", first, second, err)
			}
		}
	}
}

func TestCohortForRejectsInvalidInput(t *testing.T) {
	t.Parallel()

	if _, err := productrollout.CohortFor(uuid.Nil, productrollout.CapabilitySavedCore); !errors.Is(err, productrollout.ErrInvalidRequest) {
		t.Fatalf("CohortFor(nil owner) error = %v", err)
	}
	if _, err := productrollout.CohortFor(testOwner, productrollout.Capability("unknown")); !errors.Is(err, productrollout.ErrInvalidRequest) {
		t.Fatalf("CohortFor(unknown capability) error = %v", err)
	}
}

func TestEvaluatorHonorsZeroAndFullBasisPointBoundaries(t *testing.T) {
	t.Parallel()

	request := validRequest()
	for _, test := range []struct {
		name        string
		basisPoints int
		want        bool
	}{
		{name: "zero", basisPoints: 0, want: false},
		{name: "full", basisPoints: productrollout.CohortCount, want: true},
	} {
		t.Run(test.name, func(t *testing.T) {
			evaluator := mustEvaluator(t, configWithRule(enabledRule(test.basisPoints)))
			decision, err := evaluator.Evaluate(context.Background(), request)
			if err != nil {
				t.Fatalf("Evaluate() error = %v", err)
			}
			for _, capability := range allCapabilities() {
				if got := decision.Allows(capability); got != test.want {
					t.Errorf("Allows(%q) = %t, want %t", capability, got, test.want)
				}
			}
		})
	}
}

func TestEvaluatorUsesExclusiveUpperCohortBoundary(t *testing.T) {
	t.Parallel()

	cohort, err := productrollout.CohortFor(testOwner, productrollout.CapabilitySavedCore)
	if err != nil {
		t.Fatalf("CohortFor() error = %v", err)
	}
	request := validRequest()

	below := productrollout.Config{SavedCore: enabledRule(int(cohort))}
	decision, err := mustEvaluator(t, below).Evaluate(context.Background(), request)
	if err != nil || decision.SavedCore {
		t.Fatalf("Evaluate(basisPoints=cohort) = (%+v, %v), want disabled", decision, err)
	}

	above := productrollout.Config{SavedCore: enabledRule(int(cohort) + 1)}
	decision, err = mustEvaluator(t, above).Evaluate(context.Background(), request)
	if err != nil || !decision.SavedCore {
		t.Fatalf("Evaluate(basisPoints=cohort+1) = (%+v, %v), want enabled", decision, err)
	}
}

func TestEvaluatorDisabledRuleOverridesFullRollout(t *testing.T) {
	t.Parallel()

	rule := enabledRule(productrollout.CohortCount)
	rule.Enabled = false
	evaluator := mustEvaluator(t, productrollout.Config{SavedCore: rule})

	decision, err := evaluator.Evaluate(context.Background(), validRequest())
	if err != nil || decision.SavedCore {
		t.Fatalf("Evaluate(disabled rule) = (%+v, %v), want disabled", decision, err)
	}
}

func TestEvaluatorHonorsEnabledPlatformAndPerPlatformMinimumBuild(t *testing.T) {
	t.Parallel()

	config := productrollout.Config{
		SavedCore: ruleFor(productrollout.CohortCount, productrollout.PlatformAndroid),
		SavedSearch: productrollout.Rule{
			Enabled:          true,
			BasisPoints:      productrollout.CohortCount,
			AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid, productrollout.PlatformIOS},
			MinimumBuildByPlatform: map[productrollout.Platform]uint64{
				productrollout.PlatformAndroid: 100,
				productrollout.PlatformIOS:     200,
			},
		},
		SavedCollections: ruleFor(productrollout.CohortCount, productrollout.PlatformIOS),
		Entities: productrollout.EntityRules{
			Attraction: productrollout.Rule{
				Enabled:          true,
				BasisPoints:      productrollout.CohortCount,
				AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid},
				MinimumBuildByPlatform: map[productrollout.Platform]uint64{
					productrollout.PlatformAndroid: 50,
				},
			},
		},
	}
	evaluator := mustEvaluator(t, config)

	tests := []struct {
		name     string
		platform productrollout.Platform
		build    uint64
		want     productrollout.Decision
	}{
		{
			name:     "android below search minimum",
			platform: productrollout.PlatformAndroid,
			build:    99,
			want: productrollout.Decision{
				SavedCore: true,
				Entities:  productrollout.EntityDecision{Attraction: true},
			},
		},
		{
			name:     "android at search minimum",
			platform: productrollout.PlatformAndroid,
			build:    100,
			want: productrollout.Decision{
				SavedCore:   true,
				SavedSearch: true,
				Entities:    productrollout.EntityDecision{Attraction: true},
			},
		},
		{
			name:     "ios below search minimum",
			platform: productrollout.PlatformIOS,
			build:    199,
			want:     productrollout.Decision{},
		},
		{
			name:     "ios at search minimum",
			platform: productrollout.PlatformIOS,
			build:    200,
			want:     productrollout.Decision{},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			decision, err := evaluator.Evaluate(context.Background(), productrollout.Request{
				OwnerID:  testOwner,
				Platform: test.platform,
				Build:    test.build,
			})
			if err != nil || decision != test.want {
				t.Fatalf("Evaluate() = (%+v, %v), want %+v", decision, err, test.want)
			}
		})
	}
}

func TestEvaluatorMakesSavedCoreTheParentCapability(t *testing.T) {
	t.Parallel()

	config := configWithRule(enabledRule(productrollout.CohortCount))
	config.SavedCore = enabledRule(0)
	evaluator := mustEvaluator(t, config)

	decision, err := evaluator.Evaluate(context.Background(), validRequest())
	if err != nil {
		t.Fatalf("Evaluate() error = %v", err)
	}
	if decision != (productrollout.Decision{}) {
		t.Fatalf("decision = %#v, want all capabilities disabled", decision)
	}
}

func TestEvaluatorFailsClosedForInvalidRequest(t *testing.T) {
	t.Parallel()

	evaluator := mustEvaluator(t, configWithRule(enabledRule(productrollout.CohortCount)))
	tests := []struct {
		name    string
		ctx     context.Context
		request productrollout.Request
	}{
		{name: "nil context", request: validRequest()},
		{name: "nil owner", ctx: context.Background(), request: productrollout.Request{Platform: productrollout.PlatformAndroid, Build: 1}},
		{name: "unknown platform", ctx: context.Background(), request: productrollout.Request{OwnerID: testOwner, Platform: "web", Build: 1}},
		{name: "empty platform", ctx: context.Background(), request: productrollout.Request{OwnerID: testOwner, Build: 1}},
		{name: "unknown build", ctx: context.Background(), request: productrollout.Request{OwnerID: testOwner, Platform: productrollout.PlatformAndroid}},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			decision, err := evaluator.Evaluate(test.ctx, test.request)
			if decision != (productrollout.Decision{}) || !errors.Is(err, productrollout.ErrInvalidRequest) {
				t.Fatalf("Evaluate() = (%+v, %v), want zero decision and invalid request", decision, err)
			}
		})
	}
}

func TestEvaluatorPropagatesCanceledContextWithZeroDecision(t *testing.T) {
	t.Parallel()

	evaluator := mustEvaluator(t, configWithRule(enabledRule(productrollout.CohortCount)))
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	decision, err := evaluator.Evaluate(ctx, validRequest())
	if decision != (productrollout.Decision{}) || !errors.Is(err, context.Canceled) {
		t.Fatalf("Evaluate() = (%+v, %v), want zero decision and context cancellation", decision, err)
	}
}

func TestEvaluatorRejectsInvalidConfiguration(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		rule productrollout.Rule
	}{
		{name: "negative basis points", rule: ruleFor(-1, productrollout.PlatformAndroid)},
		{name: "basis points above maximum", rule: ruleFor(productrollout.CohortCount+1, productrollout.PlatformAndroid)},
		{name: "enabled without platform", rule: productrollout.Rule{Enabled: true, BasisPoints: 1}},
		{name: "unknown allowed platform", rule: ruleFor(1, productrollout.Platform("web"))},
		{name: "duplicate allowed platform", rule: productrollout.Rule{Enabled: true, BasisPoints: 1, AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid, productrollout.PlatformAndroid}}},
		{name: "too many allowed platforms", rule: productrollout.Rule{Enabled: true, BasisPoints: 1, AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid, productrollout.PlatformIOS, productrollout.PlatformAndroid}}},
		{name: "unknown minimum build platform", rule: productrollout.Rule{AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid}, MinimumBuildByPlatform: map[productrollout.Platform]uint64{"web": 1}}},
		{name: "minimum build platform not allowed", rule: productrollout.Rule{AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid}, MinimumBuildByPlatform: map[productrollout.Platform]uint64{productrollout.PlatformIOS: 1}}},
		{name: "zero minimum build", rule: productrollout.Rule{AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid}, MinimumBuildByPlatform: map[productrollout.Platform]uint64{productrollout.PlatformAndroid: 0}}},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := productrollout.NewEvaluator(productrollout.Config{SavedCore: test.rule})
			if !errors.Is(err, productrollout.ErrInvalidConfiguration) {
				t.Fatalf("NewEvaluator() error = %v", err)
			}
		})
	}
}

func TestEvaluatorAcceptsZeroConfigAndDefensivelyCompilesRules(t *testing.T) {
	t.Parallel()

	if _, err := productrollout.NewEvaluator(productrollout.Config{}); err != nil {
		t.Fatalf("NewEvaluator(zero config) error = %v", err)
	}

	platforms := []productrollout.Platform{productrollout.PlatformAndroid}
	minimumBuilds := map[productrollout.Platform]uint64{productrollout.PlatformAndroid: 10}
	evaluator := mustEvaluator(t, productrollout.Config{SavedCore: productrollout.Rule{
		Enabled:                true,
		BasisPoints:            productrollout.CohortCount,
		AllowedPlatforms:       platforms,
		MinimumBuildByPlatform: minimumBuilds,
	}})
	platforms[0] = productrollout.PlatformIOS
	minimumBuilds[productrollout.PlatformAndroid] = 100

	request := validRequest()
	request.Build = 10
	decision, err := evaluator.Evaluate(context.Background(), request)
	if err != nil || !decision.SavedCore {
		t.Fatalf("Evaluate() after source config mutation = (%+v, %v)", decision, err)
	}
}

func TestDecisionAllowsUnknownCapabilityFailsClosed(t *testing.T) {
	t.Parallel()

	decision := productrollout.Decision{SavedCore: true}
	if decision.Allows(productrollout.Capability("unknown")) {
		t.Fatal("Allows(unknown) = true")
	}
}

func enabledRule(basisPoints int) productrollout.Rule {
	return productrollout.Rule{
		Enabled:          true,
		BasisPoints:      basisPoints,
		AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid, productrollout.PlatformIOS},
	}
}

func ruleFor(basisPoints int, platforms ...productrollout.Platform) productrollout.Rule {
	return productrollout.Rule{
		Enabled:          true,
		BasisPoints:      basisPoints,
		AllowedPlatforms: platforms,
	}
}

func configWithRule(rule productrollout.Rule) productrollout.Config {
	return productrollout.Config{
		SavedCore:        rule,
		SavedSearch:      rule,
		SavedCollections: rule,
		Entities: productrollout.EntityRules{
			Attraction: rule,
			Activity:   rule,
			User:       rule,
		},
	}
}

func validRequest() productrollout.Request {
	return productrollout.Request{
		OwnerID:  testOwner,
		Platform: productrollout.PlatformAndroid,
		Build:    1,
	}
}

func mustEvaluator(t *testing.T, config productrollout.Config) *productrollout.Evaluator {
	t.Helper()

	evaluator, err := productrollout.NewEvaluator(config)
	if err != nil {
		t.Fatalf("NewEvaluator() error = %v", err)
	}
	return evaluator
}

func allCapabilities() []productrollout.Capability {
	return []productrollout.Capability{
		productrollout.CapabilitySavedCore,
		productrollout.CapabilitySavedSearch,
		productrollout.CapabilitySavedCollections,
		productrollout.CapabilityEntityAttraction,
		productrollout.CapabilityEntityActivity,
		productrollout.CapabilityEntityUser,
	}
}
