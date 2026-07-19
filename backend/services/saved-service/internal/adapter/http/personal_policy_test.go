package http

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestPersonalPolicyMiddlewareAllowsCurrentGrant(t *testing.T) {
	t.Parallel()

	guard := &stubPersonalPolicyGuard{grant: saveditem.PolicyGrant{Revision: 8}}
	middleware, err := NewPersonalPolicyMiddleware(guard)
	if err != nil {
		t.Fatalf("NewPersonalPolicyMiddleware() error = %v", err)
	}
	called := false
	handler := middleware.Wrap(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		called = true
		w.WriteHeader(http.StatusNoContent)
	}))
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, personalResponseTestRequest())
	if recorder.Code != http.StatusNoContent || !called || guard.calls != 1 {
		t.Fatalf("status=%d called=%t guard_calls=%d", recorder.Code, called, guard.calls)
	}
}

func TestPersonalPolicyMiddlewareMapsLockAndDependencyFailClosed(t *testing.T) {
	t.Parallel()

	for _, test := range []struct {
		name   string
		err    error
		status int
		code   string
	}{
		{name: "locked", err: domain.ErrPlatformPersonalDataLocked, status: http.StatusForbidden, code: string(domain.ErrorCodePlatformPersonalDataLocked)},
		{name: "unavailable", err: domain.ErrDependencyUnavailable, status: http.StatusServiceUnavailable, code: string(domain.ErrorCodeDependencyUnavailable)},
	} {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			middleware, err := NewPersonalPolicyMiddleware(&stubPersonalPolicyGuard{err: test.err})
			if err != nil {
				t.Fatalf("NewPersonalPolicyMiddleware() error = %v", err)
			}
			handler := middleware.Wrap(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
				t.Fatal("next handler was called")
			}))
			recorder := httptest.NewRecorder()
			handler.ServeHTTP(recorder, personalResponseTestRequest())
			if recorder.Code != test.status || !strings.Contains(recorder.Body.String(), test.code) {
				t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
			}
		})
	}
}

func TestPersonalPolicyMiddlewareRejectsZeroRevision(t *testing.T) {
	t.Parallel()

	middleware, err := NewPersonalPolicyMiddleware(&stubPersonalPolicyGuard{})
	if err != nil {
		t.Fatalf("NewPersonalPolicyMiddleware() error = %v", err)
	}
	recorder := httptest.NewRecorder()
	middleware.Wrap(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("next handler was called")
	})).ServeHTTP(recorder, personalResponseTestRequest())
	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d", recorder.Code)
	}
}

type stubPersonalPolicyGuard struct {
	grant saveditem.PolicyGrant
	err   error
	calls int
}

func (s *stubPersonalPolicyGuard) Guard(context.Context) (saveditem.PolicyGrant, error) {
	s.calls++
	return s.grant, s.err
}

var _ PersonalPolicyGuard = (*stubPersonalPolicyGuard)(nil)
