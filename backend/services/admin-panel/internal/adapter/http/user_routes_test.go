package http

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/config"
	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestUserRouteQueueRendersItemsAndReviewActions(t *testing.T) {
	t.Parallel()

	routeID := uuid.New()
	ownerID := uuid.New()
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "lead@inflap.local",
		DisplayName: "Moderation Lead",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionModerationAssign,
		},
		Roles: []enum.StaffRole{enum.StaffRoleModerationLead},
	}
	client := &userRouteHTTPClientStub{
		items: []model.AdminUserRoute{
			{
				ID:               routeID,
				OwnerUserID:      ownerID,
				Title:            "Coffee walk",
				Description:      "Best morning stops",
				Visibility:       "public",
				CityCode:         "ala",
				DistanceMeters:   1200,
				DurationSeconds:  900,
				ModerationStatus: model.UserRouteModerationPending,
				Points: []model.AdminUserRoutePoint{
					{Position: 1, Label: "Start", Latitude: 43.238, Longitude: 76.945},
					{Position: 2, Label: "Finish", Latitude: 43.245, Longitude: 76.958},
				},
				CreatedAt: time.Date(2026, 6, 22, 3, 0, 0, 0, time.UTC),
				UpdatedAt: time.Date(2026, 6, 22, 3, 5, 0, 0, time.UTC),
			},
		},
	}
	server := newUserRouteHTTPTestServer(t, app.NewUserRouteModerationUseCase(client, nil))
	request := httptest.NewRequest(http.MethodGet, "/admin/moderation/user-routes?status=pending&cityCode=ala", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.UserRouteQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200: %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"User routes",
		"Coffee walk",
		ownerID.String(),
		"1.2 km",
		"15 min",
		"/admin/moderation/user-routes/" + routeID.String() + "/approve",
		"/admin/moderation/user-routes/" + routeID.String() + "/reject",
		"/admin/moderation/user-routes/" + routeID.String() + "/hide",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q: %s", expected, body)
		}
	}
	if client.lastList.ModerationStatus != model.UserRouteModerationPending || client.lastList.CityCode != "ala" {
		t.Fatalf("list filter = %+v, want pending/ala", client.lastList)
	}
}

func TestRejectUserRouteRedirectsBackToQueue(t *testing.T) {
	t.Parallel()

	routeID := uuid.New()
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "admin@inflap.local",
		DisplayName: "Admin",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationAssign,
		},
		Roles: []enum.StaffRole{enum.StaffRoleAdmin},
	}
	client := &userRouteHTTPClientStub{
		reviewed: &model.AdminUserRoute{
			ID:               routeID,
			OwnerUserID:      uuid.New(),
			Title:            "Unsafe route",
			Visibility:       "public",
			ModerationStatus: model.UserRouteModerationRejected,
			CreatedAt:        time.Now().UTC(),
			UpdatedAt:        time.Now().UTC(),
		},
	}
	server := newUserRouteHTTPTestServer(t, app.NewUserRouteModerationUseCase(client, nil))
	form := url.Values{"reason": []string{"Unsafe content"}}
	request := httptest.NewRequest(http.MethodPost, "/admin/moderation/user-routes/"+routeID.String()+"/reject?status=pending", strings.NewReader(form.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.RejectUserRoute(recorder, request)

	if recorder.Code != http.StatusSeeOther {
		t.Fatalf("status = %d, want 303: %s", recorder.Code, recorder.Body.String())
	}
	if client.lastReview.RouteID != routeID ||
		client.lastReview.Decision != model.UserRouteReviewReject ||
		client.lastReview.Reason != "Unsafe content" {
		t.Fatalf("review input = %+v, want reject with reason", client.lastReview)
	}
	location := recorder.Header().Get("Location")
	if !strings.Contains(location, "/admin/moderation/user-routes") || !strings.Contains(location, "status=pending") {
		t.Fatalf("redirect location = %q, want queue with preserved filters", location)
	}
}

func newUserRouteHTTPTestServer(t *testing.T, routes *app.UserRouteModerationUseCase) *Server {
	t.Helper()
	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer() error = %v", err)
	}
	server := NewServer(&config.Config{}, renderer, nil, nil, nil, nil, nil, nil, nil)
	server.SetUserRouteModerationUseCase(routes)
	return server
}

func adminTestContext(ctx context.Context, staff *model.StaffUser) context.Context {
	ctx = withStaff(ctx, staff)
	ctx = withLocale(ctx, localeEN)
	ctx = withCSRFToken(ctx, "csrf-token")
	ctx = withRequestID(ctx, "request-id")
	return ctx
}

type userRouteHTTPClientStub struct {
	items      []model.AdminUserRoute
	reviewed   *model.AdminUserRoute
	lastList   model.AdminUserRouteAdminListRequest
	lastReview model.AdminUserRouteAdminReviewRequest
}

func (c *userRouteHTTPClientStub) ListUserRoutes(
	_ context.Context,
	input model.AdminUserRouteAdminListRequest,
) ([]model.AdminUserRoute, error) {
	c.lastList = input
	return c.items, nil
}

func (c *userRouteHTTPClientStub) ReviewUserRoute(
	_ context.Context,
	input model.AdminUserRouteAdminReviewRequest,
) (*model.AdminUserRoute, error) {
	c.lastReview = input
	return c.reviewed, nil
}
