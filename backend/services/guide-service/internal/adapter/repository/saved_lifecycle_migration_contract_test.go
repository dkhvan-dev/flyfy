package repository

import (
	"os"
	"strings"
	"testing"
)

func TestSavedLifecycleMigrationDefinesTransactionalOutboxContract(t *testing.T) {
	t.Parallel()
	up, err := os.ReadFile("../../../migrations/000006_saved_lifecycle_outbox.up.sql")
	if err != nil {
		t.Fatalf("read Saved lifecycle migration: %v", err)
	}
	source := string(up)
	for _, needle := range []string{
		"BEGIN;",
		"SET LOCAL lock_timeout = '5s'",
		"CREATE TABLE guide_saved_lifecycle_state",
		"CREATE TABLE guide_saved_lifecycle_outbox",
		"FOR EACH ROW",
		"guide_saved_emit_state_event",
		"guide_saved_outbox_semantics_immutable",
		"media_reference_active",
		"source_revision BIGINT NOT NULL",
		"projection_revision BIGINT NOT NULL",
		"visibility_revision BIGINT NOT NULL",
		"WHERE status = 'PENDING'",
		"WHERE status = 'PROCESSING'",
		"retention_expires_at",
	} {
		if !strings.Contains(source, needle) {
			t.Fatalf("Saved lifecycle migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/000006_saved_lifecycle_outbox.down.sql")
	if err != nil {
		t.Fatalf("read Saved lifecycle rollback: %v", err)
	}
	if !strings.Contains(string(down), "status IN ('PENDING', 'PROCESSING', 'DEAD')") ||
		!strings.Contains(string(down), "ERRCODE = '55000'") ||
		!strings.Contains(string(down), "BEGIN;") {
		t.Fatal("Saved lifecycle rollback is not guarded against event loss")
	}
}

func TestSavedLifecycleRepositoryUsesConcurrentLeaseRecovery(t *testing.T) {
	t.Parallel()
	source, err := os.ReadFile("pg_saved_lifecycle_repository.go")
	if err != nil {
		t.Fatalf("read Saved lifecycle repository: %v", err)
	}
	text := string(source)
	for _, needle := range []string{
		"FOR UPDATE SKIP LOCKED",
		"status = 'PROCESSING' AND leased_until <= $1",
		"WHEN due.status = 'PENDING' THEN outbox.attempt_count + 1",
		"AND lease_token = $2",
		"status = 'DEAD'",
	} {
		if !strings.Contains(text, needle) {
			t.Fatalf("Saved lifecycle repository must contain %q", needle)
		}
	}
}
