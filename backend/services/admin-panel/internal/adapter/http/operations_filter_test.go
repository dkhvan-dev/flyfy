package http

import (
	"html"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestParseOperationsResourceFilterIncludesDateRange(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodGet, "/admin/operations/domains/CORE?tab=feature-flags&q=otp&group=onboarding&in_archive=true&page=2&size=50&action_start_date=2026-06-01&action_end_date=2026-06-30", nil)

	filters := parseOperationsResourceFilter(request)
	input := operationsDomainDetailInput(filters)

	wantStart := time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC)
	wantEnd := time.Date(2026, 6, 30, 0, 0, 0, 0, time.UTC).Add(24*time.Hour - time.Nanosecond)
	assertOperationFilterDate(t, "feature flag start", input.FeatureFlags.ActionStartDate, wantStart)
	assertOperationFilterDate(t, "feature flag end", input.FeatureFlags.ActionEndDate, wantEnd)
	assertOperationFilterDate(t, "tech break start", input.TechBreaks.ActionStartDate, wantStart)
	assertOperationFilterDate(t, "tech break end", input.TechBreaks.ActionEndDate, wantEnd)
}

func TestOperationsDomainDetailFiltersScopesBySearch(t *testing.T) {
	t.Parallel()

	view := NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{
		Domain: model.OperationDomain{Code: "CORE"},
		Scopes: []model.OperationTechBreakScope{
			{ID: 1, Code: "CORE_TEST", Name: "Core test"},
			{ID: 2, Code: "IDENTITY", Name: "Identity checks"},
		},
	}, OperationsTabScopes, OperationsResourceFilterViewData{Search: "identity", Size: 20})

	if len(view.Scopes) != 1 || view.Scopes[0].Code != "IDENTITY" {
		t.Fatalf("view.Scopes = %#v, want only IDENTITY", view.Scopes)
	}
}

func TestOperationsDomainFeatureFlagFiltersRenderGroupDropdownAndDates(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	start := time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC)
	end := time.Date(2026, 6, 30, 0, 0, 0, 0, time.UTC).Add(24*time.Hour - time.Nanosecond)
	pageData := PageData{
		Title:     "Операции",
		Locale:    localeRU,
		Path:      "/admin/operations/domains/CORE",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data: NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{
			Domain: model.OperationDomain{
				Code:              "CORE",
				Description:       "Core команда",
				FeatureFlagGroups: []string{"onboarding", "payments"},
			},
		}, OperationsTabFeatureFlags, OperationsResourceFilterViewData{
			Group:           "payments",
			ActionStartDate: &start,
			ActionEndDate:   &end,
			Size:            20,
		}),
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/domain", pageData)
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		`<select name="group">`,
		`<option value="">Все группы</option>`,
		`<option value="payments" selected>payments</option>`,
		`name="action_start_date" value="2026-06-01"`,
		`name="action_end_date" value="2026-06-30"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("operations feature flag filters did not render %q: %s", expected, body)
		}
	}
}

func TestOperationsDomainTechBreakAndScopeFiltersRenderSearchAndDates(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}
	start := time.Date(2026, 7, 1, 0, 0, 0, 0, time.UTC)
	end := time.Date(2026, 7, 5, 0, 0, 0, 0, time.UTC).Add(24*time.Hour - time.Nanosecond)
	domain := model.OperationDomain{Code: "CORE", Description: "Core команда"}

	pageData := PageData{
		Title:     "Операции",
		Locale:    localeRU,
		Path:      "/admin/operations/domains/CORE",
		Staff:     adminTemplateActor(),
		CSRFToken: "csrf-token",
		Data: NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{
			Domain: domain,
		}, OperationsTabTechBreaks, OperationsResourceFilterViewData{
			Search:          "maintenance",
			ActionStartDate: &start,
			ActionEndDate:   &end,
			Size:            20,
		}),
	}

	recorder := httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/domain", pageData)
	body := html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		`<input type="hidden" name="tab" value="tech-breaks">`,
		`type="search" name="q" value="maintenance"`,
		`name="action_start_date" value="2026-07-01"`,
		`name="action_end_date" value="2026-07-05"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("operations tech break filters did not render %q: %s", expected, body)
		}
	}

	pageData.Data = NewOperationsDomainDetailViewData(app.OperationsDomainDetailPage{
		Domain: domain,
	}, OperationsTabScopes, OperationsResourceFilterViewData{Search: "identity", Size: 20})
	recorder = httptest.NewRecorder()
	renderer.Render(recorder, http.StatusOK, "operations/domain", pageData)
	body = html.UnescapeString(recorder.Body.String())
	for _, expected := range []string{
		`<input type="hidden" name="tab" value="scopes">`,
		`type="search" name="q" value="identity"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("operations scope filters did not render %q: %s", expected, body)
		}
	}
}

func assertOperationFilterDate(t *testing.T, name string, got *time.Time, want time.Time) {
	t.Helper()

	if got == nil || !got.Equal(want) {
		t.Fatalf("%s = %v, want %v", name, got, want)
	}
}
