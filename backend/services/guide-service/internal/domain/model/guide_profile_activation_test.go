package model

import (
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
)

func TestGuideProfileActivateDefaultsCapabilitylessProfileToExcursions(t *testing.T) {
	profile, err := NewGuideProfile(NewGuideProfileParams{
		UserID: uuid.New(),
		Type:   enum.GuideTypeIndependent,
	})
	if err != nil {
		t.Fatalf("NewGuideProfile() error = %v", err)
	}

	if err = profile.Activate(); err != nil {
		t.Fatalf("Activate() error = %v", err)
	}

	if profile.Status != enum.GuideStatusActive {
		t.Fatalf("status = %q, want ACTIVE", profile.Status)
	}
	if !profile.IsExcursionGuideAvailable {
		t.Fatal("capabilityless approved profile must support excursions")
	}
}

func TestGuideProfileActivatePreservesExplicitCapabilitySelection(t *testing.T) {
	profile, err := NewGuideProfile(NewGuideProfileParams{
		UserID: uuid.New(),
		Type:   enum.GuideTypeIndependent,
	})
	if err != nil {
		t.Fatalf("NewGuideProfile() error = %v", err)
	}
	profile.IsPrivateGuideAvailable = true

	if err = profile.Activate(); err != nil {
		t.Fatalf("Activate() error = %v", err)
	}

	if profile.IsExcursionGuideAvailable {
		t.Fatal("activation must not add excursions to an explicit capability selection")
	}
}
