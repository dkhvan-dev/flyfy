package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

func TestUseCaseRoutesUserFacingRequestsThroughValhalla(t *testing.T) {
	valhalla := &fakeEngine{name: EngineValhalla}
	osrm := &fakeEngine{name: EngineOSRM}
	uc := NewRoutingUseCase(Dependencies{
		Valhalla: valhalla,
		OSRM:     osrm,
	})

	resp, err := uc.Route(context.Background(), validRouteRequest(model.RouteProfileTouristWalk))
	if err != nil {
		t.Fatalf("Route() error = %v", err)
	}
	if resp.Provider != string(EngineValhalla) {
		t.Fatalf("provider = %q, want %q", resp.Provider, EngineValhalla)
	}
	if valhalla.routeCalls != 1 {
		t.Fatalf("valhalla route calls = %d, want 1", valhalla.routeCalls)
	}
	if osrm.routeCalls != 0 {
		t.Fatalf("osrm route calls = %d, want 0", osrm.routeCalls)
	}
}

func TestUseCaseUsesOSRMForLargeDrivingMatrixAndFallsBackToValhalla(t *testing.T) {
	valhalla := &fakeEngine{name: EngineValhalla}
	osrm := &fakeEngine{name: EngineOSRM, matrixErr: errors.New("osrm timeout")}
	uc := NewRoutingUseCase(Dependencies{
		Valhalla: valhalla,
		OSRM:     osrm,
	})

	req := model.MatrixRequest{
		Mode:    model.RouteModeDriving,
		Profile: model.RouteProfileCarStandard,
		Origins: []model.RoutePoint{
			{Latitude: 43.238949, Longitude: 76.889709},
			{Latitude: 43.255058, Longitude: 76.912628},
		},
		Destinations: []model.RoutePoint{
			{Latitude: 43.219, Longitude: 76.851},
			{Latitude: 43.236, Longitude: 76.945},
			{Latitude: 43.263, Longitude: 76.929},
		},
	}

	resp, err := uc.Matrix(context.Background(), req)
	if err != nil {
		t.Fatalf("Matrix() error = %v", err)
	}
	if resp.Provider != string(EngineValhalla) {
		t.Fatalf("provider = %q, want fallback %q", resp.Provider, EngineValhalla)
	}
	if osrm.matrixCalls != 1 {
		t.Fatalf("osrm matrix calls = %d, want 1", osrm.matrixCalls)
	}
	if valhalla.matrixCalls != 1 {
		t.Fatalf("valhalla matrix calls = %d, want 1 fallback call", valhalla.matrixCalls)
	}
}

func TestUseCaseReturnsTransitUnavailableWhenOTPIsDisabled(t *testing.T) {
	uc := NewRoutingUseCase(Dependencies{
		Valhalla: &fakeEngine{name: EngineValhalla},
	})

	_, err := uc.Route(context.Background(), validRouteRequest(model.RouteProfileTransit))
	if !errors.Is(err, ErrTransitUnavailable) {
		t.Fatalf("Route() error = %v, want ErrTransitUnavailable", err)
	}
}

func TestUseCaseUsesReadThroughRouteCache(t *testing.T) {
	valhalla := &fakeEngine{name: EngineValhalla}
	cache := newMemoryRouteCacheStub()
	uc := NewRoutingUseCase(Dependencies{
		Valhalla:      valhalla,
		RouteCache:    cache,
		RouteCacheTTL: time.Minute,
	})

	req := validRouteRequest(model.RouteProfileTouristWalk)
	first, err := uc.Route(context.Background(), req)
	if err != nil {
		t.Fatalf("first Route() error = %v", err)
	}
	second, err := uc.Route(context.Background(), req)
	if err != nil {
		t.Fatalf("second Route() error = %v", err)
	}

	if first.Provider != second.Provider {
		t.Fatalf("cached provider = %q, want %q", second.Provider, first.Provider)
	}
	if valhalla.routeCalls != 1 {
		t.Fatalf("valhalla route calls = %d, want 1", valhalla.routeCalls)
	}
	if cache.setCalls != 1 {
		t.Fatalf("cache set calls = %d, want 1", cache.setCalls)
	}
}

func TestUseCaseWarnsWhenGuideRouteTimingIsUnrealistic(t *testing.T) {
	valhalla := &fakeEngine{
		name:                 EngineValhalla,
		routeDurationSeconds: int((5 * time.Hour).Seconds()),
	}
	uc := NewRoutingUseCase(Dependencies{
		Valhalla: valhalla,
	})

	resp, err := uc.Route(context.Background(), validRouteRequest(model.RouteProfileGuideRoute))
	if err != nil {
		t.Fatalf("Route() error = %v", err)
	}
	if len(resp.Warnings) != 1 {
		t.Fatalf("warnings = %v, want one unrealistic timing warning", resp.Warnings)
	}
	if resp.Warnings[0].Code != "guide_route_timing_unrealistic" {
		t.Fatalf("warning code = %q, want guide_route_timing_unrealistic", resp.Warnings[0].Code)
	}
}

func validRouteRequest(profile model.RouteProfile) model.RouteRequest {
	return model.RouteRequest{
		Profile: profile,
		Points: []model.RoutePoint{
			{Latitude: 43.238949, Longitude: 76.889709},
			{Latitude: 43.255058, Longitude: 76.912628},
		},
	}
}

type fakeEngine struct {
	name                 EngineName
	routeCalls           int
	matrixCalls          int
	matrixErr            error
	routeDurationSeconds int
}

func (f *fakeEngine) Name() EngineName {
	return f.name
}

func (f *fakeEngine) Route(ctx context.Context, req model.RouteRequest) (model.RouteResponse, error) {
	f.routeCalls++
	durationSeconds := f.routeDurationSeconds
	if durationSeconds == 0 {
		durationSeconds = 900
	}
	return model.RouteResponse{
		Provider:        string(f.name),
		Mode:            req.Mode,
		Profile:         req.Profile,
		DistanceMeters:  1200,
		DurationSeconds: durationSeconds,
		Geometry:        model.RouteGeometry{Encoding: "polyline6", Polyline: "encoded"},
	}, nil
}

func (f *fakeEngine) Matrix(ctx context.Context, req model.MatrixRequest) (model.MatrixResponse, error) {
	f.matrixCalls++
	if f.matrixErr != nil {
		return model.MatrixResponse{}, f.matrixErr
	}
	return model.MatrixResponse{
		Provider: string(f.name),
		Rows: []model.MatrixRow{
			{Cells: []model.MatrixCell{{DistanceMeters: 1200, DurationSeconds: 900}}},
		},
	}, nil
}

func (f *fakeEngine) Isochrone(ctx context.Context, req model.IsochroneRequest) (model.IsochroneResponse, error) {
	return model.IsochroneResponse{Provider: string(f.name)}, nil
}

func (f *fakeEngine) OptimizeItinerary(ctx context.Context, req model.ItineraryOptimizationRequest) (model.ItineraryOptimizationResponse, error) {
	return model.ItineraryOptimizationResponse{Provider: string(f.name)}, nil
}

func (f *fakeEngine) MapMatch(ctx context.Context, req model.MapMatchRequest) (model.MapMatchResponse, error) {
	return model.MapMatchResponse{Provider: string(f.name)}, nil
}

type memoryRouteCacheStub struct {
	routes   map[string]model.RouteResponse
	setCalls int
}

func newMemoryRouteCacheStub() *memoryRouteCacheStub {
	return &memoryRouteCacheStub{routes: make(map[string]model.RouteResponse)}
}

func (c *memoryRouteCacheStub) Get(_ context.Context, key string, dst any) (bool, error) {
	route, ok := c.routes[key]
	if !ok {
		return false, nil
	}
	target, ok := dst.(*model.RouteResponse)
	if !ok {
		return false, nil
	}
	*target = route
	return true, nil
}

func (c *memoryRouteCacheStub) Set(_ context.Context, key string, value any) error {
	c.setCalls++
	route, ok := value.(model.RouteResponse)
	if !ok {
		return nil
	}
	c.routes[key] = route
	return nil
}
