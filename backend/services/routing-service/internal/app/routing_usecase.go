package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"

	"kz/inflap/backend/services/routing-service/internal/domain/model"
	"kz/inflap/backend/services/routing-service/internal/domain/port"
)

type EngineName string

const (
	EngineValhalla EngineName = "valhalla"
	EngineOSRM     EngineName = "osrm"
	EngineOTP      EngineName = "opentripplanner"
)

const (
	guideRouteUnrealisticTimingWarningCode = "guide_route_timing_unrealistic"
	guideRouteUnrealisticTimingMessage     = "This guide route may be too long for a comfortable walking excursion. Consider shortening the route or adding transport."
	guideRouteMaxComfortableDuration       = 4 * time.Hour
	guideRouteMaxComfortableLegDuration    = 90 * time.Minute
)

type Engine interface {
	port.RoutingEngine
	port.MatrixEngine
	port.IsochroneEngine
	port.ItineraryEngine
	port.MapMatchEngine
	Name() EngineName
}

type EngineStatusProvider interface {
	Status(ctx context.Context) model.EngineStatus
}

type Dependencies struct {
	Valhalla      Engine
	OSRM          Engine
	OTP           Engine
	RouteCache    port.RouteCache
	RouteCacheTTL time.Duration
	DataStatus    model.RoutingDataStatus
}

type RoutingUseCase struct {
	valhalla      Engine
	osrm          Engine
	otp           Engine
	routeCache    port.RouteCache
	routeCacheTTL time.Duration
	dataStatus    model.RoutingDataStatus
}

func NewRoutingUseCase(deps Dependencies) *RoutingUseCase {
	return &RoutingUseCase{
		valhalla:      deps.Valhalla,
		osrm:          deps.OSRM,
		otp:           deps.OTP,
		routeCache:    deps.RouteCache,
		routeCacheTTL: deps.RouteCacheTTL,
		dataStatus:    deps.DataStatus,
	}
}

func (uc *RoutingUseCase) Status(ctx context.Context) model.RoutingStatusResponse {
	engines := []model.EngineStatus{
		uc.engineStatus(ctx, EngineValhalla, uc.valhalla),
		uc.engineStatus(ctx, EngineOSRM, uc.osrm),
		uc.engineStatus(ctx, EngineOTP, uc.otp),
	}
	status := model.RoutingStatusOK
	if uc.valhalla == nil {
		status = model.RoutingStatusDegraded
	}
	for _, engine := range engines {
		if engine.Enabled && (!engine.Reachable || engine.Status == "error") {
			status = model.RoutingStatusDegraded
			break
		}
	}
	data := uc.dataStatus
	if !data.AttributionRequired {
		data.AttributionRequired = true
	}
	return model.RoutingStatusResponse{
		Status:  status,
		Engines: engines,
		Data:    data,
	}
}

func (uc *RoutingUseCase) Route(ctx context.Context, req model.RouteRequest) (model.RouteResponse, error) {
	if err := req.NormalizeAndValidate(); err != nil {
		return model.RouteResponse{}, err
	}
	if req.Mode == model.RouteModeTransit || req.Profile == model.RouteProfileTransit {
		if uc.otp == nil {
			return model.RouteResponse{}, ErrTransitUnavailable
		}
		return uc.otp.Route(ctx, req)
	}
	engine, err := uc.primaryRoutingEngine()
	if err != nil {
		return model.RouteResponse{}, err
	}
	cacheKey, cacheOK := routeCacheKey(req)
	if cacheOK && uc.routeCache != nil && uc.routeCacheTTL > 0 {
		var cached model.RouteResponse
		if hit, err := uc.routeCache.Get(ctx, cacheKey, &cached); err == nil && hit {
			return withRoutePolicyWarnings(req, cached), nil
		}
	}
	resp, err := engine.Route(ctx, req)
	if err != nil {
		return model.RouteResponse{}, err
	}
	resp = withRoutePolicyWarnings(req, resp)
	if cacheOK && uc.routeCache != nil && uc.routeCacheTTL > 0 {
		_ = uc.routeCache.Set(ctx, cacheKey, resp)
	}
	return resp, nil
}

func withRoutePolicyWarnings(req model.RouteRequest, resp model.RouteResponse) model.RouteResponse {
	if req.Profile != model.RouteProfileGuideRoute || req.Mode != model.RouteModeWalking {
		return resp
	}
	if hasRouteWarning(resp, guideRouteUnrealisticTimingWarningCode) {
		return resp
	}
	if !guideRouteTimingLooksUnrealistic(resp) {
		return resp
	}
	resp.Warnings = append(resp.Warnings, model.RouteWarning{
		Code:    guideRouteUnrealisticTimingWarningCode,
		Message: guideRouteUnrealisticTimingMessage,
	})
	return resp
}

func guideRouteTimingLooksUnrealistic(resp model.RouteResponse) bool {
	if resp.DurationSeconds > int(guideRouteMaxComfortableDuration.Seconds()) {
		return true
	}
	for _, leg := range resp.Legs {
		if leg.DurationSeconds > int(guideRouteMaxComfortableLegDuration.Seconds()) {
			return true
		}
	}
	return false
}

func hasRouteWarning(resp model.RouteResponse, code string) bool {
	for _, warning := range resp.Warnings {
		if warning.Code == code {
			return true
		}
	}
	return false
}

func (uc *RoutingUseCase) ETA(ctx context.Context, req model.ETARequest) (model.ETAResponse, error) {
	if err := req.NormalizeAndValidate(); err != nil {
		return model.ETAResponse{}, err
	}
	route, err := uc.Route(ctx, req.ToRouteRequest())
	if err != nil {
		return model.ETAResponse{}, err
	}
	return model.ETAResponse{
		Provider:        route.Provider,
		Mode:            route.Mode,
		Profile:         route.Profile,
		DistanceMeters:  route.DistanceMeters,
		DurationSeconds: route.DurationSeconds,
	}, nil
}

func (uc *RoutingUseCase) Matrix(ctx context.Context, req model.MatrixRequest) (model.MatrixResponse, error) {
	if err := req.NormalizeAndValidate(); err != nil {
		return model.MatrixResponse{}, err
	}
	if req.Mode == model.RouteModeTransit || req.Profile == model.RouteProfileTransit {
		if uc.otp == nil {
			return model.MatrixResponse{}, ErrTransitUnavailable
		}
		return uc.otp.Matrix(ctx, req)
	}
	if uc.shouldUseOSRM(req) {
		resp, err := uc.osrm.Matrix(ctx, req)
		if err == nil {
			return resp, nil
		}
	}
	engine, err := uc.primaryRoutingEngine()
	if err != nil {
		return model.MatrixResponse{}, err
	}
	return engine.Matrix(ctx, req)
}

func (uc *RoutingUseCase) Isochrone(ctx context.Context, req model.IsochroneRequest) (model.IsochroneResponse, error) {
	if err := req.NormalizeAndValidate(); err != nil {
		return model.IsochroneResponse{}, err
	}
	engine, err := uc.primaryRoutingEngine()
	if err != nil {
		return model.IsochroneResponse{}, err
	}
	return engine.Isochrone(ctx, req)
}

func (uc *RoutingUseCase) OptimizeItinerary(ctx context.Context, req model.ItineraryOptimizationRequest) (model.ItineraryOptimizationResponse, error) {
	if err := req.NormalizeAndValidate(); err != nil {
		return model.ItineraryOptimizationResponse{}, err
	}
	engine, err := uc.primaryRoutingEngine()
	if err != nil {
		return model.ItineraryOptimizationResponse{}, err
	}
	return engine.OptimizeItinerary(ctx, req)
}

func (uc *RoutingUseCase) MapMatch(ctx context.Context, req model.MapMatchRequest) (model.MapMatchResponse, error) {
	if err := req.NormalizeAndValidate(); err != nil {
		return model.MapMatchResponse{}, err
	}
	engine, err := uc.primaryRoutingEngine()
	if err != nil {
		return model.MapMatchResponse{}, err
	}
	return engine.MapMatch(ctx, req)
}

func (uc *RoutingUseCase) primaryRoutingEngine() (Engine, error) {
	if uc.valhalla == nil {
		return nil, fmt.Errorf("%w: valhalla is not configured", ErrEngineUnavailable)
	}
	return uc.valhalla, nil
}

func (uc *RoutingUseCase) shouldUseOSRM(req model.MatrixRequest) bool {
	if uc.osrm == nil {
		return false
	}
	return req.Mode == model.RouteModeDriving &&
		req.Profile == model.RouteProfileCarStandard &&
		req.PairCount() >= 4
}

func routeCacheKey(req model.RouteRequest) (string, bool) {
	payload, err := json.Marshal(req)
	if err != nil {
		return "", false
	}
	sum := sha256.Sum256(payload)
	return "route:" + hex.EncodeToString(sum[:]), true
}

func (uc *RoutingUseCase) engineStatus(ctx context.Context, name EngineName, engine Engine) model.EngineStatus {
	if engine == nil {
		return model.EngineStatus{
			Name:    string(name),
			Enabled: false,
			Status:  "disabled",
		}
	}
	if provider, ok := engine.(EngineStatusProvider); ok {
		status := provider.Status(ctx)
		if status.Name == "" {
			status.Name = string(name)
		}
		status.Enabled = true
		return status
	}
	return model.EngineStatus{
		Name:      string(name),
		Enabled:   true,
		Reachable: true,
		Status:    "unknown",
	}
}
