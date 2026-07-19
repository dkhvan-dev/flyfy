package repository

import (
	"strings"
	"testing"
)

func TestSavedUserEntityMigrationPreservesExistingGuideSaves(t *testing.T) {
	t.Parallel()

	up := readMigration(t, "008_saved_user_entity.up.sql")
	down := readMigration(t, "008_saved_user_entity.down.sql")
	index := readMigration(t, "008a_saved_user_reconciliation_index.up.sql")

	for _, table := range []string{
		"saved_content_projections",
		"saved_items",
		"saved_outbox",
	} {
		if !strings.Contains(up, "UPDATE "+table) ||
			!strings.Contains(up, "WHERE entity_type = 'GUIDE'") {
			t.Errorf("migration does not canonicalize GUIDE rows in %s", table)
		}
	}
	if got := strings.Count(up, "CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER')) NOT VALID"); got != 3 {
		t.Errorf("migration adds %d final USER entity checks, want 3", got)
	}
	for _, fragment := range []string{
		"DROP CONSTRAINT saved_items_projection_fkey",
		"ADD CONSTRAINT saved_items_projection_fkey",
		"VALIDATE CONSTRAINT saved_items_projection_fkey",
		"source_service = 'user-service'",
		"source_revision = 1",
		"projection_revision = 1",
		"visibility_revision = 1",
		"ELSE 'user-avatar:' || substr(",
		"ELSE '/users/' || entity_id || '/profile'",
		"reconciliation_next_attempt_at = CURRENT_TIMESTAMP",
		"reconciliation_failure_count = 0",
	} {
		if !strings.Contains(up, fragment) {
			t.Errorf("migration is missing %q", fragment)
		}
	}
	for _, precondition := range []string{
		"non-canonical GUIDE user_id exists before migration 008",
		"malformed GUIDE avatar reference exists before migration 008",
	} {
		if !strings.Contains(up, precondition) {
			t.Errorf("migration is missing safety precondition %q", precondition)
		}
	}
	if strings.Contains(strings.ToLower(up), "delete from") {
		t.Fatal("USER canonicalization must not delete Saved data")
	}
	if !strings.Contains(down, "migration 008 is irreversible while USER Saved data exists") {
		t.Fatal("down migration does not fail safely when USER data exists")
	}
	if !strings.Contains(index, "entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER')") ||
		strings.Contains(index, "'GUIDE'") {
		t.Fatal("reconciliation index does not use the final USER entity scope")
	}
}

func TestSavedUserMediaRevisionRepairTargetsOnlyRebasedGuideProjections(t *testing.T) {
	t.Parallel()

	up := readMigration(t, "008b_saved_user_media_revision_repair.up.sql")
	down := readMigration(t, "008b_saved_user_media_revision_repair.down.sql")

	for _, fragment := range []string{
		"media_reference = NULL",
		"media_reference_revision = NULL",
		"media_valid_until = NULL",
		"reconciliation_next_attempt_at = LEAST(",
		"entity_type = 'USER'",
		"source_service = 'user-service'",
		"source_revision = 1",
		"projection_revision = 1",
		"visibility_revision = 1",
		"media_reference LIKE 'user-avatar:' || entity_id || ':%'",
		"media_reference_revision > 1",
	} {
		if !strings.Contains(up, fragment) {
			t.Errorf("media revision repair is missing %q", fragment)
		}
	}
	if strings.Contains(strings.ToLower(up), "delete from") {
		t.Fatal("media revision repair must not delete Saved data")
	}
	if !strings.Contains(down, "migration 008b is an irreversible cleanup") {
		t.Fatal("down migration does not fail safely")
	}
}

func TestSavedUserSearchRevisionRepairTargetsOnlyRebasedGuideProjections(t *testing.T) {
	t.Parallel()

	up := readMigration(t, "008c_saved_user_search_revision_repair.up.sql")
	down := readMigration(t, "008c_saved_user_search_revision_repair.down.sql")

	for _, fragment := range []string{
		"search_document_version = 0",
		"normalized_search_document_en = NULL",
		"normalized_search_document_ru = NULL",
		"normalized_search_document_kk = NULL",
		"reconciliation_next_attempt_at = LEAST(",
		"entity_type = 'USER'",
		"source_service = 'user-service'",
		"source_revision = 1",
		"projection_revision = 1",
		"visibility_revision = 1",
		"search_document_version > 1",
	} {
		if !strings.Contains(up, fragment) {
			t.Errorf("search revision repair is missing %q", fragment)
		}
	}
	if strings.Contains(strings.ToLower(up), "delete from") {
		t.Fatal("search revision repair must not delete Saved data")
	}
	if !strings.Contains(down, "migration 008c is an irreversible cleanup") {
		t.Fatal("down migration does not fail safely")
	}
}
