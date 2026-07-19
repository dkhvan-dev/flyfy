package http

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"
)

type gatewayAuthorizerStub struct {
	err        error
	lastHeader string
}

func (s *gatewayAuthorizerStub) AuthorizeGateway(_ context.Context, header string) error {
	s.lastHeader = header
	return s.err
}

func TestPersonalAuthRequiresGatewayBeforeTrustingHeaders(t *testing.T) {
	t.Parallel()

	authorizer := &gatewayAuthorizerStub{err: errors.New("forged caller")}
	middleware, err := NewPersonalAuthMiddleware(authorizer)
	if err != nil {
		t.Fatalf("NewPersonalAuthMiddleware() error = %v", err)
	}
	called := false
	handler := middleware.Wrap(http.HandlerFunc(func(http.ResponseWriter, *http.Request) { called = true }))
	request := validPersonalRequest()
	request.Header.Set("Authorization", "Bearer user-or-forged-token")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if called {
		t.Fatal("protected handler was called for an unauthorized service caller")
	}
	if recorder.Code != http.StatusUnauthorized || authorizer.lastHeader != "Bearer user-or-forged-token" {
		t.Fatalf("status/header = %d/%q", recorder.Code, authorizer.lastHeader)
	}
	if got := recorder.Header().Get("Cache-Control"); got != "private, no-store" {
		t.Fatalf("Cache-Control = %q", got)
	}
}

func TestPersonalAuthInjectsValidatedPrincipal(t *testing.T) {
	t.Parallel()

	authorizer := &gatewayAuthorizerStub{}
	middleware, err := NewPersonalAuthMiddleware(authorizer)
	if err != nil {
		t.Fatalf("NewPersonalAuthMiddleware() error = %v", err)
	}
	var got PersonalPrincipal
	handler := middleware.Wrap(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var ok bool
		got, ok = PersonalPrincipalFromContext(r.Context())
		if !ok {
			t.Fatal("principal missing from request context")
		}
		w.WriteHeader(http.StatusNoContent)
	}))
	request := validPersonalRequest()
	request.Header.Set("Authorization", "Bearer service-jwt")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent {
		t.Fatalf("status = %d", recorder.Code)
	}
	if got.Subject.String() != "00000000-0000-4000-8000-000000000003" || got.UserID.String() != "00000000-0000-4000-8000-000000000001" ||
		got.SessionGeneration.String() != "00000000-0000-4000-8000-000000000002" || got.RequestID != "request-42" {
		t.Fatalf("principal = %#v", got)
	}
}

func TestPersonalAuthRejectsMalformedSessionGeneration(t *testing.T) {
	t.Parallel()

	middleware, _ := NewPersonalAuthMiddleware(&gatewayAuthorizerStub{})
	request := validPersonalRequest()
	request.Header.Set("Authorization", "Bearer service-jwt")
	request.Header.Set(HeaderSessionGeneration, "missing-or-legacy-session")
	recorder := httptest.NewRecorder()

	middleware.Wrap(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("protected handler was called")
	})).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", recorder.Code)
	}
}

func TestPersonalAuthRejectsNonCanonicalSubject(t *testing.T) {
	t.Parallel()

	middleware, _ := NewPersonalAuthMiddleware(&gatewayAuthorizerStub{})
	request := validPersonalRequest()
	request.Header.Set("Authorization", "Bearer service-jwt")
	request.Header.Set(HeaderAuthSubject, "user-subject")
	recorder := httptest.NewRecorder()

	middleware.Wrap(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("protected handler was called")
	})).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", recorder.Code)
	}
}

func TestPersonalAuthRejectsControlCharacters(t *testing.T) {
	t.Parallel()

	header := make(http.Header)
	header.Set(HeaderAuthSubject, "subject\nforged")
	header.Set(HeaderUserID, uuid.NewString())
	header.Set(HeaderSessionGeneration, uuid.NewString())
	header.Set(HeaderRequestID, "request")

	if _, err := principalFromTrustedHeaders(header); err == nil {
		t.Fatal("principalFromTrustedHeaders() accepted a control character")
	}
}

func validPersonalRequest() *http.Request {
	request := httptest.NewRequest(http.MethodGet, "/v1/users/me/saved-items", nil)
	request.Header.Set(HeaderAuthSubject, "00000000-0000-4000-8000-000000000003")
	request.Header.Set(HeaderUserID, "00000000-0000-4000-8000-000000000001")
	request.Header.Set(HeaderSessionGeneration, "00000000-0000-4000-8000-000000000002")
	request.Header.Set(HeaderRequestID, "request-42")
	return request
}
