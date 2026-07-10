package repository

import (
	"os"
	"strings"
	"testing"
)

func TestTranslationRuntimeMigrationDefinesCacheUsageAndJobSchema(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/000001_translation_runtime.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/000001_translation_runtime.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create table if not exists translation_cache",
		"create table if not exists translation_usage_monthly",
		"create table if not exists translation_jobs",
		"unique (provider, source_language, target_language, glossary_version, source_hash)",
		"status in ('pending', 'processing', 'completed', 'failed', 'cancelled')",
		"billing_mode in ('free_only', 'paid_allowed', 'disabled')",
		"create index if not exists idx_translation_jobs_due",
		"create index if not exists idx_translation_cache_lookup",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"drop table if exists translation_jobs",
		"drop table if exists translation_usage_monthly",
		"drop table if exists translation_cache",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("down migration missing %q:\n%s", required, string(down))
		}
	}
}
