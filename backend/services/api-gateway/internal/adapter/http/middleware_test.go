package http

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"kz/inflap/backend/services/api-gateway/internal/app"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

type fakeTokenVerifier struct {
	claims *app.TokenClaims
	err    error
	calls  int
}

func (f *fakeTokenVerifier) VerifyAccessToken(ctx context.Context, accessToken string) (*app.TokenClaims, error) {
	f.calls++
	if f.err != nil {
		return nil, f.err
	}
	return f.claims, nil
}

func TestAuthMiddlewareAttachesClaimsForValidOptionalPublicToken(t *testing.T) {
	verifier := &fakeTokenVerifier{
		claims: &app.TokenClaims{
			Subject: "auth-subject-1",
			UserID:  "user-1",
			Roles:   []string{"USER"},
		},
	}
	var downstreamClaims *app.TokenClaims
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		downstreamClaims = ClaimsFromContext(r.Context())
		w.WriteHeader(http.StatusNoContent)
	})
	handler := authMiddleware(&config.Config{}, verifier, next)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/feed", nil)
	req.Header.Set("Authorization", "Bearer access-token")
	req = req.WithContext(publicRouteContext(req.Context()))
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusNoContent)
	}
	if verifier.calls != 1 {
		t.Fatalf("VerifyAccessToken calls = %d, want 1", verifier.calls)
	}
	if downstreamClaims == nil {
		t.Fatal("expected downstream claims for valid optional token")
	}
	if downstreamClaims.UserID != "user-1" {
		t.Fatalf("downstream user id = %q, want user-1", downstreamClaims.UserID)
	}
}

func TestAuthMiddlewareIgnoresInvalidOptionalPublicToken(t *testing.T) {
	verifier := &fakeTokenVerifier{err: errors.New("invalid token")}
	var downstreamClaims *app.TokenClaims
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		downstreamClaims = ClaimsFromContext(r.Context())
		w.WriteHeader(http.StatusNoContent)
	})
	handler := authMiddleware(&config.Config{}, verifier, next)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/feed", nil)
	req.Header.Set("Authorization", "Bearer stale-token")
	req = req.WithContext(publicRouteContext(req.Context()))
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusNoContent)
	}
	if verifier.calls != 1 {
		t.Fatalf("VerifyAccessToken calls = %d, want 1", verifier.calls)
	}
	if downstreamClaims != nil {
		t.Fatalf("downstream claims = %+v, want nil", downstreamClaims)
	}
}

func publicRouteContext(ctx context.Context) context.Context {
	ctx = context.WithValue(ctx, contextKeyPolicy, &RoutePolicy{
		Name:     "content-feed",
		AuthMode: RouteAuthPublic,
	})
	return context.WithValue(ctx, contextKeyRouteName, "content-feed")
}
