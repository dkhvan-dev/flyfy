package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestListUserRoutesRequiresModerationRead(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionDashboardRead}}
	uc := NewUserRouteModerationUseCase(&userRouteAdminClientStub{}, &userRouteAuditRepoStub{})

	_, err := uc.ListRoutes(ctx, actor, model.AdminUserRouteListFilter{})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("ListRoutes() error = %v, want %v", err, ErrPermissionDenied)
	}
}

func TestListUserRoutesNormalizesFilterAndGatewayRole(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionModerationRead},
		Roles:       []enum.StaffRole{enum.StaffRoleModerationLead},
	}
	client := &userRouteAdminClientStub{
		items: []model.AdminUserRoute{
			{
				ID:               uuid.New(),
				OwnerUserID:      uuid.New(),
				Title:            "Coffee walk",
				Visibility:       "public",
				ModerationStatus: model.UserRouteModerationPending,
				CreatedAt:        time.Now().UTC(),
				UpdatedAt:        time.Now().UTC(),
			},
		},
	}
	uc := NewUserRouteModerationUseCase(client, &userRouteAuditRepoStub{})

	items, err := uc.ListRoutes(ctx, actor, model.AdminUserRouteListFilter{
		ModerationStatus: " PENDING ",
		CityCode:         "  ALA ",
		Limit:            1000,
		Offset:           -10,
	})

	if err != nil {
		t.Fatalf("ListRoutes() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items length = %d, want 1", len(items))
	}
	if client.lastList.ActorUserID != actor.ID.String() {
		t.Fatalf("actor user id = %q, want %s", client.lastList.ActorUserID, actor.ID)
	}
	if len(client.lastList.ActorRoles) != 1 || client.lastList.ActorRoles[0] != "MODERATOR" {
		t.Fatalf("actor roles = %#v, want MODERATOR", client.lastList.ActorRoles)
	}
	if client.lastList.ModerationStatus != model.UserRouteModerationPending {
		t.Fatalf("status = %q, want pending", client.lastList.ModerationStatus)
	}
	if client.lastList.CityCode != "ala" {
		t.Fatalf("city code = %q, want ala", client.lastList.CityCode)
	}
	if client.lastList.Limit != 200 || client.lastList.Offset != 0 {
		t.Fatalf("limit/offset = %d/%d, want 200/0", client.lastList.Limit, client.lastList.Offset)
	}
}

func TestReviewUserRouteRequiresAssignPermission(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionModerationRead}}
	uc := NewUserRouteModerationUseCase(&userRouteAdminClientStub{}, &userRouteAuditRepoStub{})

	_, err := uc.ReviewRoute(ctx, actor, model.AdminUserRouteReviewInput{
		RouteID:  uuid.New(),
		Decision: model.UserRouteReviewApprove,
	}, RequestMetadata{})

	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("ReviewRoute() error = %v, want %v", err, ErrPermissionDenied)
	}
}

func TestReviewUserRouteWritesAudit(t *testing.T) {
	ctx := context.Background()
	actor := &model.StaffUser{
		ID:          uuid.New(),
		Permissions: []enum.Permission{enum.PermissionModerationAssign},
		Roles:       []enum.StaffRole{enum.StaffRoleAdmin},
	}
	routeID := uuid.New()
	client := &userRouteAdminClientStub{
		reviewed: &model.AdminUserRoute{
			ID:               routeID,
			OwnerUserID:      uuid.New(),
			Title:            "Sunset route",
			Visibility:       "public",
			ModerationStatus: model.UserRouteModerationApproved,
			CreatedAt:        time.Now().UTC(),
			UpdatedAt:        time.Now().UTC(),
		},
	}
	audit := &userRouteAuditRepoStub{}
	uc := NewUserRouteModerationUseCase(client, audit)

	item, err := uc.ReviewRoute(ctx, actor, model.AdminUserRouteReviewInput{
		RouteID:  routeID,
		Decision: model.UserRouteReviewApprove,
		Reason:   "Looks good.",
	}, RequestMetadata{RequestID: "req-route-review", IPAddress: "127.0.0.1", UserAgent: "test-agent"})

	if err != nil {
		t.Fatalf("ReviewRoute() error = %v", err)
	}
	if item == nil || item.ID != routeID {
		t.Fatalf("reviewed item = %+v, want route %s", item, routeID)
	}
	if client.lastReview.ActorUserID != actor.ID.String() {
		t.Fatalf("actor user id = %q, want %s", client.lastReview.ActorUserID, actor.ID)
	}
	if len(client.lastReview.ActorRoles) != 1 || client.lastReview.ActorRoles[0] != "ADMIN" {
		t.Fatalf("actor roles = %#v, want ADMIN", client.lastReview.ActorRoles)
	}
	if len(audit.events) != 1 {
		t.Fatalf("audit events = %d, want 1", len(audit.events))
	}
	if audit.events[0].Action != "user_route.review.approved" {
		t.Fatalf("audit action = %q, want user_route.review.approved", audit.events[0].Action)
	}
	if audit.events[0].EntityType != "user_route" {
		t.Fatalf("entity type = %q, want user_route", audit.events[0].EntityType)
	}
	if audit.events[0].EntityID == nil || *audit.events[0].EntityID != routeID {
		t.Fatalf("entity id = %v, want %s", audit.events[0].EntityID, routeID)
	}
}

type userRouteAdminClientStub struct {
	items      []model.AdminUserRoute
	reviewed   *model.AdminUserRoute
	lastList   model.AdminUserRouteAdminListRequest
	lastReview model.AdminUserRouteAdminReviewRequest
}

func (c *userRouteAdminClientStub) ListUserRoutes(
	_ context.Context,
	input model.AdminUserRouteAdminListRequest,
) ([]model.AdminUserRoute, error) {
	c.lastList = input
	return c.items, nil
}

func (c *userRouteAdminClientStub) ReviewUserRoute(
	_ context.Context,
	input model.AdminUserRouteAdminReviewRequest,
) (*model.AdminUserRoute, error) {
	c.lastReview = input
	return c.reviewed, nil
}

type userRouteAuditRepoStub struct {
	events []*model.AuditEvent
}

func (r *userRouteAuditRepoStub) Append(_ context.Context, event *model.AuditEvent) error {
	r.events = append(r.events, event)
	return nil
}

func (r *userRouteAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}
