package valhalla

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kz/inflap/backend/services/routing-service/internal/app"
	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

func TestOptimizeItineraryUsesValhallaOptimizedRouteAndOrdersStops(t *testing.T) {
	var requestedPath string
	var requestedPayload map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestedPath = r.URL.Path
		if err := json.NewDecoder(r.Body).Decode(&requestedPayload); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		writeValhallaJSON(t, w, map[string]any{
			"locations": []map[string]any{
				{"lat": 43.200, "lon": 76.800, "original_index": 0},
				{"lat": 43.220, "lon": 76.820, "original_index": 2},
				{"lat": 43.210, "lon": 76.810, "original_index": 1},
				{"lat": 43.230, "lon": 76.830, "original_index": 3},
				{"lat": 43.240, "lon": 76.840, "original_index": 4},
			},
			"trip": valhallaTripJSON(4.2, 1800, []string{"??AA", "AAAC", "ACAE", "AEAG"}),
		})
	}))
	defer server.Close()

	client, err := New(server.URL, time.Second)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	start := model.RoutePoint{Latitude: 43.200, Longitude: 76.800, Name: "Hotel"}
	end := model.RoutePoint{Latitude: 43.240, Longitude: 76.840, Name: "Finish"}
	req := model.ItineraryOptimizationRequest{
		Profile: model.RouteProfileDayPlan,
		Start:   &start,
		Stops: []model.RoutePoint{
			{Latitude: 43.210, Longitude: 76.810, Name: "First stop"},
			{Latitude: 43.220, Longitude: 76.820, Name: "Second stop"},
			{Latitude: 43.230, Longitude: 76.830, Name: "Third stop"},
		},
		End: &end,
	}

	resp, err := client.OptimizeItinerary(context.Background(), req)
	if err != nil {
		t.Fatalf("OptimizeItinerary() error = %v", err)
	}

	if requestedPath != "/optimized_route" {
		t.Fatalf("path = %q, want /optimized_route", requestedPath)
	}
	if got := len(requestedPayload["locations"].([]any)); got != 5 {
		t.Fatalf("locations count = %d, want 5", got)
	}
	if resp.OrderedStops[0].Name != "Second stop" ||
		resp.OrderedStops[1].Name != "First stop" ||
		resp.OrderedStops[2].Name != "Third stop" {
		t.Fatalf("ordered stops = %+v", resp.OrderedStops)
	}
	if resp.Route.DistanceMeters != 4200 {
		t.Fatalf("distance meters = %.1f, want 4200", resp.Route.DistanceMeters)
	}
	if len(resp.Route.Legs) != 4 {
		t.Fatalf("route legs = %d, want 4", len(resp.Route.Legs))
	}
}

func TestOptimizeItineraryFallsBackToRouteForSmallItineraries(t *testing.T) {
	var requestedPath string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestedPath = r.URL.Path
		writeValhallaJSON(t, w, map[string]any{
			"trip": valhallaTripJSON(1.3, 600, []string{"??AA", "AAAC"}),
		})
	}))
	defer server.Close()

	client, err := New(server.URL, time.Second)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	start := model.RoutePoint{Latitude: 43.200, Longitude: 76.800, Name: "Start"}
	end := model.RoutePoint{Latitude: 43.220, Longitude: 76.820, Name: "End"}
	req := model.ItineraryOptimizationRequest{
		Profile: model.RouteProfileGuideRoute,
		Start:   &start,
		Stops: []model.RoutePoint{
			{Latitude: 43.210, Longitude: 76.810, Name: "Only stop"},
		},
		End: &end,
	}

	resp, err := client.OptimizeItinerary(context.Background(), req)
	if err != nil {
		t.Fatalf("OptimizeItinerary() error = %v", err)
	}

	if requestedPath != "/route" {
		t.Fatalf("path = %q, want /route", requestedPath)
	}
	if len(resp.OrderedStops) != 1 || resp.OrderedStops[0].Name != "Only stop" {
		t.Fatalf("ordered stops = %+v", resp.OrderedStops)
	}
}

func TestRouteAcceptsFractionalValhallaSeconds(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		writeValhallaJSON(t, w, map[string]any{
			"trip": map[string]any{
				"summary": map[string]any{"length": 3.489, "time": 2496.041},
				"legs": []map[string]any{
					{
						"summary": map[string]any{"length": 3.489, "time": 2496.041},
						"shape":   "encoded-shape",
						"maneuvers": []map[string]any{
							{"instruction": "Walk north.", "length": 0.264, "time": 186.352},
						},
					},
				},
			},
		})
	}))
	defer server.Close()

	client, err := New(server.URL, time.Second)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	resp, err := client.Route(context.Background(), model.RouteRequest{
		Profile: model.RouteProfileTouristWalk,
		Mode:    model.RouteModeWalking,
		Points: []model.RoutePoint{
			{Latitude: 43.238949, Longitude: 76.889709},
			{Latitude: 43.255058, Longitude: 76.912628},
		},
	})
	if err != nil {
		t.Fatalf("Route() error = %v", err)
	}

	if resp.DurationSeconds != 2496 {
		t.Fatalf("duration seconds = %d, want rounded fractional Valhalla seconds", resp.DurationSeconds)
	}
	if got := resp.Legs[0].Steps[0].DurationSeconds; got != 186 {
		t.Fatalf("step duration seconds = %d, want rounded fractional Valhalla seconds", got)
	}
}

func TestRouteMapsValhallaBadRequestToInvalidRequest(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/route" {
			t.Fatalf("path = %q, want /route", r.URL.Path)
		}
		http.Error(w, "Path distance exceeds the max distance limit: 250000 meters", http.StatusBadRequest)
	}))
	defer server.Close()

	client, err := New(server.URL, time.Second)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	_, err = client.Route(context.Background(), model.RouteRequest{
		Profile: model.RouteProfileGuideRoute,
		Mode:    model.RouteModeWalking,
		Points: []model.RoutePoint{
			{Latitude: 43.238949, Longitude: 76.889709},
			{Latitude: 51.12822, Longitude: 71.430668},
		},
	})
	if !errors.Is(err, model.ErrInvalidRequest) {
		t.Fatalf("Route() error = %v, want ErrInvalidRequest", err)
	}
}

func TestStatusUsesValhallaStatusEndpoint(t *testing.T) {
	var requestedPath string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestedPath = r.URL.Path
		writeValhallaJSON(t, w, map[string]any{
			"version":               "3.1.4",
			"tileset_last_modified": 1782000000,
			"has_tiles":             true,
		})
	}))
	defer server.Close()

	client, err := New(server.URL, time.Second)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	status := client.Status(context.Background())

	if requestedPath != "/status" {
		t.Fatalf("path = %q, want /status", requestedPath)
	}
	if status.Name != string(app.EngineValhalla) || !status.Reachable || status.Status != "ok" {
		t.Fatalf("status = %#v", status)
	}
	if status.Version != "3.1.4" {
		t.Fatalf("version = %q, want 3.1.4", status.Version)
	}
}

func valhallaTripJSON(length float64, seconds int, shapes []string) map[string]any {
	legs := make([]map[string]any, 0, len(shapes))
	for _, shape := range shapes {
		legs = append(legs, map[string]any{
			"summary": map[string]any{"length": length / float64(len(shapes)), "time": seconds / len(shapes)},
			"shape":   shape,
			"maneuvers": []map[string]any{
				{"instruction": "Continue", "length": length / float64(len(shapes)), "time": seconds / len(shapes)},
			},
		})
	}
	return map[string]any{
		"summary": map[string]any{"length": length, "time": seconds},
		"legs":    legs,
	}
}

func writeValhallaJSON(t *testing.T, w http.ResponseWriter, payload any) {
	t.Helper()
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		t.Fatalf("encode response: %v", err)
	}
}
