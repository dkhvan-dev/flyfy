package repository

import (
	"strings"
	"testing"
)

func TestSavedLifecycleInboxMigrationContract(t *testing.T) {
	t.Parallel()

	up := readSavedLifecycleMigration(t, "004_saved_lifecycle_inbox.up.sql")
	down := readSavedLifecycleMigration(t, "004_saved_lifecycle_inbox.down.sql")

	requiredUp := []string{
		"saved lifecycle inbox must be empty before migration 004",
		"ALTER COLUMN event_id TYPE UUID",
		"saved.source.activity.lifecycle.v1",
		"saved.source.attraction.lifecycle.v1",
		"saved.source.guide.lifecycle.v1",
		"octet_length(envelope_fingerprint) = 32",
		"target_entity_type IN ('ATTRACTION', 'ACTIVITY', 'GUIDE')",
		"source_revision > 0",
		"projection_revision > 0",
		"visibility_revision > 0",
		"APPLIED_SOURCE_ONLY",
		"IGNORED_PUBLIC_PAYLOAD_ABSENT",
		"retention_expires_at = processed_at + INTERVAL '14 days'",
		"raw event payload is never retained",
	}
	for _, fragment := range requiredUp {
		if !strings.Contains(up, fragment) {
			t.Errorf("up migration missing %q", fragment)
		}
	}

	requiredDown := []string{
		"DROP COLUMN subject",
		"DROP COLUMN envelope_fingerprint",
		"ALTER COLUMN event_id TYPE TEXT",
		"saved_inbox_dedup_event_id_check",
		"IGNORED_UNKNOWN_TARGET",
		"IGNORED_STALE_REVISION",
	}
	for _, fragment := range requiredDown {
		if !strings.Contains(down, fragment) {
			t.Errorf("down migration missing %q", fragment)
		}
	}

	for _, forbidden := range []string{
		"content.saved.lifecycle.v1.attraction",
		"saved.source.excursion.lifecycle.v1",
		"request_payload",
		"raw_payload",
		"alias",
	} {
		if strings.Contains(strings.ToLower(up), strings.ToLower(forbidden)) {
			t.Errorf("up migration contains forbidden contract %q", forbidden)
		}
	}
}
