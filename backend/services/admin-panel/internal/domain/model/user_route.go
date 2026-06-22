package model

import (
	"strings"
	"time"

	"github.com/google/uuid"
)

type UserRouteModerationStatus string

const (
	UserRouteModerationPending  UserRouteModerationStatus = "pending"
	UserRouteModerationApproved UserRouteModerationStatus = "approved"
	UserRouteModerationRejected UserRouteModerationStatus = "rejected"
	UserRouteModerationHidden   UserRouteModerationStatus = "hidden"
)

func NormalizeUserRouteModerationStatus(value string) UserRouteModerationStatus {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case string(UserRouteModerationPending):
		return UserRouteModerationPending
	case string(UserRouteModerationApproved):
		return UserRouteModerationApproved
	case string(UserRouteModerationRejected):
		return UserRouteModerationRejected
	case string(UserRouteModerationHidden):
		return UserRouteModerationHidden
	default:
		return ""
	}
}

func (s UserRouteModerationStatus) IsValid() bool {
	return NormalizeUserRouteModerationStatus(string(s)) == s && s != ""
}

type UserRouteReviewDecision string

const (
	UserRouteReviewApprove UserRouteReviewDecision = "approve"
	UserRouteReviewReject  UserRouteReviewDecision = "reject"
	UserRouteReviewHide    UserRouteReviewDecision = "hide"
)

func NormalizeUserRouteReviewDecision(value string) UserRouteReviewDecision {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "approve", "approved":
		return UserRouteReviewApprove
	case "reject", "rejected":
		return UserRouteReviewReject
	case "hide", "hidden":
		return UserRouteReviewHide
	default:
		return ""
	}
}

func (d UserRouteReviewDecision) IsValid() bool {
	return NormalizeUserRouteReviewDecision(string(d)) == d && d != ""
}

type AdminUserRoutePoint struct {
	Position  int
	Label     string
	Latitude  float64
	Longitude float64
}

type AdminUserRoute struct {
	ID                uuid.UUID
	OwnerUserID       uuid.UUID
	Title             string
	Description       string
	Visibility        string
	CityCode          string
	DistanceMeters    float64
	DurationSeconds   int
	Points            []AdminUserRoutePoint
	ModerationStatus  UserRouteModerationStatus
	ModerationReason  string
	ModeratedByUserID *string
	ModeratedAt       *time.Time
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type AdminUserRouteListFilter struct {
	ModerationStatus UserRouteModerationStatus
	OwnerUserID      string
	CityCode         string
	Limit            int
	Offset           int
}

type AdminUserRouteReviewInput struct {
	RouteID  uuid.UUID
	Decision UserRouteReviewDecision
	Reason   string
}

type AdminUserRouteAdminListRequest struct {
	ActorUserID      string
	ActorRoles       []string
	ModerationStatus UserRouteModerationStatus
	OwnerUserID      string
	CityCode         string
	Limit            int
	Offset           int
}

type AdminUserRouteAdminReviewRequest struct {
	ActorUserID string
	ActorRoles  []string
	RouteID     uuid.UUID
	Decision    UserRouteReviewDecision
	Reason      string
}
