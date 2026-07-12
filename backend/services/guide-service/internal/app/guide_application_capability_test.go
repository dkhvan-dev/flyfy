package app

import "testing"

func TestApplyDefaultGuideApplicationCapabilitiesEnablesExcursions(t *testing.T) {
	input := SubmitGuideApplicationInput{}

	applyDefaultGuideApplicationCapabilities(&input)

	if input.IsExcursionGuideAvailable == nil || !*input.IsExcursionGuideAvailable {
		t.Fatal("missing application capabilities must default to excursions")
	}
	if input.IsPrivateGuideAvailable != nil || input.IsActivityHostAvailable != nil {
		t.Fatal("unrequested guide capabilities must remain unset")
	}
}

func TestApplyDefaultGuideApplicationCapabilitiesPreservesExplicitSelection(t *testing.T) {
	disabled := false
	input := SubmitGuideApplicationInput{
		IsExcursionGuideAvailable: &disabled,
	}

	applyDefaultGuideApplicationCapabilities(&input)

	if input.IsExcursionGuideAvailable == nil || *input.IsExcursionGuideAvailable {
		t.Fatal("an explicit excursion capability selection must be preserved")
	}
}
