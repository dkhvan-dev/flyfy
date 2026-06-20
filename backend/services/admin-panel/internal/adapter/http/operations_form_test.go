package http

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
)

func TestParseOperationFeatureFlagFormUsesRepeatedArrayValues(t *testing.T) {
	t.Parallel()

	form := url.Values{}
	form.Set("code", "LIMIT_TEST")
	form.Set("name", "Limit test")
	form.Set("group", "onboarding")
	form.Set("type", "ARRAY_INTEGER")
	form.Set("action_start_date", "2026-06-19T15:00")
	form.Add("value", "10")
	form.Add("value", "20")
	request := operationFormRequest(t, form)

	input, err := parseOperationFeatureFlagForm(request, "CORE", "", true)
	if err != nil {
		t.Fatalf("parseOperationFeatureFlagForm() error = %v", err)
	}
	if len(input.Value) != 2 || input.Value[0] != 10 || input.Value[1] != 20 {
		t.Fatalf("input.Value = %#v, want [10 20]", input.Value)
	}
}

func TestParseOperationTechBreakFormDoesNotAcceptValue(t *testing.T) {
	t.Parallel()

	form := url.Values{}
	form.Set("name", "Core break")
	form.Set("action_start_date", "2026-06-19T15:00")
	form.Add("scope_codes", "CORE_TEST")
	form.Set("value", "legacy-value")
	request := operationFormRequest(t, form)

	input, err := parseOperationTechBreakForm(request, "CORE", 7)
	if err != nil {
		t.Fatalf("parseOperationTechBreakForm() error = %v", err)
	}
	if len(input.ScopeCodes) != 1 || input.ScopeCodes[0] != "CORE_TEST" {
		t.Fatalf("input.ScopeCodes = %#v, want [CORE_TEST]", input.ScopeCodes)
	}
}

func operationFormRequest(t *testing.T, form url.Values) *http.Request {
	t.Helper()

	request := httptest.NewRequest(http.MethodPost, "/admin/operations/domains/CORE", nil)
	request.Form = form
	request.PostForm = form
	return request
}
