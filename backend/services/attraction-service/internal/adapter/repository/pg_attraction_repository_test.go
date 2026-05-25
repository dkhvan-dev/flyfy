package repository

import (
	"os"
	"strings"
	"testing"
)

func TestAttractionListOrderBySupportsSortDirections(t *testing.T) {
	tests := map[string]string{
		"rating":        "a.rating DESC, a.review_count DESC, a.created_at DESC",
		"rating_desc":   "a.rating DESC, a.review_count DESC, a.created_at DESC",
		"rating_asc":    "a.rating ASC, a.review_count DESC, a.created_at DESC",
		"price_asc":     "a.price_amount ASC NULLS LAST, a.created_at DESC",
		"price_desc":    "a.price_amount DESC NULLS LAST, a.created_at DESC",
		"duration_asc":  "CASE WHEN a.duration_unit = 'DAYS' THEN a.duration_value * 24 ELSE a.duration_value END ASC NULLS LAST, a.created_at DESC",
		"duration_desc": "CASE WHEN a.duration_unit = 'DAYS' THEN a.duration_value * 24 ELSE a.duration_value END DESC NULLS LAST, a.created_at DESC",
		"unknown":       "a.created_at DESC",
	}

	for sort, expected := range tests {
		t.Run(sort, func(t *testing.T) {
			if got := attractionListOrderBy(sort); got != expected {
				t.Fatalf("order by mismatch\nexpected: %s\nactual:   %s", expected, got)
			}
		})
	}
}

func TestAttractionListPerformanceMigrationAddsQueryShapeIndexes(t *testing.T) {
	content, err := os.ReadFile("../../../migrations/021_attraction_list_performance_indexes.up.sql")
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}

	sql := string(content)
	requiredSnippets := []string{
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_latest",
		"ON attractions (country_code, city_id, created_at DESC, id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_category_latest",
		"ON attractions (country_code, city_id, category, created_at DESC, id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_rating",
		"ON attractions (country_code, city_id, rating DESC, review_count DESC, created_at DESC, id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_price",
		"price_amount IS NOT NULL",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attractions_active_country_city_duration_hours",
		"CASE WHEN duration_unit = 'DAYS' THEN duration_value * 24 ELSE duration_value END",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attraction_city_links_kind_city_attraction",
		"ON attraction_city_links (kind, city_id, attraction_id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_attraction_city_links_attraction_kind_position",
		"ON attraction_city_links (attraction_id, kind, position, city_id)",
		"WHERE deleted_at IS NULL",
	}
	for _, snippet := range requiredSnippets {
		if !strings.Contains(sql, snippet) {
			t.Fatalf("migration missing required snippet %q", snippet)
		}
	}
}
