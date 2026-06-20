package http

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestReadyReturnsServiceUnavailableWhenReadinessFails(t *testing.T) {
	handler := &Handler{
		readiness: func(context.Context) error {
			return errors.New("database is down")
		},
	}
	request := httptest.NewRequest(http.MethodGet, "/ready", nil)
	response := httptest.NewRecorder()

	handler.Ready(response, request)

	if response.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusServiceUnavailable)
	}
}

func TestLiveDoesNotCallReadinessDependency(t *testing.T) {
	called := false
	handler := &Handler{
		readiness: func(context.Context) error {
			called = true
			return nil
		},
	}
	request := httptest.NewRequest(http.MethodGet, "/live", nil)
	response := httptest.NewRecorder()

	handler.Live(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	if called {
		t.Fatal("liveness check must not call readiness dependency")
	}
}
