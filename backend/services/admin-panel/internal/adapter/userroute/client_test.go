package userroute

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestClientListUserRoutesSendsFiltersAndActorHeaders(t *testing.T) {
	t.Parallel()

	routeID := uuid.New()
	ownerID := uuid.New()
	var gotMethod string
	var gotPath string
	var gotUserID string
	var gotRoles string
	var gotInternalToken string

	client := NewClient("https://routes.internal", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotMethod = r.Method
		gotPath = r.URL.String()
		gotUserID = r.Header.Get("X-User-Id")
		gotRoles = r.Header.Get("X-User-Roles")
		gotInternalToken = r.Header.Get("X-Internal-Service-Token")
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body: io.NopCloser(strings.NewReader(`{"items":[{
				"id":"` + routeID.String() + `",
				"ownerUserId":"` + ownerID.String() + `",
				"title":"Coffee walk",
				"description":"Best morning stops",
				"visibility":"public",
				"moderationStatus":"pending",
				"cityCode":"ala",
				"points":[
					{"name":"Start","latitude":43.238,"longitude":76.945},
					{"name":"Finish","latitude":43.245,"longitude":76.958}
				],
				"snapshot":{"distanceMeters":1200,"durationSeconds":900},
				"createdAt":"2026-06-22T03:00:00Z",
				"updatedAt":"2026-06-22T03:05:00Z"
			}]}`)),
		}, nil
	})

	items, err := client.ListUserRoutes(context.Background(), model.AdminUserRouteAdminListRequest{
		ActorUserID:      ownerID.String(),
		ActorRoles:       []string{"MODERATOR"},
		ModerationStatus: model.UserRouteModerationPending,
		OwnerUserID:      ownerID.String(),
		CityCode:         "ala",
		Limit:            25,
		Offset:           5,
	})

	if err != nil {
		t.Fatalf("ListUserRoutes() error = %v", err)
	}
	if gotMethod != http.MethodGet {
		t.Fatalf("method = %s, want GET", gotMethod)
	}
	for _, expected := range []string{
		"/v1/admin/user-routes?",
		"status=pending",
		"ownerUserId=" + ownerID.String(),
		"cityCode=ala",
		"limit=25",
		"offset=5",
	} {
		if !strings.Contains(gotPath, expected) {
			t.Fatalf("path = %q, missing %q", gotPath, expected)
		}
	}
	if gotUserID != ownerID.String() || gotRoles != "MODERATOR" {
		t.Fatalf("actor headers = %q/%q, want user id and MODERATOR", gotUserID, gotRoles)
	}
	if gotInternalToken != "internal-token" {
		t.Fatalf("internal token = %q, want configured token", gotInternalToken)
	}
	if len(items) != 1 || items[0].ID != routeID || items[0].OwnerUserID != ownerID {
		t.Fatalf("items = %+v, want decoded route and owner", items)
	}
	if items[0].ModerationStatus != model.UserRouteModerationPending ||
		items[0].DistanceMeters != 1200 ||
		items[0].DurationSeconds != 900 ||
		len(items[0].Points) != 2 ||
		items[0].Points[0].Label != "Start" {
		t.Fatalf("decoded item = %+v, want moderation status, snapshot and points", items[0])
	}
}

func TestClientReviewUserRoutePostsDecisionPayload(t *testing.T) {
	t.Parallel()

	routeID := uuid.New()
	actorID := uuid.New()
	var gotMethod string
	var gotPath string
	var gotUserID string
	var gotRoles string
	var gotPayload map[string]any

	client := NewClient("https://routes.internal", time.Second, "internal-token")
	client.httpClient.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		gotMethod = r.Method
		gotPath = r.URL.Path
		gotUserID = r.Header.Get("X-User-Id")
		gotRoles = r.Header.Get("X-User-Roles")
		if err := json.NewDecoder(r.Body).Decode(&gotPayload); err != nil {
			t.Fatalf("decode payload: %v", err)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body: io.NopCloser(strings.NewReader(`{
				"id":"` + routeID.String() + `",
				"ownerUserId":"` + uuid.NewString() + `",
				"title":"Sunset route",
				"visibility":"public",
				"moderationStatus":"rejected",
				"moderationReason":"Unsafe content",
				"points":[
					{"name":"A","latitude":43.238,"longitude":76.945},
					{"name":"B","latitude":43.245,"longitude":76.958}
				],
				"createdAt":"2026-06-22T03:00:00Z",
				"updatedAt":"2026-06-22T03:10:00Z"
			}`)),
		}, nil
	})

	item, err := client.ReviewUserRoute(context.Background(), model.AdminUserRouteAdminReviewRequest{
		ActorUserID: actorID.String(),
		ActorRoles:  []string{"ADMIN"},
		RouteID:     routeID,
		Decision:    model.UserRouteReviewReject,
		Reason:      "Unsafe content",
	})

	if err != nil {
		t.Fatalf("ReviewUserRoute() error = %v", err)
	}
	if gotMethod != http.MethodPost || gotPath != "/v1/admin/user-routes/"+routeID.String()+"/review" {
		t.Fatalf("request = %s %s, want review endpoint", gotMethod, gotPath)
	}
	if gotUserID != actorID.String() || gotRoles != "ADMIN" {
		t.Fatalf("actor headers = %q/%q, want admin actor", gotUserID, gotRoles)
	}
	if gotPayload["decision"] != "reject" || gotPayload["reason"] != "Unsafe content" {
		t.Fatalf("payload = %+v, want reject reason", gotPayload)
	}
	if item == nil || item.ID != routeID || item.ModerationStatus != model.UserRouteModerationRejected {
		t.Fatalf("item = %+v, want rejected route", item)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}
