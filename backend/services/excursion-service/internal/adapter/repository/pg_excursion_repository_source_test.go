package repository

import (
	"os"
	"strings"
	"testing"
)

func TestListExcursionLanguageCodesByGuideUserIDsAggregatesExcursionsAndOffers(t *testing.T) {
	source, err := os.ReadFile("pg_excursion_repository.go")
	if err != nil {
		t.Fatalf("read pg_excursion_repository.go: %v", err)
	}

	body := string(source)
	start := strings.Index(body, "func (r *PGExcursionRepository) ListExcursionLanguageCodesByGuideUserIDs")
	if start < 0 {
		t.Fatal("ListExcursionLanguageCodesByGuideUserIDs not found")
	}
	end := strings.Index(body[start:], "func excursionOfferOrderBy")
	if end < 0 {
		t.Fatal("ListExcursionLanguageCodesByGuideUserIDs end marker not found")
	}
	fn := body[start : start+end]

	if !strings.Contains(fn, "FROM excursions o") ||
		!strings.Contains(fn, "JOIN excursion_languages l") {
		t.Fatal("guide excursion language query does not read excursion languages")
	}
	if !strings.Contains(fn, "FROM excursion_offers o") ||
		!strings.Contains(fn, "JOIN excursion_offer_languages l") {
		t.Fatal("guide excursion language query does not read offer languages")
	}
	if !strings.Contains(fn, "UNION ALL") {
		t.Fatal("guide excursion language query should union excursion and offer languages")
	}
}
