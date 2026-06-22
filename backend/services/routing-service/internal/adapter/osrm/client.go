package osrm

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"kz/inflap/backend/services/routing-service/internal/app"
	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

type Client struct {
	baseURL    string
	httpClient *http.Client
}

func New(baseURL string, timeout time.Duration) (*Client, error) {
	parsed, err := url.Parse(strings.TrimSpace(baseURL))
	if err != nil {
		return nil, fmt.Errorf("parse osrm url: %w", err)
	}
	if parsed.Scheme == "" || parsed.Host == "" {
		return nil, fmt.Errorf("parse osrm url: missing scheme or host")
	}
	return &Client{
		baseURL: strings.TrimRight(parsed.String(), "/"),
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}, nil
}

func (c *Client) Name() app.EngineName {
	return app.EngineOSRM
}

func (c *Client) Status(ctx context.Context) model.EngineStatus {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/", nil)
	if err != nil {
		return model.EngineStatus{
			Name:    string(c.Name()),
			Enabled: true,
			Status:  "error",
			Error:   err.Error(),
		}
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return model.EngineStatus{
			Name:    string(c.Name()),
			Enabled: true,
			Status:  "error",
			Error:   err.Error(),
		}
	}
	defer resp.Body.Close()

	if resp.StatusCode >= http.StatusInternalServerError {
		return model.EngineStatus{
			Name:      string(c.Name()),
			Enabled:   true,
			Reachable: true,
			Status:    "error",
			Error:     fmt.Sprintf("status probe returned %d", resp.StatusCode),
		}
	}

	return model.EngineStatus{
		Name:      string(c.Name()),
		Enabled:   true,
		Reachable: true,
		Status:    "ok",
	}
}

func (c *Client) Route(ctx context.Context, req model.RouteRequest) (model.RouteResponse, error) {
	endpoint := fmt.Sprintf("%s/route/v1/%s/%s?overview=full&geometries=polyline6&steps=true",
		c.baseURL,
		osrmProfile(req.Mode),
		coordinates(req.Points),
	)

	var out osrmRouteResponse
	if err := c.get(ctx, endpoint, &out); err != nil {
		return model.RouteResponse{}, err
	}
	if len(out.Routes) == 0 {
		return model.RouteResponse{}, fmt.Errorf("osrm returned no route")
	}

	route := out.Routes[0]
	return model.RouteResponse{
		Provider:        string(c.Name()),
		Mode:            req.Mode,
		Profile:         req.Profile,
		DistanceMeters:  route.Distance,
		DurationSeconds: int(route.Duration + 0.5),
		Geometry:        model.RouteGeometry{Encoding: "polyline6", Polyline: route.Geometry},
	}, nil
}

func (c *Client) Matrix(ctx context.Context, req model.MatrixRequest) (model.MatrixResponse, error) {
	points := append([]model.RoutePoint{}, req.Origins...)
	points = append(points, req.Destinations...)
	sourceIndexes := indexes(0, len(req.Origins))
	destinationIndexes := indexes(len(req.Origins), len(req.Destinations))

	endpoint := fmt.Sprintf("%s/table/v1/%s/%s?annotations=duration,distance&sources=%s&destinations=%s",
		c.baseURL,
		osrmProfile(req.Mode),
		coordinates(points),
		sourceIndexes,
		destinationIndexes,
	)

	var out osrmMatrixResponse
	if err := c.get(ctx, endpoint, &out); err != nil {
		return model.MatrixResponse{}, err
	}

	rows := make([]model.MatrixRow, 0, len(out.Durations))
	for i, durations := range out.Durations {
		row := model.MatrixRow{Cells: make([]model.MatrixCell, 0, len(durations))}
		for j, duration := range durations {
			distance := 0.0
			if i < len(out.Distances) && j < len(out.Distances[i]) {
				distance = out.Distances[i][j]
			}
			row.Cells = append(row.Cells, model.MatrixCell{
				DistanceMeters:  distance,
				DurationSeconds: int(duration + 0.5),
				Reachable:       duration > 0 || distance > 0,
			})
		}
		rows = append(rows, row)
	}

	return model.MatrixResponse{
		Provider: string(c.Name()),
		Rows:     rows,
	}, nil
}

func (c *Client) Isochrone(ctx context.Context, req model.IsochroneRequest) (model.IsochroneResponse, error) {
	return model.IsochroneResponse{}, fmt.Errorf("osrm does not support isochrones")
}

func (c *Client) OptimizeItinerary(ctx context.Context, req model.ItineraryOptimizationRequest) (model.ItineraryOptimizationResponse, error) {
	return model.ItineraryOptimizationResponse{}, fmt.Errorf("osrm does not support itinerary optimization")
}

func (c *Client) MapMatch(ctx context.Context, req model.MapMatchRequest) (model.MapMatchResponse, error) {
	return model.MapMatchResponse{}, fmt.Errorf("osrm map matching is not enabled for Inflap routing-service yet")
}

func (c *Client) get(ctx context.Context, endpoint string, dst any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return fmt.Errorf("create osrm request: %w", err)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("call osrm: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return fmt.Errorf("osrm returned status %d", resp.StatusCode)
	}
	if err := json.NewDecoder(resp.Body).Decode(dst); err != nil {
		return fmt.Errorf("decode osrm response: %w", err)
	}
	return nil
}

func osrmProfile(mode model.RouteMode) string {
	switch mode {
	case model.RouteModeCycling:
		return "bike"
	case model.RouteModeWalking:
		return "foot"
	default:
		return "driving"
	}
}

func coordinates(points []model.RoutePoint) string {
	parts := make([]string, 0, len(points))
	for _, point := range points {
		parts = append(parts, fmt.Sprintf("%.6f,%.6f", point.Longitude, point.Latitude))
	}
	return strings.Join(parts, ";")
}

func indexes(start int, count int) string {
	parts := make([]string, 0, count)
	for i := 0; i < count; i++ {
		parts = append(parts, fmt.Sprintf("%d", start+i))
	}
	return strings.Join(parts, ";")
}

type osrmRouteResponse struct {
	Routes []struct {
		Distance float64 `json:"distance"`
		Duration float64 `json:"duration"`
		Geometry string  `json:"geometry"`
	} `json:"routes"`
}

type osrmMatrixResponse struct {
	Durations [][]float64 `json:"durations"`
	Distances [][]float64 `json:"distances"`
}
