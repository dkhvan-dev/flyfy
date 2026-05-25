package http

import (
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/config"
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
	server := NewServer(cfg, renderer, nil, nil, nil, nil, nil)

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
