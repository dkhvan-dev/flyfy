package repository

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"kz/inflap/backend/services/user-route-service/internal/app"
)

func TestPGUserRouteRepositoryImplementsAppPort(t *testing.T) {
	var _ app.UserRouteRepository = (*PGUserRouteRepository)(nil)
}

func TestInitialMigrationCreatesRouteContentAndSaveTables(t *testing.T) {
	migrationPath := filepath.Join("..", "..", "..", "migrations", "001_user_routes.up.sql")
	payload, err := os.ReadFile(migrationPath)
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}
	sql := string(payload)
	required := []string{
		"CREATE TABLE IF NOT EXISTS user_routes",
		"CREATE TABLE IF NOT EXISTS user_route_saves",
		"visibility IN ('private', 'unlisted', 'public')",
		"points JSONB NOT NULL",
		"snapshot JSONB NOT NULL",
		"CREATE INDEX IF NOT EXISTS idx_user_routes_public_city_updated",
		"CREATE INDEX IF NOT EXISTS idx_user_route_saves_user_created",
	}
	for _, snippet := range required {
		if !strings.Contains(sql, snippet) {
			t.Fatalf("migration missing %q", snippet)
		}
	}
}

func TestModerationMigrationAddsRouteModerationColumns(t *testing.T) {
	migrationPath := filepath.Join("..", "..", "..", "migrations", "002_user_route_moderation.up.sql")
	payload, err := os.ReadFile(migrationPath)
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}
	sql := string(payload)
	required := []string{
		"ADD COLUMN IF NOT EXISTS moderation_status",
		"ADD COLUMN IF NOT EXISTS moderation_reason",
		"ADD COLUMN IF NOT EXISTS moderated_by_user_id",
		"ADD COLUMN IF NOT EXISTS moderated_at",
		"moderation_status IN ('pending', 'approved', 'rejected', 'hidden')",
		"idx_user_routes_moderation_updated",
	}
	for _, snippet := range required {
		if !strings.Contains(sql, snippet) {
			t.Fatalf("moderation migration missing %q", snippet)
		}
	}
}

func TestRouteSelectAndListQueriesIncludeModerationFields(t *testing.T) {
	selectSQL := routeSelectSQL()
	if !strings.Contains(selectSQL, "r.moderation_status") ||
		!strings.Contains(selectSQL, "r.moderation_reason") ||
		!strings.Contains(selectSQL, "r.moderated_by_user_id") ||
		!strings.Contains(selectSQL, "r.moderated_at") {
		t.Fatalf("routeSelectSQL missing moderation fields: %s", selectSQL)
	}

	listSQL := listRoutesSQL()
	if !strings.Contains(listSQL, "r.moderation_status = 'approved'") {
		t.Fatalf("public list SQL must require approved moderation status: %s", listSQL)
	}
	if !strings.Contains(listSQL, "$5::text = '' OR r.moderation_status = $5") {
		t.Fatalf("list SQL must support moderation status filter: %s", listSQL)
	}
}
