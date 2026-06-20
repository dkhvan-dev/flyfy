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
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestServerHandlerRegistersPlaceRoutesWithoutConflict(t *testing.T) {
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

func TestPlaceMediaURLUsesDedicatedRoute(t *testing.T) {
	t.Parallel()

	fileID := uuid.New()
	got := string(placeMediaURL(fileID))
	want := "/admin/place-media/" + fileID.String()
	if got != want {
		t.Fatalf("placeMediaURL() = %q, want %q", got, want)
	}
}

func TestPlaceMediaImageURLOptimizesWikimediaExternalPreviews(t *testing.T) {
	t.Parallel()

	cases := map[string]string{
		"https://commons.wikimedia.org/wiki/Special:FilePath/Toompea_Castle.jpg?width=1400":                                                                    "https://commons.wikimedia.org/wiki/Special:FilePath/Toompea_Castle.jpg?width=480",
		"https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Golden_Bridge_at_Ba_Na_Hills_20250718.jpg/3840px-Golden_Bridge_at_Ba_Na_Hills_20250718.jpg": "https://commons.wikimedia.org/wiki/Special:FilePath/Golden_Bridge_at_Ba_Na_Hills_20250718.jpg?width=480",
	}
	for externalURL, want := range cases {
		item := model.AdminPlaceMedia{ExternalURL: externalURL}
		if got := string(placeMediaImageURL(item)); got != want {
			t.Fatalf("placeMediaImageURL(%q) = %q, want %q", externalURL, got, want)
		}
	}
}

func TestPlaceMediaImageURLPrefersLocalFileRoute(t *testing.T) {
	t.Parallel()

	fileID := uuid.New()
	item := model.AdminPlaceMedia{
		FileID:      fileID,
		ExternalURL: "https://commons.wikimedia.org/wiki/Special:FilePath/Toompea_Castle.jpg?width=1400",
	}
	want := "/admin/place-media/" + fileID.String()
	if got := string(placeMediaImageURL(item)); got != want {
		t.Fatalf("placeMediaImageURL() = %q, want %q", got, want)
	}
}

func TestSecurityHeadersAllowTrustedWikimediaPlaceImages(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodGet, "/admin/places/id/edit", nil)
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

func TestSecurityHeadersAllowAdminMeetingMaps(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodGet, "/admin/moderation/activities/id", nil)
	recorder := httptest.NewRecorder()
	handler := securityHeadersMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	handler.ServeHTTP(recorder, request)

	csp := recorder.Header().Get("Content-Security-Policy")
	for _, expected := range []string{
		"script-src 'self'",
		"style-src 'self' 'unsafe-inline'",
		"connect-src 'self' https://tiles.openfreemap.org",
		"img-src 'self' data: blob: https://tiles.openfreemap.org",
		"font-src 'self' data: https://tiles.openfreemap.org",
		"worker-src 'self' blob:",
	} {
		if !strings.Contains(csp, expected) {
			t.Fatalf("Content-Security-Policy = %q, want admin meeting map directive %q", csp, expected)
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
