package http

import (
	"net/http/httptest"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

func TestParseExcursionQueueFilter(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(
		"GET",
		"/admin/moderation/excursions?status=all&city=Almaty&q=medeu&signal=new_guide&risk=high&sort=risk_desc",
		nil,
	)
	filter, view := parseExcursionQueueFilter(request)

	if len(filter.Statuses) != len(allModerationCaseStatuses) {
		t.Fatalf("status=all should include all statuses: %#v", filter.Statuses)
	}
	if filter.Search != "medeu" || filter.City != "Almaty" || filter.Signal != "new_guide" {
		t.Fatalf("unexpected text filters: %#v", filter)
	}
	if filter.Risk != model.ModerationRiskFilterHigh {
		t.Fatalf("unexpected risk filter: %q", filter.Risk)
	}
	if filter.Sort != model.ModerationQueueSortRiskDesc {
		t.Fatalf("unexpected sort: %q", filter.Sort)
	}
	if view.Status != "all" || view.Query == "" {
		t.Fatalf("view filter did not preserve selected state: %#v", view)
	}
}

func TestParseExcursionQueueFilterDefaultsToActiveStatuses(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest("GET", "/admin/moderation/excursions", nil)
	filter, view := parseExcursionQueueFilter(request)

	expected := []enum.ModerationCaseStatus{
		enum.ModerationCaseStatusOpen,
		enum.ModerationCaseStatusInReview,
		enum.ModerationCaseStatusEscalated,
	}
	if len(filter.Statuses) != len(expected) {
		t.Fatalf("unexpected default statuses: %#v", filter.Statuses)
	}
	for i := range expected {
		if filter.Statuses[i] != expected[i] {
			t.Fatalf("unexpected default statuses: %#v", filter.Statuses)
		}
	}
	if view.Status != excursionQueueStatusActive {
		t.Fatalf("unexpected default view status: %q", view.Status)
	}
}

func TestParseExcursionHistoryFilterDefaultsToAllStatuses(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest("GET", "/admin/moderation/excursions/history", nil)
	filter, view := parseExcursionHistoryFilter(request)

	if len(filter.Statuses) != len(allModerationCaseStatuses) {
		t.Fatalf("history should include all statuses by default: %#v", filter.Statuses)
	}
	if view.Status != excursionQueueStatusAll {
		t.Fatalf("unexpected history default status: %q", view.Status)
	}
	if filter.Sort != model.ModerationQueueSortOpenedDesc {
		t.Fatalf("unexpected history default sort: %q", filter.Sort)
	}
}
