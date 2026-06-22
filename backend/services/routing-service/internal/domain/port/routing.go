package port

import (
	"context"

	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

type RoutingEngine interface {
	Route(ctx context.Context, req model.RouteRequest) (model.RouteResponse, error)
}

type MatrixEngine interface {
	Matrix(ctx context.Context, req model.MatrixRequest) (model.MatrixResponse, error)
}

type IsochroneEngine interface {
	Isochrone(ctx context.Context, req model.IsochroneRequest) (model.IsochroneResponse, error)
}

type ItineraryEngine interface {
	OptimizeItinerary(ctx context.Context, req model.ItineraryOptimizationRequest) (model.ItineraryOptimizationResponse, error)
}

type MapMatchEngine interface {
	MapMatch(ctx context.Context, req model.MapMatchRequest) (model.MapMatchResponse, error)
}

type RouteCache interface {
	Get(ctx context.Context, key string, dst any) (bool, error)
	Set(ctx context.Context, key string, value any) error
}
