package http

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

type pingerStub struct {
	ping func(context.Context) error
}

func (p pingerStub) Ping(ctx context.Context) error {
	return p.ping(ctx)
}

func TestHealthDoesNotDependOnDatabase(t *testing.T) {
	handler := NewHealthHandler(nil, time.Second)
	recorder := httptest.NewRecorder()

	handler.Health(recorder, httptest.NewRequest(http.MethodGet, "/health", nil))

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}
	if got := recorder.Body.String(); got != "{\"status\":\"ok\"}\n" {
		t.Fatalf("body = %q", got)
	}
}

func TestReadyUsesBoundedDatabasePing(t *testing.T) {
	const timeout = 150 * time.Millisecond
	called := false
	handler := NewHealthHandler(pingerStub{ping: func(ctx context.Context) error {
		called = true
		deadline, ok := ctx.Deadline()
		if !ok {
			t.Fatal("Ping context has no deadline")
		}
		remaining := time.Until(deadline)
		if remaining <= 0 || remaining > timeout {
			t.Fatalf("Ping deadline remaining = %s, want (0, %s]", remaining, timeout)
		}
		return nil
	}}, timeout)
	recorder := httptest.NewRecorder()

	handler.Ready(recorder, httptest.NewRequest(http.MethodGet, "/ready", nil))

	if !called {
		t.Fatal("database Ping was not called")
	}
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}
}

func TestReadyDoesNotExposeDatabaseFailure(t *testing.T) {
	handler := NewHealthHandler(pingerStub{ping: func(context.Context) error {
		return errors.New("database credentials must stay private")
	}}, time.Second)
	recorder := httptest.NewRecorder()

	handler.Ready(recorder, httptest.NewRequest(http.MethodGet, "/ready", nil))

	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusServiceUnavailable)
	}
	if got := recorder.Body.String(); got != "{\"status\":\"not_ready\"}\n" {
		t.Fatalf("body = %q", got)
	}
}
