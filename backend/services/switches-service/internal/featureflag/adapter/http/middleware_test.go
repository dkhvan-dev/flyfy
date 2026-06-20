package http

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRequireOperationsRoleBlocksWriteWithoutAdminRole(t *testing.T) {
	handler := Chain(MiddlewareConfig{TrustedGatewayHeaderRoles: "X-User-Roles"}, requireOperationsRole(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})))

	for _, tc := range []struct {
		name  string
		roles string
		want  int
	}{
		{name: "missing role", roles: "", want: http.StatusForbidden},
		{name: "wrong role", roles: "VIEWER", want: http.StatusForbidden},
		{name: "admin role", roles: "ADMIN", want: http.StatusNoContent},
		{name: "super admin role", roles: "SUPER_ADMIN", want: http.StatusNoContent},
	} {
		t.Run(tc.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodPost, "/api/v1/feature-flags", nil)
			if tc.roles != "" {
				request.Header.Set("X-User-Roles", tc.roles)
			}
			response := httptest.NewRecorder()

			handler.ServeHTTP(response, request)

			if response.Code != tc.want {
				t.Fatalf("status = %d, want %d", response.Code, tc.want)
			}
		})
	}
}

func TestRequireOperationsAccessRequiresInternalTokenAndRole(t *testing.T) {
	handler := &Handler{internalServiceToken: "secret"}
	protected := Chain(MiddlewareConfig{TrustedGatewayHeaderRoles: "X-User-Roles"}, handler.requireOperationsAccess(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})))

	for _, tc := range []struct {
		name  string
		token string
		roles string
		want  int
	}{
		{name: "missing token", roles: "ADMIN", want: http.StatusUnauthorized},
		{name: "missing role", token: "secret", want: http.StatusForbidden},
		{name: "token and role", token: "secret", roles: "ADMIN", want: http.StatusNoContent},
	} {
		t.Run(tc.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodPost, "/api/v1/feature-flags", nil)
			if tc.token != "" {
				request.Header.Set("X-Internal-Service-Token", tc.token)
			}
			if tc.roles != "" {
				request.Header.Set("X-User-Roles", tc.roles)
			}
			response := httptest.NewRecorder()

			protected.ServeHTTP(response, request)

			if response.Code != tc.want {
				t.Fatalf("status = %d, want %d", response.Code, tc.want)
			}
		})
	}
}
