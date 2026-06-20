package port

import "context"

type FeatureFlagType string

const (
	FeatureFlagTypeToggle       FeatureFlagType = "TOGGLE"
	FeatureFlagTypeArrayString  FeatureFlagType = "ARRAY_STRING"
	FeatureFlagTypeArrayInteger FeatureFlagType = "ARRAY_INTEGER"
)

type FeatureFlag struct {
	Enabled bool
	Type    FeatureFlagType
	Values  []string
}

type FeatureFlagReader interface {
	GetFeatureFlag(ctx context.Context, domainCode string, code string) (FeatureFlag, error)
}

type TechBreakCheckInput struct {
	DomainCode string
	Nickname   string
	Email      string
	ScopeCodes []string
}

type TechBreakChecker interface {
	HasActiveTechBreak(ctx context.Context, input TechBreakCheckInput) (bool, error)
}
