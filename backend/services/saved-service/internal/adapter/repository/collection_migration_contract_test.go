package repository

import (
	"strings"
	"testing"
)

func TestSavedCollectionsMigrationContract(t *testing.T) {
	t.Parallel()

	up := readMigration(t, "002_saved_collections.up.sql")
	down := readMigration(t, "002_saved_collections.down.sql")

	requiredUp := []string{
		"CREATE TABLE saved_collections",
		"CREATE TABLE saved_collection_items",
		"CREATE TABLE saved_collection_usage",
		"UNIQUE (owner_user_id, client_creation_id)",
		"UNIQUE (owner_user_id, id)",
		"normalized_title_key COLLATE \"C\"",
		"WHERE lifecycle_state = 'ACTIVE'",
		"char_length(title) BETWEEN 1 AND 80",
		"purge_eligible_at = deleted_at + INTERVAL '14 days'",
		"FOREIGN KEY (owner_user_id, collection_id)",
		"REFERENCES saved_collections (owner_user_id, id)",
		"FOREIGN KEY (owner_user_id, saved_item_id)",
		"REFERENCES saved_items (owner_user_id, id)",
		"purge_eligible_at = removed_at + INTERVAL '14 days'",
		"saved_at_snapshot DESC",
		"saved_item_id DESC",
		"idx_saved_collection_items_owner_item_picker",
		"idx_saved_collection_items_parent_cleanup",
		"idx_saved_collection_items_removed_retention",
		"active_collections_count BIGINT",
		"active_memberships_count BIGINT",
		"ADD COLUMN observed_dependent_membership_version BIGINT",
		"ADD COLUMN observed_collection_metadata_version BIGINT",
		"ADD COLUMN observed_collection_lifecycle_version BIGINT",
		"ADD COLUMN applied_dependent_membership_version BIGINT",
		"ADD COLUMN applied_collection_id UUID",
		"ADD COLUMN applied_collection_metadata_version BIGINT",
		"ADD COLUMN applied_collection_lifecycle_version BIGINT",
		"'SET_TARGET_COLLECTIONS'",
		"'CREATE_COLLECTION'",
		"'RENAME_COLLECTION'",
		"'DELETE_COLLECTION'",
		"'SAVED_COLLECTION_TITLE_CONFLICT'",
		"'SAVED_MEMBERSHIP_LIMIT_REACHED'",
		"'COLLECTION_ITEMS'",
		"'COLLECTIONS'",
		"'COLLECTION_USAGE'",
	}
	for _, fragment := range requiredUp {
		if !strings.Contains(up, fragment) {
			t.Errorf("up migration is missing required contract fragment %q", fragment)
		}
	}

	if got := strings.Count(up, "CREATE TABLE "); got != 3 {
		t.Errorf("up migration creates %d tables, want exactly 3", got)
	}

	lowerUp := strings.ToLower(up)
	for _, banned := range []string{
		"on delete cascade",
		"create trigger",
		"saved_collection_memberships",
		"collaborator",
		"sharing",
		"shared_collection",
		"collection_note",
		"manual_order",
		"sort_position",
		"cover_reference",
		"cover_media",
		"request_payload",
		"desired_collection_ids",
		"search_query",
		"saved_alias",
		"marker_store",
		"reconcile",
		"removal_commit",
		"bulk_unsave",
	} {
		if strings.Contains(lowerUp, banned) {
			t.Errorf("up migration contains out-of-scope construct %q", banned)
		}
	}

	requiredDown := []string{
		"DO $saved_collections_rollback_guard$",
		"cannot roll back migration 002 while private collection data exists",
		"cannot roll back migration 002 while collection operation receipts exist",
		"cannot roll back migration 002 while a purge uses collection phases",
		"USING ERRCODE = '55000'",
		"DROP TABLE saved_collection_items",
		"DROP TABLE saved_collection_usage",
		"DROP TABLE saved_collections",
		"DROP COLUMN applied_collection_id",
		"CHECK (operation_kind IN ('SAVE_TARGET', 'UNSAVE_TARGET'))",
	}
	for _, fragment := range requiredDown {
		if !strings.Contains(down, fragment) {
			t.Errorf("down migration is missing rollback contract fragment %q", fragment)
		}
	}

	childDrop := strings.Index(down, "DROP TABLE saved_collection_items")
	parentDrop := strings.Index(down, "DROP TABLE saved_collections")
	if childDrop < 0 || parentDrop < 0 || childDrop >= parentDrop {
		t.Error("down migration must drop collection items before collections")
	}

	lowerDown := strings.ToLower(down)
	for _, banned := range []string{
		"drop table saved_collection_items cascade",
		"drop table saved_collection_usage cascade",
		"drop table saved_collections cascade",
		"delete from",
		"truncate table",
	} {
		if strings.Contains(lowerDown, banned) {
			t.Errorf("down migration can silently destroy or cascade data via %q", banned)
		}
	}
}
