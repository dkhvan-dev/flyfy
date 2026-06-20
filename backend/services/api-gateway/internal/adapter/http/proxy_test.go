package http

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"strings"
	"testing"

	"kz/inflap/backend/services/api-gateway/internal/app"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

type fakeUserIDResolver struct {
	userID string
}

func (f fakeUserIDResolver) ResolveUserID(ctx context.Context, subject string, roles []string, requestID string) (string, error) {
	return f.userID, nil
}

func TestInjectTrustedHeadersResolvesAuthSubjectToDomainUserID(t *testing.T) {
	const authSubjectID = "9de27f69-da07-4e77-9456-d869a1dc31b1"
	const domainUserID = "f18f4045-a230-4d2a-8a17-e3183da52e68"

	cfg := &config.Config{}
	cfg.Security.RequestIDHeader = "X-Request-Id"
	cfg.Security.TrustedHeaderSub = "X-Auth-Subject"
	cfg.Security.TrustedHeaderUser = "X-User-Id"
	cfg.Security.TrustedHeaderRoles = "X-User-Roles"

	handler := &ProxyHandler{
		cfg:            cfg,
		userIDResolver: fakeUserIDResolver{userID: domainUserID},
	}

	ctx := context.WithValue(context.Background(), contextKeyClaims, &app.TokenClaims{
		Subject: authSubjectID,
		UserID:  authSubjectID,
		Roles:   []string{"GUIDE"},
	})
	ctx = context.WithValue(ctx, contextKeyRequestID, "request-1")

	req := httptest.NewRequest("POST", "/api/v1/me/excursions", nil).WithContext(ctx)
	if err := handler.injectTrustedHeaders(req, RouteAuthAuthenticated); err != nil {
		t.Fatalf("injectTrustedHeaders returned error: %v", err)
	}

	if got := req.Header.Get("X-Auth-Subject"); got != authSubjectID {
		t.Fatalf("X-Auth-Subject = %q, want %q", got, authSubjectID)
	}
	if got := req.Header.Get("X-User-Id"); got != domainUserID {
		t.Fatalf("X-User-Id = %q, want %q", got, domainUserID)
	}
	if got := req.Header.Get("X-User-Roles"); got != "GUIDE" {
		t.Fatalf("X-User-Roles = %q, want GUIDE", got)
	}
}

func TestDispatchProxiesAdminPanelRoute(t *testing.T) {
	cfg := &config.Config{}
	cfg.Routes.APIPrefix = "/api/v1"
	cfg.Security.RequestIDHeader = "X-Request-Id"
	cfg.Security.TrustedHeaderSub = "X-Auth-Subject"
	cfg.Security.TrustedHeaderUser = "X-User-Id"
	cfg.Security.TrustedHeaderRoles = "X-User-Roles"

	handler := &ProxyHandler{
		cfg: cfg,
		adminPanelProxy: &httputil.ReverseProxy{
			Director: func(r *http.Request) {},
			Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
				if r.URL.Path != "/admin/dashboard" {
					t.Fatalf("downstream path = %q, want /admin/dashboard", r.URL.Path)
				}
				return &http.Response{
					StatusCode: http.StatusNoContent,
					Header:     make(http.Header),
					Body:       io.NopCloser(strings.NewReader("")),
				}, nil
			}),
		},
	}

	req := httptest.NewRequest(http.MethodGet, "/admin/dashboard", nil)
	rr := httptest.NewRecorder()

	handler.Dispatch(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusNoContent)
	}
}

func TestSingleHostProxyOverwritesInternalServiceToken(t *testing.T) {
	proxy, err := newSingleHostProxy("test", "http://downstream.local", "gateway-secret")
	if err != nil {
		t.Fatalf("newSingleHostProxy returned error: %v", err)
	}

	req := httptest.NewRequest(http.MethodGet, "/v1/test", nil)
	req.Header.Set("X-Internal-Service-Token", "client-supplied")
	proxy.Director(req)

	if got := req.Header.Get("X-Internal-Service-Token"); got != "gateway-secret" {
		t.Fatalf("X-Internal-Service-Token = %q, want gateway-secret", got)
	}
}

func TestSingleHostProxyLocalizesDownstreamBusinessError(t *testing.T) {
	proxy, err := newSingleHostProxy("test", "http://downstream.local", "gateway-secret")
	if err != nil {
		t.Fatalf("newSingleHostProxy returned error: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/api/v1/posts", nil)
	req.Header.Set("Accept-Language", "kk,en;q=0.8")
	resp := &http.Response{
		StatusCode: http.StatusBadRequest,
		Header:     make(http.Header),
		Body:       io.NopCloser(strings.NewReader(`{"error":"invalid request body"}`)),
		Request:    req,
	}

	if err := proxy.ModifyResponse(resp); err != nil {
		t.Fatalf("ModifyResponse returned error: %v", err)
	}

	var payload errorResponse
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		t.Fatalf("decode rewritten body: %v", err)
	}
	if payload.Message != "Сұрауды тексеріп, қайталап көріңіз." {
		t.Fatalf("Message = %q, want localized Kazakh message", payload.Message)
	}
	if resp.Header.Get("Content-Length") == "" {
		t.Fatal("Content-Length was not refreshed")
	}
}

func TestSingleHostProxyPreservesDownstreamMaintenanceError(t *testing.T) {
	proxy, err := newSingleHostProxy("test", "http://downstream.local", "gateway-secret")
	if err != nil {
		t.Fatalf("newSingleHostProxy returned error: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/api/v1/activities/join?lang=ru", nil)
	resp := &http.Response{
		StatusCode: http.StatusServiceUnavailable,
		Header:     make(http.Header),
		Body: io.NopCloser(strings.NewReader(
			`{"error":"Technical maintenance","message":"temporary","code":"activity.technical_maintenance","kind":"maintenance"}`,
		)),
		Request: req,
	}

	if err := proxy.ModifyResponse(resp); err != nil {
		t.Fatalf("ModifyResponse returned error: %v", err)
	}

	var payload errorResponse
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		t.Fatalf("decode rewritten body: %v", err)
	}
	if payload.Kind != errorKindMaintenance {
		t.Fatalf("Kind = %q, want %q", payload.Kind, errorKindMaintenance)
	}
	if payload.Code != "activity.technical_maintenance" {
		t.Fatalf("Code = %q, want activity.technical_maintenance", payload.Code)
	}
	if payload.Message != "Сейчас проводятся технические работы. Попробуйте позже." {
		t.Fatalf("Message = %q, want localized maintenance message", payload.Message)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}
