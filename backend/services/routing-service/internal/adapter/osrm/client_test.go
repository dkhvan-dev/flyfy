package osrm

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kz/inflap/backend/services/routing-service/internal/app"
)

func TestStatusMarksOSRMReachableWhenHTTPServerResponds(t *testing.T) {
	var requestedPath string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestedPath = r.URL.Path
		w.WriteHeader(http.StatusBadRequest)
	}))
	defer server.Close()

	client, err := New(server.URL, time.Second)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	status := client.Status(context.Background())

	if requestedPath != "/" {
		t.Fatalf("path = %q, want /", requestedPath)
	}
	if status.Name != string(app.EngineOSRM) || !status.Reachable || status.Status != "ok" {
		t.Fatalf("status = %#v", status)
	}
}
