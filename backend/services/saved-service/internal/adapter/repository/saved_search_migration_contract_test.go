package repository

import (
	"strings"
	"testing"
)

func TestSavedSearchMigrationContract(t *testing.T) {
	t.Parallel()

	expand := readMigration(t, "003_saved_search.up.sql")
	expandDown := readMigration(t, "003_saved_search.down.sql")
	ownerIndex := readMigration(t, "003a_saved_search_owner_index.up.sql")
	ownerIndexDown := readMigration(t, "003a_saved_search_owner_index.down.sql")
	projectionIndex := readMigration(t, "003b_saved_search_projection_index.up.sql")
	projectionIndexDown := readMigration(t, "003b_saved_search_projection_index.down.sql")
	backfillIndex := readMigration(t, "003c_saved_search_backfill_index.up.sql")
	backfillIndexDown := readMigration(t, "003c_saved_search_backfill_index.down.sql")
	contract := readMigration(t, "003d_saved_search_contract.sql")
	rollout := readMigration(t, "SAVED_SEARCH_ROLLOUT.md")

	requiredExpand := []string{
		"CREATE OR REPLACE FUNCTION saved_search_normalize_v1",
		"normalize(input_value, NFKC)",
		"lower(",
		"'[^[:alnum:]]+'",
		"IMMUTABLE",
		"STRICT",
		"PARALLEL SAFE",
		"SET lock_timeout = '5s'",
		"CREATE OR REPLACE FUNCTION saved_search_sync_projection_v1",
		"BEFORE INSERT OR UPDATE OF",
		"FOR EACH ROW",
		"saved_content_projections_search_parity_v1_check",
		") NOT VALID",
	}
	for _, fragment := range requiredExpand {
		if !strings.Contains(expand, fragment) {
			t.Errorf("expand migration is missing search contract fragment %q", fragment)
		}
	}

	searchFields := []string{
		"search_title_en_v1",
		"search_title_ru_v1",
		"search_title_kk_v1",
		"search_city_en_v1",
		"search_city_ru_v1",
		"search_city_kk_v1",
		"search_country_en_v1",
		"search_country_ru_v1",
		"search_country_kk_v1",
	}
	for _, field := range searchFields {
		if !strings.Contains(expand, "ADD COLUMN IF NOT EXISTS "+field+" TEXT") {
			t.Errorf("expand migration does not add nullable plain column %s", field)
		}
		if !strings.Contains(expand, "NEW."+field+" := saved_search_normalize_v1") {
			t.Errorf("expand migration does not dual-write %s", field)
		}
		if !strings.Contains(expand, field+" IS NOT DISTINCT FROM saved_search_normalize_v1") {
			t.Errorf("expand migration does not constrain parity for %s", field)
		}
	}
	if got := strings.Count(expand, "ADD COLUMN IF NOT EXISTS search_"); got != 9 {
		t.Errorf("expand migration adds %d search columns, want 9", got)
	}

	lowerExpand := strings.ToLower(expand)
	for _, banned := range []string{
		"generated always",
		"create index",
		"update saved_content_projections",
		"validate constraint",
		"create extension",
		"pg_trgm",
		"similarity(",
		"levenshtein",
		"unaccent(",
		"to_tsvector",
		"tsquery",
		"transliter",
		"search_query",
		"request_payload",
	} {
		if strings.Contains(lowerExpand, banned) {
			t.Errorf("expand migration contains unsafe or out-of-scope construct %q", banned)
		}
	}

	assertConcurrentSearchIndexMigration(t, ownerIndex, []string{
		"idx_saved_items_active_owner_search_v1",
		"owner_user_id, saved_at DESC, id DESC",
		"INCLUDE (entity_type, entity_id)",
		"WHERE relationship_state = 'ACTIVE'",
	})
	assertConcurrentSearchIndexMigration(t, projectionIndex, []string{
		"idx_saved_content_projections_public_search_target_v1",
		"ON saved_content_projections (entity_type, entity_id)",
		"WHERE visibility_status = 'PUBLIC' AND search_document_version > 0",
	})
	assertConcurrentSearchIndexMigration(t, backfillIndex, []string{
		"idx_saved_content_projections_search_backfill_v1",
		"ON saved_content_projections (entity_type, entity_id)",
		"search_title_en_v1 IS DISTINCT FROM saved_search_normalize_v1(title_en)",
		"search_title_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(title_ru)",
		"search_title_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(title_kk)",
		"search_city_en_v1 IS DISTINCT FROM saved_search_normalize_v1(city_en)",
		"search_city_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(city_ru)",
		"search_city_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(city_kk)",
		"search_country_en_v1 IS DISTINCT FROM saved_search_normalize_v1(country_en)",
		"search_country_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(country_ru)",
		"search_country_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(country_kk)",
	})

	if !strings.Contains(contract, "VALIDATE CONSTRAINT saved_content_projections_search_parity_v1_check") {
		t.Error("manual contract phase does not validate search parity")
	}
	if strings.Contains(strings.ToLower(contract), "begin") {
		t.Error("manual contract phase must not impose an outer transaction contract")
	}

	for _, fragment := range []string{
		"SAVED_SEARCH_PRODUCT_ENABLED=false",
		"FOR UPDATE SKIP LOCKED",
		"complete=true",
		"-mode=contract",
		"indisready=true",
		"indisvalid=true",
		"idx_saved_content_projections_search_backfill_v1",
		"no persistent",
		"Do not run the destructive down migrations on a live system",
	} {
		if !strings.Contains(rollout, fragment) {
			t.Errorf("rollout runbook is missing guardrail %q", fragment)
		}
	}

	for _, fragment := range []string{
		"DROP CONSTRAINT IF EXISTS saved_content_projections_search_parity_v1_check",
		"DROP TRIGGER IF EXISTS trg_saved_search_sync_projection_v1",
		"DROP FUNCTION IF EXISTS saved_search_sync_projection_v1()",
		"DROP COLUMN IF EXISTS search_title_en_v1",
		"DROP COLUMN IF EXISTS search_country_kk_v1",
		"DROP FUNCTION IF EXISTS saved_search_normalize_v1(TEXT)",
	} {
		if !strings.Contains(expandDown, fragment) {
			t.Errorf("expand down migration is missing rollback fragment %q", fragment)
		}
	}
	if !strings.Contains(ownerIndexDown, "DROP INDEX CONCURRENTLY IF EXISTS idx_saved_items_active_owner_search_v1") {
		t.Error("owner search index down migration is not concurrent")
	}
	if !strings.Contains(projectionIndexDown, "DROP INDEX CONCURRENTLY IF EXISTS idx_saved_content_projections_public_search_target_v1") {
		t.Error("projection search index down migration is not concurrent")
	}
	if !strings.Contains(backfillIndexDown, "DROP INDEX CONCURRENTLY IF EXISTS idx_saved_content_projections_search_backfill_v1") {
		t.Error("backfill search index down migration is not concurrent")
	}
	if strings.Index(expandDown, "DROP FUNCTION IF EXISTS saved_search_sync_projection_v1()") >
		strings.Index(expandDown, "DROP COLUMN IF EXISTS search_title_en_v1") {
		t.Error("expand down migration must remove the dual-write function before its columns")
	}
	if strings.Index(expandDown, "DROP COLUMN IF EXISTS search_title_en_v1") >
		strings.Index(expandDown, "DROP FUNCTION IF EXISTS saved_search_normalize_v1(TEXT)") {
		t.Error("expand down migration must drop search columns before normalization")
	}
}

func assertConcurrentSearchIndexMigration(t *testing.T, migration string, fragments []string) {
	t.Helper()
	for _, fragment := range fragments {
		if !strings.Contains(migration, fragment) {
			t.Errorf("concurrent index migration is missing %q", fragment)
		}
	}
	if got := strings.Count(migration, "CREATE INDEX CONCURRENTLY IF NOT EXISTS"); got != 1 {
		t.Errorf("concurrent index migration has %d index statements, want 1", got)
	}
	lower := strings.ToLower(migration)
	for _, banned := range []string{"begin;", "commit;", "alter table", "create index idx_"} {
		if strings.Contains(lower, banned) {
			t.Errorf("concurrent index migration contains unsafe construct %q", banned)
		}
	}
}
