package config

import "testing"

func TestFeatureConfigValidate(t *testing.T) {
	limits := OwnerLimitsConfig{MaxActiveSaves: 10_000}
	tests := []struct {
		name    string
		config  FeatureConfig
		wantErr bool
	}{
		{
			name: "valid staged rollout",
			config: FeatureConfig{
				CapabilityRevision:    "saved-2026.07-v1",
				SavedItemsEnabled:     true,
				QuotaWarningRemaining: 100,
			},
		},
		{
			name: "child feature without Saved",
			config: FeatureConfig{
				CapabilityRevision: "saved-v1",
				SearchEnabled:      true,
			},
			wantErr: true,
		},
		{
			name: "unstable revision",
			config: FeatureConfig{
				CapabilityRevision: " saved v1 ",
				SavedItemsEnabled:  true,
			},
			wantErr: true,
		},
		{
			name: "warning over hard bound",
			config: FeatureConfig{
				CapabilityRevision:    "saved-v1",
				SavedItemsEnabled:     true,
				QuotaWarningRemaining: hardMaxQuotaWarningRemaining + 1,
			},
			wantErr: true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			err := test.config.Validate(limits)
			if (err != nil) != test.wantErr {
				t.Fatalf("Validate() error = %v, wantErr %v", err, test.wantErr)
			}
		})
	}
}

func TestRolloutConfigValidate(t *testing.T) {
	valid := RolloutConfig{
		AndroidMinimumBuild:    1,
		IOSMinimumBuild:        1,
		CoreBasisPoints:        10_000,
		SearchBasisPoints:      5_000,
		CollectionsBasisPoints: 1,
		AttractionBasisPoints:  10_000,
		ActivityBasisPoints:    10_000,
		UserBasisPoints:        10_000,
	}
	if err := valid.Validate(); err != nil {
		t.Fatalf("Validate(valid) error = %v", err)
	}

	invalidBuild := valid
	invalidBuild.AndroidMinimumBuild = 0
	if err := invalidBuild.Validate(); err == nil {
		t.Fatal("Validate() accepted zero minimum build")
	}

	invalidPercentage := valid
	invalidPercentage.UserBasisPoints = rolloutCohortCount + 1
	if err := invalidPercentage.Validate(); err == nil {
		t.Fatal("Validate() accepted basis points above cohort size")
	}
}
