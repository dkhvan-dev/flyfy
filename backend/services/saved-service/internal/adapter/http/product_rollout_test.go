package http

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
)

type rolloutGateStub struct {
	decision productrollout.Decision
	err      error
	request  productrollout.Request
	calls    int
}

func (stub *rolloutGateStub) Evaluate(
	_ context.Context,
	request productrollout.Request,
) (productrollout.Decision, error) {
	stub.calls++
	stub.request = request
	return stub.decision, stub.err
}

func TestProductRolloutMiddlewareEvaluatesTrustedOwnerAndBoundedClientMetadata(t *testing.T) {
	t.Parallel()

	gate := &rolloutGateStub{decision: productrollout.Decision{SavedCore: true}}
	middleware, err := NewProductRolloutMiddleware(gate)
	if err != nil {
		t.Fatalf("NewProductRolloutMiddleware() error = %v", err)
	}
	var got productrollout.Decision
	var evaluated bool
	handler := middleware.Wrap(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		got, evaluated = ProductRolloutDecisionFromContext(request.Context())
		writer.WriteHeader(http.StatusNoContent)
	}))
	ownerID := uuid.MustParse("22222222-2222-4222-8222-222222222222")
	request := httptest.NewRequest(http.MethodGet, "/v1/users/me/saved-items", nil)
	request.Header.Set(HeaderClientPlatform, string(productrollout.PlatformAndroid))
	request.Header.Set(HeaderAppBuild, "42")
	request = request.WithContext(context.WithValue(request.Context(), principalContextKey{}, PersonalPrincipal{
		UserID: ownerID,
	}))
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent || !evaluated || !got.SavedCore || gate.calls != 1 {
		t.Fatalf("status=%d evaluated=%t decision=%#v calls=%d", recorder.Code, evaluated, got, gate.calls)
	}
	if gate.request.OwnerID != ownerID || gate.request.Platform != productrollout.PlatformAndroid || gate.request.Build != 42 {
		t.Fatalf("rollout request = %#v", gate.request)
	}
}

func TestProductRolloutMiddlewareFailsExpansionClosedWithoutBlockingRead(t *testing.T) {
	t.Parallel()

	gate := &rolloutGateStub{decision: productrollout.Decision{SavedCore: true}}
	middleware, err := NewProductRolloutMiddleware(gate)
	if err != nil {
		t.Fatalf("NewProductRolloutMiddleware() error = %v", err)
	}
	handler := middleware.Wrap(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		decision, evaluated := ProductRolloutDecisionFromContext(request.Context())
		if !evaluated || decision != (productrollout.Decision{}) {
			t.Fatalf("decision = %#v evaluated=%t", decision, evaluated)
		}
		writer.WriteHeader(http.StatusNoContent)
	}))
	request := httptest.NewRequest(http.MethodGet, "/v1/users/me/saved-items", nil)
	request.Header.Set(HeaderClientPlatform, "android\nowner@example.com")
	request.Header.Set(HeaderAppBuild, "not-a-build")
	request = request.WithContext(context.WithValue(request.Context(), principalContextKey{}, PersonalPrincipal{
		UserID: uuid.MustParse("22222222-2222-4222-8222-222222222222"),
	}))
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent || gate.calls != 0 {
		t.Fatalf("status=%d gate calls=%d", recorder.Code, gate.calls)
	}
}
