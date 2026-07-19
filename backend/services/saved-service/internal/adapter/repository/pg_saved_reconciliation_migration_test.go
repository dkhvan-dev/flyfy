package repository

import (
	"strings"
	"testing"
)

func TestSavedReconciliationSchedulerMigrationIsExpandOnlyAndBounded(t *testing.T) {
	t.Parallel()

	expand := readMigration(t, "006_saved_reconciliation_scheduler.up.sql")
	index := readMigration(t, "006a_saved_reconciliation_scheduler_index.up.sql")
	indexDown := readMigration(t, "006a_saved_reconciliation_scheduler_index.down.sql")
	contract := readMigration(t, "006b_saved_reconciliation_scheduler_contract.sql")

	for _, fragment := range []string{
		"SET lock_timeout = '5s'",
		"SET statement_timeout = '30s'",
		"ADD COLUMN IF NOT EXISTS reconciliation_lease_token UUID",
		"ADD COLUMN IF NOT EXISTS reconciliation_next_attempt_at TIMESTAMPTZ",
		"ADD COLUMN IF NOT EXISTS reconciliation_failure_count INTEGER DEFAULT 0",
		"ADD COLUMN IF NOT EXISTS reconciliation_failure_kind TEXT",
		"ADD COLUMN IF NOT EXISTS reconciliation_fail_closed_at TIMESTAMPTZ",
		"saved_content_projections_reconciliation_lease_v1_check",
		"saved_content_projections_reconciliation_schedule_v1_check",
		"saved_content_projections_reconciliation_quarantine_v1_check",
		"saved_content_projections_reconciliation_fail_closed_v1_check",
		"reconciliation_fail_closed_reason = 'UNVERSIONED_NOT_FOUND'",
		"DROP CONSTRAINT IF EXISTS saved_content_projections_public_title_check",
		") NOT VALID",
	} {
		if !strings.Contains(expand, fragment) {
			t.Errorf("expand migration is missing %q", fragment)
		}
	}
	for _, forbidden := range []string{
		"UPDATE saved_content_projections",
		"VALIDATE CONSTRAINT",
		"CREATE INDEX",
		"SET NOT NULL",
	} {
		if strings.Contains(strings.ToUpper(expand), strings.ToUpper(forbidden)) {
			t.Errorf("expand migration contains unsafe operation %q", forbidden)
		}
	}

	for _, fragment := range []string{
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS",
		"idx_saved_content_projections_reconciliation_due_v1",
		"GREATEST(",
		"COALESCE(",
		"created_at",
		"reconciliation_last_attempt_at",
		"reconciliation_quarantined_at IS NULL",
		"entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')",
	} {
		if !strings.Contains(index, fragment) {
			t.Errorf("concurrent index migration is missing %q", fragment)
		}
	}
	if strings.Contains(strings.ToLower(index), "-infinity") {
		t.Fatal("scheduler index must rank never-validated rows by persisted created_at")
	}
	if strings.Count(index, "CREATE INDEX CONCURRENTLY IF NOT EXISTS") != 1 {
		t.Fatal("concurrent index migration must contain exactly one index statement")
	}
	if !strings.Contains(indexDown, "DROP INDEX CONCURRENTLY IF EXISTS") {
		t.Fatal("scheduler index rollback must be concurrent")
	}
	for _, fragment := range []string{
		"SET lock_timeout = '5s'",
		"SET statement_timeout = '5min'",
		"VALIDATE CONSTRAINT saved_content_projections_reconciliation_lease_v1_check",
		"VALIDATE CONSTRAINT saved_content_projections_reconciliation_schedule_v1_check",
		"VALIDATE CONSTRAINT saved_content_projections_reconciliation_quarantine_v1_check",
		"VALIDATE CONSTRAINT saved_content_projections_reconciliation_fail_closed_v1_check",
		"VALIDATE CONSTRAINT saved_content_projections_public_title_check",
	} {
		if !strings.Contains(contract, fragment) {
			t.Errorf("contract migration is missing %q", fragment)
		}
	}
}
