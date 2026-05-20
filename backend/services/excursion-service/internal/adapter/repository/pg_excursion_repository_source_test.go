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

func TestReviewQueriesExcludeSoftDeletedRowsAndGuideStatsUseBothReviewSources(t *testing.T) {
	source, err := os.ReadFile("pg_excursion_repository.go")
	if err != nil {
		t.Fatalf("read pg_excursion_repository.go: %v", err)
	}
	body := string(source)

	listStart := strings.Index(body, "func (r *PGExcursionRepository) ListExcursionReviews")
	listEnd := strings.Index(body[listStart:], "func (r *PGExcursionRepository) CalculateLandmarkReviewStats")
	if listStart < 0 || listEnd < 0 {
		t.Fatal("ListExcursionReviews boundaries not found")
	}
	listFn := body[listStart : listStart+listEnd]
	if !strings.Contains(listFn, "deleted_at IS NULL") {
		t.Fatal("ListExcursionReviews must exclude soft-deleted excursion reviews")
	}

	statsStart := strings.Index(body, "func (r *PGExcursionRepository) CalculateLandmarkReviewStats")
	statsEnd := strings.Index(body[statsStart:], "type dbExecutor")
	if statsStart < 0 || statsEnd < 0 {
		t.Fatal("CalculateLandmarkReviewStats boundaries not found")
	}
	statsFn := body[statsStart : statsStart+statsEnd]
	if !strings.Contains(statsFn, "deleted_at IS NULL") {
		t.Fatal("CalculateLandmarkReviewStats must exclude soft-deleted excursion reviews")
	}

	guideStart := strings.Index(body, "func (r *PGExcursionRepository) CalculateGuideReviewStats")
	guideEnd := strings.Index(body[guideStart:], "const (")
	if guideStart < 0 || guideEnd < 0 {
		t.Fatal("CalculateGuideReviewStats boundaries not found")
	}
	guideFn := body[guideStart : guideStart+guideEnd]
	for _, want := range []string{
		"FROM excursion_reviews er",
		"FROM guide_reviews gr",
		"er.deleted_at IS NULL",
		"gr.deleted_at IS NULL",
		"UNION ALL",
		"s.status = 'COMPLETED'",
	} {
		if !strings.Contains(guideFn, want) {
			t.Fatalf("CalculateGuideReviewStats missing %q", want)
		}
	}
}

func TestBookingListQueryIncludesActiveGuideReviews(t *testing.T) {
	source, err := os.ReadFile("pg_excursion_repository.go")
	if err != nil {
		t.Fatalf("read pg_excursion_repository.go: %v", err)
	}
	body := string(source)

	start := strings.Index(body, "func (r *PGExcursionRepository) ListExcursionBookings")
	end := strings.Index(body[start:], "func (r *PGExcursionRepository) GetExcursionBookingByID")
	if start < 0 || end < 0 {
		t.Fatal("ListExcursionBookings boundaries not found")
	}
	fn := body[start : start+end]
	if !strings.Contains(fn, "LEFT JOIN guide_reviews") {
		t.Fatal("ListExcursionBookings must include direct guide reviews")
	}
	if !strings.Contains(fn, "gr.deleted_at IS NULL") {
		t.Fatal("ListExcursionBookings must exclude soft-deleted direct guide reviews")
	}
}
