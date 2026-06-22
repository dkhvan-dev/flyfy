package http

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	stdhttp "net/http"
	"net/http/httptest"
	"testing"

	"kz/inflap/backend/services/routing-service/internal/app"
	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

func TestHandlerExposesRouteProfiles(t *testing.T) {
	handler := NewHandler(&fakeRoutingUseCase{})
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(stdhttp.MethodGet, "/v1/route-profiles", nil)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusOK {
		t.Fatalf("status = %d, want %d; body = %s", rec.Code, stdhttp.StatusOK, rec.Body.String())
	}

	var got []model.RouteProfileInfo
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode route profiles: %v", err)
	}
	if len(got) != 7 {
		t.Fatalf("profile count = %d, want 7", len(got))
	}
}

func TestHandlerExposesRoutingStatusWithEngineAndDataMetadata(t *testing.T) {
	handler := NewHandler(&fakeRoutingUseCase{
		status: model.RoutingStatusResponse{
			Status: "degraded",
			Engines: []model.EngineStatus{
				{
					Name:      "valhalla",
					Enabled:   true,
					Reachable: true,
					Status:    "ok",
					Version:   "3.1.4",
				},
				{
					Name:      "opentripplanner",
					Enabled:   false,
					Reachable: false,
					Status:    "disabled",
				},
			},
			Data: model.RoutingDataStatus{
				Region:              "kazakhstan",
				OSMSource:           "geofabrik:kazakhstan",
				OSMDataVersion:      "2026-06-20",
				TransitEnabled:      true,
				TransitCityCode:     "ALA",
				GTFSVersion:         "almaty-gtfs-2026-06-21",
				AttributionRequired: true,
			},
		},
	})
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(stdhttp.MethodGet, "/v1/status", nil)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusOK {
		t.Fatalf("status = %d, want %d; body = %s", rec.Code, stdhttp.StatusOK, rec.Body.String())
	}
	var got model.RoutingStatusResponse
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode routing status: %v", err)
	}
	if got.Status != "degraded" {
		t.Fatalf("status = %q, want degraded", got.Status)
	}
	if len(got.Engines) != 2 || got.Engines[0].Name != "valhalla" || !got.Engines[0].Reachable {
		t.Fatalf("engines = %#v", got.Engines)
	}
	if got.Data.OSMDataVersion != "2026-06-20" || !got.Data.AttributionRequired {
		t.Fatalf("data = %#v", got.Data)
	}
	if !got.Data.TransitEnabled || got.Data.TransitCityCode != "ALA" || got.Data.GTFSVersion != "almaty-gtfs-2026-06-21" {
		t.Fatalf("transit data = %#v", got.Data)
	}
}

func TestHandlerBuildsRouteAndKeepsEngineBehindInflapAPI(t *testing.T) {
	uc := &fakeRoutingUseCase{}
	handler := NewHandler(uc)
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"profile": "tourist_walk",
		"points": [
			{"latitude": 43.238949, "longitude": 76.889709, "name": "Hotel"},
			{"latitude": 43.255058, "longitude": 76.912628, "name": "Kok Tobe"}
		]
	}`)
	req := httptest.NewRequest(stdhttp.MethodPost, "/v1/routes", bytes.NewReader(body))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusOK {
		t.Fatalf("status = %d, want %d; body = %s", rec.Code, stdhttp.StatusOK, rec.Body.String())
	}
	if uc.lastRoute.Profile != model.RouteProfileTouristWalk {
		t.Fatalf("profile = %q, want tourist_walk", uc.lastRoute.Profile)
	}
	var got model.RouteResponse
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode route response: %v", err)
	}
	if got.Provider != string(app.EngineValhalla) {
		t.Fatalf("provider = %q, want %q", got.Provider, app.EngineValhalla)
	}
	if got.Geometry.Encoding != "polyline6" || got.Geometry.Polyline == "" {
		t.Fatalf("geometry = %#v, want encoded polyline geometry", got.Geometry)
	}
}

func TestHandlerMapsTransitUnavailableToBusinessError(t *testing.T) {
	handler := NewHandler(&fakeRoutingUseCase{routeErr: app.ErrTransitUnavailable})
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"profile": "transit",
		"points": [
			{"latitude": 43.238949, "longitude": 76.889709},
			{"latitude": 43.255058, "longitude": 76.912628}
		]
	}`)
	req := httptest.NewRequest(stdhttp.MethodPost, "/v1/routes", bytes.NewReader(body))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d; body = %s", rec.Code, stdhttp.StatusServiceUnavailable, rec.Body.String())
	}
	var got errorResponse
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode error: %v", err)
	}
	if got.Code != "routing.transit_unavailable" || got.Kind != "business" {
		t.Fatalf("error = %#v, want routing.transit_unavailable business error", got)
	}
}

func TestHandlerRejectsInvalidCoordinates(t *testing.T) {
	handler := NewHandler(&fakeRoutingUseCase{})
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	body := []byte(`{
		"profile": "tourist_walk",
		"points": [
			{"latitude": 143.238949, "longitude": 76.889709},
			{"latitude": 43.255058, "longitude": 76.912628}
		]
	}`)
	req := httptest.NewRequest(stdhttp.MethodPost, "/v1/routes", bytes.NewReader(body))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != stdhttp.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body = %s", rec.Code, stdhttp.StatusBadRequest, rec.Body.String())
	}
	var got errorResponse
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode error: %v", err)
	}
	if got.Code != "routing.invalid_request" {
		t.Fatalf("code = %q, want routing.invalid_request", got.Code)
	}
}

type fakeRoutingUseCase struct {
	lastRoute model.RouteRequest
	routeErr  error
	status    model.RoutingStatusResponse
}

func (f *fakeRoutingUseCase) Status(ctx context.Context) model.RoutingStatusResponse {
	if f.status.Status != "" {
		return f.status
	}
	return model.RoutingStatusResponse{Status: "ok"}
}

func (f *fakeRoutingUseCase) Route(ctx context.Context, req model.RouteRequest) (model.RouteResponse, error) {
	f.lastRoute = req
	if f.routeErr != nil {
		return model.RouteResponse{}, f.routeErr
	}
	return model.RouteResponse{
		Provider:        string(app.EngineValhalla),
		Mode:            req.Mode,
		Profile:         req.Profile,
		DistanceMeters:  1200,
		DurationSeconds: 900,
		Geometry: model.RouteGeometry{
			Encoding: "polyline6",
			Polyline: "encoded-polyline",
		},
	}, nil
}

func (f *fakeRoutingUseCase) ETA(ctx context.Context, req model.ETARequest) (model.ETAResponse, error) {
	return model.ETAResponse{Provider: string(app.EngineValhalla)}, nil
}

func (f *fakeRoutingUseCase) Matrix(ctx context.Context, req model.MatrixRequest) (model.MatrixResponse, error) {
	return model.MatrixResponse{Provider: string(app.EngineValhalla)}, nil
}

func (f *fakeRoutingUseCase) Isochrone(ctx context.Context, req model.IsochroneRequest) (model.IsochroneResponse, error) {
	return model.IsochroneResponse{Provider: string(app.EngineValhalla)}, nil
}

func (f *fakeRoutingUseCase) OptimizeItinerary(ctx context.Context, req model.ItineraryOptimizationRequest) (model.ItineraryOptimizationResponse, error) {
	return model.ItineraryOptimizationResponse{Provider: string(app.EngineValhalla)}, nil
}

func (f *fakeRoutingUseCase) MapMatch(ctx context.Context, req model.MapMatchRequest) (model.MapMatchResponse, error) {
	return model.MapMatchResponse{}, errors.New("not implemented in fake")
}
