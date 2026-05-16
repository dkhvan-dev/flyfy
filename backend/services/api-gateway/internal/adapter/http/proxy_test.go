package http

import (
	"context"
	"net/http/httptest"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/config"
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
