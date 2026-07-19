package repository

import (
	"os"
	"strings"
	"testing"
)

func TestActivitySavedLifecycleMigrationContract(t *testing.T) {
	t.Parallel()

	up, err := os.ReadFile("../../../migrations/022_saved_lifecycle_outbox.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/022_saved_lifecycle_outbox.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}
	upSQL := strings.ToLower(string(up))
	downSQL := strings.ToLower(string(down))

	for _, required := range []string{
		"activity_saved_source_revision_seq",
		"saved_source_revision bigint",
		"saved_projection_revision bigint",
		"saved_visibility_revision bigint",
		"activity_saved_lifecycle_outbox",
		"saved.source.activity.lifecycle.v1",
		"uq_activity_saved_lifecycle_semantic_event",
		"trg_activity_saved_lifecycle_outbox_immutable",
		"trg_activities_saved_deleted_outbox",
		"interval '14 days'",
		"status in ('pending', 'processing', 'published', 'dead')",
		"visibility = 'public' or has_public_projection = false",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration is missing %q", required)
		}
	}
	for _, required := range []string{
		"refusing to drop non-empty activity saved lifecycle outbox",
		"drop table if exists activity_saved_lifecycle_outbox",
		"drop sequence if exists activity_saved_source_revision_seq",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("down migration is missing %q", required)
		}
	}
}

func TestActivitySavedLifecycleClaimUsesRecoverableSkipLockedLease(t *testing.T) {
	t.Parallel()

	source, err := os.ReadFile("pg_saved_lifecycle_outbox.go")
	if err != nil {
		t.Fatalf("read repository source: %v", err)
	}
	querySource := strings.ToLower(string(source))
	for _, required := range []string{
		"for update skip locked",
		"status in ('pending', 'processing')",
		"next_attempt_at <= $1",
		"recovered_lease",
		"locked_by = $4",
		"attempt_count + 1 >= max_attempts",
	} {
		if !strings.Contains(querySource, required) {
			t.Fatalf("outbox repository is missing %q", required)
		}
	}
}
