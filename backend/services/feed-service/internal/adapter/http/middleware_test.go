package http

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/config"
)

func TestAuthContextMiddlewareAllowsPublicPostShareWrite(t *testing.T) {
	postID := uuid.New()
	req := httptest.NewRequest(http.MethodPost, "/v1/posts/"+postID.String()+"/share", nil)
	rec := httptest.NewRecorder()

	authContextMiddleware(testAuthMiddlewareConfig(), http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})).ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
}

func TestAuthContextMiddlewareRejectsTrustedHeadersWithoutInternalToken(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/v1/posts", nil)
	req.Header.Set("X-Auth-Subject", "user-subject")
	req.Header.Set("X-User-Id", uuid.NewString())
	req.Header.Set("X-User-Roles", "user")
	rec := httptest.NewRecorder()

	authContextMiddleware(testAuthMiddlewareConfig(), http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("handler should not be called for spoofed trusted headers")
	})).ServeHTTP(rec, req)

	assertErrorResponse(t, rec, http.StatusUnauthorized, map[string]string{
		"code": "missing_authenticated_subject",
		"kind": "business",
	})
}

func TestAuthContextMiddlewareAllowsTrustedHeadersWithInternalToken(t *testing.T) {
	userID := uuid.NewString()
	req := httptest.NewRequest(http.MethodPost, "/v1/posts", nil)
	req.Header.Set("X-Internal-Service-Token", "test-internal-token")
	req.Header.Set("X-Auth-Subject", "user-subject")
	req.Header.Set("X-User-Id", userID)
	req.Header.Set("X-User-Roles", "user,moderator")
	rec := httptest.NewRecorder()

	authContextMiddleware(testAuthMiddlewareConfig(), http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := SubjectFromContext(r.Context()); got != "user-subject" {
			t.Fatalf("subject = %q, want user-subject", got)
		}
		if got := UserIDFromContext(r.Context()); got != userID {
			t.Fatalf("user id = %q, want %q", got, userID)
		}
		roles := UserRolesFromContext(r.Context())
		if len(roles) != 2 || roles[0] != "user" || roles[1] != "moderator" {
			t.Fatalf("roles = %#v, want user/moderator", roles)
		}
		w.WriteHeader(http.StatusOK)
	})).ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
}

func TestAuthContextMiddlewareStillRequiresSubjectForProtectedPostWrites(t *testing.T) {
	postID := uuid.New()
	for _, tc := range []struct {
		name   string
		method string
		path   string
	}{
		{name: "create", method: http.MethodPost, path: "/v1/posts"},
		{name: "track view", method: http.MethodPost, path: "/v1/posts/" + postID.String() + "/views"},
		{name: "like post", method: http.MethodPost, path: "/v1/posts/" + postID.String() + "/likes"},
		{name: "create comment", method: http.MethodPost, path: "/v1/posts/" + postID.String() + "/comments"},
		{name: "autosave", method: http.MethodPost, path: "/v1/posts/" + postID.String() + "/autosave"},
		{name: "update", method: http.MethodPatch, path: "/v1/posts/" + postID.String()},
		{name: "delete", method: http.MethodDelete, path: "/v1/posts/" + postID.String()},
	} {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(tc.method, tc.path, nil)
			rec := httptest.NewRecorder()

			authContextMiddleware(testAuthMiddlewareConfig(), http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusOK)
			})).ServeHTTP(rec, req)

			assertErrorResponse(t, rec, http.StatusUnauthorized, map[string]string{
				"code": "missing_authenticated_subject",
				"kind": "business",
			})
		})
	}
}

func testAuthMiddlewareConfig() *config.Config {
	return &config.Config{
		Security: config.SecurityConfig{
			RequireAuthenticatedWrites: true,
			InternalServiceToken:       "test-internal-token",
			TrustedGatewayHeaderUserID: "X-User-Id",
			TrustedGatewayHeaderRoles:  "X-User-Roles",
			TrustedGatewayHeaderSub:    "X-Auth-Subject",
		},
	}
}
