package repository

import (
	"os"
	"strings"
	"testing"
)

func TestActivityTranslationMigrationContract(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/021_activity_translations.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/021_activity_translations.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"add column source_language",
		"add column translation_status",
		"add column translations jsonb",
		"create table activity_translation_jobs",
		"uq_activity_translation_jobs_source",
		"idx_activity_translation_jobs_due",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration is missing %q", required)
		}
	}

	downSQL := strings.ToLower(string(down))
	if !strings.Contains(downSQL, "drop table if exists activity_translation_jobs") ||
		!strings.Contains(downSQL, "drop column if exists translations") {
		t.Fatalf("down migration does not remove activity translation schema: %s", downSQL)
	}
}
