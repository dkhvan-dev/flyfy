package http

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
)

func TestPersonalRouterAuthenticatesBeforePolicyAndRoutes(t *testing.T) {
	t.Parallel()

	authorizer := &countingGatewayAuthorizer{}
	policy := &orderedPolicyGuard{}
	registrar := &stubPersonalRegistrar{}
	handler, err := NewPersonalRouter(authorizer, policy, registrar)
	if err != nil {
		t.Fatalf("NewPersonalRouter() error = %v", err)
	}
	request := httptest.NewRequest(http.MethodGet, "/v1/users/me/test", nil)
	request.Header.Set("Authorization", "Bearer gateway-service-jwt")
	request.Header.Set(HeaderAuthSubject, "11111111-1111-4111-8111-111111111111")
	request.Header.Set(HeaderUserID, "22222222-2222-4222-8222-222222222222")
	request.Header.Set(HeaderSessionGeneration, "33333333-3333-4333-8333-333333333333")
	request.Header.Set(HeaderRequestID, "request-123")
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusNoContent || authorizer.calls != 1 || policy.calls != 1 || registrar.calls != 1 {
		t.Fatalf("status=%d auth=%d policy=%d route=%d", recorder.Code, authorizer.calls, policy.calls, registrar.calls)
	}
}

func TestPersonalRouterDoesNotEvaluatePolicyForUnauthenticatedRequest(t *testing.T) {
	t.Parallel()

	authorizer := &countingGatewayAuthorizer{err: errors.New("invalid service token")}
	policy := &orderedPolicyGuard{}
	handler, err := NewPersonalRouter(authorizer, policy, &stubPersonalRegistrar{})
	if err != nil {
		t.Fatalf("NewPersonalRouter() error = %v", err)
	}
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/v1/users/me/test", nil))
	if recorder.Code != http.StatusUnauthorized || policy.calls != 0 {
		t.Fatalf("status=%d policy_calls=%d", recorder.Code, policy.calls)
	}
}

func TestPersonalRouterUsesPrivateNeutralFallback(t *testing.T) {
	t.Parallel()

	handler, err := NewPersonalRouter(&countingGatewayAuthorizer{}, &orderedPolicyGuard{}, &stubPersonalRegistrar{})
	if err != nil {
		t.Fatalf("NewPersonalRouter() error = %v", err)
	}
	request := httptest.NewRequest(http.MethodGet, "/v1/users/me/not-a-real-resource", nil)
	request.Header.Set("Authorization", "Bearer gateway-service-jwt")
	request.Header.Set(HeaderAuthSubject, "11111111-1111-4111-8111-111111111111")
	request.Header.Set(HeaderUserID, "22222222-2222-4222-8222-222222222222")
	request.Header.Set(HeaderSessionGeneration, "33333333-3333-4333-8333-333333333333")
	request.Header.Set(HeaderRequestID, "request-123")
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusNotFound || recorder.Header().Get("Cache-Control") != "private, no-store" {
		t.Fatalf("status=%d cache=%q body=%s", recorder.Code, recorder.Header().Get("Cache-Control"), recorder.Body.String())
	}
}

type orderedPolicyGuard struct{ calls int }

func (g *orderedPolicyGuard) Guard(context.Context) (saveditem.PolicyGrant, error) {
	g.calls++
	return saveditem.PolicyGrant{Revision: 1}, nil
}

type countingGatewayAuthorizer struct {
	err   error
	calls int
}

func (a *countingGatewayAuthorizer) AuthorizeGateway(context.Context, string) error {
	a.calls++
	return a.err
}

type stubPersonalRegistrar struct{ calls int }

func (r *stubPersonalRegistrar) Register(mux *http.ServeMux) error {
	mux.HandleFunc("GET /v1/users/me/test", func(w http.ResponseWriter, _ *http.Request) {
		r.calls++
		w.WriteHeader(http.StatusNoContent)
	})
	return nil
}

var _ PersonalRouteRegistrar = (*stubPersonalRegistrar)(nil)
