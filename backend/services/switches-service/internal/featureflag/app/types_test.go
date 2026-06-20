package app

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestDomainResponseDoesNotExposeTechBreakValueCategories(t *testing.T) {
	t.Parallel()

	payload, err := json.Marshal(DomainResponse{
		ID:                1,
		Code:              "CORE",
		Description:       "Core",
		FeatureFlagGroups: []string{"onboarding"},
	})
	if err != nil {
		t.Fatalf("marshal DomainResponse: %v", err)
	}
	if strings.Contains(string(payload), "techBreakValueCategories") {
		t.Fatalf("DomainResponse must not expose techBreakValueCategories: %s", payload)
	}
}
