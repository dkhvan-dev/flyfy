package data

import (
	"testing"
	"time"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

func TestDefaultCatalogSeedContainsProductionBaseline(t *testing.T) {
	seed := DefaultCatalogSeed()

	if len(seed.Templates) < 8 {
		t.Fatalf("expected production baseline templates, got %d", len(seed.Templates))
	}
	if !hasTemplate(seed, "documents.passport_id", model.ChecklistPriorityCritical) {
		t.Fatal("expected critical passport/id template")
	}
	if !hasTemplate(seed, "documents.entry_requirements_self_check", model.ChecklistPriorityCritical) {
		t.Fatal("expected entry requirements self-check template")
	}
	if !hasCarryRule(seed, "power_bank", model.TransportModeFlight) {
		t.Fatal("expected flight power bank carry rule")
	}
	if !hasSeasonalProfile(seed, "JP", "Tokyo", time.July) {
		t.Fatal("expected Tokyo July seasonal profile")
	}
}

func hasTemplate(seed model.CatalogSeed, id string, priority model.ChecklistPriority) bool {
	for _, template := range seed.Templates {
		if template.ID == id && template.Priority == priority {
			return true
		}
	}
	return false
}

func hasCarryRule(seed model.CatalogSeed, itemSlug string, transportMode model.TransportMode) bool {
	for _, rule := range seed.CarryRules {
		if rule.ItemSlug == itemSlug && rule.TransportMode == transportMode {
			return true
		}
	}
	return false
}

func hasSeasonalProfile(seed model.CatalogSeed, countryCode string, cityName string, month time.Month) bool {
	for _, profile := range seed.SeasonalProfiles {
		if profile.Destination.CountryCode == countryCode &&
			profile.Destination.CityName == cityName &&
			profile.Month == month {
			return true
		}
	}
	return false
}
