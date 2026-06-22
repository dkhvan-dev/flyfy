package http

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRequestObservabilityPropagatesRequestID(t *testing.T) {
	handler := RequestObservability(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := RequestIDFromContext(r.Context()); got != "request-123" {
			t.Fatalf("request id in context = %q, want request-123", got)
		}
		w.WriteHeader(http.StatusAccepted)
	}))

	req := httptest.NewRequest(http.MethodGet, "/v1/status", nil)
	req.Header.Set("X-Request-Id", "request-123")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusAccepted)
	}
	if got := rec.Header().Get("X-Request-Id"); got != "request-123" {
		t.Fatalf("response request id = %q, want request-123", got)
	}
}

func TestRequestObservabilityGeneratesMissingRequestID(t *testing.T) {
	handler := RequestObservability(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if RequestIDFromContext(r.Context()) == "" {
			t.Fatal("request id in context is empty")
		}
		w.WriteHeader(http.StatusNoContent)
	}))

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if got := rec.Header().Get("X-Request-Id"); got == "" {
		t.Fatal("response request id is empty")
	}
}
