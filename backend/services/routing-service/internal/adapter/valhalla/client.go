package valhalla

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"math"
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
		return nil, fmt.Errorf("parse valhalla url: %w", err)
	}
	if parsed.Scheme == "" || parsed.Host == "" {
		return nil, fmt.Errorf("parse valhalla url: missing scheme or host")
	}
	return &Client{
		baseURL: strings.TrimRight(parsed.String(), "/"),
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}, nil
}

func (c *Client) Name() app.EngineName {
	return app.EngineValhalla
}

func (c *Client) Status(ctx context.Context) model.EngineStatus {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/status", nil)
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

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return model.EngineStatus{
			Name:    string(c.Name()),
			Enabled: true,
			Status:  "error",
			Error:   fmt.Sprintf("status endpoint returned %d", resp.StatusCode),
		}
	}

	var out valhallaStatusResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return model.EngineStatus{
			Name:    string(c.Name()),
			Enabled: true,
			Status:  "error",
			Error:   err.Error(),
		}
	}

	return model.EngineStatus{
		Name:      string(c.Name()),
		Enabled:   true,
		Reachable: true,
		Status:    "ok",
		Version:   out.Version,
	}
}

func (c *Client) Route(ctx context.Context, req model.RouteRequest) (model.RouteResponse, error) {
	payload := valhallaRouteRequest{
		Locations: valhallaLocations(req.Points),
		Costing:   costing(req.Mode, req.Profile),
		DirectionsOptions: map[string]string{
			"units": "kilometers",
		},
	}

	var out valhallaRouteResponse
	if err := c.post(ctx, "/route", payload, &out); err != nil {
		return model.RouteResponse{}, err
	}

	return out.toRouteResponse(req, string(c.Name())), nil
}

func (c *Client) Matrix(ctx context.Context, req model.MatrixRequest) (model.MatrixResponse, error) {
	payload := valhallaMatrixRequest{
		Sources: valhallaLocations(req.Origins),
		Targets: valhallaLocations(req.Destinations),
		Costing: costing(req.Mode, req.Profile),
	}

	var out valhallaMatrixResponse
	if err := c.post(ctx, "/sources_to_targets", payload, &out); err != nil {
		return model.MatrixResponse{}, err
	}

	return out.toMatrixResponse(string(c.Name())), nil
}

func (c *Client) Isochrone(ctx context.Context, req model.IsochroneRequest) (model.IsochroneResponse, error) {
	contours := make([]map[string]int, 0, len(req.Minutes))
	for _, minute := range req.Minutes {
		contours = append(contours, map[string]int{"time": minute})
	}
	payload := map[string]any{
		"locations": valhallaLocations([]model.RoutePoint{req.Origin}),
		"costing":   costing(req.Mode, req.Profile),
		"contours":  contours,
	}

	var out struct {
		Features []model.GeoJSONFeature `json:"features"`
	}
	if err := c.post(ctx, "/isochrone", payload, &out); err != nil {
		return model.IsochroneResponse{}, err
	}

	return model.IsochroneResponse{
		Provider: string(c.Name()),
		Features: out.Features,
	}, nil
}

func (c *Client) OptimizeItinerary(ctx context.Context, req model.ItineraryOptimizationRequest) (model.ItineraryOptimizationResponse, error) {
	points := make([]model.RoutePoint, 0, len(req.Stops)+2)
	if req.Start != nil {
		points = append(points, *req.Start)
	}
	points = append(points, req.Stops...)
	if req.End != nil {
		points = append(points, *req.End)
	}

	routeReq := model.RouteRequest{
		Profile: req.Profile,
		Mode:    req.Mode,
		Points:  points,
	}
	if err := routeReq.NormalizeAndValidate(); err != nil {
		return model.ItineraryOptimizationResponse{}, err
	}

	if len(points) < 4 {
		return c.routeItineraryInGivenOrder(ctx, req, routeReq)
	}

	payload := valhallaOptimizedRouteRequest{
		Locations: valhallaLocations(points),
		Costing:   costing(req.Mode, req.Profile),
		Units:     "kilometers",
	}

	var out valhallaOptimizedRouteResponse
	if err := c.post(ctx, "/optimized_route", payload, &out); err != nil {
		return model.ItineraryOptimizationResponse{}, err
	}

	optimizedPoints, orderedStops := optimizedPointOrder(points, req, out.Locations)
	routeReq.Points = optimizedPoints
	route := out.toRouteResponse(routeReq, string(c.Name()))

	return model.ItineraryOptimizationResponse{
		Provider:        string(c.Name()),
		OrderedStops:    orderedStops,
		Route:           route,
		DurationSeconds: route.DurationSeconds,
		DistanceMeters:  route.DistanceMeters,
	}, nil
}

func (c *Client) routeItineraryInGivenOrder(ctx context.Context, req model.ItineraryOptimizationRequest, routeReq model.RouteRequest) (model.ItineraryOptimizationResponse, error) {
	route, err := c.Route(ctx, routeReq)
	if err != nil {
		return model.ItineraryOptimizationResponse{}, err
	}
	return model.ItineraryOptimizationResponse{
		Provider:        string(c.Name()),
		OrderedStops:    req.Stops,
		Route:           route,
		DurationSeconds: route.DurationSeconds,
		DistanceMeters:  route.DistanceMeters,
	}, nil
}

func (c *Client) MapMatch(ctx context.Context, req model.MapMatchRequest) (model.MapMatchResponse, error) {
	payload := map[string]any{
		"shape":   valhallaLocations(req.Trace),
		"costing": costing(req.Mode, req.Profile),
	}

	var out valhallaRouteResponse
	if err := c.post(ctx, "/trace_route", payload, &out); err != nil {
		return model.MapMatchResponse{}, err
	}

	routeReq := model.RouteRequest{
		Profile: req.Profile,
		Mode:    req.Mode,
		Points:  []model.RoutePoint{req.Trace[0], req.Trace[len(req.Trace)-1]},
	}
	return model.MapMatchResponse{
		Provider: string(c.Name()),
		Route:    out.toRouteResponse(routeReq, string(c.Name())),
	}, nil
}

func (c *Client) post(ctx context.Context, path string, payload any, dst any) error {
	raw, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal valhalla request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(raw))
	if err != nil {
		return fmt.Errorf("create valhalla request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("%w: call valhalla %s: %v", app.ErrEngineUnavailable, path, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
		if resp.StatusCode >= http.StatusBadRequest && resp.StatusCode < http.StatusInternalServerError {
			return valhallaStatusError(model.ErrInvalidRequest, path, resp.StatusCode, body)
		}
		return valhallaStatusError(app.ErrEngineUnavailable, path, resp.StatusCode, body)
	}
	if err := json.NewDecoder(resp.Body).Decode(dst); err != nil {
		return fmt.Errorf("%w: decode valhalla %s response: %v", app.ErrEngineUnavailable, path, err)
	}
	return nil
}

func valhallaStatusError(base error, path string, statusCode int, body []byte) error {
	message := strings.TrimSpace(string(body))
	if message == "" {
		return fmt.Errorf("%w: valhalla %s returned status %d", base, path, statusCode)
	}
	return fmt.Errorf("%w: valhalla %s returned status %d: %s", base, path, statusCode, message)
}

func costing(mode model.RouteMode, profile model.RouteProfile) string {
	switch mode {
	case model.RouteModeDriving:
		return "auto"
	case model.RouteModeCycling:
		return "bicycle"
	default:
		switch profile {
		case model.RouteProfileFastWalk:
			return "pedestrian"
		default:
			return "pedestrian"
		}
	}
}

func valhallaLocations(points []model.RoutePoint) []map[string]any {
	locations := make([]map[string]any, 0, len(points))
	for _, point := range points {
		loc := map[string]any{
			"lat": point.Latitude,
			"lon": point.Longitude,
		}
		if point.Name != "" {
			loc["name"] = point.Name
		}
		locations = append(locations, loc)
	}
	return locations
}

type valhallaRouteRequest struct {
	Locations         []map[string]any  `json:"locations"`
	Costing           string            `json:"costing"`
	DirectionsOptions map[string]string `json:"directions_options,omitempty"`
}

type valhallaOptimizedRouteRequest struct {
	Locations []map[string]any `json:"locations"`
	Costing   string           `json:"costing"`
	Units     string           `json:"units,omitempty"`
}

type valhallaMatrixRequest struct {
	Sources []map[string]any `json:"sources"`
	Targets []map[string]any `json:"targets"`
	Costing string           `json:"costing"`
}

type valhallaRouteResponse struct {
	Trip struct {
		Summary struct {
			Length float64 `json:"length"`
			Time   float64 `json:"time"`
		} `json:"summary"`
		Legs []struct {
			Summary struct {
				Length float64 `json:"length"`
				Time   float64 `json:"time"`
			} `json:"summary"`
			Shape     string `json:"shape"`
			Maneuvers []struct {
				Instruction string  `json:"instruction"`
				Length      float64 `json:"length"`
				Time        float64 `json:"time"`
			} `json:"maneuvers"`
		} `json:"legs"`
	} `json:"trip"`
}

type valhallaOptimizedRouteResponse struct {
	valhallaRouteResponse
	Locations []struct {
		OriginalIndex *int `json:"original_index"`
	} `json:"locations"`
}

type valhallaStatusResponse struct {
	Version             string `json:"version"`
	TilesetLastModified int64  `json:"tileset_last_modified"`
	HasTiles            *bool  `json:"has_tiles"`
}

func (r valhallaRouteResponse) toRouteResponse(req model.RouteRequest, provider string) model.RouteResponse {
	legs := make([]model.RouteLeg, 0, len(r.Trip.Legs))
	var shape string
	for i, leg := range r.Trip.Legs {
		if shape == "" {
			shape = leg.Shape
		}
		steps := make([]model.RouteStep, 0, len(leg.Maneuvers))
		for _, maneuver := range leg.Maneuvers {
			steps = append(steps, model.RouteStep{
				Instruction:     maneuver.Instruction,
				DistanceMeters:  maneuver.Length * 1000,
				DurationSeconds: secondsToInt(maneuver.Time),
			})
		}
		legs = append(legs, model.RouteLeg{
			FromIndex:       i,
			ToIndex:         i + 1,
			DistanceMeters:  leg.Summary.Length * 1000,
			DurationSeconds: secondsToInt(leg.Summary.Time),
			Geometry:        model.RouteGeometry{Encoding: "polyline6", Polyline: leg.Shape},
			Steps:           steps,
		})
	}
	return model.RouteResponse{
		Provider:        provider,
		Mode:            req.Mode,
		Profile:         req.Profile,
		DistanceMeters:  r.Trip.Summary.Length * 1000,
		DurationSeconds: secondsToInt(r.Trip.Summary.Time),
		Geometry:        model.RouteGeometry{Encoding: "polyline6", Polyline: shape},
		Legs:            legs,
	}
}

func secondsToInt(seconds float64) int {
	if seconds <= 0 {
		return 0
	}
	return int(math.Round(seconds))
}

func optimizedPointOrder(points []model.RoutePoint, req model.ItineraryOptimizationRequest, locations []struct {
	OriginalIndex *int `json:"original_index"`
}) ([]model.RoutePoint, []model.RoutePoint) {
	if len(locations) != len(points) {
		return points, req.Stops
	}

	stopIndexByOriginalIndex := make(map[int]int, len(req.Stops))
	offset := 0
	if req.Start != nil {
		offset = 1
	}
	for i := range req.Stops {
		stopIndexByOriginalIndex[offset+i] = i
	}

	optimizedPoints := make([]model.RoutePoint, 0, len(points))
	orderedStops := make([]model.RoutePoint, 0, len(req.Stops))
	seen := make(map[int]struct{}, len(points))
	for _, location := range locations {
		if location.OriginalIndex == nil {
			return points, req.Stops
		}
		originalIndex := *location.OriginalIndex
		if originalIndex < 0 || originalIndex >= len(points) {
			return points, req.Stops
		}
		if _, ok := seen[originalIndex]; ok {
			return points, req.Stops
		}
		seen[originalIndex] = struct{}{}
		optimizedPoints = append(optimizedPoints, points[originalIndex])
		if stopIndex, ok := stopIndexByOriginalIndex[originalIndex]; ok {
			orderedStops = append(orderedStops, req.Stops[stopIndex])
		}
	}
	if len(optimizedPoints) != len(points) || len(orderedStops) != len(req.Stops) {
		return points, req.Stops
	}
	return optimizedPoints, orderedStops
}

type valhallaMatrixResponse struct {
	SourcesToTargets [][]struct {
		Distance float64 `json:"distance"`
		Time     int     `json:"time"`
	} `json:"sources_to_targets"`
}

func (r valhallaMatrixResponse) toMatrixResponse(provider string) model.MatrixResponse {
	rows := make([]model.MatrixRow, 0, len(r.SourcesToTargets))
	for _, source := range r.SourcesToTargets {
		row := model.MatrixRow{Cells: make([]model.MatrixCell, 0, len(source))}
		for _, target := range source {
			row.Cells = append(row.Cells, model.MatrixCell{
				DistanceMeters:  target.Distance * 1000,
				DurationSeconds: target.Time,
				Reachable:       target.Time > 0 || target.Distance > 0,
			})
		}
		rows = append(rows, row)
	}
	return model.MatrixResponse{
		Provider: provider,
		Rows:     rows,
	}
}
