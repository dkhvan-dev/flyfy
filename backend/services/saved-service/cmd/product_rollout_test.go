package main

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
	"kz/inflap/backend/services/saved-service/internal/config"
)

func TestSavedProductRolloutConfigMapsStaticFlagsBuildsAndSupportedEntities(t *testing.T) {
	t.Parallel()

	cfg := config.Config{
		Features: config.FeatureConfig{
			SavedItemsEnabled:  true,
			SearchEnabled:      false,
			CollectionsEnabled: true,
		},
		Rollout: config.RolloutConfig{
			AndroidMinimumBuild:    42,
			IOSMinimumBuild:        84,
			CoreBasisPoints:        10_000,
			SearchBasisPoints:      10_000,
			CollectionsBasisPoints: 10_000,
			AttractionBasisPoints:  10_000,
			ActivityBasisPoints:    10_000,
			UserBasisPoints:        10_000,
		},
	}
	evaluator, err := productrollout.NewEvaluator(savedProductRolloutConfig(cfg))
	if err != nil {
		t.Fatalf("NewEvaluator() error = %v", err)
	}
	ownerID := uuid.MustParse("22222222-2222-4222-8222-222222222222")

	below, err := evaluator.Evaluate(context.Background(), productrollout.Request{
		OwnerID: ownerID, Platform: productrollout.PlatformAndroid, Build: 41,
	})
	if err != nil || below != (productrollout.Decision{}) {
		t.Fatalf("below-minimum decision = (%#v, %v)", below, err)
	}

	decision, err := evaluator.Evaluate(context.Background(), productrollout.Request{
		OwnerID: ownerID, Platform: productrollout.PlatformAndroid, Build: 42,
	})
	if err != nil {
		t.Fatalf("Evaluate() error = %v", err)
	}
	if !decision.SavedCore || decision.SavedSearch || !decision.SavedCollections ||
		!decision.Entities.Attraction || !decision.Entities.Activity ||
		!decision.Entities.User {
		t.Fatalf("decision = %#v", decision)
	}
}
