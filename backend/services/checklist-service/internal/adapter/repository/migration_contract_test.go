package repository

import (
	"os"
	"strings"
	"testing"
)

func TestChecklistInstanceMigrationDefinesProductionPersistenceSchema(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_checklist_instances.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/001_checklist_instances.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create table checklist_instances",
		"create table checklist_instance_items",
		"unique (user_id, trip_id)",
		"references checklist_instances(id) on delete cascade",
		"create index idx_checklist_instances_user_updated",
		"create index idx_checklist_instance_items_status",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	if !strings.Contains(downSQL, "drop table if exists checklist_instance_items") ||
		!strings.Contains(downSQL, "drop table if exists checklist_instances") {
		t.Fatalf("down migration must drop checklist tables in dependency order:\n%s", string(down))
	}
}

func TestChecklistFeedbackMigrationDefinesLearningSignalSchema(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/002_checklist_item_feedback.up.sql")
	if err != nil {
		t.Fatalf("read feedback up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/002_checklist_item_feedback.down.sql")
	if err != nil {
		t.Fatalf("read feedback down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create table checklist_item_feedback",
		"references checklist_instances(id) on delete cascade",
		"feedback_type in ('helpful', 'not_helpful', 'add_next_time')",
		"length(comment) <= 500",
		"create index idx_checklist_item_feedback_trip_item",
		"create index idx_checklist_item_feedback_type_created",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("feedback up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	if !strings.Contains(downSQL, "drop table if exists checklist_item_feedback") {
		t.Fatalf("feedback down migration must drop feedback table:\n%s", string(down))
	}
}

func TestChecklistCollaborationMigrationDefinesReminderAndAssignmentSchema(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/003_checklist_collaboration.up.sql")
	if err != nil {
		t.Fatalf("read collaboration up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/003_checklist_collaboration.down.sql")
	if err != nil {
		t.Fatalf("read collaboration down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"add column start_at timestamptz",
		"add column end_at timestamptz",
		"add column destination jsonb",
		"add column assigned_user_id text",
		"create index idx_checklist_instances_start_at",
		"create index idx_checklist_instance_items_assignee",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("collaboration up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"drop column if exists assigned_user_id",
		"drop column if exists destination",
		"drop column if exists end_at",
		"drop column if exists start_at",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("collaboration down migration missing %q:\n%s", required, string(down))
		}
	}
}

func TestCustomChecklistItemsMigrationContract(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/004_custom_checklist_items.up.sql")
	if err != nil {
		t.Fatalf("read custom checklist up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/004_custom_checklist_items.down.sql")
	if err != nil {
		t.Fatalf("read custom checklist down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create table custom_checklist_items",
		"create table personal_checklist_templates",
		"custom_checklist_items_user_trip_active",
		"custom_checklist_items_instance_active",
		"personal_checklist_templates_user_active",
		"status in ('open', 'done', 'skipped')",
		"priority in ('critical', 'essential', 'important', 'recommended', 'optional')",
		"deleted_at",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("custom checklist up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"drop table if exists custom_checklist_items",
		"drop table if exists personal_checklist_templates",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("custom checklist down migration missing %q:\n%s", required, string(down))
		}
	}
}

func TestChecklistRouteContextMigrationContract(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/005_checklist_route_context.up.sql")
	if err != nil {
		t.Fatalf("read route context up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/005_checklist_route_context.down.sql")
	if err != nil {
		t.Fatalf("read route context down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"add column transport_modes text[]",
		"add column activity_slugs text[]",
		"add column has_children boolean",
		"create index idx_checklist_instances_user_start_at",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("route context up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"drop column if exists has_children",
		"drop column if exists activity_slugs",
		"drop column if exists transport_modes",
		"drop index if exists idx_checklist_instances_user_start_at",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("route context down migration missing %q:\n%s", required, string(down))
		}
	}
}
