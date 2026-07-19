package repository

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSavedCoreMigrationContract(t *testing.T) {
	t.Parallel()

	up := readMigration(t, "001_saved_core.up.sql")
	down := readMigration(t, "001_saved_core.down.sql")

	requiredUp := []string{
		"CREATE TABLE saved_content_projections",
		"CREATE TABLE saved_items",
		"CREATE TABLE saved_user_usage",
		"CREATE TABLE saved_operations",
		"CREATE TABLE saved_outbox",
		"CREATE TABLE saved_inbox_dedup",
		"CREATE TABLE saved_subject_purge_operations",
		"UNIQUE (owner_user_id, entity_type, entity_id)",
		"UNIQUE (subject, session_generation, idempotency_key)",
		"PRIMARY KEY (subject, session_generation, operation_id)",
		"octet_length(semantic_request_hmac) = 32",
		"operation_kind IN ('SAVE_TARGET', 'UNSAVE_TARGET')",
		"applied_relationship_generation UUID",
		"accepted_platform_access_policy_revision > 0",
		"retention_expires_at = completed_at + INTERVAL '14 days'",
		"retention_expires_at = processed_at + INTERVAL '14 days'",
		"commit_deadline <= created_at + INTERVAL '15 seconds'",
		"saved_content_projections_non_public_payload_check",
		"media_reference_revision BIGINT",
		"media_valid_until TIMESTAMPTZ",
		"rating_scale_max NUMERIC(7, 4)",
		"media_valid_until <= visibility_validated_at + INTERVAL '15 minutes'",
		"WHERE relationship_state = 'ACTIVE'",
		"WHERE status = 'PENDING'",
	}
	for _, fragment := range requiredUp {
		if !strings.Contains(up, fragment) {
			t.Errorf("up migration is missing required contract fragment %q", fragment)
		}
	}

	for _, table := range []string{
		"saved_subject_purge_operations",
		"saved_inbox_dedup",
		"saved_outbox",
		"saved_operations",
		"saved_user_usage",
		"saved_items",
		"saved_content_projections",
	} {
		if !strings.Contains(down, "DROP TABLE IF EXISTS "+table) {
			t.Errorf("down migration does not drop %s", table)
		}
	}

	for _, banned := range []string{
		"saved_alias",
		"create table saved_collections",
		"create table saved_collection_memberships",
		"request_payload",
		"reconcile",
		"marker_store",
		"removal_commit",
	} {
		if strings.Contains(strings.ToLower(up), banned) {
			t.Errorf("up migration contains out-of-scope construct %q", banned)
		}
	}
}

func readMigration(t *testing.T, name string) string {
	t.Helper()

	path := filepath.Join("..", "..", "..", "migrations", name)
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}
	return string(contents)
}
