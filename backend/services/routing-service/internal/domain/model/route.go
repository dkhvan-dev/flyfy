package model

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrInvalidCoordinates = errors.New("routing invalid coordinates")
	ErrInvalidRequest     = errors.New("routing invalid request")
)

type RouteMode string

const (
	RouteModeWalking RouteMode = "walking"
	RouteModeCycling RouteMode = "cycling"
	RouteModeDriving RouteMode = "driving"
	RouteModeTransit RouteMode = "transit"
)

type RouteProfile string

const (
	RouteProfileTouristWalk RouteProfile = "tourist_walk"
	RouteProfileFastWalk    RouteProfile = "fast_walk"
	RouteProfileBikeCity    RouteProfile = "bike_city"
	RouteProfileCarStandard RouteProfile = "car_standard"
	RouteProfileGuideRoute  RouteProfile = "guide_route"
	RouteProfileDayPlan     RouteProfile = "day_plan"
	RouteProfileTransit     RouteProfile = "transit"
)

type RoutePoint struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Name      string  `json:"name,omitempty"`
}

func (p RoutePoint) Validate() error {
	if p.Latitude < -90 || p.Latitude > 90 {
		return fmt.Errorf("%w: latitude %.6f is outside [-90,90]", ErrInvalidCoordinates, p.Latitude)
	}
	if p.Longitude < -180 || p.Longitude > 180 {
		return fmt.Errorf("%w: longitude %.6f is outside [-180,180]", ErrInvalidCoordinates, p.Longitude)
	}
	return nil
}

type RouteProfileInfo struct {
	ID          RouteProfile `json:"id"`
	Mode        RouteMode    `json:"mode"`
	Label       string       `json:"label"`
	Description string       `json:"description"`
}

func DefaultRouteProfiles() []RouteProfileInfo {
	return []RouteProfileInfo{
		{
			ID:          RouteProfileTouristWalk,
			Mode:        RouteModeWalking,
			Label:       "Tourist walk",
			Description: "Balanced pedestrian routing for travel discovery and sightseeing.",
		},
		{
			ID:          RouteProfileFastWalk,
			Mode:        RouteModeWalking,
			Label:       "Fast walk",
			Description: "Fast pedestrian routing for reaching meeting points on time.",
		},
		{
			ID:          RouteProfileBikeCity,
			Mode:        RouteModeCycling,
			Label:       "City bike",
			Description: "Urban cycling routing for bike-friendly city movement.",
		},
		{
			ID:          RouteProfileCarStandard,
			Mode:        RouteModeDriving,
			Label:       "Car",
			Description: "Standard car routing without proprietary live traffic data.",
		},
		{
			ID:          RouteProfileGuideRoute,
			Mode:        RouteModeWalking,
			Label:       "Guide route",
			Description: "Walking route with multiple stops for guided excursions.",
		},
		{
			ID:          RouteProfileDayPlan,
			Mode:        RouteModeWalking,
			Label:       "Day plan",
			Description: "Multi-stop travel day planning across places and activities.",
		},
		{
			ID:          RouteProfileTransit,
			Mode:        RouteModeTransit,
			Label:       "Public transport",
			Description: "Transit routing for cities with validated GTFS data.",
		},
	}
}

type RouteRequest struct {
	Profile       RouteProfile `json:"profile,omitempty"`
	Mode          RouteMode    `json:"mode,omitempty"`
	Points        []RoutePoint `json:"points"`
	DepartureTime *time.Time   `json:"departureTime,omitempty"`
	ArrivalTime   *time.Time   `json:"arrivalTime,omitempty"`
}

func (r *RouteRequest) NormalizeAndValidate() error {
	r.Profile = NormalizeProfile(r.Profile)
	if r.Mode == "" {
		r.Mode = ModeForProfile(r.Profile)
	}
	if !SupportedMode(r.Mode) {
		return fmt.Errorf("%w: unsupported route mode %q", ErrInvalidRequest, r.Mode)
	}
	if len(r.Points) < 2 {
		return fmt.Errorf("%w: route requires at least two points", ErrInvalidRequest)
	}
	return validatePoints(r.Points)
}

type ETARequest struct {
	Profile       RouteProfile `json:"profile,omitempty"`
	Mode          RouteMode    `json:"mode,omitempty"`
	Origin        RoutePoint   `json:"origin"`
	Destination   RoutePoint   `json:"destination"`
	DepartureTime *time.Time   `json:"departureTime,omitempty"`
}

func (r *ETARequest) NormalizeAndValidate() error {
	r.Profile = NormalizeProfile(r.Profile)
	if r.Mode == "" {
		r.Mode = ModeForProfile(r.Profile)
	}
	if !SupportedMode(r.Mode) {
		return fmt.Errorf("%w: unsupported eta mode %q", ErrInvalidRequest, r.Mode)
	}
	return validatePoints([]RoutePoint{r.Origin, r.Destination})
}

func (r ETARequest) ToRouteRequest() RouteRequest {
	return RouteRequest{
		Profile:       r.Profile,
		Mode:          r.Mode,
		Points:        []RoutePoint{r.Origin, r.Destination},
		DepartureTime: r.DepartureTime,
	}
}

type MatrixRequest struct {
	Profile      RouteProfile `json:"profile,omitempty"`
	Mode         RouteMode    `json:"mode,omitempty"`
	Origins      []RoutePoint `json:"origins"`
	Destinations []RoutePoint `json:"destinations"`
}

func (r *MatrixRequest) NormalizeAndValidate() error {
	r.Profile = NormalizeProfile(r.Profile)
	if r.Mode == "" {
		r.Mode = ModeForProfile(r.Profile)
	}
	if !SupportedMode(r.Mode) {
		return fmt.Errorf("%w: unsupported matrix mode %q", ErrInvalidRequest, r.Mode)
	}
	if len(r.Origins) == 0 || len(r.Destinations) == 0 {
		return fmt.Errorf("%w: matrix requires at least one origin and destination", ErrInvalidRequest)
	}
	if err := validatePoints(r.Origins); err != nil {
		return err
	}
	return validatePoints(r.Destinations)
}

func (r MatrixRequest) PairCount() int {
	return len(r.Origins) * len(r.Destinations)
}

type IsochroneRequest struct {
	Profile RouteProfile `json:"profile,omitempty"`
	Mode    RouteMode    `json:"mode,omitempty"`
	Origin  RoutePoint   `json:"origin"`
	Minutes []int        `json:"minutes"`
}

func (r *IsochroneRequest) NormalizeAndValidate() error {
	r.Profile = NormalizeProfile(r.Profile)
	if r.Mode == "" {
		r.Mode = ModeForProfile(r.Profile)
	}
	if !SupportedMode(r.Mode) || r.Mode == RouteModeTransit {
		return fmt.Errorf("%w: unsupported isochrone mode %q", ErrInvalidRequest, r.Mode)
	}
	if err := r.Origin.Validate(); err != nil {
		return err
	}
	if len(r.Minutes) == 0 {
		return fmt.Errorf("%w: isochrone requires at least one contour", ErrInvalidRequest)
	}
	for _, minute := range r.Minutes {
		if minute <= 0 || minute > 240 {
			return fmt.Errorf("%w: isochrone minute %d outside supported range", ErrInvalidRequest, minute)
		}
	}
	return nil
}

type ItineraryOptimizationRequest struct {
	Profile RouteProfile `json:"profile,omitempty"`
	Mode    RouteMode    `json:"mode,omitempty"`
	Start   *RoutePoint  `json:"start,omitempty"`
	Stops   []RoutePoint `json:"stops"`
	End     *RoutePoint  `json:"end,omitempty"`
}

func (r *ItineraryOptimizationRequest) NormalizeAndValidate() error {
	r.Profile = NormalizeProfile(r.Profile)
	if r.Mode == "" {
		r.Mode = ModeForProfile(r.Profile)
	}
	if !SupportedMode(r.Mode) || r.Mode == RouteModeTransit {
		return fmt.Errorf("%w: unsupported itinerary mode %q", ErrInvalidRequest, r.Mode)
	}
	if len(r.Stops) == 0 {
		return fmt.Errorf("%w: itinerary requires at least one stop", ErrInvalidRequest)
	}
	if r.Start != nil {
		if err := r.Start.Validate(); err != nil {
			return err
		}
	}
	if err := validatePoints(r.Stops); err != nil {
		return err
	}
	if r.End != nil {
		return r.End.Validate()
	}
	return nil
}

type MapMatchRequest struct {
	Profile RouteProfile `json:"profile,omitempty"`
	Mode    RouteMode    `json:"mode,omitempty"`
	Trace   []RoutePoint `json:"trace"`
}

func (r *MapMatchRequest) NormalizeAndValidate() error {
	r.Profile = NormalizeProfile(r.Profile)
	if r.Mode == "" {
		r.Mode = ModeForProfile(r.Profile)
	}
	if !SupportedMode(r.Mode) || r.Mode == RouteModeTransit {
		return fmt.Errorf("%w: unsupported map-match mode %q", ErrInvalidRequest, r.Mode)
	}
	if len(r.Trace) < 2 {
		return fmt.Errorf("%w: map-match requires at least two trace points", ErrInvalidRequest)
	}
	return validatePoints(r.Trace)
}

type RouteResponse struct {
	Provider        string         `json:"provider"`
	Mode            RouteMode      `json:"mode"`
	Profile         RouteProfile   `json:"profile"`
	DistanceMeters  float64        `json:"distanceMeters"`
	DurationSeconds int            `json:"durationSeconds"`
	Geometry        RouteGeometry  `json:"geometry"`
	Legs            []RouteLeg     `json:"legs,omitempty"`
	Warnings        []RouteWarning `json:"warnings,omitempty"`
}

type RouteGeometry struct {
	Encoding string       `json:"encoding"`
	Polyline string       `json:"polyline,omitempty"`
	Points   []RoutePoint `json:"points,omitempty"`
}

type RouteLeg struct {
	FromIndex       int           `json:"fromIndex"`
	ToIndex         int           `json:"toIndex"`
	DistanceMeters  float64       `json:"distanceMeters"`
	DurationSeconds int           `json:"durationSeconds"`
	Geometry        RouteGeometry `json:"geometry,omitempty"`
	Steps           []RouteStep   `json:"steps,omitempty"`
}

type RouteStep struct {
	Instruction     string  `json:"instruction"`
	DistanceMeters  float64 `json:"distanceMeters"`
	DurationSeconds int     `json:"durationSeconds"`
}

type RouteWarning struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type ETAResponse struct {
	Provider        string       `json:"provider"`
	Mode            RouteMode    `json:"mode"`
	Profile         RouteProfile `json:"profile"`
	DistanceMeters  float64      `json:"distanceMeters"`
	DurationSeconds int          `json:"durationSeconds"`
}

type MatrixResponse struct {
	Provider string      `json:"provider"`
	Rows     []MatrixRow `json:"rows"`
}

type MatrixRow struct {
	Cells []MatrixCell `json:"cells"`
}

type MatrixCell struct {
	DistanceMeters  float64 `json:"distanceMeters"`
	DurationSeconds int     `json:"durationSeconds"`
	Reachable       bool    `json:"reachable"`
}

type IsochroneResponse struct {
	Provider string           `json:"provider"`
	Features []GeoJSONFeature `json:"features"`
}

type GeoJSONFeature map[string]any

type ItineraryOptimizationResponse struct {
	Provider        string        `json:"provider"`
	OrderedStops    []RoutePoint  `json:"orderedStops"`
	Route           RouteResponse `json:"route"`
	DurationSeconds int           `json:"durationSeconds"`
	DistanceMeters  float64       `json:"distanceMeters"`
}

type MapMatchResponse struct {
	Provider string        `json:"provider"`
	Route    RouteResponse `json:"route"`
}

func NormalizeProfile(profile RouteProfile) RouteProfile {
	normalized := RouteProfile(strings.ToLower(strings.TrimSpace(string(profile))))
	switch normalized {
	case RouteProfileTouristWalk,
		RouteProfileFastWalk,
		RouteProfileBikeCity,
		RouteProfileCarStandard,
		RouteProfileGuideRoute,
		RouteProfileDayPlan,
		RouteProfileTransit:
		return normalized
	default:
		return RouteProfileTouristWalk
	}
}

func ModeForProfile(profile RouteProfile) RouteMode {
	switch NormalizeProfile(profile) {
	case RouteProfileBikeCity:
		return RouteModeCycling
	case RouteProfileCarStandard:
		return RouteModeDriving
	case RouteProfileTransit:
		return RouteModeTransit
	default:
		return RouteModeWalking
	}
}

func SupportedMode(mode RouteMode) bool {
	switch mode {
	case RouteModeWalking, RouteModeCycling, RouteModeDriving, RouteModeTransit:
		return true
	default:
		return false
	}
}

func validatePoints(points []RoutePoint) error {
	for i, point := range points {
		if err := point.Validate(); err != nil {
			return fmt.Errorf("point %d: %w", i, err)
		}
	}
	return nil
}
