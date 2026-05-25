package http

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

func TestNewDashboardViewDataBuildsLatestModerationSections(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 5, 25, 12, 0, 0, 0, time.UTC)
	excursions := make([]*model.ModerationCase, 0, 6)
	for i := 0; i < 6; i++ {
		excursions = append(excursions, dashboardTestCase(model.ModerationTargetExcursion, now.Add(-time.Duration(i)*time.Minute)))
	}
	activities := []*model.ModerationCase{dashboardTestCase(model.ModerationTargetActivity, now)}
	guides := []*model.ModerationCase{dashboardTestCase(model.ModerationTargetGuideApplication, now)}
	chats := []*model.ModerationCase{dashboardTestCase(model.ModerationTargetChatMessage, now)}

	data := NewDashboardViewData(excursions, activities, guides, chats)

	if len(data.Sections) != 4 {
		t.Fatalf("section count = %d, want 4", len(data.Sections))
	}
	first := data.Sections[0]
	if first.TitleKey != "dashboard.excursionModeration" {
		t.Fatalf("first section title key = %q, want excursion moderation", first.TitleKey)
	}
	if first.ViewAllURL != "/admin/moderation/excursions" {
		t.Fatalf("first section URL = %q, want excursions queue URL", first.ViewAllURL)
	}
	if len(first.Items) != 5 {
		t.Fatalf("first section item count = %d, want 5", len(first.Items))
	}
	if first.Items[0].Case.OpenedAt.Before(first.Items[4].Case.OpenedAt) {
		t.Fatal("dashboard items are not ordered from newest to oldest")
	}
}

func dashboardTestCase(targetType model.ModerationTargetType, openedAt time.Time) *model.ModerationCase {
	return &model.ModerationCase{
		ID:             uuid.New(),
		TargetType:     targetType,
		TargetID:       uuid.New(),
		SourceService:  "test-service",
		SourceRevision: 1,
		Status:         enum.ModerationCaseStatusOpen,
		Priority:       10,
		OpenedAt:       openedAt,
		CreatedAt:      openedAt,
		UpdatedAt:      openedAt,
	}
}
