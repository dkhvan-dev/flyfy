package repository

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

func TestPGChecklistRepositoryPersistsTripChecklistInstanceAgainstLiveDB(t *testing.T) {
	dsn := os.Getenv("CHECKLIST_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set CHECKLIST_SERVICE_REPOSITORY_TEST_DSN to run repository integration tests")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect test database: %v", err)
	}
	defer pool.Close()

	if err = ensureChecklistTestSchema(ctx, pool); err != nil {
		t.Fatalf("create checklist test schema: %v", err)
	}
	t.Cleanup(func() {
		_, _ = pool.Exec(context.Background(), `TRUNCATE checklist_item_feedback, checklist_instance_items, checklist_instances`)
	})

	repo := NewPGChecklistRepository(pool)
	checklist := model.TripChecklist{
		InstanceID: "checklist-test-instance",
		UserID:     "user-42",
		TripID:     "trip-1",
		Destination: model.TripDestination{
			CountryCode: "JP",
			CityName:    "Tokyo",
		},
		StartAt: time.Date(2026, time.June, 10, 10, 0, 0, 0, time.UTC),
		EndAt:   time.Date(2026, time.June, 20, 10, 0, 0, 0, time.UTC),
		Items: []model.ChecklistItem{
			{
				ID:         "documents.passport_id",
				Category:   model.ChecklistCategoryDocuments,
				Priority:   model.ChecklistPriorityCritical,
				Status:     model.ChecklistItemOpen,
				Title:      model.LocalizedText{EN: "Passport", RU: "Паспорт", KK: "Паспорт"},
				Reason:     model.LocalizedText{EN: "Confirm before travel"},
				TrustLevel: model.TrustLevelOfficialLinkRequired,
				Source: model.Source{
					Name:       "Official source",
					URL:        "https://example.gov/passport",
					Type:       model.SourceTypeOfficialAuthority,
					Confidence: model.SourceConfidenceHigh,
				},
				RequiresUserConfirmation: true,
			},
		},
		Readiness: model.ReadinessSummary{
			Score:  50,
			Status: model.ReadinessStatusNotReady,
		},
		TrustNotice: model.TrustNotice{
			Code:  "official_source_required",
			Title: model.LocalizedText{EN: "Official check required"},
		},
		GeneratedAt: time.Date(2026, time.June, 1, 10, 0, 0, 0, time.UTC),
		UpdatedAt:   time.Date(2026, time.June, 1, 10, 5, 0, 0, time.UTC),
	}

	if err = repo.SaveTripChecklistInstance(ctx, checklist); err != nil {
		t.Fatalf("SaveTripChecklistInstance returned error: %v", err)
	}

	found, ok, err := repo.FindTripChecklistInstance(ctx, "user-42", "trip-1")
	if err != nil {
		t.Fatalf("FindTripChecklistInstance returned error: %v", err)
	}
	if !ok {
		t.Fatal("expected persisted checklist instance")
	}
	if found.InstanceID != checklist.InstanceID || found.UserID != "user-42" || found.TripID != "trip-1" {
		t.Fatalf("unexpected checklist identity: %#v", found)
	}
	if found.Destination.CountryCode != "JP" || !found.StartAt.Equal(checklist.StartAt) {
		t.Fatalf("expected persisted trip context, got %#v", found)
	}
	if len(found.Items) != 1 || found.Items[0].Source.Confidence != model.SourceConfidenceHigh {
		t.Fatalf("expected persisted item source, got %#v", found.Items)
	}

	found.Items[0].Status = model.ChecklistItemDone
	found.Items[0].AssignedUserID = "user-42"
	found.Readiness = model.ReadinessSummary{Score: 100, Status: model.ReadinessStatusReady}
	if err = repo.SaveTripChecklistInstance(ctx, found); err != nil {
		t.Fatalf("SaveTripChecklistInstance update returned error: %v", err)
	}

	reloaded, ok, err := repo.FindTripChecklistInstance(ctx, "user-42", "trip-1")
	if err != nil {
		t.Fatalf("FindTripChecklistInstance reload returned error: %v", err)
	}
	if !ok || reloaded.Items[0].Status != model.ChecklistItemDone || reloaded.Readiness.Status != model.ReadinessStatusReady {
		t.Fatalf("expected updated status/readiness, got ok=%v checklist=%#v", ok, reloaded)
	}
	if reloaded.Items[0].AssignedUserID != "user-42" {
		t.Fatalf("expected assignment to persist, got %#v", reloaded.Items[0])
	}

	feedback := model.ChecklistItemFeedback{
		ID:                  "feedback-test-1",
		ChecklistInstanceID: checklist.InstanceID,
		UserID:              "user-42",
		TripID:              "trip-1",
		ItemID:              "documents.passport_id",
		FeedbackType:        model.ChecklistFeedbackHelpful,
		Comment:             "Useful reminder",
		CreatedAt:           time.Date(2026, time.June, 2, 10, 0, 0, 0, time.UTC),
	}
	if err = repo.SaveChecklistItemFeedback(ctx, feedback); err != nil {
		t.Fatalf("SaveChecklistItemFeedback returned error: %v", err)
	}

	var persistedType string
	var persistedComment string
	if err = pool.QueryRow(
		ctx,
		`SELECT feedback_type, comment FROM checklist_item_feedback WHERE id = $1`,
		feedback.ID,
	).Scan(&persistedType, &persistedComment); err != nil {
		t.Fatalf("select persisted feedback: %v", err)
	}
	if persistedType != string(model.ChecklistFeedbackHelpful) || persistedComment != "Useful reminder" {
		t.Fatalf("unexpected persisted feedback type=%q comment=%q", persistedType, persistedComment)
	}

	entries, err := repo.ListChecklistItemFeedback(ctx, model.ChecklistFeedbackHelpful, 10)
	if err != nil {
		t.Fatalf("ListChecklistItemFeedback returned error: %v", err)
	}
	if len(entries) != 1 || entries[0].ID != feedback.ID {
		t.Fatalf("expected persisted feedback entry, got %#v", entries)
	}
}

func TestPGChecklistRepositoryPersistsCustomChecklistItemsAgainstLiveDB(t *testing.T) {
	dsn := os.Getenv("CHECKLIST_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set CHECKLIST_SERVICE_REPOSITORY_TEST_DSN to run repository integration tests")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect test database: %v", err)
	}
	defer pool.Close()

	if err = ensureChecklistTestSchema(ctx, pool); err != nil {
		t.Fatalf("create checklist test schema: %v", err)
	}
	t.Cleanup(func() {
		_, _ = pool.Exec(
			context.Background(),
			`TRUNCATE custom_checklist_items, personal_checklist_templates, checklist_item_feedback, checklist_instance_items, checklist_instances`,
		)
	})

	repo := NewPGChecklistRepository(pool)
	checklist := model.TripChecklist{
		InstanceID:  "checklist-custom-test-instance",
		UserID:      "user-42",
		TripID:      "trip-custom",
		Destination: model.TripDestination{CountryCode: "JP", CityName: "Tokyo"},
		StartAt:     time.Date(2026, time.June, 10, 10, 0, 0, 0, time.UTC),
		EndAt:       time.Date(2026, time.June, 20, 10, 0, 0, 0, time.UTC),
		Readiness:   model.ReadinessSummary{Score: 100, Status: model.ReadinessStatusReady},
		TrustNotice: model.TrustNotice{Code: "verified_curated"},
		GeneratedAt: time.Date(2026, time.June, 1, 10, 0, 0, 0, time.UTC),
		UpdatedAt:   time.Date(2026, time.June, 1, 10, 5, 0, 0, time.UTC),
	}
	if err = repo.SaveTripChecklistInstance(ctx, checklist); err != nil {
		t.Fatalf("SaveTripChecklistInstance returned error: %v", err)
	}

	template := model.PersonalChecklistTemplate{
		ID:        "template-camera",
		UserID:    "user-42",
		Title:     "Camera charger",
		Note:      "USB-C",
		Category:  model.ChecklistCategoryCustom,
		Priority:  model.ChecklistPriorityRecommended,
		IsActive:  true,
		CreatedAt: time.Date(2026, time.June, 1, 11, 0, 0, 0, time.UTC),
		UpdatedAt: time.Date(2026, time.June, 1, 11, 0, 0, 0, time.UTC),
	}
	if err = repo.SavePersonalChecklistTemplate(ctx, template); err != nil {
		t.Fatalf("SavePersonalChecklistTemplate returned error: %v", err)
	}

	item := model.CustomChecklistItem{
		ID:                  "custom-camera",
		ChecklistInstanceID: checklist.InstanceID,
		UserID:              "user-42",
		TripID:              "trip-custom",
		Title:               "Camera charger",
		Note:                "USB-C",
		Category:            model.ChecklistCategoryCustom,
		Priority:            model.ChecklistPriorityRecommended,
		Status:              model.ChecklistItemOpen,
		ReuseInFuture:       true,
		PersonalTemplateID:  template.ID,
		CreatedAt:           time.Date(2026, time.June, 1, 12, 0, 0, 0, time.UTC),
		UpdatedAt:           time.Date(2026, time.June, 1, 12, 0, 0, 0, time.UTC),
	}
	if err = repo.SaveCustomChecklistItem(ctx, item); err != nil {
		t.Fatalf("SaveCustomChecklistItem returned error: %v", err)
	}

	found, ok, err := repo.FindCustomChecklistItem(ctx, "user-42", "trip-custom", "custom-camera")
	if err != nil {
		t.Fatalf("FindCustomChecklistItem returned error: %v", err)
	}
	if !ok || found.Title != "Camera charger" || found.PersonalTemplateID != template.ID {
		t.Fatalf("expected persisted custom item, ok=%v item=%#v", ok, found)
	}

	items, err := repo.ListCustomChecklistItems(ctx, "user-42", "trip-custom")
	if err != nil {
		t.Fatalf("ListCustomChecklistItems returned error: %v", err)
	}
	if len(items) != 1 || items[0].ID != "custom-camera" {
		t.Fatalf("expected one active custom item, got %#v", items)
	}

	templates, err := repo.ListPersonalChecklistTemplates(ctx, "user-42", true)
	if err != nil {
		t.Fatalf("ListPersonalChecklistTemplates returned error: %v", err)
	}
	if len(templates) != 1 || templates[0].ID != template.ID {
		t.Fatalf("expected active personal template, got %#v", templates)
	}

	if err = repo.SoftDeleteCustomChecklistItem(
		ctx,
		"user-42",
		"trip-custom",
		"custom-camera",
		time.Date(2026, time.June, 2, 10, 0, 0, 0, time.UTC),
	); err != nil {
		t.Fatalf("SoftDeleteCustomChecklistItem returned error: %v", err)
	}
	items, err = repo.ListCustomChecklistItems(ctx, "user-42", "trip-custom")
	if err != nil {
		t.Fatalf("ListCustomChecklistItems after delete returned error: %v", err)
	}
	if len(items) != 0 {
		t.Fatalf("expected soft-deleted item to be excluded, got %#v", items)
	}
}

func ensureChecklistTestSchema(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS checklist_instances (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			trip_id TEXT NOT NULL,
			destination JSONB,
			start_at TIMESTAMPTZ,
			end_at TIMESTAMPTZ,
			transport_modes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
			activity_slugs TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
			has_children BOOLEAN NOT NULL DEFAULT false,
			citizenship_country_code TEXT NOT NULL DEFAULT '',
			readiness JSONB NOT NULL DEFAULT '{}'::jsonb,
			seasonal_profile JSONB,
			trust_notice JSONB NOT NULL DEFAULT '{}'::jsonb,
			generated_at TIMESTAMPTZ NOT NULL,
			updated_at TIMESTAMPTZ NOT NULL,
			UNIQUE (user_id, trip_id)
		);

		CREATE TABLE IF NOT EXISTS checklist_instance_items (
			instance_id TEXT NOT NULL REFERENCES checklist_instances(id) ON DELETE CASCADE,
			item_id TEXT NOT NULL,
			category TEXT NOT NULL,
			priority TEXT NOT NULL,
			status TEXT NOT NULL,
			assigned_user_id TEXT,
			title JSONB NOT NULL DEFAULT '{}'::jsonb,
			reason JSONB NOT NULL DEFAULT '{}'::jsonb,
			trust_level TEXT NOT NULL,
			source JSONB NOT NULL DEFAULT '{}'::jsonb,
			requires_user_confirmation BOOLEAN NOT NULL DEFAULT false,
			deadline_at TIMESTAMPTZ,
			position INTEGER NOT NULL DEFAULT 0,
			created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
			updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
			PRIMARY KEY (instance_id, item_id)
		);

		CREATE TABLE IF NOT EXISTS checklist_item_feedback (
			id TEXT PRIMARY KEY,
			checklist_instance_id TEXT NOT NULL REFERENCES checklist_instances(id) ON DELETE CASCADE,
			user_id TEXT NOT NULL,
			trip_id TEXT NOT NULL,
			item_id TEXT NOT NULL,
			feedback_type TEXT NOT NULL,
			comment TEXT NOT NULL DEFAULT '',
			created_at TIMESTAMPTZ NOT NULL DEFAULT now()
		);

		CREATE TABLE IF NOT EXISTS personal_checklist_templates (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			title TEXT NOT NULL,
			note TEXT NOT NULL DEFAULT '',
			category TEXT NOT NULL DEFAULT 'custom',
			priority TEXT NOT NULL DEFAULT 'recommended',
			is_active BOOLEAN NOT NULL DEFAULT true,
			created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
			updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
		);

		CREATE TABLE IF NOT EXISTS custom_checklist_items (
			id TEXT PRIMARY KEY,
			checklist_instance_id TEXT NOT NULL REFERENCES checklist_instances(id) ON DELETE CASCADE,
			user_id TEXT NOT NULL,
			trip_id TEXT NOT NULL,
			title TEXT NOT NULL,
			note TEXT NOT NULL DEFAULT '',
			category TEXT NOT NULL DEFAULT 'custom',
			priority TEXT NOT NULL DEFAULT 'recommended',
			status TEXT NOT NULL DEFAULT 'open',
			assigned_user_id TEXT,
			reuse_in_future BOOLEAN NOT NULL DEFAULT false,
			personal_template_id TEXT REFERENCES personal_checklist_templates(id) ON DELETE SET NULL,
			created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
			updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
			deleted_at TIMESTAMPTZ
		);

		ALTER TABLE checklist_instances
			ADD COLUMN IF NOT EXISTS transport_modes TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
			ADD COLUMN IF NOT EXISTS activity_slugs TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
			ADD COLUMN IF NOT EXISTS has_children BOOLEAN NOT NULL DEFAULT false,
			ADD COLUMN IF NOT EXISTS citizenship_country_code TEXT NOT NULL DEFAULT '';
	`)
	return err
}
