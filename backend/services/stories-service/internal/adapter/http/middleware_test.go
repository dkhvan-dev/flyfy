package http

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/stories-service/internal/config"
)

func TestAuthContextMiddlewareAllowsPublicStoryShareWrite(t *testing.T) {
	storyID := uuid.New()
	req := httptest.NewRequest(http.MethodPost, "/v1/stories/"+storyID.String()+"/share", nil)
	rec := httptest.NewRecorder()

	authContextMiddleware(testAuthMiddlewareConfig(), http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})).ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
}

func TestAuthContextMiddlewareStillRequiresSubjectForProtectedStoryWrites(t *testing.T) {
	storyID := uuid.New()
	for _, tc := range []struct {
		name   string
		method string
		path   string
	}{
		{name: "create", method: http.MethodPost, path: "/v1/stories"},
		{name: "track view", method: http.MethodPost, path: "/v1/stories/" + storyID.String() + "/views"},
		{name: "like story", method: http.MethodPost, path: "/v1/stories/" + storyID.String() + "/likes"},
		{name: "create comment", method: http.MethodPost, path: "/v1/stories/" + storyID.String() + "/comments"},
		{name: "autosave", method: http.MethodPost, path: "/v1/stories/" + storyID.String() + "/autosave"},
		{name: "update", method: http.MethodPatch, path: "/v1/stories/" + storyID.String()},
		{name: "delete", method: http.MethodDelete, path: "/v1/stories/" + storyID.String()},
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
			TrustedGatewayHeaderUserID: "X-User-Id",
			TrustedGatewayHeaderRoles:  "X-User-Roles",
			TrustedGatewayHeaderSub:    "X-Auth-Subject",
		},
	}
}
