package repository

import (
	"os"
	"regexp"
	"strings"
	"testing"
)

func TestHelpCenterSupportMigrationDefinesProductionPersistenceSchema(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/001_help_center_support.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/001_help_center_support.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create extension if not exists pg_trgm",
		"create table help_categories",
		"create table help_articles",
		"create table help_article_translations",
		"create table help_article_surfaces",
		"create table help_article_tags",
		"create table help_article_actions",
		"create table help_article_related_articles",
		"create table help_article_feedback",
		"create table support_tickets",
		"create table support_ticket_events",
		"status in ('draft', 'review', 'published', 'archived')",
		"unique (article_id, locale)",
		"references help_articles(id) on delete cascade",
		"references support_tickets(id) on delete cascade",
		"context jsonb not null default '{}'::jsonb",
		"create index idx_help_articles_status_updated",
		"create index idx_help_article_translations_search",
		"create index idx_help_article_translations_title_trgm",
		"create index idx_help_article_translations_short_answer_trgm",
		"create index idx_help_article_translations_body_trgm",
		"create index idx_help_article_surfaces_surface",
		"create index idx_help_article_tags_tag",
		"create index idx_help_article_feedback_article_created",
		"create index idx_support_tickets_status_priority",
		"create index idx_support_tickets_user_last_message",
		"create index idx_support_ticket_events_ticket_created",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	previous := -1
	for _, fragment := range []string{
		"drop table if exists support_ticket_events",
		"drop table if exists support_tickets",
		"drop table if exists help_article_feedback",
		"drop table if exists help_article_related_articles",
		"drop table if exists help_article_actions",
		"drop table if exists help_article_tags",
		"drop table if exists help_article_surfaces",
		"drop table if exists help_article_translations",
		"drop table if exists help_articles",
		"drop table if exists help_categories",
	} {
		current := strings.Index(downSQL, fragment)
		if current == -1 {
			t.Fatalf("down migration missing %q:\n%s", fragment, string(down))
		}
		if current <= previous {
			t.Fatalf("down migration drops %q out of dependency order:\n%s", fragment, string(down))
		}
		previous = current
	}
}

func TestHelpArticleFeedbackUserVoteMigrationMakesArticleUserFeedbackUnique(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/014_help_article_feedback_user_vote.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/014_help_article_feedback_user_vote.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"alter table help_article_feedback",
		"add column if not exists updated_at",
		"row_number() over",
		"partition by article_id, user_id",
		"delete from help_article_feedback",
		"create unique index if not exists idx_help_article_feedback_article_user",
		"on help_article_feedback(article_id, user_id)",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("feedback user vote up migration missing %q:\n%s", required, string(up))
		}
	}
	if strings.Contains(upSQL, "truncate") {
		t.Fatal("feedback user vote up migration must not truncate existing feedback")
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"drop index if exists idx_help_article_feedback_article_user",
		"drop column if exists updated_at",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("feedback user vote down migration missing %q:\n%s", required, string(down))
		}
	}
}

func TestHelpArticleEventsMigrationDefinesAuditTrail(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/002_help_article_events.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/002_help_article_events.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create table help_article_events",
		"references help_articles(id) on delete cascade",
		"actor_id text not null",
		"event_type text not null",
		"payload jsonb not null default '{}'::jsonb",
		"create index idx_help_article_events_article_created",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	if !strings.Contains(downSQL, "drop table if exists help_article_events") {
		t.Fatalf("down migration missing help_article_events drop:\n%s", string(down))
	}
}

func TestSupportTicketCSATMigrationDefinesRatingPersistence(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/004_support_ticket_csat.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/004_support_ticket_csat.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create table support_ticket_csat",
		"ticket_id text primary key references support_tickets(id) on delete cascade",
		"user_id text not null",
		"rating integer not null check (rating between 1 and 5)",
		"comment text not null default '' check (length(comment) <= 1200)",
		"created_at timestamptz not null default now()",
		"create index idx_support_ticket_csat_created",
		"create index idx_support_ticket_csat_user_created",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	if !strings.Contains(downSQL, "drop table if exists support_ticket_csat") {
		t.Fatalf("down migration missing support_ticket_csat drop:\n%s", string(down))
	}
}

func TestSupportTicketIdempotencyMigrationDefinesRetrySafeTicketCreation(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/005_support_ticket_idempotency.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/005_support_ticket_idempotency.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"alter table support_tickets",
		"add column if not exists idempotency_key text not null default ''",
		"check (length(idempotency_key) <= 180)",
		"create unique index if not exists idx_support_tickets_user_idempotency_key",
		"on support_tickets(user_id, idempotency_key)",
		"where idempotency_key <> ''",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"drop index if exists idx_support_tickets_user_idempotency_key",
		"alter table support_tickets",
		"drop column if exists idempotency_key",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("down migration missing %q:\n%s", required, string(down))
		}
	}
}

func TestSupportSavedRepliesMigrationDefinesCannedResponsePersistence(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/006_support_saved_replies.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/006_support_saved_replies.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create table support_saved_replies",
		"id text primary key",
		"category text not null default ''",
		"status text not null default 'published'",
		"check (status in ('draft', 'review', 'published', 'archived'))",
		"tags text[] not null default '{}'::text[]",
		"translations jsonb not null default '{}'::jsonb",
		"sort_order integer not null default 0",
		"create index idx_support_saved_replies_status_category",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	if !strings.Contains(downSQL, "drop table if exists support_saved_replies") {
		t.Fatalf("down migration missing support_saved_replies drop:\n%s", string(down))
	}
}

func TestTouristFAQMigrationSeedsLocalizedDatabaseArticles(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/010_seed_tourist_faq.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/010_seed_tourist_faq.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := string(up)
	upLower := strings.ToLower(upSQL)
	for _, required := range []string{
		"delete from help_articles",
		"fallback-support-request",
		"insert into help_categories",
		"insert into help_articles",
		"insert into help_article_translations",
		"insert into help_article_surfaces",
		"insert into help_article_tags",
		"tourist-faq-001",
		"tourist-faq-005",
		"tourist-faq-100",
		"documents_visas_entry",
		"airport_flights_baggage",
		"local_rules_culture_special",
	} {
		if !strings.Contains(upLower, required) {
			t.Fatalf("tourist FAQ up migration missing %q", required)
		}
	}
	for _, forbidden := range []string{"**источники:**", "**риск обновления:**", "risk_update", "update_risk"} {
		if strings.Contains(upLower, forbidden) {
			t.Fatalf("tourist FAQ up migration must not persist source/risk field %q", forbidden)
		}
	}
	if strings.Contains(upSQL, "ON COMMIT DROP") {
		t.Fatal("tourist FAQ up migration must not use ON COMMIT DROP because the psql-based migrator runs statements in autocommit mode")
	}

	distinctIDs := map[string]struct{}{}
	for _, match := range regexp.MustCompile(`tourist-faq-\d{3}`).FindAllString(upSQL, -1) {
		distinctIDs[match] = struct{}{}
	}
	if len(distinctIDs) != 100 {
		t.Fatalf("seeded FAQ article count = %d, want 100", len(distinctIDs))
	}
	for _, required := range []string{"select id, 'ru'", "select id, 'en'", "select id, 'kk'"} {
		if !strings.Contains(upLower, required) {
			t.Fatalf("tourist FAQ up migration missing translation locale branch %q", required)
		}
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"delete from help_articles",
		"tourist-faq-",
		"delete from help_categories",
		"documents_visas_entry",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("tourist FAQ down migration missing %q", required)
		}
	}
}

func TestHelpCategoryTaxonomyMigrationDefinesLocalizedTravelCategories(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/011_help_category_taxonomy.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/011_help_category_taxonomy.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"create table if not exists help_category_translations",
		"travel_connectivity",
		"связь и интернет",
		"sim/esim",
		"travel_problems",
		"special_travel_needs",
		"insert into help_category_translations",
		"update help_articles",
		"tourist-faq-049",
		"tourist-faq-056",
		"tourist-faq-094",
		"tourist-faq-100",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("category taxonomy up migration missing %q", required)
		}
	}
	for _, categoryID := range []string{
		"documents_entry",
		"flights_airports_baggage",
		"stays_accommodation",
		"money_cards",
		"travel_connectivity",
		"health_insurance",
		"travel_safety",
		"local_transport",
		"planning_budget",
		"local_rules_culture",
		"special_travel_needs",
		"travel_problems",
	} {
		if !strings.Contains(upSQL, "'"+categoryID+"'") {
			t.Fatalf("category taxonomy up migration missing category %q", categoryID)
		}
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"delete from help_category_translations",
		"delete from help_categories",
		"travel_connectivity",
		"update help_articles",
		"money_cards_connectivity",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("category taxonomy down migration missing %q", required)
		}
	}
}

func TestSupportSavedRepliesSeedMigrationDefinesLocalizedCannedResponses(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/012_seed_support_saved_replies.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/012_seed_support_saved_replies.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"insert into support_saved_replies",
		"on conflict (id) do update",
		"jsonb_build_object",
		"'ru', jsonb_build_object",
		"'en', jsonb_build_object",
		"'kk', jsonb_build_object",
		"account_login_issue",
		"activity_meeting_point",
		"excursion_booking_question",
		"payment_refund_status",
		"currency_rate_notice",
		"technical_app_issue",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("saved replies seed up migration missing %q", required)
		}
	}

	distinctIDs := map[string]struct{}{}
	for _, match := range regexp.MustCompile(`'([a-z][a-z0-9]*(?:[_-][a-z0-9]+)+)'`).FindAllStringSubmatch(string(up), -1) {
		if strings.HasPrefix(match[1], "support_") {
			continue
		}
		distinctIDs[match[1]] = struct{}{}
	}
	for _, seededID := range []string{
		"account_login_issue",
		"activity_meeting_point",
		"payment_refund_status",
		"technical_app_issue",
	} {
		if _, ok := distinctIDs[seededID]; !ok {
			t.Fatalf("saved replies seed missing id %q", seededID)
		}
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"delete from support_saved_replies",
		"account_login_issue",
		"payment_refund_status",
		"technical_app_issue",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("saved replies seed down migration missing %q", required)
		}
	}
	if strings.Contains(downSQL, "truncate") {
		t.Fatal("saved replies seed down migration must not truncate manually created saved replies")
	}
}

func TestAppFAQMigrationSeedsUsefulLocalizedProductArticles(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/013_seed_app_faq.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/013_seed_app_faq.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := string(up)
	upLower := strings.ToLower(upSQL)
	for _, required := range []string{
		"insert into help_categories",
		"insert into help_category_translations",
		"insert into help_articles",
		"insert into help_article_translations",
		"insert into help_article_surfaces",
		"insert into help_article_tags",
		"app-faq-001",
		"app-faq-030",
		"app_getting_started",
		"app_chats_support",
		"inflap",
		"чат поддержки",
		"support chat",
		"курсы валют",
		"notifications",
		"select id, 'ru'",
		"select id, 'en'",
		"select id, 'kk'",
	} {
		if !strings.Contains(upLower, required) {
			t.Fatalf("app FAQ up migration missing %q", required)
		}
	}
	if strings.Contains(upSQL, "ON COMMIT DROP") {
		t.Fatal("app FAQ up migration must not use ON COMMIT DROP because the psql-based migrator runs statements in autocommit mode")
	}

	distinctIDs := map[string]struct{}{}
	for _, match := range regexp.MustCompile(`app-faq-\d{3}`).FindAllString(upSQL, -1) {
		distinctIDs[match] = struct{}{}
	}
	if len(distinctIDs) != 30 {
		t.Fatalf("seeded app FAQ article count = %d, want 30", len(distinctIDs))
	}

	downSQL := strings.ToLower(string(down))
	for _, required := range []string{
		"delete from help_articles",
		"app-faq-",
		"delete from help_category_translations",
		"app_getting_started",
		"app_chats_support",
	} {
		if !strings.Contains(downSQL, required) {
			t.Fatalf("app FAQ down migration missing %q", required)
		}
	}
	if strings.Contains(downSQL, "truncate") {
		t.Fatal("app FAQ down migration must not truncate manually created help content")
	}
}

func TestSupportAssignmentSegmentsMigrationDefinesRoutingPersistence(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/007_support_assignment_segments.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/007_support_assignment_segments.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"alter table support_tickets",
		"priority_reason_codes text[] not null default '{}'::text[]",
		"customer_segment text not null default 'standard'",
		"customer_segment_reason_codes text[] not null default '{}'::text[]",
		"segment_refresh_status text not null default 'stale'",
		"user_nickname_snapshot text not null default ''",
		"followers_count_snapshot integer not null default 0",
		"guide_status_snapshot text not null default ''",
		"subscription_tier_snapshot text",
		"assignment_status text not null default 'needs_assignment'",
		"assignment_reason_codes text[] not null default '{}'::text[]",
		"assigned_at timestamptz",
		"create table support_user_segments",
		"create table support_agents",
		"create index idx_support_tickets_customer_segment",
		"create index idx_support_tickets_assignment_status",
		"create index idx_support_agents_status",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	previous := -1
	for _, fragment := range []string{
		"drop table if exists support_agents",
		"drop table if exists support_user_segments",
		"alter table support_tickets",
		"drop column if exists assigned_at",
		"drop column if exists priority_reason_codes",
	} {
		current := strings.Index(downSQL, fragment)
		if current == -1 {
			t.Fatalf("down migration missing %q:\n%s", fragment, string(down))
		}
		if current <= previous {
			t.Fatalf("down migration orders %q incorrectly:\n%s", fragment, string(down))
		}
		previous = current
	}
}

func TestSupportAgentFullNameMigrationsUseGivenNameForChatDisplay(t *testing.T) {
	fullNameUp, err := os.ReadFile("../../../migrations/015_support_agent_full_name.up.sql")
	if err != nil {
		t.Fatalf("read full name up migration: %v", err)
	}
	repairUp, err := os.ReadFile("../../../migrations/016_repair_support_agent_full_name_backfill.up.sql")
	if err != nil {
		t.Fatalf("read repair up migration: %v", err)
	}
	repairDown, err := os.ReadFile("../../../migrations/016_repair_support_agent_full_name_backfill.down.sql")
	if err != nil {
		t.Fatalf("read repair down migration: %v", err)
	}

	fullNameSQL := strings.ToLower(string(fullNameUp))
	for _, required := range []string{
		"add column if not exists first_name",
		"add column if not exists last_name",
		"add column if not exists middle_name",
		"first_name = case",
		"split_part(btrim(display_name), ' ', 2)",
		"last_name = case",
		"split_part(btrim(display_name), ' ', 1)",
		"array_to_string((regexp_split_to_array(btrim(display_name), '\\s+'))[3:], ' ')",
	} {
		if !strings.Contains(fullNameSQL, required) {
			t.Fatalf("full name migration missing %q:\n%s", required, string(fullNameUp))
		}
	}

	repairSQL := strings.ToLower(string(repairUp))
	for _, required := range []string{
		"first_name = parsed.parts[2]",
		"last_name = parsed.parts[1]",
		"btrim(agent.first_name) = parsed.parts[1]",
		"btrim(agent.last_name) = parsed.parts[2]",
	} {
		if !strings.Contains(repairSQL, required) {
			t.Fatalf("repair migration missing %q:\n%s", required, string(repairUp))
		}
	}
	if strings.Contains(strings.ToLower(string(repairDown)), "update support_agents") {
		t.Fatal("repair down migration must not mutate manually corrected support agent profiles")
	}
}

func TestSupportPendingGuideSegmentRepairMigrationCorrectsFalseGuideSegments(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/009_repair_pending_guide_support_segments.up.sql")
	if err != nil {
		t.Fatalf("read up migration: %v", err)
	}
	down, err := os.ReadFile("../../../migrations/009_repair_pending_guide_support_segments.down.sql")
	if err != nil {
		t.Fatalf("read down migration: %v", err)
	}

	upSQL := strings.ToLower(string(up))
	for _, required := range []string{
		"update support_user_segments",
		"update support_tickets",
		"pending_review",
		"array_remove",
		"verified_guide",
		"segment_guide",
		"followers_count_snapshot",
		"guide_status_snapshot",
	} {
		if !strings.Contains(upSQL, required) {
			t.Fatalf("up migration missing %q:\n%s", required, string(up))
		}
	}

	downSQL := strings.ToLower(string(down))
	if !strings.Contains(downSQL, "irreversible") {
		t.Fatalf("down migration should explicitly document irreversible repair:\n%s", string(down))
	}
}
