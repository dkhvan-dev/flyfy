package repository

import (
	"strings"
	"testing"
)

func TestPlaceRegionFilterIndexMigrationAddsTagsGinIndex(t *testing.T) {
	upSQL := readMigration(t, "024_place_region_filter_indexes.up.sql")
	downSQL := readMigration(t, "024_place_region_filter_indexes.down.sql")

	if !strings.Contains(upSQL, "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_places_active_tags_gin") {
		t.Fatalf("region filter up migration must create active tags GIN index: %s", upSQL)
	}
	if !strings.Contains(upSQL, "USING GIN (tags)") {
		t.Fatalf("region filter up migration must index tags with GIN: %s", upSQL)
	}
	if !strings.Contains(downSQL, "DROP INDEX CONCURRENTLY IF EXISTS idx_places_active_tags_gin") {
		t.Fatalf("region filter down migration must drop active tags GIN index: %s", downSQL)
	}
}
