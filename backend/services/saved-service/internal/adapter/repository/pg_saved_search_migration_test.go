package repository

import (
	"strings"
	"testing"
	"time"
)

func TestSavedSearchBackfillSQLIsBoundedAndRevisionNeutral(t *testing.T) {
	t.Parallel()
	for _, fragment := range []string{
		"WITH candidates AS MATERIALIZED",
		"ORDER BY projections.entity_type, projections.entity_id",
		"LIMIT $1",
		"FOR UPDATE SKIP LOCKED",
		"IS DISTINCT FROM saved_search_normalize_v1",
		"SELECT count(*)::bigint FROM updated",
	} {
		if !strings.Contains(savedSearchBackfillBatchSQL, fragment) {
			t.Errorf("backfill SQL is missing %q", fragment)
		}
	}
	for _, field := range savedSearchProjectionColumns {
		if !strings.Contains(savedSearchBackfillBatchSQL, "SET "+field+" =") &&
			!strings.Contains(savedSearchBackfillBatchSQL, "        "+field+" =") {
			t.Errorf("backfill SQL does not update %s", field)
		}
	}
	for _, banned := range []string{
		"updated_at",
		"source_revision",
		"projection_revision",
		"visibility_revision",
		"search_document_version =",
		"owner_user_id",
		"saved_item_id",
	} {
		if strings.Contains(savedSearchBackfillBatchSQL, banned) {
			t.Errorf("backfill SQL mutates or exposes out-of-scope field %q", banned)
		}
	}
}

func TestSavedSearchReadinessRequiresValidConcurrentIndexes(t *testing.T) {
	t.Parallel()
	for _, fragment := range []string{
		"attributes.attgenerated = ''",
		"triggers.tgenabled IN ('O', 'A')",
		"constraints.convalidated",
		"indexes.indisready",
		"indexes.indisvalid",
		"idx_saved_content_projections_search_backfill_v1",
	} {
		if !strings.Contains(savedSearchSchemaStatusSQL, fragment) {
			t.Errorf("schema status SQL is missing %q", fragment)
		}
	}
	if !strings.Contains(savedSearchDropBackfillIndexSQL, "DROP INDEX CONCURRENTLY IF EXISTS") {
		t.Error("contract cleanup does not drop the temporary index concurrently")
	}
}

func TestSavedSearchMigrationOptionsAreBounded(t *testing.T) {
	t.Parallel()
	valid := SavedSearchMigrationOptions{
		LockTimeout:      time.Second,
		StatementTimeout: 10 * time.Second,
		ContractTimeout:  30 * time.Minute,
	}
	if err := valid.Validate(); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	for _, invalid := range []SavedSearchMigrationOptions{
		{LockTimeout: 0, StatementTimeout: time.Second, ContractTimeout: time.Second},
		{LockTimeout: time.Second, StatementTimeout: time.Millisecond, ContractTimeout: time.Second},
		{LockTimeout: time.Second, StatementTimeout: time.Second, ContractTimeout: 25 * time.Hour},
	} {
		if err := invalid.Validate(); err == nil {
			t.Fatalf("Validate(%+v) succeeded", invalid)
		}
	}
}
