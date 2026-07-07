package repository

import (
	"os"
	"strings"
	"testing"
)

func TestGuideSearchBackfillRepositoryScansAllGuideProfiles(t *testing.T) {
	source, err := os.ReadFile("pg_guide_repository.go")
	if err != nil {
		t.Fatalf("read pg guide repository source: %v", err)
	}
	sql := string(source)
	for _, needle := range []string{
		"func (r *PGGuideRepository) ListGuideProfilesForSearchIndexBackfill",
		"FROM guide_profiles",
		"ORDER BY updated_at ASC, id ASC",
		"LIMIT $1 OFFSET $2",
		"scanGuideProfile",
	} {
		if !strings.Contains(sql, needle) {
			t.Fatalf("guide search backfill repository must contain %q", needle)
		}
	}
}
