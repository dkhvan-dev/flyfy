package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"kz/inflap/backend/services/user-route-service/internal/domain/model"
)

func TestCreateRouteNormalizesVisibilityAndPersistsSnapshot(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, time.June, 22, 9, 0, 0, 0, time.UTC)
	repo := NewMemoryUserRouteRepository()
	uc := NewUserRouteUseCase(repo, WithClock(func() time.Time { return now }))

	route, err := uc.CreateRoute(ctx, CreateRouteInput{
		ActorUserID: "user-1",
		Title:       "Алматы: кофе и парк",
		Description: "Легкая прогулка от кофейни до парка.",
		Visibility:  model.RouteVisibilityPublic,
		Profile:     model.RouteProfileTouristWalk,
		CityCode:    "almaty",
		Points: []model.UserRoutePoint{
			{Latitude: 43.238949, Longitude: 76.889709, Name: "Кофейня"},
			{Latitude: 43.239931, Longitude: 76.912345, Name: "Парк"},
		},
		Snapshot: model.RouteSnapshot{
			Provider:        "valhalla",
			Mode:            model.RouteModeWalking,
			DistanceMeters:  1800,
			DurationSeconds: 1320,
			EncodedPolyline: "encoded-route",
		},
	})
	if err != nil {
		t.Fatalf("CreateRoute returned error: %v", err)
	}
	if route.ID == "" {
		t.Fatal("expected generated route id")
	}
	if route.OwnerUserID != "user-1" {
		t.Fatalf("owner = %q, want user-1", route.OwnerUserID)
	}
	if route.Visibility != model.RouteVisibilityPublic {
		t.Fatalf("visibility = %q, want public", route.Visibility)
	}
	if route.CreatedAt != now || route.UpdatedAt != now {
		t.Fatalf("expected deterministic timestamps, got created=%s updated=%s", route.CreatedAt, route.UpdatedAt)
	}
	if route.Snapshot.DistanceMeters != 1800 || route.Snapshot.EncodedPolyline != "encoded-route" {
		t.Fatalf("snapshot was not persisted: %#v", route.Snapshot)
	}
	if got := repo.RouteCount(); got != 1 {
		t.Fatalf("repo route count = %d, want 1", got)
	}
}

func TestCreateRouteRejectsInvalidPointCountAndCoordinates(t *testing.T) {
	ctx := context.Background()
	uc := NewUserRouteUseCase(NewMemoryUserRouteRepository())

	_, err := uc.CreateRoute(ctx, CreateRouteInput{
		ActorUserID: "user-1",
		Title:       "Broken",
		Points: []model.UserRoutePoint{
			{Latitude: 91, Longitude: 76.889709},
		},
	})
	if !errors.Is(err, model.ErrInvalidUserRoute) {
		t.Fatalf("expected invalid route error, got %v", err)
	}
}

func TestRouteVisibilityControlsReadAndSave(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryUserRouteRepository()
	uc := NewUserRouteUseCase(repo)

	privateRoute := mustCreateRoute(t, ctx, uc, "owner-1", model.RouteVisibilityPrivate, "Private walk")
	publicRoute := mustCreateRoute(t, ctx, uc, "owner-1", model.RouteVisibilityPublic, "Public walk")
	publicRoute = mustApproveRoute(t, ctx, uc, publicRoute.ID)

	if _, err := uc.GetRoute(ctx, GetRouteInput{ActorUserID: "user-2", RouteID: privateRoute.ID}); !errors.Is(err, ErrUserRouteNotFound) {
		t.Fatalf("private route should be hidden from non-owner, got %v", err)
	}

	visible, err := uc.GetRoute(ctx, GetRouteInput{ActorUserID: "user-2", RouteID: publicRoute.ID})
	if err != nil {
		t.Fatalf("public route should be visible: %v", err)
	}
	if visible.SavedByMe {
		t.Fatal("public route should not be saved before SaveRoute")
	}

	saved, err := uc.SaveRoute(ctx, SaveRouteInput{ActorUserID: "user-2", RouteID: publicRoute.ID})
	if err != nil {
		t.Fatalf("SaveRoute returned error: %v", err)
	}
	if !saved.SavedByMe || saved.Stats.SavesCount != 1 {
		t.Fatalf("expected saved route stats, got savedByMe=%v stats=%#v", saved.SavedByMe, saved.Stats)
	}

	if _, err := uc.SaveRoute(ctx, SaveRouteInput{ActorUserID: "user-2", RouteID: privateRoute.ID}); !errors.Is(err, ErrUserRouteNotFound) {
		t.Fatalf("saving hidden private route should return not found, got %v", err)
	}
}

func TestPublicRouteRequiresModerationApprovalBeforePublicRead(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryUserRouteRepository()
	uc := NewUserRouteUseCase(repo)

	route := mustCreateRoute(t, ctx, uc, "owner-1", model.RouteVisibilityPublic, "Public walk")
	if route.ModerationStatus != model.RouteModerationStatusPending {
		t.Fatalf("new public route moderation status = %q, want pending", route.ModerationStatus)
	}

	if _, err := uc.GetRoute(ctx, GetRouteInput{ActorUserID: "traveler-2", RouteID: route.ID}); !errors.Is(err, ErrUserRouteNotFound) {
		t.Fatalf("pending public route must be hidden from non-owner, got %v", err)
	}

	ownerView, err := uc.GetRoute(ctx, GetRouteInput{ActorUserID: "owner-1", RouteID: route.ID})
	if err != nil {
		t.Fatalf("owner should see pending public route: %v", err)
	}
	if ownerView.ModerationStatus != model.RouteModerationStatusPending {
		t.Fatalf("owner moderation status = %q, want pending", ownerView.ModerationStatus)
	}

	reviewed, err := uc.ReviewRoute(ctx, ReviewRouteInput{
		ActorUserID: "moderator-1",
		RouteID:     route.ID,
		Decision:    "approve",
	})
	if err != nil {
		t.Fatalf("ReviewRoute approve returned error: %v", err)
	}
	if reviewed.ModerationStatus != model.RouteModerationStatusApproved {
		t.Fatalf("reviewed status = %q, want approved", reviewed.ModerationStatus)
	}

	visible, err := uc.GetRoute(ctx, GetRouteInput{ActorUserID: "traveler-2", RouteID: route.ID})
	if err != nil {
		t.Fatalf("approved public route should be visible: %v", err)
	}
	if visible.ID != route.ID {
		t.Fatalf("visible route id = %q, want %q", visible.ID, route.ID)
	}
}

func TestReviewRouteRejectsWithReasonAndAdminListFiltersByStatus(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryUserRouteRepository()
	uc := NewUserRouteUseCase(repo)
	route := mustCreateRoute(t, ctx, uc, "owner-1", model.RouteVisibilityPublic, "Questionable route")

	if _, err := uc.ReviewRoute(ctx, ReviewRouteInput{
		ActorUserID: "moderator-1",
		RouteID:     route.ID,
		Decision:    "reject",
	}); !errors.Is(err, ErrUserRouteReviewReasonRequired) {
		t.Fatalf("reject without reason error = %v, want reason required", err)
	}

	rejected, err := uc.ReviewRoute(ctx, ReviewRouteInput{
		ActorUserID: "moderator-1",
		RouteID:     route.ID,
		Decision:    "reject",
		Reason:      "Unsafe or misleading route",
	})
	if err != nil {
		t.Fatalf("ReviewRoute reject returned error: %v", err)
	}
	if rejected.ModerationStatus != model.RouteModerationStatusRejected {
		t.Fatalf("reviewed status = %q, want rejected", rejected.ModerationStatus)
	}
	if rejected.ModerationReason != "Unsafe or misleading route" {
		t.Fatalf("reason = %q", rejected.ModerationReason)
	}
	if rejected.ModeratedByUserID == nil || *rejected.ModeratedByUserID != "moderator-1" {
		t.Fatalf("moderatedBy = %#v, want moderator-1", rejected.ModeratedByUserID)
	}
	if rejected.ModeratedAt == nil {
		t.Fatal("moderatedAt is nil")
	}

	items, err := uc.ListAdminRoutes(ctx, ListAdminRoutesInput{
		ActorUserID:      "moderator-1",
		ModerationStatus: model.RouteModerationStatusRejected,
	})
	if err != nil {
		t.Fatalf("ListAdminRoutes returned error: %v", err)
	}
	if len(items) != 1 || items[0].ID != route.ID {
		t.Fatalf("admin rejected list = %#v, want route %s", items, route.ID)
	}
}

func TestCopyRouteCreatesPrivateEditableRouteForActor(t *testing.T) {
	ctx := context.Background()
	uc := NewUserRouteUseCase(NewMemoryUserRouteRepository())
	source := mustCreateRoute(t, ctx, uc, "owner-1", model.RouteVisibilityPublic, "Weekend city route")
	source = mustApproveRoute(t, ctx, uc, source.ID)

	copy, err := uc.CopyRoute(ctx, CopyRouteInput{
		ActorUserID: "user-2",
		RouteID:     source.ID,
	})
	if err != nil {
		t.Fatalf("CopyRoute returned error: %v", err)
	}
	if copy.ID == source.ID {
		t.Fatal("copy should receive a new route id")
	}
	if copy.OwnerUserID != "user-2" {
		t.Fatalf("copy owner = %q, want user-2", copy.OwnerUserID)
	}
	if copy.Visibility != model.RouteVisibilityPrivate {
		t.Fatalf("copy visibility = %q, want private", copy.Visibility)
	}
	if copy.SourceRouteID == nil || *copy.SourceRouteID != source.ID {
		t.Fatalf("copy should remember source route id, got %#v", copy.SourceRouteID)
	}
	if copy.Title != "Weekend city route" {
		t.Fatalf("copy title = %q", copy.Title)
	}
	if copy.Stats.CopiesCount != 0 {
		t.Fatalf("new copy stats should start empty, got %#v", copy.Stats)
	}

	reloadedSource, err := uc.GetRoute(ctx, GetRouteInput{ActorUserID: "owner-1", RouteID: source.ID})
	if err != nil {
		t.Fatalf("source reload returned error: %v", err)
	}
	if reloadedSource.Stats.CopiesCount != 1 {
		t.Fatalf("source copies count = %d, want 1", reloadedSource.Stats.CopiesCount)
	}
}

func TestUpdateRouteAllowsOwnerToPublishAndEditMetadata(t *testing.T) {
	ctx := context.Background()
	now := time.Date(2026, time.June, 22, 10, 0, 0, 0, time.UTC)
	later := now.Add(15 * time.Minute)
	clock := now
	uc := NewUserRouteUseCase(
		NewMemoryUserRouteRepository(),
		WithClock(func() time.Time { return clock }),
	)
	route := mustCreateRoute(t, ctx, uc, "owner-1", model.RouteVisibilityPrivate, "Private route")

	clock = later
	title := "Public coffee walk"
	description := "Shared route for a slow city walk."
	visibility := model.RouteVisibilityPublic
	updated, err := uc.UpdateRoute(ctx, UpdateRouteInput{
		ActorUserID: "owner-1",
		RouteID:     route.ID,
		Title:       &title,
		Description: &description,
		Visibility:  &visibility,
	})
	if err != nil {
		t.Fatalf("UpdateRoute returned error: %v", err)
	}
	if updated.Title != "Public coffee walk" || updated.Description != "Shared route for a slow city walk." {
		t.Fatalf("route metadata was not updated: %#v", updated)
	}
	if updated.Visibility != model.RouteVisibilityPublic {
		t.Fatalf("visibility = %q, want public", updated.Visibility)
	}
	if !updated.CreatedAt.Equal(now) || !updated.UpdatedAt.Equal(later) {
		t.Fatalf("timestamps created=%s updated=%s", updated.CreatedAt, updated.UpdatedAt)
	}

	if updated.ModerationStatus != model.RouteModerationStatusPending {
		t.Fatalf("updated public route moderation status = %q, want pending", updated.ModerationStatus)
	}
	if _, err := uc.GetRoute(ctx, GetRouteInput{ActorUserID: "traveler-2", RouteID: route.ID}); !errors.Is(err, ErrUserRouteNotFound) {
		t.Fatalf("pending updated route must be hidden from non-owner, got %v", err)
	}
}

func TestUpdateRouteRejectsNonOwner(t *testing.T) {
	ctx := context.Background()
	uc := NewUserRouteUseCase(NewMemoryUserRouteRepository())
	route := mustCreateRoute(t, ctx, uc, "owner-1", model.RouteVisibilityPublic, "Owner route")
	route = mustApproveRoute(t, ctx, uc, route.ID)
	visibility := model.RouteVisibilityPrivate

	_, err := uc.UpdateRoute(ctx, UpdateRouteInput{
		ActorUserID: "traveler-2",
		RouteID:     route.ID,
		Visibility:  &visibility,
	})
	if !errors.Is(err, ErrUserRouteForbidden) {
		t.Fatalf("expected forbidden update, got %v", err)
	}
}

func mustCreateRoute(
	t *testing.T,
	ctx context.Context,
	uc *UserRouteUseCase,
	owner string,
	visibility model.RouteVisibility,
	title string,
) model.UserRoute {
	t.Helper()
	route, err := uc.CreateRoute(ctx, CreateRouteInput{
		ActorUserID: owner,
		Title:       title,
		Visibility:  visibility,
		Profile:     model.RouteProfileTouristWalk,
		Points: []model.UserRoutePoint{
			{Latitude: 43.238949, Longitude: 76.889709, Name: "Start"},
			{Latitude: 43.239931, Longitude: 76.912345, Name: "Finish"},
		},
		Snapshot: model.RouteSnapshot{
			Provider:        "valhalla",
			Mode:            model.RouteModeWalking,
			DistanceMeters:  1800,
			DurationSeconds: 1320,
			EncodedPolyline: "encoded-route",
		},
	})
	if err != nil {
		t.Fatalf("CreateRoute returned error: %v", err)
	}
	return route
}

func mustApproveRoute(
	t *testing.T,
	ctx context.Context,
	uc *UserRouteUseCase,
	routeID string,
) model.UserRoute {
	t.Helper()
	route, err := uc.ReviewRoute(ctx, ReviewRouteInput{
		ActorUserID: "moderator-1",
		RouteID:     routeID,
		Decision:    "approve",
	})
	if err != nil {
		t.Fatalf("ReviewRoute approve returned error: %v", err)
	}
	return route
}
