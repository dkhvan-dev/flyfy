package http

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/pkg/platformpolicy"
	"kz/inflap/backend/services/api-gateway/internal/app"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

type decisionSourceFunc func(context.Context) (platformpolicy.Decision, error)

func (fn decisionSourceFunc) FetchDecision(ctx context.Context) (platformpolicy.Decision, error) {
	return fn(ctx)
}

type countingPlatformPolicyGuard struct {
	delegate platformPersonalDataGuard
	calls    atomic.Int64
}

func (guard *countingPlatformPolicyGuard) Guard(ctx context.Context) (platformpolicy.Grant, error) {
	guard.calls.Add(1)
	return guard.delegate.Guard(ctx)
}

func TestPlatformPolicyClientIsOnDemandAuthenticatedAndCoalesced(t *testing.T) {
	const internalToken = "switches-policy-secret"
	var calls atomic.Int64
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		calls.Add(1)
		if r.URL.Scheme != "https" || r.URL.Host != "switches-service.internal:9443" {
			t.Errorf("policy origin = %s://%s", r.URL.Scheme, r.URL.Host)
		}
		if r.Method != http.MethodGet || r.URL.Path != platformpolicy.EndpointPath || r.URL.RawQuery != "" {
			t.Errorf("policy request = %s %s", r.Method, r.URL.RequestURI())
		}
		if got := r.Header.Get(platformpolicy.HeaderInternalServiceToken); got != internalToken {
			t.Errorf("internal policy token = %q", got)
		}
		if got := r.Header.Get(platformpolicy.HeaderAuthorization); got != "" {
			t.Errorf("unexpected Authorization header = %q", got)
		}
		if r.Body != nil {
			body, err := io.ReadAll(r.Body)
			if err != nil {
				t.Errorf("read policy request body: %v", err)
			}
			if len(body) != 0 {
				t.Errorf("policy request body = %q, want empty", body)
			}
		}
		time.Sleep(20 * time.Millisecond)
		now := time.Now().UTC()
		body, err := json.Marshal(platformpolicy.Decision{
			Revision:   7,
			State:      platformpolicy.StateAvailable,
			IssuedAt:   now.Add(-time.Second),
			ValidUntil: now.Add(10 * time.Second),
		})
		if err != nil {
			t.Errorf("marshal policy decision: %v", err)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(bytes.NewReader(body)),
			Request:    r,
		}, nil
	})

	cfg := testGatewayConfig()
	cfg.PlatformPolicy = config.PlatformPolicyConfig{
		BaseURL:              "https://switches-service.internal:9443",
		InternalServiceToken: internalToken,
		HTTPTimeout:          500 * time.Millisecond,
		RefreshTimeout:       time.Second,
		MaxResponseBytes:     4096,
	}
	checker, err := newPlatformPersonalDataGuardWithTransport(cfg, transport)
	if err != nil {
		t.Fatalf("newPlatformPersonalDataGuardWithTransport returned error: %v", err)
	}
	if got := calls.Load(); got != 0 {
		t.Fatalf("policy fetches during construction = %d, want on-demand zero", got)
	}

	const parallelGuards = 24
	start := make(chan struct{})
	errs := make(chan error, parallelGuards)
	var wait sync.WaitGroup
	for range parallelGuards {
		wait.Add(1)
		go func() {
			defer wait.Done()
			<-start
			_, guardErr := checker.Guard(context.Background())
			errs <- guardErr
		}()
	}
	close(start)
	wait.Wait()
	close(errs)
	for guardErr := range errs {
		if guardErr != nil {
			t.Fatalf("coalesced Guard returned error: %v", guardErr)
		}
	}
	if got := calls.Load(); got != 1 {
		t.Fatalf("coalesced policy fetches = %d, want 1", got)
	}
}

func TestMalformedPlatformPolicyHTTPResponseFailsClosedAtGateway(t *testing.T) {
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(strings.NewReader(`{"revision":1,"state":"AVAILABLE","unexpected":true}`)),
			Request:    r,
		}, nil
	})
	cfg := testGatewayConfig()
	cfg.PlatformPolicy = config.PlatformPolicyConfig{
		BaseURL:              "https://switches-service.internal:9443",
		InternalServiceToken: "policy-secret",
		HTTPTimeout:          100 * time.Millisecond,
		RefreshTimeout:       200 * time.Millisecond,
		MaxResponseBytes:     4096,
	}
	checker, err := newPlatformPersonalDataGuardWithTransport(cfg, transport)
	if err != nil {
		t.Fatalf("newPlatformPersonalDataGuardWithTransport returned error: %v", err)
	}
	var downstreamCalls atomic.Int64
	handler := &ProxyHandler{
		cfg:                 cfg,
		savedProxy:          testSavedProxy(t, &downstreamCalls, nil),
		platformPolicyGuard: checker,
	}
	path := "/api/v1/users/me/saved-items/capabilities"
	policy := matchRoutePolicyForMethod(http.MethodGet, path, "/api/v1")
	req := httptest.NewRequest(http.MethodGet, path, nil)
	ctx := routeContext(req.Context(), policy)
	ctx = context.WithValue(ctx, contextKeyRequestID, "request-malformed-http")
	req = req.WithContext(ctx)
	rr := httptest.NewRecorder()

	handler.Dispatch(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusServiceUnavailable, rr.Body.String())
	}
	assertSavedPolicyEnvelope(
		t,
		rr,
		savedPolicyCodeTemporarilyUnavailable,
		true,
		"request-malformed-http",
	)
	if downstreamCalls.Load() != 0 {
		t.Fatalf("Saved downstream calls = %d, want 0", downstreamCalls.Load())
	}
}

func TestEveryExactSavedRouteIsPolicyGuardedBeforeDispatch(t *testing.T) {
	const operationID = "53d73301-23ea-4503-b3e0-91bfc9d5d9e2"
	const collectionID = "17882988-667b-42e6-831c-9e79bbf52075"
	tests := []struct {
		method string
		path   string
	}{
		{http.MethodGet, "/api/v1/users/me/saved-items"},
		{http.MethodPost, "/api/v1/users/me/saved-items/query"},
		{http.MethodPost, "/api/v1/users/me/saved-items/status:batch"},
		{http.MethodGet, "/api/v1/users/me/saved-items/capabilities"},
		{http.MethodPut, "/api/v1/users/me/saved-items/activity/activity-123"},
		{http.MethodDelete, "/api/v1/users/me/saved-items/activity/activity-123"},
		{http.MethodGet, "/api/v1/users/me/saved-items/activity/activity-123/collections"},
		{http.MethodPut, "/api/v1/users/me/saved-items/activity/activity-123/collections"},
		{http.MethodGet, "/api/v1/users/me/saved-operations/" + operationID},
		{http.MethodPost, "/api/v1/users/me/saved-collections"},
		{http.MethodGet, "/api/v1/users/me/saved-collections"},
		{http.MethodGet, "/api/v1/users/me/saved-collections/" + collectionID},
		{http.MethodPatch, "/api/v1/users/me/saved-collections/" + collectionID},
		{http.MethodDelete, "/api/v1/users/me/saved-collections/" + collectionID},
	}

	guard := &countingPlatformPolicyGuard{delegate: mustPolicyGuard(t, platformpolicy.Decision{
		Revision:   9,
		State:      platformpolicy.StateLocked,
		IssuedAt:   time.Now().UTC().Add(-time.Second),
		ValidUntil: time.Now().UTC().Add(10 * time.Second),
	}, nil)}
	var downstreamCalls atomic.Int64
	handler := &ProxyHandler{
		cfg:                 testGatewayConfig(),
		savedProxy:          testSavedProxy(t, &downstreamCalls, nil),
		platformPolicyGuard: guard,
	}

	for _, tc := range tests {
		t.Run(tc.method+" "+tc.path, func(t *testing.T) {
			policy := matchRoutePolicyForMethod(tc.method, tc.path, "/api/v1")
			if policy == nil || !policy.SavedPersonal {
				t.Fatalf("route policy = %+v, want Saved personal policy", policy)
			}
			req := httptest.NewRequest(tc.method, tc.path, nil)
			ctx := routeContext(req.Context(), policy)
			ctx = context.WithValue(ctx, contextKeyRequestID, "request-saved-matrix")
			req = req.WithContext(ctx)
			rr := httptest.NewRecorder()

			handler.Dispatch(rr, req)

			if rr.Code != http.StatusForbidden {
				t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusForbidden, rr.Body.String())
			}
			assertSavedPolicyEnvelope(t, rr, platformpolicy.ExternalDenialCode, false, "request-saved-matrix")
		})
	}
	if got := guard.calls.Load(); got != int64(len(tests)) {
		t.Fatalf("Guard calls = %d, want %d", got, len(tests))
	}
	if got := downstreamCalls.Load(); got != 0 {
		t.Fatalf("Saved downstream calls = %d, want 0", got)
	}
}

func TestPlatformPolicyAvailableDispatchesAndTrustedHeadersRemainAuthoritative(t *testing.T) {
	guard := &countingPlatformPolicyGuard{delegate: mustAvailablePlatformPolicyGuard(t)}
	var downstreamCalls atomic.Int64
	var sessionHeader, subjectHeader, userHeader, rolesHeader, requestIDHeader, internalTokenHeader string
	proxy := testSavedProxy(t, &downstreamCalls, func(r *http.Request) {
		sessionHeader = r.Header.Get(savedSessionGenerationHeader)
		subjectHeader = r.Header.Get("X-Auth-Subject")
		userHeader = r.Header.Get("X-User-Id")
		rolesHeader = r.Header.Get("X-User-Roles")
		requestIDHeader = r.Header.Get("X-Request-Id")
		internalTokenHeader = r.Header.Get("X-Internal-Service-Token")
	})
	handler := &ProxyHandler{
		cfg:                 testGatewayConfig(),
		savedProxy:          proxy,
		platformPolicyGuard: guard,
	}

	path := "/api/v1/users/me/saved-items/activity/activity-123"
	policy := matchRoutePolicyForMethod(http.MethodPut, path, "/api/v1")
	req := httptest.NewRequest(http.MethodPut, path, nil)
	req.Header.Set(savedSessionGenerationHeader, "attacker-session")
	req.Header.Set("X-Auth-Subject", "attacker-subject")
	req.Header.Set("X-User-Id", "attacker-user")
	req.Header.Set("X-User-Roles", "ADMIN")
	req.Header.Set("X-Request-Id", "attacker-request")
	req.Header.Set("X-Internal-Service-Token", "attacker-token")
	ctx := routeContext(req.Context(), policy)
	ctx = context.WithValue(ctx, contextKeyRequestID, "request-available")
	ctx = context.WithValue(ctx, contextKeyClaims, &app.TokenClaims{
		Subject:   "auth-subject",
		UserID:    "domain-user",
		Roles:     []string{"USER"},
		SessionID: "C51500F3-F6C8-4D54-B9B8-EF6DB7FC74AA",
	})
	req = req.WithContext(ctx)
	rr := httptest.NewRecorder()

	handler.Dispatch(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusNoContent, rr.Body.String())
	}
	if guard.calls.Load() != 1 || downstreamCalls.Load() != 1 {
		t.Fatalf("guard calls = %d, downstream calls = %d", guard.calls.Load(), downstreamCalls.Load())
	}
	if sessionHeader != "c51500f3-f6c8-4d54-b9b8-ef6db7fc74aa" ||
		subjectHeader != "auth-subject" || userHeader != "domain-user" ||
		rolesHeader != "USER" || requestIDHeader != "request-available" {
		t.Fatalf(
			"trusted headers = session %q subject %q user %q roles %q request %q",
			sessionHeader,
			subjectHeader,
			userHeader,
			rolesHeader,
			requestIDHeader,
		)
	}
	if internalTokenHeader != "" {
		t.Fatalf("external internal-service token reached Saved downstream: %q", internalTokenHeader)
	}
}

func TestPlatformPolicyFailuresUseBoundedSavedContractAndNeverDispatch(t *testing.T) {
	now := time.Now().UTC()
	tests := map[string]struct {
		decision  platformpolicy.Decision
		sourceErr error
		status    int
		code      string
		retryable bool
	}{
		"explicit locked": {
			decision: platformpolicy.Decision{
				Revision: 11, State: platformpolicy.StateLocked,
				IssuedAt: now.Add(-time.Second), ValidUntil: now.Add(10 * time.Second),
			},
			status: http.StatusForbidden, code: platformpolicy.ExternalDenialCode,
		},
		"transport unavailable": {
			sourceErr: errors.New("private switches transport details"),
			status:    http.StatusServiceUnavailable,
			code:      savedPolicyCodeDependencyUnavailable,
			retryable: true,
		},
		"stale decision": {
			decision: platformpolicy.Decision{
				Revision: 12, State: platformpolicy.StateAvailable,
				IssuedAt: now.Add(-3 * time.Second), ValidUntil: now.Add(-time.Second),
			},
			status: http.StatusServiceUnavailable, code: savedPolicyCodeTemporarilyUnavailable, retryable: true,
		},
		"malformed decision": {
			decision: platformpolicy.Decision{
				State:    platformpolicy.StateAvailable,
				IssuedAt: now.Add(-time.Second), ValidUntil: now.Add(10 * time.Second),
			},
			status: http.StatusServiceUnavailable, code: savedPolicyCodeTemporarilyUnavailable, retryable: true,
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			var downstreamCalls atomic.Int64
			handler := &ProxyHandler{
				cfg:                 testGatewayConfig(),
				savedProxy:          testSavedProxy(t, &downstreamCalls, nil),
				platformPolicyGuard: mustPolicyGuard(t, tc.decision, tc.sourceErr),
			}
			path := "/api/v1/users/me/saved-items"
			policy := matchRoutePolicyForMethod(http.MethodGet, path, "/api/v1")
			req := httptest.NewRequest(http.MethodGet, path, nil)
			req.Header.Set("Accept-Language", "kk-KZ, en;q=0.8")
			ctx := routeContext(req.Context(), policy)
			ctx = context.WithValue(ctx, contextKeyRequestID, "request-policy-error")
			req = req.WithContext(ctx)
			rr := httptest.NewRecorder()

			handler.Dispatch(rr, req)

			if rr.Code != tc.status {
				t.Fatalf("status = %d, want %d; body=%s", rr.Code, tc.status, rr.Body.String())
			}
			assertSavedPolicyEnvelope(t, rr, tc.code, tc.retryable, "request-policy-error")
			if rr.Header().Get("Cache-Control") != "private, no-store" || rr.Header().Get("Pragma") != "no-cache" {
				t.Fatalf("private cache headers = %v", rr.Header())
			}
			if rr.Header().Get("Content-Language") != "kk" {
				t.Fatalf("Content-Language = %q, want kk", rr.Header().Get("Content-Language"))
			}
			if !headerContainsToken(rr.Header().Get("Vary"), "Authorization") ||
				!headerContainsToken(rr.Header().Get("Vary"), "Accept-Language") {
				t.Fatalf("Vary = %q", rr.Header().Get("Vary"))
			}
			if tc.retryable {
				if rr.Header().Get("Retry-After") != "1" {
					t.Fatalf("Retry-After = %q, want 1", rr.Header().Get("Retry-After"))
				}
			} else if rr.Header().Get("Retry-After") != "" {
				t.Fatalf("Retry-After = %q, want omitted", rr.Header().Get("Retry-After"))
			}
			if downstreamCalls.Load() != 0 {
				t.Fatalf("Saved downstream calls = %d, want 0", downstreamCalls.Load())
			}
		})
	}
}

func TestPlatformPolicyRollbackFailsClosedAfterPreviouslyAvailableDecision(t *testing.T) {
	t0 := time.Date(2026, 7, 16, 8, 0, 0, 0, time.UTC)
	clock := &mutablePolicyClock{now: t0}
	source := &sequencePolicySource{decisions: []platformpolicy.Decision{
		{
			Revision: 20, State: platformpolicy.StateAvailable,
			IssuedAt: t0, ValidUntil: t0.Add(time.Second),
		},
		{
			Revision: 19, State: platformpolicy.StateAvailable,
			IssuedAt: t0.Add(2 * time.Second), ValidUntil: t0.Add(12 * time.Second),
		},
	}}
	checker, err := platformpolicy.NewChecker(platformpolicy.CheckerConfig{
		Source: source, Clock: clock, RefreshTimeout: time.Second,
	})
	if err != nil {
		t.Fatalf("NewChecker returned error: %v", err)
	}
	if _, err := checker.Guard(context.Background()); err != nil {
		t.Fatalf("first Guard returned error: %v", err)
	}
	clock.Set(t0.Add(2 * time.Second))

	var downstreamCalls atomic.Int64
	handler := &ProxyHandler{
		cfg:                 testGatewayConfig(),
		savedProxy:          testSavedProxy(t, &downstreamCalls, nil),
		platformPolicyGuard: checker,
	}
	path := "/api/v1/users/me/saved-items/capabilities"
	policy := matchRoutePolicyForMethod(http.MethodGet, path, "/api/v1")
	req := httptest.NewRequest(http.MethodGet, path, nil)
	ctx := routeContext(req.Context(), policy)
	ctx = context.WithValue(ctx, contextKeyRequestID, "request-rollback")
	req = req.WithContext(ctx)
	rr := httptest.NewRecorder()

	handler.Dispatch(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusServiceUnavailable, rr.Body.String())
	}
	assertSavedPolicyEnvelope(t, rr, savedPolicyCodeTemporarilyUnavailable, true, "request-rollback")
	if downstreamCalls.Load() != 0 {
		t.Fatalf("downstream calls = %d, want 0", downstreamCalls.Load())
	}
}

func TestPlatformPolicyGuardRespectsCanceledSavedRequest(t *testing.T) {
	started := make(chan struct{})
	finished := make(chan struct{})
	var startOnce sync.Once
	var finishOnce sync.Once
	source := decisionSourceFunc(func(ctx context.Context) (platformpolicy.Decision, error) {
		startOnce.Do(func() { close(started) })
		<-ctx.Done()
		finishOnce.Do(func() { close(finished) })
		return platformpolicy.Decision{}, ctx.Err()
	})
	checker, err := platformpolicy.NewChecker(platformpolicy.CheckerConfig{
		Source: source, RefreshTimeout: 80 * time.Millisecond,
	})
	if err != nil {
		t.Fatalf("NewChecker returned error: %v", err)
	}
	var downstreamCalls atomic.Int64
	handler := &ProxyHandler{
		cfg:                 testGatewayConfig(),
		savedProxy:          testSavedProxy(t, &downstreamCalls, nil),
		platformPolicyGuard: checker,
	}
	path := "/api/v1/users/me/saved-items"
	policy := matchRoutePolicyForMethod(http.MethodGet, path, "/api/v1")
	baseCtx, cancel := context.WithCancel(context.Background())
	ctx := routeContext(baseCtx, policy)
	ctx = context.WithValue(ctx, contextKeyRequestID, "request-canceled")
	req := httptest.NewRequest(http.MethodGet, path, nil).WithContext(ctx)
	rr := httptest.NewRecorder()
	done := make(chan struct{})
	go func() {
		defer close(done)
		handler.Dispatch(rr, req)
	}()

	<-started
	cancel()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("canceled Saved request did not return")
	}
	select {
	case <-finished:
	case <-time.After(time.Second):
		t.Fatal("bounded policy refresh did not stop")
	}
	if rr.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d; body=%s", rr.Code, http.StatusServiceUnavailable, rr.Body.String())
	}
	if downstreamCalls.Load() != 0 {
		t.Fatalf("downstream calls = %d, want 0", downstreamCalls.Load())
	}
}

func TestPlatformPolicyFailureDoesNotLogSavedBodyPathQueryOrClaims(t *testing.T) {
	var output bytes.Buffer
	previousLogger := log.Logger
	log.Logger = zerolog.New(&output)
	t.Cleanup(func() { log.Logger = previousLogger })

	handler := &ProxyHandler{
		cfg: testGatewayConfig(),
		platformPolicyGuard: mustPolicyGuard(
			t,
			platformpolicy.Decision{},
			errors.New("source includes private-policy-host"),
		),
	}
	const collectionID = "17882988-667b-42e6-831c-9e79bbf52075"
	path := "/api/v1/users/me/saved-collections/" + collectionID
	policy := matchRoutePolicyForMethod(http.MethodPatch, path, "/api/v1")
	req := httptest.NewRequest(
		http.MethodPatch,
		path+"?cursor=private-cursor",
		strings.NewReader(`{"title":"private-body-title"}`),
	)
	ctx := routeContext(req.Context(), policy)
	ctx = context.WithValue(ctx, contextKeyRequestID, "request-private-log")
	ctx = context.WithValue(ctx, contextKeyClaims, &app.TokenClaims{
		Subject: "private-subject", UserID: "private-user",
	})
	req = req.WithContext(ctx)
	rr := httptest.NewRecorder()

	handler.Dispatch(rr, req)

	logged := output.String()
	for _, secret := range []string{
		collectionID,
		"private-cursor",
		"private-body-title",
		"private-subject",
		"private-user",
		"private-policy-host",
	} {
		if strings.Contains(logged, secret) {
			t.Fatalf("platform policy log leaked %q: %s", secret, logged)
		}
	}
}

func TestPlatformPolicyCORSAndScopedReadinessBehavior(t *testing.T) {
	guard := &countingPlatformPolicyGuard{delegate: mustPolicyGuard(
		t,
		platformpolicy.Decision{},
		errors.New("switches unavailable"),
	)}
	var downstreamCalls atomic.Int64
	cfg := testGatewayConfig()
	cfg.CORS.AllowedOrigins = "https://app.example"
	handler := &ProxyHandler{
		cfg:                 cfg,
		savedProxy:          testSavedProxy(t, &downstreamCalls, nil),
		platformPolicyGuard: guard,
	}
	wired := corsMiddleware(cfg,
		requestIDMiddleware(cfg,
			routePolicyMiddleware(cfg, http.HandlerFunc(handler.Dispatch)),
		),
	)

	readyRequest := httptest.NewRequest(http.MethodGet, "/ready", nil)
	readyRecorder := httptest.NewRecorder()
	handler.Ready(readyRecorder, readyRequest)
	if readyRecorder.Code != http.StatusOK {
		t.Fatalf("global readiness status = %d, want %d", readyRecorder.Code, http.StatusOK)
	}

	capabilitiesRequest := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/users/me/saved-items/capabilities",
		nil,
	)
	capabilitiesRequest.Header.Set("Origin", "https://app.example")
	capabilitiesRequest.Header.Set("Accept-Language", "en")
	capabilitiesRecorder := httptest.NewRecorder()
	wired.ServeHTTP(capabilitiesRecorder, capabilitiesRequest)
	if capabilitiesRecorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("Saved capabilities status = %d, want %d", capabilitiesRecorder.Code, http.StatusServiceUnavailable)
	}
	if capabilitiesRecorder.Header().Get("Access-Control-Allow-Origin") != "https://app.example" {
		t.Fatalf("Access-Control-Allow-Origin = %q", capabilitiesRecorder.Header().Get("Access-Control-Allow-Origin"))
	}
	for _, value := range []string{"Origin", "Authorization", "Accept-Language"} {
		if !headerContainsToken(capabilitiesRecorder.Header().Get("Vary"), value) {
			t.Fatalf("Vary = %q, missing %s", capabilitiesRecorder.Header().Get("Vary"), value)
		}
	}
	if capabilitiesRecorder.Header().Get("X-Request-Id") == "" {
		t.Fatal("Saved policy error omitted X-Request-Id")
	}

	preflight := httptest.NewRequest(http.MethodOptions, "/api/v1/users/me/saved-items/capabilities", nil)
	preflight.Header.Set("Origin", "https://app.example")
	preflightRecorder := httptest.NewRecorder()
	wired.ServeHTTP(preflightRecorder, preflight)
	if preflightRecorder.Code != http.StatusNoContent {
		t.Fatalf("preflight status = %d, want %d", preflightRecorder.Code, http.StatusNoContent)
	}
	if !strings.Contains(preflightRecorder.Header().Get("Access-Control-Allow-Headers"), "Saved-Source-Surface") {
		t.Fatalf("CORS allow headers = %q", preflightRecorder.Header().Get("Access-Control-Allow-Headers"))
	}
	for _, header := range []string{"X-Client-Platform", "X-App-Build"} {
		if !strings.Contains(preflightRecorder.Header().Get("Access-Control-Allow-Headers"), header) {
			t.Fatalf("CORS allow headers do not include %s: %q", header, preflightRecorder.Header().Get("Access-Control-Allow-Headers"))
		}
	}
	if guard.calls.Load() != 1 {
		t.Fatalf("policy Guard calls = %d, want only Saved capabilities GET", guard.calls.Load())
	}
	if downstreamCalls.Load() != 0 {
		t.Fatalf("Saved downstream calls = %d, want 0", downstreamCalls.Load())
	}
}

func TestPlatformPolicyDoesNotAffectNonSavedRoutes(t *testing.T) {
	guard := &countingPlatformPolicyGuard{delegate: mustPolicyGuard(
		t,
		platformpolicy.Decision{},
		errors.New("switches unavailable"),
	)}
	var downstreamCalls atomic.Int64
	adminProxy := testSavedProxy(t, &downstreamCalls, nil)
	handler := &ProxyHandler{
		cfg:                 testGatewayConfig(),
		adminPanelProxy:     adminProxy,
		platformPolicyGuard: guard,
	}
	req := httptest.NewRequest(http.MethodGet, "/admin/dashboard", nil)
	rr := httptest.NewRecorder()

	handler.Dispatch(rr, req)

	if rr.Code != http.StatusNoContent || downstreamCalls.Load() != 1 {
		t.Fatalf("non-Saved status = %d, downstream calls = %d", rr.Code, downstreamCalls.Load())
	}
	if guard.calls.Load() != 0 {
		t.Fatalf("policy Guard calls on non-Saved route = %d", guard.calls.Load())
	}
}

func mustAvailablePlatformPolicyGuard(t *testing.T) platformPersonalDataGuard {
	t.Helper()
	now := time.Now().UTC()
	return mustPolicyGuard(t, platformpolicy.Decision{
		Revision:   1,
		State:      platformpolicy.StateAvailable,
		IssuedAt:   now.Add(-time.Second),
		ValidUntil: now.Add(10 * time.Second),
	}, nil)
}

func mustPolicyGuard(
	t *testing.T,
	decision platformpolicy.Decision,
	sourceErr error,
) platformPersonalDataGuard {
	t.Helper()
	checker, err := platformpolicy.NewChecker(platformpolicy.CheckerConfig{
		Source: decisionSourceFunc(func(context.Context) (platformpolicy.Decision, error) {
			return decision, sourceErr
		}),
		RefreshTimeout: time.Second,
	})
	if err != nil {
		t.Fatalf("NewChecker returned error: %v", err)
	}
	return checker
}

func testGatewayConfig() *config.Config {
	cfg := &config.Config{}
	cfg.Routes.APIPrefix = "/api/v1"
	cfg.SavedService.RequestTimeout = time.Second
	cfg.Security.RequestIDHeader = "X-Request-Id"
	cfg.Security.TrustedHeaderSub = "X-Auth-Subject"
	cfg.Security.TrustedHeaderUser = "X-User-Id"
	cfg.Security.TrustedHeaderRoles = "X-User-Roles"
	return cfg
}

func testSavedProxy(
	t *testing.T,
	calls *atomic.Int64,
	inspect func(*http.Request),
) *httputil.ReverseProxy {
	t.Helper()
	proxy, err := newSingleHostProxy("saved-test", "http://saved-service.test", "", nil)
	if err != nil {
		t.Fatalf("newSingleHostProxy returned error: %v", err)
	}
	proxy.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		calls.Add(1)
		if inspect != nil {
			inspect(r)
		}
		return &http.Response{
			StatusCode: http.StatusNoContent,
			Header:     make(http.Header),
			Body:       io.NopCloser(strings.NewReader("")),
		}, nil
	})
	return proxy
}

func assertSavedPolicyEnvelope(
	t *testing.T,
	recorder *httptest.ResponseRecorder,
	wantCode string,
	wantRetryable bool,
	wantRequestID string,
) {
	t.Helper()
	var envelope savedPolicyErrorEnvelope
	decoder := json.NewDecoder(recorder.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&envelope); err != nil {
		t.Fatalf("decode Saved policy envelope: %v; body=%s", err, recorder.Body.String())
	}
	if envelope.Code != wantCode || envelope.Retryable != wantRetryable || envelope.RequestID != wantRequestID {
		t.Fatalf("Saved policy envelope = %+v", envelope)
	}
	if wantRetryable && envelope.RetryAfterMS != savedPolicyRetryAfterMilliseconds {
		t.Fatalf("retry_after_ms = %d, want %d", envelope.RetryAfterMS, savedPolicyRetryAfterMilliseconds)
	}
	if !wantRetryable && envelope.RetryAfterMS != 0 {
		t.Fatalf("retry_after_ms = %d, want omitted", envelope.RetryAfterMS)
	}
}

func headerContainsToken(raw, want string) bool {
	for _, value := range strings.Split(raw, ",") {
		if strings.EqualFold(strings.TrimSpace(value), want) {
			return true
		}
	}
	return false
}

type mutablePolicyClock struct {
	mu  sync.Mutex
	now time.Time
}

func (clock *mutablePolicyClock) Now() time.Time {
	clock.mu.Lock()
	defer clock.mu.Unlock()
	return clock.now
}

func (clock *mutablePolicyClock) Set(now time.Time) {
	clock.mu.Lock()
	defer clock.mu.Unlock()
	clock.now = now
}

type sequencePolicySource struct {
	mu        sync.Mutex
	decisions []platformpolicy.Decision
	next      int
}

func (source *sequencePolicySource) FetchDecision(context.Context) (platformpolicy.Decision, error) {
	source.mu.Lock()
	defer source.mu.Unlock()
	if source.next >= len(source.decisions) {
		return platformpolicy.Decision{}, errors.New("policy sequence exhausted")
	}
	decision := source.decisions[source.next]
	source.next++
	return decision, nil
}
