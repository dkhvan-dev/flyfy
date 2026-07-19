package repository

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPlatformPersonalDataPolicyMigrationContract(t *testing.T) {
	t.Parallel()

	path := filepath.Join("..", "..", "..", "..", "migrations", "000011_platform_personal_data_policy.up.sql")
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}
	sql := strings.ToLower(string(contents))

	for _, required := range []string{
		"create table if not exists platform_personal_data_policy_state",
		"create table if not exists platform_personal_data_policy_history",
		"check (singleton_id = 1)",
		"check (revision > 0)",
		"state in ('available', 'locked')",
		"valid_until <= issued_at + interval '30 seconds'",
		"!~ '[[:cntrl:]]'",
		"'available'",
		"'migration-000011'",
		"revision <> old.revision + 1",
		"platform personal-data policy history is append-only",
		"before update or delete on platform_personal_data_policy_history",
		"before truncate on platform_personal_data_policy_history",
	} {
		if !strings.Contains(sql, required) {
			t.Errorf("migration is missing %q", required)
		}
	}
}

func TestPlatformPersonalDataPolicyDownMigrationRemovesOwnedObjects(t *testing.T) {
	t.Parallel()

	path := filepath.Join("..", "..", "..", "..", "migrations", "000011_platform_personal_data_policy.down.sql")
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}
	sql := strings.ToLower(string(contents))
	for _, required := range []string{
		"drop table if exists platform_personal_data_policy_history",
		"drop table if exists platform_personal_data_policy_state",
		"drop function if exists enforce_platform_personal_data_policy_state_update()",
	} {
		if !strings.Contains(sql, required) {
			t.Errorf("down migration is missing %q", required)
		}
	}
}
