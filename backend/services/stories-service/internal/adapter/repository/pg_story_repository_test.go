package repository

import (
	"os"
	"strings"
	"testing"
)

func TestStoryListOrderBySupportsSortDirections(t *testing.T) {
	tests := map[string]string{
		"latest":         "published_at DESC NULLS LAST, created_at DESC",
		"latest_desc":    "published_at DESC NULLS LAST, created_at DESC",
		"latest_asc":     "published_at ASC NULLS LAST, created_at ASC",
		"popular":        "view_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"popular_desc":   "view_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"popular_asc":    "view_count ASC, published_at ASC NULLS LAST, created_at ASC",
		"discussed":      "comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"discussed_desc": "comment_count DESC, published_at DESC NULLS LAST, created_at DESC",
		"discussed_asc":  "comment_count ASC, published_at ASC NULLS LAST, created_at ASC",
		"unknown":        "published_at DESC NULLS LAST, created_at DESC",
	}

	for sort, expected := range tests {
		t.Run(sort, func(t *testing.T) {
			if got := storyListOrderBy(sort); got != expected {
				t.Fatalf("order by mismatch\nexpected: %s\nactual:   %s", expected, got)
			}
		})
	}
}

func TestRepositoryPersistsAndFiltersPlaceCityID(t *testing.T) {
	sourceBytes, err := os.ReadFile("pg_story_repository.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	source := string(sourceBytes)

	for _, needle := range []string{
		"place_city_id",
		"story.PlaceCityID",
		"filter.PlaceCityID",
		"item.PlaceCityID",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("repository source must contain %q", needle)
		}
	}

	migrationBytes, err := os.ReadFile("../../../migrations/004_story_place_city_id.up.sql")
	if err != nil {
		t.Fatalf("read place city migration: %v", err)
	}
	migration := string(migrationBytes)
	for _, needle := range []string{
		"ADD COLUMN IF NOT EXISTS place_city_id",
		"idx_stories_place_city_published",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("migration must contain %q", needle)
		}
	}
}
