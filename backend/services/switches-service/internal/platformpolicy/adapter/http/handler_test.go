package http

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	nethttp "net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/switches-service/internal/platformpolicy/app"
)

func TestGetDecisionRequiresInternalTokenAndSetsNoStore(t *testing.T) {
	t.Parallel()

	handler := newTestHandler(&fakePolicyService{})
	request := httptest.NewRequest(nethttp.MethodGet, InternalDecisionPath, nil)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != nethttp.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", response.Code)
	}
	assertNoStore(t, response)
}

func TestGetDecisionRejectsDuplicateInternalTokenHeaders(t *testing.T) {
	t.Parallel()

	handler := newTestHandler(&fakePolicyService{decision: testDecision()})
	request := httptest.NewRequest(nethttp.MethodGet, InternalDecisionPath, nil)
	request.Header.Add("X-Internal-Service-Token", "internal-secret")
	request.Header.Add("X-Internal-Service-Token", "internal-secret")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != nethttp.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", response.Code)
	}
	assertNoStore(t, response)
}

func TestGetDecisionReturnsExactClosedContract(t *testing.T) {
	t.Parallel()

	issuedAt := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	service := &fakePolicyService{decision: app.Decision{
		Revision:   17,
		State:      app.StateAvailable,
		IssuedAt:   issuedAt,
		ValidUntil: issuedAt.Add(20 * time.Second),
	}}
	handler := newTestHandler(service)
	request := httptest.NewRequest(nethttp.MethodGet, InternalDecisionPath, nil)
	request.Header.Set("X-Internal-Service-Token", "internal-secret")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != nethttp.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	var payload map[string]any
	if err := json.Unmarshal(response.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(payload) != 4 || payload["revision"] != float64(17) || payload["state"] != "AVAILABLE" ||
		payload["issued_at"] != "2026-07-16T10:00:00Z" || payload["valid_until"] != "2026-07-16T10:00:20Z" {
		t.Fatalf("response payload = %#v", payload)
	}
	assertNoStore(t, response)
}

func TestGetDecisionFailsClosedWithoutLeakingRepositoryError(t *testing.T) {
	t.Parallel()

	handler := newTestHandler(&fakePolicyService{err: errors.New("password authentication failed for db-user")})
	request := httptest.NewRequest(nethttp.MethodGet, InternalDecisionPath, nil)
	request.Header.Set("X-Internal-Service-Token", "internal-secret")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != nethttp.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503", response.Code)
	}
	if strings.Contains(response.Body.String(), "password") || !strings.Contains(response.Body.String(), "policy unavailable") {
		t.Fatalf("response body = %q", response.Body.String())
	}
}

func TestChangeStateRequiresInternalTokenAdminRoleAndTrustedActor(t *testing.T) {
	t.Parallel()

	validBody := `{"expected_revision":7,"state":"LOCKED","reason":"incident","change_ticket":"INC-1"}`
	for _, testCase := range []struct {
		name    string
		token   string
		roles   string
		subject string
		want    int
	}{
		{name: "missing token", roles: "ADMIN", subject: "admin-subject", want: nethttp.StatusUnauthorized},
		{name: "missing role", token: "internal-secret", subject: "admin-subject", want: nethttp.StatusForbidden},
		{name: "operations role is insufficient", token: "internal-secret", roles: "OPERATIONS_ADMIN", subject: "admin-subject", want: nethttp.StatusForbidden},
		{name: "missing actor", token: "internal-secret", roles: "ADMIN", want: nethttp.StatusUnauthorized},
		{name: "admin", token: "internal-secret", roles: "ADMIN", subject: "admin-subject", want: nethttp.StatusOK},
		{name: "super admin", token: "internal-secret", roles: "SUPER_ADMIN", subject: "super-subject", want: nethttp.StatusOK},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			service := &fakePolicyService{decision: testDecision()}
			handler := newTestHandler(service)
			request := httptest.NewRequest(nethttp.MethodPut, AdminMutationPath, strings.NewReader(validBody))
			request.Header.Set("Content-Type", "application/json")
			if testCase.token != "" {
				request.Header.Set("X-Internal-Service-Token", testCase.token)
			}
			if testCase.roles != "" {
				request.Header.Set("X-Test-Roles", testCase.roles)
			}
			if testCase.subject != "" {
				request.Header.Set("X-Test-Subject", testCase.subject)
			}
			response := httptest.NewRecorder()
			handler.ServeHTTP(response, request)

			if response.Code != testCase.want {
				t.Fatalf("status = %d, want %d; body = %s", response.Code, testCase.want, response.Body.String())
			}
			if response.Code == nethttp.StatusOK && service.lastCommand.Actor != testCase.subject {
				t.Fatalf("actor = %q, want %q", service.lastCommand.Actor, testCase.subject)
			}
			assertNoStore(t, response)
		})
	}
}

func TestChangeStateUsesStrictBoundedJSON(t *testing.T) {
	t.Parallel()

	for _, testCase := range []struct {
		name        string
		contentType string
		body        string
	}{
		{name: "missing content type", body: `{}`},
		{name: "unknown field", contentType: "application/json", body: `{"expected_revision":7,"state":"LOCKED","reason":"incident","change_ticket":"INC-1","extra":true}`},
		{name: "duplicate field", contentType: "application/json", body: `{"expected_revision":7,"expected_revision":8,"state":"LOCKED","reason":"incident","change_ticket":"INC-1"}`},
		{name: "trailing object", contentType: "application/json", body: `{"expected_revision":7,"state":"LOCKED","reason":"incident","change_ticket":"INC-1"}{}`},
		{name: "oversized", contentType: "application/json", body: `{"expected_revision":7,"state":"LOCKED","reason":"` + strings.Repeat("x", maxMutationBodyBytes) + `","change_ticket":"INC-1"}`},
		{name: "unknown state", contentType: "application/json", body: `{"expected_revision":7,"state":"available","reason":"incident","change_ticket":"INC-1"}`},
		{name: "blank reason", contentType: "application/json", body: `{"expected_revision":7,"state":"LOCKED","reason":" ","change_ticket":"INC-1"}`},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			handler := newTestHandler(&fakePolicyService{decision: testDecision()})
			request := httptest.NewRequest(nethttp.MethodPut, AdminMutationPath, bytes.NewBufferString(testCase.body))
			request.Header.Set("X-Internal-Service-Token", "internal-secret")
			request.Header.Set("X-Test-Roles", "ADMIN")
			request.Header.Set("X-Test-Subject", "admin-subject")
			if testCase.contentType != "" {
				request.Header.Set("Content-Type", testCase.contentType)
			}
			response := httptest.NewRecorder()
			handler.ServeHTTP(response, request)

			if response.Code != nethttp.StatusBadRequest {
				t.Fatalf("status = %d, want 400; body = %s", response.Code, response.Body.String())
			}
			if response.Body.String() != "{\"message\":\"invalid request\"}\n" {
				t.Fatalf("body = %q", response.Body.String())
			}
		})
	}
}

func TestChangeStateMapsDeterministicSameStateConflict(t *testing.T) {
	t.Parallel()

	handler := newTestHandler(&fakePolicyService{err: app.ErrStateUnchanged})
	request := httptest.NewRequest(nethttp.MethodPut, AdminMutationPath, strings.NewReader(
		`{"expected_revision":7,"state":"LOCKED","reason":"incident","change_ticket":"INC-1"}`,
	))
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("X-Internal-Service-Token", "internal-secret")
	request.Header.Set("X-Test-Roles", "ADMIN")
	request.Header.Set("X-Test-Subject", "admin-subject")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)

	if response.Code != nethttp.StatusConflict || !strings.Contains(response.Body.String(), "policy state is unchanged") {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
}

func newTestHandler(service policyService) nethttp.Handler {
	mux := nethttp.NewServeMux()
	NewHandler(service, AuthConfig{
		InternalServiceToken:      "internal-secret",
		TrustedGatewayHeaderRoles: "X-Test-Roles",
		TrustedGatewayHeaderSub:   "X-Test-Subject",
	}).Register(mux)
	return mux
}

type fakePolicyService struct {
	decision    app.Decision
	err         error
	lastCommand app.ChangeCommand
}

func (service *fakePolicyService) ReadDecision(context.Context) (app.Decision, error) {
	return service.decision, service.err
}

func (service *fakePolicyService) ChangeState(_ context.Context, command app.ChangeCommand) (app.Decision, error) {
	service.lastCommand = command
	if service.err != nil {
		return app.Decision{}, service.err
	}
	if command.ExpectedRevision == 0 || !command.State.Valid() || strings.TrimSpace(command.Reason) == "" ||
		strings.TrimSpace(command.ChangeTicket) == "" {
		return app.Decision{}, app.ErrInvalidCommand
	}
	return service.decision, nil
}

func testDecision() app.Decision {
	issuedAt := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	return app.Decision{
		Revision:   8,
		State:      app.StateLocked,
		IssuedAt:   issuedAt,
		ValidUntil: issuedAt.Add(20 * time.Second),
	}
}

func assertNoStore(t *testing.T, response *httptest.ResponseRecorder) {
	t.Helper()
	if value := response.Header().Get("Cache-Control"); !strings.Contains(value, "private") || !strings.Contains(value, "no-store") {
		t.Fatalf("Cache-Control = %q", value)
	}
}
