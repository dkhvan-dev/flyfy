package app

import (
	"context"
	"testing"
	"time"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

func TestTripChecklistInstancePersistsItemStatusAndReadiness(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	startAt := time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC)
	input := GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-bali-jan",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
		TransportModes: []model.TransportMode{
			model.TransportModeFlight,
		},
		ActivitySlugs: []string{"beach"},
		TravelerProfile: model.TravelerProfile{
			PreferredLanguage: "ru",
		},
	}

	created, err := uc.GetOrCreateTripChecklist(ctx, input)
	if err != nil {
		t.Fatalf("GetOrCreateTripChecklist returned error: %v", err)
	}
	if created.InstanceID == "" {
		t.Fatal("expected persisted checklist instance id")
	}
	if created.UserID != "user-1" {
		t.Fatalf("expected checklist user id to be set from input, got %q", created.UserID)
	}
	if created.Readiness.Status != model.ReadinessStatusNotReady {
		t.Fatalf("expected initial checklist to be not ready, got %q", created.Readiness.Status)
	}

	updated, err := uc.UpdateChecklistItemStatus(ctx, UpdateChecklistItemStatusInput{
		UserID: "user-1",
		TripID: "trip-bali-jan",
		ItemID: "documents.passport",
		Status: model.ChecklistItemDone,
	})
	if err != nil {
		t.Fatalf("UpdateChecklistItemStatus returned error: %v", err)
	}

	item := findChecklistItem(t, updated.Items, "documents.passport")
	if item.Status != model.ChecklistItemDone {
		t.Fatalf("expected passport to be done, got %q", item.Status)
	}
	if updated.Readiness.Status == model.ReadinessStatusNotReady {
		t.Fatalf("expected readiness to move past not_ready after critical item is done, got %#v", updated.Readiness)
	}
	if len(updated.Readiness.Blockers) != 0 {
		t.Fatalf("expected no blockers after critical item is done, got %#v", updated.Readiness.Blockers)
	}

	reloaded, err := uc.GetOrCreateTripChecklist(ctx, input)
	if err != nil {
		t.Fatalf("GetOrCreateTripChecklist reload returned error: %v", err)
	}
	reloadedItem := findChecklistItem(t, reloaded.Items, "documents.passport")
	if reloadedItem.Status != model.ChecklistItemDone {
		t.Fatalf("expected persisted passport status to survive reload, got %q", reloadedItem.Status)
	}
	if reloaded.InstanceID != created.InstanceID {
		t.Fatalf("expected same persisted instance id, got %q want %q", reloaded.InstanceID, created.InstanceID)
	}
}

func TestChecklistItemFeedbackPersistsLearningSignal(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	startAt := time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC)
	input := GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-bali-jan",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
		TransportModes: []model.TransportMode{
			model.TransportModeFlight,
		},
		ActivitySlugs: []string{"beach"},
		TravelerProfile: model.TravelerProfile{
			PreferredLanguage: "ru",
		},
	}
	if _, err := uc.GetOrCreateTripChecklist(ctx, input); err != nil {
		t.Fatalf("GetOrCreateTripChecklist returned error: %v", err)
	}

	feedback, err := uc.SubmitChecklistItemFeedback(ctx, SubmitChecklistItemFeedbackInput{
		UserID:       "user-1",
		TripID:       "trip-bali-jan",
		ItemID:       "documents.passport",
		FeedbackType: model.ChecklistFeedbackHelpful,
		Comment:      "Packed it and it was useful",
	})
	if err != nil {
		t.Fatalf("SubmitChecklistItemFeedback returned error: %v", err)
	}
	if feedback.ID == "" {
		t.Fatal("expected feedback id")
	}
	if feedback.UserID != "user-1" ||
		feedback.TripID != "trip-bali-jan" ||
		feedback.ItemID != "documents.passport" ||
		feedback.FeedbackType != model.ChecklistFeedbackHelpful {
		t.Fatalf("unexpected feedback identity: %#v", feedback)
	}

	entries := repo.FeedbackEntries()
	if len(entries) != 1 {
		t.Fatalf("expected one persisted feedback entry, got %#v", entries)
	}
	if entries[0].Comment != "Packed it and it was useful" {
		t.Fatalf("expected trimmed feedback comment, got %#v", entries[0])
	}
}

func TestChecklistItemFeedbackRejectsUnknownItem(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	startAt := time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC)
	if _, err := uc.GetOrCreateTripChecklist(ctx, GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-bali-jan",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
	}); err != nil {
		t.Fatalf("GetOrCreateTripChecklist returned error: %v", err)
	}

	_, err := uc.SubmitChecklistItemFeedback(ctx, SubmitChecklistItemFeedbackInput{
		UserID:       "user-1",
		TripID:       "trip-bali-jan",
		ItemID:       "unknown.item",
		FeedbackType: model.ChecklistFeedbackHelpful,
	})
	if err == nil {
		t.Fatal("expected unknown item feedback to fail")
	}
}

func TestChecklistItemAssignmentPersistsAssignee(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	startAt := time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC)
	if _, err := uc.GetOrCreateTripChecklist(ctx, GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-bali-jan",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
	}); err != nil {
		t.Fatalf("GetOrCreateTripChecklist returned error: %v", err)
	}

	assigned, err := uc.SetChecklistItemAssignment(ctx, SetChecklistItemAssignmentInput{
		UserID:     "user-1",
		TripID:     "trip-bali-jan",
		ItemID:     "documents.passport",
		AssignToMe: true,
	})
	if err != nil {
		t.Fatalf("SetChecklistItemAssignment returned error: %v", err)
	}
	if item := findChecklistItem(t, assigned.Items, "documents.passport"); item.AssignedUserID != "user-1" {
		t.Fatalf("expected item assigned to user-1, got %#v", item)
	}

	reloaded, err := uc.GetOrCreateTripChecklist(ctx, GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-bali-jan",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
	})
	if err != nil {
		t.Fatalf("GetOrCreateTripChecklist reload returned error: %v", err)
	}
	if item := findChecklistItem(t, reloaded.Items, "documents.passport"); item.AssignedUserID != "user-1" {
		t.Fatalf("expected assignment to survive reload, got %#v", item)
	}
}

func TestTripChecklistRemindersUsePersistedTripDates(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryChecklistRepository(seedTestCatalog())
	uc := NewChecklistUseCase(repo)

	startAt := time.Date(2026, time.January, 12, 10, 0, 0, 0, time.UTC)
	if _, err := uc.GetOrCreateTripChecklist(ctx, GenerateTripChecklistInput{
		UserID:      "user-1",
		TripID:      "trip-bali-jan",
		Destination: model.TripDestination{CountryCode: "ID", CityName: "Bali"},
		StartAt:     startAt,
		EndAt:       startAt.AddDate(0, 0, 7),
	}); err != nil {
		t.Fatalf("GetOrCreateTripChecklist returned error: %v", err)
	}

	reminders, err := uc.ListTripChecklistReminders(ctx, ListTripChecklistRemindersInput{
		UserID: "user-1",
		TripID: "trip-bali-jan",
	})
	if err != nil {
		t.Fatalf("ListTripChecklistReminders returned error: %v", err)
	}
	if len(reminders) != 5 {
		t.Fatalf("expected five production reminder milestones, got %#v", reminders)
	}
	if reminders[0].OffsetDays != 30 || !reminders[0].DueAt.Equal(startAt.AddDate(0, 0, -30)) {
		t.Fatalf("expected first reminder 30 days before trip, got %#v", reminders[0])
	}
}

func findChecklistItem(t *testing.T, items []model.ChecklistItem, id string) model.ChecklistItem {
	t.Helper()
	for _, item := range items {
		if item.ID == id {
			return item
		}
	}
	t.Fatalf("expected item %q in %#v", id, items)
	return model.ChecklistItem{}
}
