package http

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/config"
)

func TestServerHandlerRegistersAttractionRoutesWithoutConflict(t *testing.T) {
	t.Parallel()

	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer returned error: %v", err)
	}

	cfg := &config.Config{
		Security: config.SecurityConfig{
			SessionCookieName: "session",
			CSRFCookieName:    "csrf",
			RequestIDHeader:   "X-Request-Id",
		},
	}
	server := NewServer(cfg, renderer, nil, nil, nil, nil, nil, nil, nil)

	if handler := server.Handler(); handler == nil {
		t.Fatal("Handler returned nil")
	}
}

func TestAttractionMediaURLUsesDedicatedRoute(t *testing.T) {
	t.Parallel()

	fileID := uuid.New()
	got := string(attractionMediaURL(fileID))
	want := "/admin/attraction-media/" + fileID.String()
	if got != want {
		t.Fatalf("attractionMediaURL() = %q, want %q", got, want)
	}
}

func TestSecurityHeadersAllowTrustedWikimediaAttractionImages(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodGet, "/admin/attractions/id/edit", nil)
	recorder := httptest.NewRecorder()
	handler := securityHeadersMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	handler.ServeHTTP(recorder, request)

	csp := recorder.Header().Get("Content-Security-Policy")
	for _, expected := range []string{
		"img-src",
		"blob:",
		"https://upload.wikimedia.org",
		"https://commons.wikimedia.org",
	} {
		if !strings.Contains(csp, expected) {
			t.Fatalf("Content-Security-Policy = %q, want trusted Wikimedia image source %q", csp, expected)
		}
	}
}

func TestLoginErrorResponseSeparatesAuthenticationAndServerErrors(t *testing.T) {
	t.Parallel()

	status, key := loginErrorResponse(app.ErrInvalidCredentials)
	if status != http.StatusUnauthorized || key != "error.invalidCredentials" {
		t.Fatalf("invalid credentials response = (%d, %q), want (%d, %q)", status, key, http.StatusUnauthorized, "error.invalidCredentials")
	}

	status, key = loginErrorResponse(errors.New("postgres is unavailable"))
	if status != http.StatusInternalServerError || key != "error.generic" {
		t.Fatalf("internal login error response = (%d, %q), want (%d, %q)", status, key, http.StatusInternalServerError, "error.generic")
	}
}
