package model

import (
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"
)

var ErrInvalidUserRoute = errors.New("invalid user route")

type RouteVisibility string

const (
	RouteVisibilityPrivate  RouteVisibility = "private"
	RouteVisibilityUnlisted RouteVisibility = "unlisted"
	RouteVisibilityPublic   RouteVisibility = "public"
)

type RouteModerationStatus string

const (
	RouteModerationStatusPending  RouteModerationStatus = "pending"
	RouteModerationStatusApproved RouteModerationStatus = "approved"
	RouteModerationStatusRejected RouteModerationStatus = "rejected"
	RouteModerationStatusHidden   RouteModerationStatus = "hidden"
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
	RouteProfileBikeCity    RouteProfile = "bike_city"
	RouteProfileCarStandard RouteProfile = "car_standard"
	RouteProfileDayPlan     RouteProfile = "day_plan"
	RouteProfileTransit     RouteProfile = "transit"
)

const (
	MinUserRoutePoints       = 2
	MaxUserRoutePoints       = 25
	MaxRouteTitleRunes       = 120
	MaxRouteDescriptionRunes = 2000
	MaxRoutePointNameRunes   = 120
	MaxRoutePointNoteRunes   = 500
)

type UserRoutePoint struct {
	ID                  string  `json:"id,omitempty"`
	Latitude            float64 `json:"latitude"`
	Longitude           float64 `json:"longitude"`
	Name                string  `json:"name,omitempty"`
	Note                string  `json:"note,omitempty"`
	SourceType          string  `json:"sourceType,omitempty"`
	SourceID            string  `json:"sourceId,omitempty"`
	StopDurationMinutes int     `json:"stopDurationMinutes,omitempty"`
}

func (p *UserRoutePoint) Normalize(index int) {
	p.ID = strings.TrimSpace(p.ID)
	p.Name = trimRunes(strings.TrimSpace(p.Name), MaxRoutePointNameRunes)
	p.Note = trimRunes(strings.TrimSpace(p.Note), MaxRoutePointNoteRunes)
	p.SourceType = strings.ToLower(strings.TrimSpace(p.SourceType))
	p.SourceID = strings.TrimSpace(p.SourceID)
	if p.ID == "" {
		p.ID = fmt.Sprintf("point-%d", index+1)
	}
	if p.StopDurationMinutes < 0 {
		p.StopDurationMinutes = 0
	}
}

func (p UserRoutePoint) Validate() error {
	if p.Latitude < -90 || p.Latitude > 90 {
		return fmt.Errorf("%w: latitude %.6f is outside [-90,90]", ErrInvalidUserRoute, p.Latitude)
	}
	if p.Longitude < -180 || p.Longitude > 180 {
		return fmt.Errorf("%w: longitude %.6f is outside [-180,180]", ErrInvalidUserRoute, p.Longitude)
	}
	return nil
}

type RouteSnapshot struct {
	Provider        string       `json:"provider,omitempty"`
	Mode            RouteMode    `json:"mode,omitempty"`
	Profile         RouteProfile `json:"profile,omitempty"`
	DistanceMeters  int          `json:"distanceMeters,omitempty"`
	DurationSeconds int          `json:"durationSeconds,omitempty"`
	EncodedPolyline string       `json:"encodedPolyline,omitempty"`
	GeometryGeoJSON string       `json:"geometryGeoJson,omitempty"`
}

func (s *RouteSnapshot) Normalize(profile RouteProfile) {
	s.Provider = strings.TrimSpace(s.Provider)
	s.EncodedPolyline = strings.TrimSpace(s.EncodedPolyline)
	s.GeometryGeoJSON = strings.TrimSpace(s.GeometryGeoJSON)
	if s.Profile == "" {
		s.Profile = profile
	}
	if s.Mode == "" {
		s.Mode = ModeForProfile(s.Profile)
	}
	if s.DistanceMeters < 0 {
		s.DistanceMeters = 0
	}
	if s.DurationSeconds < 0 {
		s.DurationSeconds = 0
	}
}

type UserRouteStats struct {
	SavesCount  int `json:"savesCount"`
	CopiesCount int `json:"copiesCount"`
	ViewsCount  int `json:"viewsCount"`
}

type UserRoute struct {
	ID                string                `json:"id"`
	OwnerUserID       string                `json:"ownerUserId"`
	SourceRouteID     *string               `json:"sourceRouteId,omitempty"`
	Title             string                `json:"title"`
	Description       string                `json:"description,omitempty"`
	Visibility        RouteVisibility       `json:"visibility"`
	ModerationStatus  RouteModerationStatus `json:"moderationStatus"`
	ModerationReason  string                `json:"moderationReason,omitempty"`
	ModeratedByUserID *string               `json:"moderatedByUserId,omitempty"`
	ModeratedAt       *time.Time            `json:"moderatedAt,omitempty"`
	Profile           RouteProfile          `json:"profile"`
	CityCode          string                `json:"cityCode,omitempty"`
	Tags              []string              `json:"tags,omitempty"`
	Points            []UserRoutePoint      `json:"points"`
	Snapshot          RouteSnapshot         `json:"snapshot"`
	Stats             UserRouteStats        `json:"stats"`
	SavedByMe         bool                  `json:"savedByMe"`
	CreatedAt         time.Time             `json:"createdAt"`
	UpdatedAt         time.Time             `json:"updatedAt"`
}

func (r *UserRoute) Normalize() {
	r.ID = strings.TrimSpace(r.ID)
	r.OwnerUserID = strings.TrimSpace(r.OwnerUserID)
	r.Title = trimRunes(strings.TrimSpace(r.Title), MaxRouteTitleRunes)
	r.Description = trimRunes(strings.TrimSpace(r.Description), MaxRouteDescriptionRunes)
	r.Visibility = NormalizeVisibility(r.Visibility)
	r.ModerationStatus = NormalizeModerationStatus(r.ModerationStatus)
	r.ModerationReason = strings.TrimSpace(r.ModerationReason)
	if r.ModeratedByUserID != nil {
		moderatedBy := strings.TrimSpace(*r.ModeratedByUserID)
		if moderatedBy == "" {
			r.ModeratedByUserID = nil
		} else {
			r.ModeratedByUserID = &moderatedBy
		}
	}
	if r.ModeratedAt != nil {
		moderatedAt := r.ModeratedAt.UTC()
		r.ModeratedAt = &moderatedAt
	}
	r.Profile = NormalizeProfile(r.Profile)
	r.CityCode = strings.ToLower(strings.TrimSpace(r.CityCode))
	r.Tags = normalizeTags(r.Tags)
	for i := range r.Points {
		r.Points[i].Normalize(i)
	}
	r.Snapshot.Normalize(r.Profile)
	r.CreatedAt = r.CreatedAt.UTC()
	r.UpdatedAt = r.UpdatedAt.UTC()
}

func (r UserRoute) Validate() error {
	if strings.TrimSpace(r.ID) == "" {
		return fmt.Errorf("%w: route id is required", ErrInvalidUserRoute)
	}
	if strings.TrimSpace(r.OwnerUserID) == "" {
		return fmt.Errorf("%w: owner user id is required", ErrInvalidUserRoute)
	}
	if utf8.RuneCountInString(strings.TrimSpace(r.Title)) < 3 {
		return fmt.Errorf("%w: title must contain at least 3 characters", ErrInvalidUserRoute)
	}
	if len(r.Points) < MinUserRoutePoints || len(r.Points) > MaxUserRoutePoints {
		return fmt.Errorf("%w: route requires between %d and %d points", ErrInvalidUserRoute, MinUserRoutePoints, MaxUserRoutePoints)
	}
	for _, point := range r.Points {
		if err := point.Validate(); err != nil {
			return err
		}
	}
	if !r.Visibility.IsValid() {
		return fmt.Errorf("%w: unsupported visibility %q", ErrInvalidUserRoute, r.Visibility)
	}
	if !r.ModerationStatus.IsValid() {
		return fmt.Errorf("%w: unsupported moderation status %q", ErrInvalidUserRoute, r.ModerationStatus)
	}
	if !r.Profile.IsValid() {
		return fmt.Errorf("%w: unsupported profile %q", ErrInvalidUserRoute, r.Profile)
	}
	return nil
}

func (r UserRoute) IsOwnedBy(userID string) bool {
	return r.OwnerUserID != "" && r.OwnerUserID == strings.TrimSpace(userID)
}

func (r UserRoute) IsReadableBy(userID string) bool {
	if r.IsOwnedBy(userID) {
		return true
	}
	if r.ModerationStatus == RouteModerationStatusRejected ||
		r.ModerationStatus == RouteModerationStatusHidden {
		return false
	}
	if r.Visibility == RouteVisibilityPublic {
		return r.ModerationStatus == RouteModerationStatusApproved
	}
	return r.Visibility == RouteVisibilityUnlisted
}

func (v RouteVisibility) IsValid() bool {
	switch v {
	case RouteVisibilityPrivate, RouteVisibilityUnlisted, RouteVisibilityPublic:
		return true
	default:
		return false
	}
}

func NormalizeVisibility(v RouteVisibility) RouteVisibility {
	switch RouteVisibility(strings.ToLower(strings.TrimSpace(string(v)))) {
	case RouteVisibilityUnlisted:
		return RouteVisibilityUnlisted
	case RouteVisibilityPublic:
		return RouteVisibilityPublic
	default:
		return RouteVisibilityPrivate
	}
}

func (s RouteModerationStatus) IsValid() bool {
	switch s {
	case RouteModerationStatusPending, RouteModerationStatusApproved, RouteModerationStatusRejected, RouteModerationStatusHidden:
		return true
	default:
		return false
	}
}

func NormalizeModerationStatus(s RouteModerationStatus) RouteModerationStatus {
	switch RouteModerationStatus(strings.ToLower(strings.TrimSpace(string(s)))) {
	case RouteModerationStatusPending:
		return RouteModerationStatusPending
	case RouteModerationStatusRejected:
		return RouteModerationStatusRejected
	case RouteModerationStatusHidden:
		return RouteModerationStatusHidden
	default:
		return RouteModerationStatusApproved
	}
}

func (p RouteProfile) IsValid() bool {
	switch p {
	case RouteProfileTouristWalk, RouteProfileBikeCity, RouteProfileCarStandard, RouteProfileDayPlan, RouteProfileTransit:
		return true
	default:
		return false
	}
}

func NormalizeProfile(p RouteProfile) RouteProfile {
	switch RouteProfile(strings.ToLower(strings.TrimSpace(string(p)))) {
	case RouteProfileBikeCity:
		return RouteProfileBikeCity
	case RouteProfileCarStandard:
		return RouteProfileCarStandard
	case RouteProfileDayPlan:
		return RouteProfileDayPlan
	case RouteProfileTransit:
		return RouteProfileTransit
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

func trimRunes(value string, limit int) string {
	if limit <= 0 || utf8.RuneCountInString(value) <= limit {
		return value
	}
	runes := []rune(value)
	return string(runes[:limit])
}

func normalizeTags(tags []string) []string {
	seen := make(map[string]struct{}, len(tags))
	normalized := make([]string, 0, len(tags))
	for _, tag := range tags {
		tag = strings.ToLower(strings.TrimSpace(tag))
		if tag == "" {
			continue
		}
		if _, ok := seen[tag]; ok {
			continue
		}
		seen[tag] = struct{}{}
		normalized = append(normalized, tag)
	}
	return normalized
}
