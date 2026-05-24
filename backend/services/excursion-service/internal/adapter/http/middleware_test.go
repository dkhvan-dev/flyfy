package http

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/config"
)

func TestTrustedAuthHeadersRequireInternalServiceToken(t *testing.T) {
	cfg := &config.Config{}
	cfg.Security.InternalServiceToken = "internal-secret"
	cfg.Security.RequireAuthenticatedWrites = true
	cfg.Security.TrustedGatewayHeaderUserID = "X-User-Id"
	cfg.Security.TrustedGatewayHeaderRoles = "X-User-Roles"
	cfg.Security.TrustedGatewayHeaderSub = "X-Auth-Subject"
	cfg.Security.RequestIDHeader = "X-Request-Id"

	handler := authContextMiddleware(cfg, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	req := httptest.NewRequest(http.MethodPost, "/v1/admin/excursions/id/moderation/approve", nil)
	req.Header.Set("X-User-Id", "user-1")
	req.Header.Set("X-Auth-Subject", "subject-1")
	req.Header.Set("X-User-Roles", "ADMIN")
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusUnauthorized)
	}
}

func TestTrustedAuthHeadersAcceptedWithInternalServiceToken(t *testing.T) {
	cfg := &config.Config{}
	cfg.Security.InternalServiceToken = "internal-secret"
	cfg.Security.RequireAuthenticatedWrites = true
	cfg.Security.TrustedGatewayHeaderUserID = "X-User-Id"
	cfg.Security.TrustedGatewayHeaderRoles = "X-User-Roles"
	cfg.Security.TrustedGatewayHeaderSub = "X-Auth-Subject"
	cfg.Security.RequestIDHeader = "X-Request-Id"

	handler := authContextMiddleware(cfg, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := UserIDFromContext(r.Context()); got != "user-1" {
			t.Fatalf("user id = %q, want user-1", got)
		}
		if got := SubjectFromContext(r.Context()); got != "subject-1" {
			t.Fatalf("subject = %q, want subject-1", got)
		}
		w.WriteHeader(http.StatusNoContent)
	}))

	req := httptest.NewRequest(http.MethodPost, "/v1/admin/excursions/id/moderation/approve", nil)
	req.Header.Set("X-User-Id", "user-1")
	req.Header.Set("X-Auth-Subject", "subject-1")
	req.Header.Set("X-User-Roles", "ADMIN")
	req.Header.Set("X-Internal-Service-Token", "internal-secret")
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusNoContent)
	}
}
