package http

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
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

func TestNewDashboardViewDataWithSupportBuildsSupportSection(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 6, 27, 10, 0, 0, 0, time.UTC)
	tickets := make([]model.SupportTicket, 0, 6)
	for i := 0; i < 6; i++ {
		createdAt := now.Add(-time.Duration(i) * time.Minute)
		tickets = append(tickets, model.SupportTicket{
			ID:                   fmt.Sprintf("support-ticket-%d", i),
			Status:               model.SupportTicketStatusWaitingSupport,
			Priority:             model.SupportTicketPriorityNormal,
			UserNicknameSnapshot: fmt.Sprintf("traveler-%d", i),
			LastMessagePreview:   fmt.Sprintf("Need help with ticket %d", i),
			LastMessageAt:        createdAt,
			CreatedAt:            createdAt,
			UpdatedAt:            createdAt,
		})
	}
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	data := NewDashboardViewDataWithSupport(nil, nil, nil, nil, tickets, staff, localeRU)

	if data.Support == nil {
		t.Fatal("support dashboard section is missing")
	}
	if data.Support.TitleKey != "dashboard.supportTickets" {
		t.Fatalf("support section title key = %q, want dashboard.supportTickets", data.Support.TitleKey)
	}
	if data.Support.ViewAllURL != "/admin/support/tickets?status=waiting_support" {
		t.Fatalf("support section URL = %q, want waiting support queue", data.Support.ViewAllURL)
	}
	if len(data.Support.Items) != 5 {
		t.Fatalf("support section item count = %d, want 5", len(data.Support.Items))
	}
	if data.Support.Items[0].Item.LastMessageAt.Before(data.Support.Items[4].Item.LastMessageAt) {
		t.Fatal("support dashboard tickets are not ordered from newest to oldest")
	}
	if data.Support.Items[0].DetailURL != "/admin/support/tickets/support-ticket-0?status=waiting_support" {
		t.Fatalf("support ticket detail URL = %q", data.Support.Items[0].DetailURL)
	}
}

func TestDashboardViewDataLoadsWaitingSupportTicketsForSupportStaff(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 6, 27, 12, 0, 0, 0, time.UTC)
	client := &supportHTTPClientStub{tickets: []model.SupportTicket{{
		ID:                   "support-dashboard-ticket",
		Status:               model.SupportTicketStatusWaitingSupport,
		Priority:             model.SupportTicketPriorityNormal,
		UserNicknameSnapshot: "traveler",
		LastMessagePreview:   "Need help",
		LastMessageAt:        now,
		CreatedAt:            now,
		UpdatedAt:            now,
	}}}
	server := &Server{support: app.NewSupportUseCase(client, nil)}
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	data, err := server.dashboardViewData(context.Background(), staff, localeRU)

	if err != nil {
		t.Fatalf("dashboardViewData returned error: %v", err)
	}
	if data.Support == nil || len(data.Support.Items) != 1 {
		t.Fatalf("support dashboard section = %#v", data.Support)
	}
	if client.lastTicketFilter.Status != model.SupportTicketStatusWaitingSupport {
		t.Fatalf("support ticket status filter = %q, want waiting_support", client.lastTicketFilter.Status)
	}
	if client.lastTicketFilter.Limit != 5 {
		t.Fatalf("support ticket limit = %d, want 5", client.lastTicketFilter.Limit)
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
