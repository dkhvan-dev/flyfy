package http

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

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

func TestAuthMiddlewareFailsClosedForSavedTokenWithoutValidSessionID(t *testing.T) {
	tests := map[string]string{
		"missing":  "",
		"invalid":  "legacy-session",
		"nil UUID": "00000000-0000-0000-0000-000000000000",
	}

	for name, sessionID := range tests {
		t.Run(name, func(t *testing.T) {
			verifier := &fakeTokenVerifier{claims: &app.TokenClaims{
				Subject:   "auth-subject-1",
				UserID:    "user-1",
				SessionID: sessionID,
			}}
			downstreamCalled := false
			handler := authMiddleware(&config.Config{}, verifier, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				downstreamCalled = true
				w.WriteHeader(http.StatusNoContent)
			}))

			policy := matchRoutePolicyForMethod(http.MethodGet, "/api/v1/users/me/saved-items", "/api/v1")
			if policy == nil {
				t.Fatal("expected Saved route policy")
			}
			req := httptest.NewRequest(http.MethodGet, "/api/v1/users/me/saved-items", nil)
			req.Header.Set("Authorization", "Bearer access-token")
			req = req.WithContext(routeContext(req.Context(), policy))
			rr := httptest.NewRecorder()

			handler.ServeHTTP(rr, req)

			if rr.Code != http.StatusUnauthorized {
				t.Fatalf("status = %d, want %d", rr.Code, http.StatusUnauthorized)
			}
			if downstreamCalled {
				t.Fatal("downstream was called for Saved token without a valid session ID")
			}
			if !strings.Contains(rr.Body.String(), `"code":"gateway.invalid_access_token"`) {
				t.Fatalf("response = %s, want neutral invalid access token envelope", rr.Body.String())
			}
		})
	}
}

func TestAuthMiddlewareDoesNotRequireSessionIDForUnrelatedLegacyRoute(t *testing.T) {
	verifier := &fakeTokenVerifier{claims: &app.TokenClaims{
		Subject: "auth-subject-1",
		UserID:  "user-1",
	}}
	downstreamCalled := false
	handler := authMiddleware(&config.Config{}, verifier, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		downstreamCalled = true
		w.WriteHeader(http.StatusNoContent)
	}))

	policy := &RoutePolicy{Name: "users", AuthMode: RouteAuthAuthenticated}
	req := httptest.NewRequest(http.MethodGet, "/api/v1/users/me", nil)
	req.Header.Set("Authorization", "Bearer legacy-access-token")
	req = req.WithContext(routeContext(req.Context(), policy))
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent || !downstreamCalled {
		t.Fatalf("legacy route status = %d, downstream called = %t", rr.Code, downstreamCalled)
	}
}

func TestAuthMiddlewareDoesNotLogSavedClaims(t *testing.T) {
	var output bytes.Buffer
	previousLogger := log.Logger
	log.Logger = zerolog.New(&output)
	t.Cleanup(func() { log.Logger = previousLogger })

	const (
		subject   = "private-subject-456"
		sessionID = "c51500f3-f6c8-4d54-b9b8-ef6db7fc74aa"
	)
	verifier := &fakeTokenVerifier{claims: &app.TokenClaims{
		Subject:   subject,
		UserID:    "user-1",
		SessionID: sessionID,
	}}
	handler := authMiddleware(&config.Config{}, verifier, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	policy := matchRoutePolicyForMethod(http.MethodGet, "/api/v1/users/me/saved-items", "/api/v1")
	if policy == nil {
		t.Fatal("expected Saved route policy")
	}
	req := httptest.NewRequest(http.MethodGet, "/api/v1/users/me/saved-items", nil)
	req.Header.Set("Authorization", "Bearer access-token")
	req = req.WithContext(routeContext(req.Context(), policy))
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusNoContent)
	}
	for _, secret := range []string{subject, sessionID} {
		if strings.Contains(output.String(), secret) {
			t.Fatalf("Saved auth log leaked %q: %s", secret, output.String())
		}
	}
}

func TestRequestIDMiddlewareAcceptsOnlyCanonicalNonZeroUUID(t *testing.T) {
	const canonicalRequestID = "11111111-1111-4111-8111-111111111111"
	tests := map[string]struct {
		input        string
		wantPreserve bool
	}{
		"canonical UUID": {input: canonicalRequestID, wantPreserve: true},
		"empty":          {},
		"personal data":  {input: "owner-email@example.com"},
		"nil UUID":       {input: "00000000-0000-0000-0000-000000000000"},
		"uppercase UUID": {input: "11111111-1111-4111-8111-11111111111A"},
	}

	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			var downstreamRequestID string
			handler := requestIDMiddleware(&config.Config{}, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				downstreamRequestID = RequestIDFromContext(r.Context())
				w.WriteHeader(http.StatusNoContent)
			}))
			request := httptest.NewRequest(http.MethodGet, "/health", nil)
			request.Header.Set("X-Request-Id", test.input)
			recorder := httptest.NewRecorder()

			handler.ServeHTTP(recorder, request)

			if recorder.Code != http.StatusNoContent {
				t.Fatalf("status = %d, want %d", recorder.Code, http.StatusNoContent)
			}
			responseRequestID := recorder.Header().Get("X-Request-Id")
			if downstreamRequestID == "" || responseRequestID != downstreamRequestID {
				t.Fatalf("response request ID = %q, context request ID = %q", responseRequestID, downstreamRequestID)
			}
			parsed, err := uuid.Parse(responseRequestID)
			if err != nil || parsed == uuid.Nil || parsed.String() != responseRequestID {
				t.Fatalf("request ID = %q, want canonical non-zero UUID", responseRequestID)
			}
			if test.wantPreserve && responseRequestID != test.input {
				t.Fatalf("request ID = %q, want preserved %q", responseRequestID, test.input)
			}
			if !test.wantPreserve && test.input != "" && responseRequestID == test.input {
				t.Fatalf("untrusted request ID %q was preserved", test.input)
			}
		})
	}
}

func TestRequestBodyLimitRejectsSavedPayloadBeforeDownstream(t *testing.T) {
	downstreamCalled := false
	handler := requestBodyLimitMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		downstreamCalled = true
		w.WriteHeader(http.StatusNoContent)
	}))

	policy := &RoutePolicy{
		Name:                "saved-write",
		SavedPersonal:       true,
		MaxRequestBodyBytes: 4,
	}
	req := httptest.NewRequest(http.MethodPost, "/api/v1/users/me/saved-collections", strings.NewReader("12345"))
	req.ContentLength = -1
	req = req.WithContext(routeContext(req.Context(), policy))
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusRequestEntityTooLarge {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusRequestEntityTooLarge)
	}
	if downstreamCalled {
		t.Fatal("downstream was called before oversized body rejection")
	}
}

func TestSavedRequestDeadlineMiddlewareDoesNotAffectUnrelatedRoutes(t *testing.T) {
	cfg := &config.Config{}
	cfg.SavedService.RequestTimeout = time.Second

	tests := map[string]struct {
		policy       *RoutePolicy
		wantDeadline bool
	}{
		"Saved route": {
			policy:       &RoutePolicy{Name: "saved-read", SavedPersonal: true},
			wantDeadline: true,
		},
		"legacy route": {
			policy:       &RoutePolicy{Name: "users"},
			wantDeadline: false,
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			var gotDeadline bool
			handler := savedRequestDeadlineMiddleware(cfg, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				_, gotDeadline = r.Context().Deadline()
				w.WriteHeader(http.StatusNoContent)
			}))
			req := httptest.NewRequest(http.MethodGet, "/api/v1/test", nil)
			req = req.WithContext(routeContext(req.Context(), tc.policy))
			rr := httptest.NewRecorder()

			handler.ServeHTTP(rr, req)

			if gotDeadline != tc.wantDeadline {
				t.Fatalf("deadline present = %t, want %t", gotDeadline, tc.wantDeadline)
			}
		})
	}
}

func TestSavedAccessLogUsesRouteTemplateAndOmitsPersonalValues(t *testing.T) {
	var output bytes.Buffer
	previousLogger := log.Logger
	log.Logger = zerolog.New(&output)
	t.Cleanup(func() { log.Logger = previousLogger })

	const (
		entityID = "private-activity-123"
		subject  = "private-subject-456"
		query    = "cursor=private-cursor-789"
	)
	path := "/api/v1/users/me/saved-items/activity/" + entityID
	policy := matchRoutePolicyForMethod(http.MethodPut, path, "/api/v1")
	if policy == nil {
		t.Fatal("expected Saved route policy")
	}

	handler := logMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	req := httptest.NewRequest(http.MethodPut, path+"?"+query, nil)
	ctx := routeContext(req.Context(), policy)
	ctx = context.WithValue(ctx, contextKeyClaims, &app.TokenClaims{Subject: subject})
	req = req.WithContext(ctx)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	logged := output.String()
	for _, secret := range []string{entityID, subject, query, "private-cursor-789"} {
		if strings.Contains(logged, secret) {
			t.Fatalf("Saved access log leaked %q: %s", secret, logged)
		}
	}
	if !strings.Contains(logged, policy.LogPathTemplate) {
		t.Fatalf("Saved access log = %s, want route template %q", logged, policy.LogPathTemplate)
	}
}

func TestUnsupportedSavedLogPathUsesBoundedNamespaceTemplate(t *testing.T) {
	req := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/users/me/saved-operations/53d73301-23ea-4503-b3e0-91bfc9d5d9e2/reconcile?cursor=secret",
		nil,
	)
	if got := requestLogPath(req); got != "/users/me/saved-operations/{redacted}" {
		t.Fatalf("log path = %q, want bounded Saved namespace template", got)
	}
}

func publicRouteContext(ctx context.Context) context.Context {
	ctx = context.WithValue(ctx, contextKeyPolicy, &RoutePolicy{
		Name:     "content-feed",
		AuthMode: RouteAuthPublic,
	})
	return context.WithValue(ctx, contextKeyRouteName, "content-feed")
}

func routeContext(ctx context.Context, policy *RoutePolicy) context.Context {
	ctx = context.WithValue(ctx, contextKeyPolicy, policy)
	return context.WithValue(ctx, contextKeyRouteName, policy.Name)
}
