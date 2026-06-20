package switches

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

type fakeTechBreakChecker struct {
	active bool
	err    error
	check  TechBreakCheck
	calls  int
}

func (f *fakeTechBreakChecker) HasActiveTechBreak(ctx context.Context, check TechBreakCheck) (bool, error) {
	f.calls++
	f.check = check
	return f.active, f.err
}

func TestMaintenanceMiddlewareBlocksActiveTechBreak(t *testing.T) {
	t.Parallel()

	checker := &fakeTechBreakChecker{active: true}
	nextCalled := false
	handler := MaintenanceMiddleware(checker, MaintenanceMiddlewareConfig{
		DomainCode: "CHAT",
		ScopeCodes: []string{"MESSAGES"},
	})(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		nextCalled = true
	}))

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/v1/messages", nil)
	handler.ServeHTTP(rec, req)

	if nextCalled {
		t.Fatal("next handler was called for active tech break")
	}
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503", rec.Code)
	}
	if checker.check.DomainCode != "CHAT" {
		t.Fatalf("domain = %q, want CHAT", checker.check.DomainCode)
	}
	if len(checker.check.ScopeCodes) != 1 || checker.check.ScopeCodes[0] != "MESSAGES" {
		t.Fatalf("scopes = %#v, want MESSAGES", checker.check.ScopeCodes)
	}
	if got := rec.Body.String(); got == "" || !contains(got, "technical_maintenance") || !contains(got, "Проводятся технические работы") {
		t.Fatalf("body = %q, want maintenance error contract", got)
	}
}

func TestMaintenanceMiddlewareFailsOpenOnCheckerError(t *testing.T) {
	t.Parallel()

	checker := &fakeTechBreakChecker{err: errors.New("switches unavailable")}
	var observedErr error
	nextCalled := false
	handler := MaintenanceMiddleware(checker, MaintenanceMiddlewareConfig{
		DomainCode: "FEED",
		OnCheckError: func(ctx context.Context, err error, check TechBreakCheck) {
			observedErr = err
		},
	})(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		nextCalled = true
		w.WriteHeader(http.StatusNoContent)
	}))

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/v1/feed", nil)
	handler.ServeHTTP(rec, req)

	if !nextCalled {
		t.Fatal("next handler was not called on checker error")
	}
	if rec.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want 204", rec.Code)
	}
	if observedErr == nil {
		t.Fatal("OnCheckError was not called")
	}
}

func TestMaintenanceMiddlewareCachesCheckResult(t *testing.T) {
	t.Parallel()

	checker := &fakeTechBreakChecker{active: true}
	handler := MaintenanceMiddleware(checker, MaintenanceMiddlewareConfig{DomainCode: "ACTIVITY"})(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("next handler must not be called while cached tech break is active")
	}))

	for i := 0; i < 2; i++ {
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/v1/activities", nil)
		handler.ServeHTTP(rec, req)
		if rec.Code != http.StatusServiceUnavailable {
			t.Fatalf("request %d status = %d, want 503", i+1, rec.Code)
		}
	}
	if checker.calls != 1 {
		t.Fatalf("checker calls = %d, want 1 cached call", checker.calls)
	}
}

func TestMaintenanceMiddlewareSkipsHealthAndOptions(t *testing.T) {
	t.Parallel()

	checker := &fakeTechBreakChecker{active: true}
	handler := MaintenanceMiddleware(checker, MaintenanceMiddlewareConfig{
		DomainCode:       "USER",
		SkipPathPrefixes: []string{"/admin/static/"},
	})(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusAccepted)
	}))

	for _, tc := range []struct {
		name   string
		method string
		path   string
	}{
		{name: "health", method: http.MethodGet, path: "/health"},
		{name: "ready", method: http.MethodGet, path: "/ready"},
		{name: "live", method: http.MethodGet, path: "/live"},
		{name: "metrics", method: http.MethodGet, path: "/metrics"},
		{name: "options", method: http.MethodOptions, path: "/v1/users"},
		{name: "prefix", method: http.MethodGet, path: "/admin/static/css/admin.css"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(tc.method, tc.path, nil)
			handler.ServeHTTP(rec, req)
			if rec.Code != http.StatusAccepted {
				t.Fatalf("status = %d, want 202", rec.Code)
			}
		})
	}
	if checker.calls != 0 {
		t.Fatalf("checker calls = %d, want 0", checker.calls)
	}
}

func contains(s string, substr string) bool {
	for i := 0; i+len(substr) <= len(s); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
