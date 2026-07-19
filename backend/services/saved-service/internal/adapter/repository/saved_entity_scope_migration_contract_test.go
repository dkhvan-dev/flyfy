package repository

import (
	"strings"
	"testing"
)

func TestSavedEntityScopeMigrationIsOnlineAndNonDestructive(t *testing.T) {
	t.Parallel()

	expand := readMigration(t, "007_saved_entity_scope_expand.up.sql")
	validate := readMigration(t, "007a_saved_entity_scope_validate.up.sql")
	contract := readMigration(t, "007b_saved_entity_scope_contract.up.sql")

	for _, table := range []string{
		"saved_content_projections",
		"saved_items",
		"saved_outbox",
	} {
		if !strings.Contains(expand, "ALTER TABLE "+table) ||
			!strings.Contains(validate, "ALTER TABLE "+table) ||
			!strings.Contains(contract, "ALTER TABLE "+table) {
			t.Errorf("entity scope rollout does not cover %s in every phase", table)
		}
	}

	if got := strings.Count(expand, "CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')) NOT VALID"); got != 3 {
		t.Errorf("expand adds %d final entity checks, want 3", got)
	}
	if got := strings.Count(validate, "VALIDATE CONSTRAINT"); got != 3 {
		t.Errorf("validate migration validates %d constraints, want 3", got)
	}
	if got := strings.Count(contract, "RENAME CONSTRAINT"); got != 3 {
		t.Errorf("contract renames %d constraints, want 3", got)
	}
	if strings.Contains(expand, "'EXCURSION'") || strings.Contains(validate, "'EXCURSION'") ||
		strings.Contains(contract, "'EXCURSION'") {
		t.Fatal("final Saved entity scope still admits EXCURSION")
	}
	for _, migration := range []string{expand, validate, contract} {
		lower := strings.ToLower(migration)
		if strings.Contains(lower, "delete from") || strings.Contains(lower, "update saved_") {
			t.Fatal("entity scope rollout must not rewrite or delete personal data")
		}
	}
}
