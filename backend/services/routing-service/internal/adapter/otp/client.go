package otp

import (
	"context"
	"fmt"

	"kz/inflap/backend/services/routing-service/internal/app"
	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

type Client struct {
	baseURL string
}

func New(baseURL string) *Client {
	return &Client{baseURL: baseURL}
}

func (c *Client) Name() app.EngineName {
	return app.EngineOTP
}

func (c *Client) Status(ctx context.Context) model.EngineStatus {
	return model.EngineStatus{
		Name:      string(c.Name()),
		Enabled:   true,
		Reachable: false,
		Status:    "not_implemented",
		Error:     "otp adapter is configured but transit routing is not implemented yet",
	}
}

func (c *Client) Route(ctx context.Context, req model.RouteRequest) (model.RouteResponse, error) {
	return model.RouteResponse{}, fmt.Errorf("otp adapter is configured at %s but transit routing is not implemented yet", c.baseURL)
}

func (c *Client) Matrix(ctx context.Context, req model.MatrixRequest) (model.MatrixResponse, error) {
	return model.MatrixResponse{}, fmt.Errorf("otp adapter is configured at %s but transit matrix is not implemented yet", c.baseURL)
}

func (c *Client) Isochrone(ctx context.Context, req model.IsochroneRequest) (model.IsochroneResponse, error) {
	return model.IsochroneResponse{}, fmt.Errorf("otp adapter does not support isochrones")
}

func (c *Client) OptimizeItinerary(ctx context.Context, req model.ItineraryOptimizationRequest) (model.ItineraryOptimizationResponse, error) {
	return model.ItineraryOptimizationResponse{}, fmt.Errorf("otp adapter does not support itinerary optimization")
}

func (c *Client) MapMatch(ctx context.Context, req model.MapMatchRequest) (model.MapMatchResponse, error) {
	return model.MapMatchResponse{}, fmt.Errorf("otp adapter does not support map matching")
}
