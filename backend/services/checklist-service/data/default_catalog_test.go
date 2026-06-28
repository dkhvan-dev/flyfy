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
	if template, ok := findTemplate(seed, "documents.passport_id"); !ok || !template.AppliesTo.Always {
		t.Fatalf("expected passport/id to apply to every trip, got %#v", template.AppliesTo)
	}
	if template, ok := findTemplate(seed, "documents.entry_requirements_self_check"); !ok || !template.AppliesTo.InternationalTrip {
		t.Fatalf("expected entry requirements to apply to international trips, got %#v", template.AppliesTo)
	}
	if !hasTemplate(seed, "baggage.power_bank_carry_on", model.ChecklistPriorityRecommended) {
		t.Fatal("expected recommended power bank template")
	}
	if !hasTemplate(seed, "baggage.liquids_100ml", model.ChecklistPriorityRecommended) {
		t.Fatal("expected recommended liquids template")
	}
	if !hasTemplate(seed, "money.esim_offline_map", model.ChecklistPriorityRecommended) {
		t.Fatal("expected recommended connectivity template")
	}
	if template, ok := findTemplate(seed, "documents.bookings_offline"); !ok ||
		template.Title.RU != "Сохранить билеты и брони" ||
		template.Title.EN != "Save tickets and bookings" ||
		template.Title.KK != "Билеттер мен броньдарды сақтау" ||
		template.Reason.EN != "Download, add to Wallet, or print tickets, accommodation bookings, activity confirmations, and transfers for poor network moments." ||
		template.Reason.RU != "Скачайте, добавьте в Wallet или распечатайте билеты, брони жилья, активности и трансферы на случай плохой связи." ||
		template.Reason.KK != "Байланыс нашар болғанда қажет болуы үшін билеттерді, қонақүй броньдарын, белсенділік растауларын және трансферлерді жүктеп алыңыз, Wallet-ке қосыңыз немесе басып шығарыңыз." {
		t.Fatalf("expected clear offline bookings wording, got %#v", template)
	}
	if !hasCarryRule(seed, "power_bank", model.TransportModeFlight) {
		t.Fatal("expected flight power bank carry rule")
	}
	if !hasSeasonalProfile(seed, "JP", "Tokyo", time.July) {
		t.Fatal("expected Tokyo July seasonal profile")
	}
}

func hasTemplate(seed model.CatalogSeed, id string, priority model.ChecklistPriority) bool {
	template, ok := findTemplate(seed, id)
	return ok && template.Priority == priority
}

func findTemplate(seed model.CatalogSeed, id string) (model.ChecklistTemplate, bool) {
	for _, template := range seed.Templates {
		if template.ID == id {
			return template, true
		}
	}
	return model.ChecklistTemplate{}, false
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
