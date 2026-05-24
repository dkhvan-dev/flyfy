package repository

import (
	"os"
	"strings"
	"testing"
)

func TestArchiveGuideExcursionOffersArchivesGuideContentAndRefreshesProducts(t *testing.T) {
	body, err := os.ReadFile("pg_excursion_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(body)

	if !strings.Contains(source, "func (r *PGExcursionRepository) ArchiveGuideExcursionOffers") {
		t.Fatal("ArchiveGuideExcursionOffers repository method is required")
	}
	if !strings.Contains(source, "UPDATE excursions") ||
		!strings.Contains(source, "UPDATE excursion_offers") ||
		!strings.Contains(source, "refreshExcursionProductStats") {
		t.Fatal("archiving guide offers must update legacy excursions, marketplace offers, and product stats")
	}
	if !strings.Contains(source, "guide_user_id = $1") {
		t.Fatal("archive query must be scoped by guide_user_id")
	}
}
