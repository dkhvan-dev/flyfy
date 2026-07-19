package repository

import (
	"os"
	"strings"
	"testing"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

func TestPlaceListOrderBySupportsSortDirections(t *testing.T) {
	lat := 43.238949
	lon := 76.889709
	tests := map[string]string{
		"rating":        "a.rating DESC, a.review_count DESC, a.created_at DESC",
		"rating_desc":   "a.rating DESC, a.review_count DESC, a.created_at DESC",
		"rating_asc":    "a.rating ASC, a.review_count DESC, a.created_at DESC",
		"price_asc":     "a.price_amount ASC NULLS LAST, a.created_at DESC",
		"price_desc":    "a.price_amount DESC NULLS LAST, a.created_at DESC",
		"duration_asc":  "CASE WHEN a.duration_unit = 'DAYS' THEN a.duration_value * 24 ELSE a.duration_value END ASC NULLS LAST, a.created_at DESC",
		"duration_desc": "CASE WHEN a.duration_unit = 'DAYS' THEN a.duration_value * 24 ELSE a.duration_value END DESC NULLS LAST, a.created_at DESC",
		"distance":      "CASE WHEN a.latitude IS NULL OR a.longitude IS NULL THEN NULL ELSE ((a.latitude - $7) * (a.latitude - $7)) + ((a.longitude - $8) * (a.longitude - $8) * COS(RADIANS($7)) * COS(RADIANS($7))) END ASC NULLS LAST, a.rating DESC, a.review_count DESC, a.created_at DESC",
		"unknown":       "a.created_at DESC",
	}

	for sort, expected := range tests {
		t.Run(sort, func(t *testing.T) {
			filter := model.PlaceListFilter{Sort: sort}
			if sort == "distance" {
				filter.Latitude = &lat
				filter.Longitude = &lon
			}
			if got := placeListOrderBy(filter, 7, 8); got != expected {
				t.Fatalf("order by mismatch\nexpected: %s\nactual:   %s", expected, got)
			}
		})
	}
}

func TestPlaceListOrderByIgnoresDistanceWithoutCoordinates(t *testing.T) {
	lat := 43.238949

	tests := map[string]model.PlaceListFilter{
		"missing_both":      {Sort: "distance"},
		"missing_longitude": {Sort: "distance", Latitude: &lat},
	}

	for name, filter := range tests {
		t.Run(name, func(t *testing.T) {
			if got := placeListOrderBy(filter, 7, 8); got != "a.created_at DESC" {
				t.Fatalf("order by = %q, want latest fallback", got)
			}
		})
	}
}

func TestPlaceListPerformanceMigrationAddsQueryShapeIndexes(t *testing.T) {
	content, err := os.ReadFile("../../../migrations/021_place_list_performance_indexes.up.sql")
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}

	sql := string(content)
	requiredSnippets := []string{
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_places_active_country_city_latest",
		"ON places (country_code, city_id, created_at DESC, id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_places_active_country_city_category_latest",
		"ON places (country_code, city_id, category, created_at DESC, id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_places_active_country_city_rating",
		"ON places (country_code, city_id, rating DESC, review_count DESC, created_at DESC, id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_places_active_country_city_price",
		"price_amount IS NOT NULL",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_places_active_country_city_duration_hours",
		"CASE WHEN duration_unit = 'DAYS' THEN duration_value * 24 ELSE duration_value END",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_place_city_links_kind_city_place",
		"ON place_city_links (kind, city_id, place_id)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_place_city_links_place_kind_position",
		"ON place_city_links (place_id, kind, position, city_id)",
		"WHERE deleted_at IS NULL",
	}
	for _, snippet := range requiredSnippets {
		if !strings.Contains(sql, snippet) {
			t.Fatalf("migration missing required snippet %q", snippet)
		}
	}
}

func TestSavedSourceRevisionMigrationOwnsMonotonicProjectionAndVisibilityChanges(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/214_saved_source_revisions.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/214_saved_source_revisions.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := string(up)
	for _, required := range []string{
		"place_saved_source_revision_seq",
		"saved_source_revision BIGINT",
		"saved_projection_revision BIGINT",
		"saved_visibility_revision BIGINT",
		"CHECK (saved_source_revision > 0)",
		"CHECK (saved_projection_revision > 0)",
		"CHECK (saved_visibility_revision > 0)",
		"DROP CONSTRAINT IF EXISTS chk_places_saved_source_revision_positive",
		"BEFORE UPDATE ON places",
		"NEW.status IS DISTINCT FROM OLD.status",
		"NEW.deleted_at IS DISTINCT FROM OLD.deleted_at",
		"AFTER INSERT OR UPDATE OR DELETE ON place_translations",
		"AFTER INSERT OR UPDATE OR DELETE ON place_media",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q", required)
		}
	}

	downSQL := string(down)
	for _, required := range []string{
		"DROP TRIGGER IF EXISTS trg_place_media_saved_source_revisions",
		"DROP TRIGGER IF EXISTS trg_place_translations_saved_source_revisions",
		"DROP TRIGGER IF EXISTS trg_places_saved_source_revisions",
		"DROP COLUMN IF EXISTS saved_visibility_revision",
		"DROP COLUMN IF EXISTS saved_projection_revision",
		"DROP COLUMN IF EXISTS saved_source_revision",
		"DROP SEQUENCE IF EXISTS place_saved_source_revision_seq",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("down migration missing %q", required)
		}
	}
}
