package repository

import (
	"strings"
	"testing"
)

func TestSavedPostEntityMigrationExpandsAndValidatesScopeOnline(t *testing.T) {
	t.Parallel()

	expand := readMigration(t, "009_saved_post_entity_expand.up.sql")
	validate := readMigration(t, "009a_saved_post_entity_validate.up.sql")
	contract := readMigration(t, "009b_saved_post_entity_contract.up.sql")
	down := readMigration(t, "009b_saved_post_entity_contract.down.sql")
	index := readMigration(t, "009c_saved_post_reconciliation_index.up.sql")

	check := "CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')) NOT VALID"
	if got := strings.Count(expand, check); got != 3 {
		t.Fatalf("POST expansion checks = %d, want 3", got)
	}
	if got := strings.Count(validate, "\n    VALIDATE CONSTRAINT"); got != 3 {
		t.Fatalf("POST validation steps = %d, want 3", got)
	}
	if got := strings.Count(contract, "RENAME CONSTRAINT"); got != 3 {
		t.Fatalf("canonical constraint swaps = %d, want 3", got)
	}
	for _, table := range []string{
		"saved_content_projections",
		"saved_items",
		"saved_outbox",
	} {
		if !strings.Contains(down, "FROM "+table+" WHERE entity_type = 'POST'") {
			t.Errorf("rollback guard is missing POST data check for %s", table)
		}
	}
	if !strings.Contains(down, "irreversible while POST Saved data exists") {
		t.Fatal("rollback does not fail closed after POST data exists")
	}
	if !strings.Contains(index, "CREATE INDEX CONCURRENTLY") ||
		!strings.Contains(index, "entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')") {
		t.Fatal("reconciliation index does not include POST with an online rebuild")
	}
	for _, migration := range []string{expand, validate, contract} {
		lower := strings.ToLower(migration)
		if strings.Contains(lower, "update ") || strings.Contains(lower, "delete from") {
			t.Fatal("POST scope expansion must not rewrite Saved data")
		}
	}
}
