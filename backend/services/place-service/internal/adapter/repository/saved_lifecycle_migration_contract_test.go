package repository

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSavedLifecycleOutboxMigrationDefinesProductionContract(t *testing.T) {
	t.Parallel()

	up := readSavedLifecycleMigration(t, "215_saved_lifecycle_outbox.up.sql")
	required := []string{
		"CREATE TABLE IF NOT EXISTS place_saved_lifecycle_outbox",
		"UNIQUE (origin_txid, entity_id)",
		"content.published",
		"content.updated",
		"content.unavailable",
		"content.deleted",
		"content.visibility_changed",
		"status IN ('PENDING', 'DELIVERED', 'DEAD')",
		"retention_expires_at = delivered_at + INTERVAL '14 days'",
		"retention_expires_at = dead_at + INTERVAL '14 days'",
		"DROP COLUMN IF EXISTS dlq_attempt_count",
		"CREATE INDEX IF NOT EXISTS idx_place_saved_lifecycle_outbox_due",
		"CREATE INDEX IF NOT EXISTS idx_place_saved_lifecycle_outbox_lease_recovery",
		"CREATE INDEX IF NOT EXISTS idx_place_saved_lifecycle_outbox_retention",
		"CREATE OR REPLACE FUNCTION protect_place_saved_lifecycle_outbox()",
		"DROP TRIGGER IF EXISTS trg_protect_place_saved_lifecycle_outbox",
		"Saved lifecycle envelope is immutable after source commit",
		"OLD.status = 'PENDING' AND NEW.status IN ('PENDING', 'DELIVERED', 'DEAD')",
		"NEW.saved_projection_revision := nextval('place_saved_source_revision_seq')",
		"AFTER INSERT OR UPDATE ON places",
		"ON CONFLICT (origin_txid, entity_id) DO UPDATE",
	}
	for _, fragment := range required {
		if !strings.Contains(up, fragment) {
			t.Fatalf("Saved lifecycle migration missing %q", fragment)
		}
	}
	for _, forbidden := range []string{
		"public_projection JSON",
		"payload JSON",
		"payload BYTEA",
		"PRIVATE",
		"DLQ_PENDING",
		"dlq_attempt_count INTEGER",
		"status IN ('PENDING', 'DLQ_PENDING'",
	} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("Saved lifecycle outbox must remain payload-free; found %q", forbidden)
		}
	}

	repositorySource, err := os.ReadFile("pg_saved_lifecycle_outbox.go")
	if err != nil {
		t.Fatalf("read Saved lifecycle outbox repository: %v", err)
	}
	for _, fragment := range []string{
		"FOR UPDATE SKIP LOCKED",
		"locked_at IS NULL OR locked_at <= $2",
		"lease_id = gen_random_uuid()",
	} {
		if !strings.Contains(string(repositorySource), fragment) {
			t.Fatalf("Saved lifecycle outbox repository missing %q", fragment)
		}
	}
}

func TestSavedLifecycleOutboxDownMigrationIsGuarded(t *testing.T) {
	t.Parallel()

	down := readSavedLifecycleMigration(t, "215_saved_lifecycle_outbox.down.sql")
	for _, fragment := range []string{
		"IF EXISTS (SELECT 1 FROM place_saved_lifecycle_outbox LIMIT 1)",
		"ERRCODE = '55000'",
		"DROP TRIGGER IF EXISTS trg_places_saved_lifecycle_outbox",
		"DROP TABLE place_saved_lifecycle_outbox",
		"Restore the revision behavior installed by migration 214",
	} {
		if !strings.Contains(down, fragment) {
			t.Fatalf("Saved lifecycle down migration missing %q", fragment)
		}
	}
}

func readSavedLifecycleMigration(t *testing.T, name string) string {
	t.Helper()
	payload, err := os.ReadFile(filepath.Join("..", "..", "..", "migrations", name))
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}
	return string(payload)
}
