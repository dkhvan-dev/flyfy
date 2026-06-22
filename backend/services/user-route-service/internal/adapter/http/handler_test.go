package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"kz/inflap/backend/services/user-route-service/internal/app"
	"kz/inflap/backend/services/user-route-service/internal/domain/model"
)

func TestCreateRouteRequiresTrustedUserAndReturnsCreatedRoute(t *testing.T) {
	mux := newTestMux()

	body := []byte(`{
		"title":"Алматы: кофе и парк",
		"description":"Легкая прогулка",
		"visibility":"public",
		"profile":"tourist_walk",
		"cityCode":"almaty",
		"points":[
			{"latitude":43.238949,"longitude":76.889709,"name":"Кофейня"},
			{"latitude":43.239931,"longitude":76.912345,"name":"Парк"}
		],
		"snapshot":{
			"provider":"valhalla",
			"mode":"walking",
			"distanceMeters":1800,
			"durationSeconds":1320,
			"encodedPolyline":"encoded-route"
		}
	}`)

	unauthorized := httptest.NewRecorder()
	mux.ServeHTTP(unauthorized, httptest.NewRequest(http.MethodPost, "/v1/user-routes", bytes.NewReader(body)))
	if unauthorized.Code != http.StatusUnauthorized {
		t.Fatalf("unauthorized status = %d, want %d", unauthorized.Code, http.StatusUnauthorized)
	}

	req := httptest.NewRequest(http.MethodPost, "/v1/user-routes", bytes.NewReader(body))
	req.Header.Set("X-User-Id", "user-1")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d body=%s", rec.Code, http.StatusCreated, rec.Body.String())
	}
	var route model.UserRoute
	decodeJSON(t, rec.Body.Bytes(), &route)
	if route.ID == "" || route.OwnerUserID != "user-1" || route.Visibility != model.RouteVisibilityPublic {
		t.Fatalf("unexpected route response: %#v", route)
	}
	if route.Snapshot.DistanceMeters != 1800 || len(route.Points) != 2 {
		t.Fatalf("route contract lost snapshot or points: %#v", route)
	}
}

func TestPublicListAndDetailHidePrivateRoutes(t *testing.T) {
	repo := app.NewMemoryUserRouteRepository()
	uc := app.NewUserRouteUseCase(repo)
	mux := muxForUseCase(uc)

	privateRoute := mustCreateHTTPRoute(t, uc, "owner-1", "Private", model.RouteVisibilityPrivate)
	publicRoute := mustCreateHTTPRoute(t, uc, "owner-1", "Public", model.RouteVisibilityPublic)
	publicRoute = mustReviewHTTPRoute(t, uc, publicRoute.ID, "approve", "")

	privateRec := httptest.NewRecorder()
	mux.ServeHTTP(privateRec, httptest.NewRequest(http.MethodGet, "/v1/user-routes/"+privateRoute.ID, nil))
	if privateRec.Code != http.StatusNotFound {
		t.Fatalf("private detail status = %d, want 404", privateRec.Code)
	}

	publicRec := httptest.NewRecorder()
	mux.ServeHTTP(publicRec, httptest.NewRequest(http.MethodGet, "/v1/user-routes/"+publicRoute.ID, nil))
	if publicRec.Code != http.StatusOK {
		t.Fatalf("public detail status = %d, want 200 body=%s", publicRec.Code, publicRec.Body.String())
	}

	listRec := httptest.NewRecorder()
	mux.ServeHTTP(listRec, httptest.NewRequest(http.MethodGet, "/v1/user-routes?visibility=public", nil))
	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, want 200 body=%s", listRec.Code, listRec.Body.String())
	}
	var page routeListResponse
	decodeJSON(t, listRec.Body.Bytes(), &page)
	if len(page.Items) != 1 || page.Items[0].ID != publicRoute.ID {
		t.Fatalf("public list should contain only public route, got %#v", page.Items)
	}
}

func TestPendingPublicRouteIsHiddenUntilAdminApproves(t *testing.T) {
	repo := app.NewMemoryUserRouteRepository()
	uc := app.NewUserRouteUseCase(repo)
	mux := muxForUseCase(uc)
	route := mustCreateHTTPRoute(t, uc, "owner-1", "Pending public", model.RouteVisibilityPublic)

	pendingRec := httptest.NewRecorder()
	mux.ServeHTTP(pendingRec, httptest.NewRequest(http.MethodGet, "/v1/user-routes/"+route.ID, nil))
	if pendingRec.Code != http.StatusNotFound {
		t.Fatalf("pending public detail status = %d, want 404", pendingRec.Code)
	}

	reviewReq := httptest.NewRequest(http.MethodPost, "/v1/admin/user-routes/"+route.ID+"/review", bytes.NewReader([]byte(`{"decision":"approve"}`)))
	reviewReq.Header.Set("X-User-Id", "moderator-1")
	reviewReq.Header.Set("X-User-Roles", "MODERATOR")
	reviewRec := httptest.NewRecorder()
	mux.ServeHTTP(reviewRec, reviewReq)
	if reviewRec.Code != http.StatusOK {
		t.Fatalf("review status = %d, want 200 body=%s", reviewRec.Code, reviewRec.Body.String())
	}
	var reviewed model.UserRoute
	decodeJSON(t, reviewRec.Body.Bytes(), &reviewed)
	if reviewed.ModerationStatus != model.RouteModerationStatusApproved {
		t.Fatalf("reviewed status = %q, want approved", reviewed.ModerationStatus)
	}

	publicRec := httptest.NewRecorder()
	mux.ServeHTTP(publicRec, httptest.NewRequest(http.MethodGet, "/v1/user-routes/"+route.ID, nil))
	if publicRec.Code != http.StatusOK {
		t.Fatalf("approved public detail status = %d, want 200 body=%s", publicRec.Code, publicRec.Body.String())
	}
}

func TestAdminListAndReviewRoutesRequireModeratorRole(t *testing.T) {
	repo := app.NewMemoryUserRouteRepository()
	uc := app.NewUserRouteUseCase(repo)
	mux := muxForUseCase(uc)
	route := mustCreateHTTPRoute(t, uc, "owner-1", "Pending public", model.RouteVisibilityPublic)

	unauthorized := httptest.NewRecorder()
	mux.ServeHTTP(unauthorized, httptest.NewRequest(http.MethodGet, "/v1/admin/user-routes?status=pending", nil))
	if unauthorized.Code != http.StatusUnauthorized {
		t.Fatalf("admin list without user status = %d, want 401", unauthorized.Code)
	}

	forbiddenReq := httptest.NewRequest(http.MethodGet, "/v1/admin/user-routes?status=pending", nil)
	forbiddenReq.Header.Set("X-User-Id", "traveler-1")
	forbiddenReq.Header.Set("X-User-Roles", "USER")
	forbiddenRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenRec, forbiddenReq)
	if forbiddenRec.Code != http.StatusForbidden {
		t.Fatalf("admin list without role status = %d, want 403", forbiddenRec.Code)
	}

	listReq := httptest.NewRequest(http.MethodGet, "/v1/admin/user-routes?status=pending", nil)
	listReq.Header.Set("X-User-Id", "moderator-1")
	listReq.Header.Set("X-User-Roles", "MODERATOR")
	listRec := httptest.NewRecorder()
	mux.ServeHTTP(listRec, listReq)
	if listRec.Code != http.StatusOK {
		t.Fatalf("admin list status = %d, want 200 body=%s", listRec.Code, listRec.Body.String())
	}
	var page routeListResponse
	decodeJSON(t, listRec.Body.Bytes(), &page)
	if len(page.Items) != 1 || page.Items[0].ID != route.ID {
		t.Fatalf("admin pending list = %#v, want route %s", page.Items, route.ID)
	}

	reviewReq := httptest.NewRequest(http.MethodPost, "/v1/admin/user-routes/"+route.ID+"/review", bytes.NewReader([]byte(`{
		"decision":"reject",
		"reason":"Unsafe route"
	}`)))
	reviewReq.Header.Set("X-User-Id", "moderator-1")
	reviewReq.Header.Set("X-User-Roles", "MODERATOR")
	reviewRec := httptest.NewRecorder()
	mux.ServeHTTP(reviewRec, reviewReq)
	if reviewRec.Code != http.StatusOK {
		t.Fatalf("admin review status = %d, want 200 body=%s", reviewRec.Code, reviewRec.Body.String())
	}
	var reviewed model.UserRoute
	decodeJSON(t, reviewRec.Body.Bytes(), &reviewed)
	if reviewed.ModerationStatus != model.RouteModerationStatusRejected || reviewed.ModerationReason != "Unsafe route" {
		t.Fatalf("reviewed route = %#v", reviewed)
	}
}

func TestSaveAndCopyRouteUseTrustedUser(t *testing.T) {
	repo := app.NewMemoryUserRouteRepository()
	uc := app.NewUserRouteUseCase(repo)
	mux := muxForUseCase(uc)
	route := mustCreateHTTPRoute(t, uc, "owner-1", "Public", model.RouteVisibilityPublic)
	route = mustReviewHTTPRoute(t, uc, route.ID, "approve", "")

	saveReq := httptest.NewRequest(http.MethodPost, "/v1/user-routes/"+route.ID+"/save", nil)
	saveReq.Header.Set("X-User-Id", "user-2")
	saveRec := httptest.NewRecorder()
	mux.ServeHTTP(saveRec, saveReq)
	if saveRec.Code != http.StatusOK {
		t.Fatalf("save status = %d, want 200 body=%s", saveRec.Code, saveRec.Body.String())
	}
	var saved model.UserRoute
	decodeJSON(t, saveRec.Body.Bytes(), &saved)
	if !saved.SavedByMe || saved.Stats.SavesCount != 1 {
		t.Fatalf("expected saved route response, got %#v", saved)
	}

	copyReq := httptest.NewRequest(http.MethodPost, "/v1/user-routes/"+route.ID+"/copy", nil)
	copyReq.Header.Set("X-User-Id", "user-2")
	copyRec := httptest.NewRecorder()
	mux.ServeHTTP(copyRec, copyReq)
	if copyRec.Code != http.StatusCreated {
		t.Fatalf("copy status = %d, want 201 body=%s", copyRec.Code, copyRec.Body.String())
	}
	var copyRoute model.UserRoute
	decodeJSON(t, copyRec.Body.Bytes(), &copyRoute)
	if copyRoute.OwnerUserID != "user-2" || copyRoute.Visibility != model.RouteVisibilityPrivate {
		t.Fatalf("unexpected copied route: %#v", copyRoute)
	}
}

func TestUpdateRouteRequiresOwnerAndReturnsUpdatedRoute(t *testing.T) {
	repo := app.NewMemoryUserRouteRepository()
	uc := app.NewUserRouteUseCase(repo)
	mux := muxForUseCase(uc)
	route := mustCreateHTTPRoute(t, uc, "owner-1", "Public", model.RouteVisibilityPublic)
	route = mustReviewHTTPRoute(t, uc, route.ID, "approve", "")

	body := []byte(`{
		"title":"Public coffee walk",
		"description":"Shared route for a slow city walk.",
		"visibility":"public"
	}`)

	forbiddenReq := httptest.NewRequest(http.MethodPatch, "/v1/user-routes/"+route.ID, bytes.NewReader(body))
	forbiddenReq.Header.Set("X-User-Id", "user-2")
	forbiddenRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenRec, forbiddenReq)
	if forbiddenRec.Code != http.StatusForbidden {
		t.Fatalf("forbidden status = %d, want 403 body=%s", forbiddenRec.Code, forbiddenRec.Body.String())
	}

	updateReq := httptest.NewRequest(http.MethodPatch, "/v1/user-routes/"+route.ID, bytes.NewReader(body))
	updateReq.Header.Set("X-User-Id", "owner-1")
	updateRec := httptest.NewRecorder()
	mux.ServeHTTP(updateRec, updateReq)
	if updateRec.Code != http.StatusOK {
		t.Fatalf("update status = %d, want 200 body=%s", updateRec.Code, updateRec.Body.String())
	}
	var updated model.UserRoute
	decodeJSON(t, updateRec.Body.Bytes(), &updated)
	if updated.Title != "Public coffee walk" || updated.Visibility != model.RouteVisibilityPublic {
		t.Fatalf("unexpected updated route: %#v", updated)
	}
}

func newTestMux() *http.ServeMux {
	return muxForUseCase(app.NewUserRouteUseCase(app.NewMemoryUserRouteRepository()))
}

func muxForUseCase(uc *app.UserRouteUseCase) *http.ServeMux {
	mux := http.NewServeMux()
	NewHandler(uc).Register(mux)
	return mux
}

func mustCreateHTTPRoute(
	t *testing.T,
	uc *app.UserRouteUseCase,
	owner string,
	title string,
	visibility model.RouteVisibility,
) model.UserRoute {
	t.Helper()
	route, err := uc.CreateRoute(context.Background(), app.CreateRouteInput{
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

func mustReviewHTTPRoute(
	t *testing.T,
	uc *app.UserRouteUseCase,
	routeID string,
	decision string,
	reason string,
) model.UserRoute {
	t.Helper()
	route, err := uc.ReviewRoute(context.Background(), app.ReviewRouteInput{
		ActorUserID: "moderator-1",
		RouteID:     routeID,
		Decision:    decision,
		Reason:      reason,
	})
	if err != nil {
		t.Fatalf("ReviewRoute returned error: %v", err)
	}
	return route
}

func decodeJSON(t *testing.T, payload []byte, dst any) {
	t.Helper()
	if err := json.Unmarshal(payload, dst); err != nil {
		t.Fatalf("decode json: %v payload=%s", err, string(payload))
	}
}
